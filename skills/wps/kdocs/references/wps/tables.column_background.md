# wps.tables.column_background

#### 功能说明

设置在线文字文档表格的列背景。

**幂等性**：是 — safe

#### 支持功能

> 表中「操作范围 / 操作类型」即请求 JSON 的 `scope`、`verb` 字段取值。

| 功能简述 | 操作范围（`scope`） | 操作类型（`verb`） |
|----------|---------------------|--------------------|
| [列底纹色读回](#wps-tables-column-background-documents-query) | documents | query |
| [设置表格的列背景](#wps-tables-column-background-documents-update) | documents | update |

---

<a id="wps-tables-column-background-documents-query"></a>

## 列底纹色读回

#### 功能说明

列底纹色读回

**幂等性**：是 — safe

> 读回值为当前实际生效的数值枚举/度量（与写侧同一 JSAPI 属性），用于写入后的独立确证。

#### 调用示例

属性查询：

```json
{
  "file_id": "<FILE_ID>",
  "verb": "query",
  "table_index": 1,
  "col": 1
}
```

#### 参数说明

- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id；与 url、link_id 三选一
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id；与 url、file_id 三选一
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL；与 link_id、file_id 三选一
- `verb` (string, 必填): 操作类型，固定为 query（查询）。可选值：`query`
- `table_index` (number, 必填): 表格索引，从 1 开始
- `col` (number, 必填): 列号

#### 返回值说明

```json
{
  "code": 0,
  "message": "成功",
  "data": {
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

<a id="wps-tables-column-background-documents-update"></a>

## 设置表格的列背景

#### 功能说明

设置表格的列背景

**幂等性**：是 — safe

#### 调用示例

文档设置：

```json
{
  "file_id": "<FILE_ID>",
  "col": 1,
  "color_index": "smoke",
  "row": 1,
  "table_index": 1
}
```

#### 参数说明

- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id；与 url、link_id 三选一
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id；与 url、file_id 三选一
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL；与 link_id、file_id 三选一
- `verb` (string, 必填): HTTP 动作：query（查询） / update（设置）。可选值：`query` / `update`
- `col` (number, 可选): 列号
- `color_index` (string, 可选): 颜色索引
- `row` (number, 可选): 行号
- `table_index` (number, 必填): 表格索引，从 1 开始

#### 返回值说明

```json
{
  "code": 0,
  "message": "成功",
  "data": {
    "table_index": 1
  }
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `code` | number | 0 表示成功 |
| `data` | object | 业务数据 |
| `message` | string | 结果说明 |

