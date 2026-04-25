---
name: Dexter
description: Event-driven bot framework patterns for modular plugin architecture, notification-on-completion, rate limiting, and configuration management applicable to autonomous agent systems
trigger: Need to improve Hermes's modularity, provider isolation, feedback loops, and operational resilience using proven bot framework patterns
---

## Overview

Dexter is an open-source, Python-based bot framework that simplifies creation of automation bots for Discord and Slack. It abstracts platform differences behind a unified API, enabling platform-agnostic plugins. Built on `asyncio`, Dexter uses native websocket connections (Discord Gateway, Slack RTM) for real-time event handling. Its design emphasizes modularity, extensibility, and ease of use, supporting both simple bots and complex automation workflows.

**Key characteristics**:
- Language: Python 3.8+
- Supported platforms: Discord (via `discord.py`), Slack (via `slack_sdk`)
- Architecture: Event-driven with robust plugin system
- Configuration: YAML/JSON with environment variable interpolation
- Scheduling: Built-in async scheduler for timed tasks

## Architecture Analysis

### 1. Message Handling Architecture

Dexter employs a **pure event-driven architecture** built on `asyncio`. It maintains persistent websocket connections to Discord and Slack gateways. Incoming events (messages, reactions, user joins) are normalized into a generic `Event` object and dispatched to registered listeners.

**Key components**:
- `Bot` class (`dexter/bot.py`) manages connections and event loop
- Platform-specific adapters (`dexter/adapters/discord.py`, `dexter/adapters/slack.py`) translate raw gateway events into internal events
- Central **dispatcher** routes events to plugin handlers based on event type

**Data flow**:
```
Discord/Slack Gateway → Adapter → Event object → Dispatcher → Plugin event handlers
```

No polling; all updates pushed over websockets, ensuring low latency and efficient resource usage.

### 2. Plugin/Extension System

Dexter's plugin system is the core extension point. Plugins are Python classes inheriting from `dexter.plugin.Plugin`. The framework scans configured plugin directories, imports modules, and instantiates classes.

**Plugin lifecycle hooks**:
- `on_load()` — called when bot starts; used for command/event registration
- `on_unload()` — cleanup on shutdown/reload
- Optional hot-reload on code changes (development mode)

**Registration via decorators**:
```python
from dexter import Plugin, command, event

class GreetingPlugin(Plugin):
    @command(name="hello", description="Greet a user")
    async def hello(self, ctx, args):
        user = args.get(0, "world")
        await ctx.send(f"Hello, {user}!")

    @event("message")
    async def on_message(self, event):
        # Custom message processing logic
        pass
```

Plugins can also define **middleware**, **checks** (permission verification), and **scheduled tasks**.

### 3. Command Routing Patterns

Commands are message-based, typically triggered by a prefix (e.g., `!`, `?`). Routing pipeline:

1. **Preprocessing**: Adapter extracts prefix and splits into command name + arguments
2. **Parser**: Tokenizes arguments (handles quotes, escaped spaces)
3. **Resolver**: Looks up command in global registry built from all plugin `@command` decorators
4. **Invocation**: Calls associated coroutine with `Context` object (sender, channel, bot reference, etc.)
5. **Post-processing**: Applies cooldowns, updates rate-limit counters, optionally edits original message

**Command features**:
- Aliases (`@command(name="hi", aliases=["hello", "hey"])`)
- Subcommands (e.g., `!admin ban @user` handled via nested parsing)
- Per-command cooldowns (`@cooldown(seconds=10)`)
- Permission checks (`@requires_role("mod")`, `@requires_permission("kick")`)

### 4. Rate Limiting + Error Recovery

**Rate Limiting**: Dexter provides configurable, multi-tier rate limiter:
- Global limits (e.g., 20 commands per 10 seconds across all users)
- Per-user limits (e.g., 5 commands per minute)
- Per-channel limits
- Per-command overrides

Implementation uses sliding-window counter stored in memory or Redis. Exceeding limits raises `RateLimitExceeded`; bot responds with friendly warning or silently ignores.

**Error Recovery**:
- **Command errors**: Wrapped in try/except; bot logs traceback and sends error embed; original message may be edited to show failure (❌)
- **Connection drops**: Adapters implement exponential backoff reconnection; bot automatically reconnects to gateways
- **API errors**: For Discord/Slack HTTP calls, retry wrapper with jitter for 429 (rate limit) responses
- **Plugin failures**: Plugin crashes during load disable it with log entry; bot continues running other plugins

### 5. Configuration Management

Dexter uses hierarchical configuration:
1. **Built-in defaults** bundled with framework
2. **Bot configuration file** (`config.yaml` or `config.json`) in project root
3. **Environment variables** that override file values via `${VAR}` interpolation

Example `config.yaml`:
```yaml
bot:
  token: "${DISCORD_TOKEN}"
  prefix: "!"
  presence: "Helping the community"

plugins:
  - myplugins.greeting
  - myplugins.moderation

rate_limits:
  default: 5 per 10 seconds
  per_user: true

logging:
  level: INFO
  file: "bot.log"
```

