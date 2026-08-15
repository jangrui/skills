# jangrui/skills

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)
[![Marketplace](https://img.shields.io/badge/Claude%20Code-Marketplace-blue)](#快速开始)

为 **Claude Code**、**Codex CLI**、**Codex 桌面版**和 **ZCode** 整理的可安装 AI Agent Skill 集合。按工作场景安装精选 skill，也可在 `skills/` 中查阅上游 skill。

本仓库不编写 skill 源码，只负责筛选和本地化保留。

## 快速开始

### Claude Code 与 Codex CLI

```text
/plugin marketplace add jangrui/skills
/plugin install daily@jangrui  # 推荐：日常写作润色与会话收尾
```

### Codex 桌面版与 ZCode

在各自的插件市场中添加 `jangrui/skills`，再安装所需场景组。ZCode 会将本仓库作为插件根缓存；安装多个场景组会重复占用磁盘空间。

## 按场景安装

添加市场后，可按需安装整组：

```text
# 每组一条命令装全组；组内容与依赖见下方目录表
/plugin install coding@jangrui        # 代码
/plugin install collab@jangrui        # 协作
/plugin install daily@jangrui         # 常用必备
/plugin install design@jangrui        # 设计
/plugin install diagram@jangrui       # 画图
/plugin install opc@jangrui           # OPC
/plugin install observability@jangrui # 可观测性
/plugin install office@jangrui        # 办公
/plugin install video@jangrui         # 视频
/plugin install writing@jangrui       # 写作
```

## 技能目录

所有 skill 按 vendor 目录组织；下表列出各场景组及其来源。

| 场景组 | 内容 | 本地路径 | 上游 |
|---|---|---|---|
| `daily` 常用必备 | 去 AI 味润色与会话收尾 | `skills/humanizer/`、`skills/khazix/` 等 | blader/humanizer 等 |
| `coding` 代码 | Go 工程、工程实践与数据库 | `skills/golang/` `skills/mattpocock/` `skills/dbx/` | samber、mattpocock、t8y2 |
| `design` 设计 | taste 前端设计 | `skills/taste/` | Leonxlnx/taste-skill |
| `opc` | OPC 生图与平台调研 | `skills/opc/` | ReScienceLab/opc-skills |
| `observability` 运维可观测 | Grafana Core 与 LGTM | `skills/grafana/` | grafana/skills |
| `office` 日常办公 | 文档处理、anydoc 与网页 PPT | `skills/anthropic/` `skills/anydoc/` `skills/ppt/` | anthropics、firecrawl、op7418 |
| `collab` 协作套件 | 飞书与 WPS 笔记 | `skills/lark/` `skills/wpsnote/` | larksuite、wpsnote |
| `diagram` 图表与架构 | mermaid / drawio / plantuml / archify | `skills/drawio/` 等 | Agents365-ai、tt-a1i/archify |
| `video` 视频制作 | 产品视频、LibLib 生图生视频与短剧 | `skills/shotcraft/` `skills/libtv/` `skills/shuohao/` | Vincentwei1021、libtv-labs、eternityspring |
| `writing` 写作 | 宝玉 AI 创作、gzh 排版、插画与社交卡片 | `skills/baoyu/` `skills/gzh/` `skills/illustration/` | JimLiu/baoyu-skills、isjiamu、helloianneo/op7418 |

## 按需配置运行时依赖

下表列出常用场景组的主要依赖；其他 skill 的依赖以各自的 `SKILL.md` 为准。

| 组件（组·skill） | 依赖 | 安装方式 |
|---|---|---|
| opc | 各 skill 对应 API key（reddit 免 key） | 生图需 `GEMINI_API_KEY`（logo 另需 REMOVE_BG/RECRAFT），twitter/producthunt/seo-geo/requesthunt 见各 SKILL.md |
| collab·飞书 | `lark-cli` | `npx @larksuite/cli@latest install` 或 `brew install jangrui/tap/lark-cli`；首次使用执行 `lark-cli config init --new`，再 `lark-cli auth login --recommend` |
| collab·WPS 笔记 | `wpsnote-cli` | 按其官方说明安装 |
| office·anydoc | Node 20+（npx 自动下载 `@firecrawl/anydoc`） | 免安装，首次 `npx -y @firecrawl/anydoc <file>` 即用 |
| office·文档处理 | Node.js、Python 3、LibreOffice 等（因 skill 而异） | 按各 `SKILL.md` 安装所需工具 |
| writing·宝玉 | Bun | `brew install oven-sh/bun/bun` |
| coding·dbx | DBX Desktop、至少一个已配置连接、`@dbx-app/cli` | 用 `brew install --cask dbx` 安装桌面端，再 `brew install dbx-cli` 或 `npm i -g @dbx-app/cli`；用 `dbx doctor` 检查环境 |
| video·libtv | Python 3 | 设置环境变量 `LIBTV_ACCESS_KEY` |
| video·shotcraft | Node 20+ + Remotion（npm） | 模板工程内 `npm install` 即可渲染；页面截图需 `npm i puppeteer`，卡点分析可选 `pip install librosa`，剪映导出可选 `pip install pyJianYingDraft` |
| video·短剧 | Node 20+（质量门/报告渲染脚本只用内置模块） | 免安装，脚本随 skill 自带 |
| daily·neat-freak | 无 | 即装即用 |
| 其余 | 见各 `SKILL.md` | 按说明安装 |

## 常见问题

### 场景组和 `skills/` 全集有什么区别？

场景组是市场中可直接安装的精选集合；`skills/` 保留各 vendor 的完整 skill 供查阅。

### 为什么安装后仍不能使用某个 skill？

先查看上方依赖表和该 skill 的 `SKILL.md`。有些 skill 需要 API Key、CLI、桌面端连接或特定运行时。

### 为什么 ZCode 会占用较多磁盘空间？

每个场景组都以整个仓库为插件根缓存；安装多个组会产生重复缓存。

## 致谢

所有 skill 的版权归各自上游作者，本仓库仅做索引、导航与必要的 vendor 聚合。感谢：

- [Agents365-ai](https://github.com/Agents365-ai) — diagram skills
- [tt-a1i/archify](https://github.com/tt-a1i/archify) — 交互式系统架构图
- [blader/humanizer](https://github.com/blader/humanizer) — 英文去 AI 痕迹
- [hardikpandya/stop-slop](https://github.com/hardikpandya/stop-slop) — 反 AI 腔写作
- [petergyang/no-ai-slop](https://github.com/petergyang/no-ai-slop) — 移除 AI slop 写作模式
- [MrGeDiao/shuorenhua](https://github.com/MrGeDiao/shuorenhua) — 说人话：按场景清理中英文文本的 AI 套路
- [op7418](https://github.com/op7418) — humanizer-zh / guizang-ppt / guizang-social-card
- [isjiamu/gzh-design-skill](https://github.com/isjiamu/gzh-design-skill) — 微信公众号文章排版引擎（AGPL-3.0）
- [samber/cc-skills-golang](https://github.com/samber/cc-skills-golang) — Go 生产级技能
- [larksuite/cli](https://github.com/larksuite/cli) — 飞书 skill
- [grafana/skills](https://github.com/grafana/skills) — 可观测性技能
- [JimLiu/baoyu-skills](https://github.com/JimLiu/baoyu-skills) — AI 创作技能
- [eternityspring/shuohao-skills](https://github.com/eternityspring/shuohao-skills) — AI 短剧制作：角色设定集、改编大纲、美术设定、剧本、分镜（Apache-2.0）
- [wpsnote/wpsnote-skills](https://github.com/wpsnote/wpsnote-skills) — WPS 笔记技能
- [t8y2/dbx](https://github.com/t8y2/dbx) — 数据库 CLI 技能
- [libtv-labs/libtv-skills](https://github.com/libtv-labs/libtv-skills) — LibLib.tv 生图/生视频技能
- [KKKKhazix/khazix-skills](https://github.com/KKKKhazix/khazix-skills) — AI 资讯、横纵分析研究、公众号写作、任务书、知识库收尾与存储分析
- [mattpocock/skills](https://github.com/mattpocock/skills) — 工程实践技能
- [firecrawl/anydoc](https://github.com/firecrawl/anydoc) — 文档转 Markdown 技能
- [anthropics/skills](https://github.com/anthropics/skills) — Anthropic 官方 skill：docx/pdf/pptx/xlsx 文档处理、claude-api 参考、skill-creator、mcp-builder 等（部分采用 Apache-2.0；文档处理 skill 为 Anthropic 专属条款，随 skill 保留 LICENSE.txt）
- [Leonxlnx/taste-skill](https://github.com/Leonxlnx/taste-skill) — anti-slop 前端设计技能
- [Vincentwei1021/video-shotcraft](https://github.com/Vincentwei1021/video-shotcraft) — 电影感产品视频制作：镜头配方卡、Ink Press 宣传片模板、Remotion 组件与音频资产（Apache-2.0）

## 许可证

本仓库采用 [MIT](./LICENSE)。所引用和 vendor 的每个 skill 遵循其上游许可条款。
