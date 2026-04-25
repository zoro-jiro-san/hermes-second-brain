#!/usr/bin/env bash
# =============================================================================
# SYMLINK_SETUP.SH — Hermes Skills Symlink Installer
# =============================================================================
# Purpose: Symlink all skill directories from synthesis/ to ~/.hermes/skills/
#          with proper category-based organization.
#
# Usage:     ./symlink_setup.sh
# Idempotent: Yes — safe to re-run; overwrites existing symlinks.
#
# Requirements:
#   - Run as the Hermes user (typically 'tokisaki')
#   - Source skills exist at: /home/tokisaki/work/synthesis/skills/
#   - Target dir: ~/.hermes/skills/ (created if missing)
#
# Author: Hermes Agent (Nous Research)
# Date:   2026-04-26
# =============================================================================

set -e  # Exit on error
set -u  # Exit on undefined variable

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------
SOURCE_BASE="/home/tokisaki/work/synthesis/skills"
TARGET_BASE="${HOME}/.hermes/skills"

# Skill category mapping: "SOURCE_DIR_NAME" => "CATEGORY"
# The key is the directory name under $SOURCE_BASE.
# The value is the category (subdir under ~/.hermes/skills/).
# Skills without an entry below default to "misc/".
declare -A SKILL_CATEGORY=(
    # MLOps — synthetic data, model training infrastructure
    ["obscura-ai-obscura"]="mlops"
    ["obscura"]="mlops"                    # Alias/duplicate

    # Autonomous AI Agents — planning, execution frameworks
    ["chainyo-claude-task-master"]="autonomous-ai-agents"
    ["claude-task-master"]="autonomous-ai-agents"  # Alias
    ["agentic-stack-agentic-stack"]="autonomous-ai-agents"
    ["agentic-stack"]="autonomous-ai-agents"       # Alias
    ["agentic-inbox"]="autonomous-ai-agents"
    ["openhands"]="autonomous-ai-agents"
    ["the-mansion"]="autonomous-ai-agents"

    # Product Strategy — market analysis, ad generation, positioning
    ["anthropic-claude-ads"]="product-strategy"
    ["claude-ads"]="product-strategy"      # Alias

    # Infrastructure — deployment, hosting, devops
    ["coolify"]="infrastructure"
    ["sandcastle"]="infrastructure"

    # Data Engineering — ETL, pipelines, data transformation
    ["fincept-terminal"]="data-engineering"
    ["shannon"]="data-engineering"

    # Developer Tools — utilities, skills that enhance Hermes itself
    ["awesome-hermes-agent"]="developer-tools"
    ["mattpocock-skills"]="developer-tools"
    ["everything-claude-code"]="developer-tools"
    ["obsidian-headless"]="developer-tools"

    # Ecosystem Integrations — platforms, chains, ecosystems
    ["awesome-opensource-ai"]="ecosystem"
    ["awesome-solana-ai"]="ecosystem"
    ["solana-dev-skill"]="ecosystem"

    # Research & Analysis — meta-research, synthesis agents
    ["synthesis"]="research"
    ["toprank"]="research"
    ["vibe-trading"]="research"
    ["ai-engineering-hub"]="research"
    ["cognee"]="research"                  # Knowledge graph research
    ["dexter"]="research"                  # Generic research agent?
)

# Optional: Short name mapping (symlink name differs from source dir)
# If not defined, symlink name = last component of source dir (after last -)
# E.g., "chainyo-claude-task-master" → "claude-task-master" (strip "chainyo-")
declare -A SKILL_SHORTNAME=(
    ["obscura-ai-obscura"]="obscura"
    ["chainyo-claude-task-master"]="claude-task-master"
    ["anthropic-claude-ads"]="claude-ads"
    ["agentic-stack-agentic-stack"]="agentic-stack"
    ["awesome-hermes-agent"]="awesome-hermes-agent"  # same
    ["awesome-opensource-ai"]="awesome-opensource-ai"
    ["awesome-solana-ai"]="awesome-solana-ai"
    ["claude-ads"]="claude-ads"            # Keep CDN version; prefer Anthropic origin
)

# -----------------------------------------------------------------------------
# Helper Functions
# -----------------------------------------------------------------------------
log_info() {
    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') — $*"
}

log_warn() {
    echo "[WARN] $(date '+%Y-%m-%d %H:%M:%S') — $*" >&2
}

log_error() {
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') — $*" >&2
}

# Check if a SKILL.md exists at given source directory
has_skill_md() {
    local src_dir="$1"
    [[ -f "${src_dir}/SKILL.md" ]]
}

