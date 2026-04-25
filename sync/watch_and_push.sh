#!/bin/bash
#
# watch_and_push.sh — Real-time Obsidian vault → GitHub sync
#
# Monitors the local Obsidian vault for .md file changes using inotifywait.
# On change, batches updates (debounce) and pushes to GitHub.
# After successful push, runs post_push.sh to rebuild indexes.
#
# Usage: ./sync/watch_and_push.sh [--dry-run] [--verbose]
#
# Requirements: inotify-tools, git, ssh key configured for GitHub

set -euo pipefail

VAULT_PATH="${VAULT_PATH:-/home/tokisaki/vaults/hermes-second-brain}"
REPO_PATH="${REPO_PATH:-/home/tokisaki/github/hermes-second-brain}"
DEBOUNCE_SEC="${DEBOUNCE_SEC:-3}"
DRY_RUN=false
VERBOSE=false

# Parse flags
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --verbose) VERBOSE=true ;;
  esac
done

log() {
  $VERBOSE && echo "[watch] $(date '+%Y-%m-%d %H:%M:%S') $*" >&2
}

error() {
  echo "[watch] ERROR: $*" >&2
}

# Validate dependencies
if ! command -v inotifywait &>/dev/null; then
  error "inotifywait not found. Install: apt install inotify-tools"
  exit 1
fi

if ! command -v git &>/dev/null; then
  error "git not found"
  exit 1
fi

# Validate paths
if [[ ! -d "$VAULT_PATH" ]]; then
  error "Vault not found: $VAULT_PATH"
  exit 1
fi

if [[ ! -d "$REPO_PATH" ]]; then
  error "Repo not found: $REPO_PATH"
  exit 1
fi

if [[ ! -d "$REPO_PATH/.git" ]]; then
  error "Not a git repo: $REPO_PATH"
  exit 1
fi

log "Starting watch on $VAULT_PATH"
log "Repo: $REPO_PATH"
log "Debounce: ${DEBOUNCE_SEC}s"

# Trap cleanup
cleanup() {
  log "Shutting down..."
  exit 0
}
trap cleanup SIGINT SIGTERM

# Main watch loop
while true; do
  # Wait for any .md file change (create, modify, move, delete)
  # -r = recursive, -e = events, --format = just filename
  log "Waiting for changes..."
  changed_files=$(inotifywait -r -e modify,create,delete,move \
    --format '%w%f' \
    "$VAULT_PATH" 2>/dev/null | grep -i '\.md$' || true)

  if [[ -z "$changed_files" ]]; then
    continue
  fi

  log "Detected changes:"
  echo "$changed_files" | while read -r f; do log "  $f"; done

  # Debounce: wait for quiet period
  log "Debouncing ${DEBOUNCE_SEC}s..."
  sleep "$DEBOUNCE_SEC"

  # Check if there are still uncommitted changes in the repo
  pushd "$REPO_PATH" > /dev/null

  # Refresh git status (in case external changes happened)
  git fetch origin &>/dev/null || true

  # Check for changes (tracking both staged and unstaged)
  if git status --porcelain | grep -E '^.*\.md' &>/dev/null; then
    log "Changes detected in git status"

    if $DRY_RUN; then
      log "[DRY-RUN] Would commit and push"
      git status --short
    else
      # Stage all .md changes (including deletions)
      git add -u *.md 2>/dev/null || true
      git add *.md 2>/dev/null || true
      git add -A 2>/dev/null || true

      # Check if anything to commit
      if git diff --cached --quiet; then
        log "No changes to commit (maybe only non-md files)"
        popd > /dev/null
        continue
      fi

      # Commit
      commit_msg="Obsidian sync: $(date '+%Y-%m-%d %H:%M:%S')"
      git commit -m "$commit_msg" || {
        error "Git commit failed"
        popd > /dev/null
        continue
      }
      log "Committed: $commit_msg"

      # Push
      if git push origin main 2>/dev/null || git push origin master 2>/dev/null; then
        log "Pushed to GitHub"

        # Run post-push hooks
        log "Running post-push hooks..."
        if [[ -x "$REPO_PATH/sync/post_push.sh" ]]; then
          if $DRY_RUN; then
            log "[DRY-RUN] Would run post_push.sh"
          else
            "$REPO_PATH/sync/post_push.sh" || error "post_push.sh failed"
          fi
        else
          log "post_push.sh not found or not executable"
        fi
      else
        error "Git push failed — will retry on next change"
      fi
    fi
  else
    log "No .md changes to commit"
  fi

  popd > /dev/null
done
