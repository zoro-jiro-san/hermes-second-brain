---
name: Everything Claude Code
description: Collection of proven Claude Code CLI patterns for terminal automation, file system operations, project detection, prompt engineering, and error recovery to enhance Hermes's tooling and robustness
trigger: Need to improve Hermes CLI reliability, implement robust error recovery, optimize file operations, and adopt proven prompt engineering patterns for autonomous task execution
---

## Overview

`everything-claude-code` is a curated collection of Claude Code snippets, patterns, and best practices contributed by the community. It covers practical usage of the Claude Code CLI and demonstrates how to leverage Claude's built-in tools (Bash, Grep, Glob, Edit, Read, Write, Task, TodoWrite/TodoRead, Think) to automate development workflows, manage multi-step tasks, handle files, and interact with projects reliably.

The repository is organized into topical folders:
- **terminal/** — Shell automation, pipeline patterns, environment manipulation
- **filesystem/** — Navigation, multi-file editing, diff-aware replacements
- **detection/** — Project type heuristics, config discovery, git awareness
- **prompts/** — Prompt templates that maximize LLM reliability (output format, chain-of-thought, few-shot)
- **recovery/** — Error handling, retry strategies, verification loops

Each snippet includes description, exact Claude Code invocation (or natural-language prompt), and expected outcome, making it easy to adapt to similar contexts.

## Top Patterns Identified

### 1. CLI & Terminal Automation

**Core Tools**: Bash tool, environment variable capture, subshells, pipelines.

**Common Patterns**:
- **Sequential command chains** with `&&` to ensure each step succeeds:
  `Bash: "git pull && npm install && npm run build"`
- **Output capture** using command substitution:
  `Bash: "VERSION=$(node -p 'require(\"./package.json\").version')"; echo $VERSION`
- **Conditional execution** based on exit codes or output parsing:
  `Bash: "if grep -q 'ERROR' log.txt; then echo 'found error'; fi"`
- **Looping over files** with `for` or `find -exec` for batch operations
- **Job control** with background `&` and `wait` for parallel steps when appropriate
- **Temporary files** and `trap` to clean up resources even on failure

Reliable automation requires atomic, observable steps. Claude Code snippets emphasize explicit `set -e` (exit on error) and careful output parsing.

### 2. File System Navigation & Code Editing

**Core Tools**: Glob, Grep, Read, Edit, Write.

**Common Patterns**:
- **Finding files recursively**: `Glob: "**/*.ts"` — then iterate and apply edits
- **Targeted search**: `Grep: "TODO|FIXME"` to locate hotspots for refactoring
- **Reading ranges**: `Read: path/to/file, offset=100, limit=50` — avoids flooding context
- **Precise edits** using exact `old_string` matching; when fails, fetch fresh content and recompute
- **Multi-file patches** (V4A format) for bulk changes: single diff updates dozens of files reliably
- **File creation** with `Write` when new assets needed (config files, test stubs)
- **Directory operations** via Bash when needed: `Bash: "mkdir -p src/generated"`

Atomic, idempotent edits reduce drift. Repo stresses verifying after each edit with follow-up `Read` or `Grep` to confirm.

### 3. Environment & Project Detection

**Heuristics**: Presence of config files, dependency manifests, git metadata, environment variables.

**Common Patterns**:
- **Package manager detection**: `if [ -f package.json ]; then echo "node"; elif [ -f pyproject.toml ]; then echo "python"; fi`
- **Framework detection**: Look for key directories (`src/`, `app/`, `tests/`) or files (`Cargo.toml`, `go.mod`, `Dockerfile`)
- **Git awareness**: `git rev-parse --is-inside-work-tree && git config --get remote.origin.url`
- **Environment loading**: `source .env 2>/dev/null` or parse `.env` file manually
- **OS detection**: `uname` to adapt commands (e.g., `sed -i` vs `sed -i ''`)

Automation should adapt to project context. Heuristics choose correct build/test commands and set intelligent defaults.

### 4. Prompt Templates That Maximize Reliability

**Principles**: Clear roles, step-by-step reasoning, output constraints, examples.

**Template Structure**:
1. **Role** — "You are an expert CLI assistant for [domain]."
2. **Context** — Provide relevant file paths, snippets, and environment details
3. **Task** — Explicit instruction: "Generate a bash script to ..."
4. **Constraints** — "Output only the script, no explanations. Use set -euo pipefail."
5. **Examples** — One or two few-shot examples to demonstrate format
6. **Chain-of-Thought trigger** — "Think step by step before writing the script."
7. **Verification** — "After writing, verify that the script would succeed by mentally tracing it."

