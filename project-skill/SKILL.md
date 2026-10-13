---
name: project-skill
description: 项目全生命周期的"记忆与收功"规范。用于：新建项目时初始化目录与 .claude/CLAUDE.md（init）；每次会话开始时恢复上下文（resume）；会话结束时写进度/踩坑/测试记录（wrap）；为需要反复调试验证的功能制定"环境-观察方法-停止条件"并循环验证（loop）。用户说"新项目/初始化项目/收功/收尾/总结本次/恢复进度/继续上次/反复调试/验证到通过为止"时触发。
user-invocable: true
argument-hint: "init | resume | wrap | loop <feature-name> | check"
---

# project-skill — 让项目记忆活在仓库里，而不是 tmux 里

参数：`$ARGUMENTS`

## 核心原则（所有子命令共用）

1. **仓库即记忆。** 一切需要跨会话记住的东西都写进文件并进 git；tmux、会话历史、压缩摘要都不可靠（重启、迁移、换工具都会丢）。
2. **CLAUDE.md 只放"稳定、短、每次都要用"的内容**（≤ 80 行）：项目是什么、目录约定、常用命令、硬性规则、以及"先读 docs/progress.md"。长篇内容一律放 `docs/`，CLAUDE.md 只留指针。
3. **`docs/progress.md` 顶部是交接区**（"当前状态"≤ 20 行：正在做什么、下一步、阻塞），下面是按日期追加的日志。任何会话重新开始，只要读完 CLAUDE.md + 交接区就能接着干。
4. **停止条件必须可机器检验。** 需要反复调试的功能，先写 `scripts/verify/<feature>.sh`（通过 exit 0，失败 exit 非 0 并打印线索），再开始改代码。
5. **所有子命令都用中文写文档**，命令、路径、代码保持原样。

---

## 子命令分发

没有参数时：检查当前目录是否已有 `.claude/CLAUDE.md` 与 `docs/progress.md`。
- 都没有 → 当作 `init`
- 已有 → 当作 `resume`

### `init` — 新建项目初始化

在当前目录（或用户指定目录）执行，已有文件一律**不覆盖**，只补缺：

1. 如果不是 git 仓库，`git init`。
2. 建目录骨架：

   ```
   .claude/
     CLAUDE.md          # 项目记忆（短、稳定）
     settings.json      # SessionStart hook：开场自动注入交接区
   docs/
     README.md          # docs 目录索引
     requirements.md    # 需求（要做什么、不做什么、验收口径）
     design.md          # 整体设计（架构、模块、关键决策及理由）
     progress.md        # 进度：顶部"当前状态"交接区 + 按日期追加日志
     pitfalls.md        # 踩坑：现象 / 根因 / 解法 / 如何避免
     loops/             # 每个需反复调试功能的"环境-观察-停止条件"规格
   test/
     README.md          # 约定：test/YYYY-MM-DD/ 按日期存测试结果
   scripts/
     README.md
     verify/            # 可机器检验的验证脚本（exit 0 = 通过）
     dev/               # 启动环境、造数据、清理等辅助脚本
   ```

3. 用本 skill 目录下 `templates/` 的模板生成上述文件（模板路径：与本 SKILL.md 同目录的 `templates/`）。把 `{{PROJECT_NAME}}`、`{{DATE}}` 替换为实际值。
4. 复制 `hooks/session-start.sh` 到项目 `scripts/dev/session-start.sh`，并写 `.claude/settings.json`（模板 `templates/settings.json`）。这个 hook 在每次会话开始时把 `docs/progress.md` 的"当前状态"和最近 3 条踩坑打印到上下文——这才是不依赖 tmux 的"记得上次做了什么"。
5. 如果用户在用 opencode：`ln -s .claude/CLAUDE.md AGENTS.md`（opencode 读 AGENTS.md）。
6. 然后**询问用户三件事**并写入对应文件（用户已在对话里说过的直接用，不要重复问）：
   - 这个项目要做什么、不做什么 → `docs/requirements.md`
   - 技术栈 / 运行方式 / 常用命令 → `.claude/CLAUDE.md` 的"常用命令"
   - 有没有已知坑或硬性约束（比如"不能动 X 表"、"必须兼容 Y"）→ CLAUDE.md"硬性规则"
7. 最后运行 `/init`（Claude Code 内置）让它补充它从代码里看到的内容；**把 /init 产出合并进 `.claude/CLAUDE.md`，删除根目录 CLAUDE.md**（只保留一份，避免两处漂移）。合并时删掉冗长描述，保持 ≤ 80 行。
8. 首次 commit：`chore: project scaffold (project-skill init)`。

### `resume` — 会话开始，恢复上下文

1. 读 `.claude/CLAUDE.md`（通常已自动加载）、`docs/progress.md` 的"当前状态"区、`docs/pitfalls.md` 最近 3 条。
2. `git status --short` + `git log --oneline -5`，核对工作区是否与交接区描述一致（有未提交改动而交接区没提，要指出）。
3. 如果 `docs/loops/` 里有状态为 `进行中` 的规格，读它并提醒用户上次验证到哪一步。
4. 用 ≤ 10 行向用户复述："上次做到哪、下一步是什么、有什么阻塞"，然后问是否按"下一步"继续。不要在复述之前动手改代码。

