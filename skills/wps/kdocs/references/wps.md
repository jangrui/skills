# 在线文字（wps）工具完整参考文档

本文件包含金山文档 Skill 中在线文字（`wps.*`）工具的操作说明。该类工具面向在线编辑中的文字文档，适合创建空白文档、导出和原子能力执行等场景。

---

## 通用说明

### 在线文字特点

- 面向在线文字文档，不是本地 `.docx` 文件直传接口
- 支持创建空白在线文档、导出为 DOCX / PDF / 图片 / AP
- 提供结构化原子工具，对文档进行段落/区间级别的增删改查和格式设置等操作
- 若只是读取正文内容，仍优先使用通用工具 `read_file`

### 何时使用 `wps.*`
- 需要新建一个空白在线文字文档
- 需要把在线文字导出为 DOCX、PDF、图片或 AP 文稿
- 需要对文档执行原子操作：读取/修改指定段落内容、查找替换、设置段落格式、设置字符格式等

### 何时不要用 `wps.*`
- 创建空白文档 `.docx` 文件：用 `create_empty_file`
- 创建并写入，优先用工具 `create_file_with_content`
- 上传本地 docx/pdf 等文件：用 `upload_new_file`；覆盖已有文档：用 `upload_replace_file`
- 写 Markdown 富文本内容到智能文档：用 `otl.*`

### `wps.*` 工具调用说明

- 格式：服务名和工具分开，property 级命令保留点号
  例如：`kdocs-cli wps texts.range`、`kdocs-cli wps export`
- 文档定位：除创建空白文档 / 纯任务查询外，统一传 `url` / `link_id` / `file_id` **三选一**

#### 调用形态

```
kdocs-cli wps texts.format --help
kdocs-cli wps texts.format '{"file_id":"...","scope":"ranges"}'
kdocs-cli call wps.texts.format '{"file_id":"...","scope":"ranges"}'
```

## 导出能力总览

`wps.*` 中的导出能力对外拆分为三个工具：

- `wps.export`：导出 DOCX、创建 PDF 导出任务、发起 AP 导出流程
- `wps.export_image`：导出 PNG / JPEG 图片
- `wps.query_export`：统一查询异步导出结果

### 选择建议

- 需要拿到 `.docx` 下载地址：用 `wps.export`，传 `format=docx`
- 需要导出图片：用 `wps.export_image`，传 `format=png/jpeg`，定位 `url` / `link_id` / `file_id` 三选一
- 需要导出 PDF：先 `wps.export`，传 `format=pdf`；再按需用 `wps.query_export`
- 需要导出 AP：先 `wps.export`，传 `format=ap`；再用 `wps.query_export`（`format=ap` 时须传 export 返回的 `file_id`）

## 结构化文档工具

| 能力域 | 说明 | 参考 |
|--------|------|------|
| 书签操作 | 书签域相关操作。 | [书签操作](wps/bookmarks.md) |
| 分隔符操作 | 分隔符域相关操作。 | [分隔符操作](wps/breaks.md) |
| 题注操作 | 题注域相关操作。 | [题注操作](wps/captions.md) |
| 批注操作 | 批注域相关操作。 | [批注操作](wps/comments.md) |
| 内容控件操作 | 内容控件域相关操作。 | [内容控件操作](wps/content_controls.md) |
| 域操作 | 文档域相关操作。 | [域操作](wps/fields.md) |
| 脚注尾注操作 | 脚注尾注域相关操作。 | [脚注尾注操作](wps/footnote_endnotes.md) |
| 公式操作 | 公式域相关操作。 | [公式操作](wps/formulas.md) |
| 页眉页脚操作 | 页眉页脚域相关操作。 | [页眉页脚操作](wps/header_footers.md) |
| 标题操作 | 标题域相关操作。 | [标题操作](wps/headings.md) |
| 超链接操作 | 超链接域相关操作。 | [超链接操作](wps/hyperlinks.md) |
| 图片操作 | 图片域相关操作。 | [图片操作](wps/images.md) |
| 索引操作 | 索引域相关操作。 | [索引操作](wps/indexes.md) |
| 列表操作 | 列表域相关操作。 | [列表操作](wps/lists.md) |
| OLE 对象操作 | OLE 对象域相关操作。 | [OLE 对象操作](wps/ole.md) |
| 文档保护操作 | 文档保护域相关操作。 | [文档保护操作](wps/protection.md) |
| 交叉引用操作 | 交叉引用域相关操作。 | [交叉引用操作](wps/references.md) |
| 修订操作 | 修订域相关操作。 | [修订操作](wps/revisions.md) |
| 节操作 | 节域相关操作。 | [节操作](wps/sections.md) |
| 形状操作 | 形状域相关操作。 | [形状操作](wps/shapes.md) |
| 样式操作 | 样式域相关操作。 | [样式操作](wps/styles.md) |
| 表格操作 | 表格域相关操作。 | [表格操作](wps/tables.md) |
| 文字文档文本操作 | WPS 文字文档中与段落、字符区间相关的文本格式与内容操作。 | [文字文档文本操作](wps/texts.md) |
| 目录操作 | 目录域相关操作。 | [目录操作](wps/tocs.md) |
| 水印操作 | 水印域相关操作。 | [水印操作](wps/watermarks.md) |
| WordML/XML 插入 | WordML/XML 插入域相关操作。 | [WordML/XML 插入](wps/xmls.md) |

