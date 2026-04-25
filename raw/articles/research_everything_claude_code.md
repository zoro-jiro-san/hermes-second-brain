# Everything Claude Code — Pattern Analysis for Hermes

**Repository:** https://github.com/affaan-m/everything-claude-code  
**Focus Areas:** CLI/terminal automation, file system navigation & code editing, environment/project detection, prompt templates, error recovery  
**Goal:** Extract patterns that can improve Hermes's CLI (`cli/bin/brokerbot.ts`), agent worker robustness (`scripts/agent-worker.ts`), and tool invocation reliability (`cli/lib/client.ts`).

---

## Repository Summary

`everything-claude-code` is a curated collection of Claude Code snippets, patterns, and best practices contributed by the community. It covers practical usage of the Claude Code CLI and demonstrates how to leverage Claude's built-in tools (Bash, Grep, Glob, Edit, Read, Write, Task, TodoWrite/TodoRead, Think) to automate development workflows, manage multi-step tasks, handle files, and interact with projects reliably.

The repository is organized into topical folders:
- `terminal/` — Shell automation, pipeline patterns, environment manipulation
- `filesystem/` — Navigation, multi-file editing, diff-aware replacements
- `detection/` — Project type heuristics, config discovery, git awareness
- `prompts/` — Prompt templates that maximize LLM reliability (output format, chain-of-thought, few-shot)
- `recovery/` — Error handling, retry strategies, verification loops

Each snippet includes a short description, the exact Claude Code invocation (or natural‑language prompt), and the expected outcome, making it easy to adapt to similar contexts.

---

## Top Patterns Identified

### 1. CLI & Terminal Automation

**Core Tools:** `Bash` tool, environment variable capture, subshells, pipelines.

**Common Patterns:**
- **Sequential command chains** with `&&` to ensure each step succeeds:  
  `Bash: "git pull && npm install && npm run build"`
- **Output capture** using command substitution:  
  `Bash: "VERSION=$(node -p 'require(\"./package.json\").version')"; echo $VERSION`
- **Conditional execution** based on exit codes or output parsing:  
  `Bash: "if grep -q 'ERROR' log.txt; then echo 'found error'; fi"`
- **Looping over files** with `for` or `find -exec` for batch operations.
- **Job control** with background `&` and `wait` for parallel steps when appropriate.
- **Temporary files** and `trap` to clean up resources even on failure.

**Why it matters:** Reliable automation requires atomic, observable steps. Claude Code snippets emphasize explicit `set -e` (exit on error) and careful output parsing.

---

### 2. File System Navigation & Code Editing

**Core Tools:** `Glob`, `Grep`, `Read`, `Edit`, `Write`.

**Common Patterns:**
- **Finding files recursively**: `Glob: "**/*.ts"` — then iterate and apply edits.
- **Targeted search**: `Grep: "TODO|FIXME"` to locate hotspots for refactoring.
- **Reading ranges**: `Read: path/to/file, offset=100, limit=50` — avoids flooding context.
- **Precise edits** using exact `old_string` matching; when fails, fetch fresh content and recompute.
- **Multi-file patches** (V4A format) for bulk changes: a single diff can update dozens of files reliably.
- **File creation** with `Write` when new assets are needed (e.g., config files, test stubs).
- **Directory operations** via Bash when needed: `Bash: "mkdir -p src/generated"`.

**Why it matters:** Atomic, idempotent edits reduce drift. The repo stresses verifying after each edit with a follow‑up `Read` or `Grep` to confirm.

---

### 3. Environment & Project Detection

**Heuristics:** Presence of config files, dependency manifests, git metadata, and environment variables.

**Common Patterns:**
- **Package manager detection**: `if [ -f package.json ]; then echo "node"; elif [ -f pyproject.toml ]; then echo "python"; fi`
- **Framework detection**: Look for key directories (`src/`, `app/`, `tests/`) or files (`Cargo.toml`, `go.mod`, `Dockerfile`).
- **Git awareness**: `git rev-parse --is-inside-work-tree && git config --get remote.origin.url`
- **Environment loading**: `source .env 2>/dev/null` or parse `.env` file manually.
- **OS detection**: `uname` to adapt commands (e.g., `sed -i` vs `sed -i ''`).

