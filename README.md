# skill-hub

统一管理个人 skills。仓库是唯一编辑入口，本地各客户端的 skill home 目录通过软链接指向仓库，不再复制文件。

## 目录结构

```text
cursor/
  _template/
    SKILL.md
  your-skill-name/
    SKILL.md
openclaw/
  _template/
    SKILL.md
  your-skill-name/
    SKILL.md
agents/
  your-skill-name/
    SKILL.md
```

平台约定：

- `cursor/`：Cursor skills，同时供 Claude Code 使用。
- `openclaw/`：OpenClaw skills。
- `agents/`：`~/.agents/skills` skills。
- `scripts/link_skills.py`：跨平台软链接管理脚本。
- `Makefile`：常用命令入口。

## 快速使用

### 1) 预览链接变更

```bash
make link-dry-run
```

### 2) 创建或修复全部本地链接

```bash
make link
```

默认处理：

- `cursor` -> `~/.cursor/skills`
- `claude` -> `~/.claude/skills`，源目录同样是 `cursor/`
- `openclaw` -> `~/.openclaw/workspace/skills`
- `agents` -> `~/.agents/skills`

### 3) 只处理指定平台

```bash
make link PLATFORMS=cursor
make link PLATFORMS="cursor claude"
make link-dry-run PLATFORMS=openclaw
```

### 4) 取消仓库管理的软链接

```bash
make unlink
make unlink-dry-run PLATFORMS=agents
```

`unlink` 只删除指向本仓库对应平台目录的链接，不会删除其他本地 skill。

## 自定义 home 目录

可以通过环境变量覆盖默认路径：

```bash
CURSOR_SKILLS_HOME="$HOME/.cursor/skills" make link PLATFORMS=cursor
CLAUDE_SKILLS_HOME="$HOME/.claude/skills" make link PLATFORMS=claude
OPENCLAW_SKILLS_HOME="$HOME/.openclaw/workspace/skills" make link PLATFORMS=openclaw
AGENTS_SKILLS_HOME="$HOME/.agents/skills" make link PLATFORMS=agents
```

Windows PowerShell 示例：

```powershell
$env:CURSOR_SKILLS_HOME="$HOME\.cursor\skills"
make link PLATFORMS=cursor PYTHON=python
```

## Windows 说明

脚本会优先创建目录 symlink。如果 Windows 没有开启 Developer Mode 或管理员权限不足，会自动使用 directory junction。

## 维护约定

1. 新增 skill 使用 `skill-name/SKILL.md` 结构。
2. `_template/` 仅作为模板，不会链接到本地。
3. 同名本地目录被替换前会备份到 `~/.skill-hub-backups/<timestamp>/`。
4. 修改 skill 后直接在仓库提交即可，本地客户端通过链接实时读取。

## 常用 Git 命令

```bash
git status --short
git add .
git commit -m "chore: update skills"
git push
```
