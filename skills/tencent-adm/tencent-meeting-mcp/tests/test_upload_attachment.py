"""upload_attachment 单元测试

覆盖用例：
    - 全部成功：两份文件（pdf + docx）都上传成功，返回 file_id 列表
    - 部分失败：一个文件成功一个本地校验失败（文件不存在），failures 带原因
    - 空输入抛错
    - 超过个数上限抛错
    - 超过总量上限抛错
    - upload-auth 响应缺字段 → 失败条目
    - PUT 直传抛异常 → 失败条目且触发 file_state=2 通知
    - 远端 result.error → 失败条目
"""

import os
import sys
import tempfile
import unittest
import zipfile
from pathlib import Path
from typing import Any, Dict, List

_SCRIPTS_DIR = Path(__file__).resolve().parent.parent / "scripts"
sys.path.insert(0, str(_SCRIPTS_DIR))

import upload_attachment  # noqa: E402

_PDF_HEAD = b"%PDF-1.7\n%aaa\n"

# 合法 docx 所需的最小 [Content_Types].xml 内容
_DOCX_CONTENT_TYPES_XML = (
    b'<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
    b'<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
    b'<Override PartName="/word/document.xml" '
    b'ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>'
    b'</Types>'
)


def _make_pdf(path: str, pad: int = 128) -> None:
    with open(path, "wb") as f:
        f.write(_PDF_HEAD + b"x" * pad)


def _make_docx(path: str) -> None:
    """生成带 [Content_Types].xml 的最小合法 docx。"""
    with zipfile.ZipFile(path, "w") as zf:
        zf.writestr("[Content_Types].xml", _DOCX_CONTENT_TYPES_XML)
        zf.writestr("word/document.xml", b"<xml/>")


class _FakeProxy:
    """记录调用的 McpProxy 替身。

    behaviors: {tool_name: [response1, response2, ...]} 响应可为 dict 或 Exception
    """

    def __init__(self, behaviors: Dict[str, List[Any]]) -> None:
        self.behaviors = behaviors
        self.calls: List[Dict[str, Any]] = []

    def request(self, method: str, params: Dict[str, Any]) -> Dict[str, Any]:
        self.calls.append({"method": method, "params": params})
        name = params.get("name", "")
        queue = self.behaviors.get(name, [])
        if not queue:
            raise AssertionError(f"[fake-proxy] 未预期调用: {name}")
        rsp = queue.pop(0)
        if isinstance(rsp, Exception):
            raise rsp
        return rsp


def _wrap_http_resp(body_obj: Any, status_code: int = 200) -> str:
    """把业务 payload 包装成服务端 HttpResponse 的 JSON 文本。

    与 scripts/upload_attachment.py:_invoke_proxy_tool 的解析协议对齐：
        content[0].text = json.dumps({
            "status_code": int,
            "headers":    {},
            "body":       <业务 JSON 字符串>,
        })
    """
    import json as _json
    body_str = body_obj if isinstance(body_obj, str) else _json.dumps(body_obj)
    return _json.dumps({
        "status_code": status_code,
        "headers": {},
        "body": body_str,
    })


def _ok_auth_resp(file_id: str) -> Dict[str, Any]:
    """构造 meeting_attachment_upload_auth 的典型成功响应（MCP 协议结构）。"""
    payload = {
        "file_id": file_id,
        "cos_url": f"https://cos.example.com/key/{file_id}",
        "cos_auth_info": {"put_auth": f"q-sign-{file_id}"},
    }
    return {
        "jsonrpc": "2.0", "id": 1,
        "result": {"content": [{"type": "text", "text": _wrap_http_resp(payload)}]},
    }


def _ok_notify_resp() -> Dict[str, Any]:
    return {
        "jsonrpc": "2.0", "id": 1,
        "result": {"content": [{"type": "text", "text": _wrap_http_resp({})}]},
    }


