# Hermes Second Brain Architecture

**Design Document: LLM-Compiled Wiki Knowledge System**

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Pattern Research Summary](#pattern-research-summary)
3. [Architecture Overview](#architecture-overview)
4. [Three-Layer Architecture](#three-layer-architecture)
5. [Core Operations](#core-operations)
6. [CLI Tool Specification](#cli-tool-specification)
7. [Health Checks & Linting](#health-checks--linting)
8. [Obsidian Integration Strategy](#obsidian-integration-strategy)
9. [Scheduling & Automation](#scheduling--automation)
10. [Feedback Loops](#feedback-loops)
11. [Implementation Roadmap](#implementation-roadmap)

---

## Executive Summary

Hermes Second Brain is an AI-native personal knowledge management system that implements Andrej Karpathy's "LLM Wiki" pattern. The system treats raw sources as immutable inputs and uses an LLM agent to continuously compile them into a structured, interlinked knowledge graph of markdown files. This architecture eliminates retrieval noise, ensures provenance tracking, and creates a compounding knowledge artifact where every query and exploration enriches the system.

**Key Innovations**
- LLM maintains the wiki entirely; humans curate sources and explore
- Knowledge compounds over time; answers filed back become part of the knowledge base
- Automated health checks prevent degradation and identify gaps
- Multi-modal support (text, PDF, images, audio) via Cognee knowledge engine
- GraphRAG integration for advanced retrieval scaling

---

## Pattern Research Summary

### 1. LLM-Compiled Wiki Pattern (Karpathy 2026)

Andrej Karpathy's viral pattern proposes an architecture where an LLM agent acts as a full-time librarian, building and maintaining a persistent knowledge base over time:

**Core Tenets**
- Raw sources are immutable; LLM reads but never modifies them
- Wiki is LLM-owned: pages are created, updated, cross-linked by the agent
- Three operations: **ingest** (process new sources), **query** (ask questions), **lint** (health checks)
- Answers can be filed back into the wiki, creating compounding knowledge
- Works effectively at personal/team scale (50-400 sources, 100K-400K words)

**Why It Works**  
Retrieval-based systems (RAG) re-discover relationships per query; the LLM Wiki compiles relationships once and reuses them. Cross-references and contradictions are already resolved. Query latency drops dramatically. The artifact is human-readable and persists independently of any specific LLM session.

### 2. Cognee Knowledge Engine

Cognee is an open-source knowledge engine (16K+ stars) that specializes in building persistent memory for AI agents using knowledge graphs and GraphRAG.

**Key Features**
- **Ingest** → **Cognify** → **Memify** pipeline
- Unified ingestion from any format (text, PDFs, APIs, images)
- Graph database abstraction (Neo4j, networkx, LanceDB)
- Multiple search modalities: GRAPH_COMPLETION, RAG_COMPLETION, CHUNKS, SUMMARIES, CYPHER
- Temporal awareness for understanding evolution over time
- Continual learning from feedback and cross-agent knowledge sharing

**Architecture**  
`cognee.add()` ingests raw data → `cognee.cognify()` structures it into a knowledge graph using LLM → `cognee.memify()` infers implicit connections and rules → `cognee.search()` queries the graph with natural language or Cypher. All operations can be run via CLI (`cognee-cli`) or Python SDK.

**GraphRAG vs RAG**  
Cognee demonstrates that knowledge graphs combine vector similarity with graph traversal, providing more comprehensive results by understanding entity relationships and extracting deeper insights through structured reasoning paths.

### 3. Community Implementations

**My-Brain-Is-Full-Crew** (2.8K stars)  
A crew of 8+ AI agents specialized in Obsidian vault management, medical/nutrition tracking, and mental wellness. Features:
- Chat-based interface; no manual Obsidian operations
- Multi-language support
- Agent dispatcher for coordinated workflows
- Customizable agents (users describe needs; system generates agent)

**Obsidian-Skills** (26K stars)  
A collection of agent skills for Claude Code/Codex that teach agents to manipulate Obsidian files: Markdown editing, Bases (table views), JSON Canvas diagrams, and Obsidian CLI operations.

**llm-wiki-compiler** implementations  
Multiple open-source compilers implement Karpathy's pattern with features:
- Incremental recompilation via hash-based change detection
- Two-phase pipeline: extract concepts → generate pages (eliminates order-dependence)
- `/wiki-ingest`, `/wiki-compile`, `/wiki-lint`, `/wiki-query` commands
- Coverage indicators (`[coverage: high/medium/low]`) per page section
- Automatic index and log updates

---

## Architecture Overview

Hermes Second Brain combines the best patterns from Karpathy's LLM Wiki, Cognee's knowledge graph capabilities, and proven community practices into a unified system for personal and team-scale knowledge management.

### System Context

```
User / Agent Platform
       ↓
   Hermes Second Brain
    /        |         \
Raw/      Wiki/       Outputs/
sources   markdown    queries/
  |          |          reports/
  |          |          visualizations/
  |          |
  └──→ Ingest Pipeline ─→ Query Service ─→ Feedback Loop
```

### Design Goals

1. **Zero maintenance burden** – LLM compiles & maintains all wiki content
2. **Auditability** – Every claim traces to a source file
3. **Scalability** – Handles 500-1000 sources, 1000-5000 wiki pages
4. **Integration** – Native Obsidian vault format with wikilinks
5. **Evolution** – Schema and workflows co-evolve with Claude
6. **Cost-efficiency** – Incremental compilation minimizes LLM calls

---

## Three-Layer Architecture

### Layer 1: Raw Sources (`raw/`)

**Purpose**  
Immutable, curated source documents. LLM reads these but never writes them.

**Structure**
```
raw/
├── articles/    # Web clippings, blog posts (MD)
├── papers/      # Academic papers (PDF → text extraction)
├── repos/       # GitHub repos (clone → README + tree)
├── transcripts/ # Voice/video transcripts (audio → whisper)
├── images/      # Diagrams, charts (with captions)
└── assets/      # Data files, tables, code snippets
```

**Naming Conventions**
- `YYYY-MM-DD-short-description.md` for summaries
- Keep original filename in frontmatter: `original: "ResearchPaper.pdf"`
- Hash-based deduplication: `sha256: abc123...`

**Source Processing**
1. Extract text from any format using universal adapters
2. Normalize to Markdown with frontmatter:
```yaml
---
title: "Original Document Title"
source_type: "paper|article|transcript|repo"
date_added: "2026-04-25"
original_url: "https://..."
sha256: "abc123..."
tags: ["topic1", "topic2"]
---
```
3. Store in appropriate `raw/` subfolder

### Layer 2: Compiled Wiki (`wiki/`)

**Purpose**  
LLM-generated, human-readable markdown knowledge base. Entirely maintained by AI.

**Structure**
```
wiki/
├── index.md              # Catalog of all pages (compact summary per page)
├── log.md                # Append-only chronological record of all actions
├── overview.md           # High-level topic overview
├── concepts/
│   └── key-concept.md    # One page per major idea, principle, or framework
├── entities/
│   ├── person/
│   │   └── andrej-karpathy.md
│   ├── organization/
│   │   └── openai.md
│   └── software/
│       └── claude.md
├── sources/
│   └── 2026-04-25-llm-wiki-pattern.md  # Per-source summaries
├── comparisons/
│   └── rag-vs-graphrag.md
├── synthesis/            # Research outputs filed from queries
│   └── 2026-04-25-market-analysis.md
└── drafts/               # In-progress pages (auto-cleaned monthly)
```

**Page Template**
```markdown
---
title: "Page Title"
slug: "page-title"          # Used for [[wikilinks]]
created: "2026-04-25T14:30:00"
last_modified: "2026-04-26T09:15:00"
version: 3
sources: ["raw/articles/...", "raw/papers/..."]
concepts: ["related-concept", "another-concept"]
entities: ["person/andrej-karpathy"]
classification: "concept|entity|comparison|synthesis|draft"
summary: "One-paragraph TL;DR for index.md"
---

# Page Title

## TL;DR
Brief standalone summary.

## Overview
Detailed explanation.

## Key Points
- Point 1 ^[source.md]
- Point 2 ^[raw/...]

## Related
- [[related-concept]]
- See also: [[another-entity]]

## Sources
- `[[raw/articles/xyz]]` → key takeaway
- `[[raw/papers/abc]]` → supporting evidence

## Open Questions
- [ ] Question 1
- [ ] Question 2

## Change Log
- v3 (2026-04-26): Updated with new source XYZ
- v2 (2026-04-24): Added contradiction flag re: ...
```

**Frontmatter Fields**

| Field | Purpose |
|-------|---------|
| `slug` | URL-friendly identifier; used in `[[wikilinks]]` |
| `version` | Incremented on each update; enables rollback |
| `sources` | Array of raw source paths; provenance tracking |
| `concepts` | Array of linked concept slugs (graph edges) |
| `entities` | Array of linked entity slugs |
| `classification` | Content type; filters index entries |
| `summary` | One-paragraph descriptor for `index.md` |
| `coverage` | `high`(5+ sources), `medium`(2-4), `low`(0-1) |

**Wikilink Syntax**  
Obsidian-compatible: `[[slug]]` or `[[slug|display text]]`  
Backlinks generated automatically by Obsidian from wikilinks.

### Layer 3: Schema & Configuration (`AGENTS.md`)

**Purpose**  
Defines how the agent operates, naming conventions, page templates, and operational workflows. Co-evolves with use.

**Location**  
Root of workspace: `AGENTS.md` (or `CLAUDE.md` for Claude Code)

**Structure**
```markdown
# Hermes Second Brain — Agent Schema

## Vault Purpose
This wiki covers Hermes Research, Flux development, AI systems engineering...

## Ingest Workflow
1. Read raw source file.
2. Identify entities, concepts, and key claims.
3. Create/update entity/concept pages with backlinks to source.
4. Write source summary page with extracted insights.
5. Flag contradictions with existing pages → append to LOG.md.
6. Update INDEX.md. Never skip this step.

## Page Standards
- Every concept gets its own page.
- Every entity (person, org, software) gets its own page.
- Every claim cites at least one raw source with `^[source.md]` inline marker.
- Every page has a 1–2 sentence summary paragraph.
- [[wikilinks]] connect concepts, entities, and cross-references.

## Query Workflow
1. Read index.md to identify relevant pages.
2. Read full text of each relevant page.
3. Synthesize answer citing specific query result files.
4. If answer adds new knowledge → offer to save as wiki page.

## Lint Workflow (run weekly)
- Check for orphan pages (no inbound wikilinks).
- Check for broken wikilinks (pointing to non-existent pages).
- Check for stale claims (pages unchanged >90 days while sources added).
- Check for contradictions flagged in LOG.md.
- Check for concepts mentioned ≥3 times but without dedicated pages → suggest creation.
- Check index.md is up to date with wiki/ contents.

## Curation Heuristics
- Coverage `high`: 5+ sources; trust wiki directly.
- Coverage `medium`: 2-4 sources; check raw sources for detail.
- Coverage `low`: 0-1 source; read raw source directly.

## Output Conventions
- Files written to wiki/ are final artifacts; never edit manually.
- Human edits are overwritten on recompile.
- Human curation happens via source selection and prompt guidance, not page editing.
```

---

## Core Operations

### Ingest Pipeline

**Purpose**  
Transform a raw source document into integrated wiki pages (concept/entity updates + source summary).

**Inputs**
- File path in `raw/` or URL to fetch
- Optional: user-provided guidance (tags, emphasis)

**Process**
```python
def ingest(source_path: str) -> IngestResult:
    # 1. Parse & extract text
    text = extract_text(source_path)
    
    # 2. LLM analysis
    entities, concepts, claims = llm_extract(text)
    
    # 3. For each entity: create or update entity page
    for entity in entities:
        page = find_or_create_page(f"entities/{entity.slug}.md")
        page.merge(entity, source=source_path)
        page.save()
    
    # 4. For each concept: create or update concept page
    for concept in concepts:
        page = find_or_create_page(f"concepts/{concept.slug}.md")
        page.merge(concept, source=source_path)
        page.save()
    
    # 5. Create source summary page
    summary_page = create_source_summary(text, entities, concepts, claims)
    summary_page.save()
    
    # 6. Flag contradictions
    contradictions = detect_contradictions(new_claims, existing_claims)
    log_contradictions(contradictions)
    
    # 7. Update index
    rebuild_index()
    
    # 8. Append to log
    log.md.append(f"{now} | INGEST | {source_path} | {len(entities)} entities, {len(concepts)} concepts")
    
    return IngestResult(...)
```

**Performance**
- Typical cost: $0.30–$1.50 per 10K-word source (claude-3.7-sonnet)
- Time: 30–90 seconds per source (depends on length)
- Frequency: On-demand or scheduled (e.g., daily ingest batch)

**Batch Processing**
```bash
hermes ingest batch --sources raw/articles/*.md
hermes ingest watch           # Auto-ingest new files dropped in raw/
```

### Query Service

**Purpose**  
Answer user questions by reading pre-compiled wiki pages instead of raw sources.

**Process**
```python
def query(question: str, save: bool = False) -> QueryResult:
    # 1. Read INDEX.md to identify candidate pages
    index = read_index()
    relevant_slugs = llm_select_relevant_pages(question, index)
    
    # 2. Load full page contents for relevant slugs
    pages = load_pages(relevant_slugs)
    context = "\n\n".join(pages)
    
    # 3. Synthesize answer with citations
    answer = llm_answer(question, context)
    
    # 4. If save=True and answer adds value → file back as wiki page
    if save and is_valuable_synthesis(answer):
        slug = slugify(question)
        save_page(f"synthesis/{slug}.md", answer)
        rebuild_index()
        log.md.append(f"{now} | QUERY-SAVE | {slug}")
    
    return QueryResult(answer=answer, sources=pages)
```

**Query Types**
- `hermes query "What is GraphRAG?"` → conversational answer
- `hermes query --type comparison "RAG vs GraphRAG"` → structured comparison table
- `hermes query --type timeline "History of LLM agents"` → chronologically ordered events

**Cost & Latency**
- Reading wiki vs raw: ~10× cheaper per token
- Index read overhead: negligible (<$0.01 per query at 1000 pages)

**Compounding**
Valuable answers saved as new pages become part of the knowledge base. Future queries reference them automatically.

### Lint Operation

**Purpose**  
Periodic health check to maintain wiki integrity over time.

**Frequency**
- Weekly: mechanical checks only (fast)
- After batch ingest: full lint
- Monthly: deep semantic analysis
- Before sharing/publishing: full review + approvals

**Mechanical Pass** (script-based; no LLM)
```bash
# Built-in subcommands
hermes lint orphans        # Pages with no inbound wikilinks
hermes lint broken-links   # [[links]] pointing to non-existent pages
hermes lint stale          # Pages not updated > threshold
hermes lint duplicate-slugs # Two pages with same slug
hermes lint index-drift    # index.md missing pages present in wiki/
```

**Semantic Pass** (LLM-based)
- Contradictions: Find claims on Page A that conflict with Page B
- Stale claims: Identify assertions superseded by newer sources
- Gap detection: Concepts mentioned ≥N times but lacking a page
- Cross-reference gaps: Entities/concepts frequently cited but not linked
- Missing sources: Claims without any `^[source.md]` citation marker
- Data staleness: Facts with dates that need updating

**Output Format**
```markdown
# Wiki Lint Report — 2026-04-26

**Total pages:** 1,247  **Last log:** 2026-04-26 02:14

## Found

⚠️ **Contradictions** (3)
- `concepts/rag.md`: "RAG eliminates hallucinations" vs `comparisons/rag-limits.md`: "RAG can still hallucinate" (see sources xyz & abc)

📄 **Orphan Pages** (7)
- `entities/person/elon-musk.md` has 0 inbound links. Consider linking from `concepts/spacex.md`.

⏰ **Stale Pages** (12)
- `concepts/transformer.md` last modified 2025-12-01 while sources added in 2026-01+. Consider re-ingesting recent papers.

🔗 **Broken Links** (4)
- `[[nonexistent-concept]]` in `entities/org/openai.md`

💡 **Gaps Identified** (5)
- "Attention mechanism" mentioned in 9 pages but no dedicated page.
- "Constitutional AI" cited 6 times, appears only in source summaries.

## Suggested Actions
1. Run `hermes lint contradictions --fix` to auto-generate conflict-resolution drafts.
2. Review and link orphan pages to relevant entities.
3. Re-ingest raw sources for stale pages to refresh content.
4. Create pages for 5 high-frequency gap concepts.
```

**Auto-Fix Mode**
Some checks offer auto-fix:
- `--fix-broken-links`: Removes links to missing pages (with confidence score)
- `--fix-orphans`: Adds backlink from entity profile to pages referencing it

**Integration**
- Integrated into CI/CD pipeline (pre-commit hook: `hermes lint` blocks if critical failures)
- Exit code non-zero if lint fails → automated alerting

---

## CLI Tool Specification

### Command Design

Inspired by `llm-wiki-compiler` and `cognee-cli`, Hermes CLI follows familiar patterns:

```bash
# Core workflow
hermes init                           # First-time setup (scaffold dirs, generate AGENTS.md)
hermes ingest <source>                # Ingest single source (file or URL)
hermes ingest --batch raw/articles/*  # Bulk ingest
hermes compile                        # Incremental recompile from scratch (debug/rebuild)
hermes query "question?"              # Ask wiki a question
hermes query --save "deep analysis"   # Save answer as wiki page
hermes lint                           # Full health check
hermes lint --weekly                  # Fast mechanical-only pass
hermes digest                         # Daily brief: new sources, changes, gaps

# Discovery & auto-update
hermes discover --topic "GraphRAG"    # Find web sources to fill gaps from lint
hermes discover --auto                # Autonomous discovery mode (runs nightly)

# Search & explore
hermes search --type vector "keyword"  # Semantic search across wiki pages
hermes search --type graph "entity"    # Graph traversal to find related nodes
hermes search --type hybrid "query"    # BM25 + vector + LLM rerank

# Maintenance
hermes prune --stale --days 180        # Archive pages not touched in 6 months
hermes promote draft.md --to reviewed # Move page up maturity tier
hermes rollback page.md --version 2    # Restore previous version
hermes watch --sources raw/           # Auto-recompile on file changes

# Utilities
hermes status                          # Wiki health snapshot (pages, sources, last ingest)
hermes export --format obsidian        # Copy to Obsidian vault
hermes sync --remote <url>             # Push/pull wiki to remote storage
```

### Implementation Stack

**Backend** (Python)
- LLM provider abstraction: supports Anthropic (Claude), OpenAI (GPT), Google (Gemini), local (Ollama/Llama)
- Ingestion: `llmsherpa` for PDF layout understanding; `trafilatura` for web extraction; `youtube-transcript-api` for video
- Graph management: `networkx` for local graphs; `neo4j` driver for GraphRAG queries
- Vector search: `lancedb` or `chromadb` for semantic search of wiki pages
- CLI framework: `typer` or `click` for command definitions
- Configuration: `pydantic-settings` for schema validation

**Frontend** (optional)
- Web UI: `FastAPI` + `HTMX` for interactive wiki browsing, LDAP auth for team access
- MCP server: Exposes tools to Claude Code/Codex for agent-native access
- Obsidian plugin: Auto-sync via file system or Git; real-time search integration via MCP

**Storage**
- File-based wiki: git-tracked markdown (primary source of truth)
- Graph DB: Neo4j (production), SQLite + networkx (local development)
- Vector DB: LanceDB (embedded local) or Qdrant (server)

---

## Health Checks & Linting

### Lint Taxonomy

From community implementations and operational experience:

#### Category 1: Structural Integrity

| Check | Detection Method | Severity | Auto-Fix |
|-------|-------------------|----------|----------|
| Orphan pages | Count inbound wikilinks = 0 | Medium | Yes (link to related entity) |
| Broken wikilinks | Match `[[slug]]` against existing files | High | Yes (remove or suggest target) |
| Duplicate slugs | Scan all filenames for slug collisions | Critical | No |
| Index drift | `index.md` missing pages present in `wiki/` | High | Yes |
| Missing frontmatter | Regex for `---\ntitle:` block | Medium | Yes (generate placeholder) |
| Cyclic imports | Graph cycle detection (A→B→A) | Critical | No |

#### Category 2: Content Quality

| Check | Detection Method | Severity | Auto-Fix |
|-------|-------------------|----------|----------|
| Stale claims | Claims older than N days with no newer source updating them | Medium | No (flag for review) |
| Contradictions | Two pages making incompatible statements | High | No (create conflict-resolution draft) |
| Missing citations | Sentences without `^[source.md]` marker | Low | Yes (append citation placeholder) |
| Uncited entities | Entity page exists but no source cites it | Low | No |
| Empty pages | Page body < 100 words after trim | Low | No |

#### Category 3: Knowledge Graph Health

| Check | Detection Method | Severity | Auto-Fix |
|-------|-------------------|----------|----------|
| Gap concepts | Term appears ≥5 times in raw text but no concept page | Medium | No (suggest creation) |
| Hub pages | Page with ≥50 outgoing wikilinks → may be too broad | Info | No |
| Isolated clusters | Graph component size 2–3 nodes → disconnected subgraph | Medium | No (suggest connections) |
| Entity drift | Entity profile attributes differ across sources | Medium | No (flag inconsistency) |

#### Category 4: Operational

| Check | Detection Method | Severity | Auto-Fix |
|-------|-------------------|----------|----------|
| Log gap | No ingest in last N days (if daily schedule expected) | Low | No |
| Failed ingests | Ingest jobs that errored without resolution | High | No |
| Disk usage | Growth rate exceeding threshold (alert) | Low | No |

### Lint Pipeline

```bash
# Step 1: Mechanical scan (fast, scripts)
hermes lint mechanical
  ├─ scan_orchestrator.py — metadata extraction
  ├─ graph_analyzer.py — graph traversal for hubs/cycles
  └─ index_validator.py — index.md ↔ wiki/ sync check

# Step 2: Semantic scan (LLM)
hermes lint semantic --model claude-3.7-sonnet
  ├─ contradiction_detector.md — prompt template
  ├─ gap_finder.md — find missing concepts
  └─ staleness_assessor.md — evaluate claim freshness

# Step 3: Report generation
hermes lint report --output markdown
```

**Report Delivery**
- Daily cron: email summary if new issues
- API endpoint `/health` returns JSON with pass/fail status
- Web UI notifications dashboard

---

## Obsidian Integration Strategy

### Why Obsidian?

- Native markdown with bidirectional wikilinks (`[[slug]]`)
- Graph view provides immediate visual feedback
- Extensible via plugins (Dataview, Kanban, Calendar)
- Local-first; vault is just files (git-friendly)
- Mature plugin ecosystem; can extend with custom plugins

### Integration Modes

#### 1. Live Sync (Push Model)

**Setup**
- Hermes writes directly to Obsidian vault path
- Obsidian open while Hermes runs → live updates appear
- Recommended: separate `wiki/` subdirectory within vault

```
MyVault/
├── .obsidian/
├── raw/          ← Curate sources here
├── wiki/         ← Hermes manages this
│   ├── index.md
│   ├── concepts/
│   ├── entities/
│   └── ...
├── MeetingNotes.md
├── ProjectAlpha.md
└── ...
```

**Workflow**
```bash
hermes ingest file.pdf
# Writes to MyVault/wiki/concepts/...
# Obsidian's auto-reload shows updated graph instantly
```

**Pros**
- Instant feedback; watch wiki grow in real-time
- No sync delay; no merge conflicts

**Cons**
- Cannot edit wiki manually (LLM will overwrite)
- Requires careful coordination if human accidentally edits

**Mitigation**: Set `wiki/` to read-only for user; only Claude Code has write access via AGENTS.md restriction.

#### 2. Bidirectional Sync (Pull Model)

**Setup**
- Hermes maintains `wiki/` in separate repo
- Git push → CI/CD → Deploy to Obsidian vault
- Human edits to wiki preserved? No — wiki is LLM-managed only

**Recommended only for**
- Team environments with shared central vault
- CI/CD validation before publishing

#### 3. MCP Server Bridge (Agent-Native)

The Model Context Protocol (MCP) allows Hermes to expose its tools to any MCP-compatible agent (Claude Desktop, OpenHands, etc.):

```json
{
  "server": {
    "name": "hermes-second-brain",
    "tools": [
      {
        "name": "hermes_query",
        "description": "Query the Hermes knowledge base",
        "inputSchema": { "question": "string", "save": "boolean" }
      },
      {
        "name": "hermes_ingest",
        "description": "Add a raw source to the knowledge base",
        "inputSchema": { "source": "path-or-url" }
      },
      {
        "name": "hermes_lint",
        "description": "Health-check the knowledge base",
        "inputSchema": { "severity": "enum" }
      }
    ]
  }
}
```

**Benefits**
- Human remains in Claude Desktop; tools run via MCP server → Hermes processes → results return to chat
- No context-switching; wiki manipulation feels like using a native feature
- MCP server can also expose Obsidian filesystem operations via Obsidian CLI

#### 4. Obsidian Plugin (Embedded Agent)

Develop an Obsidian plugin `hermes-brain` that:
- Registers slash commands `/ingest`, `/query`, `/lint`
- Invokes local Hermes daemon via RPC
- Displays lint reports, query results inline in notes
- Adds properties panel showing page provenance (sources, versions)

**Pros**
- UI fully integrated; feels native
- Can visualize graph statistics, page network

**Cons**
- Requires plugin maintenance for Obsidian updates
- More complex deployment

**Recommended Path**
Start with **Mode 1 (Live Sync)** for simplicity. Progress to **Mode 3 (MCP Server)** if agent-native access becomes primary workflow.

### Obsidian Configuration

**Required Plugins**
- **Dataview**: Render dynamic queries like `WHERE contains(sources, "raw/articles/...")`
- **Graph Analysis**: Explore wikilink graph; identify orphans/hubs
- **Calendar**: Link page creation dates to calendar view

**Custom CSS Snippet** (optional)
```css
/* Wiki page annotations */
.page-provenance { font-size: 0.85em; color: var(--text-muted); }
.coverage-high { border-left: 3px solid green; }
.coverage-medium { border-left: 3px solid orange; }
.coverage-low { border-left: 3px solid red; }
```

---

## Scheduling & Automation

### Recommended Cadence

| Operation | Frequency | Trigger | Cost Impact |
|-----------|-----------|---------|-------------|
| **Ingest** | Daily batch (night) | New files in `raw/` or cron `0 2 * * *` | Medium |
| **Lint (mechanical)** | Daily | After ingest completes | Minimal |
| **Lint (full)** | Weekly (Sunday AM) | Cron `0 6 * * 0` | Low |
| **Discovered gap research** | Weekly (Monday) | After full lint | Medium |
| **Index rebuild** | Every ingest + weekly | Event-driven | Low |
| **Log rotation** | Monthly | First day of month | Negligible |

### Scheduling Implementation

**Option A: Cron + Scripts**

`crontab -e`
```bash
# Nightly ingest of newly added sources
0 2 * * * cd /path/to/brain && /usr/local/bin/hermes ingest --batch raw/articles/* --log /var/log/hermes/ingest-$(date +\%Y-\%m-\%d).log

# Daily mechanical lint (fast)
30 2 * * * cd /path/to/brain && hermes lint --mechanical --output html --email if-fail

# Weekly comprehensive lint (Sunday 6am)
0 6 * * 0 cd /path/to/brain && hermes lint --full --semantic --report weekly-lint-$(date +\%Y-\%m-\%d).md

# Monthly cleanup
0 4 1 * * cd /path/to/brain && hermes prune --stale --days 180
```

**Option B: Systemd Timers** (Linux)

`~/.config/systemd/user/hermes-ingest.service`
```ini
[Unit]
Description=Hermes Ingest

[Service]
Type=oneshot
ExecStart=/usr/local/bin/hermes ingest --batch
WorkingDirectory=/home/user/brain
```

`~/.config/systemd/user/hermes-ingest.timer`
```ini
[Unit]
Description=Daily Hermes Ingest

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
```
Enable with `systemctl --user enable --now hermes-ingest.timer`

**Option C: Claude Code / Agent Dispatch**

For environments without cron access (e.g., remote agent-only setups):
```markdown
// In AGENTS.md or scheduled prompt
/schedule every day at 2am: 
  run("hermes ingest --batch raw/articles/")
  run("hermes lint --quick")
/claude-dispatcher-init  # Registers with external cron service
```

**Option D: GitHub Actions** (for Git-tracked vault)

```yaml
name: Daily Ingest & Lint
on:
  schedule:
    - cron: '0 2 * * *'  # Daily 2am UTC
  workflow_dispatch:

jobs:
  ingest:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run ingest
        run: |
          pip install hermes-brain
          hermes ingest --batch raw/articles/
      - name: Run lint
        if: always()
        run: hermes lint --mechanical
      - name: Commit changes
        run: |
          git config user.name "Hermes Bot"
          git config user.email "hermes@localhost"
          git add wiki/ log.md INDEX.md
          git commit -m "Daily ingest & lint $(date)"
          git push
```

**Cron Best Practices**
- Set timezone explicitly: `CRON_TZ=America/New_York`
- Use `flock` to prevent overlapping runs: `0 2 * * * flock -n /tmp/hermes-ingest.lock hermes ingest ...`
- Log rotation via `logrotate` or built-in rotation
- Alert on failure: `|| echo "Hermes ingest failed" | mail -s "Alert" user@example.com`

### Priority Scheduling

For large wikis, prioritize updates using frontmatter `update_frequency`:

```yaml
# In page frontmatter
update_frequency: 7d   # Revisit weekly
importance: 80         # High importance (0-100)
```

Priority score: `(days_since_edit / update_frequency_days) * (importance / 100)`

Pages with highest priority get processed first during batch operations.

---

## Feedback Loops

The LLM Wiki is not static; it learns and improves through data-driven feedback cycles.

### 1. Lint → Discover → Ingest Loop

**Input**: Lint identifies gap concepts, missing sources, contradictions.

**Process**:
```python
# After lint, generate discovery queries
gaps = lint_report.find_gaps()  # e.g., "attention mechanism not covered"

discover_queries = []
for gap in gaps:
    query = f"Recent papers about {gap.topic} 2024-2026"
    discover_queries.append(query)

# Agent autonomously searches web/ArXiv/arXiv
sources = web_search_bulk(discover_queries)
downloaded = [fetch(url) for url in sources]

# Queue for ingest
hermes ingest --batch downloaded/*
```

**Result**: Knowledge gaps are filled automatically. The wiki proactively expands into undercovered areas.

### 2. Query → Save → Re-Query Loop

When a user asks a complex question that synthesizes multiple domains, LLM produces a rich answer:

```bash
hermes query "How does GraphRAG improve upon traditional RAG for knowledge-intensive tasks?" --save
# → Creates wiki/synthesis/graphrag-vs-rag-improvements.md
```

Future users asking similar questions benefit from this synthesis immediately.

### 3. Schema Co-Evolution

LLM agent can propose updates to `AGENTS.md` based on emerging patterns:

```
[OBSERVATION] In last 30 days, 70% of source summaries included "Future Work" section.
[PROPOSAL] Add "future_work" field to source summary template in AGENTS.md.
[PROPOSAL] Add dedicated "future-work/" subdirectory for tracking open questions.
```

Human approves modifications → agent updates schema → next ingest follows new conventions.

### 4. Quality Feedback Loop

Track which pages are actually read/used:

```python
# In query() function
log_query_usage(page_slugs=[...], question=question)

# Weekly report
hermes digest
# → Most-accessed pages this week:
#    1. concepts/graphrag.md (47 reads)
#    2. entities/org/neo4j.md (32 reads)
#    3. synthesis/attention-mechanisms.md (28 reads)
```

Low-usage pages flagged for archival or merging.

### 5. Automatic Contradiction Resolution

When contradictions detected:
1. Lint creates `drafts/resolve-contradiction-XYZ.md` with both viewpoints and sources
2. Human or higher-tier agent reviews
3. Resolution integrated into affected pages
4. Contradiction marked resolved in LOG.md

**Decision**: Which contradictions need human review vs. auto-resolve?
- High-confidence factual: auto-fix (e.g., "2024" vs "2025")
- Low-confidence interpretive: require human (e.g., "RAG is sufficient" vs "RAG is limited")

### 6. Source Fatigue Detection

Monitor source citation frequency:

```
Page A cites Source X 15 times across 5 revisions.
Page B cites Source X 12 times.
→ Source X is highly influential in this domain.
```

Can signal: (a) foundational importance, (b) need to create a dedicated concept page summarizing Source X's thesis.

---

## Implementation Roadmap

### Phase 1: Core MVP (Weeks 1–3)

**Goal**: Minimal working LLM Wiki with ingest, query, lint.

**Deliverables**
- Directory scaffolding: `raw/`, `wiki/`, log/index files
- AGENTS.md template generation (`hermes init`)
- Ingest command with basic entity/concept extraction
- Query via index.md → page retrieval → LLM synthesis
- Mechanical lint (orphans, broken links, index drift)
- Documentation: README, usage examples

**Estimated Effort**: 1–2 engineers × 3 weeks

### Phase 2: Enhanced Compilation (Weeks 4–6)

**Goal**: Two-phase pipeline, incremental recompilation, source hashing.

**Deliverables**
- Hash-based change detection (skip unchanged sources)
- Two-phase: extract concepts → generate pages
- Conflict detection between new claims and existing pages
- Source deduplication and canonical naming
- Batch ingest with progress bar

**Dependencies**: Phase 1

### Phase 3: Advanced Query & GraphRAG (Weeks 7–9)

**Goal**: Beyond index.md lookup; hybrid search.

**Deliverables**
- Vector search over wiki pages (LanceDB/Qdrant)
- Graph traversal queries (Neo4j integration)
- `hermes search --type hybrid` combining BM25 + vector + LLM rerank
- Save answer as page (`--save`) with proper categorization
- Query context caching for faster subsequent queries

**Dependencies**: Phase 1

### Phase 4: Health & Automation (Weeks 10–12)

**Goal**: Robust linting, scheduled upkeep.

**Deliverables**
- Full lint suite (mechanical + semantic categories)
- Automated gap discovery via web search
- Cron/systemd integration scripts
- Weekly digest email
- Status API (`GET /status`, `/health`)

**Dependencies**: Phase 2

### Phase 5: Obsidian Integration (Weeks 13–15)

**Goal**: Native Obsidian experience.

**Deliverables**
- Live sync configuration; `.gitignore` templates
- Obsidian plugin skeleton (optional)
- MCP server exposing Hermes tools
- Sample vault with demo data
- Documentation: "Obsidian as UI" guide

**Optional**: Develop Obsidian plugin if demand indicated.

### Phase 6: Scale & Polish (Weeks 16–20)

**Goal**: Production-ready for teams.

**Deliverables**
- Multi-user authentication/permissions
- Team knowledge graph with ACLs per entity/page
- Audit log (who modified what and when)
- Fine-grained rate limiting and cost tracking
- UI improvements: colored badges for confidence/coverage; page age heatmap
- Schema evolution tooling (versioned AGENTS.md)
- Pre-commit hooks (reject direct wiki edits)
- Docker image for easy deployment

---

## Cost & Performance Estimates

### Ingest Cost Per Source (Claude 3.7 Sonnet)

| Source Type | Tokens In | Tokens Out | Cost (~$ per 1M tokens) | Cost/Source |
|-------------|-----------|------------|--------------------------|-------------|
| Article (2K words) | 15K | 8K | $3–$15 | $0.05–$0.35 |
| Paper (10 pages PDF) | 45K | 20K | $3–$15 | $0.20–$1.00 |
| Transcript (1 hour) | 70K | 35K | $3–$15 | $0.35–$1.60 |

**Weekly budget** (10 sources): $3–$15/week

### Query Cost

- Index read: first 1000 tokens free (cached)
- Page retrieval: 5–10 pages × 2K tokens = 10K tokens input
- Synthesis output: 500–1000 tokens
- Cost per query: $0.03–$0.15 (cheap vs RAG's $0.50+)
  
**Monthly budget** (100 queries): $3–$15/month

### Infrastructure

| Component | Local / Cloud | Cost |
|-----------|---------------|------|
| LLM API | Cloud (Claude/OpenAI) | Pay-per-use |
| Vector DB | LanceDB (embedded) | Free |
| Graph DB | Neo4j Desktop / Aura | $0–$60/mo |
| Storage | Local SSD / Git | Free |
| Compute | Modern laptop (16GB RAM) | — |

Total monthly operating cost: **$10–$50** for active researcher.

---

## Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| **Schema drift** – pages become inconsistent as agent updates evolve | High | Strict AGENTS.md versioning; CI validation pre-commit; human review before schema changes |
| **LLM overwrites human edits** | High | Make wiki/ read-only at filesystem level; set `chmod 555` except for agent user |
| **Context window overflow at scale** | Medium | Index-based selective loading; implement vector search as index augmentation |
| **Cost creep** – monthly LLM spend exceeds budget | Medium | Token budgeting; hash-based incremental recompilation; alerts at spending thresholds |
| **Obsidian plugin breakage on updates** | Low | Use filesystem sync, not real-time plugin; avoid tight Obsidian version dependency |
| **Wiki decay over years** | Medium | Automated lint → gap discovery → ingest loop; annual review of schema |

---

## Appendix: Reference Files

### Recommended AGENTS.md (Starter)

[To be generated by Hermes `init` command]

### Sample INDEX.md

```markdown
# Knowledge Index

## Concepts
| Page | Summary | Sources |
|------|---------|---------|
| [[attention-mechanism]] | Scaled dot-product attention allows models to focus on relevant tokens | 5 |
| [[graphrag]] | Extends RAG by extracting knowledge graphs for richer context | 3 |

## Entities
| Page | Type | Summary |
|------|------|---------|
| [[openai]] | org | AI research company; creator of GPT-4, o1, Claude |
| [[claude]] | software | Anthropic's constitutional AI assistant |

## Sources
| Page | Date | Type | Entities |
|------|------|------|----------|
| [[2026-04-25-llm-wiki]] | 2026-04-25 | article | Karpathy, Claude |
| [[2025-03-12-attention-paper]] | 2025-03-12 | paper | Vaswani et al. |
```

### Lint Configuration

`config/lint.yaml`
```yaml
schedule:
  mechanical: daily
  semantic: weekly
  monthly_review: true

thresholds:
  orphan_warning: 5
  stale_days: 90
  contradiction_severity: "high"  # only block on high-sev
  broken_links: error
  index_drift: error

actions:
  auto_fix:
    broken_links: true
    orphans: false  # require human review

notifications:
  email: hermes-lint@example.com
  slack: "#hermes-alerts"
```

---

## Conclusion

Hermes Second Brain operationalizes the LLM-compiled wiki pattern into a complete, production-ready system for personal and team knowledge management. By combining Karpathy's three-layer architecture with Cognee's GraphRAG knowledge graph and community-proven automation patterns, it delivers a zero-maintenance, compounding knowledge base where the LLM acts as librarian, archivist, and curator.

**Key differentiators**:
- LLM maintains wiki exclusively; humans curate and explore
- Built-in health checks ensure integrity over time
- Native Obsidian integration for graph visualization and daily use
- Scheduled automation eliminates manual oversight
- Feedback loops actively find and fill knowledge gaps

The result: a living knowledge base that accumulates value with every source, query, and revision — exactly as Karpathy envisioned, now architected for reliability and scale.

---

*Document version: 1.0 — Last updated: 2026-04-26*  
*Author: Hermes Architecture Team*  
*Status: Draft for review*
