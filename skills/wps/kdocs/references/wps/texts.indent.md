# wps.texts.indent

#### 功能说明

设置在线文字文档文本的段落缩进。url、link_id、file_id 至少填一个。仅支持更新；省略 verb 时默认 update，不支持 query。 读取当前缩进请用 wps.texts.format（scope="paragraphs"、verb="query"，并传 paragraph_index）。 paragraph_style.indent 的 indent_type/unit 必须为字符串：indent_type 取 "1"=左缩进/"2"=右缩进/"3"=首行缩进，unit 取 "1"=磅/"2"=字符；传数字类型会报 400001，其它名称（first_line/char 等）静默回落默认值。

**幂等性**：是 — safe

> 选区首行缩进：`search` 定位 `<selected_text>` → `range` 映射段落 → `indent_type="3"` + `unit="2"`；详见 `references/workflows/wps-paragraph-align-indent.md`（场景 2）。
> 编号列表悬挂缩进：每段两次写 — 首行 `indent_type="3"` `indent_value=-2` + 左 `indent_type="1"` `indent_value=2`（`unit="2"` 字符）；`lists.blocks` 不可用时用 search 定位。详见 `references/workflows/wps-paragraph-align-indent.md`（场景 3）。
> 段落左缩进（厘米）：`search` 定位目标段 → 左缩进 `indent_type="1"`、`unit="1"`（磅）、`indent_value=厘米×28.35`（2cm≈56.7）；**不支持** `unit=cm`。详见 `references/workflows/wps-paragraph-align-indent.md`（场景 4）。

#### 支持功能

> 表中「操作范围 / 操作类型」即请求 JSON 的 `scope`、`verb` 字段取值。

| 功能简述 | 操作范围（`scope`） | 操作类型（`verb`） |
|----------|---------------------|--------------------|
| [按段落设置缩进](#wps-texts-indent-paragraphs-update) | paragraphs | update |
| [按字符区间设置缩进](#wps-texts-indent-ranges-update) | ranges | update |

---

<a id="wps-texts-indent-paragraphs-update"></a>

## 按段落设置缩进

#### 功能说明

按段落设置缩进

**幂等性**：是 — safe

> 写操作报 500002 且读操作正常时，先排查文档保护态（wps.protection.disable 后重试），再排查参数；不要盲目重试。
> paragraph_style.indent 需对象，缺失报 paragraph_style.indent required。
> indent_type 与 unit 必须为字符串（proto string 字段）：传数字类型（如 3 而非 "3"）会报 400001 参数错误。
> indent_type 合法取值为数字字符串："1"=左缩进、"2"=右缩进、"3"=首行缩进。
> unit 合法取值为数字字符串："1"=磅(point)、"2"=字符(character)。
> 其它名称（如 first_line/firstLine/char）不被识别，会静默回落到默认值（indent_type→左缩进、unit→磅），不报错但不生效。
> indent_value 为缩进量数值，配合 unit 解释。

#### 调用示例

段落设置（首行缩进 2 字符）：

```json
{
  "file_id": "<FILE_ID>",
  "scope": "paragraphs",
  "paragraph_index": 1,
  "paragraph_style": {
    "indent": {
      "indent_type": "3",
      "indent_value": 2,
      "unit": "2"
    }
  }
}
```

#### 参数说明

- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id；与 url、link_id 三选一
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id；与 url、file_id 三选一
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL；与 link_id、file_id 三选一
- `scope` (string, 必填): 操作范围，固定为 paragraphs（按段落设置）。可选值：`paragraphs`
- `paragraph_index` (number, scope=paragraphs 时必填): 段落索引，必须为从 1 开始的整数
- `paragraph_style` (object, scope=paragraphs 时必填): 段落样式对象，必须包含 `indent`。
  - `indent.indent_type` (string): "1" 左缩进、"2" 右缩进、"3" 首行缩进。
  - `indent.indent_value` (number): 缩进量。
  - `indent.unit` (string): "1" 磅、"2" 字符。
  - 示例：`{"indent":{"indent_type":"3","indent_value":2,"unit":"2"}}`

#### 返回值说明

```json
{
  "code": 0,
  "message": "成功",
  "data": {
    "paragraph_style": {
      "indent": {
        "indent_type": "3",
        "indent_value": 2,
        "unit": "2"
      }
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

<a id="wps-texts-indent-ranges-update"></a>

## 按字符区间设置缩进

#### 功能说明

按字符区间设置缩进

**幂等性**：是 — safe

> 写操作报 500002 且读操作正常时，先排查文档保护态（wps.protection.disable 后重试），再排查参数；不要盲目重试。
> begin/end 为 0-based 字符区间（与 wps.texts.search 返回的 ranges 同口径，可直接回填）；begin=0 表示文档首字符。
> paragraph_style.indent 需对象，缺失报 paragraph_style.indent required。
> indent_type 与 unit 必须为字符串（proto string 字段）：传数字类型（如 3 而非 "3"）会报 400001 参数错误。
> indent_type 合法取值为数字字符串："1"=左缩进、"2"=右缩进、"3"=首行缩进。
> unit 合法取值为数字字符串："1"=磅(point)、"2"=字符(character)。
> 其它名称（如 first_line/firstLine/char）不被识别，会静默回落到默认值（indent_type→左缩进、unit→磅），不报错但不生效。
> indent_value 为缩进量数值，配合 unit 解释。

#### 调用示例

字符区间设置（首行缩进 2 字符）：

```json
{
  "file_id": "<FILE_ID>",
  "scope": "ranges",
  "begin": 1,
  "end": 12,
  "paragraph_style": {
    "indent": {
      "indent_type": "3",
      "indent_value": 2,
      "unit": "2"
    }
  }
}
```

#### 参数说明

- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id；与 url、link_id 三选一
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id；与 url、file_id 三选一
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL；与 link_id、file_id 三选一
- `scope` (string, 必填): 操作范围，固定为 ranges（按字符区间设置）。可选值：`ranges`
- `begin` (number, scope=ranges 时必填): 区间起始位置（0-based 字符偏移，与 wps.texts.search 返回的 ranges 一致，可直接回填；0 表示文档首字符）
- `end` (number, scope=ranges 时必填): 区间结束位置（0-based 字符偏移，不含该字符；与 wps.texts.search 返回的 ranges 一致，可直接回填）
- `paragraph_style` (object, scope=ranges 时必填): 段落样式对象，必须包含 `indent`。
  - `indent.indent_type` (string): "1" 左缩进、"2" 右缩进、"3" 首行缩进。
  - `indent.indent_value` (number): 缩进量。
  - `indent.unit` (string): "1" 磅、"2" 字符。
  - 示例：`{"indent":{"indent_type":"3","indent_value":2,"unit":"2"}}`

#### 返回值说明

```json
{
  "code": 0,
  "message": "成功",
  "data": {
    "paragraph_style": {
      "indent": {
        "indent_type": "3",
        "indent_value": 2,
        "unit": "2"
      }
    }
  }
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `code` | number | 0 表示成功 |
| `data` | object | 业务数据 |
| `message` | string | 结果说明 |

