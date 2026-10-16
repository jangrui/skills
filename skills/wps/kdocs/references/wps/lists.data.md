# wps.lists.data

#### 功能说明

在线文字文档段落或范围列表属性：支持 查询/设置。查询仅支持按段落（paragraphs/query），返回段落当前列表信息。

**幂等性**：是 — safe

> 标题下多要点圆点：首段 `gallery_type=1` + `template_index=1`，后续段 `is_continue=true` 续接同一列表；写后**一次** query 代表段即可。详见 `references/workflows/wps-lists-and-indent.md`（场景 1）。
> 连续段落数字编号：首段 `gallery_type=2`（编号），后续段 `is_continue=true` 续接 1、2、3…；写后**一次** query 代表段。详见 `references/workflows/wps-lists-and-indent.md`（场景 2）。

#### 支持功能

> 表中「操作范围 / 操作类型」即请求 JSON 的 `scope`、`verb` 字段取值。

| 功能简述 | 操作范围（`scope`） | 操作类型（`verb`） |
|----------|---------------------|--------------------|
| [按段落查询列表信息](#wps-lists-data-paragraphs-query) | paragraphs | query |
| [按段落设置列表属性](#wps-lists-data-paragraphs-update) | paragraphs | update |
| [按字符区间设置列表属性](#wps-lists-data-ranges-update) | ranges | update |

---

<a id="wps-lists-data-paragraphs-query"></a>

## 按段落查询列表信息

#### 功能说明

按段落查询列表信息

**幂等性**：是 — safe

> 返回段落当前列表信息 list_info：paragraph_index(段落索引)、list_type(列表类型枚举，如 1=无序/2=编号/3=大纲)、list_type_name(列表类型名称)、list_level_number(列表层级)、list_string(编号/符号文本)。非列表段落返回空。

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
    "list_info": {
      "paragraph_index": 1,
      "list_type": 0,
      "list_type_name": "wdListNoNumbering",
      "list_level_number": 1,
      "list_string": ""
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

<a id="wps-lists-data-paragraphs-update"></a>

## 按段落设置列表属性

#### 功能说明

按段落设置列表属性

> paragraph_index 为 1-based；可由 wps.texts.range（段落 → begin/end）或 wps.texts.search 定位后换算。

#### 调用示例

段落设置：

```json
{
  "file_id": "<FILE_ID>",
  "scope": "paragraphs",
  "verb": "update",
  "gallery_type": "smoke",
  "is_continue": true,
  "level": 1,
  "paragraph_index": 1,
  "template_index": 1
}
```

#### 参数说明

- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id；与 url、link_id 三选一
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id；与 url、file_id 三选一
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL；与 link_id、file_id 三选一
- `scope` (string, 必填): 操作范围，固定为 paragraphs（按段落设置）。可选值：`paragraphs`
- `verb` (string, 必填): 动作，固定为 update（设置）。可选值：`update`
- `gallery_type` (string, 可选): 列表库：1/bullet/WD_BULLET_GALLERY 无序，2/number/WD_NUMBER_GALLERY 编号，3/outline/WD_OUTLINE_NUMBER_GALLERY 大纲。缺省 1。下游只认数字枚举
- `is_continue` (boolean, 可选): 是否继续前一列表
- `level` (number, 可选): 列表级别 1-9，缺省 1
- `paragraph_index` (number, 可选): 段落索引，从 1 起
- `template_index` (number, 可选): 库内模板索引，从 1 起，缺省 1

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

<a id="wps-lists-data-ranges-update"></a>

## 按字符区间设置列表属性

#### 功能说明

按字符区间设置列表属性

> begin/end 为 0-based 字符区间；可由 wps.texts.search 返回的 ranges 回填。

#### 调用示例

字符区间设置：

```json
{
  "file_id": "<FILE_ID>",
  "scope": "ranges",
  "verb": "update",
  "begin": 1,
  "end": 12,
  "gallery_type": "smoke",
  "is_continue": true,
  "level": 1,
  "template_index": 1
}
```

#### 参数说明

- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id；与 url、link_id 三选一
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id；与 url、file_id 三选一
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL；与 link_id、file_id 三选一
- `scope` (string, 必填): 操作范围，固定为 ranges（按字符区间设置）。可选值：`ranges`
- `verb` (string, 必填): 动作，固定为 update（设置）。可选值：`update`
- `begin` (number, 可选): 范围起点
- `end` (number, 可选): 范围终点
- `gallery_type` (string, 可选): 列表库：1/bullet/WD_BULLET_GALLERY 无序，2/number/WD_NUMBER_GALLERY 编号，3/outline/WD_OUTLINE_NUMBER_GALLERY 大纲。缺省 1。下游只认数字枚举
- `is_continue` (boolean, 可选): 是否继续前一列表
- `level` (number, 可选): 列表级别 1-9，缺省 1
- `template_index` (number, 可选): 库内模板索引，从 1 起，缺省 1

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

