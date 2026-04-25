---
name: "Obsidian Headless: Knowledge Graph & Plugin Architecture"
description: "Skills and patterns extracted from Obsidian Headless research: markdown-based knowledge graphs, note linking, and plugin-based extensibility."
trigger: "when working with knowledge organization, note linking systems, or plugin architectures"
---

# Obsidian Headless: Knowledge Graph & Extensibility Patterns

## Overview
This skill synthesizes patterns from **Obsidian Headless** — the server-side, headless version of Obsidian. It provides a model for markdown-based note management, bi-directional linking, graph-based knowledge organization, and a robust plugin architecture. These patterns are highly applicable to building AI assistant knowledge management and extensible skill systems.

## What It Does
- **Markdown vault management**: Structured note storage with frontmatter and metadata
- **Bi-directional linking**: Wikilinks, backlinks, tag-based connections forming a knowledge graph
- **Graph visualization**: Force-directed layouts, clustering, temporal ordering
- **Plugin system**: Modular skill/plugin loading with lifecycle management, dependency injection, and event systems
- **Sync/replication**: Two-way sync, change tracking, conflict resolution

## When to Use
- Building knowledge base systems for AI agents
- Implementing graph-based knowledge representation
- Designing plugin architectures for extensible AI skills
- Creating note-taking or documentation systems with rich linking
- Supporting non-linear, associative knowledge organization

## Setup
Read the full research at: `/home/tokisaki/work/research-swarm/outputs/research_obsidian_headless.md`

## Implementation Steps
1. Adopt the note/link data model: `MarkdownFile` entities with `Link` relationships
2. Build a vault abstraction: root directory, file scanning, frontmatter parsing
3. Implement wikilink parsing: `[[Note Name]]` detection and resolution
4. Generate and maintain knowledge graph: in-memory cache + change detection
5. Add graph visualization endpoints: node/edge JSON with filter options
6. Implement the plugin architecture:
   - Define `HermesSkill` interface with `initialize()` and `execute()`
   - Build a `SkillManager` for discovery, loading, and lifecycle
   - Add dependency resolution and hot-reload capabilities
7. Consider bi-directional link indexing for backlink discovery
8. Integrate tag-based categorization and auto-tagging
9. For Hermes daily-learnings: convert free-form notes to linked vault structure

## Key Patterns Extracted
### Data Model
- `MarkdownFile`: id, path, content, frontmatter, timestamps
- `Link`: source, target, linkText, position
- `GraphNode`/`GraphEdge` types: file/tag/external nodes; link/tag/embed edges

### Graph Operations
- Recursive scanning + markdown link extraction
- Real-time updates via filesystem watcher
- Graph caching for performance; rebuild on changes
- Visualization: force-directed, hierarchical, temporal, community clustering

### Plugin System
- `Plugin` interface: `id`, `name`, `version`, `load(app)`, `onunload?()`
- `App` context providing: vault, metadataCache, workspace, events
- Extension points: commands, views, modifiers, processors
- Security: sandboxed execution (optional), permissions, resource limits

## Pitfalls
- Graph can become sparse and unwieldy at scale; implement partial loading and filters
- Circular linking can create unresolvable dependencies; detect and warn
- Plugin isolation is critical to prevent privilege escalation; enforce capability-based permissions
- Conflict resolution during sync needs clear policies (last-write-wins vs manual)
- Avoid over-linking: too many weak connections dilute signal

## References
- Research: `research_obsidian_headless.md`
- Obsidian plugin docs: https://docs.obsidian.md/Plugins
