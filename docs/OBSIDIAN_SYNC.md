# Obsidian ↔ GitHub Real-Time Sync

## Architecture

This system provides **unidirectional, real-time synchronization** from a local Obsidian vault to a GitHub remote. GitHub is the source of truth; the vault is a live editing workspace.

```
┌─────────────────┐     inotify     ┌──────────────────┐   git push   ┌─────────────────┐
│  Obsidian Vault │ ──────────────▶ │  watch_and_push  │ ─────────▶ │   GitHub        │
│  (~/vaults/)    │   (file change) │     (daemon)     │  (on change) │   (hermes-      │
│                 │                 │                  │              │   second-brain) │
└─────────────────┘                 └──────────────────┘              └─────────────────┘
                                                                          │
                                                                          │ post-push hooks
                                                                          ▼
┌─────────────────┐    6-hour batch  ┌──────────────────┐   rebuild    ┌─────────────────┐
│   Cron Job      │ ◀─────────────── │   cron_push.sh   │ ◀────────── │  Index + Graph  │
│ (crontab -e)    │   (periodic)     │   (fallback)     │   hooks     │  memory/        │
└─────────────────┘                  └──────────────────┘              └─────────────────┘
```

### Components

| File | Purpose | Trigger |
|------|---------|---------|
| `sync/watch_and_push.sh` | Inotify loop: watches vault, auto-commits & pushes .md changes | Real-time (file system events) |
| `sync/cron_push.sh` | Batch push every 6 hours as fallback/consistency | Cron schedule |
| `sync/post_push.sh` | Rebuilds TF-IDF index, updates graph edges from wikilinks, runs lint | After each successful push |
| `sync/update_graph_from_wikilinks.py` | Extracts `[[wikilinks]]` from wiki pages → graph edges | Called by post_push.sh |
| `docs/OBSIDIAN_SYNC.md` | This document | — |

### Data Flow

1. **Edit** a note in Obsidian (vault path: `~/vaults/hermes-second-brain/`)
2. **Watch daemon** detects `.md` modification via `inotifywait`
3. **Debounce** (3 sec) to batch rapid edits
4. **Git operations**: `git add -A` → `git commit` → `git push`
5. **Post-push hooks**:
   - Rebuild TF-IDF index (`index/embeddings/build_index.py`)
   - Update knowledge graph edges from wikilinks (creates `links_to` edges between wiki pages)
   - Run fast lint (`bin/hermes-brain-lint --fast`)
6. **GitHub remote** now has up-to-date content; indexes reflect latest structure

### Graph Edge Update Logic

The `update_graph_from_wikilinks.py` script:

- Reads all `wiki/*.md` files
- Extracts `[[Page Name]]` wikilinks
- Creates nodes of type `page` for each wiki page (if not already present)
- Creates edges of type `links_to` linking source → target page
- Confidence: `0.9` (explicit author link)
- Merges with existing research-derived graph in `memory/` without overwriting

This enables:
- Obsidian Graph View with up-to-date connections
- Cross-page backlink tracking
- Relationship queries via `hermes-brain-query --cypher`

### Index Rebuild

TF-IDF index (`index/embeddings/index.json`) is rebuilt on every push. This lightweight BM25-like index powers fast lexical search and is used by `hermes-brain-query`.

---

## Setup

### Prerequisites

```bash
# Install inotify-tools (for watch_and_push.sh)
sudo apt-get install inotify-tools   # Debian/Ubuntu
# or: brew install inotify-tools     # macOS (with brew)

# Ensure git user is configured
git config --global user.name "Your Name"
git config --global user.email "you@example.com"

# SSH key for GitHub (if using SSH)
ssh-add -l  # Should list your key
```

### Directory Structure Assumptions

```
~/vaults/hermes-second-brain/   # Local Obsidian vault (editable)
├── Home.md                      # (symlinked to ../github/hermes-second-brain/wiki/Home.md)
├── SomeNote.md                  # (symlinked or local)
├── memory/                      # (local cache, ignored by git)
└── .obsidian/                   # Obsidian config (not synced)

~/github/hermes-second-brain/    # GitHub repo (source of truth)
├── wiki/                        # Obsidian-facing Markdown files
├── sync/                        # ← Created by this setup
│   ├── watch_and_push.sh
│   ├── cron_push.sh
│   ├── post_push.sh
│   └── update_graph_from_wikilinks.py
├── index/embeddings/            # TF-IDF search index (auto-generated)
├── memory/                      # Graph nodes + edges (auto-updated)
├── bin/                         # CLI tools (already present)
└── docs/                        # Documentation
```

