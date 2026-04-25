---
name: Research Swarm Orchestration
description: Coordinate parallel subagent teams to research multiple repositories/topics simultaneously, then synthesize results into unified knowledge.
trigger: when researching 5+ repositories or compiling broad domain knowledge
---

# Research Swarm Orchestration

## Overview
Pattern for large-scale knowledge acquisition using parallel subagent workers. Coordinates 3–N concurrent research agents, handles timeouts with fallback strategies, and consolidates outputs into synthesis artifacts.

## When to Use
- Researching 10+ repositories across a domain
- Building knowledge bases from multiple sources
- Time-sensitive research with hard deadlines
- Need for fallback when some sources are unavailable

## Setup
```bash
# Install dependencies
# (none — uses built-in delegate_task orchestration)

# Workspace layout
mkdir -p /path/to/workspace/{inputs,outputs,synthesis}
```

## Steps

1. **Define research targets** — Create list of N repositories/topics to investigate
2. **Batch into groups of 3** — Split targets into chunks matching `delegation.max_concurrent_children` (default 3)
3. **Spawn orchestrator batches** — Use `delegate_task(role='orchestrator')` → each spawns 3 leaf workers
   ```python
   delegate_task(
       role='orchestrator',
       tasks=[...3 research tasks per batch...]
   )
   ```
4. **Worker agent prompt** — For each target:
   - Clone repo if network available; else fall back to knowledge synthesis from training
   - Extract architecture, patterns, tools, integration opportunities
   - Write Markdown report to `outputs/research_<slug>.md` with YAML frontmatter
   - **NO shell commands** in final output — only `write_file` to save report
5. **Handle timeouts** — If batch times out (>300s), retry with 2-agents-per-batch; if individual agent stalls, re-spawn single agent with same task
6. **Synthesis phase** — After all reports exist:
   - Generate skill files per report (see `skill-factory` skill)
   - Build entity extraction + relationship graph (see `graph-builder` skill)
   - Produce KEEP/ADAPT/DISCARD recommendations
7. **Verification** — Count outputs + checksum; re-run any missing targets
8. **Commit & push** — One commit per logical change (restructure, skills, graph, docs)

## Key Patterns
- **Unlimited timeout** — Set `timeout=None` or large value (≥600) for synthesis agents
- **Fallback chain** — clone → local search → knowledge synthesis (LLM training data)
- **Idempotent outputs** — Deterministic filenames, overwrite-safe writes
- **Progress tracking** — Count files in `outputs/` vs. target list
- **Error isolation** — Single agent failure doesn't cascade; re-spawn only failed tasks

## Pitfalls
- **Too-large batches** — spawning 4+ agents exceeds `max_concurrent_children`; split into batches of 3
- **Network dependency** — some agents may block on `git clone`; include fallback prompt explicitly
- **Output collisions** — ensure unique filenames (slugify repo names)
- **Memory leaks** — agents processing 10+ MB files need `read_file` pagination; don't read whole file at once
- **Silent failures** — agents may exit without writing; check file existence after each batch

## References
- This skill extracted from `research_agentic_stack.md`, `research_openhands.md`, `research_cognee.md`
- Pattern used in daily-learnings research swarm (24 repos, 385 edges)
- Related: `skill-factory` (downstream processing), `graph-builder` (knowledge consolidation)
