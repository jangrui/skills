# wps.footnote_endnotes.endnote_data

#### 功能说明

在线文字文档尾注数据：支持 删除/查询。

**幂等性**：是 — safe

#### 支持功能

> 表中「操作范围 / 操作类型」即请求 JSON 的 `scope`、`verb` 字段取值。

| 功能简述 | 操作范围（`scope`） | 操作类型（`verb`） |
|----------|---------------------|--------------------|
| [删除尾注数据](#wps-footnote-endnotes-endnote-data-documents-delete) | documents | delete |
| [查询尾注数据](#wps-footnote-endnotes-endnote-data-documents-query) | documents | query |

---

<a id="wps-footnote-endnotes-endnote-data-documents-delete"></a>

## 删除尾注数据

#### 功能说明

删除尾注数据

**幂等性**：是 — safe

> *_all delete 会清空对应类型，之后 *_data delete 会 not found。

#### 调用示例

文档删除：

```json
{
  "file_id": "<FILE_ID>",
  "index": 1,
  "verb": "delete"
}
```

#### 参数说明

- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id；与 url、link_id 三选一
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id；与 url、file_id 三选一
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL；与 link_id、file_id 三选一
- `verb` (string, 必填): 操作类型，固定为 delete（删除）。可选值：`delete`
- `index` (number, 可选): 索引，从 1 开始

#### 返回值说明

```json
{
  "code": 0,
  "message": "成功",
  "data": {
    "deleted_count": 1
  }
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `code` | number | 0 表示成功 |
| `data` | object | 业务数据 |
| `message` | string | 结果说明 |


---

<a id="wps-footnote-endnotes-endnote-data-documents-query"></a>

## 查询尾注数据

#### 功能说明

查询尾注数据

**幂等性**：是 — safe

> 返回的 begin/end 为尾注引用标记在正文中的 0-based 字符位置，可直接回填到 wps.footnote_endnotes.endnote_by_range 的 range（begin/end）。

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
- `index` (number, 可选): 索引，从 1 开始

#### 返回值说明

```json
{
  "code": 0,
  "message": "成功",
  "data": {
    "item": {
      "begin": 33,
      "end": 34,
      "index": 1,
      "reference": "",
      "text": "smoke endnote",
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

