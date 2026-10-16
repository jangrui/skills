# wps.header_footers.footer_content

#### 功能说明

在线文字文档页脚的内容：支持 查询/设置。查询返回指定节、指定类型的页脚文本；设置按节写入页脚文本。

**幂等性**：是 — safe

#### 支持功能

> 表中「操作范围 / 操作类型」即请求 JSON 的 `scope`、`verb` 字段取值。

| 功能简述 | 操作范围（`scope`） | 操作类型（`verb`） |
|----------|---------------------|--------------------|
| [查询页脚内容](#wps-header-footers-footer-content-documents-query) | documents | query |
| [设置页脚内容](#wps-header-footers-footer-content-documents-update) | documents | update |

---

<a id="wps-header-footers-footer-content-documents-query"></a>

## 查询页脚内容

#### 功能说明

查询页脚内容

**幂等性**：是 — safe

> 返回 footer_content（页脚文本内容）；header_footer_type：1=主（默认）、2=首页、3=偶数页；section_index 从 1 开始。

#### 调用示例

文档查询：

```json
{
  "file_id": "<FILE_ID>",
  "header_footer_type": 1,
  "section_index": 1,
  "verb": "query"
}
```

#### 参数说明

- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id；与 url、link_id 三选一
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id；与 url、file_id 三选一
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL；与 link_id、file_id 三选一
- `verb` (string, 必填): 操作类型，固定为 query（查询）。可选值：`query`
- `header_footer_type` (number, 可选): header footer type
- `section_index` (number, 可选): 节索引，从 1 开始

#### 返回值说明

```json
{
  "code": 0,
  "message": "成功",
  "data": {
    "footer_content": "1\r\r"
  }
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `code` | number | 0 表示成功 |
| `data` | object | 业务数据 |
| `message` | string | 结果说明 |


---

<a id="wps-header-footers-footer-content-documents-update"></a>

## 设置页脚内容

#### 功能说明

设置页脚内容

**幂等性**：是 — safe

#### 调用示例

文档设置：

```json
{
  "file_id": "<FILE_ID>",
  "content": "smoke example text",
  "header_footer_type": 1,
  "section_index": 1,
  "verb": "update"
}
```

#### 参数说明

- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id；与 url、link_id 三选一
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id；与 url、file_id 三选一
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL；与 link_id、file_id 三选一
- `verb` (string, 必填): 操作类型，固定为 update（更新）。可选值：`update`
- `content` (string, 可选): 文本内容
- `header_footer_type` (number, 可选): header footer type
- `section_index` (number, 可选): 节索引，从 1 开始

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

