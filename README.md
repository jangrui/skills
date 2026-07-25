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
| [cc-skills-golang](https://github.com/samber/cc-skills-golang) | 生产级 Go 项目技能集:并发、错误处理、slog、samber 全家桶、cobra/viper、测试、性能等 | Samuel Berthe |

> ⊕ 标准插件,可经本目录的 marketplace 一键安装。

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

---

## 🔌 作为 Marketplace 使用(Claude Code)

本目录同时是一个 Claude Code marketplace,聚合了上方标注 ⊕ 的标准插件——安装后自动跟进上游,无需手动同步。

```text
/plugin marketplace add jangrui/skills
/plugin install diagram@jangrui                # 绘图五件套(drawio/mermaid/excalidraw/tldraw/plantuml)
/plugin install writing@jangrui                 # 写作润色(humanizer-zh 中文去 AI 痕迹)
/plugin install cc-skills-golang@jangrui
/plugin install mattpocock-skills@jangrui
/plugin install humanizer@jangrui
```

> Codex 没有 marketplace 机制,请用下方方式安装。

### 关于 `diagram` 的 vendor 策略

`diagram` 与本目录其它聚合项不同——它不是直连上游仓库,而是把 5 个 skill 的**本体文件** vendor(本地化)进 `plugins/diagram/<skill名>/`,只保留 skill 运行所需内容(SKILL.md + 脚本 + references),丢弃上游的 `.git`/`tests`/`docs`/CI 配置等噪声。这样做的原因:

- **仓库体积**:5 个 skill 本体合计约 **1.2 MB**;若用 git submodule 拉完整仓库,光 drawio 一个就 8.2 MB(含 tests/assets/.github 等),总计约 40 MB。
- **精确圈定**:Claude Code/Claude Code 的 marketplace schema 中,一个 plugin 的 `source` 只能指向一个来源,**没有"跨仓库挑 5 个合并成 1 个"的语义**。要让"1 个聚合名 + 只要绘图五件套"成立,必须先做物理聚合。
- **自包含验证**:vendor 前已确认这 5 个 skill 都是自包含的(脚本在 skill 目录内,不依赖同 plugin 的兄弟包)。对比 `baoyu-skills` 那种 skill 内 `.ts` 脚本依赖 `packages/baoyu-chrome-cdp` 等 workspace 兄弟包的,**不能** vendor——那种只能整仓库引用。

**同步上游更新**:

CI 自动同步 + 人工 review 兜底——GitHub Action [`sync-diagram-skills`](./.github/workflows/sync-diagram-skills.yml) 每周一 09:00 UTC(北京 17:00)自动检查 5 个上游仓库,有更新时自动开 PR,人工 review diff 后合并即可。也可在 Actions 页面手动触发(`workflow_dispatch`)。

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
