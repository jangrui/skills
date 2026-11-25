"""会议附件本地上传脚本（Skill 本地伪工具）。

用途：
    模型在创会 / 改会场景需要携带附件时，先调用本地伪工具 `upload_meeting_attachments`
    上传本地文件，拿到 file_id 列表后：
      - 创建会议：把 `[{file_id, file_name}]` 作为 `schedule_meeting.attachments` 下发；
      - 修改会议：把 `[{file_id, file_name}]` 作为 `update_meeting.attachment_add` 下发
        （服务端会在 Go 层内聚完成 GET 现状 → 合并 → PUT 全量，模型无需再先 `get_meeting`
        读取当前附件列表再本地合并）。

安全与分层约束：
    - 本脚本是 Skill 层唯一一处触碰本地文件内容和对象存储直传的位置；
      MCP Server 不接收也不中转文件字节流；
    - 本地侧必做校验：存在性 / 单文件大小 / 总量；不再做文件类型（扩展名白名单 /
      magic bytes）校验，服务端对 file_type 做最终白名单兜底；
    - upload-notify 仅在直传成功后调用一次；直传失败不再回传失败状态，
      悬挂的 file_id 由服务端按超时自行回收；
    - 日志禁止打印 put_auth / cos_url 等签名类敏感信息；
    - 所有网络调用经 mcp_proxy.McpProxy 发出；COS PUT 使用 urllib（标准库，无三方依赖）。
"""

from __future__ import annotations

import base64
import hashlib
import json
import os
import urllib.error
import urllib.parse
import urllib.request
from typing import Any, Callable, Dict, List, Optional, Tuple

# ================ 业务上限（与服务端一致，服务端二次校验兜底） ================
MAX_ATTACHMENT_COUNT = 20
MAX_TOTAL_BYTES = 100 * 1024 * 1024
# 单文件大小：不单独限制，与总量共用上限（避免误报）
MAX_SINGLE_BYTES = MAX_TOTAL_BYTES
# 哈希分块读取大小（1 MiB）
_HASH_CHUNK_BYTES = 1 << 20

# PUT 直传对象存储默认超时（秒）；大文件网络抖动时可由调用方覆盖
_DEFAULT_COS_PUT_TIMEOUT = 120


# ---- CRC64-ECMA (Go hash/crc64 ECMA 等价实现，与腾讯云 COS、阿里云 OSS 一致) ----
# 开放平台 upload-auth 要求携带 file_crc64（十进制字符串）；Python 标准库无 CRC64，
# 这里手动实现与 Go `hash/crc64.ECMA` 等价的算法：
#   - 反射多项式 0xC96C5795D7870F42（ECMA）
#   - init  = 0xFFFFFFFFFFFFFFFF （Go update 前置的 crc = ^crc）
#   - xorout= 0xFFFFFFFFFFFFFFFF （Go update 返回前的 return ^crc）
#   - 等效于 CRC-64/XZ；标准测试向量 b"123456789" → 0x995DC9BBDF1939FA
_CRC64_POLY_ECMA_REFLECTED = 0xC96C5795D7870F42
_CRC64_INIT_XOR = 0xFFFFFFFFFFFFFFFF


def _build_crc64_ecma_table() -> list:
    """按反射多项式生成 256 字节查找表（与 Go 内部表完全一致）。"""
    table = [0] * 256
    for i in range(256):
        crc = i
        for _ in range(8):
            if crc & 1:
                crc = (crc >> 1) ^ _CRC64_POLY_ECMA_REFLECTED
            else:
                crc >>= 1
        table[i] = crc
    return table


_CRC64_ECMA_TABLE = _build_crc64_ecma_table()


def _crc64_ecma(data: bytes) -> int:
    """计算整段 bytes 的 CRC64-ECMA（与 Go hash/crc64.ECMA 等价）。"""
    tbl = _CRC64_ECMA_TABLE
    crc = _CRC64_INIT_XOR  # 等价于 Go `crc = ^crc` 把 0 翻成全 1
    for b in data:
        crc = tbl[(crc ^ b) & 0xFF] ^ (crc >> 8)
    return crc ^ _CRC64_INIT_XOR  # 等价于 Go 返回前的 `^crc`


