---
name: "Mattpocock Skills: Teaching Pattern Framework"
description: "Skills and patterns extracted from mattpocock/skills research on structured teaching, skill graphs, and progressive learning systems."
trigger: "when working with teaching patterns, skill graphs, or educational curriculum design"
---

# Mattpocock Skills: Structured Teaching & Skill Graph Patterns

## Overview
This skill captures key patterns and practices from [mattpocock/skills](https://github.com/mattpocock/skills), a repository focused on structured teaching, skill decomposition, prerequisite graphs, and progressive learning patterns. These patterns are directly applicable to agent training, skill orchestration, and curriculum learning in autonomous systems like Hermes.

## What It Does
Provides a framework for:
- Decomposing capabilities into modular, composable skill units
- Representing skills as a directed acyclic graph (DAG) of prerequisites
- Defining progressive difficulty levels with explicit mastery criteria
- Implementing assessment checklists and validation mechanisms
- Supporting adaptive learning paths and personalized skill sequencing

## When to Use
- Designing agent training curricula or skill acquisition systems
- Structuring skill registries with clear dependencies
- Building systems for progressive capability unlock
- Creating assessment frameworks for agent capabilities
- Implementing multi-agent orchestration based on skill proficiency

## Setup
Read the full research at: `/home/tokisaki/work/research-swarm/outputs/research_mattpocock_skills.md`

## Implementation Steps
1. Review the skill pattern schema: `name`, `description`, `category`, `levels`, `prerequisites`, `verification`
2. Map Hermes existing capabilities to skill units, identifying prerequisite relationships
3. Build or integrate a graph database to store skill nodes and edges
4. Implement skill proficiency tracking per agent
5. Create query API: "What is the next recommended skill for agent X given goal Y?"
6. Integrate skill-aware planning into task generation and assignment
7. Add validation tasks for skill mastery demonstration (mini-projects, tests)
8. Implement feedback loops: log outcomes, analyze failures, refine difficulty curves

## Key Patterns Extracted
- **Modular Skill Units**: Each skill as a structured markdown/YAML file with metadata and levels
- **Prerequisite DAG**: Skills linked via prerequisites; advanced skills require foundational mastery first
- **Progressive Difficulty**: Shallow initial curve, steepening as integration complexity increases
- **Checklist Assessment**: Observable, binary criteria per level for objective evaluation
- **Project-Based Validation**: Higher levels require integrative mini-projects combining multiple skills
- **Feedback Loops**: Short-cycle reviews, skill retrospectives, community-driven evolution, metrics-guided iteration

## Pitfalls
- Avoid overly granular skills that create excessive management overhead
- Ensure prerequisite cycles are detected and prevented (DAG invariant)
- Balance automation (tests) with human/mentor review for complex skills
- Track skill usage metrics to identify outdated or mis-calibrated levels
- Consider skill decay: periodically re-validate proficiency for critical skills

## References
- Research: `research_mattpocock_skills.md`
- Source: https://github.com/mattpocock/skills
