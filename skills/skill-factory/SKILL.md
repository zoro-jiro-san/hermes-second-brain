---
name: Skill Factory
description: Systematically convert research reports (Markdown) into standardized SKILL.md files with YAML frontmatter, integration steps, pitfalls, and references.
trigger: when synthesizing knowledge from research articles into executable skills
---

# Skill Factory

## Overview
Pipeline that ingests research reports and produces standardized `SKILL.md` artifacts. Extracts frontmatter metadata, Integration Opportunities sections, and transforms them into actionable skill definitions with concrete steps, pitfalls, and citations.

## When to Use
- After completing research swarm phase
- Converting documentation into executable skills
- Standardizing skill format across a knowledge base
- Building skill catalogs from external sources

## Setup
```bash
# Input: research reports at /path/to/research-swarm/outputs/research_*.md
# Output: /path/to/synthesis/skills/<slug>/SKILL.md

mkdir -p /path/to/synthesis/skills
```

## Steps

1. **Discover all research files** — Glob `research_*.md` in source directory
2. **Parse frontmatter** — Extract `title`, `repo`, `date`, `status` using regex `---(.*?)---`
3. **Derive slug** — `filename.replace('research_','').replace('_','-')`
4. **Extract Integration Opportunities** — Regex capture `## Integration Opportunities.*?(?=\n##|\Z)`
5. **Generate SKILL content** — Fill template:
   ```
   ---
   name: "{title}"
   description: "Patterns from {repo} for Hermes"
   trigger: "{slug} workflows"
   ---
   # {title}
   
   ## Source
   - Repo: [{repo}](https://github.com/{repo})
   - Research: {filename}
   
   ## Integration Opportunities
   {integration_text}
   
   ## Steps
   1. Read full research: outputs/{filename}
   2. Review integration patterns above
   3. Map to Hermes architecture
   4. Implement incrementally with tests
   5. Document in ARCHITECTURE.md
   
   ## Pitfalls
   - Verify Hermes compatibility before adopting
   - Ensure error handling + logging
   - Add unit tests for new functionality
   
   ## References
   - Research: {filename}
   - GitHub: https://github.com/{repo}
   ```
6. **Write file** — Create `skills/<slug>/SKILL.md` atomically (`write_file` or `os.makedirs` + write)
7. **Handle empty/missing research** — If file is 0 bytes or missing integration section, insert placeholder: `"Research content unavailable — rerun research generation for this repo."`
8. **Validate** — Check all SKILL.md files have YAML frontmatter and non-empty Steps section
9. **Index** — Update skill catalog (optional: generate `skills/INDEX.md`)

## Key Patterns
- **Template-driven** — Single string template with `.format()` substitution; consistent structure across all skills
- **Fallback handling** — Empty research → placeholder skill with error note; no crash
- **Slug normalization** — Underscores→dashes; keeps names URL-safe
- **Provenance tracking** — Each skill cites source file + GitHub URL
- **Batch processing** — Process 8 skills per agent to avoid timeout; total 24 skills → 3 batches

## Pitfalls
- **Malformed frontmatter** — Some research reports may have missing/empty fields; use filename fallbacks
- **Huge integration sections** — Can exceed token limits; truncate in skill summary, preserve full text in source reference
- **Duplicate slugs** — Two repos with similar names (e.g., `cognee` vs `cognee-cloud`) — ensure unique directory names
- **Broken links** — GitHub URLs may be incorrect; validate with regex or skip if malformed
- **Encoding issues** — Research files may contain special characters; read as UTF-8, sanitize for Markdown

## References
- Implemented in daily-learnings synthesis (24 skills generated)
- Extracted from: `research_awesome_opensource_ai.md`, `research_openhands.md`, `research_cognee.md`, etc.
- Related: `research-swarm` (upstream), `wiki-compiler` (downstream)
