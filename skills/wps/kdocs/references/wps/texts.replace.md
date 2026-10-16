# wps.texts.replace

#### 功能说明

在在线文字文档中查找并替换文本：documents 按整篇文档替换，paragraphs 按段落原文精确替换（润色）。

#### 支持功能

> 表中「操作范围 / 操作类型」即请求 JSON 的 `scope`、`verb` 字段取值。

| 功能简述 | 操作范围（`scope`） | 操作类型（`verb`） |
|----------|---------------------|--------------------|
| [查找并替换文本](#wps-texts-replace-documents-replace) | documents | replace |
| [按段落原文精确替换](#wps-texts-replace-paragraphs-replace) | paragraphs | replace |

---

<a id="wps-texts-replace-documents-replace"></a>

## 查找并替换文本

#### 功能说明

查找并替换文本

> L1 由 URL verb 区分能力，请求体勿带 properties（见 ein DocsMeta.OmitProperties）

#### 调用示例

文档替换：

```json
{
  "file_id": "<FILE_ID>",
  "find_text": "SMOKE_SLICE_ANCHOR_2026-09-03",
  "is_all": true,
  "replace_text": "SMOKE"
}
```

#### 参数说明

- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id；与 url、link_id 三选一
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id；与 url、file_id 三选一
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL；与 link_id、file_id 三选一
- `scope` (string, 必填): 操作范围：documents（整篇文档，缺省） / paragraphs（按段落精确替换）。可选值：`documents` / `paragraphs`
- `find_text` (string, 必填): 查找文本
- `is_all` (boolean, 可选): 是否替换全部
- `replace_text` (string, 可选): 替换文本；传空串 "" 表示删除匹配文本

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

<a id="wps-texts-replace-paragraphs-replace"></a>

## 按段落原文精确替换

#### 功能说明

按段落原文精确替换

> L1 由 URL verb 区分能力，请求体勿带 properties（见 ein DocsMeta.OmitProperties）

#### 调用示例

段落替换：

```json
{
  "file_id": "<FILE_ID>",
  "scope": "paragraphs",
  "items": [
    {
      "src": "smoke example text",
      "dst": "smoke example text revised"
    }
  ],
  "skip_heading": true,
  "skip_on_multi_match": true
}
```

#### 参数说明

- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id；与 url、link_id 三选一
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id；与 url、file_id 三选一
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL；与 link_id、file_id 三选一
- `scope` (string, 必填): 操作范围：documents（整篇文档，缺省） / paragraphs（按段落精确替换）。可选值：`documents` / `paragraphs`
- `items` (array, 必填): 待替换条目数组：[{src:原文整段, dst:润色后文本}]，≤100 条
- `skip_heading` (boolean, 可选): 是否跳过标题段（缺省 true）
- `skip_on_multi_match` (boolean, 可选): 多命中行为：true=整项跳过(缺省) / false=命中全部替换

#### 返回值说明

```json
{
  "code": 0,
  "message": "成功",
  "data": {
    "skipped": 1,
    "item_status": [0]
  }
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `code` | number | 0 表示成功 |
| `data` | object | 业务数据 |
| `message` | string | 结果说明 |

