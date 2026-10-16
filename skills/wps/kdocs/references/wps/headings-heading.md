# headings · heading

<a id="heading-table"></a>
## wps.headings.heading_table

#### 功能说明

按标题章节插入完整表格（TABLE）：表题 + 表头 + 数据行 + 边框。

**幂等性**：否 — unsafe

#### 调用示例

标题章节末尾插入表格：

```json
{
  "file_id": "<FILE_ID>",
  "heading_text": "SmokeHeadingSlice",
  "position": "HEADING_END",
  "rows": 3,
  "cols": 3,
  "table_full_data": {
    "caption": "示例表题",
    "headers": [
      "列1",
      "列2",
      "列3"
    ],
    "rows": [
      {
        "cells": [
          "a",
          "b",
          "c"
        ]
      }
    ]
  }
}
```

#### 参数说明

- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id；与 url、link_id 三选一
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id；与 url、file_id 三选一
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL；与 link_id、file_id 三选一
- `heading_text` (string, 必填): 锚点标题文本（子串匹配）
- `position` (string, 可选): 插入位置：HEADING_END(章节末尾,缺省) / HEADING_BEGIN(章节开头) / HEADING_BEFORE(锚点标题之前)。可选值：`HEADING_BEFORE` / `HEADING_BEGIN` / `HEADING_END`
- `rows` (number, 必填): 表格行数（>=1）
- `cols` (number, 必填): 表格列数（>=1）
- `table_full_data` (object, 必填): 完整表格数据：{caption?, headers?:[...], rows?:[{cells:[...]}], enable_borders?}

#### 返回值说明

```json
{
  "code": 0,
  "message": "成功",
  "data": {
    "heading_index": 42,
    "table_index": 3,
    "table_rows": 3,
    "table_cols": 3
  }
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `code` | number | 0 表示成功 |
| `data` | object | 业务数据 |
| `message` | string | 结果说明 |


---

<a id="heading-delete"></a>
## wps.headings.heading_delete

#### 功能说明

按标题删除整节（HEADING_DELETE）：标题段 + 其下全部内容，保留下一同级标题。

#### 调用示例

文档删除：

```json
{
  "file_id": "<FILE_ID>",
  "heading_text": "SmokeHeadingSlice"
}
```

#### 参数说明

- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id；与 url、link_id 三选一
- `heading_text` (string, 必填): 锚点标题文本（子串匹配）
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id；与 url、file_id 三选一
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL；与 link_id、file_id 三选一

#### 返回值说明

```json
{
  "code": 0,
  "message": "成功",
  "data": {
    "deleted_paragraph_count": 1,
    "success": true
  }
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `code` | number | 0 表示成功 |
| `data` | object | 业务数据 |
| `message` | string | 结果说明 |


---

<a id="heading-meta"></a>
## wps.headings.heading_meta

#### 功能说明

按标题文本定位章节（HEADING_META）：返回标题段号/级别/章节起止段号，可选返回该节全部文本或章节树。

#### 调用示例

文档查询：

```json
{
  "file_id": "<FILE_ID>",
  "heading_text": "SmokeHeadingSlice",
  "properties": []
}
```

#### 参数说明

- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id；与 url、link_id 三选一
- `heading_text` (string, 必填): 锚点标题文本（子串匹配，取第一个命中）
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id；与 url、file_id 三选一
- `properties` (array, 可选): 返回内容：HEADING_META(位置,缺省) / HEADING_TEXT(该节文本) / HEADING_ALL(章节树)
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL；与 link_id、file_id 三选一

#### 返回值说明

```json
{
  "code": 0,
  "message": "成功",
  "data": {
    "heading_paragraph_index": 28,
    "heading_level": 1,
    "section_start": 28,
    "section_end": 28,
    "heading_text": "SmokeHeadingSlice",
    "found": true
  }
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `code` | number | 0 表示成功 |
| `data` | object | 业务数据 |
| `message` | string | 结果说明 |


---

<a id="heading-text"></a>
## wps.headings.heading_text

#### 功能说明

按标题章节插入文本（HEADING_TEXT）：默认章节末尾，支持章节开头/锚点标题之前。

#### 调用示例

文档插入：

```json
{
  "file_id": "<FILE_ID>",
  "heading_level": 1,
  "heading_text": "SmokeHeadingSlice",
  "position": "after",
  "text": "smoke example text"
}
```

#### 参数说明

- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id；与 url、link_id 三选一
- `heading_level` (number, 可选): 新段若为标题，设级别（0=正文,1-9=Heading）
- `heading_text` (string, 必填): 锚点标题文本（子串匹配）
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id；与 url、file_id 三选一
- `position` (string, 可选): 插入位置：HEADING_END(章节末尾,缺省) / HEADING_BEGIN(章节开头) / HEADING_BEFORE(锚点标题之前)。可选值：`HEADING_BEFORE` / `HEADING_BEGIN` / `HEADING_END`
- `text` (string, 必填): 要插入的文本
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL；与 link_id、file_id 三选一

#### 返回值说明

```json
{
  "code": 0,
  "message": "成功",
  "data": {
    "paragraph_index": 28,
    "begin": 611,
    "end": 630
  }
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `code` | number | 0 表示成功 |
| `data` | object | 业务数据 |
| `message` | string | 结果说明 |


---

<a id="heading-text-batch"></a>
## wps.headings.heading_text_batch

#### 功能说明

按标题章节批量插入文本（HEADING_TEXT）：一次多条，各带格式，用于长文分批写入。

#### 调用示例

文档插入：

```json
{
  "file_id": "<FILE_ID>",
  "items": [
    {
      "heading_text": "SmokeHeadingSlice",
      "text": "smoke batch heading text",
      "heading_level": 1
    }
  ]
}
```

#### 参数说明

- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id；与 url、link_id 三选一
- `items` (array, 必填): 待插入条目数组：[{heading_text, text, position?, heading_level?}]
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id；与 url、file_id 三选一
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL；与 link_id、file_id 三选一

#### 返回值说明

```json
{
  "code": 0,
  "message": "成功",
  "data": {
    "items": [
      {"paragraph_index": 28, "begin": 611, "end": 635}
    ]
  }
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `code` | number | 0 表示成功 |
| `data` | object | 业务数据 |
| `message` | string | 结果说明 |


