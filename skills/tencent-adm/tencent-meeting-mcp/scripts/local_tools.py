"""
本地伪工具实现：在 Skill 包内拦截执行；可按需转发到 MCP Server。

当前提供的本地工具：
    - set_skill_update_preference：设置当前设备的版本更新偏好
    - get_skill_update_preference：查询当前更新偏好与 snooze 静默状态，
      返回 shouldPrompt 决策给模型，模型不再自行做时间戳运算
    - upload_meeting_attachments：批量上传会议附件（本地校验 + 三步上传流水线），
      内部会调用远端 meeting_attachment_upload_auth / meeting_attachment_upload_notify，
      需要调用方透传 McpProxy 实例
"""

import json
from typing import Any, Dict, List, Optional

import update_state
import upload_attachment

# 本地伪工具名称
LOCAL_TOOL_SET_PREFERENCE = "set_skill_update_preference"
LOCAL_TOOL_GET_PREFERENCE = "get_skill_update_preference"
LOCAL_TOOL_UPLOAD_ATTACHMENTS = "upload_meeting_attachments"

# 当前所有本地工具名集合
_LOCAL_TOOL_NAMES = {
    LOCAL_TOOL_SET_PREFERENCE,
    LOCAL_TOOL_GET_PREFERENCE,
    LOCAL_TOOL_UPLOAD_ATTACHMENTS,
}

# 需要 McpProxy 访问远端 MCP 的本地伪工具集合（用于区分纯本地工具 vs. 混合工具）
_LOCAL_TOOLS_NEED_PROXY = {LOCAL_TOOL_UPLOAD_ATTACHMENTS}

# 本地工具的 inputSchema 定义（与 MCP Tool 协议保持一致）
_SET_PREFERENCE_TOOL_DEFINITION: Dict[str, Any] = {
    "name": LOCAL_TOOL_SET_PREFERENCE,
    "description": (
        "设置腾讯会议 Skill 更新偏好，仅影响当前设备本地设置。\n"
        "支持以下 action：\n"
        "- snooze：对指定版本暂不更新（静默时长由本地脚本决定，模型无需关心）\n"
        "- auto_upgrade：将默认更新偏好设为自动更新\n"
        "- disable_optional_check：关闭可选更新提醒\n"
        "- enable_optional_check：重新开启可选更新提醒\n"
        "本工具不会上报到 MCP Server，也不会影响服务端的版本检查逻辑。"
    ),
    "inputSchema": {
        "type": "object",
        "properties": {
            "action": {
                "type": "string",
                "enum": [
                    "snooze",
                    "auto_upgrade",
                    "disable_optional_check",
                    "enable_optional_check",
                ],
                "description": "要执行的本地偏好动作",
            },
            "version": {
                "type": "string",
                "description": "目标版本号，仅 action=snooze 时必填",
            },
        },
        "required": ["action"],
    },
}


# get_skill_update_preference 的 inputSchema 定义
_GET_PREFERENCE_TOOL_DEFINITION: Dict[str, Any] = {
    "name": LOCAL_TOOL_GET_PREFERENCE,
    "description": (
        "查询当前设备的腾讯会议 Skill 版本更新偏好与 snooze 静默状态。\n"
        "收到 MCP 响应中携带的版本更新提示后，模型必须先调用本工具，再决定是否打扰用户。\n"
        "返回 JSON 文本，关键字段：\n"
        "- shouldPrompt：是否需要弹出更新询问。模型仅需依据该字段决策，禁止自行解析 update-state.json 做时间判断。\n"
        "- reason：决策原因（disabled / auto_upgrade / snoozed / version_changed / expired / no_snooze / no_latest_version）。\n"
        "- snooze：当前 snooze 详情，包含 deadline 与 remainingSeconds，便于排查。\n"
        "本工具不会上报到 MCP Server，也不会修改任何本地状态。"
    ),
    "inputSchema": {
        "type": "object",
        "properties": {
            "latest_version": {
                "type": "string",
                "description": "MCP 响应 hints 中提示的最新版本号，用于判定 snooze 是否仍对该版本有效",
            },
        },
        "required": ["latest_version"],
    },
}





