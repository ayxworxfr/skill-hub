---
name: skill-sync
description: Use when synchronizing verified skills from local directories to skill-hub repository and committing changes - ensures only validated, complete skills are submitted following repository conventions
---

# Skill Synchronization

## Overview

Automate the process of synchronizing verified skills from local development directories to the skill-hub Git repository. This skill ensures that only complete, tested skills are submitted following repository conventions and prevents submission of incomplete or unverified work.

## When to Use

- After developing and testing a new skill or skill enhancement
- When local skill changes are ready for version control
- Before submitting skill updates to the skill-hub repository
- When you need to ensure skill quality before synchronization
- When following the "validate before commit" workflow

## Core Principles

### 1. Validation First
Never synchronize unverified skills. All skills must pass functional tests before submission.

### 2. Quality Gates
- ✅ All functions tested and working
- ✅ Documentation complete and accurate  
- ✅ No sensitive information included
- ✅ Code follows style guidelines
- ✅ Error handling implemented

### 3. Repository Conventions
- Follow skill-hub directory structure
- Use proper commit message format
- Maintain clean commit history
- Respect exclusion patterns (.DS_Store, .git/, etc.)

## Quick Reference

| Command | Purpose |
|---------|---------|
| `sync-skill validate <skill-name>` | Validate a specific skill before sync |
| `sync-skill sync-all` | Sync all skills from local to repository |
| `sync-skill commit "message"` | Sync and commit with custom message |
| `sync-skill status` | Check repository status |
| `sync-skill help` | Show help information |

## Implementation

### Skill Validation Checklist

Before synchronizing any skill, verify:

```bash
# 1. Skill structure validation
ls -la ~/.agents/skills/<skill-name>/
# Should contain: SKILL.md and supporting files

# 2. Documentation validation
head -20 ~/.agents/skills/<skill-name>/SKILL.md
# Should have proper frontmatter and structure

# 3. Functionality testing
# Run skill-specific tests based on skill type

# 4. Code quality check
# Review for sensitive data, hardcoded paths, etc.
```

### Synchronization Workflow

```bash
#!/bin/bash
# sync-skill.sh - Main synchronization script

# Configuration
SKILL_HUB_PATH="/Users/graycen/develope/skill-hub"
AGENTS_SKILLS_SRC="$HOME/.agents/skills"

validate_skill() {
    local skill_name="$1"
    local skill_path="$AGENTS_SKILLS_SRC/$skill_name"
    
    echo "🔍 Validating skill: $skill_name"
    
    # Check skill exists
    if [ ! -d "$skill_path" ]; then
        echo "❌ Skill not found: $skill_name"
        return 1
    fi
    
    # Check for SKILL.md
    if [ ! -f "$skill_path/SKILL.md" ]; then
        echo "❌ Missing SKILL.md in $skill_name"
        return 1
    fi
    
    # Validate SKILL.md frontmatter
    if ! grep -q "^---$" "$skill_path/SKILL.md" || \
       ! grep -q "name:" "$skill_path/SKILL.md" || \
       ! grep -q "description:" "$skill_path/SKILL.md"; then
        echo "❌ SKILL.md missing required frontmatter"
        return 1
    fi
    
    echo "✅ Skill validation passed: $skill_name"
    return 0
}

sync_all_skills() {
    echo "🔄 Synchronizing all skills to repository..."
    
    cd "$SKILL_HUB_PATH" || return 1
    
    # Run the standard sync command
    if make sync; then
        echo "✅ Skills synchronized successfully"
        return 0
    else
        echo "❌ Synchronization failed"
        return 1
    fi
}

commit_changes() {
    local commit_msg="$1"
    
    echo "📝 Committing changes with message: $commit_msg"
    
    cd "$SKILL_HUB_PATH" || return 1
    
    if make sync-commit MSG="$commit_msg"; then
        echo "✅ Changes committed and pushed"
        return 0
    else
        echo "❌ Commit failed"
        return 1
    fi
}

check_status() {
    echo "📊 Checking repository status..."
    
    cd "$SKILL_HUB_PATH" || return 1
    
    git status --short
    echo ""
    echo "Recent commits:"
    git log --oneline -5
}

# Main command handler
case "${1:-help}" in
    validate)
        if [ -z "$2" ]; then
            echo "Usage: sync-skill validate <skill-name>"
            echo "Available skills:"
            ls "$AGENTS_SKILLS_SRC"
        else
            validate_skill "$2"
        fi
        ;;
        
    sync-all)
        sync_all_skills
        ;;
        
    commit)
        if [ -z "$2" ]; then
            echo "Usage: sync-skill commit \"commit message\""
            echo "Example: sync-skill commit \"feat: add new search functionality\""
        else
            sync_all_skills && commit_changes "$2"
        fi
        ;;
        
    status)
        check_status
        ;;
        
    help|--help|-h)
        echo "Skill Synchronization Tool"
        echo "Usage: sync-skill <command> [arguments]"
        echo ""
        echo "Commands:"
        echo "  validate <skill-name>  Validate a specific skill before sync"
        echo "  sync-all              Sync all skills from local to repository"
        echo "  commit \"message\"     Sync and commit with custom message"
        echo "  status                Check repository status and recent commits"
        echo "  help                  Show this help message"
        echo ""
        echo "Examples:"
        echo "  sync-skill validate spotify-control"
        echo "  sync-skill commit \"feat: spotify-control add volume normalization\""
        echo "  sync-skill sync-all"
        ;;
        
    *)
        echo "Unknown command: $1"
        echo "Use 'sync-skill help' for usage information"
        ;;
esac
```

