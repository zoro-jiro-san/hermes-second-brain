# The Mansion — MCP Server Research

## 1. Project Purpose and Core Tools/Resources

**The-Mansion** is a personal MCP (Model Context Protocol) server by [zoro-jiro-san](https://github.com/zoro-jiro-san). It exposes local system tools, file operations, and automation capabilities to AI assistants (Claude, Cursor, etc.) via the standard MCP protocol.

**Core tools/resources:**
- **File operations**: Read, write, search filesystem with directory allow-lists
- **Command execution**: Run shell commands with sandbox/validation layer
- **System info**: Process lists, environment variables, resource metrics
- **Automation hooks**: Cron scheduling + webhook triggers for tool calls
- **Custom scripts**: Easily extensible for personal workflows

---

## 2. MCP Server Architecture

**Transport:** stdio (standard input/output) — subprocess communication, no network stack.
**Protocol:** JSON-RPC 2.0 following the MCP specification.

**Endpoints provided:**
| Endpoint        | Purpose                                       |
|-----------------|-----------------------------------------------|
| `tools/list`    | Catalog of available tools with JSON schemas  |
| `tools/call`    | Execute a tool with validated parameters      |
| `resources/list`| Enumerate accessible data resources           |
| `resources/read`| Read a resource by URI                        |
| `prompts/list`  | Available prompt templates                    |
| `sampling/create`| Delegate LLM sampling to client              |

**Internal modules:**
- `server.py` — stdio transport + JSON-RPC dispatcher
- `handlers/` — Tool handlers, resource loaders
- `sandbox.py` — Path/command validation, allow-lists
- `config.yaml` — Allowed dirs, commands, limits
- `scheduler/` — Cron + webhook background workers

---

## 3. Security Model

**Authentication:** Local-only by default (subprocess); optional token for HTTP webhook mode.

**Sandbox & Isolation:**
- **Path confinement**: Only operate within `allowed_directories` (no `../` traversal)
- **Command allow-list**: Pre-approved binaries only (e.g., git, python, make)
- **Input validation**: JSON schema enforcement before tool dispatch
- **Resource limits**: Configurable timeouts (default 300s) and memory caps
- **No privilege escalation**: Runs as invoking user; never sudo

**Threat model:** Relies on OS-level user isolation. Suitable for personal use; not multi-tenant.

---

## 4. Automation Patterns

**Cron hooks:**
- Standard cron syntax (`0 9 * * *`) for recurring tasks
- Persistent task registry (`~/.mansion/tasks.json`)
- Background scheduler polls and triggers tool calls

**Webhooks:**
- Optional HTTP server (separate port) for external triggers
- HMAC signature verification for auth
- JSON payload → tool parameters mapping

**Pattern examples:**
- File watcher → trigger on-change tool
- Periodic git status → Slack notification tool
- CI build success → deploy script execution

---

## 5. Hermes Skill/Plugin Packaging

The-Mansion’s clean MCP architecture makes Hermes integration straightforward:

```
Hermes Layer:
  └─ Spawn TheMansion subprocess (stdio pipes)
      ├─ tools/list → register Hermes actions
      └─ tools/call  → forward Hermes invocations
```

**SKILL.md Requirements:**
- **Inputs**: Match tool parameter schemas (e.g., `path`, `command`, `schedule`)
- **Outputs**: Standardized `{ success, result, error, metadata }`
- **Triggers**: `manual` | `cron` | `webhook`
- **Error handling**: Retry logic, timeout policy, fallback tools

**Benefits:**
- No code changes to The-Mansion
- Leverages existing tool registry and sandbox
- Enables local AI-assisted workflow automation within Hermes

---

*Architecture is clean, well-separated, and ready for packaging as a Hermes skill.*