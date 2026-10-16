# wps.shapes.line_dash

#### 功能说明

在线文字文档形状虚线样式：支持 查询/设置（query 返回 dashStyle 数字串）。

**幂等性**：是 — safe

> update 须用 **source_index**（与 text_box 返回 shape_item 同值）。

#### 支持功能

> 表中「操作范围 / 操作类型」即请求 JSON 的 `scope`、`verb` 字段取值。

| 功能简述 | 操作范围（`scope`） | 操作类型（`verb`） |
|----------|---------------------|--------------------|
| [查询形状虚线样式 DashStyle（msoLineDash 枚举数字，如 4 为长划线）](#wps-shapes-line-dash-documents-query) | documents | query |
| [设置形状的虚线样式](#wps-shapes-line-dash-documents-update) | documents | update |

---

<a id="wps-shapes-line-dash-documents-query"></a>

## 查询形状虚线样式 DashStyle（msoLineDash 枚举数字，如 4 为长划线）

#### 功能说明

查询形状虚线样式 DashStyle（msoLineDash 枚举数字，如 4 为长划线）

**幂等性**：是 — safe

#### 调用示例

文档查询：

```json
{
  "file_id": "<FILE_ID>",
  "shape_item": "1",
  "verb": "query"
}
```

#### 参数说明

- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id；与 url、link_id 三选一
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id；与 url、file_id 三选一
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL；与 link_id、file_id 三选一
- `verb` (string, 必填): 操作类型，固定为 query（查询）。可选值：`query`
- `shape_item` (string, 可选): shape item

#### 返回值说明

```json
{
  "code": 0,
  "message": "成功",
  "data": {
    "text": "4",
    "info": {
      "index": 1,
      "name": "Rectangle 1",
      "shape_item": "1",
      "type": 1
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

<a id="wps-shapes-line-dash-documents-update"></a>

## 设置形状的虚线样式

#### 功能说明

设置形状的虚线样式

**幂等性**：是 — safe

#### 调用示例

文档设置：

```json
{
  "file_id": "<FILE_ID>",
  "dash_style": 1,
  "source_index": 1
}
```

#### 参数说明

- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id；与 url、link_id 三选一
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id；与 url、file_id 三选一
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL；与 link_id、file_id 三选一
- `verb` (string, 必填): HTTP 动作：query（读回 dashStyle）/ update（设置）。可选值：`query` / `update`
- `dash_style` (number, 可选): dash style
- `source_index` (number, 可选): source index

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

