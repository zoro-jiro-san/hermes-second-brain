---
name: "OpenHands: Secure Execution Sandbox Patterns"
description: "Skills and patterns extracted from OpenHands research: container-based sandboxing, file system safety, and iterative plan-execute-verify loops."
trigger: "when working with sandbox execution, secure code running, or autonomous agent loops"
---

# OpenHands: Sandbox Execution & Agent Loop Patterns

## Overview
This skill captures security and execution patterns from **OpenHands** (formerly OpenDevin), an open-source AI software engineer agent. Key focus areas include Docker-based sandboxing, filesystem operation safety, shell command validation, and the iterative **Plan→Execute→Verify** agent loop. These patterns are directly applicable to building secure, autonomous agents that execute code or interact with external systems.

## What It Does
Provides patterns for:
- **Container-based isolation**: Running untrusted code in Docker containers with strict resource limits
- **Filesystem confinement**: Preventing path traversal, enforcing workspace boundaries, tracking changes
- **Command interception**: Validating shell commands against blocklists, handling timeouts and TTY detection
- **Iterative agent loop**: Planning, execution, observation, verification, and re-planning cycles
- **Auditability and rollback**: Tracking all operations for forensic analysis and recovery

## When to Use
- Executing untrusted provider code or adapters
- Running code generation agents in production
- Building autonomous agents that perform system operations
- Implementing secure sandbox environments for AI tool use
- Designing multi-step agent workflows with failure recovery

## Setup
Read the full research at: `/home/tokisaki/work/research-swarm/outputs/research_openhands.md`

## Implementation Steps
### Phase 1: Sandbox Core (Docker-Based)
1. Create `hermes/sandbox/runtime.py`: Manage container lifecycle (start, exec, stop, cleanup)
2. Create `hermes/sandbox/policy.py`: Define per-provider policies (allowed commands, file paths, network)
3. Create `hermes/sandbox/fs.py`: Read/write methods enforcing workspace confinement and path sanitization
4. Create `hermes/sandbox/executor.py`: Shell command execution with timeout, stdout/stderr streaming, blocklist detection

### Phase 2: Integration
1. Refactor `hermes/provider/adapter_runner.py`: Replace direct subprocess calls with sandbox proxy
2. Add fallback to legacy mode if sandbox unavailable
3. Create `config/sandbox.yaml` with runtime configuration and per-provider sandbox policies
4. Implement metrics and monitoring: container start/stop times, execution durations, failures

### Phase 3: Enhancements (optional)
- Container pooling: pre-warm containers to reduce latency
- Snapshot/restore: cache dependencies between runs
- Multi-tenant isolation: separate Docker networks and user namespaces
- Audit logging: immutable logs of all sandbox activity

## Key Patterns Extracted
### Sandbox Execution (Docker Isolation)
- Minimal base image, limited/blocked network, resource quotas, explicit volume mounts, non-root user
- Configuration via env vars: `SANDBOX_RUNTIME`, `SANDBOX_IMAGE`, `DOCKER_CONTAINER_OPTS`

### Filesystem Operations Safety
- Workspace confinement, path traversal prevention (`../` blocking)
- Read-only baseline with explicit write approval
- Change tracking for rollback and audit
- Extension allowlists and size limits

### Shell Command Execution + Capture
- Command interceptor with logging/validation
- Timeouts, output capture streaming, exit code handling
- Dangerous command blocklist (`rm -rf /`, `dd`, `mkfs`, TTY-demanding commands)
- Sandbox implementation in `openhands/runtime/`

### Plan→Execute→Verify Loop
1. **Planning**: LLM generates step-by-step plan from request + state
2. **Execution**: Steps executed (code run, command shelled, file edited)
3. **Observation**: Outputs, errors, file changes captured
4. **Verification**: Evaluate step success and overall goal met
5. **Re-planning**: On failure, revise plan and retry
6. **Termination**: Complete, unrecoverable error, or max iterations reached

## Pitfalls
- Cold start latency (~1-2s) can impact latency-sensitive execution; mitigate via container pooling
- Docker daemon compromise risk; use rootless mode; consider gVisor/Kata for extra isolation
- Container escape vulnerabilities; keep Docker/kernel updated; use seccomp/AppArmor profiles
- Storage bloat from exited containers; implement automatic cleanup of unused images
- Policy complexity: avoid overly restrictive policies that block legitimate operations

## References
- Research: `research_openhands.md`
- OpenHands GitHub: https://github.com/All-Hands-AI/OpenHands
