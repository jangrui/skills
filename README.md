# jangrui/skills

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)
[![Marketplace](https://img.shields.io/badge/Claude%20Code-Marketplace-blue)](#-作为-marketplace-使用claude-code)
[![Codex CLI](https://img.shields.io/badge/Codex%20CLI-Compatible-green)](#-在-codex-中使用)
[![Vendored Skills](https://img.shields.io/badge/Vendored%20Skills-190-informational)](#-技能目录)
[![Plugins](https://img.shields.io/badge/Plugins-17-informational)](#-作为-marketplace-使用claude-code)
[![Upstream Sync](https://img.shields.io/badge/Upstream%20Sync-Daily%2021%3A00%20UTC-success)](#-同步上游)

面向 **Claude Code** 与 **OpenAI Codex CLI** 的 AI 编程助手 skill 索引与 marketplace。

本仓库做两件事：

1. **索引**：按主题整理优质 skill，给出上游链接、一句话说明与安装方式。
2. **Vendor**：把可自包含的 skill 本地化到 `plugins/`，只保留运行时所需内容，并由 CI 每日跟进上游。

> 标注约定  
> - **⊕** = 已入库（vendor 或 remote），可通过本 marketplace 安装  
> - 无符号 = 纯索引，需自行 clone 上游

---

## 目录

- [项目简介](#-项目简介)
- [特性亮点](#-特性亮点)
- [快速开始](#-快速开始)
- [作为 Marketplace 使用（Claude Code）](#-作为-marketplace-使用claude-code)
- [在 Codex 中使用](#-在-codex-中使用)
- [配置说明](#-配置说明)
- [使用示例](#-使用示例)
- [技能目录](#-技能目录)
- [目录结构](#-目录结构)
- [同步上游](#-同步上游)
- [测试方法](#-测试方法)
- [常见问题](#-常见问题)
- [致谢](#-致谢)
- [许可证](#-许可证)

---

## 项目简介

`jangrui/skills` 是一个 **skill 聚合仓库**，不是 skill 源码创作仓库。它把分散在社区各处的 Agent Skills 整理成：

- 可浏览的主题索引（README）
- 可一键安装的 Claude Code marketplace（`.claude-plugin/marketplace.json`）
- 可直接拷贝的 Codex 兼容 skill 本体（`plugins/`）

当前规模：

| 指标 | 数量 |
| --- | ---: |
| Marketplace 插件 | 17 |
| 本地 vendored skill（`SKILL.md`） | 190 |
| 主题分类 | 绘图 / 写作（含 WPS 笔记） / 演示 / 插画 / Go / 飞书 / Grafana / AI 创作 / 数据库 / 工程实践 等 |

适合这些场景：

- 想用 Claude Code 一键安装一组精选 skill
- 想在 Codex CLI 里直接拷贝干净、无噪声的 skill 目录
- 想了解某类 skill 的上游来源、依赖与 vendor 策略

---

## 特性亮点

- **双客户端兼容**：Claude Code marketplace 与 Codex CLI 目录拷贝两种安装路径
- **Vendor 精简**：只保留 `SKILL.md` + 运行时脚本 + `references/` / `assets/`，排除 tests / docs / CI / LICENSE 噪声
- **可追溯版本**：每个 vendored skill 目录含 `.upstream-commit`
- **每日自动同步**：GitHub Actions 每天 21:00 UTC 检查上游并开 PR
- **按需安装**：Grafana 拆成 7 个 category plugin，不必一次装全家桶
- **明确入库边界**：workspace 兄弟包已发布 npm 的可 vendor（如 baoyu-skills）；真正搬不走的才做 remote

---

## 快速开始

### Claude Code（推荐）

```text
/plugin marketplace add jangrui/skills
/plugin install diagram@jangrui
```

装完后在对话中直接说需求，例如：

```text
用 drawio 画一个用户登录时序图
```

### Codex CLI

```bash
git clone --depth 1 https://github.com/jangrui/skills.git /tmp/jangrui-skills
cp -r /tmp/jangrui-skills/plugins/diagram/drawio ~/.codex/skills/drawio
```

重启或新开 Codex 会话后，skill 会自动被发现。

---

## 作为 Marketplace 使用（Claude Code）

本仓库是 Claude Code marketplace，名称为 `jangrui`。

```text
/plugin marketplace add jangrui/skills
```

### Vendor 插件（本地化，可 `/plugin update` 跟进）

```text
/plugin install diagram@jangrui                 # 绘图五件套（5）
/plugin install writing@jangrui                  # 中英文去 AI 痕迹（2）
/plugin install wpsnote-skills@jangrui           # WPS 笔记写作全家桶（36，需 wpsnote-cli）
/plugin install ppt@jangrui                      # 网页 PPT（1）
/plugin install illustration@jangrui             # 文章配图 + 社交卡片（2）
/plugin install lark@jangrui                     # 飞书全家桶（27，需 lark-cli）
/plugin install cc-skills-golang@jangrui         # Go 生产级技能（46）
/plugin install baoyu-skills@jangrui             # 宝玉 AI 创作合集（21，需 Bun）
/plugin install dbx@jangrui                      # 数据库 CLI 探索（1，需 @dbx-app/cli）
/plugin install grafana-core@jangrui             # Grafana 核心（8）
/plugin install grafana-cloud@jangrui            # Grafana Cloud（18）
/plugin install grafana-lgtm@jangrui             # LGTM 开源栈（5）
/plugin install grafana-plugins@jangrui          # 插件开发（5）
/plugin install grafana-app-sdk@jangrui          # App SDK（4）
/plugin install grafana-k6@jangrui               # k6 负载测试（7）
/plugin install grafana-datasources@jangrui      # 数据源 provisioning（1）
```

### Remote 插件（指向上游仓库）

```text
/plugin install mattpocock-skills@jangrui        # 工程实践（TDD / review / grilling 等）
```

### Vendor 一览

| 插件 | 模式 | Skill 数 | 约体积 |
| --- | --- | ---: | ---: |
| `diagram` | 多独立仓库 / 子目录 | 5 | ~1.2 MB |
| `writing` | 多独立仓库 / 子目录（humanizer） | 2 | ~0.1 MB |
| `wpsnote-skills` | 落在 `plugins/writing/wpsnote/`（需 wpsnote-cli） | 36 | ~1.3 MB |
| `ppt` | 单仓库单 skill / 根目录 | 1 | ~0.6 MB |
| `illustration` | 混合（子目录 + 根目录） | 2 | ~3.5 MB |
| `cc-skills-golang` | 单仓库多 skill / 扁平（排除 `evals/`） | 46 | ~2.1 MB |
| `lark` | 单仓库多 skill / 扁平 | 27 | ~5.5 MB |
| `grafana-*`（7 个） | 单仓库多 skill / 两层 category | 48 | ~6.0 MB |
| `baoyu-skills` | 单仓库多 skill / 扁平（兄弟包 npm 发布） | 21 | ~3.4 MB |
| `dbx` | 单仓库多 skill / 扁平（当前 1 个；需 `@dbx-app/cli`） | 1 | ~8 KB |

---

## 在 Codex 中使用

Codex CLI 没有 marketplace，只要把含 `SKILL.md` 的目录放进 skills 路径即可：

| 作用域 | 路径 |
| --- | --- |
| 全局 | `~/.codex/skills/<skill-name>/SKILL.md` |
| 项目级 | `<项目>/.codex/skills/<skill-name>/SKILL.md` |
| 自定义 | `$CODEX_HOME/skills/`（若设置了 `CODEX_HOME`） |

### 方式一：直拷本仓库 vendor 目录（推荐）

```bash
git clone --depth 1 https://github.com/jangrui/skills.git /tmp/jangrui-skills

# 单个 skill
cp -r /tmp/jangrui-skills/plugins/golang/golang-concurrency ~/.codex/skills/golang-concurrency

# 整个分类
cp -r /tmp/jangrui-skills/plugins/lark/lark-* ~/.codex/skills/
cp -r /tmp/jangrui-skills/plugins/grafana/grafana-core/* ~/.codex/skills/
```

### 方式二：clone 上游（纯索引项）

```bash
git clone --depth 1 https://github.com/Agents365-ai/drawio-skill /tmp/drawio-skill
cp -r /tmp/drawio-skill/skills/drawio-skill ~/.codex/skills/drawio
```

---

## 配置说明

### Claude Code

1. 添加 marketplace：`/plugin marketplace add jangrui/skills`
2. 安装插件：`/plugin install <name>@jangrui`
3. 更新插件：`/plugin update`
4. 查看已装插件：`/plugin`

### Codex CLI

1. 确认 skills 目录存在：`mkdir -p ~/.codex/skills`
2. 拷贝 skill 目录（见上一节）
3. 新开会话使 skill 生效

### 有外部依赖的插件

#### 飞书 / Lark

```bash
npx @larksuite/cli@latest install
lark-cli config init
lark-cli auth login --recommend
```

然后安装：

```text
/plugin install lark@jangrui
```

#### baoyu-skills

先安装 Bun（脚本运行时需要）：

```bash
curl -fsSL https://bun.sh/install | bash
```

Claude Code：

```text
/plugin install baoyu-skills@jangrui
```

#### wpsnote-skills

需安装并开通 **WPS 笔记** 的 `wpsnote-cli`：

1. 下载安装 [WPS 笔记](https://www.kdocs.cn/)
2. 打开应用 → 左下角「设置」→「AI 实验室」开通
3. 确认 CLI 可用：

```bash
wpsnote-cli status --json
```

Claude Code：

```text
/plugin install wpsnote-skills@jangrui
```

Codex CLI：

```bash
cp -r /tmp/jangrui-skills/plugins/writing/wpsnote/* ~/.codex/skills/
```

部分 skill（如 `web-importer` / `image-gen`）另需 Python 第三方包（`httpx`、`beautifulsoup4`、`requests` 等），按对应 `SKILL.md` 安装。

#### dbx

先安装 [dbx CLI](https://www.npmjs.com/package/@dbx-app/cli)（并建议安装/配置 DBX Desktop）：

```bash
npm install -g @dbx-app/cli
dbx doctor
```

Claude Code：

```text
/plugin install dbx@jangrui
```

Codex CLI：

```bash
cp -r plugins/dbx/dbx ~/.codex/skills/dbx
```


---

## 使用示例

### 1. 画架构图

```text
根据下面的服务列表，用 mermaid 画一张系统架构图，并导出 SVG：
- API Gateway
- Auth Service
- Order Service
- PostgreSQL
- Redis
```

### 2. 润色中文文案

```text
用 humanizer-zh 检查并改写下面这段文字，去掉 AI 文风痕迹。
```

### 3. 生成网页 PPT

```text
用 guizang-ppt 做一份 8 页产品发布会 PPT，瑞士国际主义风格，主题是「Q3 增长复盘」。
```

### 4. 操作飞书文档

```text
用 lark-doc 在知识库里新建一篇「周报模板」，并分享给我。
```

### 5. 编写 / 校验 PromQL

```text
用 promql 帮我写一个查询：统计过去 5 分钟 HTTP 5xx 错误率，按 service 分组。
```

### 6. Go 并发审查

```text
用 golang-concurrency 审查这个 worker pool 实现，指出竞态与取消传播问题。
```

---

## 技能目录

### 绘图与图表 ⊕

| 技能 | 一句话 | 上游 |
| --- | --- | --- |
| [drawio](https://github.com/Agents365-ai/drawio-skill) | draw.io 图表（PNG/SVG/PDF） | Agents365-ai |
| [mermaid](https://github.com/Agents365-ai/mermaid-skill) | Mermaid 流程图，带语法校验 | Agents365-ai |
| [excalidraw](https://github.com/Agents365-ai/excalidraw-skill) | Excalidraw 手绘风，8 色设计系统 | Agents365-ai |
| [tldraw](https://github.com/Agents365-ai/tldraw-skill) | tldraw 白板图，6 种预设 | Agents365-ai |
| [plantuml](https://github.com/Agents365-ai/plantuml-skill) | PlantUML，经 Kroki 渲染 | Agents365-ai |

```text
/plugin install diagram@jangrui
```

### 写作润色 ⊕

| 技能 | 语言 | 一句话 | 上游 |
| --- | --- | --- | --- |
| [humanizer](https://github.com/blader/humanizer) | 英文 | 去除 AI 写作痕迹 | blader |
| [humanizer-zh](https://github.com/op7418/Humanizer-zh) | 中文 | 检测并改写 24 种中文 AI 文风 | op7418 |

```text
/plugin install writing@jangrui
```

#### wpsnote-skills — WPS 笔记全家桶

[wpsnote/wpsnote-skills](https://github.com/wpsnote/wpsnote-skills)（36 个 skill，位于 `plugins/writing/wpsnote/`）覆盖笔记读写、内容创作发布、信息捕获、灵感引擎、小说写作、学习场景、标签管理、Skill 创建等。需配合 WPS 笔记内置的 `wpsnote-cli`。

| 技能 | 一句话 | 上游 |
| --- | --- | --- |
| [wpsnote-skills](https://github.com/wpsnote/wpsnote-skills) | WPS 笔记全家桶（读写/创作/捕获/学习，需 wpsnote-cli） | WPS Note Team |

```text
/plugin install wpsnote-skills@jangrui
```

### 演示文稿 ⊕

| 技能 | 一句话 | 上游 |
| --- | --- | --- |
| [guizang-ppt-skill](https://github.com/op7418/guizang-ppt-skill) | 横向翻页单文件 HTML PPT，双模板 22 版式 | op7418 |

```text
/plugin install ppt@jangrui
```

### 文章插画与社交卡片 ⊕

| 技能 | 一句话 | 上游 |
| --- | --- | --- |
| [ian-xiaohei-illustrations](https://github.com/helloianneo/ian-xiaohei-illustrations) | 16:9 白底黑线描中文配图 | helloianneo |
| [guizang-social-card-skill](https://github.com/op7418/guizang-social-card-skill) | 小红书/公众号封面，28 种版式 | op7418 |

```text
/plugin install illustration@jangrui
```

### Go 开发 ⊕

| 技能 | 一句话 | 上游 |
| --- | --- | --- |
| [cc-skills-golang](https://github.com/samber/cc-skills-golang) | 46 个生产级 Go skill：并发、错误处理、slog、samber 全家桶、cobra/viper、测试、性能、安全、可观测性、DI、设计模式等 | Samuel Berthe |

```text
/plugin install cc-skills-golang@jangrui
```

### 飞书 / Lark ⊕

| 技能 | 一句话 | 上游 |
| --- | --- | --- |
| [lark-cli](https://github.com/larksuite/cli) | 27 个官方 skill：IM、文档、多维表格、日历、邮箱、任务、知识库、会议、审批、OKR 等 | larksuite |

```text
/plugin install lark@jangrui
```

### Grafana 可观测性 ⊕

拆成 7 个独立 plugin，按需安装：

| 插件 | Skill 数 | 覆盖范围 |
| --- | ---: | --- |
| `grafana-core` | 8 | Dashboard / PromQL / Alloy / Beyla / OTel / Alerting IRM |
| `grafana-cloud` | 18 | Fleet / Adaptive Metrics / 成本 / Admin / ML / 私有连接 |
| `grafana-lgtm` | 5 | Loki / Tempo / Mimir / Prometheus / Pyroscope |
| `grafana-plugins` | 5 | 插件包体积 / React 19 / Scenes / 依赖审计 |
| `grafana-app-sdk` | 4 | CUE kind / reconciler / admission |
| `grafana-k6` | 7 | k6 脚本生成 / 性能测试 / 趋势分析 |
| `grafana-datasources` | 1 | 数据源 provisioning |

上游：[grafana/skills](https://github.com/grafana/skills)

### AI 创作与内容工具 ⊕（vendor）

[JimLiu/baoyu-skills](https://github.com/JimLiu/baoyu-skills)（21 个 skill）覆盖 AI 绘图、内容转换、多平台发布与实用工具。

> 兄弟包（baoyu-chrome-cdp / baoyu-md / baoyu-fetch）已发布到 npm，skill 内 `scripts/package.json` 以版本号声明依赖，运行时 `bun install` 自动解析。

```text
/plugin install baoyu-skills@jangrui
```

也可直接拷贝到 Codex：

```bash
cp -r plugins/baoyu ~/.codex/skills/baoyu
```

### 通用工程实践 ⊕（remote）

| 技能 | 一句话 | 上游 |
| --- | --- | --- |
| [mattpocock-skills](https://github.com/mattpocock/skills) | TDD、code review、grilling、spec/ticket、领域建模 | Matt Pocock |

```text
/plugin install mattpocock-skills@jangrui
```

### 数据库 ⊕（vendor）

| 技能 | 一句话 | 上游 |
| --- | --- | --- |
| [dbx](https://github.com/t8y2/dbx) | 通过 dbx CLI 安全探索 schema / 执行只读 SQL，支持 70+ 数据库 | t8y2 |

```text
/plugin install dbx@jangrui
```


---

## 目录结构

```text
jangrui/skills/
├── README.md                         # 本文件：索引 + 上手文档
├── LICENSE                           # MIT（仅覆盖本索引仓库）
├── .claude-plugin/
│   └── marketplace.json              # Claude Code marketplace 声明
├── plugins/                          # vendored skill 本体
│   ├── diagram/                      # drawio / mermaid / excalidraw / tldraw / plantuml
│   ├── writing/                      # humanizer / humanizer-zh + wpsnote/
│   ├── ppt/guizang-ppt/
│   ├── illustration/
│   ├── golang/golang-*/              # 46 个 Go skill
│   ├── lark/lark-*/                  # 27 个飞书 skill
│   ├── baoyu/baoyu-*/                # 21 个 AI 创作 skill
│   ├── dbx/dbx/                      # 1 个数据库 CLI skill
│   └── grafana/grafana-*/            # 7 个 category × 48 skill
├── scripts/                          # 上游同步脚本
│   ├── sync-diagram-skills.sh
│   ├── sync-writing-skills.sh
│   ├── sync-ppt-skills.sh
│   ├── sync-illustration-skills.sh
│   ├── sync-golang-skills.sh
│   ├── sync-lark-skills.sh
│   ├── sync-baoyu-skills.sh
│   ├── sync-wpsnote-skills.sh
│   ├── sync-dbx-skills.sh
│   └── sync-grafana-skills.sh
└── .github/workflows/                # 每日自动同步 PR
```

---

## 同步上游

环境要求：Git、Bash（兼容 macOS bash 3.2）、`rsync`。

```bash
# dry-run：只检查，不写入
./scripts/sync-diagram-skills.sh --check
./scripts/sync-lark-skills.sh --check
./scripts/sync-golang-skills.sh --check
./scripts/sync-grafana-skills.sh --check
./scripts/sync-baoyu-skills.sh --check
./scripts/sync-wpsnote-skills.sh --check
./scripts/sync-dbx-skills.sh --check

# 实际同步
./scripts/sync-diagram-skills.sh
./scripts/sync-lark-skills.sh lark-base          # 只同步某个 skill
./scripts/sync-grafana-skills.sh grafana-k6      # 只同步某个 category
./scripts/sync-dbx-skills.sh                     # 同步 dbx
./scripts/sync-wpsnote-skills.sh                 # 同步 wpsnote

# review
git diff plugins/
```

通用模式：

```bash
./scripts/sync-<name>-skills.sh --check
./scripts/sync-<name>-skills.sh
./scripts/sync-<name>-skills.sh <子集>
```

CI 每天 21:00 UTC 自动检查上游并开 PR；合并前请人工 review diff。

约定：

- 不在 vendored 目录手改上游 `SKILL.md`（下次同步会覆盖）
- 不用 `git submodule` 拉整仓噪声
- JSON：2 空格缩进、UTF-8、末尾换行
- Commit 前缀：`feat` / `fix` / `chore` / `ci` / `docs`

---

## 测试方法

本仓库没有传统单元测试套件；验证重点是 **同步脚本正确性** 与 **marketplace 一致性**。

### 1. 同步脚本 dry-run

```bash
for s in scripts/sync-*-skills.sh; do
  echo "==> $s"
  bash -n "$s"
  "$s" --check
done
```

### 2. Marketplace 与磁盘对齐

```bash
# skill 数量
find plugins -name SKILL.md | wc -l

# marketplace 插件列表
python3 - <<'PY'
import json
from pathlib import Path
mp = json.loads(Path('.claude-plugin/marketplace.json').read_text())
for p in mp['plugins']:
    skills = p.get('skills') or []
    print(f"{p['name']}: {len(skills) if skills else 'remote'}")
PY
```

### 3. 本地加载验证

- Claude Code：安装插件后，在新会话中触发对应 skill
- Codex CLI：拷贝 skill 目录后，确认会话可发现该 skill

### 4. CI

`.github/workflows/sync-*-skills.yml` 每天 21:00 UTC 自动检查上游；有更新时开 PR，合并前人工 review `git diff`。

---

## 常见问题

### 这个仓库是 skill 源码仓库吗？

不是。它是 **索引 + 精选 vendor**。skill 版权与演进归各自上游。

### Claude Code 和 Codex 都能用吗？

能。Claude Code 走 marketplace；Codex 拷贝 `plugins/` 下目录。

### 为什么有的 skill 不 vendor？

常见原因：

- 需要额外目录筛选（如 mattpocock 含 deprecated / in-progress）

### 更新会自动进来吗？

Vendor 项：CI 每天检查上游并开 PR，合并后本地 `/plugin update` 可跟进。  
Remote 项：跟随上游仓库本身。

### 安装 lark 后不能用？

先安装并登录 `lark-cli`：

```bash
npx @larksuite/cli@latest install
lark-cli config init
lark-cli auth login --recommend
```

### 如何只装 Grafana 的一部分？

按 category 安装，例如只要核心：

```text
/plugin install grafana-core@jangrui
```

### Codex 拷贝后找不到 skill？

检查：

1. 路径是否为 `~/.codex/skills/<name>/SKILL.md`
2. 是否新开了会话
3. 若设置了 `CODEX_HOME`，是否拷到了 `$CODEX_HOME/skills/`

### 可以提交新的 skill 候选吗？

可以。请在 PR 中附上游链接、是否可自包含、建议的 plugin 归属，以及你验证过的安装方式。

---

## 致谢

所有 skill 的版权归各自上游作者，本仓库仅做索引、导航与必要的 vendor 聚合。感谢：

- [Agents365-ai](https://github.com/Agents365-ai)
- [blader/humanizer](https://github.com/blader/humanizer)
- [op7418](https://github.com/op7418)
- [samber/cc-skills-golang](https://github.com/samber/cc-skills-golang)
- [larksuite/cli](https://github.com/larksuite/cli)
- [grafana/skills](https://github.com/grafana/skills)
- [JimLiu/baoyu-skills](https://github.com/JimLiu/baoyu-skills)
- [wpsnote/wpsnote-skills](https://github.com/wpsnote/wpsnote-skills)
- [t8y2/dbx](https://github.com/t8y2/dbx)
- [mattpocock/skills](https://github.com/mattpocock/skills)

---

## 许可证

本索引仓库采用 [MIT](./LICENSE)。

所索引 / 所 vendor 的每个 skill 遵循其**上游仓库**的 License；使用前请阅读对应上游许可条款。
