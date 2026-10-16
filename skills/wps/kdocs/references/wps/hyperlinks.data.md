# wps.hyperlinks.data

#### 功能说明

在线文字文档超链接数据：支持删除/查询。

**幂等性**：是 — safe

#### 支持功能

> 表中「操作范围 / 操作类型」即请求 JSON 的 `scope`、`verb` 字段取值。

| 功能简述 | 操作范围（`scope`） | 操作类型（`verb`） |
|----------|---------------------|--------------------|
| [删除整篇文档的超链接数据](#wps-hyperlinks-data-documents-delete) | documents | delete |
| [查询超链接数据](#wps-hyperlinks-data-documents-query) | documents | query |

---

<a id="wps-hyperlinks-data-documents-delete"></a>

## 删除整篇文档的超链接数据

#### 功能说明

删除整篇文档的超链接数据

**幂等性**：是 — safe

> delete 的 index 来自 wps.hyperlinks.list（1-based）；先 insert 再测删除。
> data delete 删一条；勿在 wps.hyperlinks.all delete 之后再测单条 delete。

#### 调用示例

文档删除：

```json
{
  "file_id": "<FILE_ID>",
  "index": 1,
  "is_del_text": true,
  "verb": "delete"
}
```

#### 参数说明

- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id；与 url、link_id 三选一
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id；与 url、file_id 三选一
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL；与 link_id、file_id 三选一
- `verb` (string, 必填): 操作类型，固定为 delete（删除）。可选值：`delete`
- `index` (number, 必填): 索引，从 1 开始
- `is_del_text` (boolean, 可选): 删除超链接时是否同时删除文本

#### 返回值说明

```json
{
  "code": 0,
  "message": "成功",
  "data": {}
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `code` | number | 0 表示成功 |
| `data` | object | 业务数据 |
| `message` | string | 结果说明 |


---

<a id="wps-hyperlinks-data-documents-query"></a>

## 查询超链接数据

#### 功能说明

查询超链接数据

**幂等性**：是 — safe

#### 调用示例

文档查询：

```json
{
  "file_id": "<FILE_ID>",
  "index": 1,
  "verb": "query"
}
```

#### 参数说明

- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id；与 url、link_id 三选一
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id；与 url、file_id 三选一
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL；与 link_id、file_id 三选一
- `verb` (string, 必填): 操作类型，固定为 query（查询）。可选值：`query`
- `index` (number, 必填): 索引，从 1 开始

#### 返回值说明

```json
{
  "code": 0,
  "message": "成功",
  "data": {
    "hyperlink": {
      "address": "https://example.com/smoke",
      "begin": 0,
      "display_text": "smoke link",
      "end": 52,
      "index": 1,
      "sub_address": "",
      "type": 0
    }
  }
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `code` | number | 0 表示成功 |
| `data` | object | 业务数据 |
| `message` | string | 结果说明 |

