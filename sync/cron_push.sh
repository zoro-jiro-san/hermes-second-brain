#!/bin/bash
#
# cron_push.sh — 6-hour batch push for Obsidian vault changes
#
# Called by cron (or manually) to commit and push all pending changes.
# More efficient than watch_and_push for periodic sync when file changes
# are frequent or the watcher isn't running.
#
# Usage: ./sync/cron_push.sh [--dry-run] [--force] [--quiet]
#
# --dry-run  : Show what would be committed, don't modify git state
# --force    : Commit even if there are no changes (creates empty commit)
# --quiet    : Only output errors

set -euo pipefail

REPO_PATH="${REPO_PATH:-/home/tokisaki/github/hermes-second-brain}"
DRY_RUN=false
FORCE=false
QUIET=false

# Parse flags
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --force) FORCE=true ;;
    --quiet) QUIET=true ;;
  esac
done

log() {
  $QUIET || echo "[cron_push] $(date '+%Y-%m-%d %H:%M:%S') $*" >&2
}

error() {
  echo "[cron_push] ERROR: $*" >&2
}

# Change to repo
cd "$REPO_PATH" || { error "Cannot cd to $REPO_PATH"; exit 1; }

# Validate git repo
if [[ ! -d ".git" ]]; then
  error "Not a git repository: $REPO_PATH"
  exit 1
fi

log "Checking for changes in $REPO_PATH"

# Fetch remote to check for conflicts
git fetch origin &>/dev/null || true

# Get status
if git status --porcelain | grep -q '^'; then
  log "Uncommitted changes detected"
else
  log "No uncommitted changes"
  $FORCE || exit 0
fi

# Stage all changes (including deletions)
if $DRY_RUN; then
  log "[DRY-RUN] Would stage all changes"
  git status --short
else
  git add -A || { error "git add failed"; exit 1; }

  # Check if anything staged
  if git diff --cached --quiet; then
    log "No changes to commit"
    $FORCE || exit 0
  fi

  # Commit
  commit_msg="Batch sync: $(date '+%Y-%m-%d %H:%M:%S')"
  git commit -m "$commit_msg" || { error "git commit failed"; exit 1; }
  log "Committed: $commit_msg"

  # Push
  log "Pushing to origin..."
  if git push origin main 2>/dev/null || git push origin master 2>/dev/null; then
    log "Push successful"
  else
    error "Push failed — will retry later"
    exit 1
  fi

  # Run post_push hooks
  log "Running post-push hooks..."
  if [[ -x "$REPO_PATH/sync/post_push.sh" ]]; then
    "$REPO_PATH/sync/post_push.sh" || error "post_push.sh failed"
  else
    log "post_push.sh not found or not executable"
  fi
fi

log "Done"
