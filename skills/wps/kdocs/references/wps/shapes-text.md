# shapes · text

<a id="text-box"></a>
## wps.shapes.text_box

#### 功能说明

插入在线文字文档形状的文本框。

**幂等性**：是 — safe

> **锚定插入**：配合 `wps.texts.search` 的 begin/end 在指定文字旁插入；多命中取首处。**禁止**写前 `shapes.count`（见 `references/workflows/wps-shapes-textbox.md`）。

#### 调用示例

文档插入：

```json
{
  "file_id": "<FILE_ID>",
  "height": 50,
  "left": 72,
  "top": 72,
  "width": 100
}
```

#### 参数说明

- `begin` (number, 可选): 锚定起点（0-based，不传锚文档起始）
- `end` (number, 可选): 锚定终点（0-based，不传锚文档起始）
- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id；与 url、link_id 三选一
- `height` (number, 可选): 高度
- `left` (number, 可选): left
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id；与 url、file_id 三选一
- `top` (number, 可选): top
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL；与 link_id、file_id 三选一
- `width` (number, 可选): 宽度

#### 返回值说明

```json
{
  "code": 0,
  "message": "成功",
  "data": {
    "info": {
      "height": 50,
      "index": 5,
      "left": 72,
      "name": "TextBox 5",
      "shape_item": "5",
      "top": 72,
      "type": 17,
      "width": 100
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

<a id="text-box-auto-size"></a>
## wps.shapes.text_box_auto_size

#### 功能说明

设置在线文字文档形状的文本框自动调整大小。

**幂等性**：是 — safe

> 须先 insert 文本框；shape_item 来自 wps.shapes.list 中文本框项。

#### 调用示例

文档设置：

```json
{
  "file_id": "<FILE_ID>",
  "auto_size": 1,
  "shape_item": "6"
}
```

#### 参数说明

- `auto_size` (number, 可选): auto size
- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id；与 url、link_id 三选一
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id；与 url、file_id 三选一
- `shape_item` (string, 可选): shape item
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


---

<a id="text-box-link"></a>
## wps.shapes.text_box_link

#### 功能说明

设置在线文字文档形状的文本框。

**幂等性**：是 — safe

#### 调用示例

文档设置：

```json
{
  "file_id": "<FILE_ID>",
  "source_index": 3,
  "target_index": 4
}
```

#### 参数说明

- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id；与 url、link_id 三选一
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id；与 url、file_id 三选一
- `source_index` (number, 可选): source index
- `target_index` (number, 可选): target index
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


---

<a id="text-box-margins"></a>
## wps.shapes.text_box_margins

#### 功能说明

设置在线文字文档形状的文本框内边距。

**幂等性**：是 — safe

> 须先 insert 文本框；shape_item 来自 wps.shapes.list 中文本框项。

#### 调用示例

文档设置：

```json
{
  "file_id": "<FILE_ID>",
  "margin_bottom": 1,
  "margin_left": 1,
  "margin_right": 1,
  "margin_top": 1,
  "shape_item": "6"
}
```

#### 参数说明

- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id；与 url、link_id 三选一
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id；与 url、file_id 三选一
- `margin_bottom` (number, 可选): margin bottom
- `margin_left` (number, 可选): margin left
- `margin_right` (number, 可选): margin right
- `margin_top` (number, 可选): margin top
- `shape_item` (string, 可选): shape item
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


---

<a id="text-replace"></a>
## wps.shapes.text_replace

#### 功能说明

设置在线文字文档形状内文本查找替换。

**幂等性**：是 — safe

#### 调用示例

文档设置：

```json
{
  "file_id": "<FILE_ID>",
  "find_text": "SMOKE_SLICE_ANCHOR_2026-09-03",
  "replace_text": "SMOKE",
  "shape_item": "1.2"
}
```

#### 参数说明

- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id；与 url、link_id 三选一
- `find_text` (string, 可选): find text
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id；与 url、file_id 三选一
- `replace_text` (string, 可选): replace text
- `shape_item` (string, 可选): shape item
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL；与 link_id、file_id 三选一

#### 返回值说明

```json
{
  "code": 0,
  "message": "成功",
  "data": {
    "info": {
      "index": 0,
      "name": "",
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


