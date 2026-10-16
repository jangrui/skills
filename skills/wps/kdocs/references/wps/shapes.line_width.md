# wps.shapes.line_width

#### 功能说明

在线文字文档形状线条宽度：支持 查询/设置（query 返回磅值数字串）。

**幂等性**：是 — safe

#### 支持功能

> 表中「操作范围 / 操作类型」即请求 JSON 的 `scope`、`verb` 字段取值。

| 功能简述 | 操作范围（`scope`） | 操作类型（`verb`） |
|----------|---------------------|--------------------|
| [查询形状线条宽度（磅值数字串）](#wps-shapes-line-width-documents-query) | documents | query |
| [设置形状的线条宽度](#wps-shapes-line-width-documents-update) | documents | update |

---

<a id="wps-shapes-line-width-documents-query"></a>

## 查询形状线条宽度（磅值数字串）

#### 功能说明

查询形状线条宽度（磅值数字串）

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
    "text": "24",
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

<a id="wps-shapes-line-width-documents-update"></a>

## 设置形状的线条宽度

#### 功能说明

设置形状的线条宽度

**幂等性**：是 — safe

#### 调用示例

文档设置：

```json
{
  "file_id": "<FILE_ID>",
  "shape_item": "1",
  "value": "true"
}
```

#### 参数说明

- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id；与 url、link_id 三选一
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id；与 url、file_id 三选一
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL；与 link_id、file_id 三选一
- `verb` (string, 必填): HTTP 动作：query（读回磅值）/ update（设置）。可选值：`query` / `update`
- `shape_item` (string, 可选): shape item
- `value` (string, 可选): 属性值

#### 返回值说明

```json
{
  "code": 0,
  "message": "成功",
  "data": {
    "info": {
      "index": 1,
      "name": "Group 6",
      "type": 6
    }
  }
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `code` | number | 0 表示成功 |
| `data` | object | 业务数据 |
| `message` | string | 结果说明 |

