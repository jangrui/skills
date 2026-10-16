# footnote_endnotes · endnote

<a id="endnote-all"></a>
## wps.footnote_endnotes.endnote_all

#### 功能说明

删除在线文字文档脚注/尾注的全部尾注。

**幂等性**：是 — safe

> *_all delete 会清空对应类型，之后 *_data delete 会 not found。

#### 调用示例

文档删除：

```json
{
  "file_id": "<FILE_ID>"
}
```

#### 参数说明

- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id；与 url、link_id 三选一
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id；与 url、file_id 三选一
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL；与 link_id、file_id 三选一

#### 返回值说明

```json
{
  "code": 0,
  "message": "成功",
  "data": {
    "deleted_count": 2
  }
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `code` | number | 0 表示成功 |
| `data` | object | 业务数据 |
| `message` | string | 结果说明 |


---

<a id="endnote-by-paragraph"></a>
## wps.footnote_endnotes.endnote_by_paragraph

#### 功能说明

插入在线文字文档脚注/尾注的段落插入尾注。

**幂等性**：是 — safe

> 脚注与尾注是两套数据；测 endnote_* 前须 endnote_by_paragraph 或 endnote_by_range insert。

#### 调用示例

文档插入：

```json
{
  "file_id": "<FILE_ID>",
  "paragraph_index": 1,
  "text": "smoke example text"
}
```

#### 参数说明

- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id；与 url、link_id 三选一
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id；与 url、file_id 三选一
- `paragraph_index` (number, 可选): 段落索引，从 1 开始
- `text` (string, 可选): 文本内容
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL；与 link_id、file_id 三选一

#### 返回值说明

```json
{
  "code": 0,
  "message": "成功",
  "data": {
    "item": {
      "begin": 34,
      "end": 35,
      "index": 2,
      "reference": "",
      "text": "smoke example text",
      "type": 0
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

<a id="endnote-by-range"></a>
## wps.footnote_endnotes.endnote_by_range

#### 功能说明

插入在线文字文档脚注/尾注的区间插入尾注。

**幂等性**：是 — safe

> 脚注与尾注是两套数据；测 endnote_* 前须 endnote_by_paragraph 或 endnote_by_range insert。

#### 调用示例

文档插入：

```json
{
  "file_id": "<FILE_ID>",
  "range": {
    "begin": 1,
    "end": 5
  },
  "text": "smoke example text"
}
```

#### 参数说明

- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id；与 url、link_id 三选一
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id；与 url、file_id 三选一
- `range` (object, 可选): range
- `text` (string, 可选): 文本内容
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL；与 link_id、file_id 三选一

#### 返回值说明

```json
{
  "code": 0,
  "message": "成功",
  "data": {
    "item": {
      "begin": 5,
      "end": 6,
      "index": 1,
      "reference": "",
      "text": "smoke example text",
      "type": 0
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

<a id="endnote-count"></a>
## wps.footnote_endnotes.endnote_count

#### 功能说明

查询在线文字文档尾注数量。

**幂等性**：是 — safe

#### 调用示例

文档查询：

```json
{
  "file_id": "<FILE_ID>"
}
```

#### 参数说明

- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id；与 url、link_id 三选一
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id；与 url、file_id 三选一
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL；与 link_id、file_id 三选一

#### 返回值说明

```json
{
  "code": 0,
  "message": "成功",
  "data": {
    "endnote_count": 1
  }
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `code` | number | 0 表示成功 |
| `data` | object | 业务数据 |
| `message` | string | 结果说明 |


---

<a id="endnote-list"></a>
## wps.footnote_endnotes.endnote_list

#### 功能说明

查询在线文字文档尾注列表。

**幂等性**：是 — safe

> 返回的 begin/end 为尾注引用标记在正文中的 0-based 字符位置，可直接回填到 wps.footnote_endnotes.endnote_by_range 的 range（begin/end）。

#### 调用示例

文档查询：

```json
{
  "file_id": "<FILE_ID>"
}
```

#### 参数说明

- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id；与 url、link_id 三选一
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id；与 url、file_id 三选一
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL；与 link_id、file_id 三选一

#### 返回值说明

```json
{
  "code": 0,
  "message": "成功",
  "data": {
    "endnote_count": 1,
    "endnotes": [
      {
        "begin": 33,
        "end": 34,
        "index": 1,
        "reference": "",
        "text": "smoke endnote",
        "type": 0
      }
    ]
  }
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `code` | number | 0 表示成功 |
| `data` | object | 业务数据 |
| `message` | string | 结果说明 |


---

<a id="endnote-text"></a>
## wps.footnote_endnotes.endnote_text

#### 功能说明

设置在线文字文档尾注文本。

**幂等性**：是 — safe

#### 调用示例

文档设置：

```json
{
  "file_id": "<FILE_ID>",
  "index": 1,
  "text": "smoke example text"
}
```

#### 参数说明

- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id；与 url、link_id 三选一
- `index` (number, 可选): 索引，从 1 开始
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id；与 url、file_id 三选一
- `text` (string, 可选): 文本内容
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL；与 link_id、file_id 三选一

#### 返回值说明

```json
{
  "code": 0,
  "message": "成功",
  "data": {
    "item": {
      "begin": 6,
      "end": 7,
      "index": 1,
      "reference": "",
      "text": "smoke example text",
      "type": 0
    }
  }
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `code` | number | 0 表示成功 |
| `data` | object | 业务数据 |
| `message` | string | 结果说明 |


