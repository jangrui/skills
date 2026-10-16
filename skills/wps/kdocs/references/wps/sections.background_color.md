# wps.sections.background_color

#### 功能说明

在线文字文档的页面背景色：支持查询/设置。value 口径：number 为 OLE RGB long（B*65536+G*256+R），字符串为 CSS 十六进制 "#RRGGBB"（推荐，浅黄如

**幂等性**：是 — safe

#### 支持功能

> 表中「操作范围 / 操作类型」即请求 JSON 的 `scope`、`verb` 字段取值。

| 功能简述 | 操作范围（`scope`） | 操作类型（`verb`） |
|----------|---------------------|--------------------|
| [查询页面背景色](#wps-sections-background-color-documents-query) | documents | query |
| [设置页面背景色](#wps-sections-background-color-documents-update) | documents | update |

---

<a id="wps-sections-background-color-documents-query"></a>

## 查询页面背景色

#### 功能说明

查询页面背景色

**幂等性**：是 — safe

> SECTION_BACKGROUND_COLOR proto 化专用字段 background；
> JSAPI 依据 Document.Background.Fill.Visible / ForeColor.RGB（references/Document/Background.md）；背景仅在 Web 版式视图可见
> value 写侧口径：number 为 OLE RGB long（B*65536+G*256+R）或字符串 "#RRGGBB"；WdColorIndex 数值不适用（会被按 RGB long 解释，如 wdYellow=7 写出近黑色）
> 内核 ForeColor.RGB getter 与持久化存在 R/B 字节序差，读回侧已做逆向交换，hex/rgb/foreColorRGB 与写侧 value 口径一致
> 写后持久化为异步落盘（内核 doc.Save，通常约 1 分钟内），写后立即查询可能读到旧值；核验建议写后稍候或重试查询

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
- `verb` (string, 必填): query 查询 / update 设置（query 返回 background 专用字段）。可选值：`query` / `update`

#### 返回值说明

```json
{
  "code": 0,
  "message": "成功",
  "data": {
    "background": {
      "visible": -1,
      "fore_color_rgb": 15203839,
      "rgb": "255,253,231",
      "hex": "#FFFDE7"
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

<a id="wps-sections-background-color-documents-update"></a>

## 设置页面背景色

#### 功能说明

设置页面背景色

**幂等性**：是 — safe

> value 为 OLE RGB long（B*65536+G*256+R）或 "#RRGGBB" 字符串；WdColorIndex 不适用
> 背景仅在 Web 版式视图可见（JSAPI Document.Background.Fill 语义）
> 写侧执行 doc.Save() 落盘为异步生效，通常约 1 分钟内可被 query 读回

#### 调用示例

设置浅黄背景：

```json
{
  "file_id": "<FILE_ID>",
  "value": "#FFFDE7"
}
```

设置浅黄背景（RGB long）：

```json
{
  "file_id": "<FILE_ID>",
  "value": "15203839"
}
```

#### 参数说明

- `file_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 文件 id；与 url、link_id 三选一
- `link_id` (string, 三选一必填: `url` / `link_id` / `file_id`): 分享 id；与 url、file_id 三选一
- `url` (string, 三选一必填: `url` / `link_id` / `file_id`): 文档 URL；与 link_id、file_id 三选一
- `verb` (string, 必填): query 查询 / update 设置（query 返回 background 专用字段）。可选值：`query` / `update`
- `value` (string, 可选): 颜色值口径：number 为 OLE RGB long（B*65536+G*256+R）；字符串为 CSS 十六进制 "#RRGGBB"（推荐）。WdColorIndex 数值不适用（会被按 RGB long 解释，如 wdYellow=7 写出近黑色）。浅黄推荐 "#FFFDE7"（OLE RGB=15203839）

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

