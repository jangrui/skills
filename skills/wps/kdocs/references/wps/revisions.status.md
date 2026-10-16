# wps.revisions.status

#### 功能说明

设置在线文字文档的修订模式状态。

**幂等性**：是 — safe

#### 支持功能

> 表中「操作范围 / 操作类型」即请求 JSON 的 `scope`、`verb` 字段取值。

| 功能简述 | 操作范围（`scope`） | 操作类型（`verb`） |
|----------|---------------------|--------------------|
| [修订模式开关读回](#wps-revisions-status-documents-query) | documents | query |
| [设置修订模式状态](#wps-revisions-status-documents-update) | documents | update |

---

<a id="wps-revisions-status-documents-query"></a>

## 修订模式开关读回

#### 功能说明

修订模式开关读回

**幂等性**：是 — safe

> 读回值为当前修订模式开关状态，用于写入后的独立确证。

#### 调用示例

状态查询：

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
  "data": {"status": true}
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `code` | number | 0 表示成功 |
| `data` | object | 业务数据 |
| `message` | string | 结果说明 |


---

<a id="wps-revisions-status-documents-update"></a>

## 设置修订模式状态

#### 功能说明

设置修订模式状态

**幂等性**：是 — safe

#### 调用示例

文档设置：

```json
{
  "file_id": "<FILE_ID>",
  "enable": true
}
```

#### 参数说明

- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id；与 url、link_id 三选一
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id；与 url、file_id 三选一
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL；与 link_id、file_id 三选一
- `verb` (string, 必填): 操作固定为 update（更新）。可选值：`query` / `update`
- `enable` (boolean, 可选): enable

#### 返回值说明

```json
{
  "code": 0,
  "message": "成功",
  "data": {
    "status": true
  }
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `code` | number | 0 表示成功 |
| `data` | object | 业务数据 |
| `message` | string | 结果说明 |

