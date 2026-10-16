# wps.images.alternative_text

#### 功能说明

读取或设置嵌入图片替代文字（无障碍，IMAGE_ALTERNATIVE_TEXT）。

**幂等性**：是 — safe

#### 支持功能

> 表中「操作范围 / 操作类型」即请求 JSON 的 `scope`、`verb` 字段取值。

| 功能简述 | 操作范围（`scope`） | 操作类型（`verb`） |
|----------|---------------------|--------------------|
| [读取图片替代文字](#wps-images-alternative-text-documents-query) | documents | query |
| [设置图片替代文字](#wps-images-alternative-text-documents-update) | documents | update |

---

<a id="wps-images-alternative-text-documents-query"></a>

## 读取图片替代文字

#### 功能说明

读取图片替代文字

**幂等性**：是 — safe

#### 调用示例

文档查询：

```json
{
  "file_id": "<FILE_ID>",
  "verb": "query",
  "index": 6
}
```

#### 参数说明

- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL
- `verb` (string, 必填): 操作类型，固定为 query（查询）。可选值：`query`
- `index` (number, 必填): 图片索引，从 1 开始

#### 返回值说明

```json
{
  "code": 0,
  "message": "成功",
  "data": {
    "info": {
      "alternative_text": "compatible",
      "begin": 0,
      "end": 0,
      "index": 6,
      "paragraph_index": 0,
      "title": "",
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


---

<a id="wps-images-alternative-text-documents-update"></a>

## 设置图片替代文字

#### 功能说明

设置图片替代文字

**幂等性**：是 — safe

#### 调用示例

文档设置：

```json
{
  "file_id": "<FILE_ID>",
  "verb": "update",
  "alternative_text": "smoke",
  "index": 6
}
```

#### 参数说明

- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL
- `verb` (string, 必填): 操作类型，固定为 update（设置）。可选值：`update`
- `alternative_text` (string, 必填): 替代文字内容
- `index` (number, 必填): 图片索引，从 1 开始

#### 返回值说明

```json
{
  "code": 0,
  "message": "成功",
  "data": {
    "index": 6,
    "alternative_text": "smoke"
  }
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `code` | number | 0 表示成功 |
| `data` | object | 业务数据 |
| `message` | string | 结果说明 |

