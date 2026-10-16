# wps.shapes.fill_color

#### 功能说明

在线文字文档形状填充颜色：支持 查询/设置（查询返回 R,G,B 颜色串）。

**幂等性**：是 — safe

#### 支持功能

> 表中「操作范围 / 操作类型」即请求 JSON 的 `scope`、`verb` 字段取值。

| 功能简述 | 操作范围（`scope`） | 操作类型（`verb`） |
|----------|---------------------|--------------------|
| [查询形状填充颜色（R,G,B 串）](#wps-shapes-fill-color-documents-query) | documents | query |
| [设置形状的填充颜色](#wps-shapes-fill-color-documents-update) | documents | update |

---

<a id="wps-shapes-fill-color-documents-query"></a>

## 查询形状填充颜色（R,G,B 串）

#### 功能说明

查询形状填充颜色（R,G,B 串）

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
    "info": {
      "index": 1,
      "name": "TextBox 1",
      "shape_item": "1",
      "type": 17,
      "fill_color": "0,128,255"
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

<a id="wps-shapes-fill-color-documents-update"></a>

## 设置形状的填充颜色

#### 功能说明

设置形状的填充颜色

**幂等性**：是 — safe

> shape_item 应来自 wps.shapes.list，勿硬编码形状名。

#### 调用示例

文档设置：

```json
{
  "file_id": "<FILE_ID>",
  "shape_item": "2",
  "value": "true"
}
```

#### 参数说明

- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id；与 url、link_id 三选一
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id；与 url、file_id 三选一
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL；与 link_id、file_id 三选一
- `verb` (string, 必填): HTTP 动作：query（查询，返回 R,G,B）/ update（设置）。可选值：`query` / `update`
- `shape_item` (string, 可选): shape item
- `value` (string, 可选): 属性值

#### 返回值说明

```json
{
  "code": 0,
  "message": "成功",
  "data": {
    "info": {
      "index": 2,
      "name": "Straight Connector 4",
      "type": 9
    }
  }
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `code` | number | 0 表示成功 |
| `data` | object | 业务数据 |
| `message` | string | 结果说明 |

