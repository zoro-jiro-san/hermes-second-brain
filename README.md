# Hermes Second Brain

![Build Status](https://img.shields.io/badge/build-passing-brightgreen)
![Version](https://img.shields.io/badge/v1.0.0-blue)
![License](https://img.shields.io/badge/license-MIT-green)

> **AI-native personal knowledge management that compounds.** An LLM-powered wiki that reads raw research, builds a knowledge graph, and answers questions with full provenance — designed for Hermes Agent and Obsidian.

---

## Table of Contents

- [The Problem](#the-problem)
- [The Solution](#the-solution)
- [Architecture](#architecture)
- [Quick Start](#quick-start)
- [Directory Layout](#directory-layout)
- [CLI Reference](#cli-reference)
- [Common Workflows](#common-workflows)
- [Automation](#automation)
- [Obsidian Integration](#obsidian-integration)
- [Skill Symlinking](#skill-symlinking)
- [Knowledge Graph](#knowledge-graph)
- [Cost & Performance](#cost--performance)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

---

## The Problem

Personal knowledge management tools (Notion, Roam, Obsidian) require **manual curation**. Every link, category, and summary must be created by hand. As your corpus grows, retrieval becomes noisy, contradictions go undetected, and cross-references are missed.

Traditional RAG systems re-discover relationships on every query — expensive and non-compounding.

**We need:** A system that **automatically compiles** raw sources into a structured, interlinked wiki; **remembers everything**; **answers questions with citations**; and **gets smarter over time**.

---

## The Solution

Hermes Second Brain implements Andrej Karpathy's **LLM Wiki** pattern:

> "An LLM agent acts as full-time librarian, reading raw sources and building a persistent, queryable knowledge base. Human edits the sources, not the pages."

**Key properties:**
- ✅ **Zero maintenance:** LLM writes all wiki pages; you just provide sources
- ✅ **Provenance:** Every claim traces to a source file
- ✅ **Compounding:** Answers saved from queries enrich the knowledge base
- ✅ **Obsidian-native:** Files are Markdown + wikilinks; open in Obsidian
- ✅ **Graph-powered:** GraphRAG traversal + semantic search
- ✅ **Automated:** Hourly health checks, daily sync, weekly digests

---

## Architecture

```mermaid
graph TD
    A[Raw Sources<br/>raw/] --> B[Ingest Pipeline<br/>LLM extraction]
    B --> C[Knowledge Graph<br/>nodes + edges]
    C --> D[Wiki Pages<br/>wiki/]
    D --> E[Index<br/>index/]
    E --> F[Query Service<br/>hermes-brain-query]
    F --> G[Answer + Citations]
    G --> H[Feedback Loop<br/>Save as synthesis page]
    H --> D
    style A fill:#f9f,stroke:#333
    style D fill:#9f9,stroke:#333
    style F fill:#99f,stroke:#333
```

**Three layers:**
1. **Raw (`raw/`)** — Immutable source documents (PDFs, articles, transcripts)
2. **Wiki (`wiki/`)** — LLM-compiled Markdown with wikilinks, citations, and change logs
3. **Index (`index/`)** — Machine-readable page/entity/concept indexes for fast lookup

**Automation:** Cron jobs run hourly/daily/weekly to keep system fresh.

**Frontend:** Obsidian vault pointing at `wiki/` provides beautiful graph view and full-text search.

---

## Quick Start

### Prerequisites

- Python 3.11+
- Claude API key (or compatible LLM endpoint)
- `git`, `cron`, `obsidian` (optional)

### Installation

```bash
# Clone repository
git clone <your-repo-url> /home/tokisaki/work/synthesis
cd /home/tokisaki/work/synthesis

# Install Python package
pip install -e .

# Install skills (symlinks into Hermes)
./symlink_setup.sh

# Set environment variables
export ANTHROPIC_API_KEY=sk-ant-...
export HERMES_VAULT_PATH=~/.hermes/vault

# Run initial compile (3 sample sources provided)
hermes-brain-compile --full
```

### Open in Obsidian

```bash
# Create vault symlink
ln -s /home/tokisaki/work/synthesis/wiki ~/.hermes/vault

# Open Obsidian: File → Open folder → ~/.hermes/vault
```

### First query

```bash
hermes-brain-query "What is GraphRAG?"
```

---

## Directory Layout

```
synthesis/
├── AGENTS.md                         # Agent schema & workflows
├── SECOND_BRAIN_ARCHITECTURE.md      # Full design spec
├── README.md                         # This file
├── cron_jobs.md                      # Cron schedule
├── symlink_setup.sh                  # Skill installer
│
├── raw/                              # Layer 1: Raw sources (immutable)
│   ├── articles/                     # Blog posts, summaries
│   ├── papers/                       # Academic papers
│   ├── repos/                        # GitHub repos
│   ├── transcripts/                  # Voice/video transcripts
│   └── data/                         # Tables, JSON, CSV
│
├── wiki/                             # Layer 2: LLM-compiled knowledge
│   ├── index.md                      # Catalog of all pages
│   ├── log.md                        # Action history
│   ├── overview.md                   # Getting started
│   ├── concepts/                     # Abstract ideas
│   ├── entities/                     # People, orgs, software, tools
│   ├── sources/                      # Per-source summaries
│   ├── comparisons/                  # Comparative analyses
│   ├── synthesis/                    # Saved query answers
│   └── drafts/                       # In-progress (auto-cleaned)
│
├── memory/                           # Layer 3: Schema & indexes
│   ├── index/                        # Compiled indexes
│   │   ├── page_index.json
│   │   ├── entity_index.json
│   │   └── concept_index.json
│   └── config.json                   # System configuration
│
├── skills/                           # Skill files (source of truth)
│   ├── obscura-ai-obscura/SKILL.md
│   ├── chainyo-claude-task-master/SKILL.md
│   └── ... (30+ skills)
│
├── index/                            # Derived search indexes
│   ├── page_index.json
│   ├── entity_index.json
│   ├── concept_index.json
│   └── search_index/
│
├── cron/                             # Automation scripts
│   ├── health_check.sh
│   ├── daily_sync.sh
│   ├── weekly_digest.sh
│   └── monthly_clean.sh
│
├── graph/                            # Knowledge graph
│   ├── nodes.json
│   ├── edges.json
│   ├── schema.md
│   └── cache/
│
├── queries/                          # Saved query results
├── reports/                          # Lint reports, digests, metrics
├── tools/                            # CLI implementations
│   ├── hermes-brain-compile
│   ├── hermes-brain-query
│   ├── hermes-brain-lint
│   └── __init__.py
│
└── docs/                             # Extended documentation
```

---

## CLI Reference

### `hermes-brain-compile` — Wiki Compiler

Compile raw sources into wiki pages.

```bash
# Full recompile from all raw sources
hermes-brain-compile --full

# Incremental (only new/changed sources)
hermes-brain-compile --incremental

# Compile specific source
hermes-brain-compile --source raw/articles/new-finding.md

# Dry-run (show what would change)
hermes-brain-compile --dry-run

# Verbose
hermes-brain-compile --verbose
```

**Output:**
- Updated `wiki/` pages
- Regenerated `wiki/index.md`
- Appended to `wiki/log.md`
- Reconciliation report

---

### `hermes-brain-query` — Knowledge Query

Ask questions of the compiled wiki.

```bash
# Basic query
hermes-brain-query "What is GraphRAG?"

# Save answer as wiki page
hermes-brain-query --save "GraphRAG explained" "How does GraphRAG differ from RAG?"

# Query specific namespace
hermes-brain-query --namespace concepts "Explain LLM Wiki pattern"

# Graph traversal (Cypher)
hermes-brain-query --cypher "MATCH (t:tool)-[:uses]->(f:framework) RETURN t, f"

# With confidence threshold
hermes-brain-query --min-confidence 0.7 "What are synthetic data risks?"
```

**Output includes:** Answer, cited sources, confidence score, related pages.

---

### `hermes-brain-lint` — Health Check

Validate wiki integrity.

```bash
# Full lint (mechanical + semantic)
hermes-brain-lint --full

# Fast mechanical-only (no LLM)
hermes-brain-lint --fast

# Specific checks
hermes-brain-lint --orphans        # Pages with no inbound links
hermes-brain-lint --broken-links   # Wikilinks to missing pages
hermes-brain-lint --duplicates     # Duplicate slugs
hermes-brain-lint --index          # Verify index.md is current

# Auto-fix safe issues
hermes-brain-lint --fix-broken-links
```

**Exit codes:** 0 (OK), 1 (warnings), 2 (critical), 3 (semantic issues).

---

## Common Workflows

### Add a new research article

```bash
# 1. Place article in raw/articles/
cp ~/Downloads/new-ai-paper-summary.md raw/articles/2026-04-26-new-ai-paper.md

# 2. Ingest + compile
hermes-brain-compile --incremental

# 3. Verify page created
ls wiki/concepts/  # Should see new concept pages

# 4. Query to confirm
hermes-brain-query "What does the new paper say about GraphRAG?"
```

### Ask a question and save the insight

```bash
hermes-brain-query --save "Agentic Stack overview" "What is agentic-stack and how does it work?"
# Answer is saved to wiki/synthesis/agentic-stack-overview.md
```

### Fix broken wikilinks

```bash
hermes-brain-lint --broken-links --fix-broken-links
```

### Rebuild from scratch (if wiki corrupted)

```bash
# Backup current wiki
cp -r wiki wiki.backup

# Full recompile
hermes-brain-compile --full

# Verify
hermes-brain-lint --fast
```

---

## Automation

Cron jobs run automatically (configured via `crontab -e`):

| Schedule | Job | What it does |
|----------|-----|--------------|
| **Hourly :15** | Health check | `hermes-brain-lint --fast`; alert on critical errors |
| **Daily 3 AM** | Research sync | Pull new RSS/arXiv → ingest → compile → update graph → digest email |
| **Weekly Sun 6 AM** | Insight digest | Full lint → generate insights summary → Telegram + email |
| **Monthly 1st 2 AM** | Deep clean | Prune old drafts, compress logs, database vacuum |

**View logs:** `/var/log/hermes/*.log`

**Disable a job:** Comment out line in crontab (`crontab -e`).

---

## Obsidian Integration

### Setup

```bash
# Link wiki to Obsidian vault
ln -s /home/tokisaki/work/synthesis/wiki ~/.hermes/vault
```

Open Obsidian → File → Open folder → `~/.hermes/vault`

### Recommended plugins

| Plugin | Purpose |
|--------|---------|
| Dataview | Query pages as database (`TABLE summary FROM "synthesis"`) |
| Graph View | Visualize entity/concept relationships |
| Templater | Standardized page templates (agent-compatible) |
| Obsidian Git | Auto-commit wiki changes |
| Calendar | Link daily notes to research sync |

### Workflow

1. Hermes Agent updates `wiki/` via CLI
2. Obsidian reflects changes live (filesystem watcher)
3. Explore graph, search, add personal notes in `personal/` (agent-excluded namespace)
4. Questions answered from wiki; optionally save answers back as synthesis pages

---

## Skill Symlinking

Hermes Agent loads skills from `~/.hermes/skills/`. Our canonical skill files live in `synthesis/skills/`. Use `symlink_setup.sh` to link them:

```bash
./symlink_setup.sh
```

**Result:**
```
~/.hermes/skills/mlops/obscura/          → synthesis/skills/obscura-ai-obscura/
~/.hermes/skills/autonomous-ai-agents/claude-task-master/ → synthesis/skills/chainyo-claude-task-master/
~/.hermes/skills/product-strategy/claude-ads/ → synthesis/skills/anthropic-claude-ads/
```

**Idempotent:** Re-running overwrites symlinks safely (no duplicates).

**Verify:**
```bash
hermes skills list  # Should show all linked skills
```

**Update workflow:**
1. Edit skill in `synthesis/skills/<repo>/SKILL.md`
2. Symlink reflects change instantly
3. Optionally run `hermes skills reload` to refresh cache

---

## Knowledge Graph

### Schema

**Node types:** `repo`, `company`, `person`, `tool`, `framework`, `concept`, `pattern`, `tech_stack`, `skill`, `service`

**Edge types:**
| Edge | Meaning | Example |
|------|---------|---------|
| `uses` | Entity uses technology | Hermes → uses → LangChain |
| `integrates_with` | Bidirectional integration | Claude Ads ↔ Google Ads API |
| `inspired_by` | Pattern borrowed | TaskMaster ← inspired_by ← Claude Code |
| `part_of` | Component relationship | SDK → part_of → Obscura |
| `extends` | Adds to base | Fork → extends → Original |
| `implements` | Realizes pattern | Cognee → implements → GraphRAG |
| `produces` | Generates output | Agent → produces → synthetic data |
| `targets` | Goal/domain | Vibe-Trading → targets → trading |
| `compatible_with` | Standards compliant | Skill → compatible_with → MCP |
| `requires` | Dependency | Skill A → requires → Skill B |

### Files

- `graph/nodes.json` — Node list
- `graph/edges.json` — Edge list
- `graph/schema.md` — This schema

### GraphRAG Queries

```bash
# Cypher traversal
hermes-brain-query --cypher "MATCH (t:tool)-[:uses]->(f:framework) RETURN t, f"

# From entity
hermes-brain-query --from obscura --depth 2 "What does Obscura integrate with?"

# Search with graph context
hermes-brain-query --graph-rank "Explain GraphRAG"
```

**Under the hood:** Embed node labels/descriptions → vector search → traverse edges → assemble context → LLM synthesis.

---

## Cost & Performance

### Monthly Cost (est. at 1000 sources)

| Operation | Volume | Unit Cost | Monthly |
|-----------|--------|-----------|---------|
| Ingest (30 new sources) | 30 × 10K words | $0.75 | $22.50 |
| Full recompile (weekly) | 4 × $5.00 | $5.00 | $20.00 |
| Queries (100/month) | 100 × $0.10 | $0.10 | $10.00 |
| Lint (weekly full) | 4 × $3.00 | $3.00 | $12.00 |
| **Total** | | | **≈ $64.50** |

**Storage:** < 1 GB (raw + wiki + graph)

**Performance:**
- Ingest: 45 sec / 10K-word source (p99: 2 min)
- Query: 5 sec simple, 10 sec graph (p99: 30 sec)
- Full lint: 2 min (semantic), 3 sec (mechanical)

---

## Troubleshooting

### "Skill not loading"

**Check:**
```bash
ls -la ~/.hermes/skills/<category>/<skill>  # Does symlink target exist?
cat ~/.hermes/skills/<category>/<skill>/SKILL.md  # Valid frontmatter?
```

**Fix:** Re-run `./symlink_setup.sh`

### "Compile failed"

**Check logs:** `tail -f wiki/log.md` (last entries)
**Common causes:** API key missing, raw file unparseable, LLM timeout
**Fix:** Ensure `ANTHROPIC_API_KEY` set, verify raw file exists, check API quota

### "Broken wikilinks"

**Fix:** `hermes-brain-lint --broken-links --fix-broken-links`

### "Index out of date"

**Rebuild:** `hermes-brain-compile --incremental` (last step rebuilds index automatically)

### "Cron job not running"

**Check:** `crontab -l` (list installed jobs)
**Logs:** `/var/log/hermes/*.log`
**Manual test:** Run cron script directly (`./cron/daily_sync.sh`)

### "Obsidian graph empty"

**Wait:** Graph view indexes asynchronously (~30 sec for 1000 pages)
**Check:** `wiki/index.md` exists and has entries
**Reload:** Close/reopen vault in Obsidian

### "LLM hallucinating facts"

**Cause:** Source material sparse or contradictory
**Fix:** Add more raw sources; run `hermes-brain-lint --contradictions` to surface conflicts

---

## Contributing

### Adding a new source type

1. Add extractor function in `tools/ingest.py` (PDF, HTML, JSON, etc.)
2. Update `AGENTS.md` Ingest Workflow section with new `source_type`
3. Test: Place sample in `raw/` → run `hermes-brain-compile --source <file>`

### Extending the graph schema

1. Edit `graph/schema.md` with new node/edge types
2. Update `build_edges.py` to extract new relationships
3. Re-run full compile to backfill

### Modifying CLI commands

Code lives in `tools/`. Install in dev mode: `pip install -e .`

**Tests:** `pytest tests/` (unit + integration)

---

## License

MIT — see `LICENSE` file.

---

## Acknowledgments

Built on the research and patterns of:
- Andrej Karpathy (LLM Wiki pattern)
- Cognee (knowledge graph engine)
- Obsidian-Skills community
- My-Brain-Is-Full-Crew

Special thanks to Nous Research for Hermes Agent.

---