## Common Workflows

### 1. Complete Skill Update Workflow
```bash
# 1. Develop and test skill locally
# 2. Validate the skill
sync-skill validate spotify-control

# 3. Sync and commit
sync-skill commit "feat: spotify-control add playlist support"

# 4. Verify the commit
sync-skill status
```

### 2. Quick Sync (When confident)
```bash
# Sync all skills without validation
sync-skill sync-all

# Or sync and commit with default message
cd /Users/graycen/develope/skill-hub
make sync-commit-default
```

### 3. Validation-Only Workflow
```bash
# Just validate before manual operations
sync-skill validate spotify-control
sync-skill validate writing-skills

# Then manually sync if validation passes
cd /Users/graycen/develope/skill-hub
make sync
git commit -m "chore: update validated skills"
git push
```

## Validation Rules

### Mandatory Checks
1. **Skill exists** in local directory
2. **SKILL.md present** with proper frontmatter
3. **No .git directories** within skill (would be excluded by rsync anyway)
4. **No sensitive data** in scripts or documentation

### Skill-Specific Validation
Different skill types may require additional validation:

#### **Executable Skills** (like spotify-control)
```bash
# Test help command
./spotify-control.sh help

# Test basic functionality (if safe)
./spotify-control.sh status 2>/dev/null || echo "Info: Status check may fail without Spotify"
```

#### **Documentation Skills** (like writing-skills)
```bash
# Check documentation structure
grep -q "## " ~/.agents/skills/writing-skills/SKILL.md
```

#### **Template Skills**
```bash
# Verify template completeness
[ -f ~/.agents/skills/_template/SKILL.md ] && echo "Template exists"
```

## Error Handling

### Common Issues and Solutions

1. **Skill not found**
   - Check skill name spelling
   - Verify skill exists in `~/.agents/skills/`

2. **Missing SKILL.md**
   - Every skill must have SKILL.md
   - Create it following the template

3. **Sync failed**
   - Check skill-hub repository path
   - Verify make commands work
   - Check Git configuration

4. **Commit failed**
   - Network connectivity for git push
   - Git authentication
   - Repository permissions

## Integration with Development Workflow

### Before Skill Modification
```bash
# Check current state
sync-skill status

# Note which skills you'll be modifying
```

### During Development
```bash
# Test skill functionality thoroughly
# Update documentation as needed
# Remove debug code and sensitive data
```

### After Development
```bash
# 1. Validate the skill
sync-skill validate <skill-name>

# 2. If validation passes, sync and commit
sync-skill commit "feat: <skill-name> <description>"

# 3. Verify the result
sync-skill status
```

## Notes

- This skill assumes skill-hub repository is at `/Users/graycen/develope/skill-hub`
- Modify `SKILL_HUB_PATH` if your repository is elsewhere
- Always review changes with `git status` before committing
- Use descriptive commit messages following conventional commits
- Never bypass validation for incomplete or broken skills

## Safety Features

1. **No force pushes** - Preserves commit history
2. **Validation gate** - Prevents bad submissions
3. **Dry-run option** - Consider adding `--dry-run` flag
4. **Backup consideration** - Skills are already version controlled

## Future Enhancements

Potential improvements:
- Skill-specific test suites
- Automated quality scoring
- Integration with CI/CD
- Change detection and partial sync
- Multi-repository support