**Important:** The vault uses symlinks pointing to `../github/hermes-second-brain/wiki/`. This means edits in Obsidian write directly to the GitHub repo. The sync scripts operate on the repo, not the symlinks.

### Installation

1. **Clone or verify the repo exists**

```bash
cd /home/tokisaki/github
git clone git@github.com:YOUR_USER/hermes-second-brain.git  # if not already cloned
```

2. **Verify vault symlinks**

Your vault should already have symlinks to the `wiki/` directory. If not:

```bash
cd ~/vaults/hermes-second-brain
ln -s /home/tokisaki/github/hermes-second-brain/wiki/*.md .
```

3. **Create sync scripts** (if not already present)

The scripts are provided in this repo under `sync/`. Ensure they are executable:

```bash
cd /home/tokisaki/github/hermes-second-brain
chmod +x sync/*.sh sync/*.py
```

4. **Test the watch script manually**

```bash
# Terminal 1: start the watcher
./sync/watch_and_push.sh --verbose

# Terminal 2: create a test note
echo "# Test Note" > ~/vaults/hermes-second-brain/test-sync.md
# Or edit via Obsidian

# Watch output should show:
#   Detected changes: /home/.../test-sync.md
#   Committed: ...
#   Pushed to GitHub
#   Running post-push hooks...
#   [Hook 1] ✓ TF-IDF index rebuilt successfully
#   ...
```

5. **Install the cron job (6-hour batch fallback)**

```bash
crontab -e
```

Add the line:

```
0 */6 * * * /home/tokisaki/github/hermes-second-brain/sync/cron_push.sh --quiet >> /home/tokisaki/github/hermes-second-brain/logs/cron_push_$(date +\%Y\%m\%d).log 2>&1
```

This runs at 00:00, 06:00, 12:00, 18:00 daily.

6. **(Optional) Systemd service for persistent watcher**

Create `~/.config/systemd/user/hermes-sync.service`:

```ini
[Unit]
Description=Hermes Obsidian→GitHub Sync Watcher
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/home/tokisaki/github/hermes-second-brain/sync/watch_and_push.sh --quiet
Restart=on-failure
RestartSec=10
WorkingDirectory=/home/tokisaki/github/hermes-second-brain

[Install]
WantedBy=default.target
```

Enable and start:

```bash
systemctl --user daemon-reload
systemctl --user enable --now hermes-sync.service
systemctl --user status hermes-sync
```

### Environment Variables

You can override defaults:

| Variable | Default | Meaning |
|----------|---------|---------|
| `VAULT_PATH` | `/home/tokisaki/vaults/hermes-second-brain` | Obsidian vault root |
| `REPO_PATH` | `/home/tokisaki/github/hermes-second-brain` | Git repo working directory |
| `DEBOUNCE_SEC` | `3` | Wait time after last change before committing |

Example:

```bash
export VAULT_PATH=~/my-vault
export REPO_PATH=~/my-repo
./sync/watch_and_push.sh --verbose
```

### Dry-Run Testing

Both scripts support `--dry-run`:

```bash
# Watch: show actions without committing/pushing
./sync/watch_and_push.sh --verbose --dry-run

# Cron: preview what would be committed
./sync/cron_push.sh --dry-run
```

---

## Operations

### Starting the Watcher

```bash
# Foreground (development / debugging)
./sync/watch_and_push.sh --verbose

# Background (manual)
nohup ./sync/watch_and_push.sh --quiet > /dev/null 2>&1 &

# Systemd (persistent across reboots)
systemctl --user start hermes-sync
```

### Manual Trigger

Run the full pipeline (commit + push + hooks) manually:

```bash
cd /home/tokisaki/github/hermes-second-brain
git add -A
git commit -m "Manual sync: $(date)"
git push
./sync/post_push.sh
```

### Monitoring

**Watcher logs**: stdout/stderr or systemd journal:

```bash
# If running via systemd
journalctl --user -u hermes-sync -f
```

**Cron logs**: Redirected to `logs/cron_push_YYYYMMDD.log`

**Git push failures**: The watcher logs errors and will retry on next file change.

**Index/Graph status**:

