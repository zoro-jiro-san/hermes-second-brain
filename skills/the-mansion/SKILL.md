---
name: "The Mansion: MCP Server & Local Tool Automation"
description: "Skills and patterns extracted from The-Mansion research: MCP server architecture, local tool execution, cron automation, and webhook-triggered actions for AI assistants."
trigger: "when working with MCP protocol, local tool integration, or scheduled/webhook automation"
---

# The Mansion: MCP Server & Local Automation Patterns

## Overview
This skill extracts patterns from **The-Mansion** by zoro-jiro-san — a personal MCP (Model Context Protocol) server that exposes local system tools, file operations, and automation capabilities to AI assistants via the standard MCP protocol. It demonstrates clean separation between transport, protocol, security sandbox, and tool handlers, with cron scheduling and webhook triggers.

## What It Does
Provides patterns for:
- **MCP server implementation**: JSON-RPC 2.0 over stdio (subprocess) transport
- **Tool registry & execution**: Dynamic tool listing with JSON schemas; validated parameter dispatch
- **Security sandbox**: Directory allow-lists, command allow-lists, input validation, resource limits, no privilege escalation
- **Automation hooks**: Cron scheduling and webhook-triggered tool invocations
- **Extensible scripts**: Simple mechanism to add custom personal workflows

## When to Use
- Building MCP-compatible servers for local AI assistant integration
- Exposing local system tools safely to LLM agents
- Implementing scheduled or event-driven automation from AI assistants
- Packaging local capabilities as discoverable tools with standards-based protocols
- Creating personal automation servers that bridge AI and local workflows

## Setup
Read the full research at: `/home/tokisaki/work/research-swarm/outputs/research_the_mansion.md`

## Implementation Steps
1. Study MCP specification: JSON-RPC 2.0, stdio transport, endpoints: `tools/list`, `tools/call`, `resources/list`, `resources/read`, `prompts/list`, `sampling/create`
2. Design tool schemas in JSON Schema format; document inputs/outputs for each tool
3. Build core server: stdio transport layer + JSON-RPC dispatcher
4. Implement sandbox layer: enforce `allowed_directories` (no `../`), command allow-list, timeouts (default 300s)
5. Create tool handlers: file read/write, command execution, system info, custom scripts
6. Add scheduler: persistent task registry (e.g., `~/.mansion/tasks.json`), cron polling, webhook HTTP server (optional)
7. Integrate into Hermes:
   - Spawn The-Mansion (or compatible MCP server) as subprocess
   - Map Hermes actions → MCP tool calls
   - Forward tool results back to Hermes reasoning loop
   - Expose tools in Hermes action registry
8. Package as a Hermes SKILL following Standard SKILL.md format

## Key Patterns Extracted
### Architecture
- **Transport**: stdio (subprocess pipes) — no network stack needed for local integration
- **Protocol**: JSON-RPC 2.0 per MCP spec
- **Endpoints**: `tools/list` (catalog + schemas), `tools/call` (execution), `resources/list/read`, `prompts/list`, `sampling/create`
- **Internal modules**: `server.py` (dispatcher), `handlers/` (tool logic), `sandbox.py` (validation), `config.yaml` (allow-lists), `scheduler/` (cron/webhooks)

### Security Model
- Local-only by default (subprocess); optional token for HTTP webhook mode
- **Path confinement**: only within `allowed_directories` (reject `../`)
- **Command allow-list**: pre-approved binaries only (git, python, make, etc.)
- **Input validation**: JSON schema enforcement pre-dispatch
- **Resource limits**: configurable timeouts, memory caps; no privilege escalation
- Threat model: OS-level user isolation; suitable for personal, not multi-tenant

### Automation Patterns
- **Cron hooks**: recurring tasks via standard cron syntax; persistent task registry; background scheduler
- **Webhooks**: optional HTTP server with HMAC auth; JSON payload → tool param mapping
- Examples: file watcher → on-change tool; periodic git status → Slack notification; CI build success → deploy script

### Hermes SKILL Packaging
- Inputs: match tool parameter schemas (`path`, `command`, `schedule`)
- Outputs: standardized `{ success, result, error, metadata }`
- Triggers: `manual`, `cron`, `webhook`
- Error handling: retry logic, timeout policy, fallback tools
- Benefits: no changes to The-Mansion code; leverages existing tool registry and sandbox
- Enables local AI-assisted workflow automation within Hermes

## Pitfalls
- Ensure command allow-list is minimal; avoid including destructive commands (rm, dd) unless absolutely necessary with strict arguments
- Cron parsing edge cases: handle environment differences, PATH issues; consider using a well-tested cron library
- Webhook security: verify HMAC signatures; rate limit incoming requests; avoid exposing to public internet without auth
- Subprocess management: monitor for zombie processes; implement proper SIGTERM/SIGKILL handling
- Tool output size: enforce limits to prevent memory exhaustion; stream large outputs if needed
- Version compatibility: stick to stable MCP spec version; pin dependencies

## References
- Research: `research_the_mansion.md`
- GitHub: https://github.com/zoro-jiro-san/The-Mansion
- MCP Spec: https://spec.modelcontextprotocol.io/
