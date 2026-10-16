# wps.texts.format

#### 功能说明

在线文字文档文本的段落格式：支持 查询/设置。查询返回当前段落格式（对齐、缩进、行距等实际值）；设置按段落或字符区间写入格式。

**幂等性**：是 — safe

> **标题段设色定位**：`wps.texts.structure` 不可用时，**只对 P1 调用一次** paragraphs query 查 outline_level；若 P1 为 1–9 即已找到标题段，立即转 `font_color` 设色。**禁止**为「确认无其他标题」而对 P2…PN 逐段 query（形似标题的正文段 outline_level 为 10，不是标题段）。详见 `wps.md` → 标题段自定义色设置。
> **样式清除验证**：清除/套用样式后须用 `wps.texts.style` 回读 `style_name`/`outline_level`；**禁止**无 `key` 的 paragraphs query（400100 TEXT_FORMAT key required）。
> **段前/段后间距**：`scope=paragraphs` update 时 `key=SpaceBefore` 或 `SpaceAfter`、`value=N`（磅，字符串）；回读用 paragraphs query 的 `space_before`/`space_after`。详见 `references/workflows/wps-paragraph-align-indent.md`（场景 6）。

#### 支持功能

> 表中「操作范围 / 操作类型」即请求 JSON 的 `scope`、`verb` 字段取值。

| 功能简述 | 操作范围（`scope`） | 操作类型（`verb`） |
|----------|---------------------|--------------------|
| [按段落查询格式信息](#wps-texts-format-paragraphs-query) | paragraphs | query |
| [按段落设置格式](#wps-texts-format-paragraphs-update) | paragraphs | update |
| [按字符区间设置格式](#wps-texts-format-ranges-update) | ranges | update |

---

<a id="wps-texts-format-paragraphs-query"></a>

## 按段落查询格式信息

#### 功能说明

按段落查询格式信息

**幂等性**：是 — safe

> 返回 format_info（段落当前实际生效的格式值）：paragraph_index(段落索引)、alignment(对齐枚举)、first_line_indent/left_indent/right_indent(首行/左/右缩进)、line_spacing/line_spacing_rule(行距及行距规则)、space_before/space_after(段前/段后间距)、outline_level(大纲级别)、keep_with_next/keep_together/page_break_before/widow_control(分页相关布尔)。
> 查询返回的是段落当前实际值，可直接用于「统一格式」「格式对比」等场景；写入请用 verb=update（paragraphs 或 ranges）。
> 定位「标题段」设色/对齐时：若 `wps.texts.structure` 不可用，**先只查 P1–P9 标题候选**；outline_level 1–9 即标题段，确认后**禁止**对 P10 以降全文逐段 query（见 `references/workflows/wps-heading-by-outline.md` 场景 1 / 场景 2）。

#### 调用示例

段落查询：

```json
{
  "file_id": "<FILE_ID>",
  "scope": "paragraphs",
  "verb": "query",
  "paragraph_index": 1
}
```

#### 参数说明

- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id；与 url、link_id 三选一
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id；与 url、file_id 三选一
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL；与 link_id、file_id 三选一
- `scope` (string, 必填): 操作范围，固定为 paragraphs（按段落查询）。可选值：`paragraphs`
- `verb` (string, 必填): 动作，固定为 query（查询）。可选值：`query`
- `paragraph_index` (number, 必填): 段落索引，从 1 开始

#### 返回值说明

```json
{
  "code": 0,
  "message": "成功",
  "data": {
    "format_info": {
      "paragraph_index": 1,
      "alignment": 3,
      "line_spacing": 12,
      "outline_level": 10
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

<a id="wps-texts-format-paragraphs-update"></a>

## 按段落设置格式

#### 功能说明

按段落设置格式

**幂等性**：是 — safe

> 写操作报 500002 且读操作正常时，先排查文档保护态（wps.protection.disable 后重试），再排查参数；不要盲目重试。
> key 与 value 必须成对传（key=属性名如 Bold，value=属性值如 true）；只传 paragraph_style 报 key and value required。

#### 调用示例

段落设置：

```json
{
  "file_id": "<FILE_ID>",
  "scope": "paragraphs",
  "verb": "update",
  "key": "Bold",
  "paragraph_index": 1,
  "value": "true"
}
```

#### 参数说明

- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id；与 url、link_id 三选一
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id；与 url、file_id 三选一
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL；与 link_id、file_id 三选一
- `scope` (string, 必填): 操作范围，固定为 paragraphs（按段落设置）。可选值：`paragraphs`
- `verb` (string, 必填): 动作，固定为 update（设置）。可选值：`update`
- `key` (string, 可选): 属性名
- `paragraph_index` (number, 可选): 段落索引，从 1 开始
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

<a id="wps-texts-format-ranges-update"></a>

## 按字符区间设置格式

#### 功能说明

按字符区间设置格式

**幂等性**：是 — safe

> 写操作报 500002 且读操作正常时，先排查文档保护态（wps.protection.disable 后重试），再排查参数；不要盲目重试。
> begin/end 为 0-based 字符区间（与 wps.texts.search 返回的 ranges 同口径，可直接回填）；begin=0 表示文档首字符。
> key 与 value 必须成对传（key=属性名如 Bold，value=属性值如 true）；只传 paragraph_style 报 key and value required。

#### 调用示例

字符区间设置：

```json
{
  "file_id": "<FILE_ID>",
  "scope": "ranges",
  "verb": "update",
  "begin": 1,
  "end": 12,
  "key": "Bold",
  "value": "true"
}
```

#### 参数说明

- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id；与 url、link_id 三选一
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id；与 url、file_id 三选一
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL；与 link_id、file_id 三选一
- `scope` (string, 必填): 操作范围，固定为 ranges（按字符区间设置）。可选值：`ranges`
- `verb` (string, 必填): 动作，固定为 update（设置）。可选值：`update`
- `begin` (number, 可选): 区间起始位置（0-based 字符偏移，与 wps.texts.search 返回的 ranges 一致，可直接回填；0 表示文档首字符）
- `end` (number, 可选): 区间结束位置（0-based 字符偏移，不含该字符；与 wps.texts.search 返回的 ranges 一致，可直接回填）
- `key` (string, 可选): 属性名
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

