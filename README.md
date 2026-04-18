# skill-hub

统一管理个人技能仓库，按平台分目录维护。

## 目录结构

- `cursor/`：存放 Cursor 相关 skills
- `openclaw/`：存放 OpenClaw 相关 skills
- `scripts/`：仓库维护脚本

## 使用约定

1. 每次变更都执行 git commit。
2. 提交后手动执行 git push 同步到 GitHub。
3. 新增 skill 时，建议以 `技能名/SKILL.md` 形式组织。

## 推荐结构

```text
cursor/
  your-skill-name/
    SKILL.md
openclaw/
  your-skill-name/
    SKILL.md
```

## 快速同步

你可以使用脚本快速完成“提交并推送”：

```bash
chmod +x scripts/sync.sh
./scripts/sync.sh "chore: 更新 cursor skills"
```
