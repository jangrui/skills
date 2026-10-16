# wps.texts.builtin_properties

#### 功能说明

在线文字文档文本的内置文档属性（标题、作者等）：支持 查询/设置。

**幂等性**：是 — safe

#### 支持功能

> 表中「操作范围 / 操作类型」即请求 JSON 的 `scope`、`verb` 字段取值。

| 功能简述 | 操作范围（`scope`） | 操作类型（`verb`） |
|----------|---------------------|--------------------|
| [查询文本的内置文档属性（标题、作者等）](#wps-texts-builtin-properties-documents-query) | documents | query |
| [设置文本的内置文档属性（标题、作者等）](#wps-texts-builtin-properties-documents-update) | documents | update |

---

<a id="wps-texts-builtin-properties-documents-query"></a>

## 查询文本的内置文档属性（标题、作者等）

#### 功能说明

查询文本的内置文档属性（标题、作者等）

**幂等性**：是 — safe

#### 调用示例

文档查询：

```json
{
  "file_id": "<FILE_ID>",
  "verb": "query"
}
```

#### 参数说明

- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id；与 url、link_id 三选一
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id；与 url、file_id 三选一
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL；与 link_id、file_id 三选一
- `verb` (string, 必填): 操作类型，固定为 query（查询）。可选值：`query`

#### 返回值说明

```json
{
  "code": 0,
  "message": "成功",
  "data": {
    "builtin_properties": {
      "pages": 1,
      "words": 7
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

<a id="wps-texts-builtin-properties-documents-update"></a>

## 设置文本的内置文档属性（标题、作者等）

#### 功能说明

设置文本的内置文档属性（标题、作者等）

**幂等性**：是 — safe

#### 调用示例

文档设置：

```json
{
  "file_id": "<FILE_ID>",
  "verb": "update",
  "author": "smoke",
  "keywords": "smoke",
  "subject": "smoke",
  "title": "SmokeCC"
}
```

#### 参数说明

- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id；与 url、link_id 三选一
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id；与 url、file_id 三选一
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL；与 link_id、file_id 三选一
- `verb` (string, 必填): 操作类型，固定为 update（更新）。可选值：`update`
- `author` (string, 可选): author
- `keywords` (string, 可选): keywords
- `subject` (string, 可选): subject
- `title` (string, 可选): title

#### 返回值说明

```json
{
  "code": 0,
  "message": "成功",
  "data": {
    "properties": {
      "author": "smoke",
      "keywords": "smoke",
      "subject": "smoke",
      "title": "SmokeCC"
    }
  }
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `code` | number | 0 表示成功 |
| `data` | object | 业务数据 |
| `message` | string | 结果说明 |

