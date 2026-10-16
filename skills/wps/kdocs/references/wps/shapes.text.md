# wps.shapes.text

#### 功能说明

在线文字文档形状文本：支持 查询/设置。

**幂等性**：是 — safe

#### 支持功能

> 表中「操作范围 / 操作类型」即请求 JSON 的 `scope`、`verb` 字段取值。

| 功能简述 | 操作范围（`scope`） | 操作类型（`verb`） |
|----------|---------------------|--------------------|
| [查询形状文本](#wps-shapes-text-documents-query) | documents | query |
| [设置形状文本](#wps-shapes-text-documents-update) | documents | update |

---

<a id="wps-shapes-text-documents-query"></a>

## 查询形状文本

#### 功能说明

查询形状文本

**幂等性**：是 — safe

#### 调用示例

文档查询：

```json
{
  "file_id": "<FILE_ID>",
  "shape_item": "5",
  "verb": "query"
}
```

#### 参数说明

- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id；与 url、link_id 三选一
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id；与 url、file_id 三选一
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL；与 link_id、file_id 三选一
- `verb` (string, 必填): 操作类型，固定为 query（查询）。可选值：`query`
- `shape_item` (string, 可选): shape item

#### 返回值说明

```json
{
  "code": 0,
  "message": "成功",
  "data": {
    "text": "\r"
  }
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `code` | number | 0 表示成功 |
| `data` | object | 业务数据 |
| `message` | string | 结果说明 |


---

<a id="wps-shapes-text-documents-update"></a>

## 设置形状文本

#### 功能说明

设置形状文本

**幂等性**：是 — safe

> 文本类 update 应用 wps.shapes.list 中文本框类型（type=17）的 shape_item。

#### 调用示例

文档设置：

```json
{
  "file_id": "<FILE_ID>",
  "verb": "update",
  "shape_item": "6",
  "text": "smoke example text"
}
```

#### 参数说明

- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id；与 url、link_id 三选一
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id；与 url、file_id 三选一
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL；与 link_id、file_id 三选一
- `verb` (string, 必填): 操作类型，固定为 update（更新）。可选值：`update`
- `shape_item` (string, 可选): shape item
- `text` (string, 可选): 文本内容

#### 返回值说明

```json
{
  "code": 0,
  "message": "成功",
  "data": {
    "info": {
      "index": 4,
      "name": "TextBox 6",
      "text": "smoke example text\r",
      "type": 17
    }
  }
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `code` | number | 0 表示成功 |
| `data` | object | 业务数据 |
| `message` | string | 结果说明 |

