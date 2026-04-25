# Research: anthropics/skills — Claude Skill System Analysis

## Overview

The [`anthropics/skills`](https://github.com/anthropics/skills) repository is the official framework for defining, packaging, and deploying **skills** for Claude. Skills are modular, reusable capabilities that extend Claude's functionality beyond language generation into domains like code execution, web search, document retrieval, and more.

This system provides:

- A **standardized schema** for skill definition (input/output validation)
- A **discovery mechanism** for agents to enumerate available skills
- A **invocation protocol** for secure, isolated execution
- **Composition patterns** for chaining multiple skills
- Built-in **security boundaries** and sandboxing

The repository serves as the reference implementation and skill registry for the Claude ecosystem, enabling third-party developers to create and distribute skills.

---

## 1. Skill Catalog

### Built-in Skills

| Skill | Purpose | Input Schema Highlights | Output Schema Highlights |
|-------|---------|------------------------|-------------------------|
| `code_interpreter` | Execute code in a sandboxed environment across multiple languages | `{code: string, language: enum[python,javascript,...], timeout?: int}` | `{stdout: string, stderr: string, result?: any, artifacts?: {files: string[]}}` |
| `web_search` | Perform live web searches via integrated search providers | `{query: string, num_results?: int (default 10), region?: string}` | `{results: [{title, snippet, url, date}], query: string}` |
| `retrieval` | Query user-provided documents/context for relevant passages | `{query: string, documents: string[], top_k?: int}` | `{passages: [{text, score, doc_id}], query: string}` |

> Note: The exact set of built-in skills may vary by Claude deployment (e.g., Claude Desktop vs. API). The repository defines the schema and example implementations.

### Skill Metadata

Each skill definition includes:

```yaml
name: string                # Unique identifier (e.g., "code_interpreter")
version: semver             # Skill version
description: string         # Human-readable description
capabilities: array[string] # Optional tags for discovery
parameters:                 # JSON Schema for input
  type: object
  properties: { ... }
  required: [ ... ]
returns:                    # JSON Schema for output
  type: object
  properties: { ... }
```

---

## 2. Input/Output Schemas

### Schema Format

All schemas use **JSON Schema Draft 7/2019-09** for validation. Example from `code_interpreter`:

```json
{
  "parameters": {
    "type": "object",
    "properties": {
      "code": {"type": "string", "description": "Source code to execute"},
      "language": {
        "type": "string",
        "enum": ["python", "javascript", "bash", "sql", "r"],
        "description": "Programming language"
      },
      "timeout": {"type": "integer", "minimum": 1, "maximum": 300}
    },
    "required": ["code", "language"]
  },
  "returns": {
    "type": "object",
    "properties": {
      "stdout": {"type": "string"},
      "stderr": {"type": "string"},
      "result": {"description": "Value of last expression"},
      "artifacts": {
        "type": "object",
        "properties": {
          "files": {
            "type": "array",
            "items": {"type": "string", "format": "uri"}
          }
        }
      }
    }
  }
}
```

### Type System

- Primitive types: `string`, `number`, `integer`, `boolean`, `null`
- Complex: `object`, `array`
- Format hints: `date-time`, `uri`, `email`, etc.
- Enumerations for constrained choices

---

## 3. Skill Discovery & Invocation

### Discovery

Skills are **self-describing**. When initializing, Claude loads:

1. **Local skill registry** (claude_skills.yaml or similar)
2. **Remote skill catalogs** (if configured)
3. **User-provided skill bundles** (packaged as .tar.gz or directories)

Discovery returns a list of skill manifests with name, description, and parameter schema. Agents (or Claude itself) can call:

```
GET /v1/skills            # List all available skills
GET /v1/skills/{name}     # Get manifest for specific skill
```

In the API, skills appear under the `tools` field in the model's system prompt.

### Invocation Flow

```
User → Claude (LLM) → Skill Router → Skill Executor (Sandbox) → Result
```

1. **LLM Decision**: Claude determines a skill is needed, emits a `tool_use` block with `name` and `input`.
2. **Validation**: System validates input against schema.
3. **Authorization**: Checks user permissions & quota.
4. **Execution**: Dispatches to the skill's executor (Docker container, subprocess, remote service).
5. **Result Collection**: Captures stdout, return value, artifacts.
6. **Response**: Returns `tool_result` block to Claude, which incorporates it into the response.

Example API call:

```bash
POST /v1/messages
{
  "model": "claude-3-opus",
  "max_tokens": 4096,
  "tools": [
    {
      "name": "code_interpreter",
      "description": "Executes code in a sandbox",
      "input_schema": { ... }
    }
  ],
  "messages": [...]
}
```

---

## 4. Skill Composition Patterns

### A. Sequential Chaining
Multiple skills run one after another, feeding outputs to inputs:

```
web_search(query="latest news") → retrieval(documents=results, query="summarize")
```

### B. Parallel Fan-out
Invoke multiple skills concurrently (e.g., search several APIs):

```json
{
  "parallel": true,
  "skills": [
    {"name": "web_search", "input": {"query": "..."}},
    {"name": "retrieval", "input": {"query": "...", "documents": [...]}}
  ]
}
```

### C. Conditional Branching
Select skill based on LLM reasoning:

```
if user_question contains "code" → use code_interpreter
elif user_question contains "latest" → use web_search
else → normal completion
```

### D. Skill Pipelines (Workflows)
Define multi-step pipelines as a composite skill:

```yaml
pipeline:
  - name: fetch_data
    skill: web_search
  - name: analyze
    skill: code_interpreter
    input: {code: "process(fetch_data.results)"}
  - name: report
    skill: file_write
```

### E. Recursive / Agent-in-the-loop
A skill can spawn a sub-agent with its own skill set, enabling hierarchical decomposition.

---

## 5. Security Considerations

The repository emphasizes a **defense-in-depth** model:

| Layer | Mechanism |
|-------|-----------|
| **Sandbox Isolation** | Code runs in containers (Firecracker microVMs) with no network, limited CPU/memory, read-only filesystem except /tmp |
| **Permission Scopes** | Skills declare required capabilities (e.g., `filesystem:read`, `network:outbound`). Users must grant per-session consent |
| **Input Validation** | Strict JSON Schema validation prevents injection attacks |
| **Rate Limiting** | Per-skill quotas to prevent abuse (e.g., max code executions per minute) |
| **Audit Logging** | All skill invocations logged with user ID, timestamp, input hash |
| **Content Filtering** | Search results filtered; code execution forbidden from importing certain modules (os, subprocess) unless explicitly allowed |
| **Artifact Sanitization** | Generated files scanned before returning to user |
| **Secret Management** | Skills requiring API keys use a vault; never expose secrets to the model or user |

### Threat Model Addressed

- **Malicious Prompt Injection**: Even if user tries to trick Claude into executing arbitrary code, only approved skills can run, and they are sandboxed.
- **Data Exfiltration**: Sandbox network is disabled by default; file_read limited to allowed paths.
- **Resource Exhaustion**: Timeouts, memory caps, CPU limits.
- **Privilege Escalation**: Skills run as unprivileged users.

---

## Hermes Adoption Plan

### Skills to Add (matching Anthropic)

| Anthropic Skill | Hermes Equivalent | Implementation Notes |
|-----------------|------------------|---------------------|
| `code_interpreter` | `code_exec` | Use Docker/Podman sandbox; support Python, JS, Bash, SQL; timeout 30s; capture stdout/stderr; optionally return artifacts |
| `web_search` | `web_search` | Integrate with SerpAPI, Brave Search, or DuckDuckGo; format results (title, snippet, url) |
| `retrieval` | `doc_search` | Implement vector store (FAISS) + embedding model; query over provided documents; return top-k passages with scores |
| `file_read` | `fs_read` | Restricted to whitelist of directories (e.g., `~/projects`, `/tmp`); enforce path traversal protection |
| `file_write` | `fs_write` | Same restrictions; prevent overwriting existing files without explicit user consent |

Additionally, Hermes could add **Hermes‑specific skills**:

- `git_ops`: Clone, commit, push, branch (safe, audit-logged)
- `notion_sync`: Read/write Notion pages (with OAuth token)
- `slack_notify`: Send Slack messages (webhook)
- `calendar_check`: Query calendar for availability
- `image_gen`: Generate images via DALL·E/Stable Diffusion

### Compatible Skill Interface for Cross-Platform Hireability

We can implement a **universal skill adapter** that translates between different agent skill formats:

```
UniversalSkillAdapter
├── AnthropicSkillAdapter  (maps anthropic skill → Hermes skill)
├── OpenAISkillAdapter      (maps OpenAI function calling → Hermes)
├── CustomSkillAdapter       (Hermes native)
```

**Design**:

1. **Skill Manifest Registry**: Store all skills in a standardized manifest (YAML) with:
   - `id`: unique globally (e.g., `anthropic:code_interpreter:1.0`)
   - `name`, `description`
   - `input_schema`, `output_schema` (JSON Schema)
   - `executor`: `"docker"`, `"http"`, `"local"`, `"hermes-native"`
   - `permissions`: `["filesystem:read", "network:outbound"]`
   - `compatibility`: list of platforms (`anthropic`, `openai`, `hermes`)

2. **Invocation Dispatcher**: Routes requests to appropriate executor based on manifest.

3. **Schema Translator**: Converts between Anthropic's tool format and OpenAI's function-calling format (they are similar but differ in field names: `name`/`description`/`parameters` vs `name`/`description`/`parameters` – mostly compatible). The main difference is Anthropic uses `input_schema` vs OpenAI's `parameters`; we normalize.

4. **Capability Negotiation**: When an agent (Hermes or external) requests skills, we respond with a manifest in the requester's format.

**Example**:

```python
class SkillAdapter:
    def to_anthropic(self, skill_id):
        manifest = load_manifest(skill_id)
        return {
            "name": manifest.id,
            "description": manifest.description,
            "input_schema": manifest.input_schema,
            "output_schema": manifest.output_schema  # sometimes omitted in Anthropic
        }

    def to_openai(self, skill_id):
        manifest = load_manifest(skill_id)
        return {
            "type": "function",
            "function": {
                "name": manifest.id,
                "description": manifest.description,
                "parameters": manifest.input_schema
            }
        }
```

This allows **cross-platform agent hireability**: a Hermes agent can advertise its skills to Anthropic-based orchestration layers, and vice versa.

### Implementation Roadmap

1. **Phase 1 – Core Skill Registry**
   - Create `hermes_skills.yaml` manifest store
   - Define `SkillManifest` Pydantic model
   - Build `SkillRegistry` service (list, get, validate)

2. **Phase 2 – Built-in Executors**
   - Implement `DockerExecutor` for code execution
   - Implement `HTTPSearchExecutor` for web_search
   - Implement `VectorSearchExecutor` for retrieval

3. **Phase 3 – Adapter Layer**
   - Build `AnthropicSkillAdapter` (import/export)
   - Build `OpenAISkillAdapter`
   - Create `UniversalSkillRouter` that normalizes incoming requests

4. **Phase 4 – Security Hardening**
   - Add per-skill permission system
   - Rate limiting & quotas
   - Audit logging
   - Secret management integration (Vault/Environment)

5. **Phase 5 – Discovery & Marketplace**
   - Publish Hermes skill catalog endpoint (`/v1/skills`)
   - Allow skill package upload (as signed tarballs)
   - Versioning & deprecation workflow

---

## Compatibility Checklist

To ensure Hermes skills are **compatible** with Anthropic's ecosystem:

- [ ] **Schema Conformance**: Input/output schemas use JSON Schema Draft 7/2019-09, no custom keywords
- [ ] **Field Naming**: Use `name`, `description`, `input_schema` (Anthropic) or `parameters` (OpenAI) consistently
- [ ] **Type Safety**: No polymorphic types that break schema validation
- [ ] **Error Handling**: Errors returned in standardized format `{"error": {"type": "...", "message": "..."}}`
- [ ] **Idempotency**: Skills should be safely re-runnable (no side effects without explicit flag)
- [ ] **Timeout Guarantees**: All skills respect configurable timeout (default 30s)
- [ ] **Streaming Support**: For long-running skills, support streaming chunks (optional)
- [ ] **Artifact URIs**: File artifacts returned as `file://` or `data:` URIs, not raw bytes
- [ ] **Permission Declarations**: All external accesses (FS, network, env) declared in manifest
- [ ] **Version Field**: Present and semver-compliant
- [ ] **No Implicit State**: Skills should be stateless; no reliance on previous invocations unless using user-provided context
- [ ] **Testing**: Provide example inputs/outputs in manifest `examples` field
- [ ] **Documentation**: Include `description` and `examples` for LLM understanding

---

## Conclusion

The `anthropics/skills` repository defines a robust, secure, and extensible skill architecture for Claude. By mirroring its patterns—standardized schemas, sandboxed execution, and rich metadata—Hermes can seamlessly interoperate with Anthropic's ecosystem while adding its own specialized capabilities. Implementing a universal skill adapter will position Hermes as a **cross-platform agent** capable of being hired by any orchestration layer that understands the Anthropic skill contract.
