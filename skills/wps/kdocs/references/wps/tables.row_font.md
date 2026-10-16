# wps.tables.row_font

#### 功能说明

在线文字文档表格的行字体：支持 查询/设置。查询返回当前字号、加粗、颜色等；设置按行写入字体样式。

**幂等性**：是 — safe

#### 支持功能

> 表中「操作范围 / 操作类型」即请求 JSON 的 `scope`、`verb` 字段取值。

| 功能简述 | 操作范围（`scope`） | 操作类型（`verb`） |
|----------|---------------------|--------------------|
| [查询行字体信息](#wps-tables-row-font-documents-query) | documents | query |
| [设置表格的行字体](#wps-tables-row-font-documents-update) | documents | update |

---

<a id="wps-tables-row-font-documents-query"></a>

## 查询行字体信息

#### 功能说明

查询行字体信息

**幂等性**：是 — safe

> 返回 font_style_info（行当前实际生效的字体值）：font_name(字体名)、font_size(磅值)、bold/italic/strike_through/double_strike_through/superscript/subscript(布尔)、color/color_index(数值颜色)、underline(数字枚举)、spacing(字距)、scaling(缩放百分比)。

#### 调用示例

行查询：

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
- `row` (number, 可选): 行号
- `table_index` (number, 必填): 表格索引，从 1 开始

#### 返回值说明

```json
{
  "code": 0,
  "message": "成功",
  "data": {
    "font_style_info": {
      "font_name": "Arial",
      "font_size": 22,
      "bold": true
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

<a id="wps-tables-row-font-documents-update"></a>

## 设置表格的行字体

#### 功能说明

设置表格的行字体

**幂等性**：是 — safe

#### 调用示例

文档设置：

```json
{
  "file_id": "<FILE_ID>",
  "col": 1,
  "font_style": {
    "bold": true
  },
  "row": 1,
  "table_index": 1,
  "verb": "update"
}
```

#### 参数说明

- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id；与 url、link_id 三选一
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id；与 url、file_id 三选一
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL；与 link_id、file_id 三选一
- `verb` (string, 必填): 操作类型，固定为 update（更新）。可选值：`update`
- `col` (number, 可选): 列号
- `font_style` (object, 可选): 字体样式对象
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

