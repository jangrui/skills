# wps.tables.cell_content

#### 功能说明

在线文字文档表格的单元格内容：支持 删除/查询/设置。

**幂等性**：是 — safe

#### 支持功能

> 表中「操作范围 / 操作类型」即请求 JSON 的 `scope`、`verb` 字段取值。

| 功能简述 | 操作范围（`scope`） | 操作类型（`verb`） |
|----------|---------------------|--------------------|
| [删除表格的单元格内容](#wps-tables-cell-content-documents-delete) | documents | delete |
| [查询表格的单元格内容](#wps-tables-cell-content-documents-query) | documents | query |
| [设置表格的单元格内容](#wps-tables-cell-content-documents-update) | documents | update |

---

<a id="wps-tables-cell-content-documents-delete"></a>

## 删除表格的单元格内容

#### 功能说明

删除表格的单元格内容

**幂等性**：是 — safe

> 破坏性 delete 前文档须有可用表格（wps.tables.count ≥ 1）。
> data delete 早于 all delete；merge/split 后表结构变化，后续操作可能需重新插表。

#### 调用示例

文档删除：

```json
{
  "file_id": "<FILE_ID>",
  "col": 1,
  "row": 1,
  "table_index": 1,
  "verb": "delete"
}
```

#### 参数说明

- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id；与 url、link_id 三选一
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id；与 url、file_id 三选一
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL；与 link_id、file_id 三选一
- `verb` (string, 必填): 操作类型，固定为 delete（删除）。可选值：`delete`
- `col` (number, 可选): 列号
- `row` (number, 可选): 行号
- `table_index` (number, 可选): 表格索引，从 1 开始

#### 返回值说明

```json
{
  "code": 0,
  "message": "成功",
  "data": {
    "col": 1,
    "row": 1,
    "table_index": 1
  }
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `code` | number | 0 表示成功 |
| `data` | object | 业务数据 |
| `message` | string | 结果说明 |


---

<a id="wps-tables-cell-content-documents-query"></a>

## 查询表格的单元格内容

#### 功能说明

查询表格的单元格内容

**幂等性**：是 — safe

#### 调用示例

文档查询：

```json
{
  "file_id": "<FILE_ID>",
  "col": 1,
  "row": 1,
  "table_index": 1,
  "verb": "query"
}
```

#### 参数说明

- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id；与 url、link_id 三选一
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id；与 url、file_id 三选一
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL；与 link_id、file_id 三选一
- `verb` (string, 必填): 操作类型，固定为 query（查询）。可选值：`query`
- `col` (number, 可选): 列号
- `row` (number, 可选): 行号
- `table_index` (number, 可选): 表格索引，从 1 开始

#### 返回值说明

```json
{
  "code": 0,
  "message": "成功",
  "data": {
    "begin": 49,
    "col": 1,
    "end": 50
  }
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `code` | number | 0 表示成功 |
| `data` | object | 业务数据 |
| `message` | string | 结果说明 |


---

<a id="wps-tables-cell-content-documents-update"></a>

## 设置表格的单元格内容

#### 功能说明

设置表格的单元格内容

**幂等性**：是 — safe

#### 调用示例

文档设置：

```json
{
  "file_id": "<FILE_ID>",
  "col": 1,
  "row": 1,
  "table_index": 1,
  "text": "smoke cell",
  "verb": "update"
}
```

#### 参数说明

- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id；与 url、link_id 三选一
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id；与 url、file_id 三选一
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL；与 link_id、file_id 三选一
- `verb` (string, 必填): 操作类型，固定为 update（更新）。可选值：`update`
- `col` (number, 可选): 列号
- `row` (number, 可选): 行号
- `table_index` (number, 可选): 表格索引，从 1 开始
- `text` (string, 可选): 文本内容

#### 返回值说明

```json
{
  "code": 0,
  "message": "成功",
  "data": {
    "col": 1,
    "text": "smoke cell"
  }
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `code` | number | 0 表示成功 |
| `data` | object | 业务数据 |
| `message` | string | 结果说明 |

