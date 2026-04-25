#!/usr/bin/env bash
# cron/weekly_digest.sh — Hermes Second Brain automation

set -euo pipefail

# Configuration
export HOME="/home/tokisaki"
WORKDIR="${HOME}/github/hermes-second-brain"
LOG_DIR="/var/log/hermes"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
LOGFILE="${LOG_DIR}/$(basename "$0" .sh).log"
WEEKLY_REPORT="${WORKDIR}/reports/weekly_insights_$(date '+%Y-%m-%d').md"
LINT_REPORT="${WORKDIR}/reports/lint_$(date '+%Y-%m-%d').md"

# Ensure log dir exists
mkdir -p "${LOG_DIR}"
mkdir -p "${WORKDIR}/reports"

# Log start
echo "[START] ${TIMESTAMP} — $(basename "$0")" >> "${LOGFILE}"

# Change to workdir
cd "${WORKDIR}"

# --- Job steps ---

# 1. Run full lint (mechanical + semantic if available)
echo "[INFO] Step 1: Running hermes-brain-lint --full" >> "${LOGFILE}"
if command -v hermes-brain-lint &> /dev/null; then
    hermes-brain-lint --full --output "${LINT_REPORT}" >> "${LOGFILE}" 2>&1 || true
else
    echo "[WARNING] hermes-brain-lint not found, creating empty lint report" >> "${LOGFILE}"
    echo "# Lint Report — $(date '+%Y-%m-%d')" > "${LINT_REPORT}"
fi

# 2. Generate weekly insights summary
echo "[INFO] Step 2: Generating weekly insights" >> "${LOGFILE}"
if command -v hermes-brain-digest &> /dev/null; then
    hermes-brain-digest --weekly --lint-report "${LINT_REPORT}" --output "${WEEKLY_REPORT}" >> "${LOGFILE}" 2>&1 || true
else
    echo "[WARNING] hermes-brain-digest not found, creating basic weekly report" >> "${LOGFILE}"
    echo "# Weekly Insights — w$(date +%V)" > "${WEEKLY_REPORT}"
    echo "" >> "${WEEKLY_REPORT}"
    echo "Lint report generated. See: ${LINT_REPORT}" >> "${WEEKLY_REPORT}"
fi

# 3. Send email (if configured)
if command -v mail &> /dev/null && [[ -f "${WEEKLY_REPORT}" ]]; then
    echo "[INFO] Step 3: Sending weekly email" >> "${LOGFILE}"
    mail -s "Hermes Weekly Insights — w$(date +%V)" tokisaki@localhost < "${WEEKLY_REPORT}" || true
fi

# 4. Post to Telegram (rich formatting)
if [[ -f "${HOME}/.hermes/telegram_config.py" ]]; then
    echo "[INFO] Step 4: Posting to Telegram" >> "${LOGFILE}"
    source "${HOME}/.hermes/telegram_config.py" 2>/dev/null || true
    if [[ -n "${TELEGRAM_BOT_TOKEN:-}" && -n "${TELEGRAM_CHAT_ID:-}" ]]; then
        MESSAGE="📊 *Hermes Weekly Insights — w$(date +%V)*\n\n"
        MESSAGE+="✅ New pages: See full report\n"
        MESSAGE+="📄 Full report: file://${LINT_REPORT}"
        curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
             -d "chat_id=${TELEGRAM_CHAT_ID}" \
             -d "text=${MESSAGE}" \
             -d "parse_mode=MarkdownV2" > /dev/null 2>&1 || true
    fi
fi

# 5. Archive old drafts (> 30 days)
echo "[INFO] Step 5: Archiving old drafts" >> "${LOGFILE}"
if [[ -d "wiki/drafts" ]]; then
    find wiki/drafts -type f -mtime +30 -delete 2>/dev/null || true
    echo "[INFO] Old drafts archived" >> "${LOGFILE}"
else
    echo "[INFO] wiki/drafts not found, skipping" >> "${LOGFILE}"
fi

# 6. Log completion
echo "[INFO] Step 6: Logging completion" >> "${LOGFILE}"
END_TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
if [[ -f "wiki/log.md" ]]; then
    echo "${END_TIMESTAMP} | WEEKLY_DIGEST | posted=telegram,email" >> "wiki/log.md"
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
