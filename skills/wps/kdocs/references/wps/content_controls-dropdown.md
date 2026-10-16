# content_controls · dropdown

<a id="dropdown"></a>
## wps.content_controls.dropdown

#### 功能说明

插入在线文字文档内容控件的下拉列表。

**幂等性**：是 — safe

> 各类型 insert 的 range 区间勿重叠（checkbox/date_picker/dropdown/plain_text/rich_text 各占不同偏移）。

#### 调用示例

文档插入：

```json
{
  "file_id": "<FILE_ID>",
  "range": {
    "begin": 61,
    "end": 69
  },
  "tag": "smoke-cc",
  "title": "SmokeCC"
}
```

#### 参数说明

- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id；与 url、link_id 三选一
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id；与 url、file_id 三选一
- `range` (object, 可选): range
- `tag` (string, 可选): tag
- `title` (string, 可选): title
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL；与 link_id、file_id 三选一

#### 返回值说明

```json
{
  "code": 0,
  "message": "成功",
  "data": {
    "item": {
      "index": 3,
      "tag": "smoke-cc",
      "title": "SmokeCC",
      "type": 4,
      "value": ""
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

<a id="dropdown-add"></a>
## wps.content_controls.dropdown_add

#### 功能说明

设置在线文字文档内容控件的下拉项。

**幂等性**：是 — safe

> index 必须指向 dropdown 类型控件；先 wps.content_controls.dropdown insert 成功再 update。

#### 调用示例

文档设置：

```json
{
  "file_id": "<FILE_ID>",
  "index": 3,
  "item_text": "smoke",
  "value": "true"
}
```

#### 参数说明

- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id；与 url、link_id 三选一
- `index` (number, 可选): 索引，从 1 开始
- `item_text` (string, 可选): item text
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id；与 url、file_id 三选一
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL；与 link_id、file_id 三选一
- `value` (string, 可选): 属性值

#### 返回值说明

```json
{
  "code": 0,
  "message": "成功",
  "data": {
    "item": {
      "index": 3,
      "tag": "",
      "title": "",
      "type": 4,
      "value": ""
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

<a id="dropdown-remove"></a>
## wps.content_controls.dropdown_remove

#### 功能说明

设置在线文字文档内容控件的下拉项。

**幂等性**：是 — safe

> index 必须指向 dropdown 类型控件；先 wps.content_controls.dropdown insert 成功再 update。

#### 调用示例

文档设置：

```json
{
  "file_id": "<FILE_ID>",
  "index": 3,
  "item_text": "smoke",
  "value": "true"
}
```

#### 参数说明

- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id；与 url、link_id 三选一
- `index` (number, 可选): 索引，从 1 开始
- `item_text` (string, 可选): item text
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id；与 url、file_id 三选一
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL；与 link_id、file_id 三选一
- `value` (string, 可选): 属性值

#### 返回值说明

```json
{
  "code": 0,
  "message": "成功",
  "data": {
    "item": {
      "index": 3,
      "tag": "",
      "title": "",
      "type": 0,
      "value": ""
    }
  }
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `code` | number | 0 表示成功 |
| `data` | object | 业务数据 |
| `message` | string | 结果说明 |