```bash
# Check index size
ls -lh index/embeddings/index.json

# Check graph node/edge counts
python3 -c "import json; d=json.load(open('memory/graph.nodes.json')); print('Nodes:', len(d))"
python3 -c "import json; d=json.load(open('memory/graph.edges.json')); print('Edges:', len(d))"
```

### Conflict Handling

Since sync is push-only (local → GitHub), conflicts can only occur if:
- Multiple machines edit the same vault simultaneously
- Manual edits are made directly in the repo while watcher runs

**Resolution**:
1. The `git push` will fail with non-fast-forward error
2. Watcher logs the error and continues watching
3. Manual intervention required:
   ```bash
   cd /home/tokisaki/github/hermes-second-brain
   git fetch origin
   git merge origin/main   # resolve conflicts
   # or: git reset --hard origin/main  # discard local
   git push
   ```
4. Restart watcher if needed

**Best practice**: Use a single source for Obsidian edits (one machine). If multi-device needed, consider `git pull` before edit or use Obsidian's built-in Git plugin with bidirectional sync (out of scope here).

### Stopping the Watcher

```bash
# If foreground: Ctrl+C
# If background: kill PID
pkill -f "watch_and_push.sh"

# If systemd:
systemctl --user stop hermes-sync
```

---

## Troubleshooting

### "inotifywait: failed to watch: No space left on device"

**Cause**: System inotify watch limit reached.

**Fix**:
```bash
# Check current limit
cat /proc/sys/fs/inotify/max_user_watches

# Increase (temporary)
sudo sysctl fs.inotify.max_user_watches=524288

# Permanent: add to /etc/sysctl.conf or ~/.sysctl.conf
fs.inotify.max_user_watches=524288
```

### "git push failed — will retry on next change"

Common causes:
- Remote has new commits (need manual merge)
- Network down
- Authentication expired

**Fix**: Run a manual `git push` to see the actual error message.

### Index rebuild slow

Large vaults (1000+ pages) may take a few seconds. The watcher waits for completion. If it's too slow:
- Consider incremental indexing (future enhancement)
- Or run index rebuild asynchronously in post_push.sh (background)

### Graph edges not updating

1. Check wikilink syntax: must be `[[Page Name]]` (double brackets)
2. Verify `update_graph_from_wikilinks.py` is executable
3. Run manually:
   ```bash
   python3 sync/update_graph_from_wikilinks.py
   ```
4. Inspect `memory/graph.edges.json` for new `links_to` edges

### Lint reports broken links but graph doesn't reflect

`hermes-brain-lint` checks for missing target files. The graph builder only creates edges if the target file exists. If a link is broken, it won't appear in the graph — that's expected.

Fix broken links via:

```bash
./bin/hermes-brain-lint --broken-links --fix-broken-links
```

### Cron job not running

1. Verify crontab entry: `crontab -l`
2. Check cron daemon: `systemctl status cron` (Ubuntu) or `crond`
3. Ensure script is executable: `chmod +x sync/cron_push.sh`
4. Test manually: `./sync/cron_push.sh --verbose`

---

## Extending the System

### Adding More Post-Push Hooks

Edit `sync/post_push.sh` and add new sections. Example: send a Telegram notification on success.

### Bidirectional Sync

Currently L→R only. To pull from GitHub:

1. Add a `git pull` step before committing in `watch_and_push.sh`
2. Handle merge conflicts (typically automatic for independent pages)
3. Beware of race conditions if Obsidian auto-saves while pulling

Not recommended without robust merge strategy.

### Custom Indexing Strategies

Replace `index/embeddings/build_index.py` with a more sophisticated ranker (e.g., BM25 with okapi, or embedding-based). Ensure output format stays compatible.

---

## Files Created/Modified

```
hermes-second-brain/
├── sync/
│   ├── watch_and_push.sh          # New — inotify watcher + git push loop
│   ├── cron_push.sh               # New — 6-hour batch push
│   ├── post_push.sh               # New — orchestrates hooks after push
│   └── update_graph_from_wikilinks.py  # New — wikilink → graph edges
├── docs/
│   └── OBSIDIAN_SYNC.md           # New — this document
└── README.md                      # Updated — added "Obsidian Sync Workflow" section
```

---

## Summary

This system gives you **live, automatic Git persistence** for your Obsidian vault with zero manual steps. Edges and search indexes stay current without intervention, making the Second Brain a truly autonomous knowledge system.
