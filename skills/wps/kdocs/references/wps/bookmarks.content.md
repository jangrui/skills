# wps.bookmarks.content

#### 功能说明

在线文字文档书签内容：支持查询/设置。

**幂等性**：是 — safe

#### 支持功能

> 表中「操作范围 / 操作类型」即请求 JSON 的 `scope`、`verb` 字段取值。

| 功能简述 | 操作范围（`scope`） | 操作类型（`verb`） |
|----------|---------------------|--------------------|
| [查询整篇文档的书签内容](#wps-bookmarks-content-documents-query) | documents | query |
| [更新整篇文档的书签内容](#wps-bookmarks-content-documents-update) | documents | update |

---

<a id="wps-bookmarks-content-documents-query"></a>

## 查询整篇文档的书签内容

#### 功能说明

查询整篇文档的书签内容

**幂等性**：是 — safe

#### 调用示例

文档查询：

```json
{
  "file_id": "<FILE_ID>",
  "bookmark_name": "SmokeBookmark_0903",
  "verb": "query"
}
```

#### 参数说明

- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id；与 url、link_id 三选一
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id；与 url、file_id 三选一
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL；与 link_id、file_id 三选一
- `verb` (string, 必填): 操作类型，固定为 query（查询）。可选值：`query`
- `bookmark_name` (string, 必填): 书签名称

#### 返回值说明

```json
{
  "code": 0,
  "message": "成功",
  "data": {
    "bookmark_name": "SmokeBookmark_0903",
    "end": 32,
    "text": "2026/9/3smoke example textsmoke\r"
  }
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `code` | number | 0 表示成功 |
| `data` | object | 业务数据 |
| `message` | string | 结果说明 |


---

<a id="wps-bookmarks-content-documents-update"></a>

## 更新整篇文档的书签内容

#### 功能说明

更新整篇文档的书签内容

**幂等性**：是 — safe

#### 调用示例

文档设置：

```json
{
  "file_id": "<FILE_ID>",
  "bookmark_name": "SmokeBookmark_0903",
  "text": "smoke example text",
  "verb": "update"
}
```

#### 参数说明

- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id；与 url、link_id 三选一
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id；与 url、file_id 三选一
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL；与 link_id、file_id 三选一
- `verb` (string, 必填): 操作类型，固定为 update（更新）。可选值：`update`
- `bookmark_name` (string, 必填): 书签名称
- `text` (string, 可选): 替换后的书签文本

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