def _crc64_ecma_update(crc_inner: int, data: bytes) -> int:
    """流式分块更新：传入上一次的"内部中间态 crc"（已未 ^xorout），返回新的中间态。

    - 第一次调用前需以 _CRC64_INIT_XOR 作为初始值（即 Go 内部 `^0` = all-1s）；
    - 全部数据喂完后，由调用方做最终的 `crc ^ _CRC64_INIT_XOR` 得到最终 CRC64 值。
    """
    tbl = _CRC64_ECMA_TABLE
    crc = crc_inner
    for b in data:
        crc = tbl[(crc ^ b) & 0xFF] ^ (crc >> 8)
    return crc


# ================ 内部工具 ================

def _calc_hashes(path: str) -> Dict[str, Any]:
    """一次性遍历文件计算 md5 / sha1 / crc64-ecma 以及总大小。

    crc64 以十进制字符串形式返回，与开放平台 upload-auth 入参契约一致。

    Returns:
        {"size": int, "md5": hex-str, "sha1": hex-str, "crc64": decimal-str}
    """
    md5 = hashlib.md5()
    sha1 = hashlib.sha1()
    crc64 = _CRC64_INIT_XOR  # 等价于 Go `crc = ^crc`（init = all-1s）
    size = 0
    with open(path, "rb") as f:
        while True:
            chunk = f.read(_HASH_CHUNK_BYTES)
            if not chunk:
                break
            md5.update(chunk)
            sha1.update(chunk)
            crc64 = _crc64_ecma_update(crc64, chunk)
            size += len(chunk)
    return {
        "size": size,
        "md5": md5.hexdigest(),
        "sha1": sha1.hexdigest(),
        "crc64": str(crc64 ^ _CRC64_INIT_XOR),  # 等价于 Go 返回前的 `^crc`
    }


def _put_to_cos(cos_url: str, put_auth: str, path: str, md5_hex: str,
                timeout: int = _DEFAULT_COS_PUT_TIMEOUT) -> None:
    """PUT 直传对象存储。

    Content-MD5 头按 COS 要求使用 base64(md5-raw)；Authorization 使用 put_auth 原值。
    """
    md5_b64 = base64.b64encode(bytes.fromhex(md5_hex)).decode("ascii")
    with open(path, "rb") as f:
        data = f.read()
    req = urllib.request.Request(
        cos_url,
        data=data,
        method="PUT",
        headers={
            "Authorization": put_auth,
            "Content-MD5": md5_b64,
            "Content-Length": str(len(data)),
        },
    )
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        if resp.status >= 400:
            raise RuntimeError(f"COS PUT 失败: status={resp.status}")


