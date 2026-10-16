# wps.header_footers.footer_alignment

#### 功能说明

在线文字文档页脚的对齐：支持 查询（读回对齐值）/设置。

**幂等性**：是 — safe

> 须设页脚段落对齐时仅用 **update**；写后用 `footer_content` 回读，勿 query alignment。

#### 支持功能

> 表中「操作范围 / 操作类型」即请求 JSON 的 `scope`、`verb` 字段取值。

| 功能简述 | 操作范围（`scope`） | 操作类型（`verb`） |
|----------|---------------------|--------------------|
| [查询页脚对齐](#wps-header-footers-footer-alignment-documents-query) | documents | query |
| [设置页脚对齐](#wps-header-footers-footer-alignment-documents-update) | documents | update |

---

<a id="wps-header-footers-footer-alignment-documents-query"></a>

## 查询页脚对齐

#### 功能说明

查询页脚对齐

**幂等性**：是 — safe

> 返回 footer_alignment（JSAPI 枚举名）与 alignment（数值）；枚举：0=wdAlignParagraphLeft、1=wdAlignParagraphCenter、2=wdAlignParagraphRight、3=wdAlignParagraphJustify、4=wdAlignParagraphDistribute。
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
    "alignment": 1,
    "footer_alignment": "wdAlignParagraphCenter"
  }
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `code` | number | 0 表示成功 |
| `data` | object | 业务数据 |
| `message` | string | 结果说明 |


---

<a id="wps-header-footers-footer-alignment-documents-update"></a>

## 设置页脚对齐

#### 功能说明

设置页脚对齐

**幂等性**：是 — safe

#### 调用示例

文档设置：

```json
{
  "file_id": "<FILE_ID>",
  "alignment": "smoke",
  "header_footer_type": 1,
  "section_index": 1
}
```

#### 参数说明

- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id；与 url、link_id 三选一
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id；与 url、file_id 三选一
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL；与 link_id、file_id 三选一
- `verb` (string, 必填): query（读回对齐值） / update（设置对齐）。可选值：`query` / `update`
- `alignment` (string, 可选): 对齐方式
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

