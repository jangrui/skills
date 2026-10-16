# wps.shapes.z_order

#### 功能说明

在线文字文档形状叠放次序：支持 设置/查询（查询返回 ZOrderPosition 数字串，支持 "a.b" 嵌套 shape_item）。

**幂等性**：是 — safe

> 形状置顶场景见 `references/workflows/wps-shapes-draw-compose.md`。

#### 支持功能

> 表中「操作范围 / 操作类型」即请求 JSON 的 `scope`、`verb` 字段取值。

| 功能简述 | 操作范围（`scope`） | 操作类型（`verb`） |
|----------|---------------------|--------------------|
| [查询形状 ZOrderPosition](#wps-shapes-z-order-documents-query) | documents | query |
| [设置形状的叠放次序](#wps-shapes-z-order-documents-update) | documents | update |

---

<a id="wps-shapes-z-order-documents-query"></a>

## 查询形状 ZOrderPosition

#### 功能说明

查询形状 ZOrderPosition

**幂等性**：是 — safe

#### 调用示例

文档查询：

```json
{
  "file_id": "<FILE_ID>",
  "shape_item": "10.1",
  "verb": "query"
}
```

#### 参数说明

- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id；与 url、link_id 三选一
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id；与 url、file_id 三选一
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL；与 link_id、file_id 三选一
- `verb` (string, 必填): 操作类型，固定为 query（查询）。可选值：`query`
- `shape_item` (string, 可选): shape item（支持 "a.b" 嵌套路径，如 "10.1"）

#### 返回值说明

```json
{
  "code": 0,
  "message": "成功",
  "data": {
    "info": {
      "index": 10,
      "name": "AutoShape 83",
      "shape_item": "10.1",
      "type": 1,
      "z_order_position": 2
    }
  }
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `code` | number | 0 表示成功 |
| `data` | object | 业务数据 |
| `message` | string | 结果说明 |


---

<a id="wps-shapes-z-order-documents-update"></a>

## 设置形状的叠放次序

#### 功能说明

设置形状的叠放次序

**幂等性**：是 — safe

#### 调用示例

文档设置：

```json
{
  "file_id": "<FILE_ID>",
  "shape_item": "3",
  "zorder": "msoBringToFront"
}
```

#### 参数说明

- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id；与 url、link_id 三选一
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id；与 url、file_id 三选一
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL；与 link_id、file_id 三选一
- `verb` (string, 必填): HTTP 动作：query（查询 ZOrderPosition）/ update（设置叠放次序）。可选值：`query` / `update`
- `shape_item` (string, 可选): shape item
- `zorder` (string, 可选): 叠放次序：msoBringToFront / msoSendToBack / msoBringForward / msoSendBackward。可选值：`msoBringToFront` / `msoSendToBack` / `msoBringForward` / `msoSendBackward`

#### 返回值说明

```json
{
  "code": 0,
  "message": "成功",
  "data": {
    "info": {
      "index": 3,
      "name": "Rectangle 7",
      "type": 1
    }
  }
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `code` | number | 0 表示成功 |
| `data` | object | 业务数据 |
| `message` | string | 结果说明 |

