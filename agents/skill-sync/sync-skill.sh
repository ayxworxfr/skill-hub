#!/bin/bash

# Skill Synchronization Tool
# Automates syncing verified skills to skill-hub repository

# Configuration
SKILL_HUB_PATH="/Users/graycen/develope/skill-hub"
AGENTS_SKILLS_SRC="$HOME/.agents/skills"
CURSOR_SKILLS_SRC="$HOME/.cursor/skills"
OPENCLAW_SKILLS_SRC="$HOME/.openclaw/workspace/skills"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Log functions
log_info() {
    echo -e "${BLUE}ℹ ${NC}$1"
}

log_success() {
    echo -e "${GREEN}✅ ${NC}$1"
}

log_warning() {
    echo -e "${YELLOW}⚠ ${NC}$1"
}

log_error() {
    echo -e "${RED}❌ ${NC}$1"
}

# Validation functions
validate_skill_structure() {
    local skill_name="$1"
    local skill_path="$AGENTS_SKILLS_SRC/$skill_name"
    
    log_info "Validating skill structure: $skill_name"
    
    # Check skill exists
    if [ ! -d "$skill_path" ]; then
        log_error "Skill directory not found: $skill_path"
        return 1
    fi
    
    # Check for SKILL.md
    if [ ! -f "$skill_path/SKILL.md" ]; then
        log_error "Missing SKILL.md in $skill_name"
        return 1
    fi
    
    # Validate SKILL.md frontmatter
    if ! head -10 "$skill_path/SKILL.md" | grep -q "^---$"; then
        log_error "SKILL.md missing frontmatter start (---)"
        return 1
    fi
    
    if ! grep -q "^name:" "$skill_path/SKILL.md"; then
        log_error "SKILL.md missing 'name:' field"
        return 1
    fi
    
    if ! grep -q "^description:" "$skill_path/SKILL.md"; then
        log_error "SKILL.md missing 'description:' field"
        return 1
    fi
    
    # Check for common issues
    if find "$skill_path" -name "*.sh" -type f | grep -q .; then
        for script in "$skill_path"/*.sh; do
            if [ -f "$script" ]; then
                # Check if script has execute permission
                if [ ! -x "$script" ]; then
                    log_warning "Script not executable: $(basename "$script")"
                fi
                
                # Check for shebang
                if ! head -1 "$script" | grep -q "^#!/"; then
                    log_warning "Script missing shebang: $(basename "$script")"
                fi
            fi
        done
    fi
    
    log_success "Skill structure validation passed: $skill_name"
    return 0
}

validate_skill_content() {
    local skill_name="$1"
    local skill_path="$AGENTS_SKILLS_SRC/$skill_name"
    
    log_info "Validating skill content: $skill_name"
    
    # Check for sensitive information patterns
    local sensitive_patterns=(
        "password"
        "secret"
        "token"
        "api[_-]key"
        "private[_-]key"
        "192\.168\."
        "10\.\."
        "172\.(1[6-9]|2[0-9]|3[0-1])\."
    )
    
    for pattern in "${sensitive_patterns[@]}"; do
        if grep -r -i "$pattern" "$skill_path" --exclude="*.md" 2>/dev/null | grep -v "^Binary" | head -5; then
            log_warning "Potential sensitive information found matching pattern: $pattern"
            log_warning "Please review files before submission"
        fi
    done
    
    # Check file sizes (warning for very large files)
    local large_files=$(find "$skill_path" -type f -size +100k 2>/dev/null | head -5)
    if [ -n "$large_files" ]; then
        log_warning "Large files detected (>100KB):"
        echo "$large_files" | while read file; do
            echo "  - $file ($(du -h "$file" | cut -f1))"
        done
    fi
    
    log_success "Skill content validation passed: $skill_name"
    return 0
}

test_skill_functionality() {
    local skill_name="$1"
    local skill_path="$AGENTS_SKILLS_SRC/$skill_name"
    
    log_info "Testing skill functionality: $skill_name"
    
    # Different test strategies based on skill type
    case "$skill_name" in
        spotify-control)
            # Test help command
            if [ -f "$skill_path/spotify-control.sh" ]; then
                if "$skill_path/spotify-control.sh" help >/dev/null 2>&1; then
                    log_success "Help command works"
                else
                    log_warning "Help command may have issues"
                fi
            fi
            ;;
            
        skill-sync)
            # This skill - test basic commands
            if [ -f "$skill_path/sync-skill.sh" ]; then
                if "$skill_path/sync-skill.sh" help >/dev/null 2>&1; then
                    log_success "Help command works"
                fi
            fi
            ;;
            
        *)
            # Generic test - check for executable scripts
            if find "$skill_path" -name "*.sh" -type f -executable | grep -q .; then
                log_info "Found executable scripts, consider adding specific tests"
            else
                log_info "No executable scripts found, documentation-only skill"
            fi
            ;;
    esac
    
    log_success "Skill functionality testing completed: $skill_name"
    return 0
}

validate_skill() {
    local skill_name="$1"
    
    echo "🔍 ========================================="
    echo "🔍 Validating skill: $skill_name"
    echo "🔍 ========================================="
    
    # Run all validation steps
    if ! validate_skill_structure "$skill_name"; then
        log_error "Skill structure validation failed"
        return 1
    fi
    
    if ! validate_skill_content "$skill_name"; then
        log_warning "Skill content validation had warnings"
        # Continue despite warnings (they're not errors)
    fi
    
    if ! test_skill_functionality "$skill_name"; then
        log_warning "Skill functionality testing had warnings"
        # Continue despite warnings
    fi
    
    echo ""
    log_success "✅ Skill validation completed: $skill_name"
    echo "   The skill appears ready for synchronization."
    echo "   Please review any warnings before proceeding."
    return 0
}

sync_all_skills() {
    log_info "Synchronizing all skills to repository..."
    
    if [ ! -d "$SKILL_HUB_PATH" ]; then
        log_error "Skill-hub repository not found: $SKILL_HUB_PATH"
        return 1
    fi
    
    cd "$SKILL_HUB_PATH" || {
        log_error "Failed to change directory to: $SKILL_HUB_PATH"
        return 1
    }
    
    # Run the standard sync command
    log_info "Running: make sync"
    if make sync; then
        log_success "Skills synchronized successfully"
        
        # Show what changed
        local changes=$(git status --short)
        if [ -n "$changes" ]; then
            log_info "Changes detected:"
            echo "$changes"
        else
            log_info "No changes detected (already synchronized)"
        fi
        
        return 0
    else
        log_error "Synchronization failed"
        return 1
    fi
}

commit_changes() {
    local commit_msg="$1"
    
    if [ -z "$commit_msg" ]; then
        log_error "Commit message cannot be empty"
        return 1
    fi
    
    log_info "Committing changes with message: $commit_msg"
    
    cd "$SKILL_HUB_PATH" || return 1
    
    # Use the repository's sync-commit command
    log_info "Running: make sync-commit MSG=\"$commit_msg\""
    if make sync-commit MSG="$commit_msg"; then
        log_success "Changes committed and pushed successfully"
        return 0
    else
        log_error "Commit failed"
        return 1
    fi
}

check_status() {
    log_info "Checking repository status..."
    
    if [ ! -d "$SKILL_HUB_PATH" ]; then
        log_error "Skill-hub repository not found: $SKILL_HUB_PATH"
        return 1
    fi
    
    cd "$SKILL_HUB_PATH" || return 1
    
    echo ""
    echo "📊 Repository: $(pwd)"
    echo "📊 Branch: $(git branch --show-current 2>/dev/null || echo 'unknown')"
    echo ""
    
    # Show status
    local status_output=$(git status --short)
    if [ -n "$status_output" ]; then
        echo "📋 Uncommitted changes:"
        echo "$status_output"
    else
        echo "📋 No uncommitted changes"
    fi
    
    echo ""
    
    # Show recent commits
    echo "📜 Recent commits (last 5):"
    git log --oneline -5 2>/dev/null || echo "  (unable to get commit history)"
    
    echo ""
    
    # Show skill directories
    echo "📁 Skill directories:"
    echo "  Agents: $(ls agents/ | wc -l) skills"
    echo "  Cursor: $(ls cursor/ | wc -l) skills"
    echo "  OpenClaw: $(ls openclaw/ | wc -l) skills"
    
    return 0
}

list_skills() {
    log_info "Available skills in local directories:"
    
    echo ""
    echo "📚 Agents skills (~/.agents/skills/):"
    if [ -d "$AGENTS_SKILLS_SRC" ]; then
        ls -1 "$AGENTS_SKILLS_SRC" | while read skill; do
            if [ -f "$AGENTS_SKILLS_SRC/$skill/SKILL.md" ]; then
                echo "  ✅ $skill"
            else
                echo "  ⚠  $skill (missing SKILL.md)"
            fi
        done
    else
        echo "  (directory not found)"
    fi
    
    echo ""
    echo "💻 Cursor skills (~/.cursor/skills/):"
    if [ -d "$CURSOR_SKILLS_SRC" ]; then
        ls -1 "$CURSOR_SKILLS_SRC" 2>/dev/null | head -10 | while read skill; do
            echo "  📝 $skill"
        done
        local count=$(ls -1 "$CURSOR_SKILLS_SRC" 2>/dev/null | wc -l)
        if [ "$count" -gt 10 ]; then
            echo "  ... and $((count - 10)) more"
        fi
    else
        echo "  (directory not found)"
    fi
    
    echo ""
    echo "🦞 OpenClaw skills (~/.openclaw/workspace/skills/):"
    if [ -d "$OPENCLAW_SKILLS_SRC" ]; then
        ls -1 "$OPENCLAW_SKILLS_SRC" 2>/dev/null | head -10 | while read skill; do
            echo "  🦞 $skill"
        done
        local count=$(ls -1 "$OPENCLAW_SKILLS_SRC" 2>/dev/null | wc -l)
        if [ "$count" -gt 10 ]; then
            echo "  ... and $((count - 10)) more"
        fi
    else
        echo "  (directory not found)"
    fi
}

# Main command handler
main() {
    local command="${1:-help}"
    
    case "$command" in
        validate)
            if [ -z "$2" ]; then
                log_error "Usage: $0 validate <skill-name>"
                echo ""
                log_info "Available skills in ~/.agents/skills/:"
                ls "$AGENTS_SKILLS_SRC" 2>/dev/null || echo "  (directory not found)"
                return 1
            else
                validate_skill "$2"
            fi
            ;;
            
        sync-all)
            sync_all_skills
            ;;
            
        commit)
            if [ -z "$2" ]; then
                log_error "Usage: $0 commit \"commit message\""
                echo ""
                log_info "Example: $0 commit \"feat: add new search functionality\""
                log_info "Example: $0 commit \"fix: correct error handling in spotify-control\""
                return 1
            else
                # Shift to get the full commit message
                shift
                local commit_msg="$*"
                sync_all_skills && commit_changes "$commit_msg"
            fi
            ;;
            
        status)
            check_status
            ;;
            
        list)
            list_skills
            ;;
            
        help|--help|-h)
            echo "🔄 Skill Synchronization Tool"
            echo "Automates syncing verified skills to skill-hub repository"
            echo ""
            echo "Usage: $0 <command> [arguments]"
            echo ""
            echo "Commands:"
            echo "  validate <skill-name>  Validate a specific skill before sync"
            echo "  sync-all              Sync all skills from local to repository"
            echo "  commit \"message\"     Sync and commit with custom message"
            echo "  status                Check repository status and recent commits"
            echo "  list                  List all available skills in local directories"
            echo "  help                  Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0 validate spotify-control"
            echo "  $0 validate skill-sync"
            echo "  $0 commit \"feat: spotify-control add volume normalization\""
            echo "  $0 sync-all"
            echo "  $0 status"
            echo "  $0 list"
            echo ""
            echo "Repository: $SKILL_HUB_PATH"
            echo "Local directories:"
            echo "  Agents: $AGENTS_SKILLS_SRC"
            echo "  Cursor: $CURSOR_SKILLS_SRC"
            echo "  OpenClaw: $OPENCLAW_SKILLS_SRC"
            ;;
            
        *)
            log_error "Unknown command: $command"
            echo ""
            echo "Use '$0 help' for usage information"
            return 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"