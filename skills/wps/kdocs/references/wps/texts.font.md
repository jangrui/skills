# wps.texts.font

#### 功能说明

在线文字文档文本的段落字体：支持 查询/设置。查询返回当前字号、加粗、颜色等字符格式；设置按段落或字符区间写入字体样式（不支持 highlight_color，写高亮须用 wps.texts.highlight）。

**幂等性**：是 — safe

> 同区间多字形（如 bold+italic）：一次 `font_style` 同时传 `bold` 与 `italic`；禁止分两次写。详见 `references/workflows/wps-multi-target-search-style.md`（场景 3）。
> 写后验证：多处已用 `search` 定位并 `font_color` 设色后，用 `ranges_query` **一次**抽查代表区间即可；勿对每个目标重复 query。批量设色流程见 `references/workflows/wps-multi-target-search-style.md`。

#### 支持功能

> 表中「操作范围 / 操作类型」即请求 JSON 的 `scope`、`verb` 字段取值。

| 功能简述 | 操作范围（`scope`） | 操作类型（`verb`） |
|----------|---------------------|--------------------|
| [按段落查询字体信息](#wps-texts-font-paragraphs-query) | paragraphs | query |
| [按段落设置字体](#wps-texts-font-paragraphs-update) | paragraphs | update |
| [按字符区间查询字体信息](#wps-texts-font-ranges-query) | ranges | query |
| [按字符区间设置字体](#wps-texts-font-ranges-update) | ranges | update |

---

<a id="wps-texts-font-paragraphs-query"></a>

## 按段落查询字体信息

#### 功能说明

按段落查询字体信息

**幂等性**：是 — safe

> 返回 font_style_info（当前生效值，含段落级直接覆盖）：font_name(字体名)、font_size(磅值)、bold/italic/strike_through/double_strike_through/superscript/subscript(布尔)、color/color_index(数值颜色)、underline(数字枚举)、spacing(字距)、scaling(缩放百分比)。
> 若段落带直接字号覆盖（未走样式定义），本接口返回的是实际显示字号，可直接用于「放大一号」「统一字号」等场景。

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
    "font_style_info": {
      "font_name": "Arial",
      "font_size": 10.5,
      "color": -16777216,
      "underline": "0",
      "scaling": 100
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

<a id="wps-texts-font-paragraphs-update"></a>

## 按段落设置字体

#### 功能说明

按段落设置字体

**幂等性**：是 — safe

> 写操作报 500002 且读操作正常时，先排查文档保护态（wps.protection.disable 后重试），再排查参数；不要盲目重试。
> font_style 字段：font_name(字体名)、font_size(磅值)、bold/italic/strike_through/double_strike_through/superscript/subscript(布尔)、spacing(字距)、scaling(缩放百分比)。布尔属性传 false 即清除该格式（如 bold:false 去粗、italic:false 去斜体），传 true 设置；不传该字段则不改动。
> 支持多属性合并写：font_style 可同时传多个属性（如 {bold:true,italic:true}、{font_name:宋体,font_size:12}），全部生效并合并回显；旧单属性调用不受影响。
> font_style 不支持 highlight_color 字段（传了报 400100：参数不支持）；写高亮必须走 wps.texts.highlight（high_color 为 WdColorIndex，0=清除高亮）。查询读回里的 highlight_color 字段仅作回显。
> underline 只接受数字（WdUnderline：0=无、1=单线、2=仅词下划线、3=双线、4=点线、6=粗单线、7=虚线、9=点划、11=波浪线）；字符串如 single 不生效（解析为 0）。
> color_index 接受颜色名或数字：black/blue/red/yellow/green/white/auto 等，或 WdColorIndex 数字。

#### 调用示例

段落设置：

```json
{
  "file_id": "<FILE_ID>",
  "scope": "paragraphs",
  "verb": "update",
  "font_style": {
    "bold": true
  },
  "paragraph_index": 1
}
```

#### 参数说明

- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id；与 url、link_id 三选一
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id；与 url、file_id 三选一
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL；与 link_id、file_id 三选一
- `scope` (string, 必填): 操作范围，固定为 paragraphs（按段落设置）。可选值：`paragraphs`
- `verb` (string, 必填): 动作，固定为 update（设置）。可选值：`update`
- `font_style` (object, 可选): 字体样式对象
- `paragraph_index` (number, 可选): 段落索引，从 1 开始

#### 返回值说明

```json
{
  "code": 0,
  "message": "成功",
  "data": {
    "font_style": {
      "bold": true
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

<a id="wps-texts-font-ranges-query"></a>

## 按字符区间查询字体信息

#### 功能说明

按字符区间查询字体信息

**幂等性**：是 — safe

> begin/end 为 0-based 字符区间（与 wps.texts.search 返回的 ranges 同口径，可直接回填）；begin=0 表示文档首字符。
> 返回 font_style_info（当前生效值）：font_name(字体名)、font_size(磅值)、bold/italic/strike_through/double_strike_through/superscript/subscript(布尔)、color_index(颜色名或数字)、highlight_color(高亮)、underline(数字枚举)、spacing(字距)、scaling(缩放百分比)。
> color_index 字段为 WdColorIndex 口径（颜色名或数字：0=自动/黑、2=蓝、6=红等，见 enums.md）；若为数字且取值超出 WdColorIndex 范围，则为 WdColor BGR 十进制（value = B*65536 + G*256 + R，蓝色=16711680、红色=255）。
> font_style_info.highlight_color 为读回回显；设置高亮不能走本工具的 update（报 400100），必须用 wps.texts.highlight。
> 字符区间上的直接字符格式（run 级覆盖）可被本接口读到，无需导出文档解析 XML。

#### 调用示例

字符区间查询：

```json
{
  "file_id": "<FILE_ID>",
  "scope": "ranges",
  "verb": "query",
  "begin": 1,
  "end": 12
}
```

#### 参数说明

- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id；与 url、link_id 三选一
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id；与 url、file_id 三选一
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL；与 link_id、file_id 三选一
- `scope` (string, 必填): 操作范围，固定为 ranges（按字符区间查询）。可选值：`ranges`
- `verb` (string, 必填): 动作，固定为 query（查询）。可选值：`query`
- `begin` (number, 必填): 区间起始位置（0-based 字符偏移，与 wps.texts.search 返回的 ranges 一致，可直接回填；0 表示文档首字符）
- `end` (number, 必填): 区间结束位置（0-based 字符偏移，不含该字符；与 wps.texts.search 返回的 ranges 一致，可直接回填）

#### 返回值说明

```json
{
  "code": 0,
  "message": "成功",
  "data": {
    "font_style_info": {
      "font_name": "Arial",
      "font_size": 10.5,
      "underline": "0",
      "underline_color": 6,
      "emphasis_mark": 2,
      "gradient": {
        "fill_type": 1,
        "gradient_style": 1,
        "gradient_variant": 1,
        "fore_color": 255,
        "back_color": 16711680
      },
      "color_index": "0",
      "scaling": 100
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

<a id="wps-texts-font-ranges-update"></a>

## 按字符区间设置字体

#### 功能说明

按字符区间设置字体

**幂等性**：是 — safe

> 写操作报 500002 且读操作正常时，先排查文档保护态（wps.protection.disable 后重试），再排查参数；不要盲目重试。
> begin/end 为 0-based 字符区间，begin=0 表示文档首字符。
> font_style 字段：font_name(字体名)、font_size(磅值)、bold/italic/strike_through/double_strike_through/superscript/subscript(布尔)、spacing(字距)、scaling(缩放百分比)。
> underline 只接受数字（WdUnderline：0=无、1=单线、2=仅词下划线、3=双线、4=点线、6=粗单线、7=虚线、9=点划、11=波浪线）；字符串如 single 不生效（解析为 0）。
> color_index 接受颜色名或数字：black/blue/red/yellow/green/white/auto 等，或 WdColorIndex 数字。

#### 调用示例

字符区间设置：

```json
{
  "file_id": "<FILE_ID>",
  "scope": "ranges",
  "verb": "update",
  "begin": 1,
  "end": 12,
  "font_style": {
    "bold": true
  }
}
```

#### 参数说明

- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id；与 url、link_id 三选一
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id；与 url、file_id 三选一
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL；与 link_id、file_id 三选一
- `scope` (string, 必填): 操作范围，固定为 ranges（按字符区间设置）。可选值：`ranges`
- `verb` (string, 必填): 动作，固定为 update（设置）。可选值：`update`
- `begin` (number, 可选): 区间起始位置（0-based）
- `end` (number, 可选): 区间结束位置（0-based）
- `font_style` (object, 可选): 字体样式对象

#### 返回值说明

```json
{
  "code": 0,
  "message": "成功",
  "data": {
    "font_style": {
      "bold": true
    }
  }
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `code` | number | 0 表示成功 |
| `data` | object | 业务数据 |
| `message` | string | 结果说明 |