# upload_meeting_attachments 的 inputSchema 定义
_UPLOAD_ATTACHMENTS_TOOL_DEFINITION: Dict[str, Any] = {
    "name": LOCAL_TOOL_UPLOAD_ATTACHMENTS,
    "description": (
        "批量上传本地文件作为会议附件，返回可直接用于 schedule_meeting / update_meeting 的 "
        "attachments（含 file_id、file_name）。\n"
        "- 创建会议：把结果作为 `schedule_meeting.attachments` 下发；\n"
        "- 修改会议：把结果作为 `update_meeting.attachment_add` 下发。\n"
        "本工具是 Skill 层本地伪工具，处理步骤：\n"
        "1) 本地预校验：个数（<= 20）、单文件/总大小（<= 100 MB）、存在性与非空检查；\n"
        "2) 为每个文件调用远端 meeting_attachment_upload_auth 申请直传授权（file_type 按本地扩展名透传，无扩展名时为空串）；\n"
        "3) 本地按 PUT 方式直传对象存储；\n"
        "4) 直传成功后调用远端 meeting_attachment_upload_notify 通知完成；直传失败不回传状态，"
        "悬挂的 file_id 由服务端按超时自行回收。\n"
        "**安全约束**：禁止把本地文件内容发给 MCP Server；file 内容仅在本机与对象存储之间流转。\n"
        "**部分失败不中断**：任一文件失败不会中断其他文件，结果中 `uploaded` 为成功列表、"
        "`failures` 为失败明细（含路径与原因）。"
    ),
    "inputSchema": {
        "type": "object",
        "properties": {
            "paths": {
                "type": "array",
                "items": {"type": "string"},
                "minItems": 1,
                "maxItems": 20,
                "description": "本地文件绝对路径列表；最多 20 个，总大小上限 100 MB",
            },
        },
        "required": ["paths"],
    },
}


def _get_local_tool_definitions() -> List[Dict[str, Any]]:
    """返回当前所有本地伪工具的协议定义"""
    return [_SET_PREFERENCE_TOOL_DEFINITION, _GET_PREFERENCE_TOOL_DEFINITION, _UPLOAD_ATTACHMENTS_TOOL_DEFINITION]


def is_local_tool_call(method: str, params: Dict[str, Any]) -> bool:
    """
    判断当前调用是否命中本地伪工具。

    仅当 method == tools/call 且 name 属于本地工具集合时返回 True。
    """
    if method != "tools/call":
        return False
    if not isinstance(params, dict):
        return False
    name = params.get("name", "")
    return name in _LOCAL_TOOL_NAMES


def handle_local_tool_call(method: str, params: Dict[str, Any],
                           proxy: Optional[Any] = None) -> Dict[str, Any]:
    """
    执行本地伪工具调用，并返回符合 MCP 协议的响应结构。

    返回结构与远端 tools/call 一致：
        {"jsonrpc": "2.0", "id": 1, "result": {"content": [{"type": "text", "text": "..."}]}}

    Args:
        method: JSONRPC2.0 method，必须为 tools/call
        params: JSONRPC2.0 params（含 name/arguments）
        proxy: 可选的 McpProxy 实例；仅混合型本地工具（如 upload_meeting_attachments）
               需要通过它与远端 MCP Server 交互。纯本地工具可省略。
    """
    if method != "tools/call":
        return _build_error_response("不支持的本地方法")

    name = params.get("name", "")
    arguments = params.get("arguments", {}) if isinstance(params, dict) else {}
    if not isinstance(arguments, dict):
        arguments = {}

    if name == LOCAL_TOOL_SET_PREFERENCE:
        return _handle_set_skill_update_preference(arguments)

    if name == LOCAL_TOOL_GET_PREFERENCE:
        return _handle_get_skill_update_preference(arguments)

    if name == LOCAL_TOOL_UPLOAD_ATTACHMENTS:
        if proxy is None:
            return _build_text_response("[失败] 当前调用上下文未提供 MCP 代理，无法上传附件")
        return _handle_upload_meeting_attachments(arguments, proxy)

    return _build_error_response(f"未知的本地工具: {name}")


def tool_needs_proxy(name: str) -> bool:
    """判断某个本地工具是否需要 McpProxy（供入口层决定如何调用 handle_local_tool_call）。"""
    return name in _LOCAL_TOOLS_NEED_PROXY


def inject_local_tools(tools_list_result: Dict[str, Any]) -> Dict[str, Any]:
    """
    将本地伪工具注入到远端 tools/list 的返回结果中。

    - 若结果格式异常或缺失字段，返回原结果，避免影响主流程
    - 若已存在同名工具，则跳过注入，不重复添加
    """
    if not isinstance(tools_list_result, dict):
        return tools_list_result

    inner = tools_list_result.get("result")
    if not isinstance(inner, dict):
        return tools_list_result

    tools = inner.get("tools")
    if not isinstance(tools, list):
        tools = []

    existing_names = {t.get("name") for t in tools if isinstance(t, dict)}
    for definition in _get_local_tool_definitions():
        if definition["name"] not in existing_names:
            tools.append(definition)

    inner["tools"] = tools
    tools_list_result["result"] = inner
    return tools_list_result


