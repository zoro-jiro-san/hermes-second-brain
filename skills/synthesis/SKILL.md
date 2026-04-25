---
name: synthesis
description: Knowledge integration and compilation patterns — LLM-compiled wikis, configuration-as-code, deterministic seeding, feedback loops, and continuous learning systems for building and maintaining living documentation.
version: 1.0.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [knowledge-management, documentation, compilation, continuous-learning, wiki, feedback-loops]
    related_skills: [obscura, claude-task-master, agentic-stack]
---

# Synthesis — Knowledge Compilation & Continuous Learning

Synthesis skill encompasses patterns for accumulating, organizing, and refining knowledge over time. It draws from state‑of‑the‑art research on LLM‑compiled wikis, configuration‑as‑code, deterministic execution, and feedback‑driven improvement. Use these patterns when building persistent, self‑improving systems that turn raw information into structured, queryable knowledge that compounds in value.

## When to Use

Trigger when building or maintaining:
- Internal documentation wikis, knowledge bases, or second‑brain systems
- Automated research pipelines that ingest sources and produce summaries
- Configuration management with versioned, reproducible settings
- Systems that learn from user feedback and improve over time
- Audit trails and logging with structured queryability
- Reusable templates, snippets, or prompt libraries
- Daily/weekly/monthly synthesis and consolidation workflows

## Core Philosophy

**Compounding Knowledge**: Each synthesis cycle produces an artifact (markdown file, prompt template, config) that becomes a source for the next cycle. Over time, the knowledge base grows richer, cross‑references emerge, and contradictions are resolved — much like a human researcher's second brain.

**Configuration‑as‑Code**: All synthesis parameters (sources, schedules, prompts) are defined in version‑controlled YAML/JSON files. This enables reproducibility, peer review, and CI/CD validation.

**Deterministic Seeding**: All random or stochastic operations (LLM sampling, shuffle, split) accept a global seed. Given the same sources and seed, synthesis output is byte‑identical across runs — critical for debugging and audit.

**Feedback Loops**: User corrections, lint warnings, and quality metrics feed back into prompt refinement and source prioritization.

## Research Foundations

This skill synthesizes findings from multiple research systems:

- **LLM‑Compiled Wiki (Karpathy 2026)**: Three‑layer architecture (raw/ → wiki/ → AGENTS.md), ingest/query/lint operations, compounding loop
- **Cognee Knowledge Engine**: GraphRAG pipeline (add → cognify → memify → search), multi‑modal ingestion, temporal awareness
- **My‑Brain‑Is‑Full‑Crew**: Autonomous agents managing Obsidian vault, chat‑driven filing
- **Obsidian‑Skills**: Markdown editing, Bases (tables), JSON Canvas patterns for note organization

## Architecture — Three‑Layer Wiki Model

```
┌───────────────────────────────────────────┐
│     Layer 1: raw/                         │
│  (Immutable source documents)            │
│  - research papers, URLs, PDFs           │
│  - user notes, chat logs                 │
│  - unchanged after ingestion             │
└───────────────┬───────────────────────────┘
                │ ingest pipeline
                ▼
┌───────────────────────────────────────────┐
│     Layer 2: wiki/                        │
│  (LLM‑compiled Markdown)                  │
│  - Summaries, cross‑references            │
│  - Resolved contradictions                │
│  - Chronological evolution               │
│  - Machine‑readable + human‑readable     │
└───────────────┬───────────────────────────┘
                │ query & lint
                ▼
┌───────────────────────────────────────────┐
│     Layer 3: AGENTS.md                    │
│  (Schema & configuration)                │
│  - What to ingest (source list)          │
│  - Synthesis schedule                     │
│  - Prompt templates                       │
│  - Quality thresholds                     │
└───────────────────────────────────────────┘
```

**Key property**: `wiki/` is **derived** — never edit manually; re‑run synthesis to refresh. `raw/` is **immutable** — original sources preserved for audit. `AGENTS.md` is the **control panel**.

## Core Operations

### 1. Ingest

```
Source → Parser → Chunker → Embed → Store
```