**Variations**:
- XML/JSON delimiters to extract structured data: `<response>...</response>`
- Negative instructions: "Do not use sudo. Do not overwrite existing files."

Poorly framed prompts lead to ambiguous output, extra parsing, and failures. Templates consistently yield parseable, executable results.

### 5. Error Recovery Strategies

**Philosophy**: Expect partial failure; decompose; verify; retry with adaptation.

**Common Strategies**:
- **Check-then-act**: Before editing, `Read` target area; after `Edit`, `Grep` to confirm change
- **Idempotent re-runs**: Design scripts to succeed even if already applied (e.g., `mkdir -p`, `git checkout` if already on branch)
- **Graceful fallbacks**: If `Glob` returns no matches, try broader pattern or fall back to default path
- **Retry loops** with exponential backoff for flaky commands (network calls, compilation)
- **Progress tracking** via `TodoWrite`/`TodoRead` so long task can be resumed after interruption
- **Error-aware prompting**: When step fails, feed error back to Claude and ask for revised plan

Automation scripts often run unattended. Built-in recovery reduces manual intervention and increases robustness.

## Adaptation Suggestions for Hermes

### CLI Improvements (`cli/bin/brokerbot.ts`)

**Pattern: Interactive AI-Assisted Commands**
- **From**: `terminal/ai-assist.md` — Use Claude within CLI to generate complex flags or payloads
- **Adaptation**: Add `--ai` flag to commands requiring rich input. Example:
  ```bash
  brokerbot screen --name "Acme Corp" --ai-suggest
  ```
  CLI constructs prompt using template pattern, calls Claude via internal service, suggests jurisdiction, budget, SLA based on company context.

**Implementation**:
```typescript
// In cli/commands/screen.ts
import { suggestScreenParams } from '@/lib/ai/suggest';

program
  .command('screen')
  .option('--ai-suggest', 'Use AI to suggest missing parameters')
  .action(async (opts) => {
    if (opts.aiSuggest && !opts.jurisdiction) {
      const suggestion = await suggestScreenParams({ name: opts.name, domain: opts.domain });
      opts.jurisdiction = suggestion.jurisdiction;
      opts.budget = suggestion.budget;
      opts.sla = suggestion.sla;
    }
    // proceed with existing logic
  });
```

**Pattern: Multi-Step Task Orchestration with Todo**
- **From**: `recovery/todo-orchestration.md` — Use `TodoWrite`/`TodoRead` to manage long-running CLI operations
- **Adaptation**: For commands invoking several API calls (e.g., `screen` → `escrow create` → `fund`), use persistent todo file so user can resume if interrupted.
- Use TodoWrite to track completed steps; on restart, read todo to know where to resume.

### Agent Worker Resilience (`scripts/agent-worker.ts`)

**Pattern: Retry with Exponential Backoff**
- **From**: `recovery/retry-pattern.md` — Wrap flaky calls in generic `retry` helper
- Current code exits after single failure; could keep trying with backoff.

**Implementation**:
```typescript
async function withRetry<T>(
  fn: () => Promise<T>,
  maxAttempts = 5,
  baseDelay = 1000
): Promise<T> {
  let lastError;
  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      return await fn();
    } catch (e) {
      lastError = e;
      if (attempt < maxAttempts) {
        const delay = baseDelay * 2 ** (attempt - 1);
        await new Promise(r => setTimeout(r, delay));
      }
    }
  }
  throw lastError;
}

// In agentTick, wrap external calls
const result = await withRetry(() => agentTick());
```

**Pattern: Progress Persistence with Todo**
- **From**: `recovery/todo-persistence.md` — Write progress after each sub-task; resume from last completed
- **Adaptation**: Agent tick may consist of multiple steps (fetch jobs → process → update DB). Record completion markers in local file or DB keyed by tick ID.

```typescript
import { TodoList } from '@/lib/agent/todo';

async function agentTick() {
  const todo = new TodoList('agent-tick-state.json');
  if (!todo.has('fetch-jobs')) {
    const jobs = await fetchDueJobs();
    todo.add('fetch-jobs', { count: jobs.length });
  }
  if (!todo.has('process-jobs')) {
    await processJobs(todo.get('fetch-jobs').jobs);
    todo.add('process-jobs', { success: true });
  }
  // ... clear on completion
  return { tick: Date.now(), completed: true };
}
```

