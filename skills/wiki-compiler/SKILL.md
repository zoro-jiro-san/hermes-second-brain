---
name: Wiki Compiler
description: Build and maintain an LLM-compiled Markdown wiki from raw sources (raw/ → wiki/). Handles incremental compilation, provenance tracking, and change detection.
trigger: when maintaining a persistent knowledge base that compounds over time
---

# Wiki Compiler

## Overview
Three-layer architecture for persistent, LLM-maintained knowledge bases. Raw sources stay immutable; an LLM agent incrementally compiles them into interlinked Markdown wiki pages with citations, backlinks, and concept articles. Designed for Hermes Second Brain pattern (Karpathy-style LLM Wiki + Cognee GraphRAG augmentation).

## When to Use
- Building a personal/team knowledge base from articles/papers/repos
- Need persistent, human-readable knowledge independent of any LLM session
- Want cross-references, contradiction resolution, and concept taxonomy
- Plan to query the wiki with natural language and feed answers back in

## Setup
```bash
# Directory layout
mkdir -p {raw,raw/articles,raw/papers,raw/repos,wiki,index}

# Initial ingest
# Place source files in raw/ with YAML frontmatter:
# ---
# title: "Article Title"
# source: "https://example.com/article"
# ingested: 2025-04-27
# tags: [ai, agents, architecture]
# ---
```

## Steps

1. **Ingest source** — Drop file into `raw/` (any format: `.md`, `.pdf`, `.html`). Add YAML frontmatter with `title`, `source`, `ingested`, `tags`.
2. **Hash & track** — Compute SHA256 of source; store in `wiki/.ingest_log.jsonl`. Skip re-compilation if hash unchanged.
3. **Invoke LLM compile** — Prompt LLM agent with:
   ```
   You are a librarian. Read this source file. Produce:
   A) A wiki article at wiki/<slug>.md with:
      - Summary paragraph
      - Key concepts as subheadings
      - [[wikilinks]] to other known concepts
      - Citations: ^[source.md]
   B) Update/create index files:
      - wiki/INDEX.md — alphabetical list of all articles
      - wiki/CONCEPTS.md — concept taxonomy with backlinks
   C) If conflicting info with existing articles, add "Contradictions" section.
   ```
4. **Write atomically** — LLM writes to temp file → atomic rename into `wiki/`
5. **Update graph** — Extract entities (people, repos, tech, patterns) and append to `memory/graph.nodes.json`; create edges to related nodes (`research-swarm` + `graph-builder` skills)
6. **Index for search** — Generate vector embedding of article summary; append to `index/vectors.faiss` with metadata pointer
7. **Health check** — Run `hermes-brain-lint` (mechanical: broken links, empty files; semantic: orphaned articles, contradictory claims)
8. **Digest** — Weekly, generate `reports/digest-<date>.md` summarizing new articles, gap analysis, suggested follow-up questions

## Key Patterns
- **Immutable raw/** — Never edit source files; versioned by ingest date
- **LLM as librarian** — Compiles, links, maintains index; human rarely edits wiki directly
- **Provenance via ^[source.md]** — Inline citation format traced back to raw filename
- **Incremental** — Hash-based change detection avoids re-compiling unchanged sources
- **Compounding** — Answers to queries become new wiki pages (feedback loop)
- **Obsidian-ready** — Wiki uses `[[wikilinks]]`; open `wiki/` as Obsidian vault directly

## Pitfalls
- **LLM drift** — Over time, compiled summaries may diverge from sources; periodic re-compile of all sources detects drift
- **Broken wikilinks** — New concepts may link to non-existent articles; lint tool must flag and suggest creation
- **Circular references** — A→B→A loops; detect with cycle-check in lint pass
- **Cost creep** — Large source base → expensive re-index; use incremental hashing
- **Format drift** — LLM may change article structure; enforce schema via validation step

## References
- Inspired by Karpathy's LLM Wiki pattern; implemented in daily-learnings Second Brain
- Cognee integration: `memory/graph.*.json` stores extracted entities; GraphRAG layer in `index/`
- Research sources: `wiki_patterns.md` (architecture), `cognee.md` (graph patterns), `obsidian-headless.md` (vault management)
- Related skills: `graph-builder` (entity extraction), `obsidian-second-brain` (frontend setup)