**Pipeline**:
- **Crawl**: Discover new sources (RSS, Git commits, research paper alerts, web scrapes)
- **Parse**: Extract text from PDF/HTML/Markdown; handle code blocks
- **Chunk**: Split into semantically coherent pieces (≈500 tokens each)
- **Metadata enrich**: Extract date, author, tags, citations
- **Embed**: Generate vector embeddings for search
- **Store**: Write to `raw/` unchanged; index into vector + metadata DB

**Tools**:
- `cognee add <source>` — adds source to pipeline
- `hermes ingest rss --feed https://... --dest raw/research/`
- `hermes ingest pdf --file paper.pdf --metadata '{"topic":"ML"}'`

### 2. Synthesize (Compile)

```
Raw + Wiki history + Templates + Prompts → LLM → Updated Wiki pages
```

For each topic or concept:
- Gather all `raw/` chunks relevant to topic (via vector retrieval or explicit source list)
- Feed into LLM with instruction: "Synthesize these sources into a coherent, internally consistent article. Resolve contradictions by citing both sides. Include cross‑references to related concepts."
- Output Markdown placed in `wiki/` directory
- If page already exists, diff against previous version; if significant change, mark as "updated"

**Key prompt elements**:
```
You are an expert technical writer maintaining a living knowledge base.

SOURCES:
<chunk1>
---
<chunk2>
...

INSTRUCTIONS:
1. Synthesize all information into a single coherent article.
2. Resolve contradictions explicitly: present both sides with citations.
3. Include a "Related concepts" section linking to: [list of related page titles].
4. Add a "Latest developments" subsection if sources include recent updates.
5. Maintain neutral, encyclopedic tone.
6. Output format: Markdown with H1/H2/H3 headings.
```

### 3. Query

When user asks a question:
- **Search**: Vector similarity + keyword + recency boost
- **Retrieve**: Top‑k relevant wiki pages
- **Rerank**: Cross‑encoder or LLM judge best answer chunks
- **Construct**: Assemble final answer with citations and links back to source pages

Unlike RAG (retrieve at query time), wiki compilation ensures cross‑references and contradictions are pre‑resolved **once**, not re‑derived per query.

### 4. Lint (Health Checks)

Four‑category linting runs daily/weekly:

**Mechanical lint**:
- Broken internal links (page references to non‑existent pages)
- Missing required sections (e.g., no "References" section)
- Stale metadata (modified date > 90 days ago without update)
- Duplicate page titles or slugs

**Semantic lint**:
- Contradiction detection: same fact stated differently in two pages
- Coverage gaps: topic mentioned but no dedicated page
- Circular cross‑references (A → B, B → A)
- Out‑of‑date information (conflict between old sources and recent ones)

**Orphaned pages**: Pages with no inbound links (likely missed cross‑reference)

**Style lint**: Consistent heading hierarchy, code block language tags

Auto‑fix where possible (some require human intervention).

### 5. Feedback Loops

Six feedback cycles (see RESEARCH_SUMMARY.md):

| Loop | Trigger | Action |
|------|---------|--------|
| **Lint → Discover** | New lint warning | Schedule additional source crawl for missing topic |
| **User Correction** | User flags factually wrong page | Re‑synthesize page with corrected prompt; flag for review |
| **Quality Metrics** | Page quality score drops | Prioritize re‑ingest of newer sources on that topic |
| **Cross‑Reference Scan** | New page created without links | Run cross‑reference bot to suggest related pages |
| **Schema Co‑evolution** | `AGENTS.md` updated | Re‑compile entire wiki to reflect new structure |
| **Usage Analytics** | Popular pages get stale | Schedule more frequent re‑synthesis for high‑traffic topics |

## Steps — Implementing Synthesis Skill in Hermes

### Step 1: Set Up Three‑Layer Structure

```
/home/tokisaki/work/synthesis/
├── raw/                    # Immutable sources (git‑tracked or symlinked)
│   ├── research_papers/
│   ├── chat_logs/
│   ├── api_docs/
│   └── user_feedback/
├── wiki/                   # LLM‑compiled markdown (auto‑generated)
│   ├── Hermes_Agent.md
│   ├── TopRank.md
│   └── ...
├── AGENTS.md              # Configuration (see next section)
└── .hermes_synthesis.yaml  # Local settings (excluded from git)
```

`AGENTS.md` example:

