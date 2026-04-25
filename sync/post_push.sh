#!/bin/bash
#
# post_push.sh — Post-push hooks for Obsidian→GitHub sync
#
# Runs after successful git push. Performs:
#   1. Rebuild TF-IDF lexical search index
#   2. Update knowledge graph edges from wikilinks
#   3. Run fast lint (mechanical checks only)
#
# Exit code: 0 if all hooks succeed, non-zero if any fail.
# Failures are logged but do not stop the pipeline (best-effort).

set -euo pipefail

REPO_PATH="${REPO_PATH:-/home/tokisaki/github/hermes-second-brain}"
LOG_FILE="$REPO_PATH/reports/post_push_$(date '+%Y%m%d_%H%M%S').log"

# Logging
exec 1> >(tee -a "$LOG_FILE")
exec 2> >(tee -a "$LOG_FILE" >&2)

echo "=== Post-push hook started: $(date '+%Y-%m-%d %H:%M:%S') ==="

# Change to repo
cd "$REPO_PATH" || { echo "ERROR: Cannot cd to $REPO_PATH"; exit 1; }

FAILED=0

# ----------------------------------------------------------------------
# Hook 1: Rebuild TF-IDF index
# ----------------------------------------------------------------------
echo ""
echo "[Hook 1] Rebuilding TF-IDF index..."
if [[ -f "$REPO_PATH/index/embeddings/build_index.py" ]]; then
  if python3 "$REPO_PATH/index/embeddings/build_index.py"; then
    echo "[Hook 1] ✓ TF-IDF index rebuilt successfully"
  else
    echo "[Hook 1] ✗ TF-IDF index rebuild failed"
    FAILED=1
  fi
else
  echo "[Hook 1] ✗ build_index.py not found"
  FAILED=1
fi

# ----------------------------------------------------------------------
# Hook 2: Update graph edges from wikilinks
# ----------------------------------------------------------------------
echo ""
echo "[Hook 2] Updating knowledge graph from wikilinks..."
if [[ -f "$REPO_PATH/sync/update_graph_from_wikilinks.py" ]]; then
  if python3 "$REPO_PATH/sync/update_graph_from_wikilinks.py"; then
    echo "[Hook 2] ✓ Graph edges updated successfully"
  else
    echo "[Hook 2] ✗ Graph update failed"
    FAILED=1
  fi
else
  echo "[Hook 2] ✗ update_graph_from_wikilinks.py not found"
  FAILED=1
fi

# ----------------------------------------------------------------------
# Hook 3: Run fast lint
# ----------------------------------------------------------------------
echo ""
echo "[Hook 3] Running fast lint..."
if [[ -x "$REPO_PATH/bin/hermes-brain-lint" ]]; then
  if "$REPO_PATH/bin/hermes-brain-lint" --fast; then
    echo "[Hook 3] ✓ Lint passed"
  else
    echo "[Hook 3] ✗ Lint failed (warnings/errors found)"
    # Lint failures are non-critical for sync continuity
    # FAILED=1  # Uncomment to treat lint failures as fatal
  fi
else
  echo "[Hook 3] ✗ hermes-brain-lint not found or not executable"
  FAILED=1
fi

# ----------------------------------------------------------------------
# Summary
# ----------------------------------------------------------------------
echo ""
echo "=== Post-push hook completed: $(date '+%Y-%m-%d %H:%M:%S') ==="
echo "Log: $LOG_FILE"

if [[ $FAILED -eq 0 ]]; then
  echo "Result: All hooks succeeded"
  exit 0
else
  echo "Result: Some hooks failed (see log)"
  exit 1
fi