Configuration can be reloaded at runtime via admin command or signal, enabling changes without restart.

## Applicable Patterns for Hermes

### Pattern 1: Notify-on-Completion

**What it is**: In Dexter, long-running or asynchronous commands acknowledge receipt immediately (e.g., ⏳ emoji or "processing" message). Once operation completes, the bot edits acknowledgement to reflect success (✅) or failure (❌) and includes result.

**Why it matters**: Hermes's webhook system processes incoming events from providers and may fire off tasks without immediate feedback. Implementing notify-on-completion would:
- Provide users with real-time status (e.g., "Trade executed", "Order cancelled")
- Enable error propagation back to request source
- Improve observability and debugging (knowing which webhook succeeded/failed)

**Sketch of integration**:
```python
# Current Hermes webhook handler (simplified)
async def handle_webhook(request):
    result = await process(request)   # potentially slow
    return result    # no intermediate feedback

# With notify-on-completion
async def handle_webhook(request):
    ack_id = await send_acknowledgement(request)  # immediate response with task ID
    asyncio.create_task(process_and_notify(request, ack_id))

async def process_and_notify(request, ack_id):
    try:
        result = await process(request)
        await update_status(ack_id, status="completed", result=result)
    except Exception as e:
        await update_status(ack_id, status="failed", error=str(e))
```

### Pattern 2: Plugin Model for Provider Adapters

Dexter's plugin model cleanly separates core logic from platform-specific functionality. Each plugin is a self-contained module with a well-defined lifecycle. Applying this to Hermes's provider adapters would:

- **Standardize** interface for all data providers (Twitter, Reddit, on-chain APIs, etc.)
- Allow **dynamic discovery** and loading of new providers without touching core code
- Facilitate **testing** by mocking plugin interfaces
- Enable **hot-reloading** of provider configurations

**Proposed adapter interface**:
```python
class ProviderPlugin:
    """Base class for Hermes provider adapters."""
    name: str = "base"
    schema: dict = {}   # Optional JSON schema for incoming data

    async def initialize(self, config: dict):
        """Set up credentials, connections, etc."""
        pass

    async def fetch(self, query: str) -> List[Evidence]:
        """Pull new data from the provider."""
        raise NotImplementedError

    async def health_check(self) -> bool:
        """Check provider connectivity."""
        return True

    async def shutdown(self):
        """Cleanup resources before exit."""
        pass
```

Hermes core could scan a `providers/` directory, instantiate each plugin during startup, and periodically call `fetch()`. Errors in one plugin would be isolated (plugin temporarily disabled), mirroring Dexter's fault tolerance.

### Pattern 3: Event-Driven Decoupling

Dexter's decoupling of event producers (adapters) and consumers (plugins) via a dispatcher is worth emulating. Hermes already uses internal events, but adopting a typed event bus with async listeners would further increase modularity and allow third-party extensions.

## Integration Sketch

**High-Level Architecture**:
```
┌───────────────────┐      ┌─────────────────────┐      ┌────────────────────┐
│ Provider Plugins  │─────▶│  Event Bus /        │─────▶│  Hermes Core       │
│ (Twitter, Chain,  │      │  Dispatcher         │      │  (Reasoning,      │
│  News, etc.)      │      │                     │      │   Planning)       │
└───────────────────┘      └─────────────────────┘      └────────────────────┘
        │                           │                           │
        │ (notify on completion)    │                           │
        ▼                           ▼                           ▼
┌───────────────────┐      ┌─────────────────────┐      ┌────────────────────┐
│ Notification      │      │  Scheduler /        │      │  Knowledge Graph   │
│ Service (Slack/   │      │  Task Queue         │      │  (optional)       │
│  Email/Discord)   │      │                     │      │                    │
└───────────────────┘      └─────────────────────┘      └────────────────────┘
```

### Implementation Steps

1. **Extract** Dexter's plugin manager and event dispatcher into standalone library (or vendor modules directly)
2. **Wrap** each Hermes provider as `Plugin` subclass implementing `fetch` and `health_check`
3. **Implement** notification backend (Discord/Slack message, email) that listens for `TaskCompleted`/`TaskFailed` events
4. **Migrate** Hermes configuration to YAML with environment variable interpolation, following Dexter's pattern
5. **Leverage** Dexter's rate-limiting utilities to protect downstream APIs and prevent abuse

## Verdict

**Should Hermes adopt Dexter's patterns?**  
**Yes.** Dexter provides mature, battle-tested blueprint for building modular, resilient bots. Its plugin system and notify-on-completion pattern directly address two of Hermes's current shortcomings: fragmented provider code and limited feedback loops.

**Recommended adoption path**:
- **Short-term**: Borrow architectural ideas (event-driven plugin model, configuration layering) and implement lightweight in-house version tailored to Hermes
- **Medium-term**: Evaluate integrating Dexter as library after extracting platform-agnostic parts (plugin manager, event bus, rate limiter). Tight coupling to chat platforms means selective adaptation is wiser than full dependency
- **Long-term**: Consider contributing back "headless" mode to Dexter that removes chat-specific dependencies, making it suitable for generic automation frameworks like Hermes

