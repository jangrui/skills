# wps.styles.data

#### 功能说明

为段落或区间套用已有样式。

#### 支持功能

> 表中「操作范围 / 操作类型」即请求 JSON 的 `scope`、`verb` 字段取值。

| 功能简述 | 操作范围（`scope`） | 操作类型（`verb`） |
|----------|---------------------|--------------------|
| [按段落套用已有样式](#wps-styles-data-paragraphs-update) | paragraphs | update |
| [按字符区间套用已有样式](#wps-styles-data-ranges-update) | ranges | update |

---

<a id="wps-styles-data-paragraphs-update"></a>

## 按段落套用已有样式

#### 功能说明

按段落套用已有样式

> paragraph_index 为 1-based；可由 wps.texts.range（段落 → begin/end）或 wps.texts.search 定位后换算。

#### 调用示例

段落设置：

```json
{
  "file_id": "<FILE_ID>",
  "paragraph_index": 1,
  "scope": "paragraphs",
  "style_name": "SmokeStyleSlice"
}
```

#### 参数说明

- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL
- `scope` (string, 必填): 操作范围，固定为 paragraphs（按段落设置）。可选值：`paragraphs`
- `paragraph_index` (number, 可选): 段落序号（scope=paragraphs 时必填，从 1 起）
- `style_name` (string, 必填): 样式名称

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

<a id="wps-styles-data-ranges-update"></a>

## 按字符区间套用已有样式

#### 功能说明

按字符区间套用已有样式

> begin/end 为 0-based 字符区间；可由 wps.texts.search 返回的 ranges 回填。

#### 调用示例

字符区间设置：

```json
{
  "file_id": "<FILE_ID>",
  "begin": 1,
  "end": 74,
  "scope": "ranges",
  "style_name": "SmokeStyleSlice"
}
```

#### 参数说明

- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL
- `scope` (string, 必填): 操作范围，固定为 ranges（按字符区间设置）。可选值：`ranges`
- `begin` (number, 可选): 区间起点（scope=ranges 时必填）
- `end` (number, 可选): 区间终点（scope=ranges 时必填）
- `style_name` (string, 必填): 样式名称

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