### Tool Invocation Reliability (`cli/lib/client.ts`)

**Pattern: Intelligent Retry & Circuit Breaker**
- **From**: `recovery/circuit-breaker.md` — Track success rates; temporarily disable failing endpoint
- Current `call` function throws on non-OK responses. Add: retry on 429/5xx with jitter, timeout enforcement, circuit breaker to avoid hammering down service.

**Implementation**:
```typescript
class CircuitBreaker {
  private failures = 0;
  private state: 'CLOSED' | 'OPEN' | 'HALF' = 'CLOSED';
  private lastFailure = 0;
  private readonly threshold = 5;
  private readonly timeout = 30_000; // 30s

  async execute<T>(fn: () => Promise<T>): Promise<T> {
    if (this.state === 'OPEN') {
      if (Date.now() - this.lastFailure > this.timeout) {
        this.state = 'HALF';
      } else {
        throw new Error('Circuit OPEN');
      }
    }
    try {
      const result = await fn();
      this.failures = 0;
      this.state = 'CLOSED';
      return result;
    } catch (e) {
      this.failures++;
      this.lastFailure = Date.now();
      if (this.failures >= this.threshold) this.state = 'OPEN';
      throw e;
    }
  }
}

// Updated call()
const breaker = new CircuitBreaker();

export async function call(method, path, body) {
  return await breaker.execute(async () => {
    const res = await fetch(/* ... */);
    // ... same as before
  });
}
```

**Pattern: Environment / Project Detection for Config**
- **From**: `detection/config-heuristics.md` — Auto-discover `.env` files and set defaults
- **Adaptation**: `loadConfig()` currently reads process.env only. Enhance to look for `.env` in cwd and parent dirs; detect `NEXT_PUBLIC_BROKERBOT_URL` from next.config if present.

```typescript
import fs from 'fs';
import path from 'path';

function loadEnvFile(filePath: string): Record<string, string> {
  const lines = fs.readFileSync(filePath, 'utf-8').split('\n');
  const env: Record<string, string> = {};
  for (const line of lines) {
    const match = line.match(/^([\w.]+)\s*=\s*(.*)$/);
    if (match) env[match[1]] = match[2].replace(/^["']|["']$/g, '');
  }
  return env;
}

function findEnvFile(startDir = process.cwd()): string | null {
  let dir = startDir;
  while (dir !== path.dirname(dir)) {
    const p = path.join(dir, '.env');
    if (fs.existsSync(p)) return p;
    dir = path.dirname(dir);
  }
  return null;
}

export function loadConfig(): ClientConfig {
  const envFile = findEnvFile();
  const fileEnv = envFile ? loadEnvFile(envFile) : {};
  const merged = { ...fileEnv, ...process.env };

  return {
    base_url: merged.BROKERBOT_API_URL ?? merged.NEXT_PUBLIC_BROKERBOT_URL ?? 'http://localhost:3000',
    api_key: merged.BROKERBOT_API_KEY ?? 'dev_change_me',
  };
}
```

## Implementation Priority

| Priority | Area | Pattern | Effort | Impact |
|----------|------|---------|--------|--------|
| Quick Wins | `cli/lib/client.ts` | Retry with backoff | Low (1–2 hrs) | High — prevents transient failures from breaking flows |
| Quick Wins | `cli/lib/client.ts` | `.env` auto-discovery | Low (1 hr) | Medium — improves UX in local dev |
| Quick Wins | `scripts/agent-worker.ts` | Circuit breaker | Low (1–2 hrs) | High — protects downstream services |
| Medium | `cli/bin/brokerbot.ts` + commands | AI-suggest flag using prompt templates | Medium (3–4 hrs) | High — adds smart assistance |
| Medium | Agent tick logic | Todo persistence | Medium (2–3 hrs) | Medium — makes long jobs resumable |
| Major Refactor | Entire CLI | Multi-step task orchestration with Task tool | High (1–2 weeks) | High — enables complex workflows |
| Major Refactor | Agent worker | Full supervisor hierarchy with health checks & auto-restart | High (1 week) | Medium — improves long-running reliability |

**Recommendation**: Start with robust client-side retry/timeout and env detection (quick wins). Then add AI assistance to the CLI. Finally, evaluate if full task orchestration framework fits Hermes's long-term needs.

## Steps

