# wps.shapes.wrap_type

#### 功能说明

在线文字文档形状环绕方式：支持 设置/查询（wrap_type 取值（JSAPI WdWrapType 官方值）：0=四周型 1=紧密型 2=穿越型 3=无环绕 4=上下型 5=衬于文字下方 6=浮于文字上方 7=嵌入型；写 7 会将浮动形状转为嵌入型（脱离 Shapes 浮动集合），非法值显式报错）。

**幂等性**：是 — safe

#### 支持功能

> 表中「操作范围 / 操作类型」即请求 JSON 的 `scope`、`verb` 字段取值。

| 功能简述 | 操作范围（`scope`） | 操作类型（`verb`） |
|----------|---------------------|--------------------|
| [查询形状环绕方式](#wps-shapes-wrap-type-documents-query) | documents | query |
| [设置形状的环绕方式](#wps-shapes-wrap-type-documents-update) | documents | update |

---

<a id="wps-shapes-wrap-type-documents-query"></a>

## 查询形状环绕方式

#### 功能说明

查询形状环绕方式

**幂等性**：是 — safe

#### 调用示例

文档查询：

```json
{
  "file_id": "<FILE_ID>",
  "shape_item": "3",
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
      "index": 3,
      "name": "Picture 7",
      "shape_item": "3",
      "type": 13,
      "wrap_type": 0
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

<a id="wps-shapes-wrap-type-documents-update"></a>

## 设置形状的环绕方式

#### 功能说明

设置形状的环绕方式

**幂等性**：是 — safe

> 非法 wrap_type 值（非 0-7）会显式报错（500002），不会静默成功

#### 调用示例

文档设置：

```json
{
  "file_id": "<FILE_ID>",
  "shape_item": "2",
  "wrap_type": 0
}
```

#### 参数说明

- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id；与 url、link_id 三选一
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id；与 url、file_id 三选一
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL；与 link_id、file_id 三选一
- `verb` (string, 必填): HTTP 动作：query（查询环绕方式）/ update（设置环绕方式）。可选值：`query` / `update`
- `shape_item` (string, 可选): shape item
- `wrap_type` (number, 可选): 环绕方式（WdWrapType：0=四周型 1=紧密型 2=穿越型 3=无环绕 4=上下型 5=衬于文字下方 6=浮于文字上方 7=嵌入型）

#### 返回值说明

```json
{
  "code": 0,
  "message": "成功",
  "data": {
    "info": {
      "index": 2,
      "name": "TextBox 5",
      "type": 17
    }
  }
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `code` | number | 0 表示成功 |
| `data` | object | 业务数据 |
| `message` | string | 结果说明 |