def _invoke_proxy_tool(proxy: Any, tool_name: str,
                       arguments: Dict[str, Any]) -> Dict[str, Any]:
    """通过 McpProxy 调用远端 tool，并解析其业务 JSON 文本，返回 body 部分。

    与 scripts/tencent_meeting.py 中的解析规则保持一致：
        - result.error → 抛 RuntimeError（含服务端 JSONRPC 层错误信息）
        - result.content[0].text 是服务端 HttpResponse 结构的 JSON 字符串：
            {
              "status_code": int,   // HTTP 状态码
              "headers":     map,   // 响应头
              "body":        str    // 响应体字符串
            }
          其中 body 本身是字符串：
            - status_code == 200 时，body 是业务出参 JSON 字符串；
            - status_code != 200 时，body 是业务报错字符串。

    本函数在协议收口处统一：
        1) 非 200 → 抛 RuntimeError，异常消息直接取 body；
        2) 200   → 将 body 二次 json.loads 为对象后返回，便于上层直接
                    .get(业务字段) 使用。
    """
    rsp = proxy.request("tools/call", {"name": tool_name, "arguments": arguments})
    if not isinstance(rsp, dict):
        raise RuntimeError(f"[{tool_name}] 远端响应格式异常")
    inner = rsp.get("result")
    if not isinstance(inner, dict):
        raise RuntimeError(f"[{tool_name}] 远端响应缺少 result")

    if "error" in inner:
        err = inner["error"] if isinstance(inner["error"], dict) else {}
        msg = err.get("message") or json.dumps(err, ensure_ascii=False)
        raise RuntimeError(f"[{tool_name}] {msg}")

    for item in inner.get("content", []) or []:
        if isinstance(item, dict) and item.get("type") == "text":
            text = item.get("text", "")
            try:
                parsed = json.loads(text) if text else {}
            except json.JSONDecodeError as e:
                raise RuntimeError(f"[{tool_name}] 响应文本不是合法 JSON: {e}")
            if not isinstance(parsed, dict):
                raise RuntimeError(f"[{tool_name}] 响应顶层不是对象")

            status_code = parsed.get("status_code")
            body = parsed.get("body", "")

            # 非 200：body 即为业务报错字符串，直接抛出
            if status_code != 200:
                msg = body if isinstance(body, str) and body else json.dumps(
                    parsed, ensure_ascii=False
                )
                raise RuntimeError(f"[{tool_name}] {msg} (status_code={status_code})")

            # 200：body 是业务出参 JSON 字符串，二次解析为对象返回
            if not isinstance(body, str) or not body:
                return {}
            try:
                parsed_body = json.loads(body)
            except json.JSONDecodeError as e:
                raise RuntimeError(f"[{tool_name}] 业务 body 不是合法 JSON: {e}")
            return parsed_body if isinstance(parsed_body, dict) else {}
    raise RuntimeError(f"[{tool_name}] 响应 content 为空")


# ================ 预校验 ================

def _ext_of(path: str) -> str:
    """提取小写扩展名（不含点），无扩展名时返回空串。"""
    return os.path.splitext(path)[1].lstrip(".").lower()

def _preflight(paths: List[str]) -> Tuple[List[Tuple[str, str]], List[Dict[str, str]]]:
    """批量预校验：个数 + 累计总量 + 单文件存在性 / 非空 / 大小。

    不发任何网络请求；返回：
        (valid, failures)：
            - valid: [(path, ext), ...] —— 已通过本地全部校验的文件及其扩展名（小写，
              无点；无扩展名时为空串）。该 ext 直接作为 upload-auth 的 file_type 透传；
            - failures: [{"path": str, "reason": str}, ...] —— 可直接并入最终返回。

    注意：
        - 批次级（个数、累计总量）采用 raise ValueError，让调用方感知为批次性拒绝；
        - 单文件级错误仅进 failures，保持当前"best-effort 批处理"语义。
    """
    failures: List[Dict[str, str]] = []

    if not paths:
        raise ValueError("paths 不能为空")
    if len(paths) > MAX_ATTACHMENT_COUNT:
        raise ValueError(
            f"附件个数 {len(paths)} 超过上限 {MAX_ATTACHMENT_COUNT}"
        )

    total = 0
    valid: List[Tuple[str, str]] = []
    for p in paths:
        if not isinstance(p, str) or not p:
            failures.append({"path": str(p), "reason": "路径为空或非字符串"})
            continue
        if not os.path.isfile(p):
            failures.append({"path": p, "reason": "文件不存在或不是普通文件"})
            continue
        try:
            size = os.path.getsize(p)
        except OSError as e:
            failures.append({"path": p, "reason": f"读取文件大小失败: {e}"})
            continue
        if size == 0:
            failures.append({"path": p, "reason": "文件为空"})
            continue
        if size > MAX_SINGLE_BYTES:
            failures.append({
                "path": p,
                "reason": f"文件大小 {size} 超过上限 {MAX_SINGLE_BYTES} 字节",
            })
            continue
        total += size
        valid.append((p, _ext_of(p)))

    if total > MAX_TOTAL_BYTES:
        raise ValueError(
            f"附件总大小 {total} 字节 超过上限 {MAX_TOTAL_BYTES} 字节"
        )
    return valid, failures


# ================ 单文件上传流水线 ================

