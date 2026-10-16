# wps.styles.definition

#### 功能说明

插入、更新或删除在线文字文档样式定义。

#### 支持功能

> 表中「操作范围 / 操作类型」即请求 JSON 的 `scope`、`verb` 字段取值。

| 功能简述 | 操作范围（`scope`） | 操作类型（`verb`） |
|----------|---------------------|--------------------|
| [删除样式定义](#wps-styles-definition-documents-delete) | documents | delete |
| [插入样式定义](#wps-styles-definition-documents-insert) | documents | insert |
| [更新样式定义](#wps-styles-definition-documents-update) | documents | update |

---

<a id="wps-styles-definition-documents-delete"></a>

## 删除样式定义

#### 功能说明

删除样式定义

#### 调用示例

文档删除：

```json
{
  "file_id": "<FILE_ID>",
  "style_name": "SmokeStyleSlice",
  "verb": "delete"
}
```

#### 参数说明

- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL
- `verb` (string, 必填): 操作类型，固定为 delete（删除）。可选值：`delete`
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

<a id="wps-styles-definition-documents-insert"></a>

## 插入样式定义

#### 功能说明

插入样式定义

#### 调用示例

文档插入：

```json
{
  "file_id": "<FILE_ID>",
  "bold": true,
  "font_name": "Arial",
  "font_size": 12,
  "style_name": "SmokeStyleSliceInsert",
  "style_type": 1,
  "verb": "insert"
}
```

#### 参数说明

- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL
- `verb` (string, 必填): 操作类型，固定为 insert（插入）。可选值：`insert`
- `bold` (boolean, 可选): 是否加粗
- `font_name` (string, 可选): 字体名称
- `font_size` (number, 可选): 字号
- `color` (string, 可选): 字体颜色（R,G,B，与 line_color 同口径；也接受
- `style_name` (string, 必填): 样式名称
- `style_type` (number, 可选): 样式类型

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

<a id="wps-styles-definition-documents-update"></a>

## 更新样式定义

#### 功能说明

更新样式定义

#### 调用示例

文档设置：

```json
{
  "file_id": "<FILE_ID>",
  "alignment": 1,
  "bold": true,
  "font_name": "Arial",
  "font_size": 12,
  "style_name": "SmokeStyleSlice",
  "verb": "update"
}
```

#### 参数说明

- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL
- `verb` (string, 必填): 操作类型，固定为 update（更新）。可选值：`update`
- `alignment` (number, 可选): 段落对齐（verb=update）：0=左对齐, 1=居中, 2=右对齐, 3=两端对齐, 4=分散对齐
- `bold` (boolean, 可选): 是否加粗
- `font_name` (string, 可选): 字体名称
- `font_size` (number, 可选): 字号
- `color` (string, 可选): 字体颜色（R,G,B，与 line_color 同口径；也接受
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