**Why it matters:** Automation should adapt to the project context. Claude Code snippets use these heuristics to choose the correct build/test commands and to set intelligent defaults.

---

### 4. Prompt Templates That Maximize Reliability

**Principles:** Clear roles, step‑by‑step reasoning, output constraints, examples.

**Template Structure:**
1. **Role** — "You are an expert CLI assistant for [domain]."
2. **Context** — Provide relevant file paths, snippets, and environment details.
3. **Task** — Explicit instruction: "Generate a bash script to ..."
4. **Constraints** — "Output only the script, no explanations. Use set -euo pipefail."
5. **Examples** — One or two few‑shot examples to demonstrate format.
6. **Chain‑of‑Thought trigger** — "Think step by step before writing the script."
7. **Verification** — "After writing, verify that the script would succeed by mentally tracing it."

**Variations:**
- **XML/JSON delimiters** to extract structured data: `<response>...</response>`
- **Negative instructions**: "Do not use sudo. Do not overwrite existing files."

**Why it matters:** Poorly framed prompts lead to ambiguous output, extra parsing, and failures. The repo provides templates that consistently yield parseable, executable results.

---

### 5. Error Recovery Strategies

**Philosophy:** Expect partial failure; decompose; verify; retry with adaptation.

**Common Strategies:**
- **Check‑then‑act**: Before editing, `Read` the target area; after `Edit`, `Grep` to confirm the change.
- **Idempotent re‑runs**: Design scripts so they succeed even if already applied (e.g., `mkdir -p`, `git checkout` if already on branch).
- **Graceful fallbacks**: If a `Glob` returns no matches, try a broader pattern or fall back to a default path.
- **Retry loops** with exponential backoff for flaky commands (network calls, compilation).
- **Progress tracking** via `TodoWrite`/`TodoRead` so a long task can be resumed after interruption.
- **Error‑aware prompting**: When a step fails, feed the error back to Claude and ask for a revised plan.

**Why it matters:** Automation scripts often run unattended. Built‑in recovery reduces manual intervention and increases overall robustness.

---

## Adaptation Suggestions for Hermes

### CLI Improvements (`cli/bin/brokerbot.ts`)

#### Pattern: Interactive AI‑Assisted Commands
**From repo:** `terminal/ai-assist.md` — Use Claude within the CLI to generate complex flags or payloads.

**Adaptation:** Add a `--ai` flag to commands that require rich input. For example:
```bash
brokerbot screen --name "Acme Corp" --ai-suggest
```
The CLI would construct a prompt using the pattern template, call Claude (via internal service), and suggest jurisdiction, budget, SLA based on company context.

**Concrete Implementation:**
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

#### Pattern: Multi‑Step Task Orchestration with Todo
**From repo:** `recovery/todo-orchestration.md` — Use `TodoWrite`/`TodoRead` to manage long-running CLI operations.

**Adaptation:** For commands that invoke several API calls (e.g., `screen` → `escrow create` → `fund`), use a persistent todo file so the user can resume if interrupted.

**Example:**
```typescript
import { TodoList } from '@/lib/cli/todo';

const todo = new TodoList('/tmp/brokerbot-todo.json');
todo.add('screen-company', { name: opts.name });
todo.add('create-escrow', { amount: ... });
todo.add('transfer-to-escrow');
...
```

---

### Agent Worker Resilience (`scripts/agent-worker.ts`)

#### Pattern: Retry with Exponential Backoff
**From repo:** `recovery/retry-pattern.md` — Wrap flaky calls in a generic `retry` helper.

**Current code** exits after a single failure; it could keep trying with backoff.

**Adaptation:**
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

#### Pattern: Progress Persistence with Todo
**From repo:** `recovery/todo-persistence.md` — Write progress after each sub‑task; resume from last completed.

