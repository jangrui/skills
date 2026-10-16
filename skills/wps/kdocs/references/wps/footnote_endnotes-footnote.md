# footnote_endnotes · footnote

<a id="footnote-all"></a>
## wps.footnote_endnotes.footnote_all

#### 功能说明

删除在线文字文档脚注/尾注的全部脚注。

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
    "deleted_count": 4
  }
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `code` | number | 0 表示成功 |
| `data` | object | 业务数据 |
| `message` | string | 结果说明 |


---

<a id="footnote-by-paragraph"></a>
## wps.footnote_endnotes.footnote_by_paragraph

#### 功能说明

插入在线文字文档脚注/尾注的段落插入脚注。

**幂等性**：是 — safe

> 脚注与尾注是两套数据；测 endnote_* 前须 endnote_by_paragraph 或 endnote_by_range insert。
> paragraph_index 为 1-based；可由 wps.texts.range（段落 → begin/end）或 wps.texts.search 定位后换算。

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
      "begin": 36,
      "end": 37,
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

<a id="footnote-by-range"></a>
## wps.footnote_endnotes.footnote_by_range

#### 功能说明

插入在线文字文档脚注/尾注的区间插入脚注。

**幂等性**：是 — safe

> 脚注与尾注是两套数据；测 endnote_* 前须 endnote_by_paragraph 或 endnote_by_range insert。
> begin/end 为 0-based 字符区间；可由 wps.texts.search 返回的 ranges 回填。

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

<a id="footnote-count"></a>
## wps.footnote_endnotes.footnote_count

#### 功能说明

查询在线文字文档脚注数量。

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
    "footnote_count": 1
  }
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `code` | number | 0 表示成功 |
| `data` | object | 业务数据 |
| `message` | string | 结果说明 |


---

<a id="footnote-font"></a>
## wps.footnote_endnotes.footnote_font

#### 功能说明

设置在线文字文档脚注/尾注的字体（font_style 强类型；省略 font_style 时读回当前属性）。

**幂等性**：是 — safe

#### 调用示例

设置脚注字号：

```json
{
  "file_id": "<FILE_ID>",
  "index": 1,
  "font_style": {
    "font_size": 9
  }
}
```

读回脚注字号：

```json
{
  "file_id": "<FILE_ID>",
  "index": 1
}
```

#### 参数说明

- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id；与 url、link_id 三选一
- `font_style` (object, 可选): 字体样式对象，键取 font_size(磅值)/bold(1|0)/color(数值) 恰好其一；省略则读回当前属性
- `index` (number, 可选): 脚注索引，从 1 开始
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id；与 url、file_id 三选一
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL；与 link_id、file_id 三选一

#### 返回值说明

```json
{
  "code": 0,
  "message": "成功",
  "data": {
    "item": {
      "index": 1,
      "text": "脚注测试内容",
      "reference": "_Ref123456",
      "type": 1,
      "begin": 120,
      "end": 121,
      "font_style": {
        "font_size": 9,
        "bold": false,
        "color_index": "-16777216"
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

<a id="footnote-list"></a>
## wps.footnote_endnotes.footnote_list

#### 功能说明

查询在线文字文档脚注列表。

**幂等性**：是 — safe

> 返回的 begin/end 为脚注引用标记在正文中的 0-based 字符位置，可直接回填到 wps.footnote_endnotes.footnote_by_range 的 range（begin/end）。

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
    "footnote_count": 1,
    "footnotes": [
      {
        "begin": 32,
        "end": 33,
        "index": 1,
        "reference": "",
        "text": "smoke footnote",
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

<a id="footnote-text"></a>
## wps.footnote_endnotes.footnote_text

#### 功能说明

设置在线文字文档脚注文本。

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


