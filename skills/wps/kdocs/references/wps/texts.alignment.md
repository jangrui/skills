# wps.texts.alignment

#### 功能说明

在线文字文档文本的段落对齐：支持 设置/查询。query 读回段落对齐（format_info.alignment，WdParagraphAlignment 数值口径：0=左、1=居中、2=右、3=两端、4=分散）。

**幂等性**：是 — safe

> 节标题下正文两端对齐：`search` 定位标题 → `range` 映射段落 → 标题后连续 outline_level=10 为正文段，`alignment=justify` 批量写入；详见 `references/workflows/wps-section-body-format.md`（场景 2）。勿 range/format 扫全文。

#### 支持功能

> 表中「操作范围 / 操作类型」即请求 JSON 的 `scope`、`verb` 字段取值。

| 功能简述 | 操作范围（`scope`） | 操作类型（`verb`） |
|----------|---------------------|--------------------|
| [查询段落对齐（format_info.alignment）](#wps-texts-alignment-paragraphs-query) | paragraphs | query |
| [按段落设置对齐](#wps-texts-alignment-paragraphs-update) | paragraphs | update |
| [按字符区间设置对齐](#wps-texts-alignment-ranges-update) | ranges | update |

---

<a id="wps-texts-alignment-paragraphs-query"></a>

## 查询段落对齐（format_info.alignment）

#### 功能说明

查询段落对齐（format_info.alignment）

**幂等性**：是 — safe

> alignment 为 WdParagraphAlignment 数值口径（0=左、1=居中、2=右、3=两端、4=分散）；与写侧字符串 left/center 同义，写 center 后读回 1。
> JSAPI 依据 Paragraph.Format.Alignment

#### 调用示例

查询段落对齐：

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
- `verb` (string, 必填): 操作类型，固定为 query（查询）。可选值：`query`
- `paragraph_index` (number, 必填): 段落索引，从 1 开始

#### 返回值说明

```json
{
  "code": 0,
  "message": "成功",
  "data": {
    "format_info": {
      "paragraph_index": 1,
      "alignment": 1
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

<a id="wps-texts-alignment-paragraphs-update"></a>

## 按段落设置对齐

#### 功能说明

按段落设置对齐

**幂等性**：是 — safe

> 写操作报 500002 且读操作正常时，先排查文档保护态（wps.protection.disable 后重试），再排查参数；不要盲目重试。
> 需传 paragraph_style 对象（如 alignment=center），非顶层 alignment 字段；缺失报 paragraph_style is required。
> alignment 支持字符串 left/center(centre)/right/justify/distribute，亦接受数字（0=左、1=中、2=右、3=两端、4=分散；100 归一为左对齐）。

#### 调用示例

段落设置：

```json
{
  "file_id": "<FILE_ID>",
  "scope": "paragraphs",
  "paragraph_index": 1,
  "paragraph_style": {
    "alignment": "left"
  }
}
```

#### 参数说明

- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id；与 url、link_id 三选一
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id；与 url、file_id 三选一
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL；与 link_id、file_id 三选一
- `scope` (string, 必填): 操作范围，固定为 paragraphs（按段落设置）。可选值：`paragraphs`
- `verb` (string, 必填): HTTP 动作：update（更新） / query（查询）。可选值：`update` / `query`
- `paragraph_index` (number, 可选): 段落索引，从 1 开始
- `paragraph_style` (object, 可选): 段落样式对象

#### 返回值说明

```json
{
  "code": 0,
  "message": "成功",
  "data": {
    "paragraph_style": {
      "alignment": "0"
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

<a id="wps-texts-alignment-ranges-update"></a>

## 按字符区间设置对齐

#### 功能说明

按字符区间设置对齐

**幂等性**：是 — safe

> 写操作报 500002 且读操作正常时，先排查文档保护态（wps.protection.disable 后重试），再排查参数；不要盲目重试。
> begin/end 为 0-based 字符区间（与 wps.texts.search 返回的 ranges 同口径，可直接回填）；begin=0 表示文档首字符。
> 需传 paragraph_style 对象（如 alignment=center），非顶层 alignment 字段；缺失报 paragraph_style is required。
> alignment 支持字符串 left/center(centre)/right/justify/distribute，亦接受数字（0=左、1=中、2=右、3=两端、4=分散；100 归一为左对齐）。

#### 调用示例

字符区间设置：

```json
{
  "file_id": "<FILE_ID>",
  "scope": "ranges",
  "begin": 1,
  "end": 12,
  "paragraph_style": {
    "alignment": "left"
  }
}
```

#### 参数说明

- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id；与 url、link_id 三选一
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id；与 url、file_id 三选一
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL；与 link_id、file_id 三选一
- `scope` (string, 必填): 操作范围，固定为 ranges（按字符区间设置）。可选值：`ranges`
- `verb` (string, 必填): HTTP 动作：update（更新） / query（查询）。可选值：`update` / `query`
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
      "alignment": "0"
    }
  }
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `code` | number | 0 表示成功 |
| `data` | object | 业务数据 |
| `message` | string | 结果说明 |