def _handle_set_skill_update_preference(arguments: Dict[str, Any]) -> Dict[str, Any]:
    """处理 set_skill_update_preference 工具调用"""
    # 严格做 str 类型校验：避免模型传入非字符串污染本地状态文件
    raw_action = arguments.get("action")
    raw_version = arguments.get("version")
    action = raw_action if isinstance(raw_action, str) else ""
    version = raw_version if isinstance(raw_version, str) else ""

    if action == "snooze":
        if not version:
            return _build_text_response("[失败] action=snooze 时必须传入 version 参数")
        update_state.save_snooze(version)
        return _build_text_response(f"已对版本 {version} 设置暂不更新")

    if action == "auto_upgrade":
        update_state.enable_auto_upgrade()
        return _build_text_response("已开启默认自动更新")

    if action == "disable_optional_check":
        update_state.disable_optional_update_check()
        return _build_text_response("已关闭可选更新提醒")

    if action == "enable_optional_check":
        update_state.enable_optional_update_check()
        return _build_text_response("已重新启用可选更新提醒")

    return _build_text_response(f"[失败] 不支持的 action: {action}")


def _handle_get_skill_update_preference(arguments: Dict[str, Any]) -> Dict[str, Any]:
    """处理 get_skill_update_preference 工具调用

    将本地状态 + compute_prompt_decision 结果合并为 JSON 文本返回。
    模型读到 shouldPrompt 即可决定是否打扰用户，无需自己解析时间戳。
    """
    raw_version = arguments.get("latest_version")
    latest_version = raw_version if isinstance(raw_version, str) else ""

    state = update_state.load_update_state()
    decision = update_state.compute_prompt_decision(state, latest_version)

    payload: Dict[str, Any] = {
        "optionalUpdateCheck": bool(state.get("optionalUpdateCheck", True)),
        "autoUpgrade": bool(state.get("autoUpgrade", False)),
        "latestVersion": latest_version,
        "shouldPrompt": decision.get("shouldPrompt", False),
        "reason": decision.get("reason", ""),
    }
    if "snooze" in decision:
        payload["snooze"] = decision["snooze"]
    else:
        payload["snooze"] = None

    return _build_text_response(json.dumps(payload, ensure_ascii=False))


def _handle_upload_meeting_attachments(arguments: Dict[str, Any], proxy: Any) -> Dict[str, Any]:
    """处理 upload_meeting_attachments 工具调用。

    入参结构：{"paths": ["/abs/a.pdf", "/abs/b.docx", ...]}
    返回文本是业务 JSON：{"uploaded": [...], "failures": [...]}

    任何预校验异常（如个数/总量超限、空 paths）会以 [失败] 文本返回，保持与
    其它本地工具的失败态一致，避免调用方把 Python 异常直接抛给用户。
    """
    raw_paths = arguments.get("paths")
    if not isinstance(raw_paths, list) or not raw_paths:
        return _build_text_response("[失败] 参数 paths 必填且为非空字符串数组")
    paths: List[str] = []
    for p in raw_paths:
        if isinstance(p, str) and p:
            paths.append(p)
    if not paths:
        return _build_text_response("[失败] 参数 paths 中没有有效的字符串路径")

    try:
        result = upload_attachment.upload_attachments(proxy, paths)
    except ValueError as e:
        # 预校验级错误（个数/总量超限等），作为人类可读文本返回
        return _build_text_response(f"[失败] {e}")
    except Exception as e:  # noqa: BLE001 — 本地伪工具的兜底，防止异常泄漏到入口层
        return _build_text_response(f"[失败] 上传过程发生异常: {e}")
    return _build_text_response(json.dumps(result, ensure_ascii=False))


def _build_text_response(text: str) -> Dict[str, Any]:
    """构建符合 MCP 协议的文本响应

    注：当前 Skill 主入口为命令行 stdout 模式，请求侧未透传 jsonrpc id，
    因此这里 id 留空（None）。后续若改造为 stdio 长连接模式，需要由调用方
    透传请求 id，避免与 jsonrpc 请求-响应映射不一致。
    """
    return {
        "jsonrpc": "2.0",
        "id": None,
        "result": {
            "content": [
                {"type": "text", "text": text}
            ]
        },
    }


def _build_error_response(message: str) -> Dict[str, Any]:
    """构建符合 MCP 协议的错误响应

    注：id 同 _build_text_response，CLI 模式下无来源，置为 None。
    """
    return {
        "jsonrpc": "2.0",
        "id": None,
        "result": {
            "error": {
                "code": -32601,
                "message": message,
            }
        },
    }
