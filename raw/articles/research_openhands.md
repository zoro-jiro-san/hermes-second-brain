# OpenHands Security Research Report

## OpenHands Overview

OpenHands (formerly OpenDevin) is an open-source AI software engineer agent that can autonomously execute software development tasks. It operates by interpreting user requests, breaking them down into actionable steps, and executing those steps in a secure sandboxed environment. Key features include:

- **Agent Architecture**: Uses a ReAct-style loop with an LLM to plan and execute tasks
- **Execution Environment**: Runs code in isolated Docker containers to prevent host system damage
- **File System Interaction**: Provides controlled read/write access to project files
- **Shell Capabilities**: Executes terminal commands with output capture and streaming
- **Multi-modal Support**: Can handle both code and UI interactions through browser automation

The project aims to provide a safe, reproducible environment for AI-driven software development while maintaining strict security boundaries.

---

## Security Patterns

### 1. Sandbox Execution (Docker Isolation)

OpenHands employs Docker containers as the primary sandbox mechanism:

- **Default Runtime**: Uses `docker` or `podman` as the container runtime
- **Image**: Based on a minimal Linux image (often `ubuntu:latest` or a custom image)
- **Network Isolation**: Containers run with limited or no network access by default
- **Resource Limits**: CPU, memory, and storage quotas are enforced via Docker runtime flags
- **Volume Mounts**: Only explicitly granted directories are mounted into the container (typically the workspace directory)
- **User Isolation**: Container processes run as non-root users when possible

Configuration is managed through environment variables like `SANDBOX_RUNTIME`, `SANDBOX_IMAGE`, and `DOCKER_CONTAINER_OPTS`.

### 2. File System Operations Safety

OpenHands implements multiple layers of file system protection:

- **Workspace Confinement**: All file operations are restricted to a designated workspace directory that is mounted into the sandbox
- **Path Traversal Prevention**: The agent sanitizes file paths to prevent escaping the workspace (e.g., blocking `../` sequences)
- **Read-Only Baseline**: Initial workspace is read-only; write operations require explicit approval or are logged
- **Extension Allowlist**: Certain file extensions or operations may be blocked based on policy
- **Change Tracking**: File modifications are tracked for rollback and audit purposes
- **Size Limits**: Maximum file upload/download sizes are enforced to prevent DoS

The file system abstraction is implemented in `openhands/core/fs.py` and `openhands/runtime/impl/local/local_runtime.py`, which route all operations through a security layer.

### 3. Shell Command Execution + Capture

Shell execution is a core capability with careful safety measures:

- **Command Interceptor**: All shell commands go through a wrapper that logs and validates them
- **Timeouts**: Commands have execution timeouts to prevent infinite loops
- **Output Capture**: stdout and stderr are captured streamingly and fed back to the LLM
- **Exit Code Handling**: Non-zero exit codes are reported as errors
- **Dangerous Command Blocklist**: Commands like `rm -rf /`, `dd`, `mkfs`, etc. are blocked
- **Interactive Command Handling**: Commands requiring TTY (e.g., `sudo`, `passwd`) are detected and rejected

The execution runtime (`openhands/runtime/`) manages the command execution interface, whether in Docker, local, or remote environments.

### 4. Plan→Execute→Verify Loop

OpenHands follows an iterative agent loop:

- **Planning Phase**: LLM generates a step-by-step plan based on the user request and current state
- **Execution Phase**: Each step is executed (code run, command shelled, file edited)
- **Observation Capture**: Outputs, errors, and file changes are captured
- **Verification Phase**: The agent evaluates whether the step succeeded and if the overall goal is met
- **Re-planning**: On failure, the agent revises the plan and retries
- **Termination**: Loop exits when the task is complete, an unrecoverable error occurs, or a max iteration limit is reached

This loop is orchestrated by `openhands/agent/` and the state machine in `openhands/core/loop.py`.

---

## Hermes Sandbox Recommendation

### Recommendation: **Partial Integration with Containerization**

OpenHands' sandbox model could **significantly improve** the security of Hermes' provider adapter execution, but **full containerization may not be necessary** in all cases. Here's the reasoning:

#### Pros of Adopting OpenHands Sandbox:

