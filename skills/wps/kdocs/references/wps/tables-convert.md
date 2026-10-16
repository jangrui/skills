# tables · convert

<a id="convert-from-text"></a>
## wps.tables.convert_from_text

#### 功能说明

将字符区间文本转换为表格（TABLE_CONVERT_FROM_TEXT）。

**幂等性**：否 — unsafe

> 与 wps.tables.convert_to_text（表格转文本）方向相反，勿混用。

#### 调用示例

字符区间插入：

```json
{
  "file_id": "<FILE_ID>",
  "begin": 184,
  "cols": 3,
  "end": 258
}
```

#### 参数说明

- `begin` (number, 必填): 区间起点（0-based，与 wps.texts.search 一致）
- `cols` (number, 必填): 目标列数，最小 1
- `end` (number, 必填): 区间终点（0-based）
- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id；与 url、link_id 三选一
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id；与 url、file_id 三选一
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL；与 link_id、file_id 三选一

#### 返回值说明

```json
{
  "code": 0,
  "message": "成功",
  "data": {
    "rows": 1,
    "cols": 3
  }
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `code` | number | 0 表示成功 |
| `data` | object | 业务数据 |
| `message` | string | 结果说明 |


---

<a id="convert-to-text"></a>
## wps.tables.convert_to_text

#### 功能说明

设置在线文字文档表格转文本。

**幂等性**：是 — safe

> merge/split/sort 会改变表结构；操作前确认 wps.tables.count ≥ 1。

#### 调用示例

文档设置：

```json
{
  "file_id": "<FILE_ID>",
  "table_index": 1
}
```

#### 参数说明

- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id；与 url、link_id 三选一
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id；与 url、file_id 三选一
- `table_index` (number, 必填): 表格索引，从 1 开始
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


