# Hermes Second Brain — Complete System Architecture

**Version:** 1.0
**Date:** 2026-04-26
**Author:** Hermes Agent (Nous Research)
**Status:** Design Specification

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Design Goals](#design-goals)
3. [Three-Layer Architecture](#three-layer-architecture)
4. [Skill Extraction & Symlinking](#skill-extraction--symlinking)
5. [Knowledge Graph + GraphRAG Layer](#knowledge-graph--graphrag-layer)
6. [CLI Tool Suite](#cli-tool-suite)
7. [Cron Jobs & Automation](#cron-jobs--automation)
8. [Obsidian Frontend Integration](#obsidian-frontend-integration)
9. [Cost & Performance Estimates](#cost--performance-estimates)
10. [Implementation Roadmap](#implementation-roadmap)

---

## Executive Summary

Hermes Second Brain is an AI-native personal knowledge management system built on Andrej Karpathy's **LLM Wiki** pattern. The system treats raw research sources as immutable inputs and uses Claude (via Hermes Agent) as a full-time librarian to continuously compile them into a structured, interlinked knowledge graph of markdown files.

**Key Properties:**
- **Zero maintenance**: LLM compiles and maintains all wiki content; humans only curate sources
- **Compounding knowledge**: Answers saved from queries become part of the wiki
- **Full audit trail**: Every claim traces to a source file
- **Obsidian-native**: Files are standard Markdown with wikilinks; vault-ready
- **GraphRAG-enabled**: Structured querying via knowledge graph traversal

**Core Data Flow:**
```
Raw sources (JSON/MD/PDF) → Ingest → Knowledge Graph → Wiki pages (Markdown)
                                        ↓
                                    Query API ← User questions
                                        ↓
                                Saved answers (feedback loop)
```

---

## Design Goals

| Goal | Description | Success Metric |
|------|-------------|----------------|
| **Zero maintenance** | LLM compiles & maintains; humans curate sources only | No manual wiki page edits for 30 days |
| **Auditability** | Every claim cites a source file | >95% of wiki paragraphs have citations |
| **Scalability** | Handle 500–1000 sources, 2000–5000 wiki pages | Ingest < 2 min per source at 1000 sources |
| **Integration** | Native Obsidian vault format with wikilinks | Obsidian graph view displays correctly |
| **Evolution** | Schema and workflows co-evolve with Claude | AGENTS.md updates monthly |
| **Cost-efficiency** | Incremental compilation minimizes LLM calls | < $50/mo for 1000-source corpus |

---

## Three-Layer Architecture

### Layer 1: Raw Sources (`raw/`)

Immutable, curated source documents. LLM reads these but never writes.

**Structure:**
```
raw/
├── articles/         # Web clippings, blog posts, summaries (Markdown)
├── papers/           # Academic papers (PDF → extracted text)
├── repos/            # GitHub repos (README + file tree + key code snippets)
├── transcripts/      # Voice/video transcripts (Whisper output)
├── images/           # Diagrams, charts, screenshots (with captions)
├── data/             # Tables, JSON dumps, CSV files
└── assets/           # Supporting files (code snippets, configs)
```

**Naming Convention:**
- `YYYY-MM-DD-short-description.md` for text-based sources
- Original filename preserved in frontmatter
- Hash-based deduplication: `sha256: <hex>` field
- Sources grouped by type for ingest pipeline routing

**Frontmatter Schema:**
```yaml
---
title: "Original Document Title"
source_type: "article|paper|repo|transcript|image|data"
date_added: "2026-04-25"
original_url: "https://..."
original_path: "/path/to/source.pdf"
sha256: "abc123def456..."
tags: ["topic1", "topic2", "hermes"]
categories: ["research", "engineering"]
ingested_at: "2026-04-25T14:30:00Z"
---
```

**Source Ingestion Rules:**
1. Extract text using universal adapters (unstructured, PyPDF2, etc.)
2. Normalize to Markdown + YAML frontmatter
3. Store in appropriate `raw/` subfolder by `source_type`
4. Compute SHA256 fingerprint; skip if already present (idempotency)
5. Log ingestion to `raw/ingest.log`

---

### Layer 2: Compiled Wiki (`wiki/`)

LLM-generated, human-readable markdown knowledge base. Entirely maintained by AI.

**Structure:**
```
wiki/
├── index.md              # Catalog of all pages with summaries (auto-generated)
├── log.md                # Append-only chronological action log
├── overview.md           # High-level topic overview & getting started
├── AGENTS_SCHEMA.md      # Schema & operational guidelines for agent
├── concepts/             # Abstract ideas, principles, frameworks
│   ├── llm-wiki-pattern.md
│   ├── graphrag.md
│   └── knowledge-compounding.md
├── entities/             # Real-world objects (people, orgs, software, tools)
│   ├── person/
│   │   ├── andrej-karpathy.md
│   │   └── anthropic.md
│   ├── organization/
│   │   ├── nous-research.md
│   │   └── openai.md
│   ├── software/
│   │   ├── claude.md
│   │   ├── obsidian.md
│   │   └── hermes-agent.md
│   └── tool/
│       ├── cognee.md
│       └── langchain.md
├── sources/              # Per-source summaries (derived from raw/)
│   ├── 2026-04-25-llm-wiki-pattern.md
│   └── 2026-04-26-cognee-knowledge-engine.md
├── comparisons/          # Comparative analyses
│   ├── rag-vs-graphrag.md
│   └── crewai-vs-autogen.md
├── synthesis/            # Research outputs filed from queries
│   ├── 2026-04-25-agentic-swarm-analysis.md
│   └── 2026-04-26-skill-linking-strategy.md
├── templates/            # Reusable page templates (for agent reference)
└── drafts/               # In-progress pages (auto-cleaned monthly)
```

**Wiki Page Template:**
```markdown
---
title: "Page Title"
slug: "page-title"              # Used in [[wikilinks]]
created: "2026-04-25T14:30:00Z"
last_modified: "2026-04-26T09:15:00Z"
version: 3
sources: ["raw/articles/xyz.md", "raw/papers/abc.txt"]
concepts: ["related-concept", "another-concept"]
entities: ["person/andrej-karpathy", "software/claude"]
classification: "concept|entity|comparison|synthesis|source_summary|draft"
summary: "One-paragraph TL;DR for index.md"
coverage: "high|medium|low"      # Based on source count (high=5+, med=2-4, low=0-1)
change_log:
  - version: 3
    date: "2026-04-26"
    description: "Updated with new source XYZ; added contradiction resolution"
  - version: 2
    date: "2026-04-24"
    description: "Added supporting evidence from raw/abc"
---
# Page Title

## TL;DR
Brief standalone summary (2-3 sentences).

## Overview
Detailed explanation with context. Use headings as needed.

## Key Points
- Point 1 ^[source.md] — inline citation to raw source file
- Point 2 ^[raw/articles/xyz.md] — explicit provenance tracking
- Subtle nuance ^[source.md#section-id] — anchor to section if available

## Related
- [[related-concept]]
- [[another-entity]]
- See also: [[different-namespace/page]]

## Sources
- `[[raw/articles/xyz]]` → key takeaway from this source
- `[[raw/papers/abc]]` → supporting evidence or counterpoint

## Open Questions
- [ ] Question 1 that needs investigation
- [ ] Question 2 that may become a new wiki page
```

**Frontmatter Fields Reference:**

| Field | Purpose | Values / Format |
|-------|---------|-----------------|
| `slug` | URL-friendly identifier for wikilinks | lowercase-kebab-case |
| `version` | Incremented on each update; enables rollback | integer |
| `sources` | Array of raw source paths (provenance) | `["raw/...", "raw/..."]` |
| `concepts` | Linked concept slugs (graph edges) | `["concept-slug", ...]` |
| `entities` | Linked entity slugs with optional namespace | `["person/name", "software/tool"]` |
| `classification` | Content type for index filtering | `concept\|entity\|comparison\|synthesis\|source_summary\|draft` |
| `summary` | One-paragraph descriptor for `index.md` | plain text |
| `coverage` | Source depth indicator | `high\|medium\|low` |
| `change_log` | Versioned history of modifications | array of `{version, date, description}` |

**Wikilink Syntax (Obsidian-compatible):**
- `[[slug]]` — basic link
- `[[slug\|display text]]` — custom display
- `[[slug\|^]]` — inline citation footnoted to sources section
- External links: `[text](https://...)`

**Maintenance Notes:**
- Files written by agent are final artifacts; manual edits discouraged
- Human curation happens via source selection and prompt guidance
- Page regeneration overwrites previous versions (versioned in `change_log`)
- `drafts/` auto-cleaned monthly; `log.md` is append-only

---

### Layer 3: Schema & Configuration (`AGENTS.md`)

**Purpose:** Defines operational workflows, naming conventions, page templates, and agent guidelines. Co-evolves with usage patterns.

**Location:** Root of workspace: `AGENTS.md`

```markdown
# Hermes Second Brain — Agent Operational Schema

## Vault Purpose
This wiki covers Hermes Research, Flux development, AI systems engineering, and adjacent knowledge domains. Focus areas: agentic systems, knowledge graphs, LLM infrastructure, and developer tools.

## Namespace Conventions
- `concepts/` — Abstract ideas, patterns, methodologies (LLM Wiki, GraphRAG, RAG)
- `entities/person/` — Individual people (researchers, engineers)
- `entities/organization/` — Companies, open-source projects, research labs
- `entities/software/` — Software tools, frameworks, libraries
- `entities/tool/` — CLI tools, utilities, platforms (distinct from software)
- `sources/` — Summaries of raw source documents
- `comparisons/` — Comparative analyses between entities/concepts
- `synthesis/` — Query-derived knowledge (answers filed back)
- `drafts/` — In-progress pages (auto-cleared monthly)

## Ingest Workflow (raw → wiki)
1. Read raw source file frontmatter + content.
2. Extract: entities (who/what), concepts (ideas), claims (facts + sources).
3. For each entity: find or create `entities/{type}/{slug}.md`, update with new info + source citation, append change_log.
4. For each concept: find or create `concepts/{slug}.md`, weave in new insights, link to entities.
5. Build source summary page in `sources/` capturing all extracted entities/concepts/claims.
6. Detect contradictions between new claims and existing pages → append to `log.md` with confidence scores.
7. Rebuild `index.md` from scratch (deterministic, never skip).
8. Append ingest record to `log.md`: timestamp, source path, entity/concept counts.

## Query Workflow (user question → answer → optional save)
1. Read `index.md` to identify candidate pages relevant to question.
2. Load full text of each candidate page (statistically re-ranked by LLM).
3. Synthesize answer with inline citations: `[[page-slug]]` or `^[source.md]`.
4. If `--save` flag or answer adds new knowledge → offer to save as `synthesis/` page.
5. On save: create new page, update `index.md`, log action.

## Lint Workflow (weekly automated health check)
Mechanical (scripted, no LLM):
- Orphan pages: pages with zero inbound wikilinks
- Broken links: `[[slug]]` referencing non-existent pages
- Duplicate slugs: two pages with same `slug:` frontmatter
- Index drift: `index.md` missing pages present in `wiki/`
- Empty files: zero-byte or whitespace-only files
- Circular category nesting: invalid directory structures

Semantic (LLM-assisted):
- Contradictions: claims on Page A conflicting with Page B
- Stale claims: assertions superseded by newer sources (temporal invalidation)
- Gap detection: concepts mentioned ≥3 times but lacking dedicated pages
- Cross-reference gaps: entities cited but not linked
- Missing sources: paragraphs without any `^[source.md]` citation marker
- Data staleness: date-stamped facts that need refreshing

## Curation Heuristics
Based on `coverage:` field:
- **High (5+ sources):** Trust wiki directly; minimal raw review needed
- **Medium (2-4):** Check raw sources for nuance; verify contradictory claims
- **Low (0-1):** Read raw source directly; wiki is preliminary

## Output Conventions
- All `wiki/` files are agent-owned; manual edits may be overwritten on recompile
- Human curation occurs at source selection level (what goes into `raw/`) not page editing
- Every factual claim must cite at least one raw source with `^[source.md]`
- Every entity/concept gets its own page once it reaches threshold (≥2 mentions)
- `index.md` rebuild is last step of any operation that mutates wiki

## Error Handling
- Ingest failure: log to `log.md`, retain partial page, continue with others
- Query timeout: return partial + offer to retry with expanded context window
- Lint critical failures (broken index, duplicate slugs): block subsequent operations until resolved
```

---

## Detailed Ingest Pipeline

**Inputs:**
- File path in `raw/` or URL to fetch
- Optional user guidance: tags, emphasis, source-level notes

**Process Flow:**
```
1. Parse & extract text
   └─> Universal adapters: PDF, HTML, MD, TXT, JSON, CSV, image OCR

2. LLM entity & concept extraction
   └─> Identify: persons, organizations, software, tools, concepts, claims
   └─> Generate slugs (kebab-case), classify types, assign confidence scores

3. Entity page updates (create or merge)
   └─> For each entity: read existing page or create template
   └─> Merge new information:
        - Add new claims with citations ^[source.md]
        - Update relationships (uses, implements, created_by)
        - Append changelog entry
   └─> Save to `entities/{type}/{slug}.md`

4. Concept page updates
   └─> Similar pattern: definitions, principles, related concepts
   └─> Link to affected entities
   └─> Save to `concepts/{slug}.md`

5. Source summary page
   └─> Create `sources/YYYY-MM-DD-description.md`
   └─> Page includes: extracted entities, concepts, key claims, full text excerpt
   └─> Establishes provenance for all downstream wiki pages

6. Contradiction detection
   └─> LLM scans new claims vs existing entity/concept pages
   └─> Flags: direct opposites, dated facts, competing interpretations
   └─> Log to `log.md` with confidence and source pointers

7. Index rebuild
   └─> Regenerate `index.md` table of contents from all `wiki/` pages
   └─> Format: `| Page | Classification | Sources | Last Modified | Summary |`

8. Action logging
   └─> Append: `2026-04-26T14:30:00Z | INGEST | raw/articles/xyz.md | entities: 12, concepts: 5, contradictions: 0`
```

**Performance:**
- Typical cost (Claude 3.7 Sonnet): $0.30–$1.50 per 10K-word source
- Average time: 30–90 seconds per source (depends on length and entity density)
- Frequency: On-demand or scheduled (daily batch ingest)

---

## Knowledge Graph + GraphRAG Layer

### Graph Schema

**Node Types** (from `graph.nodes.json`):
```
Node { id, type, label, source, url?, metadata? }

Type             Description                         Example
----             -----------                         -------
repo             GitHub repository                   anthropic/claude-ads
company          Organization                        Nous Research
person           Individual contributor              Andrej Karpathy
tool             CLI tool / utility                  cognee-cli
framework        Software framework                  LangChain
concept          Abstract idea / pattern             GraphRAG, RAG
pattern          Reusable design pattern             LLM Wiki, Agent Loop
tech_stack       Technology stack                    Docker + Postgres
skill            Hermes skill definition             obscura, claude-task-master
service          External API / cloud provider       OpenAI API, Anthropic
```

**Edge Types** (from `graph.edges.json`):
```
Edge { from, to, relation, weight?, source? }

Relation          Meaning (directional)               Example
--------          -----------------                   -------
uses              Entity utilizes technology           Hermes → uses → LangChain
integrates_with   Bidirectional integration            Claude Ads ↔ integrates_with → Google Ads API
inspired_by       Pattern borrowed / derived           TaskMaster ← inspired_by ← Claude Code
part_of           Component relationship               SDK → part_of → Obscura platform
extends           Adds to base functionality           fork → extends → original
implements        Realizes a pattern/architecture      Cognee → implements → GraphRAG
produces          Outputs / generates                  Agent → produces → synthetic data
targets           Goal or domain focus                 Vibe-Trading → targets → algorithmic trading
compatible_with   Standards compliant                  Skill → compatible_with → MCP protocol
requires          Dependency / prerequisite            Skill A → requires → Skill B
```

### GraphRAG Query Layer

**Architecture:**
```
User query (natural language)
        ↓
Graph retrieval:
  - Identify relevant nodes via text similarity (vector search)
  - Traverse edges to expand context (graph walk)
  - Apply weights (citation frequency, recency, confidence)
        ↓
Hybrid context assembly:
  - Node embeddings (vector similarity)
  - Subgraph extraction (1–3 hops)
  - Node metadata + relationship text
        ↓
LLM synthesis → Answer + source citations + confidence score
```

**Query Modalities:**
- **GRAPH_COMPLETION:** "What tools does Hermes use?" → traverse `uses` edges
- **RAG_COMPLETION:** "Explain GraphRAG" → semantic search over entity descriptions
- **CYPHER:** "Find all skills that require cognee" → structured query language
- **CHUNKS:** "What did the paper say about GraphRAG limitations?" → raw source excerpts
- **SUMMARIES:** "Summarize what we know about Claude Ads" → aggregate node summaries

**Implementation Notes:**
- Store graph in Neo4j or LanceDB for production; NetworkX for local/dev
- Embed node labels + descriptions using Llama embeddings or OpenAI
- Update graph incrementally on each ingest; edge weights decay over time
- Support versioned graph snapshots (enable rollback to prior knowledge state)

---

## Skill Extraction & Symlinking

### Skill Identification Criteria

A research repo qualifies as a **skill** if:
1. It is a tool/framework that Hermes can **operate directly** (invoke API, run CLI)
2. It has **programmatic control surface**: functions/methods/commands
3. It solves a **specific capability need** (code generation, data synthesis, deployment)
4. It is **reusable across multiple projects/tasks**

Filter out:
- Pure documentation/reference repos
- Theory/papers without implementation
- Repos that are effects not causes (symptoms vs. tools)

### Skill File Format (`SKILL.md`)

Each skill in `/skills/<repo-name>/SKILL.md`:

```markdown
---
name: short-skill-name
description: One-line capability description
version: 1.0.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [tag1, tag2, tag3]
    related_skills: [skill-a, skill-b]
    category: mlops|autonomous-ai-agents|product-strategy|infrastructure|data-engineering
    requires: [dependency-skill-1]  # Optional: skills needed before this one
    capability_triggers:
      - "when user asks to generate synthetic data"
      - "when deploying to Coolify"
      - "when user needs to augment ML dataset"
---

# Skill Name — Capability Summary

## When to Use

Trigger when the user:
- Needs capability X
- Wants to achieve Y
- Requires Z

## Prerequisites

- Dependencies (API keys, installations, configs)
- Environment setup steps

## Quick Reference

```python
# Code example showing typical usage
from skill import main_function
result = main_function(params)
```

Equivalent CLI:
```bash
skill-cli command --option value
```

## Integration with Hermes

### 1. Setup
- Store credentials in `~/.hermes/.env` or keyring
- Install package: `pip install skill-name`
- Register tool with hermes-tools registry

### 2. Workflow
Natural language → skill invocation → return structured result

### 3. Caching & Optimization
- Cache expensive computations (e.g., model loads)
- Batch operations when possible
- Respect rate limits with exponential backoff

## Pitfalls

- Cost management: API usage may incur expenses
- Domain gap: synthetic results may not match real-world
- Rate limits: implement queuing for parallel jobs
- Reproducibility: always set random seeds
- Asset licensing: verify commercial use rights
- Network dependency: implement offline mode or cache
```

### Symlink Strategy

**Source (canonical):**
```
/home/tokisaki/work/synthesis/skills/<repo-name>/SKILL.md
```

**Target (Hermes):**
```
~/.hermes/skills/<category>/<short-skill-name>/SKILL.md
```

**Symlink creation:**
```bash
ln -sf /home/tokisaki/work/synthesis/skills/<repo-name> \
       ~/.hermes/skills/<category>/<short-skill-name>
```

Benefits:
- Single source of truth (edit in `synthesis/`, reflected live)
- Zero duplication (same inode, two directory entries)
- Fast iteration (no copy step)
- Version control separate from Hermes config

**Idempotent setup script:** `symlink_setup.sh` (provided below)

---

## CLI Tool Specification

Three core tools wrapping ingest-query-lint cycles:

### `hermes-brain-compile` — Wiki Compiler

Rebuild wiki from scratch or incrementally.

**Usage:**
```bash
# Full recompile from all raw sources
hermes-brain-compile --full

# Incremental: only new/changed sources since last compile
hermes-brain-compile --incremental

# Compile specific source only
hermes-brain-compile --source raw/articles/new-finding.md

# Dry-run: show what would change
hermes-brain-compile --dry-run

# Verbose logging
hermes-brain-compile --verbose
```

**Output:**
- Updated wiki pages in `wiki/`
- New/updated `index.md`
- Appended entries to `wiki/log.md`
- Reconciliation report (added/updated/deleted pages)

**Under the hood:**
- Computes hash of each raw source; skips unchanged (incremental)
- Runs LLM extraction + page generation for each changed source
- Commits changes atomically (writes to temp dir, then moves into place)

---

### `hermes-brain-query` — Knowledge Query

Query the compiled wiki with natural language.

**Usage:**
```bash
# Basic query
hermes-brain-query "What is GraphRAG?"

# Save answer as wiki page
hermes-brain-query --save "GraphRAG explained" "How does GraphRAG differ from RAG?"

# Query specific section of wiki
hermes-brain-query --namespace concepts "Explain LLM Wiki pattern"

# Graph traversal query (Cypher-like)
hermes-brain-query --type graph "What tools does Cognee use?"

# With confidence threshold (0–1)
hermes-brain-query --min-confidence 0.7 "What are the risks of synthetic data?"
```

**Output:**
```
Answer: GraphRAG is a retrieval-augmented generation approach that...

Sources:
  - [[concepts/graphrag]] (coverage: high, last modified: 2026-04-25)
  - [[comparisons/rag-vs-graphrag]] (coverage: medium)

Confidence: 0.87

[Related: [[cognee]], [[knowledge-graph]]]
```

**Graph query examples:**
```bash
# Using Cypher syntax
hermes-brain-query --cypher "MATCH (t:tool)-[:uses]->(f:framework) RETURN t, f"

# Traverse from entity
hermes-brain-query --from obscura --depth 2 "What does Obscura integrate with?"
```

---

### `hermes-brain-lint` — Health Check & Linter

Validate wiki integrity and semantic consistency.

**Usage:**
```bash
# Full lint (mechanical + semantic)
hermes-brain-lint --full

# Quick mechanical-only (fast, no LLM)
hermes-brain-lint --fast

# Specific checks
hermes-brain-lint --orphans        # Pages with no inbound links
hermes-brain-lint --broken-links   # [[wikilinks]] to missing pages
hermes-brain-lint --duplicates     # Duplicate slugs
hermes-brain-lint --index          # Verify index.md is current

# Auto-fix safe issues
hermes-brain-lint --fix-broken-links
hermes-brain-lint --fix-duplicates --dry-run

# Semantic checks (LLM-powered)
hermes-brain-lint --contradictions
hermes-brain-lint --gaps           # High-frequency concepts without pages
hermes-brain-lint --stale          # Uncited claims or outdated facts
```

**Exit codes:**
- 0: No issues found
- 1: Non-critical warnings (orphans, minor broken links)
- 2: Critical failures (index corruption, duplicate slugs)
- 3: Semantic issues detected (contradictions, data staleness)

**Output format:**
```markdown
# Wiki Lint Report — 2026-04-26

**Total pages:** 1,247 | **Last log:** 2026-04-26 02:14

## Found

⚠️ **Contradictions** (3)
- `concepts/rag.md`: "RAG eliminates hallucinations" vs `comparisons/rag-limits.md`: "RAG can still hallucinate"
  Sources: `raw/articles/karpathy.md` vs `raw/papers/rag-limits-2025.pdf`

📄 **Orphan Pages** (7)
- `entities/person/elon-musk.md` has 0 inbound links. Consider linking from `concepts/spacex.md`.

⏰ **Stale Pages** (12)
- `concepts/transformer.md` last modified 2025-12-01; sources added 2026-01+. Re-ingest recent papers.

🔗 **Broken Links** (4)
- `[[nonexistent-concept]]` in `entities/org/openai.md`

💡 **Gaps Identified** (5)
- "Attention mechanism" mentioned in 9 pages but no dedicated page.
- "Constitutional AI" cited 6 times, appears only in source summaries.

## Suggested Actions
1. Run `hermes-brain-lint contradictions --fix` to auto-generate conflict-resolution drafts.
2. Review and link orphan pages to relevant entities.
3. Re-ingest raw sources for stale pages to refresh content.
4. Create pages for 5 high-frequency gap concepts.
```

---

## Cron Jobs & Automation

### Schedule Overview

| Cron | Job | Trigger | Steps |
|------|-----|---------|-------|
| **Daily 3:00 AM** | Research Sync | 00 3 * * * | 1. Pull new research (RSS/arXiv/Newsletters) → `raw/articles/`<br>2. Run `hermes-brain-compile --incremental`<br>3. Update knowledge graph (`build_edges.py`)<br>4. Send daily digest email |
| **Weekly Sunday 6:00 AM** | Insight Digest | 0 6 * * 0 | 1. Run `hermes-brain-lint --full`<br>2. Generate weekly insights summary (new concepts, contradictions, gaps)<br>3. Post to Telegram channel + send email digest<br>4. Archive old `drafts/` (older than 30 days) |
| **Hourly :15** | Health Check | 15 * * * * | 1. Quick `hermes-brain-lint --fast`<br>2. Check for broken symlinks in `~/.hermes/skills/`<br>3. Verify `wiki/` directory not empty, `index.md` exists<br>4. Alert on critical failures (Telegram bot + email) |
| **Monthly 1st 2:00 AM** | Deep Clean | 0 2 1 * * | 1. Full `hermes-brain-lint --full --semantic`<br>2. Prune unreferenced orphan pages (>90 days, <3 inbound links)<br>3. Compress/rotate `wiki/log.md` (keep last 1000 lines, archive rest)<br>4. Database VACUUM if using SQLite/Neo4j |

### Cron Implementation

Use `crontab -e` for user-level scheduling. Alternatively, systemd timers for centralized management.

**Crontab entry example:**
```bash
# HERMES SECOND BRAIN AUTOMATION
# Edit at: crontab -e (user: tokisaki)

# ── Hourly health check
15 * * * * /home/tokisaki/work/synthesis/cron/health_check.sh >> /var/log/hermes/health.log 2>&1

# ── Daily research sync (3 AM)
0 3 * * * /home/tokisaki/work/synthesis/cron/daily_sync.sh >> /var/log/hermes/daily_sync.log 2>&1

# ── Weekly digest (Sunday 6 AM)
0 6 * * 0 /home/tokisaki/work/synthesis/cron/weekly_digest.sh >> /var/log/hermes/weekly_digest.log 2>&1

# ── Monthly deep clean (1st of month, 2 AM)
0 2 1 * * /home/tokisaki/work/synthesis/cron/monthly_clean.sh >> /var/log/hermes/monthly_clean.log 2>&1
```

**Script locations:** `/home/tokisaki/work/synthesis/cron/`
- `health_check.sh`
- `daily_sync.sh`
- `weekly_digest.sh`
- `monthly_clean.sh`

Each script:
1. Logs start timestamp to `cron.log`
2. Runs appropriate CLI commands
3. Captures exit code and output
4. Sends alert on non-zero exit (Telegram webhook + email)
5. Logs completion timestamp and duration

---

## Obsidian Frontend Integration

### Vault Setup

Hermes Second Brain wiki is a fully functional Obsidian vault:

```
~/.hermes/vault/              (symlink to /home/tokisaki/work/synthesis/wiki/)
├── .obsidian/
│   ├── plugins/               (optional: community plugins)
│   ├── themes/
│   └── hotkeys.json
├── index.md
├── concepts/
├── entities/
├── sources/
├── comparisons/
├── synthesis/
└── AGENTS.md                  (vault-specific config)
```

**Setup:**
```bash
# Create symlink to wiki as Obsidian vault
ln -s /home/tokisaki/work/synthesis/wiki ~/.hermes/vault

# Open Obsidian: File → Open folder → ~/.hermes/vault
```

**Obsidian plugins recommended:**
- **Dataview:** Query wiki pages as a database (`TABLE summary FROM "synthesis"`)
- **Graph View:** Visualize entity/concept relationships
- **Templater:** Standardized page creation (agent uses templates)
- **Obsidian Git:** Auto-commit wiki changes (optional versioning)
- **Calendar:** Link daily notes to research sync events

**Workflow:**
1. Hermes Agent updates `wiki/` via CLI commands
2. Obsidian desktop app (open on `~/.hermes/vault`) reflects changes live
3. User explores graph, searches, creates manual notes in `personal/` (separate namespace)
4. User queries answered from wiki; answers optionally saved back as synthesis pages

**Two-way sync:** (optional)
- Obsidian notes in `personal/` excluded from agent control
- Agent can read but never writes to `personal/`
- Manual curation happens in separate namespace

---

## Cost & Performance Estimates

### Compute Costs

| Component | Monthly Volume | Unit Cost | Monthly Cost |
|-----------|---------------|-----------|--------------|
| **Ingest** | 30 sources × 10K words | $0.75 / source (Claude Sonnet 3.7) | $22.50 |
| **Compile** | Full recompile weekly (1K pages) | $5.00 / recompile | $20.00 |
| **Query** | 100 queries × 2K words context | $0.10 / query | $10.00 |
| **Lint** | Weekly full lint (LLM checks) | $3.00 / run | $12.00 |
| **Graph update** | Incremental (script, no LLM) | $0.00 | $0.00 |
| **Total** | | | **~$64.50 / month** |

*Note: Costs scale sublinearly as wiki matures (incremental compile cheaper).*

### Storage

- Raw sources: ~500 MB (PDFs + extracted text)
- Wiki: ~50 MB (Markdown)
- Graph DB: ~10 MB (nodes + edges)
- Obsidian vault (synced): ~60 MB

**Total:** < 1 GB

### Performance

| Operation | Time (avg) | Time (p99) | Dependencies |
|-----------|------------|------------|--------------|
| Ingest single source (10K words) | 45 sec | 2 min | Claude API, text extraction |
| Full compile (1000 sources) | 35 min | 45 min | Incremental mode skips unchanged |
| Query (simple) | 5 sec | 15 sec | Index read + LLM synthesis |
| Query (graph traversal, 2-hop) | 10 sec | 30 sec | Graph DB lookup |
| Lint (fast, mechanical) | 3 sec | 5 sec | Local filesystem only |
| Lint (full semantic) | 2 min | 5 min | LLM for contradiction detection |

---

## Implementation Roadmap

### Phase 1: Foundation (Week 1)
**Goal:** Set up directory structure, schema files, basic tooling.

- [ ] Create `raw/`, `wiki/`, `cron/`, `skills/` directories
- [ ] Write `AGENTS.md` schema specification
- [ ] Implement `hermes-brain-compile` (basic: read raw → LLM → write wiki pages)
- [ ] Implement `hermes-brain-query` (basic: search index → read pages → answer)
- [ ] Write `symlink_setup.sh` for skill linking
- [ ] Create sample raw source and generate corresponding wiki page

**Deliverable:** Working end-to-end ingest → compile → query cycle on 3 sample sources.

---

### Phase 2: Graph Integration (Week 2)
**Goal:** Build knowledge graph layer, GraphRAG queries.

- [ ] Build `graph.nodes.json` and `graph.edges.json` from existing wiki
- [ ] Implement `build_edges.py` (extract relationships from wiki pages)
- [ ] Add `--graph` query mode to `hermes-brain-query`
- [ ] Integrate with Cognee GraphRAG pipeline (optional, if available)
- [ ] Add graph updates to compile pipeline (auto-extract new edges)

**Deliverable:** Query "What does Obscura use?" returns structured graph results.

---

### Phase 3: Automation (Week 3)
**Goal:** Scheduling, health checks, periodic maintenance.

- [ ] Write `cron/` scripts: `health_check.sh`, `daily_sync.sh`, `weekly_digest.sh`
- [ ] Implement `hermes-brain-lint` with mechanical checks (orphans, broken links, duplicates)
- [ ] Add semantic lint passes (LLM-powered contradiction detection)
- [ ] Set up crontab entries
- [ ] Configure Telegram bot for alerts
- [ ] Test weekly digest generation

**Deliverable:** Scheduled jobs operational; weekly digest sent to Telegram channel.

---

### Phase 4: Obsidian Integration (Week 4)
**Goal:** Vault ready for human exploration, bi-directional sync optional.

- [ ] Symlink `wiki/` → `~/.hermes/vault/`
- [ ] Configure Obsidian: plugins, hotkeys, theme
- [ ] Test graph view rendering
- [ ] Document Obsidian workflows in `overview.md`
- [ ] (Optional) Implement personal/ namespace separation
- [ ] (Optional) Git commit automation for wiki changes

**Deliverable:** Obsidian vault open; knowledge graph browsable; daily operations running.

---

### Phase 5: Scale & Polish (Weeks 5–6)
**Goal:** Robustness at scale, user documentation, migration from existing research.

- [ ] Migrate existing research summaries (24 reports) into raw/ + wiki/
- [ ] Populate `entities/` from `entities.json` knowledge graph
- [ ] Bulk ingest all 30+ skills from `/skills/` → wiki entity pages
- [ ] Performance testing at 1000+ sources
- [ ] Cost optimization (caching, batching, cheaper models)
- [ ] Write user manual: `docs/USER_GUIDE.md`
- [ ] Create troubleshooting guide
- [ ] Document recovery procedures (graph rebuild, wiki rollback)

**Deliverable:** Production-ready Second Brain with 1000+ sources, automated pipeline, operational dashboard.

---

## Maintenance & Monitoring

### Metrics to Track

1. **Wiki growth:**
   - Pages added per week
   - Source-to-wiki ratio (sources : pages)
2. **Quality:**
   - Citation density (paragraphs with sources)
   - Contradiction rate (per 1000 pages)
   - Orphan page count
3. **Performance:**
   - Ingest time per source
   - Query latency (p50, p99)
   - LLM cost per operation
4. **Health:**
   - Lint errors (critical vs. warning)
   - Broken symlinks
   - Failed cron runs

### Logging

All operations append to `wiki/log.md`:
```
2026-04-26T03:00:00Z | DAILY_SYNC | sources_added=3, pages_updated=12, errors=0, duration=14m
2026-04-26T06:00:00Z | WEEKLY_DIGEST | sent=telegram,email, new_insights=5, gaps=3
2026-04-26T09:15:12Z | QUERY | "What is GraphRAG?" | pages_used=4 | confidence=0.87
```

### Alerting

Critical conditions trigger Telegram + email:
- Compile failure (incomplete wiki rebuild)
- Health check failure (broken index, duplicate slugs)
- High contradiction rate (>5 new in 24 hours)
- Cron job missed or timeout

---

## Conclusion

Hermes Second Brain transforms research from fragmented reports into a living, breathing knowledge compendium that grows smarter over time. By leveraging the LLM Wiki pattern, GraphRAG, and tight Obsidian integration, it becomes a force multiplier for Hermes's own reasoning capabilities — a true **externalized cortex** that never forgets and continuously learns.

**Next steps:** Begin Phase 1 implementation. Scaffold directories. Write first compile and query tools. Validate with 3 sample sources. Iterate.

---

*End of Architecture Specification*
