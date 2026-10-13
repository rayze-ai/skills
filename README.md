# skills

个人 Claude Code / opencode skills 仓库。每个 skill 一个目录，目录名即 skill 名，入口文件是 `<skill>/SKILL.md`。

## 为什么要有这个仓库

- Claude Code / opencode 的会话记忆靠 tmux 和对话历史，重启、迁移、换工具就丢；skill 和它们生成的项目文档放在 git 里，哪台机器 clone 下来都一样。
- 把反复用到的工作流（建项目、收功、调试验证、代码检查……）固化成 skill，而不是每次在对话里重新交代。

## 目录结构

```
skills/
  README.md
  <skill-name>/
    SKILL.md          # 必需：frontmatter(name/description) + 指令正文
    README.md         # 可选：面向人的说明、安装方式
    templates/        # 可选：skill 生成文件时用的模板
    hooks/            # 可选：配套的 hook 脚本
    scripts/          # 可选：skill 调用的脚本
```

## 安装

全部 skill 一次软链（推荐，仓库更新即生效）：

```bash
git clone <this-repo> /data/code/skills
mkdir -p ~/.claude/skills
for d in /data/code/skills/*/; do
  n=$(basename "$d"); [ -f "$d/SKILL.md" ] && ln -sfn "$d" ~/.claude/skills/"$n"
done
```

只装一个：

```bash
ln -sfn /data/code/skills/<skill> ~/.claude/skills/<skill>
```

opencode 新版本会读取 `~/.claude/skills`；若没识别，再软链到 `~/.config/opencode/skill/<skill>`。

只想在某个项目里启用：软链到该项目的 `.claude/skills/<skill>` 即可。

## 使用

- 在 Claude Code 里输入 `/<skill> [参数]` 手动调用，例如 `/project-skill wrap`。
- `description` 写清触发场景的 skill，AI 会在合适时机自动调用，无需手动输入。
- 每个 skill 的参数和子命令见其目录下的 `README.md` 或 `SKILL.md` 开头的 `argument-hint`。

## 新增一个 skill

1. `mkdir <skill-name> && $EDITOR <skill-name>/SKILL.md`
2. frontmatter 至少写 `name`（与目录名一致）和 `description`（说清**什么时候用**，这是 AI 决定是否自动触发的依据）；需要手动调用的加 `user-invocable: true`，有子命令的加 `argument-hint`。
3. 正文写给 AI 看：按步骤、可执行、有明确的产出和停止条件；长模板放 `templates/`，别塞进 SKILL.md。
4. 有脚本就跑一遍 `bash -n` 并实际试一次，再在下表登记。

## 已有 skill

| skill | 用途 | 调用 |
|---|---|---|
| [project-skill](project-skill/) | 项目全生命周期记忆：init 建骨架与 CLAUDE.md、resume 恢复上下文、wrap 收功、loop 反复调试验证规格、check 体检 | `/project-skill init\|resume\|wrap\|loop <feature>\|check` |
