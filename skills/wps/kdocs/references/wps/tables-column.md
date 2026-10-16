# tables · column

<a id="column"></a>
## wps.tables.column

#### 功能说明

删除在线文字文档表格的列。

**幂等性**：是 — safe

> 破坏性 delete 前文档须有可用表格（wps.tables.count ≥ 1）。
> data delete 早于 all delete；merge/split 后表结构变化，后续操作可能需重新插表。

#### 调用示例

文档删除：

```json
{
  "file_id": "<FILE_ID>",
  "col": 1,
  "table_index": 1
}
```

#### 参数说明

- `col` (number, 可选): 列号
- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id；与 url、link_id 三选一
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id；与 url、file_id 三选一
- `table_index` (number, 可选): 表格索引，从 1 开始
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL；与 link_id、file_id 三选一

#### 返回值说明

```json
{
  "code": 0,
  "message": "成功",
  "data": {
    "col": 1,
    "table_index": 1
  }
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `code` | number | 0 表示成功 |
| `data` | object | 业务数据 |
| `message` | string | 结果说明 |


---

<a id="column-content"></a>
## wps.tables.column_content

#### 功能说明

查询在线文字文档表格的列内容。

**幂等性**：是 — safe

#### 调用示例

文档查询：

```json
{
  "file_id": "<FILE_ID>",
  "col": 1,
  "table_index": 1
}
```

#### 参数说明

- `col` (number, 可选): 列号
- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id；与 url、link_id 三选一
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id；与 url、file_id 三选一
- `table_index` (number, 可选): 表格索引，从 1 开始
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL；与 link_id、file_id 三选一

#### 返回值说明

```json
{
  "code": 0,
  "message": "成功",
  "data": {
    "cells": [
      {
        "begin": 49,
        "col": 1,
        "end": 50,
        "row": 1,
        "text": ""
      },
      {
        "begin": 53,
        "col": 1,
        "end": 54,
        "row": 2,
        "text": ""
      },
      {
        "begin": 57,
        "col": 1,
        "end": 58,
        "row": 3,
        "text": ""
      }
    ],
    "col": 1
  }
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `code` | number | 0 表示成功 |
| `data` | object | 业务数据 |
| `message` | string | 结果说明 |


---

<a id="column-insert"></a>
## wps.tables.column_insert

#### 功能说明

设置在线文字文档表格的列。

**幂等性**：是 — safe

#### 调用示例

文档设置：

```json
{
  "file_id": "<FILE_ID>",
  "col": 1,
  "position": "after",
  "table_index": 1
}
```

#### 参数说明

- `col` (number, 可选): 列号
- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id；与 url、link_id 三选一
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id；与 url、file_id 三选一
- `position` (string, 可选): 插入位置：before/after
- `table_index` (number, 必填): 表格索引，从 1 开始
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL；与 link_id、file_id 三选一

#### 返回值说明

```json
{
  "code": 0,
  "message": "成功",
  "data": {
    "table_index": 1
  }
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `code` | number | 0 表示成功 |
| `data` | object | 业务数据 |
| `message` | string | 结果说明 |


---

<a id="column-merge"></a>
## wps.tables.column_merge

#### 功能说明

设置在线文字文档表格的合并列。

**幂等性**：是 — safe

> merge/split/sort 会改变表结构；操作前确认 wps.tables.count ≥ 1。

#### 调用示例

文档设置：

```json
{
  "file_id": "<FILE_ID>",
  "col": 1,
  "table_index": 1
}
```

#### 参数说明

- `col` (number, 可选): 列号
- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id；与 url、link_id 三选一
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id；与 url、file_id 三选一
- `table_index` (number, 必填): 表格索引，从 1 开始
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL；与 link_id、file_id 三选一

#### 返回值说明

```json
{
  "code": 0,
  "message": "成功",
  "data": {
    "table_index": 1
  }
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `code` | number | 0 表示成功 |
| `data` | object | 业务数据 |
| `message` | string | 结果说明 |


---

<a id="column-width"></a>
## wps.tables.column_width

#### 功能说明

设置在线文字文档表格的列宽。

**幂等性**：是 — safe

#### 调用示例

文档设置：

```json
{
  "file_id": "<FILE_ID>",
  "col": 1,
  "table_index": 1,
  "width": 72
}
```

#### 参数说明

- `col` (number, 可选): 列号
- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id；与 url、link_id 三选一
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id；与 url、file_id 三选一
- `table_index` (number, 必填): 表格索引，从 1 开始
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL；与 link_id、file_id 三选一
- `width` (number, 可选): 宽度

#### 返回值说明

```json
{
  "code": 0,
  "message": "成功",
  "data": {
    "width": 72
  }
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `code` | number | 0 表示成功 |
| `data` | object | 业务数据 |
| `message` | string | 结果说明 |


