---
name: agentic-inbox
description: Reliable, scalable agent-to-agent messaging system using Cloudflare Workers + Durable Objects — persistent inboxes, streaming push notifications, webhook forwarding with retry, and at-least-once delivery guarantees.
version: 1.0.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [agent-messaging, message-queue, webhooks, durable-storage, sse, cloudflare-workers]
    related_skills: [agentic-stack, hermes-agent, claude-task-master]
---

# Agentic Inbox — Persistent Agent Messaging Infrastructure

Agentic Inbox is a Cloudflare Workers + Durable Objects pattern for reliable, scalable agent‑to‑agent messaging. It provides each agent a globally unique, durable inbox with persistent storage, real‑time streaming via Server‑Sent Events (SSE), and asynchronous webhook delivery with automatic retry. Adopt this pattern to ensure Hermes never loses incoming messages, can receive events from external services, and supports bidirectional agent communication at scale.

## When to Use

Trigger when Hermes needs:
- A persistent, addressable mailbox for receiving external events (payment confirmations, API callbacks, alerts)
- Real‑time push notifications to running agent instances (no polling)
- At‑least‑once delivery guarantees even if Hermes restarts or network blips occurs
- Multi‑tenant message segregation (different streams per agent or purpose)
- Audit trail of all received messages (who sent what and when)
- Scalable horizontal architecture that handles thousands of concurrent inboxes
- Webhook reliability: external services POST to inbox, inbox forwards to Hermes with retry
- Agent‑to‑agent direct messaging in multi‑agent workflows

## Prerequisites

- Cloudflare account with Workers and Durable Objects enabled
- `wrangler` CLI for deployment
- Domain configured for Workers route (e.g., `inbox.hermes.ai`)
- Basic understanding of JavaScript/TypeScript or Python (via Workers‑Python runtime)
- Hermes running with HTTP server capability to receive forwarded webhooks or SSE subscriptions

## Quick Reference

### Inbox Architecture

```
┌─────────────────────────────┐
│  External Sender            │
│  (Payment gateway, API,     │
│   another agent)            │
└─────────────┬───────────────┘
              │ HTTP POST
              ▼
┌─────────────────────────────┐
│  Cloudflare Worker           │
│  (Stateless router)         │
│  Routes /:inboxId → DO      │
└─────────────┬───────────────┘
              │ maps to
              ▼
┌─────────────────────────────┐
│  Durable Object (per inbox) │
│  - Persistent SQLite store  │
│  - Active SSE listeners set │
│  - Webhook config           │
│  - Retry queue for failures │
└─────────────┬───────────────┘
              │ push messages
              ▼
    ┌─────────────────┐
    │ Hermes Agent    │
    │ (SSE consumer) │
    │ or webhook URL │
    └─────────────────┘
```

### Message Flow

```javascript
// Sender: POST a message to an inbox
POST https://inbox.hermes.ai/agent_abc123
Content-Type: application/json

{
  "stream": "default",        // named channel within inbox
  "data": {
    "event": "payment_confirmed",
    "tx_id": "tx_789xyz",
    "amount": 150.00,
    "currency": "USD"
  },
  "id": "msg_uuid_optional"   // optional deduplication ID
}
```

```python
# Hermes consumer: listen via SSE
import sseclient

response = requests.get(
    "https://inbox.hermes.ai/agent_abc123",
    headers={"Accept": "text/event-stream"},
    stream=True
)
client = sseclient.SSEClient(response)

for event in client.events():
    message = json.loads(event.data)
    hermes.handle_incoming(message)
```

### Webhook Forwarding with Retry

```javascript
// Inside Durable Object (simplified)
class InboxDurableObject {
  async fetch(request) {
    const url = new URL(request.url);
    if (url.pathname === "/" && request.method === "POST") {
      const body = await request.json();

      // 1. Persist to SQLite (source of truth)
      await this.store.put(body.id, body);

      // 2. Fan-out to SSE listeners
      this.broadcastToListeners(body);

      // 3. Queue webhook delivery (async, retryable)
      if (this.webhookUrl) {
        await this.queueWebhookDelivery(body);
      }

      return new Response("OK", { status: 200 });
    }
  }

  async queueWebhookDelivery(message, attempt = 1) {
    try {
      await fetch(this.webhookUrl, {
        method: "POST",
        body: JSON.stringify(message),
        headers: {"Content-Type": "application/json"}
      });
    } catch (err) {
      // Exponential backoff retry up to 5 attempts
      if (attempt < 5) {
        const delay = Math.min(1000 * 2 ** attempt, 3600000);
        setTimeout(() => this.queueWebhookDelivery(message, attempt + 1), delay);
      } else {
        this.recordDeliveryFailure(message, err);
      }
    }
  }
}
```