### `wrap` — 会话结束，收功

目标：**下一个会话（可能是另一台机器、另一个工具）零上下文也能接着干。** 按顺序做：

1. **盘点本次改动**：`git diff --stat`、`git status --short`、本次对话里做过的事。
2. **更新 `docs/progress.md`**：
   - 重写顶部"当前状态"区（整体替换，不是追加）：正在做什么 / 下一步具体到可以直接执行 / 阻塞与待决策。
   - 在日志区**追加**一条 `## YYYY-MM-DD` 记录：做了什么、怎么验证的、未完成的、踩的坑（指向 pitfalls.md 条目）。同一天多次 wrap 就在当天条目下续写。
3. **更新 `docs/pitfalls.md`**：本次新踩的坑，每条按"现象 / 根因 / 解法 / 如何避免"写。没有就不写，不要凑数。
4. **测试结果归档**：本次如果跑过测试或验证脚本，把关键输出存到 `test/YYYY-MM-DD/<主题>.md`（结论放最前面，原始输出放后面，太长就截取并注明）。
5. **回写 CLAUDE.md**（仅当出现新的"稳定规则"时）：比如新常用命令、新的硬性约束、目录约定变化。不要把一次性进度写进 CLAUDE.md。
6. **loop 规格状态**：若本次在做某个 `docs/loops/<feature>.md`，更新其状态（进行中 / 已通过 / 已放弃）与"最新一次结果"。
7. **检查交接区能否自解释**：假装自己是明天的新会话，只读 CLAUDE.md + 当前状态区，能否不问人就开始干？不能就补。
8. `git add` 文档与改动，给出建议 commit message；用户之前说过"自动提交"就直接 commit，否则询问。
9. 向用户输出 ≤ 15 行的收功摘要：做了什么、下一步、阻塞、本次新增踩坑数、测试归档位置。

**触发时机提醒**：用户说"收功 / 收尾 / 今天到这 / 总结一下"、长会话即将压缩、或用户要关机/迁移时，都应主动建议或直接执行 wrap。

### `loop <feature-name>` — 为反复调试的功能定"环境-观察-停止条件"

这不是项目创建时做的事，是**实现某个具体功能、预计要改-跑-看多轮**时做的。流程分两段：

**第一段：先写规格，再动代码。** 生成 `docs/loops/<feature-name>.md`（模板 `templates/loop.md`），和用户一起把下面五项填实，任何一项含糊都不要开始改代码：

| 项 | 要求 |
|---|---|
| 目标 | 一句话说清做成什么样 |
| 环境 | 怎么启动（命令）、依赖什么（端口/数据/服务/密钥来自哪里）、怎么重置到干净状态 |
| 观察方法 | 看哪里：日志路径、URL、输出文件、数据库表；用什么命令看 |
| 停止条件 | **可机器判定**：写成 `scripts/verify/<feature-name>.sh`，exit 0 = 通过；多个条件就列多条 |
| 上限 | 最多迭代几轮 / 多长时间仍未通过就停下来找人，而不是无限循环 |

同时生成 `scripts/verify/<feature-name>.sh`（模板 `templates/verify.sh`），并先跑一次确认它**在当前（未实现）状态下会失败**——验证脚本不会失败就等于没有验证。

**第二段：循环验证。** 每一轮：
1. 改代码（一轮只针对一个假设，不要同时改多处）。
2. 重置环境 → 跑 `scripts/verify/<feature-name>.sh`。
3. 在 `test/YYYY-MM-DD/<feature-name>.md` 追加一条：第 N 轮 / 改了什么 / 结果 / 下一步假设。
4. 通过 → 把规格状态改为"已通过"，记录最终方案，建议顺手 `wrap`。
5. 未通过且未到上限 → 继续；到上限 → 停下，把现象、已排除的假设、建议写进规格的"卡点"区，交给用户。

长时间的等待类验证（比如等部署、等定时任务），用 `/loop <间隔> bash scripts/verify/<feature>.sh` 轮询，不要在前台 sleep。

### `check` — 体检当前项目的记忆健康度

快速检查并报告（不自动修改）：
- `.claude/CLAUDE.md` 是否存在、是否超 80 行、是否包含"先读 docs/progress.md"
- `docs/progress.md` 顶部"当前状态"区最后更新日期距今几天、是否为空模板
- `docs/pitfalls.md` 条数
- `docs/loops/` 中"进行中"的规格有哪些
- `test/` 最新日期目录
- `.claude/settings.json` 是否配置了 SessionStart hook
- 根目录是否同时存在 `CLAUDE.md` 和 `.claude/CLAUDE.md`（两份会漂移）

每项给出 ✅ / ⚠️ 和一句修复建议。

---

## 写文档的口径（避免越写越没人看）

- 进度写"事实 + 下一步"，不写感想。
- 踩坑一条一个，标题是**现象**（搜索时是按现象搜的），正文再讲根因。
- 测试结果**结论先行**，原始输出放后面；超过 200 行就截取关键段并注明来源命令。
- 不确定的事明确写"未验证"，不要写成结论。
- 文件名、路径、命令用反引号原样写，日期用 `YYYY-MM-DD`。
