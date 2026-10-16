# wps.tables.repeat_header_row

#### 功能说明

设置在线文字文档表格的重复标题行。

**幂等性**：是 — safe

#### 支持功能

> 表中「操作范围 / 操作类型」即请求 JSON 的 `scope`、`verb` 字段取值。

| 功能简述 | 操作范围（`scope`） | 操作类型（`verb`） |
|----------|---------------------|--------------------|
| [标题行重复读回](#wps-tables-repeat-header-row-documents-query) | documents | query |
| [设置表格的重复标题行](#wps-tables-repeat-header-row-documents-update) | documents | update |

---

<a id="wps-tables-repeat-header-row-documents-query"></a>

## 标题行重复读回

#### 功能说明

标题行重复读回

**幂等性**：是 — safe

> 读回值为当前实际生效的标题行重复设置，用于写入后的独立确证。

#### 调用示例

属性查询：

```json
{
  "file_id": "<FILE_ID>",
  "verb": "query",
  "table_index": 1,
  "row": 1
}
```

#### 参数说明

- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id；与 url、link_id 三选一
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id；与 url、file_id 三选一
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL；与 link_id、file_id 三选一
- `verb` (string, 必填): 操作类型，固定为 query（查询）。可选值：`query`
- `table_index` (number, 必填): 表格索引，从 1 开始
- `row` (number, 可选): 行号，默认 1（标题行）；默认值：`1`

#### 返回值说明

```json
{
  "code": 0,
  "message": "成功",
  "data": {"table_index": 1, "row": 1, "enabled": 1}
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `code` | number | 0 表示成功 |
| `data` | object | 业务数据 |
| `message` | string | 结果说明 |


---

<a id="wps-tables-repeat-header-row-documents-update"></a>

## 设置表格的重复标题行

#### 功能说明

设置表格的重复标题行

**幂等性**：是 — safe

#### 调用示例

文档设置：

```json
{
  "file_id": "<FILE_ID>",
  "enabled": true,
  "table_index": 1
}
```

#### 参数说明

- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id；与 url、link_id 三选一
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id；与 url、file_id 三选一
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL；与 link_id、file_id 三选一
- `verb` (string, 必填): 操作固定为 update（更新）。可选值：`query` / `update`
- `enabled` (boolean, 可选): 是否启用
- `table_index` (number, 必填): 表格索引，从 1 开始

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

