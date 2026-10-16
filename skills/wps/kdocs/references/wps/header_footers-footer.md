# header_footers · footer

<a id="footer-font"></a>
## wps.header_footers.footer_font

#### 功能说明

设置在线文字文档页脚的字体。

**幂等性**：是 — safe

> 支持多属性合并写：font_style 中多个属性（font_name/font_size/bold/italic/underline/color_index 等）会全部生效，不再只取第一个属性。
> 空字体属性（font_style 为空对象且未传 key/value）返回显式报错（400100），不再静默。

#### 调用示例

文档设置：

```json
{
  "file_id": "<FILE_ID>",
  "font_style": {
    "bold": true
  },
  "header_footer_type": 1,
  "key": "Bold",
  "section_index": 1,
  "value": "true"
}
```

#### 参数说明

- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id；与 url、link_id 三选一
- `font_style` (object, 可选): 字体样式对象
- `header_footer_type` (number, 可选): header footer type
- `key` (string, 可选): 属性名
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id；与 url、file_id 三选一
- `section_index` (number, 可选): 节索引，从 1 开始
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL；与 link_id、file_id 三选一
- `value` (string, 可选): 属性值

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


---

<a id="footer-link-previous"></a>
## wps.header_footers.footer_link_previous

#### 功能说明

设置在线文字文档页脚链接上一节。

**幂等性**：是 — safe

> 需要 section_index ≥ 2（第一节无上一节）；先插入分节符再设 link。

#### 调用示例

文档设置：

```json
{
  "file_id": "<FILE_ID>",
  "enabled": true,
  "header_footer_type": 1,
  "section_index": 2
}
```

#### 参数说明

- `enabled` (boolean, 可选): 是否启用
- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id；与 url、link_id 三选一
- `header_footer_type` (number, 可选): header footer type
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id；与 url、file_id 三选一
- `section_index` (number, 可选): 节索引，从 1 开始
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL；与 link_id、file_id 三选一

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


---

<a id="footer-page-number"></a>
## wps.header_footers.footer_page_number

#### 功能说明

设置在线文字文档页脚的页码。

**幂等性**：是 — safe

> 页码右对齐：一次调用设 `alignment=right`（如 `wdAlignParagraphRight` / 数值 2），空页脚可直接插入；写后用 `footer_content` 回读。详见 `references/workflows/wps-header-footer-pagination.md`（场景 2 路径 D）。勿先 query `footer_alignment`。

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

- `alignment` (string, 可选): 对齐方式
- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id；与 url、link_id 三选一
- `header_footer_type` (number, 可选): header footer type
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id；与 url、file_id 三选一
- `section_index` (number, 可选): 节索引，从 1 开始
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL；与 link_id、file_id 三选一

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


---

<a id="footer-remove"></a>
## wps.header_footers.footer_remove

#### 功能说明

删除在线文字文档页脚。

**幂等性**：是 — safe

#### 调用示例

文档设置：

```json
{
  "file_id": "<FILE_ID>",
  "header_footer_type": 1,
  "section_index": 1
}
```

#### 参数说明

- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id；与 url、link_id 三选一
- `header_footer_type` (number, 可选): header footer type
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id；与 url、file_id 三选一
- `section_index` (number, 可选): 节索引，从 1 开始
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL；与 link_id、file_id 三选一

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