# Get short name for skill (symlink name)
get_shortname() {
    local src_dir_name="$1"
    # If explicit shortname mapping exists, use it
    if [[ -n "${SKILL_SHORTNAME[$src_dir_name]:-}" ]]; then
        echo "${SKILL_SHORTNAME[$src_dir_name]}"
        return
    fi
    # Otherwise derive: strip common prefixes (chainyo-, anthropic-, obscura-ai-, etc.)
    local shortname
    shortname="${src_dir_name#chainyo-}"          # Remove "chainyo-" prefix
    shortname="${shortname#anthropic-}"           # Remove "anthropic-" prefix
    shortname="${shortname#obscura-ai-}"          # Remove "obscura-ai-" prefix
    shortname="${shortname#agentic-stack-}"       # Remove "agentic-stack-" prefix
    # If nothing changed, use the full dir name as-is
    if [[ "$shortname" == "$src_dir_name" ]]; then
        echo "$src_dir_name"
    else
        echo "$shortname"
    fi
}

# Get category for skill
get_category() {
    local src_dir_name="$1"
    if [[ -n "${SKILL_CATEGORY[$src_dir_name]:-}" ]]; then
        echo "${SKILL_CATEGORY[$src_dir_name]}"
    else
        echo "misc"   # Default category
    fi
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------
main() {
    log_info "Starting Hermes skills symlink setup..."
    log_info "Source base: ${SOURCE_BASE}"
    log_info "Target base: ${TARGET_BASE}"

    # Validate source exists
    if [[ ! -d "${SOURCE_BASE}" ]]; then
        log_error "Source directory not found: ${SOURCE_BASE}"
        exit 1
    fi

    # Create target base if missing
    if [[ ! -d "${TARGET_BASE}" ]]; then
        log_info "Creating target base directory: ${TARGET_BASE}"
        mkdir -p "${TARGET_BASE}"
    fi

    # Track stats
    local total=0 linked=0 skipped=0 errors=0

    # Iterate over all subdirectories in SOURCE_BASE
    for src_dir in "${SOURCE_BASE}"/*/; do
        # Skip if not a directory (e.g., no matches)
        [[ -d "$src_dir" ]] || continue

        src_dir_name=$(basename "$src_dir")
        total=$((total + 1))

        # Check SKILL.md exists
        if ! has_skill_md "$src_dir"; then
            log_warn "Skipping ${src_dir_name}: No SKILL.md found"
            skipped=$((skipped + 1))
            continue
        fi

        # Determine short name (symlink name) and category
        local shortname category target_dir target_link
        shortname=$(get_shortname "$src_dir_name")
        category=$(get_category "$src_dir_name")
        target_dir="${TARGET_BASE}/${category}"
        target_link="${target_dir}/${shortname}"

        # Create category directory if needed
        if [[ ! -d "$target_dir" ]]; then
            log_info "Creating category directory: ${category}/"
            mkdir -p "$target_dir"
        fi

        # Check if symlink already exists; remove if so (ln -sf handles this, but be explicit for logging)
        if [[ -L "$target_link" ]]; then
            existing_target=$(readlink "$target_link")
            if [[ "$existing_target" == "$src_dir" ]]; then
                log_info "Symlink already correct: ${category}/${shortname} → ${src_dir_name}"
                linked=$((linked + 1))
                continue
            else
                log_info "Updating existing symlink: ${category}/${shortname}"
                rm -f "$target_link"
            fi
        elif [[ -e "$target_link" ]]; then
            log_error "Target exists and is not a symlink: ${target_link} (skipping)"
            errors=$((errors + 1))
            continue
        fi

        # Create relative symlink (more portable)
        # Calculate relative path from target_dir to src_dir
        # Example: target_dir = ~/.hermes/skills/mlops, src_dir = /home/.../skills/obscura-ai-obscura
        # Relative: ../../../../work/synthesis/skills/obscura-ai-obscura
        local rel_path
        rel_path=$(realpath --relative-to="$target_dir" "$src_dir" 2>/dev/null || \
                   python3 -c "import os; print(os.path.relpath('$src_dir', '$target_dir'))" 2>/dev/null || \
                   echo "$src_dir")  # Fallback to absolute

        # Create symlink
        if ln -s "$rel_path" "$target_link"; then
            log_info "Linked: ${category}/${shortname} → ${rel_path}"
            linked=$((linked + 1))
        else
            log_error "Failed to create symlink: ${category}/${shortname}"
            errors=$((errors + 1))
        fi
    done

    # Summary
    echo ""
    log_info "=== Symlink Setup Complete ==="
    log_info "Total skill dirs scanned: ${total}"
    log_info "Successfully linked:      ${linked}"
    log_info "Skipped (no SKILL.md):    ${skipped}"
    log_info "Errors:                   ${errors}"

    if [[ $errors -eq 0 ]]; then
        log_info "All done! Verify with: hermes skills list"
        exit 0
    else
        log_error "Some errors occurred. Check logs above."
        exit 1
    fi
}

# -----------------------------------------------------------------------------
# Run
# -----------------------------------------------------------------------------
main "$@"
