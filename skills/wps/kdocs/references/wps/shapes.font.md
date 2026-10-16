# wps.shapes.font

#### 功能说明

在线文字文档形状内字体样式：支持 设置/查询。query 读回形状文字 Bold/Size/ColorIndex（data.text JSON 约定串）。

**幂等性**：是 — safe

#### 支持功能

> 表中「操作范围 / 操作类型」即请求 JSON 的 `scope`、`verb` 字段取值。

| 功能简述 | 操作范围（`scope`） | 操作类型（`verb`） |
|----------|---------------------|--------------------|
| [查询形状文字字体（JSON 约定串）](#wps-shapes-font-documents-query) | documents | query |
| [设置形状内字体样式](#wps-shapes-font-documents-update) | documents | update |

---

<a id="wps-shapes-font-documents-query"></a>

## 查询形状文字字体（JSON 约定串）

#### 功能说明

查询形状文字字体（JSON 约定串）

**幂等性**：是 — safe

> content 为免 proto 约定通道（QueryDocumentShapeResp.text 复用）；JSAPI 依据 Shape.TextFrame.TextRange.Font 的 Bold/Size/ColorIndex
> bold 为 wdToggle 数值：-1=是、0=否、9999999=混合（未定义）；color_index 为 WdColorIndex（0=自动/黑、2=蓝、6=红等），与 wps.shapes.font update 的 key=ColorIndex 写入口径一致

#### 调用示例

查询形状文字字体：

```json
{
  "file_id": "<FILE_ID>",
  "verb": "query",
  "shape_item": "1"
}
```

#### 参数说明

- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id；与 url、link_id 三选一
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id；与 url、file_id 三选一
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL；与 link_id、file_id 三选一
- `verb` (string, 必填): 操作类型，固定为 query（查询）。可选值：`query`
- `shape_item` (string, 必填): 形状索引（从 1 开始；嵌套形状用 "a.b" 路径）；来自 wps.shapes.list / wps.shapes.info

#### 返回值说明

```json
{
  "code": 0,
  "message": "成功",
  "data": {
    "text": "{\"shape_item\":\"1\",\"bold\":-1,\"size\":12,\"color_index\":0}"
  }
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `code` | number | 0 表示成功 |
| `data` | object | 业务数据 |
| `message` | string | 结果说明 |


---

<a id="wps-shapes-font-documents-update"></a>

## 设置形状内字体样式

#### 功能说明

设置形状内字体样式

**幂等性**：是 — safe

> shape_item 应来自 wps.shapes.list，勿硬编码形状名。

#### 调用示例

文档设置：

```json
{
  "file_id": "<FILE_ID>",
  "key": "Bold",
  "shape_item": "2",
  "value": "true"
}
```

#### 参数说明

- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id；与 url、link_id 三选一
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id；与 url、file_id 三选一
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL；与 link_id、file_id 三选一
- `verb` (string, 必填): HTTP 动作：update（更新） / query（查询）。可选值：`update` / `query`
- `key` (string, 可选): 属性名
- `shape_item` (string, 可选): shape item
- `value` (string, 可选): 属性值

#### 返回值说明

```json
{
  "code": 0,
  "message": "成功",
  "data": {
    "info": {
      "index": 0,
      "name": "",
      "shape_item": "2",
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

