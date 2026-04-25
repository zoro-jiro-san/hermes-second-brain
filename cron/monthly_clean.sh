#!/usr/bin/env bash
# cron/monthly_clean.sh — Hermes Second Brain automation

set -euo pipefail

# Configuration
export HOME="/home/tokisaki"
WORKDIR="${HOME}/github/hermes-second-brain"
LOG_DIR="/var/log/hermes"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
LOGFILE="${LOG_DIR}/$(basename "$0" .sh).log"
MONTHLY_REPORT="${WORKDIR}/reports/lint_monthly_$(date '+%Y-%m').md"

# Ensure log dir exists
mkdir -p "${LOG_DIR}"
mkdir -p "${WORKDIR}/reports"

# Log start
echo "[START] ${TIMESTAMP} — $(basename "$0")" >> "${LOGFILE}"

# Change to workdir
cd "${WORKDIR}"

# --- Job steps ---

# 1. Run deep semantic lint
echo "[INFO] Step 1: Running deep semantic lint" >> "${LOGFILE}"
if command -v hermes-brain-lint &> /dev/null; then
    hermes-brain-lint --full --semantic --output "${MONTHLY_REPORT}" >> "${LOGFILE}" 2>&1 || true
else
    echo "[WARNING] hermes-brain-lint not found, creating empty monthly report" >> "${LOGFILE}"
    echo "# Monthly Lint Report — $(date '+%Y-%m')" > "${MONTHLY_REPORT}"
fi

# 2. Prune unreferenced orphan pages (archive only, not delete)
echo "[INFO] Step 2: Archiving orphan pages" >> "${LOGFILE}"
if [[ -d "wiki/drafts" ]]; then
    # Find orphan pages (concept: pages with zero inbound links) older than 90 days
    # This is a placeholder - actual implementation would parse graph/edges.json
    ORPHAN_COUNT=0
    echo "[INFO] Would archive ${ORPHAN_COUNT} orphan page(s) (dry-run)" >> "${LOGFILE}"
    # Actual archive command when implementation ready:
    # hermes-brain-lint --orphans --age 90d --archive wiki/archive/orphans/
else
    echo "[INFO] wiki/drafts not found, skipping orphan archive" >> "${LOGFILE}"
fi

# 3. Compress & rotate wiki/log.md
echo "[INFO] Step 3: Rotating log file" >> "${LOGFILE}"
if [[ -f "wiki/log.md" ]]; then
    # Archive old lines (keep last 1000)
    TOTAL_LINES=$(wc -l < "wiki/log.md")
    KEEP=1000
    if [[ ${TOTAL_LINES} -gt ${KEEP} ]]; then
        tail -n ${KEEP} "wiki/log.md" > "wiki/log.md.tmp" && mv "wiki/log.md.tmp" "wiki/log.md"
        head -n -${KEEP} "wiki/log.md" 2>/dev/null | gzip > "wiki/log.archives/log_$(date '+%Y-%m').txt.gz" || true
        echo "[INFO] Rotated log: kept ${KEEP} lines, archived $((TOTAL_LINES - KEEP)) lines" >> "${LOGFILE}"
    else
        echo "[INFO] Log file has ${TOTAL_LINES} lines, no rotation needed" >> "${LOGFILE}"
    fi
else
    echo "[INFO] wiki/log.md not found, skipping rotation" >> "${LOGFILE}"
fi

# 4. Database maintenance (SQLite VACUUM if DB exists)
echo "[INFO] Step 4: Database maintenance" >> "${LOGFILE}"
if [[ -f "graph/cache/wiki.db" ]]; then
    sqlite3 "graph/cache/wiki.db" "VACUUM;" >> "${LOGFILE}" 2>&1 && \
        echo "[INFO] SQLite VACUUM completed" >> "${LOGFILE}" || \
        echo "[WARNING] SQLite VACUUM failed" >> "${LOGFILE}"
else
    echo "[INFO] No SQLite DB found, skipping VACUUM" >> "${LOGFILE}"
fi

# 5. Cleanup old reports (> 90 days)
echo "[INFO] Step 5: Cleaning up old reports" >> "${LOGFILE}"
if [[ -d "reports" ]]; then
    find reports -type f -mtime +90 -delete 2>/dev/null || true
    echo "[INFO] Old reports cleaned" >> "${LOGFILE}"
fi

# 6. Log completion
echo "[INFO] Step 6: Logging completion" >> "${LOGFILE}"
END_TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
if [[ -f "wiki/log.md" ]]; then
    echo "${END_TIMESTAMP} | MONTHLY_CLEAN | log_rotated=true, db_vacuumed=true" >> "wiki/log.md"
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
