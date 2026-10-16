# wps.texts.content

#### 功能说明

在线文字文档文本内容：支持查询/插入/设置/删除。url、link_id、file_id 至少填一个。

**幂等性**：是 — safe

> A/C gap: documents insert/delete TEXT_CONTENT

#### 支持功能

> 表中「操作范围 / 操作类型」即请求 JSON 的 `scope`、`verb` 字段取值。

| 功能简述 | 操作范围（`scope`） | 操作类型（`verb`） |
|----------|---------------------|--------------------|
| [按文档删除文本内容](#wps-texts-content-documents-delete) | documents | delete |
| [按文档插入文本内容](#wps-texts-content-documents-insert) | documents | insert |
| [按文档查询文本内容](#wps-texts-content-documents-query) | documents | query |
| [按段落插入文本内容](#wps-texts-content-paragraphs-insert) | paragraphs | insert |
| [按段落查询文本内容](#wps-texts-content-paragraphs-query) | paragraphs | query |
| [按段落设置文本内容](#wps-texts-content-paragraphs-update) | paragraphs | update |
| [按字符区间插入文本内容](#wps-texts-content-ranges-insert) | ranges | insert |
| [按字符区间设置文本内容](#wps-texts-content-ranges-update) | ranges | update |

---

<a id="wps-texts-content-documents-delete"></a>

## 按文档删除文本内容

#### 功能说明

按文档删除文本内容

**幂等性**：是 — safe

> A/C gap: documents insert/delete TEXT_CONTENT

#### 调用示例

文档删除：

```json
{
  "file_id": "<FILE_ID>",
  "scope": "documents",
  "verb": "delete"
}
```

#### 参数说明

- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id；与 url、link_id 三选一
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id；与 url、file_id 三选一
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL；与 link_id、file_id 三选一
- `scope` (string, 必填): 操作范围，固定为 documents（按文档设置）。可选值：`documents`
- `verb` (string, 必填): 操作类型，固定为 delete（删除）。可选值：`delete`

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

<a id="wps-texts-content-documents-insert"></a>

## 按文档插入文本内容

#### 功能说明

按文档插入文本内容

**幂等性**：是 — safe

> A/C gap: documents insert/delete TEXT_CONTENT

#### 调用示例

文档插入：

```json
{
  "file_id": "<FILE_ID>",
  "scope": "documents",
  "verb": "insert",
  "is_br": true,
  "text": "smoke example text"
}
```

#### 参数说明

- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id；与 url、link_id 三选一
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id；与 url、file_id 三选一
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL；与 link_id、file_id 三选一
- `scope` (string, 必填): 操作范围，固定为 documents（按文档设置）。可选值：`documents`
- `verb` (string, 必填): 操作类型，固定为 insert（插入）。可选值：`insert`
- `is_br` (boolean, 可选): 是否插入换行
- `text` (string, 可选): 待插入文本

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

<a id="wps-texts-content-documents-query"></a>

## 按文档查询文本内容

#### 功能说明

按文档查询文本内容

**幂等性**：是 — safe

> A/C gap: documents insert/delete TEXT_CONTENT

#### 调用示例

文档查询：

```json
{
  "file_id": "<FILE_ID>",
  "scope": "documents",
  "verb": "query"
}
```

#### 参数说明

- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id；与 url、link_id 三选一
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id；与 url、file_id 三选一
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL；与 link_id、file_id 三选一
- `scope` (string, 必填): 操作范围，固定为 documents（按文档设置）。可选值：`documents`
- `verb` (string, 必填): 操作类型，固定为 query（查询）。可选值：`query`

#### 返回值说明

```json
{
  "code": 0,
  "message": "成功",
  "data": {
    "content": "SMOKE_SLICE_ANCHOR_2026-09-03 baseline paragraph for slice smoke examples.\r\r\u0007\r\u0007\r\u0007\r\u0007\r\u0007\r\u0007\r\u0007\r\u0007\r\u0007\r\u0007\r\u0007\r\u0007\r"
  }
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `code` | number | 0 表示成功 |
| `data` | object | 业务数据 |
| `message` | string | 结果说明 |


---

<a id="wps-texts-content-paragraphs-insert"></a>

## 按段落插入文本内容

#### 功能说明

按段落插入文本内容

**幂等性**：是 — safe

> A/C gap: documents insert/delete TEXT_CONTENT
> 必须传 position（before/after）；缺失时报 unresolved placeholder in rendered js。
> position=after 为行内追加语义：文本追加在目标段落末尾，不会新起段落（TC_137 教训）；若需要新起段落，请改用 wps.texts.content ranges_insert 并在文本中带 \r（回车）作为段落分隔。

#### 调用示例

段落插入：

```json
{
  "file_id": "<FILE_ID>",
  "scope": "paragraphs",
  "verb": "insert",
  "paragraph_index": 1,
  "position": "after",
  "text": "smoke example text"
}
```

#### 参数说明

- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id；与 url、link_id 三选一
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id；与 url、file_id 三选一
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL；与 link_id、file_id 三选一
- `scope` (string, 必填): 操作范围，固定为 paragraphs（按段落设置）。可选值：`paragraphs`
- `verb` (string, 必填): 操作类型，固定为 insert（插入）。可选值：`insert`
- `paragraph_index` (number, 可选): 段落索引，从 1 开始
- `position` (string, 可选): 插入位置：before/after
- `text` (string, 可选): 待插入文本

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

<a id="wps-texts-content-paragraphs-query"></a>

## 按段落查询文本内容

#### 功能说明

按段落查询文本内容

> 按段落索引（1-based）查询段落文本内容；若返回空或文档含表格/复杂结构，可配合 wps.texts.count / wps.texts.range 定位。

#### 调用示例

段落查询：

```json
{
  "file_id": "<FILE_ID>",
  "scope": "paragraphs",
  "verb": "query",
  "paragraph_index": 1
}
```

#### 参数说明

- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id；与 url、link_id 三选一
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id；与 url、file_id 三选一
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL；与 link_id、file_id 三选一
- `scope` (string, 必填): 操作范围，固定为 paragraphs（按段落查询）。可选值：`paragraphs`
- `verb` (string, 必填): 操作类型，固定为 query（查询）。可选值：`query`
- `paragraph_index` (number, 可选): 段落索引，从 1 开始

#### 返回值说明

```json
{
  "code": 0,
  "message": "成功",
  "data": {
    "content": "SMOKE_SLICE_ANCHOR_2026-09-03 baseline paragraph for slice smoke examples.\r"
  }
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `code` | number | 0 表示成功 |
| `data` | object | 业务数据 |
| `message` | string | 结果说明 |


---

<a id="wps-texts-content-paragraphs-update"></a>

## 按段落设置文本内容

#### 功能说明

按段落设置文本内容

**幂等性**：是 — safe

> 写操作报 500002 且读操作正常时，先排查文档保护态（wps.protection.disable 后重试），再排查参数；不要盲目重试。
> A/C gap: documents insert/delete TEXT_CONTENT

#### 调用示例

段落设置：

```json
{
  "file_id": "<FILE_ID>",
  "scope": "paragraphs",
  "verb": "update",
  "content": "smoke example text",
  "paragraph_index": 1
}
```

#### 参数说明

- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id；与 url、link_id 三选一
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id；与 url、file_id 三选一
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL；与 link_id、file_id 三选一
- `scope` (string, 必填): 操作范围，固定为 paragraphs（按段落设置）。可选值：`paragraphs`
- `verb` (string, 必填): 操作类型，固定为 update（更新）。可选值：`update`
- `content` (string, 可选): 文本内容
- `paragraph_index` (number, 可选): 段落索引，从 1 开始

#### 返回值说明

```json
{
  "code": 0,
  "message": "成功",
  "data": {
    "content": "smoke example text"
  }
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `code` | number | 0 表示成功 |
| `data` | object | 业务数据 |
| `message` | string | 结果说明 |


---

<a id="wps-texts-content-ranges-insert"></a>

## 按字符区间插入文本内容

#### 功能说明

按字符区间插入文本内容

**幂等性**：是 — safe

> A/C gap: documents insert/delete TEXT_CONTENT
> begin 必须为正整数（≥1），传 0 报 begin must be a positive integer。

#### 调用示例

字符区间插入：

```json
{
  "file_id": "<FILE_ID>",
  "scope": "ranges",
  "verb": "insert",
  "begin": 1,
  "end": 12,
  "text": "smoke example text"
}
```

#### 参数说明

- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id；与 url、link_id 三选一
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id；与 url、file_id 三选一
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL；与 link_id、file_id 三选一
- `scope` (string, 必填): 操作范围，固定为 ranges（按字符区间设置）。可选值：`ranges`
- `verb` (string, 必填): 操作类型，固定为 insert（插入）。可选值：`insert`
- `begin` (number, 可选): 区间起始位置
- `end` (number, 可选): 区间结束位置
- `text` (string, 可选): 待插入文本

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

<a id="wps-texts-content-ranges-update"></a>

## 按字符区间设置文本内容

#### 功能说明

按字符区间设置文本内容

**幂等性**：是 — safe

> 写操作报 500002 且读操作正常时，先排查文档保护态（wps.protection.disable 后重试），再排查参数；不要盲目重试。
> begin/end 为 0-based 字符区间（与 wps.texts.search 返回的 ranges 同口径，可直接回填）；begin=0 表示文档首字符。
> A/C gap: documents insert/delete TEXT_CONTENT
> begin 必须为正整数（≥1），传 0 报 begin must be a positive integer。

#### 调用示例

字符区间设置：

```json
{
  "file_id": "<FILE_ID>",
  "scope": "ranges",
  "verb": "update",
  "begin": 1,
  "content": "smoke example text",
  "end": 12
}
```

#### 参数说明

- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id；与 url、link_id 三选一
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id；与 url、file_id 三选一
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL；与 link_id、file_id 三选一
- `scope` (string, 必填): 操作范围，固定为 ranges（按字符区间设置）。可选值：`ranges`
- `verb` (string, 必填): 操作类型，固定为 update（更新）。可选值：`update`
- `begin` (number, 可选): 区间起始位置（0-based 字符偏移，与 wps.texts.search 返回的 ranges 一致，可直接回填；0 表示文档首字符）
- `content` (string, 可选): 文本内容
- `end` (number, 可选): 区间结束位置（0-based 字符偏移，不含该字符；与 wps.texts.search 返回的 ranges 一致，可直接回填）

#### 返回值说明

```json
{
  "code": 0,
  "message": "成功",
  "data": {
    "content": "smoke example text"
  }
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `code` | number | 0 表示成功 |
| `data` | object | 业务数据 |
| `message` | string | 结果说明 |

