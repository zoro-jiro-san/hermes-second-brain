#!/usr/bin/env bash
# cron/daily_sync.sh — Hermes Second Brain automation

set -euo pipefail

# Configuration
export HOME="/home/tokisaki"
WORKDIR="${HOME}/github/hermes-second-brain"
LOG_DIR="/var/log/hermes"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
LOGFILE="${LOG_DIR}/$(basename "$0" .sh).log"
DIGEST_DATE=$(date '+%Y-%m-%d')
DIGEST_FILE="${WORKDIR}/reports/digest_${DIGEST_DATE}.md"

# Ensure log dir exists
mkdir -p "${LOG_DIR}"
mkdir -p "${WORKDIR}/reports"

# Log start
echo "[START] ${TIMESTAMP} — $(basename "$0")" >> "${LOGFILE}"

# Change to workdir
cd "${WORKDIR}"

# --- Job steps ---

# 1. Pull new research (manual drop workflow - optional)
echo "[INFO] Step 1: Checking for new research in raw/articles/" >> "${LOGFILE}"
if [[ -d "raw/articles" ]]; then
    ARTICLE_COUNT=$(find raw/articles -type f 2>/dev/null | wc -l)
    echo "[INFO] Found ${ARTICLE_COUNT} article(s) in raw/articles/" >> "${LOGFILE}"
else
    echo "[INFO] raw/articles/ not found, skipping research pull" >> "${LOGFILE}"
fi

# 2. Run incremental compile
echo "[INFO] Step 2: Running hermes-brain-compile --incremental" >> "${LOGFILE}"
if command -v hermes-brain-compile &> /dev/null; then
    hermes-brain-compile --incremental >> "${LOGFILE}" 2>&1
else
    echo "[ERROR] hermes-brain-compile not found in PATH" >> "${LOGFILE}"
    exit 1
fi

# 3. Update knowledge graph
echo "[INFO] Step 3: Updating knowledge graph" >> "${LOGFILE}"
if [[ -f "tools/build_edges.py" ]]; then
    python3 tools/build_edges.py --input wiki/ --output graph/ >> "${LOGFILE}" 2>&1
else
    echo "[WARNING] tools/build_edges.py not found, skipping graph update" >> "${LOGFILE}"
fi

# 4. Generate daily digest
echo "[INFO] Step 4: Generating daily digest" >> "${LOGFILE}"
if command -v hermes-brain-digest &> /dev/null; then
    hermes-brain-digest --daily --output "${DIGEST_FILE}" >> "${LOGFILE}" 2>&1 || true
else
    echo "[WARNING] hermes-brain-digest not found, creating basic digest" >> "${LOGFILE}"
    echo "# Daily Digest — ${DIGEST_DATE}" > "${DIGEST_FILE}"
    echo "" >> "${DIGEST_FILE}"
    echo "Compile completed successfully." >> "${DIGEST_FILE}"
fi

# 5. Send email digest (if configured)
if command -v mail &> /dev/null && [[ -f "${DIGEST_FILE}" ]]; then
    echo "[INFO] Step 5: Sending email digest" >> "${LOGFILE}"
    echo "Daily digest attached" | mail -s "Hermes Daily Digest — ${DIGEST_DATE}" tokisaki@localhost < "${DIGEST_FILE}" || true
else
    echo "[INFO] Email not configured or digest missing, skipping" >> "${LOGFILE}"
fi

# 6. Post to Telegram (if configured)
if [[ -f "${HOME}/.hermes/telegram_config.py" ]]; then
    echo "[INFO] Step 6: Posting to Telegram" >> "${LOGFILE}"
    # Source the config and send
    source "${HOME}/.hermes/telegram_config.py" 2>/dev/null || true
    if [[ -n "${TELEGRAM_BOT_TOKEN:-}" && -n "${TELEGRAM_CHAT_ID:-}" ]]; then
        MESSAGE=$(head -20 "${DIGEST_FILE}" | tr '\n' ' ' | sed 's/"/\\"/g')
        curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
             -d "chat_id=${TELEGRAM_CHAT_ID}" \
             -d "text=${MESSAGE}" > /dev/null 2>&1 || true
    else
        echo "[INFO] Telegram config incomplete, skipping" >> "${LOGFILE}"
    fi
else
    echo "[INFO] Telegram config not found, skipping" >> "${LOGFILE}"
fi

# 7. Log completion to wiki/log.md
echo "[INFO] Step 7: Logging completion" >> "${LOGFILE}"
END_TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
DURATION=$(( $(date -d "${END_TIMESTAMP}" +%s) - $(date -d "${TIMESTAMP}" +%s) ))
DURATION_STR="$(( DURATION / 60 ))m"
if [[ -f "wiki/log.md" ]]; then
    echo "${END_TIMESTAMP} | DAILY_SYNC | duration=${DURATION_STR}" >> "wiki/log.md"
fi

# --- End job steps ---

# Log completion
EXIT_CODE=$?
END_TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
if [[ $EXIT_CODE -eq 0 ]]; then
    echo "[SUCCESS] ${END_TIMESTAMP} — exit=${EXIT_CODE}" >> "${LOGFILE}"
else
    echo "[FAILURE] ${END_TIMESTAMP} — exit=${EXIT_CODE}" >> "${LOGFILE}"
fi

exit $EXIT_CODE
