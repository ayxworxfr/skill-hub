# skill-hub

统一管理个人技能仓库，按平台分目录维护。

## 目录结构

- `cursor/`：存放 Cursor 相关 skills
- `openclaw/`：存放 OpenClaw 相关 skills
- `scripts/`：仓库维护脚本
- `Makefile`：标准化同步命令入口

## 使用约定

1. 每次变更都执行 git commit。
2. 提交后手动执行 git push 同步到 GitHub。
3. 新增 skill 时，建议以 `技能名/SKILL.md` 形式组织。
4. 使用 `_template/SKILL.md` 作为新建 skill 的统一模板。

## 推荐结构

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
```

## 快速同步

### 1) 提交并推送任意变更

```bash
chmod +x scripts/sync.sh
./scripts/sync.sh "chore: 更新 cursor skills"
```

### 2) 同步你电脑上的 skill 到仓库

默认同步源目录：

- Cursor: `~/.cursor/skills`
- OpenClaw: `~/.openclaw/workspace/skills`

执行命令：

```bash
chmod +x scripts/sync_local_skills.sh
make sync
```

### 3) 一键“同步 + 提交 + 推送”

```bash
make sync-commit MSG="chore: sync local skills"
```

或者使用默认提交信息：

```bash
make sync-commit-default
```

### 4) 自定义本地源目录（可选）

```bash
CURSOR_SKILLS_SRC="你的路径" OPENCLAW_SKILLS_SRC="你的路径" make sync
```