#### 导出

> 异步导出为多种格式及状态轮询

| 工具 | 功能简述 | 详情 |
|------|----------|------|
| `wps.export` | 统一导出在线文字文档 | [详情](wps/export.md) |
| `wps.export_image` | 将在线文字导出为图片 | [详情](wps/export_image.md) |
| `wps.query_export` | 统一查询异步导出结果 | [详情](wps/query_export.md) |

### 图片类写操作

以下工具需传入**公网可访问的图片 URL**（服务端会拉取图片）：

| 工具 | 顶层参数 | 说明 |
|------|----------|------|
| `wps.watermarks.image` | `file_path` | 插入图片水印 |
| `wps.shapes.picture` | `file_path` | 插入浮动图片形状 |

## 典型用途

| 场景 | 说明 | 工作流 |
|------|------|--------|
| 空白文档创建 | 新建在线文字后再进入后续编辑流程 | — |
| 文档导出 | 通过 `wps.export`、`wps.export_image`、`wps.query_export` | — |
| AP 生成 | 通过 `wps.export(format=ap)` 与 `wps.query_export(format=ap)` | — |
| 内容读写 | 通过 `wps.texts.content`、`wps.texts.range`、`wps.texts.count` 等 | — |
| 查找替换 | 通过 `wps.texts.search` / `wps.texts.replace` | — |
| 段落格式 | 通过 `wps.texts.alignment`、`wps.texts.indent`、`wps.texts.line_spacing` 等 | — |
| 字符样式（多目标） | 按关键词检索后批量改字体/高亮/下划线等 | `workflows/wps-multi-target-search-style.md` |
| 标题段（大纲） | 按 outline_level 识别标题段后改色/对齐/字距 | `workflows/wps-heading-by-outline.md` |
| 段落对齐缩进边框 | 对齐、缩进、行距、段边框与底纹 | `workflows/wps-paragraph-align-indent.md` |
| 节下正文 | 锚定小节后批量字号/对齐/行距 | `workflows/wps-section-body-format.md` |
| 列表编号 | 项目符号、数字编号、多级列表 | `workflows/wps-lists-and-indent.md` |
| 清除与字体替换 | 清除格式、内置样式、字体替换 | `workflows/wps-clear-and-replace-font.md` |
| 内置样式/ranges | 指定页套用样式、全文间距字号 | `workflows/wps-styles-apply-by-page.md` |
| 页眉页脚页码 | 页眉文字、页脚页码、罗马页码 | `workflows/wps-header-footer-pagination.md` |
| 分节版式 | 分页、分节、页边距、边框、水印 | `workflows/wps-section-break-layout.md` |
| 附件节横向 | 目录与附件分节组合 | `workflows/wps-combo-section-attachment.md` |
| 目录 | 插入/更新/生成目录 | `workflows/wps-toc-lifecycle.md` |
| 题注域公式 | 图片/表格题注、日期域、公式 | `workflows/wps-captions-and-fields.md` |
| 公文与书签 | 公文字体、书签增删 | `workflows/wps-official-and-bookmarks.md` |
| 复制粘贴格式刷 | 纯文本/保留格式/格式刷 | `workflows/wps-copy-paste-format.md` |
| 图片 | 插入、缩放、裁剪、环绕 | `workflows/wps-image-on-page.md` |
| 文本框形状 | 文本框与简单形状文案 | `workflows/wps-shapes-textbox.md` |
| 形状组合叠放 | 箭头、组合、置顶、删图 | `workflows/wps-shapes-draw-compose.md` |
