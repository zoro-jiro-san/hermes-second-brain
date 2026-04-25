---
name: claude-task-master
description: AI-powered project planning and task management system — recursive task decomposition, DAG-based dependency tracking, and artifact generation via Claude API.
version: 1.0.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [project-planning, task-management, ai-planner, dag, workflow, claude-api]
    related_skills: [hermes-agent, agentic-stack]
---

# Claude Task Master — AI Project Planner

Claude Task Master is an AI pair planner that recursively decomposes complex goals into granular, implementable subtasks, tracks dependencies via a DAG, manages artifacts, and provides an "intelligent next action" recommendation engine. Use this skill when Hermes needs structured planning, scope management, or persistent project state across sessions.

## When to Use

Trigger when the user:
- Wants to break down a large, vague project into concrete executable steps
- Needs dependency-aware task ordering and progress tracking
- Requires persistent project state (across multiple Hermes sessions)
- Asks for artifact/file scaffolding linked to specific tasks
- Prefers CLI-first, JSON/Markdown/Mermaid output formats
- Needs to manage multiple work sessions with isolation and rollback capability
- Is building a complex system that benefits from hierarchical planning

## Prerequisites

- Install: `npm install -g @chainyo/claude-task-master` or clone the repo
- API key: `ANTHROPIC_API_KEY` set in environment
- Optional: Configure model in `.taskmaster/config.json`
- Storage: Project must have write access for `.taskmaster/` directory

## Quick Reference

```bash
# Initialize new project
taskmaster init "My Project"
# Add epic-level task
taskmaster add "Build user authentication system"
# AI breakdown into subtasks
taskmaster breakdown T1
# See recommended next task
taskmaster next
# Start/complete tasks
taskmaster start T1.2
taskmaster complete T1.2
# View project status tree
taskmaster status
# Manage artifacts (generated files)
taskmaster artifact add T1.2 ./src/auth.ts
# Create named work session
taskmaster session create "Sprint 1"
# Export to various formats
taskmaster export --format markdown
```

## Core Patterns & Data Model

**Task Entity** (recursive):
```typescript
interface Task {
  id: string
  title: string
  description: string
  status: "pending" | "in_progress" | "completed" | "blocked"
  priority: number  // 1 (high) to 5 (low)
  dependencies: string[]  // prerequisite task IDs
  subtasks: Task[]  // recursive
  artifacts: Artifact[]  // generated files/folders
  estimatedEffort?: string  // e.g., "2h", "1d"
  sessionId?: string
}
```

**Artifact**: File or folder linked to a task.
**Session**: Named work period with snapshot of completed tasks.

**Storage**: Single JSON file (e.g., `.taskmaster/tasks.json`) + artifact files on disk.

## Steps — Integration with Hermes Agent

### Mode 1: Hermes as TaskMaster Executor (Recommended)
Hermes receives tasks from TaskMaster and performs actual implementation:

1. **User asks Hermes**: "Plan and build a REST API for user management"
2. **Hermes invokes TaskMaster** (via CLI or Python SDK wrapper):
   ```python
   result = subprocess.run(["taskmaster", "breakdown", "T1"], capture_output=True)
   task_tree = parse_output(result.stdout)
   ```
3. **Hermes executes tasks** sequentially:
   - Query `taskmaster next` to get highest-priority ready task
   - Mark as in_progress: `taskmaster start <id>`
   - Perform implementation (coding, testing, documentation)
   - Create artifacts: `taskmaster artifact add <id> <path>`
   - Mark complete: `taskmaster complete <id>`
4. **Hermes reports** results to user and updates task status

**Benefits**: Clear separation of planning (TaskMaster) and execution (Hermes intelligence). TaskMaster provides structured queue; Hermes provides adaptive problem-solving.

### Mode 2: TaskMaster as Hermes Subsystem
Embed TaskMaster's engine directly as Hermes's planning module:

1. Replace Hermes's simple job queue with TaskMaster's DAG scheduler
2. Use TaskMaster's AI breakdown when request complexity exceeds threshold (e.g., "build a microservice")
3. Share persistent store: Hermes jobs become TaskMaster tasks
4. Leverage artifact tracking for Hermes-generated files
5. Implement custom status callbacks (Hermes → TaskMaster) for real-time sync

**Implementation notes**:
- Use TaskMaster's JSON storage format for interoperability
- Expose CRUD operations via a Python wrapper around TaskMaster's storage
- Consider using `taskmaster export` to sync with external dashboards

### Mode 3: Hybrid — TaskMaster for Planning, Hermes for Execution & Adaptation
For dynamic projects where plans change:
- Initial breakdown via TaskMaster
- As Hermes works, it may discover new subtasks or dependencies
- Inject new tasks into TaskMaster's JSON store using direct file manipulation or a custom API bridge
- Re-run `taskmaster status` to re-evaluate critical path

## Triggers — Automated Planning Scenarios

| User Request | Action |
|--------------|--------|
| "Plan X and build it" | Create project → breakdown epic → execute |
| "What should I work on next?" | Query `taskmaster next` and suggest |
| "Show me project progress" | Render `taskmaster status --tree` with visual progress bars |
| "Break down task T15 further" | `taskmaster breakdown T15` (re-decompose) |
| "I'm blocked on T3" | Mark `taskmaster block T3`, re-run `next` to find alternative work |
| "Undo to session S1" | `taskmaster revert S1` to roll back |

## Pitfalls

- **API costs**: Each breakdown calls Claude API; use judiciously for large epics only. Cache breakdown results.
- **Breakdown quality varies**: Claude sometimes produces overlapping or ambiguous subtasks. Always review breakdowns; manual refinement may be needed.
- **Granularity balance**: Too coarse → subtasks still overwhelming; too fine → overhead. Aim for 1–4 hours per atomic subtask.
- **Dependency hell**: Complex interdependencies can create scheduling bottlenecks. Review the DAG; consider merging or splitting blocked tasks.
- **Session proliferation**: Each named session creates a snapshot. Archives can grow; prune old sessions periodically.
- **Storage format coupling**: TaskMaster uses a proprietary JSON schema. If building deep integration, pin to a specific TaskMaster version to avoid breaking changes.
- **Artifact management**: Files created via `artifact add` are just tracked, not generated by TaskMaster itself. Hermes must create actual files separately.
- **Model drift**: Prompt templates may degrade as Claude versions change. Monitor breakdown quality over time; re-prompt if results worsen.

## Configuration

```json
{
  "version": "1.0",
  "project": {"name": "...", "description": "..."},
  "tasks": {...},
  "sessions": {...},
  "settings": {
    "model": "claude-3-5-sonnet-20241022",
    "maxSubtasks": 10,
    "breakdownTemperature": 0.3
  }
}
```

## References

- GitHub: https://github.com/chainyo/claude-task-master
- Original: https://github.com/eyaltoledano/claude-task-master
- CLI docs: `taskmaster --help`
