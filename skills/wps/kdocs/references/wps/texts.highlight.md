# wps.texts.highlight

#### 功能说明

设置在线文字文档文本的段落高亮。

**幂等性**：是 — safe

> 多段落重点内容批量高亮：对每条条目 `search` 定位后，用 `scope=paragraphs` + `paragraph_index` 直接设色（粉色 `highlight_color=pink` → 5）；**禁止**先 `content` 或逐段 `range` 扫全文。详见 `references/workflows/wps-multi-target-search-style.md`（场景 2 路径 B）。
> **全文清除高亮**：`highlight_color=0`（WdNoHighlight）；逐段 `font` 探测后对仍有高亮的区间写 0。流程见 `references/workflows/wps-multi-target-search-style.md`（场景 8）。

#### 支持功能

> 表中「操作范围 / 操作类型」即请求 JSON 的 `scope`、`verb` 字段取值。

| 功能简述 | 操作范围（`scope`） | 操作类型（`verb`） |
|----------|---------------------|--------------------|
| [按段落设置高亮](#wps-texts-highlight-paragraphs-update) | paragraphs | update |
| [按字符区间设置高亮](#wps-texts-highlight-ranges-update) | ranges | update |

---

<a id="wps-texts-highlight-paragraphs-update"></a>

## 按段落设置高亮

#### 功能说明

按段落设置高亮

**幂等性**：是 — safe

> 写操作报 500002 且读操作正常时，先排查文档保护态（wps.protection.disable 后重试），再排查参数；不要盲目重试。
> font_style 需传 highlight_color（如 yellow）；传 highlight 字段报 font_style.highlight_color required。
> highlight_color 接受颜色名或数字：black/blue/red/yellow/green/white/auto 等，或 WdColorIndex 数字（实测 yellow → 7）。

#### 调用示例

段落设置：

```json
{
  "file_id": "<FILE_ID>",
  "scope": "paragraphs",
  "font_style": {
    "highlight_color": "yellow"
  },
  "paragraph_index": 1
}
```

#### 参数说明

- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id；与 url、link_id 三选一
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id；与 url、file_id 三选一
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL；与 link_id、file_id 三选一
- `scope` (string, 必填): 操作范围，固定为 paragraphs（按段落设置）。可选值：`paragraphs`
- `font_style` (object, 可选): 字体样式对象
- `paragraph_index` (number, 可选): 段落索引，从 1 开始

#### 返回值说明

```json
{
  "code": 0,
  "message": "成功",
  "data": {
    "font_style": {
      "highlight_color": "7"
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

<a id="wps-texts-highlight-ranges-update"></a>

## 按字符区间设置高亮

#### 功能说明

按字符区间设置高亮

**幂等性**：是 — safe

> 写操作报 500002 且读操作正常时，先排查文档保护态（wps.protection.disable 后重试），再排查参数；不要盲目重试。
> begin/end 为 0-based 字符区间（与 wps.texts.search 返回的 ranges 同口径，可直接回填）；begin=0 表示文档首字符。
> end 为绝对字符位（半开区间 [begin, end)，不含 end），写后仅 [begin, end) 落盘；非目标区间不会被波及。
> font_style 需传 highlight_color（如 yellow）；传 highlight 字段报 font_style.highlight_color required。
> highlight_color 接受颜色名（含 wd 前缀，如 wdPink/wdRed）或 WdColorIndex 数字，两种口径等价：black=1、blue=2、turquoise=3、brightGreen=4、pink=5、red=6、yellow=7、white=8、darkBlue=9、teal=10、green=11、violet=12、darkRed=13、darkYellow=14、gray50=15、gray25=16、auto=9999998；未知名称会静默按 0 处理（无高亮），建议回读确认。
> 回读 highlight_color 时 9999999 表示区间内混合（部分高亮、部分无）；写前建议先探基线——部分样张自带高亮，写后非目标区间的既有高亮属于样张基线而非写扩散。

#### 调用示例

字符区间设置：

```json
{
  "file_id": "<FILE_ID>",
  "scope": "ranges",
  "begin": 1,
  "end": 12,
  "font_style": {
    "highlight_color": "yellow"
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
- `font_style` (object, 可选): 字体样式对象

#### 返回值说明

```json
{
  "code": 0,
  "message": "成功",
  "data": {
    "font_style": {
      "highlight_color": "7"
    }
  }
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `code` | number | 0 表示成功 |
| `data` | object | 业务数据 |
| `message` | string | 结果说明 |