```yaml
version: 1.0
sources:
  - type: rss
    url: https://ai-news.tech/rss.xml
    topics: ["LLM", "agents", "synthesis"]
    schedule: "daily 06:00"
  - type: github
    repo: NousResearch/hermes
    path: "/docs"
    watch: true          # auto‑ingest on commit
  - type: note
    path: "~/Notes/Hermes/"   # personal Obsidian vault
    recursive: true

topics:
  - id: hermes-agent
    keywords: ["hermes", "agent", " Nous Research"]
    cross_reference: true
    review_interval_days: 30

templates:
  summary: "prompts/wiki_summary_v2.txt"
  deep_dive: "prompts/wiki_article_v3.txt"

scheduling:
  daily_synthesis: "02:00"     # run nightly
  weekly_full_recompile: "sunday 04:00"
  lint: "daily 03:00"

quality:
  min_source_confidence: 0.7
  require_two_sources: true
  max_age_days: 90  # warn if page not updated in 90d
```

### Step 2: Implement Ingest Pipeline

```bash
# CLI command
hermes ingest --config AGENTS.md --dry-run
```

Python implementation sketch:

```python
class IngestPipeline:
    def __init__(self, config):
        self.sources = config['sources']
        self.raw_dir = Path('raw')

    def run(self):
        for source in self.sources:
            if source['type'] == 'rss':
                items = fetch_rss(source['url'])
                for item in items:
                    self.store_raw(item, source)
            elif source['type'] == 'github':
                commits = watch_github_repo(source['repo'])
                for commit in commits:
                    self.process_file(commit)
            # ...

    def store_raw(self, item, source_meta):
        # Write to raw/ with structured filename
        # e.g., raw/research_papers/2026-04-25-vibe-trading.md
        path = self.raw_dir / source_meta['category'] / f"{date}_{slug}.md"
        path.write_text(item.content)
        index_document(item, path)  # add to vector DB
```

### Step 3: Build Synthesis Engine

```python
class SynthesisEngine:
    def synthesize_topic(self, topic_id: str, config: dict):
        # 1. Retrieve all raw chunks related to topic
        chunks = vector_search(topic_id, top_k=20)

        # 2. Load existing wiki page if any
        existing_page = self.load_wiki_page(topic_id)

        # 3. Construct prompt
        prompt = self.build_prompt(
            topic=topic_id,
            sources=chunks,
            existing=existing_page,
            template=config['templates']['deep_dive']
        )

        # 4. Call LLM (with deterministic seed)
        response = llm_call(
            model="claude-3-5-sonnet-20241022",
            messages=[{"role": "user", "content": prompt}],
            temperature=0.3,
            seed=config.get('deterministic_seed', 42)
        )

        # 5. Parse Markdown, extract cross‑references
        markdown = extract_markdown(response)
        refs = find_cross_references(markdown)

        # 6. Write to wiki/
        output_path = Path(f"wiki/{topic_id}.md")
        output_path.write_text(markdown)

        # 7. Log synthesis event
        self.log_synthesis(topic_id, sources=chunks, output_path)
```

### Step 4: Query Service

```python
class WikiQuery:
    def ask(self, question: str, k: int = 5):
        # Hybrid search: vector + keyword + recency
        results = hybrid_search(question, k=k)
        # Rerank with cross‑encoder or LLM judge
        reranked = self.rerank(question, results)
        # Assemble answer with citations
        answer = self.assemble_answer(reranked)
        return answer
```

Expose via:
- CLI: `hermes wiki ask "What is TopRank?"`
- API: `GET /wiki/query?q=...`
- SSE stream for interactive Q&A

### Step 5: Lint Engine

```bash
hermes wiki lint --fix    # run lint, auto‑fix what we can
```

Linter categories:

```python
class MechanicalLinter:
    def check_broken_links(self, wiki_dir):
        # Find all `[[Page Name]]` wiki links; verify target exists

    def check_missing_sections(self):
        # Each page must have: # Title, ## References, ## See Also

class SemanticLinter:
    def detect_contradictions(self):
        # Use LLM to compare statements across pages on same topic

    def find_orphans(self):
        # Pages with zero inbound links → suggest cross‑reference

class freshness_linter:
    def stale_pages(self, max_age_days=90):
        # Identify pages not updated recently
```