## Key Patterns

| Pattern | Description | Benefit |
|---------|-------------|---------|
| **Inbox‑per‑agent** | Unique durable object ID per agent; state isolated | Global addressability, independent scaling |
| **Durable storage as source of truth** | All messages written to SQLite‑backed DO before acknowledgement | No message loss across restarts/partitions |
| **Stream‑based pub/sub** | Named streams (`default`, `alerts`, `transactions`) within inbox | Topic‑style routing, simple filtering |
| **SSE push** | Long‑lived HTTP connections for real‑time event streaming | Low overhead, firewall‑friendly, no polling |
| **Idempotent delivery** | Optional deduplication via message `id` field | Safe for retry scenarios |
| **Async webhook retry** | Failed deliveries re‑queued with exponential backoff | External endpoint outages don't lose messages |
| **Stateless worker + stateful DO** | Front‑end router contains no inbox state; DO holds everything | Simplifies reasoning, scales independently |
| **HTTP‑native API** | Plain POST/GET, no special protocol | Easy integration from any language |

## Steps — Integrating Agentic Inbox with Hermes

### Step 1: Deploy Agentic Inbox Instance

```bash
# Clone and configure
git clone https://github.com/cloudflare/agentic-inbox.git
cd agentic-inbox

# Edit wrangler.toml
cat > wrangler.toml <<EOF
name = "hermes-inbox"
main = "src/index.ts"
compatibility_date = "2026-01-01"

[[durable_objects.bindings]]
name = "INBOX"
class_name = "Inbox"
script_name = "hermes-inbox"

[[routes]]
pattern = "inbox.hermes.ai/*"
zone_name = "hermes.ai"
EOF

# Deploy
npx wrangler deploy
```

Inbox URL pattern: `https://inbox.hermes.ai/:inboxId`

### Step 2: Assign Inbox ID to Hermes Agent

Each Hermes agent instance gets a unique inbox identifier:

```python
# During agent initialization
self.inbox_id = f"hermes_{uuid4().hex[:12]}"  # e.g., hermes_a1b2c3d4e5f6
self.inbox_url = f"https://inbox.hermes.ai/{self.inbox_id}"

# Register inbox URL with external services that need to call back
# e.g., Stripe webhook, GitHub webhook, Slack events
register_webhook(
    service="stripe",
    url=self.inbox_url,
    events=["payment_intent.succeeded", "invoice.payment_failed"]
)
```

Persist `inbox_id` so it survives restarts (stable identity).

### Step 3: Listen for Incoming Messages

**Option A: SSE long‑poll** (Hermes process runs continuously):

```python
import aiohttp
import asyncio

async def inbox_listener(self):
    async with aiohttp.ClientSession() as session:
        async with session.get(self.inbox_url, headers={"Accept": "text/event-stream"}) as resp:
            async for line in resp.content:
                if line.startswith(b"data:"):
                    message = json.loads(line[5:].strip())
                    await self.handle_message(message)

# Start asyncio task at agent startup
asyncio.create_task(inbox_listener())
```

**Option B: Periodic poll** (Hermes runs intermittently):

Since Durable Objects are pull‑based, implement pull endpoint:

```python
# In DO: GET /messages?since=timestamp  returns unread messages
GET https://inbox.hermes.ai/:inboxId/messages?since=2026-04-26T00:00:00Z
```

Hermes calls this endpoint on each start to drain backlog.

**Option C: Webhook forwarding to local Hermes URL**

Configure inbox to forward messages to Hermes's local HTTP server:

```python
# During setup: tell inbox where to send events
POST https://inbox.hermes.ai/:inboxId/config
{
  "webhook_url": "http://localhost:8080/hermes/webhook",
  "webhook_retry_policy": {
    "max_attempts": 5,
    "backoff": "exponential"
  }
}
```