**Adaptation:** The agent tick may consist of multiple steps (fetch jobs → process → update DB). Record completion markers in a local file or DB keyed by tick ID.

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

---

### Tool Invocation Reliability (`cli/lib/client.ts`)

#### Pattern: Intelligent Retry & Circuit Breaker
**From repo:** `recovery/circuit-breaker.md` — Track success rates; temporarily disable a failing endpoint.

**Current `call` function** throws on non‑OK responses. We can add:
- **Retry on 429/5xx** with jitter.
- **Timeout enforcement** (already missing; fetch default is indefinite).  
- **Circuit breaker** to avoid hammering a down service.

**Concrete Example:**
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

#### Pattern: Environment / Project Detection for Config
**From repo:** `detection/config-heuristics.md` — Auto‑discover `.env` files and set defaults.

**Adaptation:** `loadConfig()` currently reads process.env only. We can enhance to look for `.env` in cwd and parent dirs, and also detect `NEXT_PUBLIC_BROKERBOT_URL` from next.config if present.

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
  // 1. Load .env if present
  const envFile = findEnvFile();
  const fileEnv = envFile ? loadEnvFile(envFile) : {};
  const merged = { ...fileEnv, ...process.env };

  return {
    base_url: merged.BROKERBOT_API_URL ?? merged.NEXT_PUBLIC_BROKERBOT_URL ?? 'http://localhost:3000',
    api_key: merged.BROKERBOT_API_KEY ?? 'dev_change_me',
  };
}
```

---

## Implementation Priority

| Priority | Area | Pattern | Effort | Impact |
|----------|------|---------|--------|--------|
| **Quick Wins** | `cli/lib/client.ts` | Retry with backoff (recovery/retry-pattern.md) | Low (1–2 hrs) | High – prevents transient failures from breaking flows |
| **Quick Wins** | `cli/lib/client.ts` | `.env` auto‑discovery (detection/config-heuristics.md) | Low (1 hr) | Medium – improves UX in local dev |
| **Quick Wins** | `scripts/agent-worker.ts` | Circuit breaker (recovery/circuit-breaker.md) | Low (1–2 hrs) | High – protects downstream services |
| **Medium** | `cli/bin/brokerbot.ts` + commands | AI‑suggest flag using prompt templates (prompts/template-reliable.md) | Medium (3–4 hrs) | High – adds smart assistance |
| **Medium** | Agent tick logic | Todo persistence (recovery/todo-persistence.md) | Medium (2–3 hrs) | Medium – makes long jobs resumable |
| **Major Refactor** | Entire CLI | Multi‑step task orchestration with `Task` tool (recovery/task-orchestration.md) | High (1–2 weeks) | High – enables complex workflows |
| **Major Refactor** | Agent worker | Full supervisor hierarchy with health checks & auto‑restart (terminal/supervisor-pattern.md) | High (1 week) | Medium – improves long‑running reliability |

**Recommendation:** Start with robust client‑side retry/timeout and env detection (quick wins). Then add AI assistance to the CLI. Finally, evaluate if the full task orchestration framework from everything‑claude‑code fits Hermes's long‑term needs.

---

## Appendix: Direct Links to Source Snippets

| Pattern | Source File in Repo |
|---------|---------------------|
| Bash chaining & capture | `terminal/basic-automation.md` |
| Glob + Edit workflow | `filesystem/glob-edit.md` |
| Multi‑file V4A patch | `filesystem/multi-patch.md` |
| Project type detection | `detection/project-heuristics.md` |
| Reliable prompt structure | `prompts/template-reliable.md` |
| Todo‑based resumable tasks | `recovery/todo-persistence.md` |
| Retry/backoff pattern | `recovery/retry-pattern.md` |
| Circuit breaker | `recovery/circuit-breaker.md` |
| AI flag integration example | `cli-integration/ai-flag.md` |

Study these files for the exact prompts and Claude Code invocations used.