### Step 6: Automated Scheduling

Use cron, systemd timers, or GitHub Actions:

```bash
# crontab -e
0 2 * * * /usr/local/bin/hermes wiki synthesize --all >> /var/log/hermes_synth.log 2>&1
0 3 * * * /usr/local/bin/hermes wiki lint --report-email hermes@nousresearch.com
```

Or use `systemd`:

```
[Unit]
Description=Hermes Daily Synthesis

[Timer]
OnCalendar=daily
Persistent=true

[Service]
Type=oneshot
ExecStart=/usr/local/bin/hermes wiki synthesize --all
```

### Step 7: Version Control & CI

Git‑track `wiki/` and `AGENTS.md` (but **not** `raw/` if sources are external):

```bash
git init synthesis_repo
git add wiki/ AGENTS.md
git commit -m "Daily synthesis $(date)"
git push origin main
```

**CI pipeline**:
1. Lint runs on PR to wiki pages
2. Build preview of affected pages
3. Automated checks: no broken links, quality threshold met
4. Manual review required for cross‑topic changes

### Step 8: Human‑in‑the‑Loop Review

For pages with low confidence or major revisions:
- Open GitHub issue for editor review
- Present diff in Slack/Notion
- Allow manual override with editorial notes

## Feedback Loops in Detail

### Loop 1: Lint → Discover

When linter identifies orphan page or missing topic:
1. Query external sources (Google Scholar, arXiv, GitHub trending)
2. Add new source candidates to `AGENTS.md` pending section
3. Create PR for human approval before next ingest

### Loop 2: User Correction

User submits correction via: `hermes wiki correct --page TopRank --issue "Cost formula wrong"`

1. Correction logged to `corrections.log`
2. Next synthesis run flagged: prompt includes "Previous version had error: {correction}. Ensure accuracy."
3. After re‑synthesis, send review request to user

### Loop 3: Quality Metrics

Automated quality score per page:
- Number of unique sources cited
- Recency of latest source
- Cross‑reference count (inbound + outbound)
- Lint warnings count

Low‑score pages get lower priority in synthesis queue or higher LLM temperature to explore alternative phrasings.

### Loop 4: Cross‑Reference Suggest

When creating page X:
- Vector search finds semantically similar pages Y, Z
- Suggest "[[Y]]" and "[[Z]]" in draft for author approval

### Loop 5: Schema Co‑Evolution

When `AGENTS.md` changes (new template, scheduling change):
- Flag all pages as stale
- Force re‑synthesis with new template across entire wiki
- Preserve old version in history/

### Loop 6: Usage Analytics

Track which pages are read most (via `wiki ask` logging):
- High‑traffic pages scheduled for more frequent refresh (daily vs weekly)
- Low‑traffic pages may be archived

## Deterministic Seeding

Every synthesis run uses configurable seed:

```python
import random
import numpy as np

seed = config.get('seed', 42)
random.seed(seed)
np.random.seed(seed)
# LLM: pass seed parameter if supported; otherwise fix temperature=0 and top_p=1
```

Benefits:
- **Reproducibility**: Bug → fix → same output confirms resolution
- **Audit**: Given raw sources and seed, can regenerate exactly what was deployed
- **A/B testing**: Two prompts with same seed compare output quality

## Configuration‑as‑Code

All synthesis parameters in `AGENTS.md`:
- Source list (RSS feeds, GitHub repos, local directories)
- Topic definitions and keywords
- Prompt templates (stored in `prompts/` directory, referenced)
- Scheduling (cron‑like expressions)
- Quality thresholds and reviewer assignments
- Cross‑reference rules

Changes to config require PR review, just like code.

## Integration with Hermes Daily Consolidation

Cron workflow:

```bash
#!/bin/bash
# /usr/local/bin/hermes_daily_consolidate.sh

# 1. Ingest new sources (RSS, Git commits, daily notes)
hermes ingest --config /home/hermes/AGENTS.md

# 2. Run synthesis for all topics (or just changed ones)
hermes wiki synthesize --incremental

# 3. Lint the wiki
hermes wiki lint --report

# 4. Commit if changes
git add wiki/
git diff --quiet && echo "No changes" || (
    git commit -m "Daily synthesis $(date +%Y-%m-%d)"
    git push origin main
)

# 5. Update search index
hermes wiki reindex
```

