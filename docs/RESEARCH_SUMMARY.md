# Research Summary: Hermes Second Brain Architecture

## Research Conducted

### 1. LLM-Compiled Wiki Pattern (Karpathy 2026)
**Sources examined**: Dev.to guide, multiple Medium articles, original GitHub gist

**Key findings**:
- Three-layer architecture: raw/ (immutable sources) → wiki/ (LLM-maintained markdown) → AGENTS.md (schema configuration)
- Core operations: ingest (process sources), query (ask questions), lint (health checks)
- Compounding knowledge loop: good answers saved back to wiki
- Works at personal/team scale: 50-400 sources, 100K-400K words
- Real-world implementations: llm-wiki-compiler (TypeScript), various community projects

### 2. Cognee Knowledge Engine
**Sources examined**: GitHub repository (16K stars), documentation, tutorial notebooks

**Key findings**:
- Pipeline: `cognee.add()` → `cognee.cognify()` → `cognee.memify()` → `cognee.search()`
- GraphRAG capability: combines vector search with Neo4j knowledge graphs
- CLI tool: `cognee-cli` with `add`, `cognify`, `search` commands
- Multi-database support: Neo4j, networkx, LanceDB, SQLite
- Search types: GRAPH_COMPLETION, RAG_COMPLETION, CHUNKS, CYPHER
- Continual learning from feedback and cross-agent knowledge sharing

### 3. Repository Analysis
**My-Brain-Is-Full-Crew** (2.8K stars):
- Crew of 8+ AI agents managing Obsidian vault
- Specialized skills: transcription, filing, nutrition, mental wellness
- Chat-based interface; no manual file operations
- Agent coordination via dispatcher
- Multi-language support

**Obsidian-Skills** (26K stars):
- Agent skills for Claude Code/Codex
- Covers Markdown editing, Bases (tables), JSON Canvas, CLI operations
- Follows Agent Skills specification

### 4. Additional Patterns Researched
- Health check/linting implementations (mechanical + semantic layers)
- Scheduling patterns (cron, systemd, GitHub Actions)
- Feedback loops (lint → discover → ingest)
- Cost and performance benchmarks
- Obsidian integration strategies

---

## Deliverable

**Created**: `/home/tokisaki/work/synthesis/wiki_patterns.md`

**Content**: Comprehensive 1166-line design document covering:
1. ✅ Architecture for LLM-compiled wiki (three-layer structure)
2. ✅ Health checks/linting patterns (4 categories with auto-fix)
3. ✅ CLI tool specification (15+ commands with stack details)
4. ✅ Obsidian integration strategy (4 integration modes)
5. ✅ Cron schedule for daily/weekly/monthly updates
6. ✅ Feedback loops (6 distinct loops documented)

**Document sections**:
- Executive Summary
- Pattern Research Summary (all 4 sources synthesized)
- Architecture Overview (system context, design goals)
- Three-Layer Architecture (detailed directory structures, templates)
- Core Operations (ingest pipeline, query service, lint operation)
- CLI Tool Specification (command set, implementation stack)
- Health Checks & Linting (taxonomy, pipeline, report format)
- Obsidian Integration Strategy (4 modes, configuration)
- Scheduling & Automation (cron, systemd, GitHub Actions examples)
- Feedback Loops (6 self-improving cycles)
- Implementation Roadmap (6 phases, 20 weeks)
- Cost & Performance Estimates
- Risks & Mitigations

---

## Key Insights

**Why LLM Wiki beats RAG**:
- Knowledge compiled once vs re-derived per query (10× cost reduction)
- Cross-references and contradictions pre-resolved
- Human-readable artifact independent of LLM vendor
- Compounding: answers become part of knowledge base

**Cognee's value-add**:
- Knowledge graph abstraction layer
- GraphRAG for advanced retrieval
- Temporal awareness for time-aware queries
- Multi-modal ingestion (text, PDFs, audio, images)

**Observations from community**:
- Linting is critical; wikis decay without weekly health checks
- Index-based query works up to ~1000 pages; beyond that need vector/graph augmentation
- Schema co-evolution essential; AGENTS.md evolves with usage
- Cost-effective: $10–$50/month for active researcher

---

## Implementation Roadmap

The design document outlines a 20-week implementation plan with clear phases:

**Phase 1–3** (Weeks 1–9): Core MVP, enhanced compilation, advanced query/GraphRAG
**Phase 4** (Weeks 10–12): Health & automation with scheduled upkeep
**Phase 5** (Weeks 13–15): Obsidian integration via live sync and MCP server
**Phase 6** (Weeks 16–20): Scale & polish for team production use

---

## Files Created

- `/home/tokisaki/work/synthesis/wiki_patterns.md` (40,384 bytes, 1166 lines)

---

## No Issues Encountered

All research completed successfully. Comprehensive web searches and GitHub exploration yielded sufficient detail. No blocking problems.

---

## Status: Complete

The design document provides a thorough, implementable blueprint for the Hermes Second Brain system, synthesizing state-of-the-art patterns from Karpathy's LLM Wiki, Cognee's knowledge graphs, and community implementations. Ready for architecture review and phase 1 kickoff.
