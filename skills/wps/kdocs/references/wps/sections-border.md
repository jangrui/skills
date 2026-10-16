# sections · border

<a id="border"></a>
## wps.sections.border

#### 功能说明

删除在线文字文档节的页面边框，恢复无边框态（line_style=0、line_width=9999999、art=0）。

**幂等性**：是 — safe

> **添加页面边框**：`break_type=1`（单实线）或 `7`（双线）写入节页面边框；返回 `data.deleted_section` 为 JSAPI **命名遗留**（表示边框操作已作用于该节），**非**删除节。**禁止**用 `wps.texts.border`（段落边框）。
> 写后 `wps.sections.border_data` query；若 `data={}` 空对象但写侧 code=0，仍视为写成功。详见 `references/workflows/wps-section-break-layout.md`（场景 4）。

#### 调用示例

删除页面边框（恢复无边框）：

```json
{
  "file_id": "<FILE_ID>",
  "section_index": 1
}
```

#### 参数说明

- `break_type` (number, 可选): 兼作页面边框线型（WdLineStyle）：0=无边框（清除页面边框，默认）；1=单线；其他值按 WdLineStyle 枚举写入
- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id；与 url、link_id 三选一
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id；与 url、file_id 三选一
- `section_index` (number, 必填): 节索引，从 1 开始
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL；与 link_id、file_id 三选一

#### 返回值说明

```json
{
  "code": 0,
  "message": "成功",
  "data": {
    "deleted_section": 1
  }
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `code` | number | 0 表示成功 |
| `data` | object | 业务数据 |
| `message` | string | 结果说明 |


---

<a id="border-art"></a>
## wps.sections.border_art

#### 功能说明

设置在线文字文档节的页面边框艺术型。

**幂等性**：是 — safe

#### 调用示例

文档设置：

```json
{
  "file_id": "<FILE_ID>",
  "border_art_style": 1,
  "border_art_width": 1,
  "section_index": 1
}
```

#### 参数说明

- `border_art_style` (number, 可选): border art style
- `border_art_width` (number, 可选): border art width
- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id；与 url、link_id 三选一
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

<a id="border-data"></a>
## wps.sections.border_data

#### 功能说明

查询在线文字文档节的边框数据。

**幂等性**：是 — safe

> SECTION_BORDER_DATA proto 化专用字段 border_data；JSAPI 依据 Section.Borders.Item(wdBorderTop/...).LineStyle/LineWidth/Color/ArtStyle

#### 调用示例

文档查询：

```json
{
  "file_id": "<FILE_ID>",
  "section_index": 1
}
```

#### 参数说明

- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id；与 url、link_id 三选一
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id；与 url、file_id 三选一
- `section_index` (number, 可选): 节索引，从 1 开始
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL；与 link_id、file_id 三选一

#### 返回值说明

```json
{
  "code": 0,
  "message": "成功",
  "data": {
    "border_data": [
      {"side": -1, "line_style": 1, "line_width": 12, "color": -16777216, "art": 1},
      {"side": -3, "line_style": 1, "line_width": 12, "color": -16777216, "art": 1},
      {"side": -2, "line_style": 1, "line_width": 12, "color": -16777216, "art": 1},
      {"side": -4, "line_style": 1, "line_width": 12, "color": -16777216, "art": 1}
    ]
  }
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `code` | number | 0 表示成功 |
| `data` | object | 业务数据 |
| `message` | string | 结果说明 |


---

<a id="border-distance"></a>
## wps.sections.border_distance

#### 功能说明

设置在线文字文档节的页面边框距正文距离。

**幂等性**：是 — safe

#### 调用示例

文档设置：

```json
{
  "file_id": "<FILE_ID>",
  "border_distance_bottom": 1,
  "border_distance_from": 1,
  "border_distance_left": 1,
  "border_distance_right": 1,
  "border_distance_top": 1,
  "section_index": 1
}
```

#### 参数说明

- `border_distance_bottom` (number, 可选): border distance bottom
- `border_distance_from` (number, 可选): border distance from
- `border_distance_left` (number, 可选): border distance left
- `border_distance_right` (number, 可选): border distance right
- `border_distance_top` (number, 可选): border distance top
- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id；与 url、link_id 三选一
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