class TestUploadAttachment(unittest.TestCase):
    def setUp(self) -> None:
        self._tmpdir = tempfile.mkdtemp(prefix="upload_attachment_ut_")
        self.pdf_path = os.path.join(self._tmpdir, "a.pdf")
        self.docx_path = os.path.join(self._tmpdir, "b.docx")
        _make_pdf(self.pdf_path)
        _make_docx(self.docx_path)
        self.put_calls: List[Dict[str, Any]] = []

    def tearDown(self) -> None:
        for root, _dirs, files in os.walk(self._tmpdir, topdown=False):
            for fn in files:
                try:
                    os.remove(os.path.join(root, fn))
                except OSError:
                    pass
            try:
                os.rmdir(root)
            except OSError:
                pass

    def _fake_put(self, cos_url: str, put_auth: str, path: str, md5_hex: str) -> None:
        self.put_calls.append(
            {"cos_url": cos_url, "put_auth": put_auth, "path": path, "md5": md5_hex}
        )

    def _fake_put_fail(self, *args: Any, **kwargs: Any) -> None:
        raise RuntimeError("网络不通")

    # ---- happy path ----

    def test_upload_all_success(self):
        proxy = _FakeProxy({
            "meeting_attachment_upload_auth": [
                _ok_auth_resp("fid_1"), _ok_auth_resp("fid_2"),
            ],
            "meeting_attachment_upload_notify": [
                _ok_notify_resp(), _ok_notify_resp(),
            ],
        })
        res = upload_attachment.upload_attachments(
            proxy, [self.pdf_path, self.docx_path], put_cos=self._fake_put,
        )
        self.assertEqual(len(res["uploaded"]), 2)
        self.assertEqual(res["failures"], [])
        self.assertEqual({u["file_id"] for u in res["uploaded"]}, {"fid_1", "fid_2"})
        # PUT 直传被调用两次
        self.assertEqual(len(self.put_calls), 2)
        # upload-auth 2 次 + upload-notify 2 次
        self.assertEqual(len(proxy.calls), 4)
        # notify 入参只带 file_id，不再携带 file_state（仅成功路径才会调用）
        notify_calls = [c for c in proxy.calls
                        if c["params"].get("name") == "meeting_attachment_upload_notify"]
        for c in notify_calls:
            args = c["params"]["arguments"]
            self.assertIn("file_id", args)
            self.assertNotIn("file_state", args)
        # 验证 upload-auth 参数里 file_type 按扩展名透传
        auth_calls = [c for c in proxy.calls
                      if c["params"].get("name") == "meeting_attachment_upload_auth"]
        file_types = {c["params"]["arguments"]["file_type"] for c in auth_calls}
        self.assertEqual(file_types, {"pdf", "docx"})

    def test_upload_sends_required_file_crc64(self):
        """upload-auth 入参必须携带非空 file_crc64 字段（业务侧要求必填）。"""
        proxy = _FakeProxy({
            "meeting_attachment_upload_auth": [_ok_auth_resp("fid_c")],
            "meeting_attachment_upload_notify": [_ok_notify_resp()],
        })
        res = upload_attachment.upload_attachments(
            proxy, [self.pdf_path], put_cos=self._fake_put,
        )
        self.assertEqual(len(res["uploaded"]), 1)
        auth_calls = [c for c in proxy.calls
                      if c["params"].get("name") == "meeting_attachment_upload_auth"]
        self.assertEqual(len(auth_calls), 1)
        args_sent = auth_calls[0]["params"]["arguments"]
        self.assertIn("file_crc64", args_sent)
        self.assertTrue(args_sent["file_crc64"],
                        "file_crc64 不能为空字符串")
        # crc64 必须是 10 进制字符串
        self.assertTrue(args_sent["file_crc64"].isdigit(),
                        f"file_crc64 应为十进制字符串，实际为 {args_sent['file_crc64']!r}")

    def test_crc64_matches_go_hash_crc64_ecma(self):
        """CRC64-ECMA 实现必须与 Go hash/crc64.ECMA 等价（标准测试向量）。"""
        # Go hash/crc64.ECMA.Checksum([]byte("123456789"), t) == 0x995DC9BBDF1939FA
        self.assertEqual(upload_attachment._crc64_ecma(b"123456789"),
                         0x995DC9BBDF1939FA)
        # 空输入 => 0
        self.assertEqual(upload_attachment._crc64_ecma(b""), 0)

    # ---- preflight ----

    def test_empty_paths_raises(self):
        proxy = _FakeProxy({})
        with self.assertRaises(ValueError):
            upload_attachment.upload_attachments(proxy, [], put_cos=self._fake_put)

    def test_too_many_paths_raises(self):
        proxy = _FakeProxy({})
        many = [self.pdf_path] * (upload_attachment.MAX_ATTACHMENT_COUNT + 1)
        with self.assertRaises(ValueError) as ctx:
            upload_attachment.upload_attachments(proxy, many, put_cos=self._fake_put)
        self.assertIn("个数", str(ctx.exception))

    def test_total_bytes_over_limit(self):
        # 临时将上限调小来触发总量超限
        orig = upload_attachment.MAX_TOTAL_BYTES
        orig_single = upload_attachment.MAX_SINGLE_BYTES
        upload_attachment.MAX_TOTAL_BYTES = 10
        # 单文件上限也要同步调大，避免被 preflight 先以"单文件超限"挡下
        upload_attachment.MAX_SINGLE_BYTES = 10 * 1024 * 1024
        try:
            proxy = _FakeProxy({})
            with self.assertRaises(ValueError) as ctx:
                upload_attachment.upload_attachments(
                    proxy, [self.pdf_path], put_cos=self._fake_put,
                )
            self.assertIn("总大小", str(ctx.exception))
        finally:
            upload_attachment.MAX_TOTAL_BYTES = orig
            upload_attachment.MAX_SINGLE_BYTES = orig_single

    def test_missing_file_returned_as_failure(self):
        proxy = _FakeProxy({
            # 只会为 pdf 调用一次 upload-auth / notify
            "meeting_attachment_upload_auth": [_ok_auth_resp("fid_1")],
            "meeting_attachment_upload_notify": [_ok_notify_resp()],
        })
        ghost = os.path.join(self._tmpdir, "ghost.pdf")
        res = upload_attachment.upload_attachments(
            proxy, [self.pdf_path, ghost], put_cos=self._fake_put,
        )
        self.assertEqual(len(res["uploaded"]), 1)
        self.assertEqual(len(res["failures"]), 1)
        self.assertEqual(res["failures"][0]["path"], ghost)

    def test_preflight_accepts_any_extension(self):
        """前置校验已去除文件类型校验：后缀与内容不一致、非白名单后缀的文件均应正常上传。

        本用例涵盖本次需求变更的核心语义：本地不再做文件类型校验，由服务端对 file_type
        做最终白名单兜底。file_type 按扩展名透传（无扩展名时为空串）。
        """
        # 后缀为 .docx 但内容为 pdf
        fake_docx = os.path.join(self._tmpdir, "evil.docx")
        _make_pdf(fake_docx)
        # 后缀为 .txt（不在之前的白名单内）
        plain_txt = os.path.join(self._tmpdir, "readme.txt")
        with open(plain_txt, "wb") as f:
            f.write(b"hello world")
        # 无扩展名
        no_ext = os.path.join(self._tmpdir, "noext")
        with open(no_ext, "wb") as f:
            f.write(b"hello")

        proxy = _FakeProxy({
            "meeting_attachment_upload_auth": [
                _ok_auth_resp("fid_a"), _ok_auth_resp("fid_b"), _ok_auth_resp("fid_c"),
            ],
            "meeting_attachment_upload_notify": [
                _ok_notify_resp(), _ok_notify_resp(), _ok_notify_resp(),
            ],
        })
        res = upload_attachment.upload_attachments(
            proxy, [fake_docx, plain_txt, no_ext], put_cos=self._fake_put,
        )
        self.assertEqual(len(res["uploaded"]), 3)
        self.assertEqual(res["failures"], [])
        # file_type 完全按扩展名透传；无扩展名时为空串
        auth_calls = [c for c in proxy.calls
                      if c["params"].get("name") == "meeting_attachment_upload_auth"]
        file_types = [c["params"]["arguments"]["file_type"] for c in auth_calls]
        self.assertEqual(sorted(file_types), sorted(["docx", "txt", ""]))

    # ---- upload-auth 响应缺字段 ----

    def test_auth_response_missing_fields(self):
        bad_auth = {
            "jsonrpc": "2.0", "id": 1,
            # 业务 body 为 "{}"：HTTP 200 但缺 file_id / cos_url
            "result": {"content": [{"type": "text",
                                     "text": _wrap_http_resp({})}]},
        }
        proxy = _FakeProxy({
            "meeting_attachment_upload_auth": [bad_auth],
        })
        res = upload_attachment.upload_attachments(
            proxy, [self.pdf_path], put_cos=self._fake_put,
        )
        self.assertEqual(res["uploaded"], [])
        self.assertEqual(len(res["failures"]), 1)
        self.assertIn("必要字段", res["failures"][0]["reason"])
        # 没有触发 PUT
        self.assertEqual(self.put_calls, [])

    # ---- PUT 直传失败 → 不再回传失败状态，不调用 notify ----

    def test_put_cos_failure_does_not_notify(self):
        """直传失败时 upload-notify 不应被调用（悬挂 file_id 由服务端超时回收）。"""
        proxy = _FakeProxy({
            "meeting_attachment_upload_auth": [_ok_auth_resp("fid_fail")],
            # 故意不为 notify 准备响应：一旦误调用，_FakeProxy 会抛 AssertionError
        })
        res = upload_attachment.upload_attachments(
            proxy, [self.pdf_path], put_cos=self._fake_put_fail,
        )
        self.assertEqual(res["uploaded"], [])
        self.assertEqual(len(res["failures"]), 1)
        self.assertIn("直传", res["failures"][0]["reason"])
        # 不应有任何 notify 调用
        notify_calls = [c for c in proxy.calls
                        if c["params"].get("name") == "meeting_attachment_upload_notify"]
        self.assertEqual(notify_calls, [])

    # ---- 远端错误 ----

    def test_remote_error_response(self):
        err_resp = {
            "jsonrpc": "2.0", "id": 1,
            "result": {"error": {"code": -32001, "message": "鉴权失败"}},
        }
        proxy = _FakeProxy({
            "meeting_attachment_upload_auth": [err_resp],
        })
        res = upload_attachment.upload_attachments(
            proxy, [self.pdf_path], put_cos=self._fake_put,
        )
        self.assertEqual(res["uploaded"], [])
        self.assertEqual(len(res["failures"]), 1)
        self.assertIn("鉴权失败", res["failures"][0]["reason"])

    # ---- 本地校验失败（文件为空） ----

    def test_local_validation_failure(self):
        empty_path = os.path.join(self._tmpdir, "empty.pdf")
        open(empty_path, "wb").close()  # 0 字节
        proxy = _FakeProxy({})  # 不应产生任何远端调用
        res = upload_attachment.upload_attachments(
            proxy, [empty_path], put_cos=self._fake_put,
        )
        self.assertEqual(res["uploaded"], [])
        self.assertEqual(len(res["failures"]), 1)
        # preflight 仅保留存在性/非空/大小/总量类校验；空文件被挡下
        self.assertIn("文件为空", res["failures"][0]["reason"])
        self.assertEqual(proxy.calls, [])
        self.assertEqual(self.put_calls, [])

    # ---- cos_url / put_auth URL 百分号编码场景 ----

    def test_cos_url_percent_encoded_is_decoded(self):
        """服务端返回的 cos_url / put_auth 可能是 URL-encoded（如 'https%3A%2F%2F...'）。

        _upload_one 必须在交给 put_cos 之前 unquote 解码，否则 urllib 会抛
        'unknown url type' 错误。本用例回归现网实际故障。
        """
        import json as _json
        import urllib.parse as _up

        raw_url = (
            "https://wemeet-attachment-1258344699.cos.ap-guangzhou.myqcloud.com"
            "/123/abc/def/9709/646425397134653097.xlsx"
        )
        raw_put_auth = (
            "q-sign-algorithm=sha1&q-ak=AKID&q-sign-time=1&q-key-time=1"
            "&q-header-list=&q-url-param-list=&q-signature=deadbeef"
        )
        encoded_auth_payload = {
            "file_id": "fid_enc",
            "cos_url": _up.quote(raw_url, safe=""),
            "cos_auth_info": {"put_auth": _up.quote(raw_put_auth, safe="")},
        }
        encoded_auth_resp = {
            "jsonrpc": "2.0", "id": 1,
            "result": {"content": [{"type": "text",
                                     "text": _wrap_http_resp(encoded_auth_payload)}]},
        }
        proxy = _FakeProxy({
            "meeting_attachment_upload_auth": [encoded_auth_resp],
            "meeting_attachment_upload_notify": [_ok_notify_resp()],
        })
        res = upload_attachment.upload_attachments(
            proxy, [self.pdf_path], put_cos=self._fake_put,
        )
        self.assertEqual(len(res["uploaded"]), 1)
        self.assertEqual(res["failures"], [])
        # put_cos 收到的参数必须是解码后的原始形态
        self.assertEqual(len(self.put_calls), 1)
        self.assertEqual(self.put_calls[0]["cos_url"], raw_url)
        self.assertEqual(self.put_calls[0]["put_auth"], raw_put_auth)

    def test_cos_url_plain_is_passed_through(self):
        """未经编码的 cos_url / put_auth 经过 unquote 应保持不变（幂等）。"""
        proxy = _FakeProxy({
            "meeting_attachment_upload_auth": [_ok_auth_resp("fid_plain")],
            "meeting_attachment_upload_notify": [_ok_notify_resp()],
        })
        res = upload_attachment.upload_attachments(
            proxy, [self.pdf_path], put_cos=self._fake_put,
        )
        self.assertEqual(len(res["uploaded"]), 1)
        self.assertEqual(len(self.put_calls), 1)
        self.assertEqual(self.put_calls[0]["cos_url"],
                         "https://cos.example.com/key/fid_plain")
        self.assertEqual(self.put_calls[0]["put_auth"], "q-sign-fid_plain")


if __name__ == "__main__":
    unittest.main()