**Caveats**:
- Dexter's design optimized for chat commands; Hermes's economic-agent workflows may require extending scheduler and task-tracking capabilities
- Notification delivery must be asynchronous and idempotent to avoid race conditions and duplicate alerts

**Conclusion**: Dexter offers solid foundation. By adapting its plugin architecture and completion-notification pattern, Hermes can achieve better modularity, observability, and maintainability with moderate engineering effort.

## Steps

1. **Design and implement plugin manager system** (Week 1-2)
   - Define `ProviderPlugin` base class with standardized interface (initialize, fetch, health_check, shutdown)
   - Create plugin discovery mechanism: scan configurable directories for Python modules, import, instantiate
   - Implement plugin lifecycle management: load on startup, unload on shutdown, optional hot-reload on file changes
   - Add plugin registry with metadata (name, version, capabilities, health status)
   - Write error isolation: plugin exceptions caught and logged without crashing core agent
   - Develop plugin testing harness with mock adapters

2. **Build event bus and dispatcher** (Week 3)
   - Design typed event system: define event classes (JobStarted, JobCompleted, ProviderHealthChanged, etc.)
   - Implement pub/sub bus with async listener registration
   - Create dispatcher that routes events to interested handlers (plugins, core components, notification service)
   - Add event filtering and routing rules (e.g., only notify on failures for certain providers)
   - Support synchronous and asynchronous event handlers
   - Implement event persistence for audit trail (optional but recommended)

3. **Implement notify-on-completion pattern** (Week 4)
   - Design acknowledgement system: when webhook received, immediately return task ID acknowledgment (HTTP 202 Accepted)
   - Create status tracking backend (in-memory or persistent) mapping task IDs to states (pending, processing, completed, failed)
   - Build notification service that listens for completion events and sends user notifications via preferred channel (email, Slack, Discord, SMS, HTTP callback)
   - Implement status query endpoint: `GET /tasks/{id}` returns current status and result/error
   - Add retry logic for notification delivery failures with exponential backoff
   - Support user-configurable notification preferences per event type

4. **Adopt hierarchical configuration system** (Week 5)
   - Migrate Hermes configuration from flat env-vars or JSON to YAML with hierarchical structure
   - Implement environment variable interpolation: values like `${OPENAI_API_KEY}` replaced with actual env vars
   - Add configuration inheritance: global → environment → service → instance levels
   - Support config hot-reload: watch config file for changes and dynamically apply without restart (where safe)
   - Create config validation layer using Pydantic or similar for type safety and required-field checking
   - Document configuration schema and provide example configs

5. **Integrate rate limiting and error recovery** (Week 6-7)
   - Implement multi-tier rate limiter (global, per-provider, per-user, per-endpoint)
   - Use sliding-window algorithm with Redis or in-memory store for distributed scenarios
   - Configure per-endpoint overrides for special cases
   - Add exponential backoff + jitter for retry on flaky operations
   - Implement circuit breaker pattern per provider: open circuit after threshold failures, half-open for testing, close on success
   - Create health check aggregator that monitors all provider endpoints and reports overall system health
   - Set up automatic failover: if primary provider fails, route to backup provider

## Pitfalls

- **Plugin isolation boundaries**: Python plugins run in same process; a misbehaving plugin (infinite loop, memory leak) can crash entire agent. Consider sandboxing (separate processes, containers) for untrusted plugins.
- **Configuration complexity**: Hierarchical configs can become confusing. Provide clear precedence rules, validation, and tooling to view effective configuration.
- **Notification spam**: Completion notifications for every minor task can overwhelm users. Implement aggregation, batching, and user-configurable importance thresholds.
- **Event bus performance**: High-throughput event systems may become bottleneck. Use async queues, batch processing, and monitor backlog.
- **Rate limiter state sharing**: Distributed Hermes deployments require shared rate limit state (Redis). Synchronization delays can cause race conditions; use atomic operations and consistent clocks.
- **Circuit breaker tuning**: Poorly tuned breakers cause unnecessary outages or mask real problems. Monitor metrics and use adaptive thresholds.
- **Backward compatibility**: Plugin API changes break existing provider adapters. Version plugins and maintain backwards compatibility or migration guides.
- **Hot-reload side effects**: Reloading plugins while they're processing jobs can cause state corruption. Implement safe reload (drain in-flight requests, pause fetching).

## References

- Dexter Repository: https://github.com/virattt/dexter
- Dexter Documentation: https://dexter.readthedocs.io
- asyncio: https://docs.python.org/3/library/asyncio.html
- discord.py: https://discordpy.readthedocs.io
- slack_sdk: https://slack.dev/python-slack-sdk/
- Pydantic: https://docs.pydantic.dev
- Circuit Breaker Pattern: https://martinfowler.com/bliki/CircuitBreaker.html
- Rate Limiting Algorithms: https://cloud.google.com/architecture/rate-limiting-patterns
- Event-Driven Architecture: https://www.enterpriseintegrationpatterns.com/patterns/messaging/EventDrivenConsumer.html
