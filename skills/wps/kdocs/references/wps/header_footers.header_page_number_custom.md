# wps.header_footers.header_page_number_custom

#### 功能说明

在线文字文档页眉插入自定义文字包裹的页码（如「第 X 页」）：支持 查询（读回页眉文本）/设置。

**幂等性**：是 — safe

#### 支持功能

> 表中「操作范围 / 操作类型」即请求 JSON 的 `scope`、`verb` 字段取值。

| 功能简述 | 操作范围（`scope`） | 操作类型（`verb`） |
|----------|---------------------|--------------------|
| [查询页眉自定义文字包裹页码](#wps-header-footers-header-page-number-custom-documents-query) | documents | query |
| [在页眉插入自定义文字包裹的页码](#wps-header-footers-header-page-number-custom-documents-update) | documents | update |

---

<a id="wps-header-footers-header-page-number-custom-documents-query"></a>

## 查询页眉自定义文字包裹页码

#### 功能说明

查询页眉自定义文字包裹页码

**幂等性**：是 — safe

> 复用 backend header_content/footer_content 兼容字段读回；PAGE 域结果文本包含在 text 内（无域级拆分读回）。
> header_footer_type：1=主（默认）、2=首页、3=偶数页；section_index 从 1 开始。

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
    "text": "第 1 页\r"
  }
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `code` | number | 0 表示成功 |
| `data` | object | 业务数据 |
| `message` | string | 结果说明 |


---

<a id="wps-header-footers-header-page-number-custom-documents-update"></a>

## 在页眉插入自定义文字包裹的页码

#### 功能说明

在页眉插入自定义文字包裹的页码

**幂等性**：是 — safe

#### 调用示例

页眉插入「第 X 页」右对齐页码：

```json
{
  "file_id": "<FILE_ID>",
  "text_prefix": "第",
  "text_suffix": "页",
  "alignment": "right",
  "replace": true,
  "header_footer_type": 1,
  "section_index": 1
}
```

页脚插入居中纯数字页码：

```json
{
  "file_id": "<FILE_ID>",
  "text_prefix": "",
  "text_suffix": "",
  "alignment": "center",
  "header_footer_type": 1,
  "section_index": 1
}
```

#### 参数说明

- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id；与 url、link_id 三选一
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id；与 url、file_id 三选一
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL；与 link_id、file_id 三选一
- `verb` (string, 必填): query（读回页眉文本） / update（插入自定义文字包裹页码）。可选值：`query` / `update`
- `alignment` (string, 可选): 对齐方式
- `replace` (boolean, 可选): 是否先清空原页眉再插入（默认 true；false=保留原内容追加）
- `text_prefix` (string, 可选): 页码前缀文字（映射 v7 key 字段），如「第」；纯数字页码传空
- `text_suffix` (string, 可选): 页码后缀文字（映射 v7 value 字段），如「页」；纯数字页码传空
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