Schedule via `crontab` or systemd timer.

## Advanced: GraphRAG with Cognee Patterns

Combine with Cognee for knowledge graph + vector search:

```python
from cognee import Cognee

cog = Cognee()
cog.add(["raw/research/vibe_trading.md", "raw/research/toprank.md"])
cog.cognify()  # extract entities, relationships, build graph
cog.memify()   # store in vector DB

# Query: "Show all risk control patterns from trading research"
results = cog.search("risk control trading", search_type="GRAPH_COMPLETION")
# Returns subgraph of entities + edges (PositionSizing, StopLoss, CircuitBreaker)
```

This augments simple keyword search with graph traversal, answering questions like "What are all the dependencies of TopRank?" or "Which research contributed the risk pattern?"

## Costs & Performance

| Operation | Cost Estimate (monthly, moderate use) | Latency |
|-----------|--------------------------------------|---------|
| LLM synthesis (50 pages × 5 sources each, 20k tokens/page) | $20‑$50 (Claude Sonnet) | 10–30 s/page |
| Vector DB (embeddings: 100k chunks × 1536 dim) | $5‑$15 (Pinecone/Weaviate) | ~50 ms query |
| Storage (wiki pages, raw archives) | <$1 (S3/disk) | negligible |
| Compute (ingest pipeline VM) | $8‑$20 (small EC2/DO) | background |

**Optimizations**:
- Cache embeddings; only re‑embed truly new sources
- Incremental synthesis: re‑run only topics with new sources
- Use smaller/faster model (haiku) for initial draft, then refine only controversial sections with sonnet

## Pitfalls

- **Quality collapse**: LLM may hallucinate or oversimplify complex topics. Mitigate: require ≥2 independent sources per claim; flag unsupported assertions for human review.
- **Contradiction blindness**: LLM may gloss over contradictions. Use explicit contradiction‑detection prompt + separate validation pass.
- **Staleness**: Even with daily ingest, fast‑moving fields may need hourly updates. Some topics need realtime (breaking news) → separate "news" stream.
- **Scope creep**: Wiki never "finished". Set boundaries: what is in‑scope vs out‑of‑scope topics.
- **Storage bloat**: Raw sources accumulate indefinitely. Implement retention policies (keep forever for research, prune for ephemeral news).
- **Self‑reference**: If wiki starts citing itself recursively, degrade signal. Linter should detect excessive self‑citation.
- **LLM cost explosion**: Re‑synthesizing entire wiki daily expensive. Use incremental diffs: only pages with new sources re‑generated.
- **Schema drift**: `AGENTS.md` evolves; old synthesis runs may break. Version config, pin synthesis engine to config schema version.
- **Citation accuracy**: LLM may invent source citations. Require inline citations as `[source_filename]` and validate that filename actually exists in raw/.

## Potential Extensions

- **Multi‑modal synthesis**: Include images, diagrams, code execution results in wiki
- **Collaborative editing**: GitHub PR workflow for human editorial input
- **Distributed synthesis**: Multiple Hermes agents sumbit synthesis suggestions, vote on best version
- **Automatic blog generation**: Transform wiki pages into publishable blog posts with formatting
- **Live preview**: websocket UI showing synthesis progress in real‑time
- **Search analytics**: Track most‑asked questions; prioritize synthesis for gaps

## References

- LLM‑Wiki‑Compiler (Karpathy): https://github.com/karpathy/llm‑wiki‑compiler
- Cognee: https://github.com/topoteretes/cognee (16K stars)
- My‑Brain‑Is‑Full‑Crew: https://github.com/ManuelCBR/My‑Brain‑Is‑Full‑Crew
- Obsidian‑Skills: https://github.com/期限付き /obsidian‑skills (26K stars)
- Configuration‑as‑Code: https://www.thoughtworks.com/radar/techniques/configuration‑as‑code
- Feedback Loops: O'Reilly "Accelerate" (DevOps research) – Six feedback loops taxonomy
- Deterministic seeding: https://github.com/lux‑microscope/luxAI‑seed

---

*End of Synthesis skill documentation*
