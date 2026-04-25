#!/usr/bin/env bash
# cron/health_check.sh — Hermes Second Brain automation

set -euo pipefail

# Configuration
export HOME="/home/tokisaki"
WORKDIR="${HOME}/github/hermes-second-brain"
LOG_DIR="/var/log/hermes"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
LOGFILE="${LOG_DIR}/$(basename "$0" .sh).log"

# Ensure log dir exists
mkdir -p "${LOG_DIR}"

# Log start
echo "[START] ${TIMESTAMP} — $(basename "$0")" >> "${LOGFILE}"

# Change to workdir
cd "${WORKDIR}"

# --- Job steps ---

# 1. Run fast lint (mechanical checks only)
echo "[INFO] Running hermes-brain-lint --fast" >> "${LOGFILE}" 2>&1
if command -v hermes-brain-lint &> /dev/null; then
    hermes-brain-lint --fast >> "${LOGFILE}" 2>&1 || true
else
    echo "[WARNING] hermes-brain-lint not found in PATH" >> "${LOGFILE}"
fi

# 2. Verify wiki directory and index.md
if [[ ! -d "wiki" ]]; then
    echo "[CRITICAL] wiki directory missing!" >> "${LOGFILE}"
elif [[ ! -f "wiki/index.md" ]]; then
    echo "[CRITICAL] wiki/index.md missing!" >> "${LOGFILE}"
else
    echo "[INFO] wiki directory and index.md OK" >> "${LOGFILE}"
fi

# 3. Check skills symlinks (if they exist)
if [[ -d "${HOME}/.hermes/skills" ]]; then
    BROKEN_SYMLINKS=$(find "${HOME}/.hermes/skills" -xtype l 2>/dev/null | wc -l)
    if [[ ${BROKEN_SYMLINKS} -gt 0 ]]; then
        echo "[WARNING] ${BROKEN_SYMLINKS} broken symlink(s) in ~/.hermes/skills/" >> "${LOGFILE}"
    else
        echo "[INFO] All skill symlinks valid" >> "${LOGFILE}"
    fi
else
    echo "[INFO] ~/.hermes/skills not found (skipping symlink check)" >> "${LOGFILE}"
fi

# --- End job steps ---

# Log completion
EXIT_CODE=$?
END_TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
if [[ $EXIT_CODE -eq 0 ]]; then
    echo "[SUCCESS] ${END_TIMESTAMP} — exit=${EXIT_CODE}" >> "${LOGFILE}"
else
    echo "[FAILURE] ${END_TIMESTAMP} — exit=${EXIT_CODE}" >> "${LOGFILE}"
    # Alert conditions would go here (Telegram + email)
fi

exit $EXIT_CODE
