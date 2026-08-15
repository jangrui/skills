# jangrui/skills

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)
[![Marketplace](https://img.shields.io/badge/Claude%20Code-Marketplace-blue)](#claude-codemarketplace)
[![Codex CLI](https://img.shields.io/badge/Codex%20CLI-Compatible-green)](#codex-cli目录拷贝)
[![Vendored Skills](https://img.shields.io/badge/Vendored%20Skills-276-informational)](#技能目录)
[![Plugins](https://img.shields.io/badge/Plugins-10-informational)](#claude-codemarketplace)
[![Upstream Sync](https://img.shields.io/badge/Upstream%20Sync-Daily%2006%3A00%20UTC-success)](#同步上游)

面向 **Claude Code** 与 **Codex CLI** 的 AI 编程助手 skill 聚合仓库。

不创作 skill 源码，只做两件事：

1. **聚合**：按主题整理优质 Agent Skills，提供上游链接与安装入口
2. **Vendor**：把可自包含的 skill 本地化到 `skills/`，只保留运行时必需内容，由 CI 每日跟进上游

当前规模：**10 个使用场景组插件**（共 86 个精选 skill，每组跨 vendor 组合），vendor 全集 **276 个 SKILL.md**。市场只放精选，全集见 `skills/` 目录自取。

---

## 使用方式

### Claude Code（marketplace）

```text
/plugin marketplace add jangrui/skills

# 每组一条命令装全组；daily 为 AGENTS 必备调用，其余按需
/plugin install daily@jangrui         # 常用必备：去 AI 味润色 5 + 会话收尾（6 个）
/plugin install coding@jangrui        # 代码：Go 工程 11 + 工程实践 4 + dbx（16 个）
/plugin install design@jangrui        # 设计：taste anti-slop 前端设计（4 个）
/plugin install marketing@jangrui     # 营销：OPC 生图 3 + 平台调研 6（9 个，各自需 API key）
/plugin install observability@jangrui # 运维可观测：Grafana 核心 5 + LGTM 栈 5（10 个）
/plugin install office@jangrui        # 办公：文档四件套 + anydoc + 网页 PPT（6 个）
/plugin install collab@jangrui        # 协作套件：飞书 8 + WPS 笔记 6（未来加腾讯文档、钉钉等）
/plugin install diagram@jangrui       # 画图：mermaid / drawio / plantuml / archify（4 个）
/plugin install video@jangrui         # 视频：电影感产品视频 + LibLib 生图生视频 + AI 短剧 5（7 个）
/plugin install writing@jangrui       # 写作：宝玉 AI 创作 7 + 公众号排版 + 插画 + 社交卡片（10 个）
```

### Codex CLI（目录拷贝）

```bash
git clone --depth 1 https://github.com/jangrui/skills.git /tmp/jangrui-skills
cp -r /tmp/jangrui-skills/skills/drawio/drawio ~/.codex/skills/drawio
cp -r /tmp/jangrui-skills/skills/humanizer/humanizer ~/.codex/skills/humanizer
# 以此类推，每个 skills/<plugin>/<skill>/ 目录即一个 skill
```

重启或新开会话后，skill 会自动发现。

---

## 技能目录

所有 skill 按 vendor 目录组织；marketplace 条目是按使用场景组合的 **8 个组插件**，组成员为各全集的精选子集。

| 组插件 | 内容 | 本地路径（全集） | 精选/全集 | 上游 |
|---|---|---|---|---|
| `daily` 常用必备 | 去 AI 味润色 5 + neat-freak | `skills/humanizer/` 等 5 仓 `skills/khazix/` | 6 | blader/humanizer 等 |
| `coding` 代码 | Go 工程 11 + 工程实践 4 + dbx | `skills/golang/` `skills/mattpocock/` `skills/dbx/` | 16/73 | samber、mattpocock、t8y2 |
| `design` 设计 | taste 前端设计 4 | `skills/taste/` | 4/13 | Leonxlnx/taste-skill |
| `marketing` 营销增长 | OPC 生图 3（nanobanana/logo/banner）+ 调研 6（reddit/twitter/producthunt/requesthunt/seo-geo/domain-hunter） | `skills/opc/` | 9/10 | ReScienceLab/opc-skills |
| `observability` 运维可观测 | Grafana 核心 5 + LGTM 栈 5 | `skills/grafana/` | 10/49 | grafana/skills |
| `office` 日常办公 | 文档四件套 + anydoc + 网页 PPT | `skills/anthropic/` `skills/anydoc/` `skills/ppt/` | 6/19 | anthropics、firecrawl、op7418 |
| `collab` 协作套件 | 飞书 8 + WPS 笔记 6（未来加腾讯文档、钉钉等） | `skills/lark/` `skills/wpsnote/` | 14/64 | larksuite、wpsnote |
| `diagram` 画图绘图 | mermaid / drawio / plantuml / archify | `skills/drawio/` 等 6 仓 | 4/6 | Agents365-ai、tt-a1i/archify |
| `video` 做视频 | 电影感产品视频 + LibLib 生图生视频 + 烁皓短剧 5 | `skills/shotcraft/` `skills/libtv/` `skills/shuohao/` | 7/7 | Vincentwei1021、libtv-labs、eternityspring |
| `writing` 写作 | 宝玉 AI 创作 + gzh 排版 + 插画 + 社交卡片 | `skills/baoyu/` `skills/gzh/` `skills/illustration/` | 10/24 | JimLiu/baoyu-skills、isjiamu、helloianneo/op7418 |

市场**仅由 `.claude-plugin/marketplace.json` 单文件策展**：10 个组条目、组内 skills 路径相对仓库根、`source: "./"`，无任何生成物。Claude Code 与 Codex 原生消费条目内联 skills；ZCode 也能看到 skill——但 `source: "./"` 意味着插件根 = 整个仓库，ZCode 安装时会把整仓（约 130MB）复制进每组缓存，多组安装注意磁盘占用。

不上市场的全集（如 grafana-k6 / grafana-cloud / 插件开发、anthropic 其余 13 个、wpsnote 其余 30 个等）仍完整保留在 `skills/` 下，可按 Codex 目录拷贝方式自取。

### 运行时依赖

| 组件（组·skill） | 依赖 | 安装方式 |
|---|---|---|
| marketing·OPC 9 件 | 各 skill 对应 API key（reddit 免 key） | 生图需 `GEMINI_API_KEY`（logo 另需 REMOVE_BG/RECRAFT），twitter/producthunt/seo-geo/requesthunt 见各 SKILL.md |
| collab·飞书 8 件 | `lark-cli`（npm） | `npx @larksuite/cli@latest install && lark-cli auth login --recommend` |
| collab·WPS 笔记 6 件 | `wpsnote-cli` | 按其官方说明安装 |
| office·anydoc | Node 20+（npx 自动下载 `@firecrawl/anydoc`） | 免安装，首次 `npx -y @firecrawl/anydoc <file>` 即用 |
| office·文档四件套 | 零额外依赖 | 自取 anthropic 其余 skill 按需 pip（slack-gif-creator 需 `pip install pillow imageio numpy`，webapp-testing 需 `pip install playwright && playwright install chromium`，mcp-builder 脚本需 `pip install anthropic mcp`） |
| writing·宝玉 | Bun | `brew install oven-sh/bun/bun` |
| coding·dbx | `@dbx-app/cli`（npm） | `npm i -g @dbx-app/cli` |
| video·libtv | `python3`（macOS 自带） | 设置环境变量 `LIBTV_ACCESS_KEY` |
| video·shotcraft | Node 20+ + Remotion（npm） | 模板工程内 `npm install` 即可渲染；页面截图需 `npm i puppeteer`，卡点分析可选 `pip install librosa`，剪映导出可选 `pip install pyJianYingDraft` |
| video·短剧 5 件 | Node 20+（质量门/报告渲染脚本只用内置模块） | 免安装，脚本随 skill 自带 |
| daily·neat-freak | 无 | 即装即用（khazix 全集中 hv-analysis 自取需 `pip install weasyprint markdown`） |
| 其余 | 无 | 拷贝即用 |

---

## 目录结构

```
├── .claude-plugin/marketplace.json    ← 唯一策展文件（10 个使用场景组条目 + skills 路径，source "./"，无生成物）
├── skills/                           ← 按源仓库归属，一仓一目录（不再建主题聚合目录）
│   ├── drawio/                        ← Agents365-ai/drawio-skill
│   ├── mermaid/                       ← Agents365-ai/mermaid-skill
│   ├── excalidraw/                    ← Agents365-ai/excalidraw-skill（未精选）
│   ├── tldraw/                        ← Agents365-ai/tldraw-skill（未精选）
│   ├── plantuml/                      ← Agents365-ai/plantuml-skill
│   ├── archify/                       ← tt-a1i/archify 交互式架构图
│   ├── humanizer/                     ← blader/humanizer（去 AI 味，英）
│   ├── humanizer-zh/                  ← op7418/Humanizer-zh（去 AI 味，中）
│   ├── stop-slop/                     ← hardikpandya/stop-slop
│   ├── no-ai-slop/                    ← petergyang/no-ai-slop
│   ├── shuorenhua/                    ← MrGeDiao/shuorenhua
│   ├── taste/                         ← Leonxlnx/taste-skill 13 个前端设计 skill
│   ├── wpsnote/                       ← wpsnote/wpsnote-skills 37 个 skill
│   ├── ppt/                           ← guizang-ppt
│   ├── gzh/                           ← gzh-design 公众号文章排版
│   ├── illustration/                  ← 插画 + 社交卡片
│   ├── golang/                        ← 46 个 Go skill（扁平）
│   ├── lark/                          ← 27 个飞书 skill（扁平）
│   ├── baoyu/                         ← 21 个 AI 创作 skill（扁平）
│   ├── shuohao/                       ← 5 个 AI 短剧制作 skill（小说→角色/大纲/美术/剧本/分镜）
│   │   └── novel-characters/  novel-outline/  novel-art/  novel-script/  novel-storyboard/
│   ├── grafana/                       ← 49 个 skill，7 个 category
│   │   ├── grafana-core/  grafana-cloud/  grafana-lgtm/
│   │   ├── grafana-skills/  grafana-app-sdk/  grafana-k6/
│   │   └── grafana-datasources/
│   ├── dbx/                           ← 1 个 skill
│   ├── libtv/                         ← 1 个 skill（AI 生图/生视频）
│   ├── opc/                           ← 10 个 solopreneur 营销/设计 skill（扁平）
│   │   ├── nanobanana/  logo-creator/  banner-creator/  ← Gemini 生图设计
│   │   ├── reddit/  twitter/  producthunt/  requesthunt/  ← 平台调研
│   │   └── seo-geo/  domain-hunter/  archive/
│   ├── shotcraft/                     ← 1 个电影感产品视频 skill（约 50MB，音频资产占大头）
│   │   └── video-shotcraft/           ← 镜头配方卡 + Ink Press 模板 + Remotion 组件/SFX
│   ├── khazix/                        ← 6 个卡兹克 skill（扁平）
│   │   ├── aihot/  hv-analysis/  khazix-writer/
│   │   ├── leader/  neat-freak/  storage-analyzer/
│   ├── mattpocock/                    ← 26 个 skill（engineering + productivity）
│   │   ├── engineering/  productivity/
│   ├── anydoc/                        ← 1 个 skill（文档转 Markdown）
│   │   └── convert-documents-to-markdown/
│   └── anthropic/                     ← Anthropic 官方 17 个 skill（扁平）
│       ├── docx/  pdf/  pptx/  xlsx/  ← Office 文档处理
│       ├── claude-api/  mcp-builder/  skill-creator/
│       └── algorithmic-art/  canvas-design/  theme-factory/ 等
├── scripts/                           ← 20 个同步脚本
│   ├── sync-anthropic-skills.sh
│   ├── sync-diagram-skills.sh
│   ├── sync-writing-skills.sh
│   ├── sync-ppt-skills.sh
│   ├── sync-gzh-skills.sh
│   ├── sync-illustration-skills.sh
│   ├── sync-golang-skills.sh
│   ├── sync-lark-skills.sh
│   ├── sync-grafana-skills.sh
│   ├── sync-baoyu-skills.sh
│   ├── sync-mattpocock-skills.sh
│   ├── sync-wpsnote-skills.sh
│   ├── sync-dbx-skills.sh
│   ├── sync-libtv-skills.sh
│   ├── sync-khazix-skills.sh
│   ├── sync-taste-skills.sh
│   ├── sync-anydoc-skills.sh
│   ├── sync-opc-skills.sh
│   ├── sync-shuohao-skills.sh
│   └── sync-shotcraft-skills.sh
└── .github/workflows/                 ← 每日自动同步
```

---

## 同步上游

需求：Git、Bash、`rsync`。

```bash
# dry-run：只检查不写入
./scripts/sync-diagram-skills.sh --check

# 同步
./scripts/sync-diagram-skills.sh

# 同步子集（只同步某个 category 或 skill）
./scripts/sync-grafana-skills.sh grafana-k6
./scripts/sync-lark-skills.sh lark-base
./scripts/sync-mattpocock-skills.sh engineering/tdd

# review
git diff skills/
```

CI（GitHub Actions）每天 06:00 UTC 自动检查上游更新并开 PR。合并前请人工 review。

### 约定

- 不在 vendored 目录手改上游 SKILL.md（下次同步会覆盖）
- 不用 `git submodule`，统一 sparse-checkout + rsync
- JSON：2 空格缩进，UTF-8，末尾换行
- commit 前缀：`feat`/`fix`/`chore`/`ci`/`docs`

---

## 入库决策

不是所有 Agent Skill 项目都适合 vendor。核心判断框架：

1. **一票否决**：SKILL 的输出必须由另一个独立 CLI 执行才有意义 → 不放（闭环系统）
2. **CLI 安装渠道**：只有源码构建无 Release → 不放
3. **运行时依赖**：能否跟着 skill 目录一起搬？
   - 纯 SKILL.md + references → ✅ vendor
   - 依赖 npm 外部包 → ✅ vendor
   - 依赖独立 CLI（已发布）→ ✅ vendor
   - 依赖 workspace 未发布兄弟包 → ❌ remote

---

## 常见问题

### 这个仓库是 skill 源码仓库吗？

不是。它是索引 + 精选 vendor。skill 版权与演进归各自上游。

### Claude Code 和 Codex 都能用吗？

能。Claude Code 走 marketplace；Codex 拷贝 `skills/` 下目录即可。

### 更新会自动进来吗？

Vendor 项：CI 每天检查上游并开 PR，合并后本地 `/plugin update` 可跟进。

### marketplace 为什么没有某个 skill / 全量合集？

marketplace 是策展层，只放精选子集（条目 `skills` 数组即完整集合）。全集始终在 `skills/` 下，两种自取方式：Codex 式目录拷贝，或 fork 后在 marketplace.json 里把路径加进对应条目。

### 如何只装 Grafana 的一部分？

市场提供 `grafana-core` 与 `grafana-lgtm` 两个精选；k6、Cloud、插件开发等从 `skills/grafana/` 目录自取。

### 安装 lark-core 后不能用？

先安装并登录 `lark-cli`：

```bash
npx @larksuite/cli@latest install
lark-cli config init
lark-cli auth login --recommend
```

### Codex 拷贝后找不到 skill？

检查路径是否为 `~/.codex/skills/<name>/SKILL.md`，是否新开了会话。

### 可以提交新的 skill 候选吗？

可以，请在 PR 中附上游链接、是否可自包含、建议的 plugin 归属。

---

## 致谢

所有 skill 的版权归各自上游作者，本仓库仅做索引、导航与必要的 vendor 聚合。感谢：

- [Agents365-ai](https://github.com/Agents365-ai) — diagram skills
- [tt-a1i/archify](https://github.com/tt-a1i/archify) — 交互式系统架构图
- [blader/humanizer](https://github.com/blader/humanizer) — 英文去 AI 痕迹
- [hardikpandya/stop-slop](https://github.com/hardikpandya/stop-slop) — 反 AI 腔写作
- [petergyang/no-ai-slop](https://github.com/petergyang/no-ai-slop) — 移除 20+ AI slop 模式
- [op7418](https://github.com/op7418) — humanizer-zh / guizang-ppt / guizang-social-card
- [isjiamu/gzh-design-skill](https://github.com/isjiamu/gzh-design-skill) — 微信公众号文章排版引擎（AGPL-3.0）
- [samber/cc-skills-golang](https://github.com/samber/cc-skills-golang) — 46 个 Go 生产级技能
- [larksuite/cli](https://github.com/larksuite/cli) — 飞书 27 个 skill
- [grafana/skills](https://github.com/grafana/skills) — 49 个可观测性技能
- [JimLiu/baoyu-skills](https://github.com/JimLiu/baoyu-skills) — 21 个 AI 创作技能
- [eternityspring/shuohao-skills](https://github.com/eternityspring/shuohao-skills) — 5 个 AI 短剧制作技能：角色设定集、改编大纲、美术设定、剧本、分镜（Apache-2.0）
- [wpsnote/wpsnote-skills](https://github.com/wpsnote/wpsnote-skills) — 37 个 WPS 笔记技能
- [t8y2/dbx](https://github.com/t8y2/dbx) — 数据库 CLI 技能
- [libtv-labs/libtv-skills](https://github.com/libtv-labs/libtv-skills) — LibLib.tv 生图/生视频技能
- [KKKKhazix/khazix-skills](https://github.com/KKKKhazix/khazix-skills) — 卡兹克 6 个技能：AI 资讯、横纵分析研究、公众号写作、agent 任务书、知识库收尾、存储分析
- [mattpocock/skills](https://github.com/mattpocock/skills) — 工程实践技能
- [firecrawl/anydoc](https://github.com/firecrawl/anydoc) — 文档转 Markdown 技能
- [anthropics/skills](https://github.com/anthropics/skills) — Anthropic 官方 17 个技能：docx/pdf/pptx/xlsx 文档处理、claude-api 参考、skill-creator、mcp-builder 等（13 个 Apache-2.0；文档四件套为 Anthropic 专属条款，随 skill 保留 LICENSE.txt）
- [Leonxlnx/taste-skill](https://github.com/Leonxlnx/taste-skill) — 13 个 anti-slop 前端设计技能
- [Vincentwei1021/video-shotcraft](https://github.com/Vincentwei1021/video-shotcraft) — 电影感产品视频制作技能：106 张镜头配方卡、Ink Press 宣传片模板、Remotion 组件与音频资产（Apache-2.0）

---

## 许可证

本仓库采用 [MIT](./LICENSE)。所引用和 vendor 的每个 skill 遵循其上游许可条款。