1. **Enhance CLI client with retry, timeout, and circuit breaker** (Week 1)
   - Implement `withRetry` utility function with exponential backoff and jitter
   - Add configurable request timeouts to all HTTP calls
   - Build `CircuitBreaker` class per endpoint/provider to prevent hammering failing services
   - Integrate circuit breaker into existing `call()` function in `cli/lib/client.ts`
   - Write unit tests with simulated failures
   - Add metrics: retry count, circuit breaker state changes

2. **Implement intelligent configuration detection** (Week 2)
   - Write `loadConfig()` enhancement that walks parent directories to find `.env` files
   - Add support for parsing `.env` files with proper quoting and variable expansion
   - Detect framework-specific configs (Next.js `next.config.js`, Node `package.json`) when present
   - Cache resolved config and support hot-reload on file changes
   - Make environment variable precedence explicit: CLI flags > env vars > .env file > defaults
   - Document configuration discovery behavior

3. **Build notify-on-completion feedback system** (Week 3-4)
   - Design StatusTracker class: generates task IDs, tracks state (pending/processing/completed/failed), stores result/error
   - Modify webhook handlers to immediately acknowledge with task ID (202 Accepted)
   - Create async worker that processes request and updates StatusTracker
   - Implement notification channels (email, Slack webhook, Discord webhook, HTTP callback)
   - Add user-preferred notification channel per event type
   - Build status query endpoint: `GET /api/tasks/{id}`
   - Test with long-running operations (e.g., data processing, model inference)

4. **Refactor provider adapters into plugin architecture** (Week 5-6)
   - Define `ProviderPlugin` abstract base class with required methods: `initialize`, `fetch`, `health_check`, `shutdown`
   - Create plugin discovery: scan `providers/` directory, load Python/TypeScript modules dynamically (depending on Hermes tech stack)
   - Implement plugin manager that instantiates, registers, and monitors plugins
   - Add plugin lifecycle hooks: `on_load` for registration, `on_unload` for cleanup
   - Build plugin health monitoring: periodic `health_check()` calls, mark unhealthy plugins as disabled after threshold
   - Ensure one plugin's failure doesn't crash agent; implement fallback behavior
   - Migrate existing provider code (Twitter, Reddit, chains) to plugin format

5. **Adopt robust prompt engineering for CLI AI features** (Week 7)
   - Design prompt templates following identified principles: role, context, task, constraints, examples, CoT trigger, verification
   - Create template library for common CLI AI suggestions (parameter inference, error explanation, command generation)
   - Implement prompt rendering engine with variable interpolation and context injection
   - Add few-shot examples to critical prompts (e.g., "Given this error, suggest fix")
   - Validate template output with automated tests against known-good responses
   - Iterate based on actual LLM output quality; log failures for analysis

## Pitfalls

- **Retry amplification**: Aggressive retry on already-failing operations can worsen congestion. Implement exponential backoff + jitter and circuit breakers.
- **Circuit breaker half-open race conditions**: Multiple concurrent requests during half-open state may cause cascade if service still failing. Use single "test" request or semaphore.
- **Config file traversal security**: Walking parent directories to find `.env` may inadvertently load sensitive files from unexpected locations. Limit search depth or root directory.
- **Plugin loading security**: Dynamic module loading of untrusted plugins is dangerous. Only load from trusted directories; consider sandboxing plugins in separate processes if third-party plugins are allowed.
- **Notification delivery failures**: Notification channels themselves can fail. Implement retry queues and dead-letter queues for undeliverable notifications.
- **Status tracking storage growth**: Persistent task status storage can grow indefinitely. Implement TTL-based cleanup (e.g., archive/delete completed tasks after 30 days).
- **Async task cancellation**: Long-running-async tasks need cancellation support when user aborts or plugin reload occurs. Implement proper signal handling.
- **Template rigidity**: Strict prompt templates may limit flexibility. Allow template overrides and a/b testing of different formulations.

## References

- Everything Claude Code: https://github.com/affaan-m/everything-claude-code
- Claude Code Documentation: https://docs.anthropic.com/en/docs/claude-code
- asyncio: https://docs.python.org/3/library/asyncio.html
- Circuit Breaker Pattern: https://martinfowler.com/bliki/CircuitBreaker.html
- Retry Pattern: https://cloud.google.com/architecture/retry-pattern
- TodoWrite/TodoRead (Claude Tools): https://docs.anthropic.com/en/docs/claude-code/tools
- Bash Best Practices: https://github.com/azlux/bash-login
- Docker Compose: https://docs.docker.com/compose/
