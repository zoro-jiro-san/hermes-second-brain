---
name: low-resource-optimization
description: >-
  Systematic optimization for AI agents on constrained hosts (≤32GB disk,
  limited RAM). Three-layer defense: system caps, agent automation, application
  logic. Includes tmpfs/journald/Docker limits, cache LRU, research age-based
  rotation.
triggers:
  - disk space low
  - OOM prevention
  - constrained host maintenance
  - storage hygiene automation
prerequisites:
  - Linux systemd host
  - bash, python3, sqlite3
  - sudo access (system layer)
  - Hermes Agent installed (optional: agent-side scripts work standalone)
steps:
  - Deploy ~/.hermes/scripts/prune-night-research.sh (age-based: keep 7d verbatim, compress 7–30d .md → .gz, purge >30d)
  - Deploy ~/.hermes/lib/cache_manager.py (size-bounded LRU, default 100 MB hard cap)
  - Enhance ~/.hermes/scripts/disk-cleanup.sh to invoke prune + cache LRU + session archive before final cleanup
  - Mirror scripts to hermes-agent-architecture/scripts/ for versioning (one commit per file per user preference)
  - Apply sys-level configs via sysops/install-lowres-optimizations.sh:
    - tmpfs /tmp cap at 10% RAM (systemd mount override)
    - journald limits: RuntimeMaxUse=100M, SystemMaxUse=200M, retention 7d
    - Docker log rotation: max-size 10m, max-file 3 (if Docker installed)
    - Weekly system cleanup (APT, thumbnails, lxsession logs, old /tmp)
    - tmpfiles.d aging rules for /run/hermes
  - Verify Disk Cleanup cron job (06:30, ID 97ecbd9da843) picks up enhanced script automatically
  - Set config.yaml compression.threshold=0.7 (protect_last_n=20) for token budget management
pitfalls:
  - /tmp cleanup: skip systemd-private-* dirs (PermissionError); use `find /tmp -mindepth 1 -maxdepth 1 -mtime +1` not recursive delete
  - journald SystemMaxUse only when Storage=persistent; for volatile (default) set RuntimeMaxUse; verify `grep '^Storage' /etc/systemd/journald.conf`
  - Docker log rotation applies only to new containers; recreate existing to pick up daemon.json changes
  - Cache LRU must run after cache writes; hook into nightly Disk Cleanup (06:30), not earlier cron to avoid races
  - Tmpfs override requires `systemctl daemon-reload && systemctl restart tmp.mount`; verify `findmnt /tmp` shows size=10%
  - Agent scripts must be executable (chmod +x); agent job runs as user, not root
  - Commit scripts individually (one file per commit) to maintain clean history per user preference
  - hermes-brain-digest missing from Second Brain bin/ — weekly digest falls back to minimal summary until implemented
verification:
  - System: `findmnt /tmp` → size 10% RAM; `sudo journalctl --disk-usage` → <200 MB; `docker system df` (if used) → logs bounded
  - Agent: `cat ~/.hermes/cron/output/disk-cleanup-*.log` → reports removed/compressed/deleted counts; `du -sh ~/.hermes/cache` → ≤100 MB after run
  - Research rotation: `ls -lt ~/.hermes/night-research` → last 7d .md present, 7–30d .gz files exist, >30d absent
  - Config: `grep threshold ~/.hermes/config.yaml` → threshold ≥0.7 for constrained hosts
resources:
  - daily-learnings/2026-04-26-low-resource-optimization-guide.md
  - daily-learnings/2026-04-26-implementation-tracker.md
  - hermes-agent-architecture/scripts/{disk-cleanup.sh,prune-night-research.sh,cache_manager.py}
  - daily-learnings/sysops/install-lowres-optimizations.sh
---
  - hermes-agent-architecture/scripts/disk-monitor.sh
  - hermes-agent-architecture/scripts/disk_cleanup_wrapper.py
