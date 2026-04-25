# Nightly Loop Integration Report

**Date:** 2026-04-26
**Audience:** Nico (zoro-jiro-san)
**Author:** Hermes Agent (Nous Research)

---

## Executive Summary

Hermes currently maintains **two parallel nightly automation systems**:

1. **Legacy System Cron** (currently non-functional) — 4 shell scripts in `/home/tokisaki/github/hermes-second-brain/cron/` that should run hourly/daily/weekly/monthly but are misconfigured (crontab points to `/home/tokisaki/work/synthesis/cron/` which doesn't exist). Logs are empty → no execution.

2. **Active Hermes Agent Scheduler** — 8+ AI-driven jobs defined in `~/.hermes/cron/jobs.json` that run automatically via the long-lived agent process (`hermes_cli.main gateway run`). These produce research outputs to `~/.hermes/night-research/` and push to GitHub repos (daily-learnings, hermes-agent-architecture).

**Key observation:** The `hermes-brain-compile` tool exists and works (generates wiki stubs from `raw/articles/`), and the weekly digest infrastructure (`weekly_digest.sh`) exists but fails due to missing `hermes-brain-digest`. These should be migrated into the agent's nightly loop rather than relying on broken system cron.

**Z.AI quota monitoring:** `~/.hermes/scripts/zai_quota.py` monitors Z.AI API usage (session, weekly, time limits) and is referenced by the `hermes-token-optimization` skill.

---

## 1. System Cron (Legacy — Misconfigured)

### Crontab Entries (as of now)

```
15 * * * * /home/tokisaki/work/synthesis/cron/health_check.sh >> /var/log/hermes/health.log 2>&1
0 3 * * * /home/tokisaki/work/synthesis/cron/daily_sync.sh >> /var/log/hermes/daily_sync.log 2>&1
0 6 * * 0 /home/tokisaki/work/synthesis/cron/weekly_digest.sh >> /var/log/hermes/weekly_digest.log 2>&1
0 2 1 * * /home/tokisaki/work/synthesis/cron/monthly_clean.sh >> /var/log/hermes/monthly_clean.log 2>&1
```

### Actual Script Location

Scripts reside in: `/home/tokisaki/github/hermes-second-brain/cron/`
- `health_check.sh` — fast lint + symlink validation
- `daily_sync.sh` — compile wiki, update graph, generate digest, email/Telegram
- `weekly_digest.sh` — full lint + weekly insights + Telegram
- `monthly_clean.sh` — deep lint, orphan cleanup, log rotation, DB VACUUM

**Problem:** Crontab points to `/home/tokisaki/work/synthesis/cron/` which does **not exist** (directory missing). Logs in `/var/log/hermes/` are empty → no jobs are actually running via system cron.

A `cron_install.json` report dated 2026-04-26T01:15:00Z claims scripts were copied to `work/synthesis/cron/`, but the directory is absent. Likely a cleanup removed it or copy never persisted.

**Status:** ❌ Broken — execution path invalid.

---

## 2. Hermes Agent Scheduler (Active)

The agent runs as a daemon:
```
/home/tokisaki/.hermes/hermes-agent/venv/bin/python -m hermes_cli.main gateway run --replace
```

Jobs are defined in `~/.hermes/cron/jobs.json` and executed via LLM-driven prompts (model: glm-4.5-air, provider: zai). Outputs saved to `~/.hermes/cron/output/<job_id>/`.

### Weekly Pipeline (from SKILL.md)

```
00:00 — Deep Tech Research      (daily, 3000–5000 words on new topic)
01:30 — Daydreaming Session      (creative exploration, analogies)
03:00 — Self-Architecture        (improve own architecture, iterate)
04:30 — Global News Scrape        (curated news digest 1500–2500 words)
06:00 — Repo Update & Consolidation (push to GitHub: daily-learnings & hermes-agent-architecture)
08:00 — Morning Summary          (Telegram briefing under 4000 chars)
21:00 — Daily Learnings          (catch-up from day sessions)
```

### Additional Daily Maintenance Jobs

| Job | Schedule | Purpose |
|-----|---------|---------|
| Hermes Self-Update | 07:00 daily | Run `hermes update` (currently failing with empty response) |
| Repo Update Reminder | 22:00 daily | Check if daily-learnings & arch repos updated; remind if stale |
| Disk Cleanup | 06:30 daily | Run `~/.hermes/scripts/disk-cleanup.sh` (currently failing) |
| Daily Malware Scan | 03:45 daily | Run ClamAV/rkhunter/Lynis, report findings |
| Cognee Sync | 06:20 daily | Sync cron outputs to Cognee cloud dataset |
| TMP Snapshot Push | 00:00 daily | Push /tmp snapshot to GitHub backup |
| TMP Safe Cleanup | 00:20 daily | Clean /tmp only if same-day snapshot exists |
| German Course Monitor | 10:00 Mondays | Check Berlin VHS/ZeBuS/WBS for A1 course dates |

### Outputs & Delivery

- Research outputs: `~/.hermes/night-research/` (RESEARCH-*.md, daydream-*.md, arch-*.md, news-*.md)
- Agent job logs: `~/.hermes/cron/output/<job_id>/<timestamp>.md`
- GitHub push: SSH to `git@github.com:zoro-jiro-san/daily-learnings.git` and `git@github.com:zoro-jiro-san/hermes-agent-architecture.git`
- Delivery origin: Telegram (chat_id: 7833088241) for summaries and reminders

**Status:** ✅ Active — agent daemon running, jobs scheduled via internal scheduler.

---

## 3. Zai Quota Monitor (`~/.hermes/scripts/zai_quota.py`)

**Purpose:** Monitor Z.AI API usage quotas via undocumented endpoint `GET https://api.z.ai/api/monitor/usage/quota/limit`.

**Monitors:**
- **Session limit** — 5-hour rolling window (5M tokens) — unit=3, period=5h
- **Weekly limit** — 7-day rolling window (likely 50M) — unit=6, period=7d
- **Time limits** — web_search/reader/zread call quotas
- Reset times and remaining percentages

**Usage:**
```bash
python3 ~/.hermes/scripts/zai_quota.py          # human-readable
python3 ~/.hermes/scripts/zai_quota.py --json   # raw JSON
python3 ~/.hermes/scripts/zai_quota.py --percent # session % only (for scripts)
```

**Integration:** Used by `hermes-token-optimization` skill to throttle agent activity if Z.AI quota is exhausted. Session (5h) is the tightest constraint — the script returns current session percentage.

**Recent failure evidence:** Deep Research job on 2026-04-26 hit `HTTP 429: Insufficient balance` after 3 retries → quota exhausted. The agent continued anyway (the job produced an error report rather than silently failing). The `zai_quota.py` check should be gated before launching expensive research jobs.

---

## 4. Current Nightly Loop — Complete Schedule (CEST, UTC+2)

| Time | Job | Type | Output | Delivery |
|------|-----|------|--------|----------|
| 00:00 | Deep Tech Research | Agent (ae30be4c47ab) | `~/.hermes/night-research/RESEARCH-YYYY-MM-DD.md` | local (no push) |
| 00:00 | TMP Snapshot Push | Agent (a9eb14d0a9eb) | Git commit to backup repo | local |
| 00:20 | TMP Safe Cleanup | Agent (b4e69023a8af) | Log summary | local |
| 01:30 | Daydreaming Session | Agent (f81ecfb9c2b0) | `~/.hermes/night-research/daydream-YYYY-MM-DD.md` + push to arch repo | local |
| 03:00 | Self-Architecture Research | Agent (59cf35e5c622) | `~/.hermes/night-research/arch-YYYY-MM-DD.md` + push to arch repo | local |
| 03:45 | Daily Malware Scan | Agent (d8a2605ee2a1) | Scan report summary | local |
| 04:30 | Global News Scrape | Agent (dc6da511dd91) | `~/.hermes/night-research/news-YYYY-MM-DD.md` | local |
| 06:00 | Repo Update & Consolidation | Agent (2cb5ab614036) | Push to daily-learnings & arch repos | local |
| 06:20 | Cognee Sync | Agent (56fb1ee99d48) | Cognee dataset status | local |
| 06:30 | Disk Cleanup | Agent (97ecbd9da843) | Space freed summary | local |
| 07:00 | Hermes Self-Update | Agent (19899937be9d) | Update status | local (currently erroring) |
| 08:00 | Morning Summary | Agent (c780648cc5b2) | Telegram message (<4000 chars) | Telegram |
| 09:00 PM | Daily Learnings | Agent (3af6bd9734b5) | Push to daily-learnings | Telegram |
| 10:00 PM | Repo Update Reminder | Agent (4ffb553be43f) | Reminder if repos stale | Telegram |
| Weekly Sun 06:00 | Weekly Insight Digest | System cron (broken) | Full lint + insights report | Telegram+email |

The agent's internal schedule dominates; system cron jobs are disabled due to path errors.

---

## 5. Issues Identified

1. **System cron path mismatch** — crontab uses `/home/tokisaki/work/synthesis/cron/` but scripts are in the git repo. No execution → `daily_sync.sh`, `weekly_digest.sh`, `monthly_clean.sh` never run.
2. **Missing `hermes-brain-digest` tool** — `weekly_digest.sh` and `daily_sync.sh` call `hermes-brain-digest` which does not exist. Fallback creates empty placeholder reports.
3. **Z.AI quota exhaustion** — Deep Research job (00:00) hit HTTP 429 on 2026-04-26. No pre-check via `zai_quota.py` before launching expensive research.
4. **Self-Update job failing** — 07:00 job produces empty response (model error/timeout/misconfiguration).
5. **Disconnected pipelines** — The `hermes-second-brain` wiki compilation (`hermes-brain-compile`) operates independently of agent nightly research, creating two silos of knowledge.

---

## 6. Proposed Integration: Daily Compile + Weekly Digest into Agent Nightly Loop

### Philosophy

Consolidate all automation under the **Hermes Agent scheduler** (single source of truth). Decommission broken system cron entries for these two functions and replace them with agent-driven jobs.

### Integration Plan

#### A. Daily Compile Job (new agent job)

- **Schedule:** Daily at 06:30 (after Repo Update at 06:00, before Disk Cleanup at 06:30 and Self-Update at 07:00)
- **Purpose:** Process `raw/articles/` → `wiki/` via `hermes-brain-compile`, rebuild knowledge graph (`tools/build_edges.py`), generate daily report, post to Telegram.
- **Prompt outline:**
  > You are Toki. Run the daily Second Brain compilation pipeline.
  >
  > 1. Run `hermes-brain-compile --incremental` (binaries are in `~/github/hermes-second-brain/bin/` and are on PATH). Capture stdout/stderr.
  > 2. If compile succeeded, run `python3 ~/github/hermes-second-brain/tools/build_edges.py --input wiki/ --output memory/graph/`.
  > 3. Run `hermes-brain-lint --fast` to catch issues; record report to `reports/lint_YYYY-MM-DD.json`.
  > 4. If `hermes-brain-digest` exists, run `hermes-brain-digest --daily --output reports/digest_YYYY-MM-DD.md`; else create a minimal summary with compile stats.
  > 5. If `~/.hermes/telegram_config.py` is configured, post a short status message to Telegram (e.g., "✅ Daily compile: X new, Y skipped. Graph updated.").
  > 6. Write one line to `wiki/log.md`: `YYYY-MM-DD HH:MM | DAILY_COMPILE | compiled=X, skipped=Y`.
  > Return a concise status summary (or `[SILENT]` if nothing changed).
- **Deliver:** local (no Telegram unless configured; keep separate from Morning Summary)

#### B. Weekly Digest Job (new agent job, or enhance existing Morning Summary on Sundays)

Option 1 (separate job):
- **Schedule:** Sundays at 07:30 (after Self-Update at 07:00)
- **Purpose:** Full weekly health check + insights digest
- **Prompt:**
  > Run weekly maintenance:
  > 1. `hermes-brain-lint --full --semantic --output reports/lint_week_YYYY-MM-DD.md`
  > 2. If `hermes-brain-digest` exists, run `hermes-brain-digest --weekly --lint-report reports/lint_*.json --output reports/weekly_insights_YYYY-MM-DD.md`; else create summary from recent compile stats.
  > 3. Post rich message to Telegram: "📊 Weekly Insights — w##: X new pages, Y warnings, Z graph updates."
  > 4. Append to `wiki/log.md`: `YYYY-MM-DD | WEEKLY_DIGEST | lint=OK, posted=telegram`
- **Deliver:** origin (Telegram)

Option 2 (bake into Morning Summary on Sundays): Enhance `c780648cc5b2` prompt to include weekly lint/digest when `date +%u = 7` (Sunday). But that would change existing behavior; separate job is cleaner.

#### C. Create `hermes-brain-digest` Tool (prerequisite)

The shell scripts expect `hermes-brain-digest` but it doesn't exist. Implement a lightweight Python tool that reads the Second Brain (wiki, graph, reports) and produces human-readable summaries:

```python
#!/usr/bin/env python3
# ~/github/hermes-second-brain/bin/hermes-brain-digest
# Generates daily or weekly digest from compiled knowledge.
# --daily: summary of today's new/changed wiki pages, top graph edges, recent topics
# --weekly: aggregate stats, trending entities, knowledge gaps (orphaned pages), top contributors
# --lint-report <file>: incorporate lint warnings
# --output <file>: write markdown report
```

Initial version can be simple: parse `reports/compile_*.json`, `reports/lint_*.json`, `wiki/log.md` and produce a markdown summary. Full implementation can be iterative.

**Recommendation:** Implement v1 immediately (1–2 hours) to unblock weekly digest; enhance later.

---

### Alternative: Fix System Cron Instead?

We could fix the crontab to point to the correct script location:

```
15 * * * * /home/tokisaki/github/hermes-second-brain/cron/health_check.sh >> /var/log/hermes/health.log 2>&1
0 3 * * * /home/tokisaki/github/hermes-second-brain/cron/daily_sync.sh >> /var/log/hermes/daily_sync.log 2>&1
0 6 * * 0 /home/tokisaki/github/hermes-second-brain/cron/weekly_digest.sh >> /var/log/hermes/weekly_digest.log 2>&1
0 2 1 * * /home/tokisaki/github/hermes-second-brain/cron/monthly_clean.sh >> /var/log/hermes/monthly_clean.log 2>&1
```

However, this still leaves the missing `hermes-brain-digest` problem and creates **two separate automation systems** that may conflict (e.g., both agent and system cron trying to compile/wiki). The agent's scheduler is more robust (LLM-driven error handling, delivery via Telegram, centralized job management). Therefore, **migrating into the agent's loop is the recommended path**.

---

## 7. Implementation Steps

1. **Create `hermes-brain-digest`** in `~/github/hermes-second-brain/bin/`:
   - Start with a script that reads `reports/compile_*.json` and `wiki/log.md` to produce a daily markdown digest.
   - Add `--weekly` mode that aggregates last 7 days of logs, lint warnings, and newly created wiki pages.
   - Make it executable, add to venv PATH if needed.
   - Test manually: `hermes-brain-digest --daily --output reports/digest_test.md`

2. **Update `daily_sync.sh` to use working digest** (optional if we keep it for manual use):
   - The script already calls `hermes-brain-digest`; once tool exists, the fallback path won't trigger.

3. **Add Daily Compile job to `~/.hermes/cron/jobs.json`**:
   ```json
   {
     "id": "compile-<uuid>",
     "name": "Daily Wiki Compile",
     "prompt": "... (see section 6A above) ...",
     "schedule": { "kind": "cron", "expr": "30 6 * * *" },
     "enabled": true,
     "state": "scheduled",
     "deliver": "local"
   }
   ```
   Place after "Repo Update & Consolidation" (06:00) → run at 06:30.

4. **Add Weekly Digest job to `~/.hermes/cron/jobs.json`**:
   ```json
   {
     "id": "digest-<uuid>",
     "name": "Weekly Insight Digest",
     "prompt": "... (see section 6B above) ...",
     "schedule": { "kind": "cron", "expr": "30 7 * * 0" },
     "enabled": true,
     "state": "scheduled",
     "deliver": "origin"
   }
   ```

5. **Fix System Crontab (optional but recommended to avoid confusion)**:
   - Comment out or remove the 4 broken system cron entries (point to non-existent paths) to prevent confusion and failed execution attempts.
   - Command: `crontab -e` and either delete lines or prefix with `# DISABLED: paths broken 2026-04-26`.

6. **Update Documentation** (this report):
   - Save as `/home/tokisaki/github/hermes-second-brain/docs/nightly_loop_integration.md`
   - Link from README.md

7. **Test**:
   - Wait for next scheduled run or temporarily trigger jobs via agent CLI (`hermes job trigger <id>` if supported).
   - Verify outputs appear in `reports/` and Telegram (if configured).
   - Check `wiki/log.md` for new entries.

---

## 8. Recommendations & Next Steps

### Immediate
- [ ] Implement `hermes-brain-digest` (v1 simple) — unblocks weekly digest
- [ ] Add Daily Compile and Weekly Digest jobs to `jobs.json`
- [ ] Comment out broken system cron entries (avoid wasted slots / confusion)
- [ ] Add pre-run Z.AI quota check to expensive jobs (Deep Research, News Scrape) to avoid 429 errors:
  - Modify job prompts to run `python3 ~/.hermes/scripts/zai_quota.py --percent` and if >80%, respond `[SILENT]` with reason "Quota near limit"

### Short-term
- [ ] Consider consolidating `Repo Update` and `Daily Compile` — maybe compile after research outputs are pushed? Currently order: Repo Update (06:00) → Daily Compile (06:30) → knowledge graph updated. But the compile operates on `raw/articles/` which is unrelated to nightly research. If you want nightly research content in the Second Brain, extend Daily Compile to also ingest `~/.hermes/night-research/` key files into `raw/articles/` or directly into wiki.
- [ ] Fix `hermes-self-update` job — investigate why it returns empty (model error, timeout).
- [ ] Rotate `last-topics.txt` and prune old entries (monthly) to avoid indefinite growth.

### Long-term
- [ ] Migrate all maintenance tasks (health_check, monthly_clean) into agent scheduler for uniformity.
- [ ] Build alerting on Z.AI quota threshold (Telegram notification when session >70%).
- [ ] Create dashboard view: `hermes-brain-status` that aggregates last run times, next runs, and health of all jobs.

---

## Appendix: Full Cron Reference

### System Cron (Broken)
| Schedule | Script | Intended Function |
|----------|--------|-------------------|
| `15 * * * *` | `health_check.sh` | Fast lint + broken symlink scan |
| `0 3 * * *` | `daily_sync.sh` | Compile wiki, graph update, daily digest, email/Telegram |
| `0 6 * * 0` | `weekly_digest.sh` | Full lint + weekly insights + notifications |
| `0 2 1 * *` | `monthly_clean.sh` | Deep lint, orphan archiving, log rotation, DB VACUUM |

### Hermes Agent Scheduler (Active)
| Cron | Job ID | Name |
|------|--------|------|
| `0 0 * * *` | ae30be4c47ab | Deep Tech Research |
| `30 1 * * *` | f81ecfb9c2b0 | Daydreaming Session |
| `0 3 * * *` | 59cf35e5c622 | Self-Architecture Research |
| `30 4 * * *` | dc6da511dd91 | Global News Scrape |
| `0 6 * * *` | 2cb5ab614036 | Repo Update & Consolidation |
| `0 8 * * *` | c780648cc5b2 | Morning Summary |
| `0 7 * * *` | 19899937be9d | Hermes Self-Update |
| `0 22 * * *` | 4ffb553be43f | Repo Update Reminder |
| `30 6 * * *` | 97ecbd9da843 | Disk Cleanup |
| `45 3 * * *` | d8a2605ee2a1 | Daily Malware Scan |
| `20 6 * * *` | 56fb1ee99d48 | Cognee Sync |
| `0 0 * * *` | a9eb14d0a9eb | TMP Snapshot Push |
| `20 0 * * *` | b4e69023a8af | TMP Safe Cleanup |
| `0 10 * * 1` | 1ffcb3e7017d | German Course Monitor (Mondays) |

---

**Report generated by:** Hermes Agent inspection  
**Saved to:** `/home/tokisaki/github/hermes-second-brain/docs/nightly_loop_integration.md`