Inbox then POSTs each message to Hermes webhook; if Hermes is down, inbox retries.

### Step 4: Stream Segregation

Use multiple streams to categorize messages:

```python
# Separate streams for different concerns
INBOX_STREAMS = {
    "payments": ["payment_confirmed", "payment_failed"],
    "alerts": ["system_alert", "risk_threshold_breached"],
    "tasks": ["task_completed", "task_failed"],
    "social": ["mention", "follow", "dm"]
}

# Hermes subscribes to relevant streams
# (Inbox automatically fans out to SSE listeners listening on any stream)
```

### Step 5: Deduplication & Exactly‑Once Processing

Optional, but recommended for idempotency:

```python
# Track processed message IDs in Ledger (avoid double‑processing)
processed = set()

async def handle_message(msg):
    msg_id = msg.get("id")
    if msg_id in processed:
        return  # already handled (duplicate)
    processed.add(msg_id)

    # Process...
    await process(msg)

    # Acknowledge (optional: mark as handled in DO)
    await mark_handled(msg_id)
```

**Warning**: SSE delivers every message; if Hermes restarts, may receive duplicates. Deduplication required for exactly‑once semantics.

### Step 6: Audit & Replay

All messages stored in DO SQLite are persistent:

```bash
# Inspect inbox contents (admin tool)
hermes inbox query --inbox-id agent_abc123 --stream payments --since 2026-04-25

# Export audit log
hermes inbox export --format jsonl > payments_audit_20260425.jsonl
```

Replay capability: re‑process historical messages for debugging or re‑conciliation.

### Step 7: Scaling & Multi‑Agent

Each agent gets its own inbox ID; DO instances scale independently based on request volume. Routes automatically route to correct DO instance based on `inboxId`.

For multi‑agent systems:
- Each sub‑agent has own inbox (agent_abc123_coder, agent_abc123_writer)
- Coordinator agent routes messages to appropriate sub‑agent inbox

### Step 8: Delete/Archive Old Inboxes

Inboxes accumulate messages. Periodic cleanup:

```python
# Retention policy: delete messages older than 90 days
POST https://inbox.hermes.ai/:inboxId/admin/expire?older_than_days=90
```

Archive before deletion if audit needed.

## Hermes Messaging Patterns with Agentic Inbox

### Pattern 1: Direct Agent‑to‑Agent

```python
# Agent A sends to Agent B
payload = {"command": "research", "topic": "quantum computing"}
requests.post(f"https://inbox.hermes.ai/agent_b_inbox_id", json=payload)

# Agent B receives instantly via SSE listener or webhook
```

### Pattern 2: Broadcast to Agent Group

Create a shared inbox for a team:

```python
# All "researcher" agents listen on inbox "team_research"
# Anyone can post to that inbox to broadcast a message
```

### Pattern 3: Request‑Response Correlation

```python
# Include correlation ID for tracking request lifecycle
message = {
    "id": uuid4(),
    "type": "payment_request",
    "correlation_id": "task_12345",
    "payload": {...}
}
# Response webhook includes same correlation_id → match to original task
```

### Pattern 4: Dead Letter Queue

After maximum webhook retries, move undeliverable messages to a `dead_letter` stream or external error tracking system (Sentry, Slack alert).

## Comparison to Alternatives

| Approach | Pros | Cons |
|----------|------|------|
| **Agentic Inbox (Durable Objects)** | Fully managed, HTTP-native, zero‑ops scaling, built‑in SQLite persistence | Cloudflare vendor lock‑in (but patterns portable) |
| **Redis Pub/Sub** | Fast, simple | No persistence by default; requires separate infra |
| **RabbitMQ / Kafka** | Mature, durable queues | Higher operational burden, protocol overhead |
| **Custom DB polling** | Full control | Polling latency, database load, complexity |
| **Webhooks without queue** | Simple | No retry; message loss on 5xx/timeout |

## Costs & Ops

| Resource | Estimated Cost (per month, small deployment) |
|----------|---------------------------------------------|
| Cloudflare Workers | $0.50‑$5 (first 100K requests free; $0.50/M thereafter) |
| Durable Objects | $0.20 per GB‑month storage + $0.50 per million requests |
| Data transfer | Minimal (webhooks only); included in Workers plan |
| **Total** | **≈ $5‑$20** for moderate agent traffic |

