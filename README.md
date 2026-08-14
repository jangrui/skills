# jangrui/skills

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)
[![Marketplace](https://img.shields.io/badge/Claude%20Code-Marketplace-blue)](#claude-codemarketplace)
[![Codex CLI](https://img.shields.io/badge/Codex%20CLI-Compatible-green)](#codex-cli目录拷贝)
[![Vendored Skills](https://img.shields.io/badge/Vendored%20Skills-258-informational)](#技能目录)
[![Plugins](https://img.shields.io/badge/Plugins-20-informational)](#claude-codemarketplace)
[![Upstream Sync](https://img.shields.io/badge/Upstream%20Sync-Daily%2006%3A00%20UTC-success)](#同步上游)

面向 **Claude Code** 与 **Codex CLI** 的 AI 编程助手 skill 聚合仓库。

不创作 skill 源码，只做两件事：

1. **聚合**：按主题整理优质 Agent Skills，提供上游链接与安装入口
2. **Vendor**：把可自包含的 skill 本地化到 `plugins/`，只保留运行时必需内容，由 CI 每日跟进上游

当前规模：**20 个 marketplace 插件**（含 `golang-core` 别名），涵盖 **258 个 SKILL.md**，分布在 **13 个主题分类**。

---

## 使用方式

### Claude Code（marketplace）

```text
/plugin marketplace add jangrui/skills
/plugin install diagram@jangrui          # 绘图五件套
/plugin install writing@jangrui          # 写作润色 + WPS 笔记
/plugin install ppt@jangrui              # 网页 PPT
/plugin install illustration@jangrui     # 插画 + 社交卡片
/plugin install lark@jangrui             # 飞书全家桶（需 lark-cli）
/plugin install cc-skills-golang@jangrui # Go 生产级技能
/plugin install baoyu-skills@jangrui     # AI 创作合集（需 Bun）
/plugin install grafana-core@jangrui     # Grafana 核心
/plugin install grafana-cloud@jangrui    # Grafana Cloud
/plugin install grafana-lgtm@jangrui     # LGTM 开源栈
/plugin install grafana-plugins@jangrui  # Grafana 插件
/plugin install grafana-app-sdk@jangrui  # Grafana App SDK
/plugin install grafana-k6@jangrui       # k6 负载测试
/plugin install grafana-datasources@jangrui
/plugin install dbx@jangrui              # 数据库 CLI
/plugin install libtv@jangrui            # AI 生图/生视频（需 LIBTV_ACCESS_KEY）
/plugin install khazix-skills@jangrui    # 卡兹克 6 skill（资讯/研究/写作/任务书/收尾/存储）
/plugin install mattpocock-skills@jangrui
/plugin install anydoc@jangrui            # 文档转 Markdown（Word/PPT/Excel/PDF 等，需 Node 20+）
```

### Codex CLI（目录拷贝）

```bash
git clone --depth 1 https://github.com/jangrui/skills.git /tmp/jangrui-skills
cp -r /tmp/jangrui-skills/plugins/diagram/drawio ~/.codex/skills/drawio
cp -r /tmp/jangrui-skills/plugins/writing/humanizer ~/.codex/skills/humanizer
# 以此类推，每个 plugins/<plugin>/<skill>/ 目录即一个 skill
```

重启或新开会话后，skill 会自动发现。

---

## 技能目录

所有 skill 按 vendor 目录组织。插件名即 `@jangrui` 下的安装标识。

| 主题 | 插件 | 本地路径 | 技能数 | 上游 |
|---|---|---|---|---|
| 绘图 | `diagram` | `plugins/diagram/` | 5 | Agents365-ai |
| 写作润色 + 前端设计 | `writing` | `plugins/writing/humanizer*`、`stop-slop`、`no-ai-slop`、`shuorenhua`、`taste/` | 18 | blader/humanizer, op7418/Humanizer-zh, hardikpandya/stop-slop, petergyang/no-ai-slop, MrGeDiao/shuorenhua, Leonxlnx/taste-skill |
| WPS 笔记 | writing（子集） | `plugins/writing/wpsnote/` | 37 | wpsnote/wpsnote-skills |
| 演示文稿 | `ppt` | `plugins/ppt/` | 1 | op7418/guizang-ppt-skill |
| 插画 | `illustration` | `plugins/illustration/` | 2 | helloianneo, op7418 |
| Go 开发 | `cc-skills-golang` | `plugins/golang/` | 46 | samber/cc-skills-golang |
| 飞书/Lark | `lark` | `plugins/lark/` | 27 | larksuite/cli |
| 可观测性 | `grafana-*`（×7） | `plugins/grafana/` | 48 | grafana/skills |
| AI 创作 | `baoyu-skills` | `plugins/baoyu/` | 21 | JimLiu/baoyu-skills |
| 数据库 | `dbx` | `plugins/dbx/` | 1 | t8y2/dbx |
| AI 生图/生视频 | `libtv` | `plugins/libtv/` | 1 | libtv-labs/libtv-skills |
| 卡兹克工具箱 | `khazix-skills` | `plugins/khazix/` | 6 | KKKKhazix/khazix-skills |
| 工程实践 | `mattpocock-skills` | `plugins/mattpocock/` | 22 | mattpocock/skills |
| 文档转 Markdown | `anydoc` | `plugins/anydoc/` | 1 | firecrawl/anydoc |
| Anthropic 官方 | —（不进 marketplace，仅目录拷贝） | `plugins/anthropic/` | 17 | anthropics/skills |

Grafana 拆成 7 个 plugin 允许按需安装，不必一次装全家桶。

### 运行时依赖

| 插件 | 依赖 | 安装方式 |
|---|---|---|
| `lark` | `lark-cli`（npm） | `npx @larksuite/cli@latest install && lark-cli auth login --recommend` |
| `baoyu-skills` | Bun | `brew install oven-sh/bun/bun` |
| `dbx` | `@dbx-app/cli`（npm） | `npm i -g @dbx-app/cli` |
| `libtv` | `python3`（macOS 自带） | 设置环境变量 `LIBTV_ACCESS_KEY` |
| `khazix-skills`（hv-analysis） | Python 3 + `weasyprint`、`markdown`（pip） | `pip install weasyprint markdown`；其余 5 个 skill 零依赖（storage-analyzer 纯标准库） |
| `anydoc` | Node 20+（npx 自动下载 `@firecrawl/anydoc`） | 免安装，首次 `npx -y @firecrawl/anydoc <file>` 即用 |
| `anthropic`（目录拷贝） | Python 3 + 按需 pip 包 | 文档四件套（docx/pdf/pptx/xlsx）零额外依赖；slack-gif-creator 需 `pip install pillow imageio numpy`，webapp-testing 需 `pip install playwright && playwright install chromium`，mcp-builder 脚本需 `pip install anthropic mcp` |
| 其余 | 无 | 拷贝即用 |

---

## 目录结构

```
├── .claude-plugin/marketplace.json    ← Claude Code marketplace 声明
├── plugins/
│   ├── diagram/                       ← 5 个 skill
│   │   ├── drawio/  mermaid/  excalidraw/  tldraw/  plantuml/
│   ├── writing/                       ← 5 润色 + 13 前端设计 + 37 wpsnote
│   │   ├── humanizer/  humanizer-zh/  stop-slop/  no-ai-slop/  shuorenhua/
│   │   ├── taste/                     ← 13 个前端设计 skill
│   │   └── wpsnote/                   ← 37 个 skill
│   ├── ppt/                           ← guizang-ppt
│   ├── illustration/                  ← 插画 + 社交卡片
│   ├── golang/                        ← 46 个 Go skill（扁平）
│   ├── lark/                          ← 27 个飞书 skill（扁平）
│   ├── baoyu/                         ← 21 个 AI 创作 skill（扁平）
│   ├── grafana/                       ← 48 个 skill，7 个 category
│   │   ├── grafana-core/  grafana-cloud/  grafana-lgtm/
│   │   ├── grafana-plugins/  grafana-app-sdk/  grafana-k6/
│   │   └── grafana-datasources/
│   ├── dbx/                           ← 1 个 skill
│   ├── libtv/                         ← 1 个 skill（AI 生图/生视频）
│   ├── khazix/                        ← 6 个卡兹克 skill（扁平）
│   │   ├── aihot/  hv-analysis/  khazix-writer/
│   │   ├── leader/  neat-freak/  storage-analyzer/
│   ├── mattpocock/                    ← 22 个 skill
│   │   ├── engineering/  productivity/
│   ├── anydoc/                        ← 1 个 skill（文档转 Markdown）
│   │   └── convert-documents-to-markdown/
│   └── anthropic/                     ← Anthropic 官方 17 个 skill（扁平）
│       ├── docx/  pdf/  pptx/  xlsx/  ← Office 文档处理
│       ├── claude-api/  mcp-builder/  skill-creator/
│       └── algorithmic-art/  canvas-design/  theme-factory/ 等
├── scripts/                           ← 16 个同步脚本
│   ├── sync-anthropic-skills.sh
│   ├── sync-diagram-skills.sh
│   ├── sync-writing-skills.sh
│   ├── sync-ppt-skills.sh
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
│   └── sync-anydoc-skills.sh
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
git diff plugins/
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

能。Claude Code 走 marketplace；Codex 拷贝 `plugins/` 下目录即可。

### 更新会自动进来吗？

Vendor 项：CI 每天检查上游并开 PR，合并后本地 `/plugin update` 可跟进。

### 如何只装 Grafana 的一部分？

按 category 安装，如 `/plugin install grafana-core@jangrui`。

### 安装 lark 后不能用？

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
- [blader/humanizer](https://github.com/blader/humanizer) — 英文去 AI 痕迹
- [hardikpandya/stop-slop](https://github.com/hardikpandya/stop-slop) — 反 AI 腔写作
- [petergyang/no-ai-slop](https://github.com/petergyang/no-ai-slop) — 移除 20+ AI slop 模式
- [op7418](https://github.com/op7418) — humanizer-zh / guizang-ppt / guizang-social-card
- [samber/cc-skills-golang](https://github.com/samber/cc-skills-golang) — 46 个 Go 生产级技能
- [larksuite/cli](https://github.com/larksuite/cli) — 飞书 27 个 skill
- [grafana/skills](https://github.com/grafana/skills) — 48 个可观测性技能
- [JimLiu/baoyu-skills](https://github.com/JimLiu/baoyu-skills) — 21 个 AI 创作技能
- [wpsnote/wpsnote-skills](https://github.com/wpsnote/wpsnote-skills) — 37 个 WPS 笔记技能
- [t8y2/dbx](https://github.com/t8y2/dbx) — 数据库 CLI 技能
- [libtv-labs/libtv-skills](https://github.com/libtv-labs/libtv-skills) — LibLib.tv 生图/生视频技能
- [KKKKhazix/khazix-skills](https://github.com/KKKKhazix/khazix-skills) — 卡兹克 6 个技能：AI 资讯、横纵分析研究、公众号写作、agent 任务书、知识库收尾、存储分析
- [mattpocock/skills](https://github.com/mattpocock/skills) — 工程实践技能
- [firecrawl/anydoc](https://github.com/firecrawl/anydoc) — 文档转 Markdown 技能
- [anthropics/skills](https://github.com/anthropics/skills) — Anthropic 官方 17 个技能：docx/pdf/pptx/xlsx 文档处理、claude-api 参考、skill-creator、mcp-builder 等（13 个 Apache-2.0；文档四件套为 Anthropic 专属条款，随 skill 保留 LICENSE.txt）
- [Leonxlnx/taste-skill](https://github.com/Leonxlnx/taste-skill) — 13 个 anti-slop 前端设计技能

---

## 许可证

本仓库采用 [MIT](./LICENSE)。所引用和 vendor 的每个 skill 遵循其上游许可条款。
