# wps.tocs.data

#### 功能说明

查询、插入或删除在线文字文档目录。

> 目录更新前文档须已有标题结构；删除目录用 documents/delete。

#### 支持功能

> 表中「操作范围 / 操作类型」即请求 JSON 的 `scope`、`verb` 字段取值。

| 功能简述 | 操作范围（`scope`） | 操作类型（`verb`） |
|----------|---------------------|--------------------|
| [按文档删除目录](#wps-tocs-data-documents-delete) | documents | delete |
| [按文档插入目录](#wps-tocs-data-documents-insert) | documents | insert |
| [按文档查询目录](#wps-tocs-data-documents-query) | documents | query |
| [按段落插入目录](#wps-tocs-data-paragraphs-insert) | paragraphs | insert |
| [按字符区间插入目录](#wps-tocs-data-ranges-insert) | ranges | insert |

---

<a id="wps-tocs-data-documents-delete"></a>

## 按文档删除目录

#### 功能说明

按文档删除目录

> all delete 清空后 data delete 会 not found；宜先测 data delete。

#### 调用示例

文档删除：

```json
{
  "file_id": "<FILE_ID>",
  "scope": "documents",
  "toc_index": 1,
  "verb": "delete"
}
```

#### 参数说明

- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL
- `scope` (string, 必填): 操作范围，固定为 documents（按文档设置）。可选值：`documents`
- `verb` (string, 必填): 操作类型，固定为 delete（删除）。可选值：`delete`
- `toc_index` (number, 可选): 目录索引

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

<a id="wps-tocs-data-documents-insert"></a>

## 按文档插入目录

#### 功能说明

按文档插入目录

> 须先 insert 目录再 query/update/delete；无目录时 query 报 tableOfContents not found。
> insert 需传 upper_level/lower_level 正整数，缺失报 upper_level must be a positive integer。
> insert 前先查 wps.tocs.count：已有目录（count>0）时应先用 wps.tocs.data verb=delete 删除旧目录再插入，否则会叠加多个目录（TC_119/TC_055）。
> 空标题段（无文字的标题样式段落）会被静默跳过，不报错；生成的目录条目数以实际有文字的标题为准（TC_121）。

#### 调用示例

文档插入：

```json
{
  "file_id": "<FILE_ID>",
  "lower_level": 1,
  "scope": "documents",
  "upper_level": 1,
  "verb": "insert"
}
```

#### 参数说明

- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL
- `scope` (string, 必填): 操作范围，固定为 documents（按文档设置）。可选值：`documents`
- `verb` (string, 必填): 操作类型，固定为 insert（插入）。可选值：`insert`
- `lower_level` (number, 可选): 结束标题级别
- `upper_level` (number, 可选): 起始标题级别

#### 返回值说明

```json
{
  "code": 0,
  "message": "成功",
  "data": {
    "toc_index": 1
  }
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `code` | number | 0 表示成功 |
| `data` | object | 业务数据 |
| `message` | string | 结果说明 |


---

<a id="wps-tocs-data-documents-query"></a>

## 按文档查询目录

#### 功能说明

按文档查询目录

> toc_index 为 1-based；无目录时 query 失败，须先 insert。

#### 调用示例

文档查询：

```json
{
  "file_id": "<FILE_ID>",
  "scope": "documents",
  "toc_index": 1,
  "verb": "query"
}
```

#### 参数说明

- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL
- `scope` (string, 必填): 操作范围，固定为 documents（按文档设置）。可选值：`documents`
- `verb` (string, 必填): 操作类型，固定为 query（查询）。可选值：`query`
- `toc_index` (number, 可选): 目录索引

#### 返回值说明

```json
{
  "code": 0,
  "message": "成功",
  "data": {
    "toc_info": {
      "toc_index": 1,
      "upper_level": 1,
      "lower_level": 1,
      "end": 31,
      "use_hyperlinks": true,
      "include_page_numbers": true,
      "right_align_page_numbers": true,
      "use_heading_styles": true
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

<a id="wps-tocs-data-paragraphs-insert"></a>

## 按段落插入目录

#### 功能说明

按段落插入目录

> paragraph_index 为 1-based；可由 wps.texts.range（段落 → begin/end）或 wps.texts.search 定位后换算。

#### 调用示例

段落插入：

```json
{
  "file_id": "<FILE_ID>",
  "lower_level": 1,
  "paragraph_index": 1,
  "position": "after",
  "scope": "paragraphs",
  "upper_level": 1,
  "verb": "insert",
  "text": "smoke example text"
}
```

#### 参数说明

- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL
- `scope` (string, 必填): 操作范围，固定为 paragraphs（按段落设置）。可选值：`paragraphs`
- `verb` (string, 必填): 操作类型，固定为 insert（插入）。可选值：`insert`
- `lower_level` (number, 可选): 结束标题级别
- `paragraph_index` (number, 可选): 段落序号（scope=paragraphs 时必填，从 1 起）
- `position` (string, 可选): 插入位置：before/after
- `upper_level` (number, 可选): 起始标题级别

#### 返回值说明

```json
{
  "code": 0,
  "message": "成功",
  "data": {
    "toc_index": 1
  }
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `code` | number | 0 表示成功 |
| `data` | object | 业务数据 |
| `message` | string | 结果说明 |


---

<a id="wps-tocs-data-ranges-insert"></a>

## 按字符区间插入目录

#### 功能说明

按字符区间插入目录

> begin/end 为 0-based 字符区间；可由 wps.texts.search 返回的 ranges 回填。

#### 调用示例

字符区间插入：

```json
{
  "file_id": "<FILE_ID>",
  "begin": 1,
  "end": 74,
  "lower_level": 1,
  "scope": "ranges",
  "upper_level": 1,
  "verb": "insert"
}
```

#### 参数说明

- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL
- `scope` (string, 必填): 操作范围，固定为 ranges（按字符区间设置）。可选值：`ranges`
- `verb` (string, 必填): 操作类型，固定为 insert（插入）。可选值：`insert`
- `begin` (number, 可选): 区间起点（scope=ranges 时必填）
- `end` (number, 可选): 区间终点（scope=ranges 时必填）
- `lower_level` (number, 可选): 结束标题级别
- `upper_level` (number, 可选): 起始标题级别

#### 返回值说明

```json
{
  "code": 0,
  "message": "成功",
  "data": {
    "toc_index": 1
  }
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `code` | number | 0 表示成功 |
| `data` | object | 业务数据 |
| `message` | string | 结果说明 |

