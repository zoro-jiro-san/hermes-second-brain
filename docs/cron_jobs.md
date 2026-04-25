# Hermes Second Brain — Cron Jobs Schedule

**Version:** 1.0
**Date:** 2026-04-26
**Owner:** Hermes Agent (Nous Research)
**Scope:** Automated maintenance, ingestion, health checks, and reporting

---

## Table of Contents

1. [Overview](#overview)
2. [Job Schedule](#job-schedule)
3. [Job Specifications](#job-specifications)
4. [Script Templates](#script-templates)
5. [Alerting & Monitoring](#alerting--monitoring)
6. [Installation](#installation)
7. [Disaster Recovery](#disaster-recovery)

---

## Overview

Hermes Second Brain runs four automated cron jobs to maintain knowledge integrity, ingest new research, distribute insights, and perform maintenance.

### Job Categories

| Category | Frequency | Purpose |
|----------|-----------|---------|
| **Health Check** | Hourly | Detect broken links, empty files, duplicate entities |
| **Daily Sync** | Daily 3 AM | Pull new research → compile wiki → update graph → digest |
| **Weekly Digest** | Weekly Sun 6 AM | Full lint → insights summary → Telegram/Email |
| **Monthly Clean** | Monthly 1st 2 AM | Prune drafts, compress logs, database maintenance |

### Execution Environment

- **User:** `tokisaki` (cron runs under this user)
- **Working directory:** `/home/tokisaki/work/synthesis/`
- **Python environment:** Assumes `hermes-brain-*` CLI tools in PATH (pip install -e .)
- **Environment variables:** Read from `~/.hermes/.env` (ANTHROPIC_API_KEY, etc.)
- **Log directory:** `/var/log/hermes/` (must exist; scripts create if missing)
- **Permissions:** Scripts executable by user `tokisaki` only

---

## Job Schedule

### Cron Table

Install with `crontab -e` (user: tokisaki). Copy-paste the block below:

```bash
# =============================================================================
# HERMES SECOND BRAIN AUTOMATION
# Edit: crontab -e (user=tokisaki)
# =============================================================================

# ── PATH (ensure hermes-brain-* tools are available)
PATH=/usr/local/bin:/usr/bin:/bin:/home/tokisaki/.local/bin

# ── Hourly Health Check (minute 15)
# Purpose: Fast mechanical lint; alert on critical failures
15 * * * * /home/tokisaki/work/synthesis/cron/health_check.sh >> /var/log/hermes/health.log 2>&1

# ── Daily Research Sync (3:00 AM)
# Purpose: Ingest new sources, compile wiki, update graph, send digest
0 3 * * * /home/tokisaki/work/synthesis/cron/daily_sync.sh >> /var/log/hermes/daily_sync.log 2>&1

# ── Weekly Insight Digest (Sunday 6:00 AM)
# Purpose: Full lint, insights summary, Telegram + email
0 6 * * 0 /home/tokisaki/work/synthesis/cron/weekly_digest.sh >> /var/log/hermes/weekly_digest.log 2>&1

# ── Monthly Deep Clean (1st of month, 2:00 AM)
# Purpose: Prune old drafts, compress logs, database VACUUM
0 2 1 * * /home/tokisaki/work/synthesis/cron/monthly_clean.sh >> /var/log/hermes/monthly_clean.log 2>&1
```

### Timing Rationale

| Job | Time | Reason |
|-----|------|--------|
| **Health Check** | :15 hourly | Avoid cron contention at top of hour; catch issues quickly |
| **Daily Sync** | 3:00 AM | Off-peak hours; research RSS feeds typically updated by 2 AM |
| **Weekly Digest** | Sun 6:00 AM | Week in review before workday starts |
| **Monthly Clean** | 1st 2:00 AM | Start of month; minimal user activity |

---

## Job Specifications

### 1. Hourly Health Check

**Trigger:** Every hour at minute 15
**Duration:** ~10–30 seconds
**Exit codes:** 0 (OK), 1 (warnings), 2 (critical)

**Steps:**
1. Run `hermes-brain-lint --fast` (mechanical checks only: orphans, broken links, duplicates, index consistency)
2. Verify `wiki/` directory is non-empty and `index.md` exists
3. Check `~/.hermes/skills/` symlinks are valid (no broken links)
4. Alert on critical failures only (index missing, broken index, duplicate slugs)
5. Log results: timestamp, page count, error count, duration

**Alert conditions (send Telegram + email):**
- `wiki/index.md` missing or invalid
- Duplicate slugs detected (pages with same `slug:` frontmatter)
- Broken symlink in `~/.hermes/skills/`
- `health_check.sh` script itself fails (permission, missing binary)

**Output:** `/var/log/hermes/health.log` (rotated weekly, keep 8 weeks)

---

### 2. Daily Research Sync (3:00 AM)

**Trigger:** Daily at 3:00 AM
**Duration:** 5–20 minutes (depends on new sources)
**Exit codes:** 0 (success), 1 (partial failure), 2 (complete failure)

**Steps:**
1. **Pull new research** (if RSS/newsletter configured)
   ```bash
   # Optional: run research fetcher (not implemented by default)
   # /home/tokisaki/work/synthesis/tools/fetch_research.py --output raw/articles/
   ```
   *Note: Manual drop of files into `raw/articles/` is primary workflow.*

2. **Run incremental compile**
   ```bash
   hermes-brain-compile --incremental
   ```
   - Detects new/modified files in `raw/` (by hash)
   - Extracts entities, concepts, claims
   - Updates/create wiki pages
   - Rebuilds `wiki/index.md`

3. **Update knowledge graph**
   ```bash
   python3 /home/tokisaki/work/synthesis/build_edges.py --input wiki/ --output graph/
   ```
   - Extracts node/edge relationships from updated wiki
   - Merges into `graph/nodes.json` and `graph/edges.json`
   - Optionally: re-embed nodes (if using vector search)

4. **Generate daily digest**
   ```bash
   hermes-brain-digest --daily --output reports/digest_$(date +%Y-%m-%d).md
   ```
   - Summarizes: sources added, pages updated, new entities, contradictions flagged
   - Format: markdown with bullet points

5. **Send email digest** (if configured)
   ```bash
   mail -s "Hermes Daily Digest — $(date +%Y-%m-%d)" tokisaki@localhost < reports/digest_$(date +%Y-%m-%d).md
   ```

6. **Post to Telegram** (if bot configured)
   ```bash
   curl -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        -d "chat_id=${TELEGRAM_CHAT_ID}" \
        -d "text=$(cat reports/digest_$(date +%Y-%m-%d).md | head -20)"
   ```

7. **Log completion**
   Append to `wiki/log.md`:
   ```
   2026-04-26T03:00:00Z | DAILY_SYNC | sources_added=2, pages_updated=5, contradictions=0, duration=12m
   ```

**Alert conditions:**
- Compile exit code != 0
- Graph update fails
- Digest generation fails
- Any step exceeds timeout (default: 30 minutes)

---

### 3. Weekly Insight Digest (Sunday 6:00 AM)

**Trigger:** Every Sunday at 6:00 AM
**Duration:** 5–15 minutes

**Steps:**
1. **Run full lint**
   ```bash
   hermes-brain-lint --full --output reports/lint_$(date +%Y-%m-%d).md
   ```
   - Mechanical (fast): orphans, broken links, duplicates, index drift
   - Semantic (LLM-powered): contradictions, stale claims, gap detection, cross-reference gaps

2. **Generate weekly insights summary**
   ```bash
   hermes-brain-digest --weekly --lint-report reports/lint_$(date +%Y-%m-%d).md \
                       --output reports/weekly_insights_$(date +%Y-%m-%d).md
   ```
   Content includes:
   - New concepts discovered this week
   - Top contradictions (by confidence)
   - Orphan pages requiring attention
   - Gap concepts (high-frequency terms without pages)
   - Trending entities (most cited this week)

3. **Send email**
   ```bash
   mail -s "Hermes Weekly Insights — w$(date +%V)" tokisaki@localhost < reports/weekly_insights_$(date +%Y-%m-%d).md
   ```

4. **Post to Telegram channel** (rich formatting)
   ```bash
   # Format: bold headings, bullet points, emojis
   MESSAGE="📊 *Hermes Weekly Insights — w$(date +%V)*\n\n"
   MESSAGE+="✅ New pages: 12\n"
   MESSAGE+="⚠️ Contradictions: 3 (see lint report)\n"
   MESSAGE+="💡 Gaps identified: 5\n"
   MESSAGE+="📄 Full report: file:///home/tokisaki/work/synthesis/reports/lint_$(date +%Y-%m-%d).md"
   curl -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        -d "chat_id=${TELEGRAM_CHAT_ID}" \
        -d "text=${MESSAGE}" \
        -d "parse_mode=MarkdownV2"
   ```

5. **Archive old drafts** (older than 30 days)
   ```bash
   find /home/tokisaki/work/synthesis/wiki/drafts -type f -mtime +30 -delete
   ```

6. **Log completion**
   ```
   2026-04-26T06:00:00Z | WEEKLY_DIGEST | lint_pages=1247, contradictions=3, gaps=5, posted=telegram,email
   ```

**Alert conditions:**
- Lint found >10 orphan pages
- Contradictions detected in high-traffic concepts
- Script failure

---

### 4. Monthly Deep Clean (1st 2:00 AM)

**Trigger:** 1st day of each month at 2:00 AM
**Duration:** 3–10 minutes

**Steps:**
1. **Run deep semantic lint**
   ```bash
   hermes-brain-lint --full --semantic --output reports/lint_monthly_$(date +%Y-%m).md
   ```
   - Same as weekly but includes: data staleness check, source citation audit

2. **Prune unreferenced orphan pages**
   - Orphan pages (zero inbound links) older than 90 days
   - Candidate list from lint report
   - Move to `wiki/archive/orphans/` (not delete) for manual review
   ```bash
   hermes-brain-lint --orphans --age 90d --archive wiki/archive/orphans/
   ```

3. **Compress & rotate `wiki/log.md`**
   - Keep last 1000 lines in `wiki/log.md`
   - Archive rest to `wiki/log.archives/log_$(date +%Y-%m).txt.gz`
   ```bash
   tail -n 1000 wiki/log.md > wiki/log.md.tmp && mv wiki/log.md.tmp wiki/log.md
   head -n -1000 wiki/log.md | gzip > "wiki/log.archives/log_$(date +%Y-%m).txt.gz"
   ```

4. **Database maintenance** (if using SQLite/Neo4j)
   ```bash
   # SQLite VACUUM
   sqlite3 graph/cache/wiki.db "VACUUM;"

   # Neo4j cleanup (if running as service)
   # cypher-shell -u neo4j -p password "CALL dbms.clearQueryCaches();"
   ```

5. **Cleanup old reports**
   - Delete reports older than 90 days
   ```bash
   find /home/tokisaki/work/synthesis/reports -type f -mtime +90 -delete
   ```

6. **Log completion**
   ```
   2026-05-01T02:00:00Z | MONTHLY_CLEAN | orphans_archived=7, log_rotated=true, db_vacuumed=true
   ```

**Alert conditions:**
- Orphan archive >50 pages (potential knowledge fragmentation)
- Log rotation fails
- Database maintenance errors

---

## Script Templates

All cron scripts should follow this template:

```bash
#!/usr/bin/env bash
# cron/<job_name>.sh — Hermes Second Brain automation

set -euo pipefail

# Configuration
export HOME="/home/tokisaki"
WORKDIR="${HOME}/work/synthesis"
LOG_DIR="/var/log/hermes"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
LOGFILE="${LOG_DIR}/$(basename "$0" .sh).log"

# Ensure log dir exists
mkdir -p "${LOG_DIR}"

# Log start
echo "[START] ${TIMESTAMP} — $(basename "$0")" >> "${LOGFILE}"

# Change to workdir
cd "${WORKDIR}"

# --- Job steps below ---

# Example: hermes-brain-compile --incremental >> "${LOGFILE}" 2>&1

# --- End job steps ---

# Log completion
EXIT_CODE=$?
END_TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
if [[ $EXIT_CODE -eq 0 ]]; then
    echo "[SUCCESS] ${END_TIMESTAMP} — exit=${EXIT_CODE}" >> "${LOGFILE}"
else
    echo "[FAILURE] ${END_TIMESTAMP} — exit=${EXIT_CODE}" >> "${LOGFILE}"
    # Send alerts
    # (Telegram webhook + email logic here)
fi

exit $EXIT_CODE
```

### Implemented Scripts

Four scripts must exist in `cron/`:

| Script | Purpose | Key Commands |
|--------|---------|--------------|
| `health_check.sh` | Hourly fast lint + symlink check | `hermes-brain-lint --fast`, `find ~/.hermes/skills -xtype l` |
| `daily_sync.sh`   | Daily ingest + compile + graph + digest | `hermes-brain-compile --incremental`, `build_edges.py`, `hermes-brain-digest --daily` |
| `weekly_digest.sh`| Weekly full lint + insights + notify | `hermes-brain-lint --full --semantic`, `hermes-brain-digest --weekly`, Telegram/email |
| `monthly_clean.sh`| Monthly prune + rotate + vacuum | `find ... -mtime +90`, `tail/gzip`, `sqlite3 VACUUM` |

---

## Alerting & Monitoring

### Alert Channels

| Severity | Conditions | Channels |
|----------|------------|----------|
| **Critical** | Compile failure, index corruption, duplicate slugs, broken index | Telegram (immediate) + Email |
| **Warning**   | Orphan pages (>50), many broken links, stale pages (>30 days) | Telegram (digest in weekly) |
| **Info**      | Successful runs, metrics | Log files only |

### Telegram Bot Setup

```python
# ~/.hermes/telegram_config.py
TELEGRAM_BOT_TOKEN="123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11"
TELEGRAM_CHAT_ID="123456789"  # Your user ID or channel ID

# Send message function
send_telegram(message: str, parse_mode: str = "MarkdownV2"):
    import requests
    url = f"https://api.telegram.org/bot{TELEGRAM_BOT_TOKEN}/sendMessage"
    payload = {"chat_id": TELEGRAM_CHAT_ID, "text": message, "parse_mode": parse_mode}
    requests.post(url, json=payload)
```

Cron scripts use:
```bash
source ~/.hermes/telegram_config.py
curl -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" ...
```

### Email Setup

Use `mail` (sendmail/postfix) or `mutt`. Configure `~/.mailrc` or system MTA.

Test:
```bash
echo "Test" | mail -s "Hermes test" tokisaki@localhost
```

### Log Rotation

Configure `/etc/logrotate.d/hermes`:
```
/var/log/hermes/*.log {
    weekly
    rotate 8
    compress
    missingok
    notifempty
    create 0640 tokisaki tokisaki
}
```

---

## Installation

### Step 1: Create log directory

```bash
sudo mkdir -p /var/log/hermes
sudo chown tokisaki:tokisaki /var/log/hermes
chmod 750 /var/log/hermes
```

### Step 2: Create cron directory and scripts

```bash
mkdir -p /home/tokisaki/work/synthesis/cron
# Copy scripts: health_check.sh, daily_sync.sh, weekly_digest.sh, monthly_clean.sh
# (See script templates above; will be provided separately)
chmod +x /home/tokisaki/work/synthesis/cron/*.sh
```

### Step 3: Install CLI tools

```bash
cd /home/tokisaki/work/synthesis/tools
pip install -e .
# Verify installation
which hermes-brain-compile   # Should resolve
hermes-brain-compile --help  # Should show usage
```

### Step 4: Install crontab entries

```bash
crontab -e
# Paste the cron table from "Job Schedule" section above
# Save and exit
```

Verify:
```bash
crontab -l  # List installed jobs
```

### Step 5: Test each job manually

```bash
# Test health check
/home/tokisaki/work/synthesis/cron/health_check.sh

# Test daily sync
/home/tokisaki/work/synthesis/cron/daily_sync.sh

# Test weekly digest
/home/tokisaki/work/synthesis/cron/weekly_digest.sh

# Test monthly clean
/home/tokisaki/work/synthesis/cron/monthly_clean.sh
```

Check exit codes and log output: `tail -f /var/log/hermes/*.log`

---

## Disaster Recovery

### If a cron job fails repeatedly:

1. Check logs: `tail -n 50 /var/log/hermes/<job>.log`
2. Test command manually: run the script directly
3. Verify environment: `echo $PATH`, `echo $ANTHROPIC_API_KEY` (stored in `~/.hermes/.env`)
4. Ensure `hermes-brain-*` CLI tools installed and callable
5. Check disk space: `df -h /home/tokisaki/work/synthesis`
6. If LLM API failure: verify API key, quotas, network connectivity

### If wiki corrupted:

```bash
# Restore from backup
cp -r ~/.hermes/vault.backup ~/.hermes/vault

# Re-run full compile from raw
hermes-brain-compile --full

# Rebuild graph
python3 build_edges.py --input wiki/ --output graph/
```

### If index out of sync:

```bash
# Force rebuild index
hermes-brain-lint --index --fix

# Or full recompile
hermes-brain-compile --full
```

### If skills not loading:

```bash
# Re-run symlink installer
./symlink_setup.sh

# Verify
ls -la ~/.hermes/skills/
hermes skills list

# Restart Hermes agent if running as daemon
systemctl --user restart hermes-agent
```

---

## Monitoring Dashboard (Optional)

Create a simple status page:

```bash
#!/usr/bin/env bash
# tools/brain_status.sh
echo "=== Hermes Second Brain Status ==="
echo "Wiki pages:     $(find wiki -name '*.md' | wc -l)"
echo "Raw sources:    $(find raw -type f | wc -l)"
echo "Graph nodes:    $(jq length graph/nodes.json 2>/dev/null || echo 'N/A')"
echo "Graph edges:    $(jq length graph/edges.json 2>/dev/null || echo 'N/A')"
echo "Last compile:   $(tail -1 wiki/log.md | cut -d'|' -f1)"
echo "Health status:  $(hermes-brain-lint --fast >/dev/null 2>&1 && echo 'OK' || echo 'ISSUES DETECTED')"
echo "Cron next run:  $(crontab -l | grep -v '^#' | head -1)"
```

Schedule this to run hourly and post to dashboard or internal status page.

---

## Change Log

| Date | Change | Author |
|------|--------|--------|
| 2026-04-26 | Initial specification | Hermes Agent |

---

*End of cron jobs specification.*
