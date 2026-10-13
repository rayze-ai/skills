# project-skill

让项目记忆活在仓库里，而不是 tmux 里。解决的问题：Claude Code / opencode 退出、机器重启、迁移之后 AI 不记得之前做了什么。

## 做什么

| 子命令 | 时机 | 做什么 |
|---|---|---|
| `/project-skill init` | 新建项目 | 建 `docs/ test/ scripts/` 骨架、`.claude/CLAUDE.md`、SessionStart hook，合并 `/init` 产出 |
| `/project-skill resume` | 会话开始 | 读交接区 + git 状态，复述"上次做到哪、下一步" |
| `/project-skill wrap` | 会话结束 | 重写交接区、追加进度日志、记踩坑、归档测试结果、回写 CLAUDE.md |
| `/project-skill loop <feature>` | 实现需反复调试的功能前 | 写清环境 / 观察方法 / 机器可判定停止条件 / 迭代上限，再循环验证 |
| `/project-skill check` | 随时 | 体检记忆健康度 |

不带参数：没初始化就 `init`，已初始化就 `resume`。

## 安装

```bash
# Claude Code（全局）
ln -s /data/code/skills/project-skill ~/.claude/skills/project-skill

# opencode：新版本会读 ~/.claude/skills；若没识别，再加一条
mkdir -p ~/.config/opencode/skill
ln -s /data/code/skills/project-skill ~/.config/opencode/skill/project-skill
```

## 目录

```
SKILL.md                 # skill 正文
templates/               # init 用的文件模板
  CLAUDE.md  progress.md  pitfalls.md  requirements.md  design.md
  loop.md  verify.sh  settings.json
  docs-README.md  test-README.md  scripts-README.md
hooks/
  session-start.sh       # 复制到项目 scripts/dev/，SessionStart 时注入交接区
```
