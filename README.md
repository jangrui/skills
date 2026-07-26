# jangrui 的 AI 编程助手技能目录

一个按主题分类的技能导航,适用于 **Claude Code** 与 **OpenAI Codex CLI** 两类客户端。本仓库只做索引,不持有任何 skill 源码——所有技能均链接到上游作者维护的原始仓库。

- 🤖 **Claude Code**:目录里的「标准 plugin」可一键安装,见 [作为 Marketplace 使用](#-作为-marketplace-使用)。
- 🧠 **Codex CLI**:所有技能均兼容,把 `SKILL.md` 所在文件夹放进 `~/.codex/skills/` 即自动加载,见 [在 Codex 中使用](#-在-codex-中使用)。

---

## 📐 绘图与图表

把自然语言、源码或架构描述转成专业图表。

| 技能 | 一句话 | 来源 |
| --- | --- | --- |
| [drawio-skill](https://github.com/Agents365-ai/drawio-skill) | draw.io 图表(可导出 PNG/SVG/PDF) | Agents365-ai |
| [mermaid-skill](https://github.com/Agents365-ai/mermaid-skill) | Mermaid 流程图,带语法校验 | Agents365-ai |
| [excalidraw-skill](https://github.com/Agents365-ai/excalidraw-skill) | Excalidraw 手绘风图,内置 8 色设计系统 | Agents365-ai |
| [tldraw-skill](https://github.com/Agents365-ai/tldraw-skill) | tldraw 白板图,6 种预设 + 视觉自检 | Agents365-ai |
| [plantuml-skill](https://github.com/Agents365-ai/plantuml-skill) | PlantUML,经 Kroki 渲染,无需本地 Java | Agents365-ai |

> 这 5 个均为单 skill 仓库,无 `plugin.json`。
> - **Claude Code**:已聚合为本目录的 `diagram` 插件,`/plugin install diagram@jangrui` 一次装全(见 [作为 Marketplace 使用](#-作为-marketplace-使用));亦可直连上游聚合仓库 `/plugin marketplace add Agents365-ai/365-skills`。
> - **Codex**:clone 后把 `skills/<名字>/` 拷进 `~/.codex/skills/`。

## 📝 笔记与知识管理

| 技能 | 一句话 | 来源 |
| --- | --- | --- |
| [wpsnote-skills](https://github.com/wpsnote/wpsnote-skills) | WPS 笔记全场景 Agent Skills(40+ skill,覆盖读写、创作、搜索、学习) | WPS Note Team |

> 本身是一个 marketplace。
> - **Claude Code**:`/plugin marketplace add wpsnote/wpsnote-skills`。
> - **Codex**:clone 后把想要的 `skills/<名字>/` 子目录拷进 `~/.codex/skills/`(共 40+ 个)。

## 🐹 Go 开发

| 技能 | 一句话 | 来源 |
| --- | --- | --- |
| [cc-skills-golang](https://github.com/samber/cc-skills-golang) | 生产级 Go 项目技能集（46 个 skill）：并发、错误处理、slog、samber 全家桶（lo/mo/ro/oops/hot/do）、cobra/viper、stretchr/testify、uber dig/fx、google wire、测试、性能、安全、可观测性、grpc、graphql、数据库、依赖注入、设计模式、项目布局、命名、现代化改造、文档、Swagger、troubleshooting 等 | Samuel Berthe |

> ⊕ 标准插件，已 vendor 到本目录的 `golang` 插件，可经 marketplace 一键安装。
> - **Claude Code**：`/plugin install cc-skills-golang@jangrui`
> - **Codex**：从 `plugins/golang/golang-<skill>/` 拷进 `~/.codex/skills/`，例如：
>   ```bash
>   # 装某个 skill
>   cp -r plugins/golang/golang-concurrency ~/.codex/skills/golang-concurrency
>   # 装全部
>   cp -r plugins/golang/golang-* ~/.codex/skills/
>   ```
>
> **vendor 策略**：与 `lark` 同属「单仓库多 skill / 扁平」型，把 46 个 `golang-*` skill 本体（SKILL.md + references/ + assets/，约 2.2 MB）vendor 到 `plugins/golang/<skill名>/`。排除上游的 `evals/`（CI 评估数据，0 个 SKILL.md 引用，纯非运行时文件，排除省 32% 体积）。CI 每天 21:00 UTC 自动检查上游并开 PR。

## 🛠️ 通用工程实践

| 技能 | 一句话 | 来源 |
| --- | --- | --- |
| [mattpocock-skills](https://github.com/mattpocock/skills) | TDD、code review、grilling 追问法、spec/ticket 流程、领域建模等 22 个工程技能 | Matt Pocock |

> ⊕ 标准插件,可经本目录的 marketplace 一键安装。

## 🗄️ 数据库

| 技能 | 一句话 | 来源 |
| --- | --- | --- |
| [dbx skill](https://github.com/t8y2/dbx) (位于 `skills/dbx/`) | 通过 dbx CLI 安全探索 schema、执行只读 SQL(写操作需确认),支持 70+ 数据库 | t8y2 |

> 需先安装 [dbx CLI](https://github.com/t8y2/dbx);skill 文件在仓库的 `skills/dbx/` 子目录。
> - **Claude Code** / **Codex**:clone 后把 `skills/dbx/` 拷进各自的 skills 目录(`~/.claude/skills/` 或 `~/.codex/skills/`)。

## ✍️ 写作润色

| 技能 | 一句话 | 语言 | 来源 |
| --- | --- | --- | --- |
| [humanizer](https://github.com/blader/humanizer) | 去除 AI 写作痕迹,让文字更自然(基于维基百科「Signs of AI writing」) | 英文 | blader |
| [Humanizer-zh](https://github.com/op7418/Humanizer-zh) | 检测并改写 24 种中文 AI 文风痕迹(宣传式语言、过度象征、破折号滥用等) | 中文 | op7418 |

> 两者均为 ⊕ 标准插件,可经本目录的 marketplace 一键安装。
> - **Claude Code**:`humanizer`(英文)和 `humanizer-zh`(中文)都走下方 marketplace。
> - **Codex**:两者都整个 clone 到 `~/.codex/skills/<名字>/`。可并用。

## 🐦 飞书 / Lark

飞书官方 `lark-cli` 的全套 Agent Skills——让 AI 直接操作飞书 IM、文档、多维表格、日历、邮箱、任务、知识库等。

| 技能 | 一句话 | 来源 |
| --- | --- | --- |
| [lark-cli](https://github.com/larksuite/cli) | 飞书官方 CLI 配套 27 个 skill：IM 收发、云文档、多维表格、日历、邮箱、任务、知识库、视频会议、审批、OKR、妙搭应用开发等 | larksuite |

> ⊕ 标准插件,已聚合为本目录的 `lark` 插件。
>
> **前置依赖**:所有 skill 都需要先装 npm 包 `lark-cli`:
> ```bash
> npx @larksuite/cli@latest install   # 装 lark-cli 二进制
> lark-cli config init                # 配置应用凭证
> lark-cli auth login --recommend     # 登录授权
> ```
>
> - **Claude Code**:`/plugin install lark@jangrui` 一次装全 27 个 skill(见 [作为 Marketplace 使用](#-作为-marketplace-使用))。
> - **Codex**:clone 后把 `skills/lark-*/` 子目录拷进 `~/.codex/skills/`(`cp -r skills/lark-* ~/.codex/skills/`),或用上游自带的 `npx skills add larksuite/cli -y -g`。
>
> **vendor 策略**:与 `diagram` 相同,把 27 个 skill 本体(SKILL.md + references/,约 5.5 MB)vendor 到 `plugins/lark/<skill名>/`,只保留运行时所需内容。CI 每天 21:00 UTC 自动检查上游并开 PR。

---

## 📊 演示文稿

生成横向翻页网页 PPT（单文件 HTML），内置两套专业设计系统——电子杂志风与瑞士国际主义风。

| 技能 | 一句话 | 来源 |
| --- | --- | --- |
| [guizang-ppt-skill](https://github.com/op7418/guizang-ppt-skill) | 横向翻页网页 PPT：双模板（电子杂志 × 电子墨水 / 瑞士国际主义）、WebGL 背景、22 种版式。支持照片、截图、数据大字报、时间线、地图等场景 | op7418 |

> ⊕ 标准插件，已 vendor 到本目录的 `ppt` 插件，可经 marketplace 一键安装。
> - **Claude Code**：`/plugin install ppt@jangrui`
> - **Codex**：从 `plugins/ppt/guizang-ppt/` 拷进 `~/.codex/skills/guizang-ppt-skill`

## 🖼️ 文章插画与社交卡片

生成固定风格的中文文章配图和社交媒体卡片。

| 技能 | 一句话 | 来源 |
| --- | --- | --- |
| [ian-xiaohei-illustrations](https://github.com/helloianneo/ian-xiaohei-illustrations) | 16:9 白底黑线描中文文章配图，固定 IP 角色「小黑」手绘怪诞风格 | helloianneo |
| [guizang-social-card-skill](https://github.com/op7418/guizang-social-card-skill) | 小红书图文/公众号封面生成器：Editorial × Swiss 双排版系统，28 种版式骨架，支持 Live Photo | op7418 |

> ⊕ 标准插件，已 vendor 到本目录的 `illustration` 插件，可经 marketplace 一键安装。
> - **Claude Code**：`/plugin install illustration@jangrui`
> - **Codex**：从 `plugins/illustration/` 下对应目录拷进 `~/.codex/skills/`（`ian-xiaohei-illustrations`、`guizang-social-card` 各一个）

## 📊 Grafana 可观测性

Grafana Labs 官方维护的 48 个 Agent Skills——覆盖 Grafana 全家桶：Dashboard 建模、PromQL、告警 IRM、Alloy/Beyla/OpenTelemetry 采集、Grafana Cloud 治理（成本、fleet、SSO、私有连接）、LGTM 开源栈（Loki/Tempo/Mimir/Prometheus/Pyroscope）、插件开发、k6 负载测试。

| 类别 | 代表 skill | 一句话 |
|---|---|---|
| **Grafana 核心** | `dashboarding` | 通过 HTTP API 构建/修改/发布 Grafana 仪表盘 JSON |
| | `promql` | 编写、校验、优化 PromQL 查询（rate/histogram_quantile/基数排查） |
| | `alerting-irm` | 配置 Grafana Alerting / IRM / SLO 端到端 |
| | `alloy` | 用 Grafana Alloy 构建统一遥测管线（OpenTelemetry 兼容） |
| | `beyla` | 用 eBPF 自动插桩 HTTP/gRPC/DB 流量（无需改代码） |
| | `opentelemetry` | 用 OTel 插桩并把 metrics/logs/traces 发到 Grafana |
| | `grafana-oss` | 配置 Grafana OSS（YAML 供应 dashboard + 数据源） |
| | `skill-authoring` | 按 Anthropic 指南审计/编写 Grafana SKILL.md |
| **Grafana Cloud**（18 个） | `adaptive-metrics` | 用 Adaptive Metrics 聚合规则降低 Cloud Metrics 成本 |
| | `fleet-management` | 集中管理一批 Alloy 采集器（基于属性下发管线） |
| | `cost-management` | 把 Grafana Cloud 账单归因到团队、降遥测量 |
| | `admin` | 管理 Cloud 账号：组织/stack/RBAC/SSO/服务账号/Terraform |
| | `assistant-mcp` | 经 `mcp-grafana` 把 AI agent 接入 Grafana Cloud |
| | `infrastructure` | `k8s-monitoring` Helm 把 K8s/主机/容器遥测送进 Cloud |
| | `ml-ai` | 开启 Cloud 的 AI/ML：Grafana Assistant、异常检测、SLO 等 |
| | `app-observability` | Application Observability：RED 指标 + 服务图 + RUM + LLM 监控 |
| | `database-observability` | MySQL/PostgreSQL 数据库可观测性（Performance Schema 等） |
| | `private-connectivity` | AWS/Azure/GCP 私有连接到 Grafana Cloud |
| | `dpm-finder` | 找出撑高 Cloud 账单的 Prometheus 指标 |
| | `loki-label-analyzer` / `prometheus-label-strategy` | Loki/Prometheus 标签策略评估器 |
| | `prometheus-cardinality-troubleshooter` | Prometheus 基数爆炸诊断（慢查询/OOM/高账单） |
| | `cloud-integrations` / `send-data` / `testing` / `oncall-irm` | 云集成、数据接入、合成监控、OnCall 排班 |
| **LGTM 开源栈** | `loki` / `tempo` / `mimir` / `prometheus` / `pyroscope` | 日志/追踪/长期 Prometheus 指标/持续 profiling |
| **插件开发** | `plugin-bundle-size` | 用 React.lazy + 代码分割优化插件包体积 |
| | `react-19-plugin-migration` | 把插件迁移到 React 19（适配 Grafana 12） |
| | `grafana-scenes` | 用 @grafana/scenes 构建插件页面 |
| | `check-npm` / `audit-and-reduce-dependencies` | npm 供应链加固 / 依赖瘦身 |
| **App SDK** | `cue-kind-definition` / `reconciler-logic` / `admission-control` / `app-sdk-concepts` | 在 Grafana App Platform 上构建应用（CUE schema、reconciler、admission） |
| **k6 负载测试** | `k6` | 生成/校验/review k6 脚本（load/stress/spike/soak 等） |
| | `k6-perf-test-website` | 端到端性能测试一个公开网站 |
| | `k6-cloud-investigate-test` / `k6-trend-analysis` / `k6-test-maintenance` / `k6-manage` / `k6-docs` | 排查/趋势分析/维护/管理/写文档 |
| **数据源** | `datasources-provisioning` | 生成 Grafana 数据源 provisioning 文件（YAML/Terraform） |

> ⊕ 拆成 **7 个独立 plugin**（与上游 `grafana/skills` 的官方分类对齐），可按需单独安装——不需要整个 Grafana 全家桶就只装相关的 category。
>
> - **Claude Code**（按需挑）：
>   ```
>   /plugin install grafana-core@jangrui         # 8 个：Dashboard/PromQL/Alloy/Beyla/OTel/告警 IRM
>   /plugin install grafana-cloud@jangrui        # 18 个：Fleet/Adaptive Metrics/成本/Admin(SSO+RBAC)/ML/AIOps
>   /plugin install grafana-lgtm@jangrui         # 5 个：Loki/Tempo/Mimir/Prometheus/Pyroscope
>   /plugin install grafana-plugins@jangrui      # 5 个：插件 bundle 优化/React 19 迁移/@grafana/scenes
>   /plugin install grafana-app-sdk@jangrui      # 4 个：CUE kind/reconciler/admission
>   /plugin install grafana-k6@jangrui           # 7 个：k6 脚本生成/性能测试/趋势分析
>   /plugin install grafana-datasources@jangrui  # 1 个：数据源 provisioning
>   ```
> - **Codex**：从 `plugins/grafana/grafana-<category>/<skill>/` 拷进 `~/.codex/skills/`，例如：
>   ```bash
>   # 装某个 skill
>   cp -r plugins/grafana/grafana-core/promql ~/.codex/skills/promql
>   # 装整个 category
>   cp -r plugins/grafana/grafana-lgtm/* ~/.codex/skills/
>   ```
>
> **vendor 策略**：与 `lark` 相同（单仓库多 skill），但上游多嵌套一层 category——`skills/grafana-<category>/<skill>/`。vendor 到 `plugins/grafana/grafana-<category>/<skill>/`，保留两层结构。**marketplace 层面拆成 7 个独立 plugin，共享同一物理 source 目录 `./plugins/grafana`，靠各自的 `skills` 数组划分**（与上游官方 `.claude-plugin/marketplace.json` 完全一致）。CI 每天 21:00 UTC 自动检查上游并开 PR。

---

## 🎨 AI 创作与内容工具

宝玉（Jim Liu）维护的 21 个 AI 创作技能合集——覆盖 AI 图像生成、内容获取/转换、多平台发布、实用工具四大类。大部分 skill 内有 `.ts` 脚本依赖 workspace 共享包，需**整仓引用**。

| 类别 | 技能 | 一句话 | 前置依赖 |
|---|---|---|---|
| **AI 图像生成** | [baoyu-image-gen](https://github.com/JimLiu/baoyu-skills/tree/main/skills/baoyu-image-gen) | 多后端 AI 绘图（OpenAI GPT Image 2、Azure OpenAI、Google、Replicate、MiniMax、Seedream、通义万相、智谱 GLM、快手可灵等） | `bun` |
| | [baoyu-article-illustrator](https://github.com/JimLiu/baoyu-skills/tree/main/skills/baoyu-article-illustrator) | 分析文章结构，定位配图位置，按 Type×Style×Palette 三维度生成插图 | `bun` |
| | [baoyu-comic](https://github.com/JimLiu/baoyu-skills/tree/main/skills/baoyu-comic) | 知识漫画生成器（多艺术风格、分镜布局、批量出图） | `bun` |
| | [baoyu-cover-image](https://github.com/JimLiu/baoyu-skills/tree/main/skills/baoyu-cover-image) | 文章封面图生成器（11 色板 × 7 渲染风格，支持 2.35:1 / 16:9 / 1:1） | `bun` |
| | [baoyu-infographic](https://github.com/JimLiu/baoyu-skills/tree/main/skills/baoyu-infographic) | 专业信息图生成器（21 种布局 × 22 种视觉风格） | `bun` |
| | [baoyu-diagram](https://github.com/JimLiu/baoyu-skills/tree/main/skills/baoyu-diagram) | 深色主题 SVG 专业图表（架构图、流程图、时序图、思维导图等） | —（纯 skill） |
| | [baoyu-xhs-images](https://github.com/JimLiu/baoyu-skills/tree/main/skills/baoyu-xhs-images) | 小红书/微信图文卡片系列（12 视觉风格 × 8 布局 × 3 色板） | `bun` |
| | [baoyu-slide-deck](https://github.com/JimLiu/baoyu-skills/tree/main/skills/baoyu-slide-deck) | 幻灯片图像生成 | `bun` |
| | [baoyu-danger-gemini-web](https://github.com/JimLiu/baoyu-skills/tree/main/skills/baoyu-danger-gemini-web) | 逆向 Gemini Web API 的图片/文本生成（备用后端） | `bun` |
| **内容获取与转换** | [baoyu-url-to-markdown](https://github.com/JimLiu/baoyu-skills/tree/main/skills/baoyu-url-to-markdown) | URL→Markdown（Chrome CDP + 站点适配器，支持 X/YouTube/HN/通用页面） | `bun` |
| | [baoyu-danger-x-to-markdown](https://github.com/JimLiu/baoyu-skills/tree/main/skills/baoyu-danger-x-to-markdown) | X/Twitter 帖子/文章→Markdown（需用户授权逆向 API） | `bun` |
| | [baoyu-youtube-transcript](https://github.com/JimLiu/baoyu-skills/tree/main/skills/baoyu-youtube-transcript) | YouTube 字幕/封面/章节/说话人识别下载 | —（纯 skill） |
| | [baoyu-format-markdown](https://github.com/JimLiu/baoyu-skills/tree/main/skills/baoyu-format-markdown) | Markdown 格式化（前置元数据、标题层级、加粗列表、代码块；不改内容） | `bun` / `npx` |
| | [baoyu-markdown-to-html](https://github.com/JimLiu/baoyu-skills/tree/main/skills/baoyu-markdown-to-html) | Markdown→HTML（微信兼容主题、代码高亮、数学公式、Mermaid/PlantUML 渲染） | `bun` |
| | [baoyu-translate](https://github.com/JimLiu/baoyu-skills/tree/main/skills/baoyu-translate) | 高质量翻译（精翻），支持文章/技术文档 | —（纯 skill） |
| | [baoyu-wechat-summary](https://github.com/JimLiu/baoyu-skills/tree/main/skills/baoyu-wechat-summary) | 微信群聊精华摘要（支持毒舌版、用户画像、事实记忆） | `wx-cli` |
| **发布** | [baoyu-post-to-wechat](https://github.com/JimLiu/baoyu-skills/tree/main/skills/baoyu-post-to-wechat) | 发布到微信公众号（文章/贴图/图文，Markdown 外链自动转底部引用） | `bun` |
| | [baoyu-post-to-weibo](https://github.com/JimLiu/baoyu-skills/tree/main/skills/baoyu-post-to-weibo) | 发布到微博（普通帖/头条文章） | `bun` |
| | [baoyu-post-to-x](https://github.com/JimLiu/baoyu-skills/tree/main/skills/baoyu-post-to-x) | 发布到 X/Twitter（普通帖 + X Articles） | `bun` |
| **实用工具** | [baoyu-compress-image](https://github.com/JimLiu/baoyu-skills/tree/main/skills/baoyu-compress-image) | 图片压缩（WebP / PNG） | `bun` / `npx` |
| | [baoyu-electron-extract](https://github.com/JimLiu/baoyu-skills/tree/main/skills/baoyu-electron-extract) | Electron 应用资源提取（从 `.asar` 反解源码） | `bun` |

> baoyu-skills 因 workspace 兄弟包依赖不可零散 vendor，只能整仓库引用。
>
> **前置依赖**（按需）：大部分 skill 需要 `bun` 运行时：
> ```bash
> curl -fsSL https://bun.sh/install | bash
> ```
>
> - **Claude Code**：`/plugin install baoyu-skills@jangrui`（或直连上游 `/plugin marketplace add JimLiu/baoyu-skills`）。
> - **Codex**：clone 整个仓库并 symlink 到 skills 目录：
>   ```bash
>   git clone --depth 1 https://github.com/JimLiu/baoyu-skills.git /tmp/baoyu-skills
>   # 然后对每个期望的 skill 做 symlink（或全量拷贝）
>   for d in /tmp/baoyu-skills/skills/baoyu-*/; do
>     ln -sf "$d" ~/.codex/skills/"$(basename "$d")"
>   done
>   ```

---

## 🔌 作为 Marketplace 使用(Claude Code)

本目录同时是一个 Claude Code marketplace,聚合了上方标注 ⊕ 的标准插件——安装后自动跟进上游,无需手动同步。

```text
/plugin marketplace add jangrui/skills
/plugin install diagram@jangrui                # 绘图五件套(drawio/mermaid/excalidraw/tldraw/plantuml)
/plugin install writing@jangrui                 # 写作润色(humanizer 英文 + humanizer-zh 中文,去 AI 痕迹)
/plugin install lark@jangrui                    # 飞书/Lark 全家桶(27 个 skill,需配合 npm 包 lark-cli)
	/plugin install ppt@jangrui                   # 网页 PPT 生成(guizang-ppt-skill:杂志风/瑞士风,单 HTML 横向翻页)
/plugin install illustration@jangrui            # 文章配图 + 社交卡片(小黑手绘插画 + 归藏小红书/公众号封面)
/plugin install grafana-core@jangrui           # Grafana 核心(Dashboard/PromQL/Alloy/Beyla/OTel/告警,8 个)——另有 grafana-cloud/lgtm/plugins/app-sdk/k6/datasources 6 个姊妹 plugin
/plugin install baoyu-skills@jangrui            # AI 创作 21 技能(宝玉文集:AI绘图/图文转换/发布/工具)
/plugin install cc-skills-golang@jangrui
/plugin install mattpocock-skills@jangrui
```

> Codex 没有 marketplace 机制,请用下方方式安装。

### 关于 `diagram` 的 vendor 策略

`diagram` 与本目录其它聚合项不同——它不是直连上游仓库,而是把 5 个 skill 的**本体文件** vendor(本地化)进 `plugins/diagram/<skill名>/`,只保留 skill 运行所需内容(SKILL.md + 脚本 + references),丢弃上游的 `.git`/`tests`/`docs`/CI 配置等噪声。这样做的原因:

- **仓库体积**:5 个 skill 本体合计约 **1.2 MB**;若用 git submodule 拉完整仓库,光 drawio 一个就 8.2 MB(含 tests/assets/.github 等),总计约 40 MB。
- **精确圈定**:Claude Code/Claude Code 的 marketplace schema 中,一个 plugin 的 `source` 只能指向一个来源,**没有"跨仓库挑 5 个合并成 1 个"的语义**。要让"1 个聚合名 + 只要绘图五件套"成立,必须先做物理聚合。
- **自包含验证**:vendor 前已确认这 5 个 skill 都是自包含的(脚本在 skill 目录内,不依赖同 plugin 的兄弟包)。对比 `baoyu-skills` 那种 skill 内 `.ts` 脚本依赖 `packages/baoyu-chrome-cdp` 等 workspace 兄弟包的,**不能** vendor——那种只能整仓库引用。

**同步上游更新**:

CI 自动同步 + 人工 review 兜底——GitHub Action [`sync-diagram-skills`](./.github/workflows/sync-diagram-skills.yml) 每天 21:00 UTC(北京 05:00)自动检查 5 个上游仓库,有更新时自动开 PR,人工 review diff 后合并即可。也可在 Actions 页面手动触发(`workflow_dispatch`)。

手动同步(应急或 CI 不可用时):

```bash
./scripts/sync-diagram-skills.sh --check     # 先 dry-run 看哪些有更新
./scripts/sync-diagram-skills.sh             # 同步全部
./scripts/sync-diagram-skills.sh drawio      # 只同步某个
git diff plugins/diagram/                     # review diff
git commit -am "chore(diagram): sync upstream"
```

每个 skill 目录下有 `.upstream-commit` 文件记录当前对应的上游 commit,可追溯、可回退。同步脚本内置「自包含性自检」,若上游某天重构引入了兄弟包依赖,会告警提示改用整仓库引用。

当前各 skill 对应的上游版本见 [`plugins/diagram/*/`](./plugins/diagram/) 下的 `.upstream-commit`。

### 关于 `lark` 的 vendor 策略

`lark` 与 `diagram` 同属「多 skill 需要聚合 + 自包含」的情况,采用相同的 vendor 套路,把飞书官方 `larksuite/cli` 仓库 `skills/` 下的 27 个 `lark-*` 子目录抓到 `plugins/lark/<skill名>/`。与 `diagram` 的差异:

- **单仓库多 skill**:`diagram` 是 5 个独立上游仓库,而 `lark` 全部来自 `larksuite/cli` 一个仓库。同步脚本 `sync-lark-skills.sh` 一次 sparse-checkout 拿全部,无需循环 clone。
- **外部二进制依赖**:所有 `lark-*` skill 的 frontmatter 都声明 `metadata.requires.bins: ["lark-cli"]`,需另装 `npm` 包 `lark-cli` 才能工作(见上方「前置依赖」)。
- **自动检测新 skill**:脚本会扫描上游新增的 `lark-*` 目录并 vendor 进来,但需手动把它加入 `plugins/lark/.claude-plugin/plugin.json` 和 `marketplace.json` 的 skills 数组(脚本会提示)。

**同步上游更新**:

```bash
./scripts/sync-lark-skills.sh --check          # dry-run 看哪些有更新
./scripts/sync-lark-skills.sh                  # 同步全部
./scripts/sync-lark-skills.sh lark-base        # 只同步某个
git diff plugins/lark/                          # review
```

CI(GitHub Action `sync-lark-skills`)每天 21:00 UTC 自动检查并开 PR。

### 关于 `grafana` 的 vendor 策略

`grafana` 与 `lark` 同属「单仓库多 skill」型，但来自 [grafana/skills](https://github.com/grafana/skills) 的上游多嵌套一层 category——`skills/grafana-<category>/<skill>/SKILL.md`，共 7 个 category、48 个 skill：

| category | skill 数 | 内容 |
|---|---|---|
| `grafana-core` | 8 | Dashboard、PromQL、Alloy、Beyla、OpenTelemetry、alerting-irm、grafana-oss、skill-authoring |
| `grafana-cloud` | 18 | Adaptive Metrics、Fleet、Admin、成本、ML/AI、基础设施、私有连接等 |
| `grafana-lgtm` | 5 | Loki、Tempo、Mimir、Prometheus、Pyroscope（开源 LGTM 栈） |
| `grafana-plugins` | 5 | 插件包体积、React 19 迁移、@grafana/scenes、依赖审计 |
| `grafana-app-sdk` | 4 | CUE kind 定义、reconciler、admission control |
| `grafana-k6` | 7 | k6 脚本生成/校验/趋势分析/性能测试网站 |
| `grafana-datasources` | 1 | 数据源 provisioning |

vendor 时**保留两层结构**到 `plugins/grafana/grafana-<category>/<skill>/`（不像 `lark` 那样扁平化），原因：

- 与上游目录一一对应，diff 更直观；
- 同步脚本可按 category 维度单独操作（`./scripts/sync-grafana-skills.sh grafana-k6`）；
- 每个 skill 目录单独保存 `.upstream-commit`，便于单点回退。

**marketplace 层面进一步拆成 7 个独立 plugin**（`grafana-core` / `grafana-cloud` / `grafana-lgtm` / `grafana-plugins` / `grafana-app-sdk` / `grafana-k6` / `grafana-datasources`），与上游官方 `.claude-plugin/marketplace.json` 的划分完全一致。技术上：7 个 plugin 条目共享同一个物理 source 目录 `./plugins/grafana`，仅靠各自的 `skills` 数组（指向该目录下的不同子路径）来划分作用域——用户可只装 `grafana-core` 而不引入整个 Cloud 全家桶。`plugins/grafana/` 下因此**没有 `.claude-plugin/plugin.json`**（避免与 marketplace 的 7 个条目冲突）。

与 `lark` 的相似点：都靠一次 `git sparse-checkout set skills/` 拿全部，无需循环 clone；都有「自包含性自检」防兄弟包依赖；都自动检测上游新增 skill（需手动加入对应 category plugin 在 `marketplace.json` 的 skills 数组，脚本会提示）。

**同步上游更新**：

```bash
./scripts/sync-grafana-skills.sh --check                    # dry-run 看哪些有更新
./scripts/sync-grafana-skills.sh                            # 同步全部
./scripts/sync-grafana-skills.sh grafana-k6                 # 同步整个 category
./scripts/sync-grafana-skills.sh grafana-core/promql        # 只同步某个 skill
git diff plugins/grafana/                                    # review
```

CI（GitHub Action `sync-grafana-skills`）每天 21:00 UTC 自动检查并开 PR。

### 关于 `ppt` 的 vendor 策略

`ppt` 与 `diagram` 同属单仓库单 skill 的 vendor 模式,将上游 `guizang-ppt-skill` 的 SKILL.md、`assets/`(HTML 模板 + WebGL shader + Motion One + 截图背景)、`references/`(布局、主题色、组件、检查清单)和 `scripts/`(瑞士风校验器) vendor 到 `plugins/ppt/guizang-ppt/`。

本 skill 为**纯 AI 自包含型**：SKILL 教 AI 写的单文件 HTML 由 AI 的 Write 工具直接产出,无需任何外部 CLI 配合。符合 AGENTS.md 入库决策树第一分支——✅ vendor。

**同步上游更新**:

```bash
./scripts/sync-ppt-skills.sh --check          # dry-run 看更新
./scripts/sync-ppt-skills.sh                  # 同步
git diff plugins/ppt/                          # review
```

CI(GitHub Action `sync-ppt-skills`)每天 21:00 UTC 自动检查并开 PR。

### 关于 `illustration` 的 vendor 策略

`illustration` 聚合了两个来自不同上游的 skill，采用两种同步策略：

| skill | SKILL.md 位置 | 同步策略 |
|---|---|---|
| `ian-xiaohei-illustrations` | 子目录 `ian-xiaohei-illustrations/` | sparse-checkout |
| `guizang-social-card` | 仓库根目录 | 浅克隆 + rsync |

前者与 `diagram` 各 skill 结构相同（子目录），后者与 `ppt` 结构相同（根目录）。同步脚本 `sync-illustration-skills.sh` 根据 SKILL.md 位置自动选择策略。

**同步上游更新**:

```bash
./scripts/sync-illustration-skills.sh --check                 # dry-run
./scripts/sync-illustration-skills.sh                         # 全部同步
./scripts/sync-illustration-skills.sh guizang-social-card     # 只同步某个
git diff plugins/illustration/                                 # review
```

CI(GitHub Action `sync-illustration-skills`)每天 21:00 UTC 自动检查并开 PR。

## 🧠 在 Codex 中使用

Codex CLI 没有 marketplace,而是把每个 skill 作为一个含 `SKILL.md` 的文件夹放进 skills 目录即自动加载:

- **全局**: `~/.codex/skills/<skill-name>/SKILL.md`
- **项目级**: `<项目>/.codex/skills/<skill-name>/SKILL.md`

通用安装套路(以 drawio 为例,Claude Code 与 Codex 通用):

```bash
git clone --depth 1 https://github.com/Agents365-ai/drawio-skill /tmp/drawio-skill

# Claude Code
cp -r /tmp/drawio-skill/skills/drawio-skill ~/.claude/skills/

# Codex CLI
cp -r /tmp/drawio-skill/skills/drawio-skill ~/.codex/skills/
```

> 上方表格里「根目录就是 skill」的仓库(`Humanizer-zh`、`humanizer`)整个 clone 到 skills 目录即可;「skill 在 `skills/<名字>/` 子目录」的仓库(dbx、绘图五件套、wpsnote 各 skill)只拷那个子目录。
> 本机已检测到 `~/.codex/skills/` 存在;若你设置了 `CODEX_HOME` 环境变量,请改用 `$CODEX_HOME/skills/`。

---

## 致谢

所有技能的版权归各自上游作者,本目录仅做索引与导航。详见每个链接的原始仓库。

## License

本索引仓库采用 [MIT](./LICENSE);所索引的每个技能遵循其上游仓库的 License。