1. **Strong Isolation**: Docker containers provide robust process, filesystem, and network isolation—critical for running untrusted provider code.
2. **Reproducible Environments**: Each adapter run gets a clean environment, avoiding dependency conflicts.
3. **Resource Control**: Limits prevent runaway adapters from exhausting host resources.
4. **Auditability**: All operations are logged inside the container, aiding forensic analysis.
5. **Cross-Platform Consistency**: Containers behave the same across dev, staging, and production.

#### Caveats and Considerations:

1. **Performance Overhead**: Container startup time (~1–2 seconds) could impact latency-sensitive adapter execution. Mitigation: Use container pooling or lightweight runtimes (e.g., `containerd` + `shim`).
2. **Complexity**: Managing Docker daemons, images, and volumes adds operational burden.
3. **Existing Hermes Model**: If Hermes already runs jobs in isolated VMs or has other isolation mechanisms, Docker may be redundant.
4. **Provider Trust Level**: If adapters are from trusted sources (internal team), full containerization may be overkill; a restricted subprocess sandbox could suffice.

#### Recommended Approach: **Hybrid Sandbox**

- For **untrusted or third-party providers**: Use OpenHands-style Docker containers with strict resource limits and no network access.
- For **internal, vetted providers**: Use a lightweight subprocess sandbox with seccomp/AppArmor profiles and filesystem namespaces.
- Implement **policy-driven execution**: Allow configuration per-provider to choose isolation level.

---

## Implementation Sketch

If proceeding with OpenHands-inspired containerization, here's a high-level plan:

### Phase 1: Sandbox Core (Docker-Based)

1. **Runtime Service** (`hermes/sandbox/runtime.py`):
   - Wraps Docker SDK to manage container lifecycle
   - Implements `start()`, `exec(cmd)`, `stop()`, `cleanup()`
   - Handles image pulling and caching

2. **Security Policy Engine** (`hermes/sandbox/policy.py`):
   - Defines per-provider policies (allowed commands, file paths, network)
   - Validates all execution requests against policy before dispatch

3. **Filesystem Proxy** (`hermes/sandbox/fs.py`):
   - Provides `read(path)` and `write(path, content)` methods
   - Enforces workspace confinement and path sanitization
   - Uses Docker volume mounts or `docker cp` for file transfer

4. **Command Executor** (`hermes/sandbox/executor.py`):
   - Accepts shell commands, runs them in container with timeout
   - Streams stdout/stderr back to caller
   - Blockslisted command detection

### Phase 2: Integration with Existing Hermes Jobs

1. **Adapter Runner Refactor** (`hermes/provider/adapter_runner.py`):
   - Replace direct subprocess calls with sandbox proxy
   - Add fallback to legacy mode if sandbox unavailable

2. **Configuration** (`config/sandbox.yaml`):
   ```yaml
   sandbox:
     default_runtime: docker
     docker_image: hermes-sandbox:latest
     timeout_seconds: 300
     memory_limit_mb: 1024
     cpu_quota: 50000  # 50% of one CPU
     network_enabled: false
   providers:
     - name: openai
       sandbox_level: none  # trusted internal
     - name: anthropic
       sandbox_level: container  # untrusted external
   ```

3. **Metrics & Monitoring**:
   - Track container start/stop times, execution durations, failures
   - Alert on policy violations or resource exhaustion

### Phase 3: Optional Enhancements

- **Container Pooling**: Pre-warm containers to reduce latency
- **Snapshot/Restore**: Save container state between runs for caching dependencies
- **Multi-tenant Isolation**: Run each provider in separate Docker networks/user namespaces
- **Audit Logging**: Immutable logs of all sandbox activity

### Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Docker daemon compromise | Run Docker in rootless mode; use gVisor or Kata Containers for extra isolation |
| Container escape vulnerabilities | Keep Docker and kernel updated; use seccomp/AppArmor profiles |
| Storage bloat from containers | Automatic cleanup of exited containers and unused images |
| Cold start latency | Implement a pool of warm containers per provider type |

---

## Conclusion

Adopting OpenHands' sandbox patterns would raise Hermes' security posture significantly, especially when executing code from external providers. A **gradual rollout** starting with high-risk adapters is recommended, combined with robust monitoring to detect any sandbox failures. The investment in containerization pays off in security, reproducibility, and auditability.
