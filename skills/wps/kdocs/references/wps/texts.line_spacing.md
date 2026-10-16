# wps.texts.line_spacing

#### 功能说明

设置在线文字文档文本的段落行距。

**幂等性**：是 — safe

> 节下正文批量行距：`search` 定位节标题与下一节边界 → `scope=ranges` 一次写入 → `format` 回读；`spacing_rule` 见 `enums.md`（0=单倍/1=1.5倍/2=双倍）。详见 `references/workflows/wps-section-body-format.md`（场景 3）。
> 选区固定磅值行距：`search` + `range` → `spacing_rule="4"` + `spacing_value=N`（磅）；详见 `references/workflows/wps-paragraph-align-indent.md`（场景 5）。

#### 支持功能

> 表中「操作范围 / 操作类型」即请求 JSON 的 `scope`、`verb` 字段取值。

| 功能简述 | 操作范围（`scope`） | 操作类型（`verb`） |
|----------|---------------------|--------------------|
| [按段落设置行距](#wps-texts-line-spacing-paragraphs-update) | paragraphs | update |
| [按字符区间设置行距](#wps-texts-line-spacing-ranges-update) | ranges | update |

---

<a id="wps-texts-line-spacing-paragraphs-update"></a>

## 按段落设置行距

#### 功能说明

按段落设置行距

**幂等性**：是 — safe

> 写操作报 500002 且读操作正常时，先排查文档保护态（wps.protection.disable 后重试），再排查参数；不要盲目重试。
> paragraph_style.line_spacing 是对象非数字，需传 line_spacing 与 line_spacing_rule（或 spacing_rule 与 spacing_value）；传数字报 unmarshal 错误。
> spacing_rule 必须传字符串（proto enum）："0"=单倍、"1"=1.5倍、"2"=双倍、"3"=至少(at least)、"4"=固定(exactly)、"5"=多倍(multiple)；传数字报 unmarshal 错误。
> spacing_rule=3/4 时 spacing_value 为磅值；=5 时 spacing_value 为倍数（如 1.5）；"0"/"1"/"2" 对应单倍/1.5倍/双倍，可不传或忽略 spacing_value。
> 读回（wps.texts.format query）口径：line_spacing.spacing_value 读回为磅值（如单倍 12 磅），换算倍数需结合段落字号（近似 = 磅值/单倍行距磅值，单倍行距随字号变化，非固定 12pt 基准）；spacing_rule 读回可能被引擎归一化，不能可靠区分原始 rule 类型，核验以写入时传入的值为准。

#### 调用示例

段落设置：

```json
{
  "file_id": "<FILE_ID>",
  "scope": "paragraphs",
  "paragraph_index": 1,
  "paragraph_style": {
    "line_spacing": {
      "spacing_rule": "5",
      "spacing_value": 1.5
    }
  }
}
```

#### 参数说明

- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id；与 url、link_id 三选一
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id；与 url、file_id 三选一
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL；与 link_id、file_id 三选一
- `scope` (string, 必填): 操作范围，固定为 paragraphs（按段落设置）。可选值：`paragraphs`
- `paragraph_index` (number, 可选): 段落索引，从 1 开始
- `paragraph_style` (object, 可选): 段落样式对象

#### 返回值说明

```json
{
  "code": 0,
  "message": "成功",
  "data": {
    "paragraph_style": {
      "line_spacing": {
        "spacing_rule": "0",
        "spacing_value": 12
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

<a id="wps-texts-line-spacing-ranges-update"></a>

## 按字符区间设置行距

#### 功能说明

按字符区间设置行距

**幂等性**：是 — safe

> 写操作报 500002 且读操作正常时，先排查文档保护态（wps.protection.disable 后重试），再排查参数；不要盲目重试。
> begin/end 为 0-based 字符区间（与 wps.texts.search 返回的 ranges 同口径，可直接回填）；begin=0 表示文档首字符。
> paragraph_style.line_spacing 是对象非数字，需传 line_spacing 与 line_spacing_rule（或 spacing_rule 与 spacing_value）；传数字报 unmarshal 错误。
> spacing_rule 必须传字符串（proto enum）："0"=单倍、"1"=1.5倍、"2"=双倍、"3"=至少(at least)、"4"=固定(exactly)、"5"=多倍(multiple)；传数字报 unmarshal 错误。
> spacing_rule=3/4 时 spacing_value 为磅值；=5 时 spacing_value 为倍数（如 1.5）；"0"/"1"/"2" 对应单倍/1.5倍/双倍，可不传或忽略 spacing_value。
> 读回（wps.texts.format query）口径：line_spacing.spacing_value 读回为磅值（如单倍 12 磅），换算倍数需结合段落字号（近似 = 磅值/单倍行距磅值，单倍行距随字号变化，非固定 12pt 基准）；spacing_rule 读回可能被引擎归一化，不能可靠区分原始 rule 类型，核验以写入时传入的值为准。

#### 调用示例

字符区间设置：

```json
{
  "file_id": "<FILE_ID>",
  "scope": "ranges",
  "begin": 1,
  "end": 12,
  "paragraph_style": {
    "line_spacing": {
      "spacing_rule": "5",
      "spacing_value": 1.5
    }
  }
}
```

#### 参数说明

- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id；与 url、link_id 三选一
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id；与 url、file_id 三选一
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL；与 link_id、file_id 三选一
- `scope` (string, 必填): 操作范围，固定为 ranges（按字符区间设置）。可选值：`ranges`
- `begin` (number, 可选): 区间起始位置（0-based 字符偏移，与 wps.texts.search 返回的 ranges 一致，可直接回填；0 表示文档首字符）
- `end` (number, 可选): 区间结束位置（0-based 字符偏移，不含该字符；与 wps.texts.search 返回的 ranges 一致，可直接回填）
- `paragraph_style` (object, 可选): 段落样式对象

#### 返回值说明

```json
{
  "code": 0,
  "message": "成功",
  "data": {
    "paragraph_style": {
      "line_spacing": {
        "spacing_rule": "0",
        "spacing_value": 12
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