**Operational simplicity**: No servers to manage; Cloudflare handles scaling, replication, and durability.

## Pitfalls & Gotchas

- **Vendor lock‑in**: Code depends on Cloudflare Workers API; porting to other platforms requires reimplementation. Mitigate: abstract inbox interface behind `MessageBroker` protocol; implement alternate backends (Redis, PostgreSQL) as drop‑in replacements.
- **Idempotency required**: SSE pushes every message; duplicates occur if Hermes restarts mid‑stream or network blips. Design handlers to be idempotent or track processed IDs.
- **Message size limits**: DO storage limits (currently ~128 MB per object; individual message ≤ 1 MB). For large payloads, store externally (S3, database) and send reference URL.
- **Cold start latency**: First message to a new DO may incur ~50‑100 ms initialization delay. Not significant for infrequent agents.
- **Regional data residency**: Cloudflare Workers global but may route to region; data compliance requires understanding DO placement.
- **Backpressure**: If Hermes consumer is slower than incoming rate, DO memory grows. Implement rate‑limiting or batch pulls.
- **Ordering guarantees**: Within a single stream, messages are ordered (FIFO). Across streams, no ordering guarantee.
- **Webhook retry storms**: If many messages fail simultaneously, exponential backoff spreads retries; ensure DO timer budget not exceeded (each DO has CPU limits).
- **Monitoring gaps**: Cloudflare provides Workers metrics, but DO-specific metrics (message queue depth, SSE connections) require custom instrumentation.

## Advanced Features

### 1. Message Acknowledgment & Stream Cursor

Track per‑stream read position:

```python
# GET /stream/:name?after=<message_id>
# Returns only messages after known ID → enables checkpointed consumption
```

Hermes stores last read ID per stream; on restart, resumes from checkpoint.

### 2. Batch Delivery

For high‑throughput scenarios, support batch POST and batch SSE push to amortize overhead.

### 3. ACL & Authentication

Add JWT verification on message POST:

```python
# DO checks Authorization: Bearer <token>
# Token must match inbox owner's identity
```

Prevents unauthorized messages.

### 4. Message Retention Policies

Auto‑expire messages after N days or when storage quota exceeded (FIFO eviction).

### 5. Dead Letter Queues

After max retries, move failed webhook deliveries to a special `dead_letter` stream; optionally alert human operator.

## Configuration

```yaml
# ~/.hermes/agentic_inbox.yaml
inbox:
  base_url: "https://inbox.hermes.ai"
  default_stream: "default"
  reserved_streams: ["alerts", "tasks", "payments", "debug"]

webhook:
  enabled: true
  endpoint: "http://localhost:8080/hermes/webhook"
  retry_policy:
    max_attempts: 5
    base_delay_seconds: 2
    max_delay_seconds: 3600
    backoff: "exponential"

listener:
  mode: "sse"  # or "poll"
  reconnect_delay_seconds: 5
  heartbeat_timeout_seconds: 30

durability:
  retention_days: 90
  enable_archive: true  # also write to S3 before DO expiry
```

## Deploy Checklist

- [ ] Deploy Cloudflare Worker + Durable Object
- [ ] Reserve subdomain (e.g., `inbox.hermes.ai`) and point to Worker
- [ ] Generate stable inbox ID per Hermes agent (persist to config)
- [ ] Configure webhook endpoint (if using forwarding mode)
- [ ] Add SSE listener code to Hermes agent initialization
- [ ] Implement idempotent message handler (track processed IDs)
- [ ] Set up monitoring: DO storage usage, request count, error rate
- [ ] Test failure scenarios: network drop during delivery, duplicate messages, DO restart
- [ ] Document inbox IDs for each agent in ops manual

## References

- Cloudflare Durable Objects: https://developers.cloudflare.com/durable-objects/
- Agentic Inbox prototype: https://github.com/cloudflare/agentic-inbox
- Server‑Sent Events (SSE): https://developer.mozilla.org/en-US/docs/Web/API/Server-sent_events
- Idempotency best practices: Stripe API docs on idempotent requests
- Cloudflare Workers pricing: https://developers.cloudflare.com/workers/platform/pricing/