def _upload_one(proxy: Any, path: str, file_type: str,
                put_cos: Callable[..., None] = _put_to_cos) -> Dict[str, Any]:
    """按"算哈希 → 申请授权 → 直传 → 通知完成"的流程上传单个文件。

    前置约束：调用方必须确保 path 已通过 `_preflight` 的本地校验（存在性 / 非空 /
    大小 / 总量），因此本函数内部不再重复做本地校验。

    成功返回 {file_id, file_name, file_size}；失败抛 RuntimeError（含原因）。
    put_cos 参数仅用于单测注入，生产调用不要覆盖默认值。
    """
    name = os.path.basename(path)

    # 1) 计算哈希与大小（本地校验已在 preflight 完成，这里不再重复）
    h = _calc_hashes(path)

    # 2) 申请上传授权（服务端返回 cos_url / put_auth / file_id）
    auth = _invoke_proxy_tool(
        proxy,
        "meeting_attachment_upload_auth",
        {
            "file_name": name,
            "file_type": file_type,
            "file_size": str(h["size"]),
            "file_md5": h["md5"],
            "file_sha1": h["sha1"],
            "file_crc64": h["crc64"],  # 业务侧要求必填
        },
    )
    file_id = auth.get("file_id")
    cos_url = auth.get("cos_url")
    cos_auth_info = auth.get("cos_auth_info") or {}
    put_auth = cos_auth_info.get("put_auth") if isinstance(cos_auth_info, dict) else None
    if not file_id or not cos_url or not put_auth:
        raise RuntimeError(f"[{name}] upload-auth 响应缺少必要字段")

    # 服务端返回的 cos_url / put_auth 可能经过 URL 百分号编码（例如
    # "https%3A%2F%2F..."），urllib 无法识别此类 scheme，直接透传会报
    # "unknown url type"。此处统一 unquote 一次还原为原始形态；
    # 对未经编码的纯 ASCII 串，unquote 是幂等的，无副作用。
    cos_url = urllib.parse.unquote(cos_url)
    put_auth = urllib.parse.unquote(put_auth)

    # 4) 直传对象存储；失败直接抛出，upload-notify 仅在成功路径调用，
    #    悬挂的 file_id 由服务端按超时自行回收，不再回传失败状态。
    try:
        put_cos(cos_url, put_auth, path, h["md5"])
    except Exception as e:
        raise RuntimeError(f"[{name}] 直传对象存储失败: {e}")

    # 5) 通知完成（只在直传成功后调用一次）
    _invoke_proxy_tool(
        proxy,
        "meeting_attachment_upload_notify",
        {"file_id": file_id},
    )

    return {"file_id": file_id, "file_name": name, "file_size": h["size"]}


# ================ 对外入口 ================

def upload_attachments(proxy: Any, paths: List[str],
                       put_cos: Optional[Callable[..., None]] = None) -> Dict[str, Any]:
    """批量上传附件。

    Args:
        proxy: McpProxy 实例（具备 request(method, params) 能力）。
        paths: 本地文件绝对路径列表；最多 MAX_ATTACHMENT_COUNT 项，总量 ≤ MAX_TOTAL_BYTES。
        put_cos: 可选，单测注入的 PUT 直传函数；生产调用不要覆盖。

    Returns:
        {
            "uploaded": [ {file_id, file_name, file_size}, ... ],
            "failures": [ {path, reason}, ... ],
        }
    """
    put_fn = put_cos or _put_to_cos
    valid, failures = _preflight(paths)
    uploaded: List[Dict[str, Any]] = []
    for p, file_type in valid:
        try:
            uploaded.append(_upload_one(proxy, p, file_type, put_cos=put_fn))
        except Exception as e:
            failures.append({"path": p, "reason": str(e)})
    return {"uploaded": uploaded, "failures": failures}

# 便于 skill_md 中以字符串列出的"上限"一致（供文档交叉引用）
__all__ = [
    "MAX_ATTACHMENT_COUNT",
    "MAX_TOTAL_BYTES",
    "upload_attachments",
]
