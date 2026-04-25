---
name: agentic-stack
description: Modular, composable framework for AI agent development — layered architecture, tool decorator pattern, memory abstraction, reflection loops, and multi-agent collaboration.
version: 1.0.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [agent-framework, llm-agents, orchestration, modularity, interoperability, tools, memory, multi-agent]
    related_skills: [hermes-agent, claude-task-master, opencode]
---

# Agentic Stack — Modular AI Agent Framework

The Agentic Stack is an open-source organization providing composable frameworks for AI agent development and orchestration. Core principles: **modularity** (reusable components), **interoperability** (multi-provider support), **transparency** (visible reasoning), and **extensibility** (custom behaviors). Adopt these patterns to build agents that are cleaner, more maintainable, and easier to extend.

## When to Use

Trigger when the user (or Hermes internal design) needs:
- A structured way to build new autonomous agents with clear separation of concerns
- Multi-LLM provider support (OpenAI, Anthropic, local models, etc.)
- Tool discovery and dynamic invocation patterns
- Memory abstractions for short-term, long-term, and graph-based memory
- Reflection/self-correction loops in agent reasoning
- Multi-agent collaboration protocols
- Observable, debuggable agent execution (tracing, metrics, logging)
- A learning roadmap for agent engineering best practices

## Prerequisites

- Python 3.10+
- LLM provider credentials (OpenAI, Anthropic, OpenRouter, or local inference)
- Basic understanding of async programming (async/await)
- Optional: Vector database for advanced memory (Chroma, Pinecone, Weaviate, Qdrant)

## Architecture — Layered Design

```
┌─────────────────────────────────────────┐
│         Application Layer               │
│    (User Workflows & Interfaces)       │
├─────────────────────────────────────────┤
│         Orchestration Layer             │
│    (Agent Coordination & Routing)      │
├───────────────┬─────────────────────────┤
│   Tool Layer  │    Memory Layer         │
│ (Capabilities │ (State & Knowledge      │
│  & Actions)   │  Persistence)           │
├───────────────┴─────────────────────────┤
│         LLM Provider Integration        │
│    (OpenAI, Anthropic, Local, etc.)    │
└─────────────────────────────────────────┘
```

## Core Design Patterns

### 1. Agent-as-Function Pattern
Treat agents as callable functions:
```python
async def run(task: str) -> AgentResult:
    # Accepts input, returns structured output
```
Enables easy composition and chaining of agent behaviors.

### 2. Tool-Decorator Pattern
Tools decorated with metadata (description, parameters, examples):
```python
@tool(
    name="weather_forecast",
    description="Get weather forecast for a location",
    parameters={
        "location": {"type": "string", "description": "City name"},
        "days": {"type": "integer", "default": 3, "max": 7}
    }
)
async def get_weather(location: str, days: int = 3) -> dict:
    return await weather_api.fetch(location, days)
```
LLMs dynamically discover and use tools based on metadata.

### 3. Memory Abstraction Layer
Unified interface for different memory backends:
```python
class MemoryBackend(ABC):
    @abstractmethod
    async def store(self, key: str, value: Any, metadata: dict = None): ...
    @abstractmethod
    async def search(self, query: str, k: int = 5) -> List[MemoryResult]: ...
    @abstractmethod
    async def delete(self, key: str): ...

# Implementations: VectorMemory, GraphMemory, EphemeralMemory, RedisBackend
```
Supports episodic, semantic, and procedural memory types.

### 4. Reflection Loop Pattern
Agents evaluate their own outputs and self-correct:
```
Plan → Act → Observe → Reflect → Revise
```
Implemented as iterative improvement cycles.

### 5. Multi-Agent Collaboration
Structured protocols for agent communication:
```python
router = Router({
    "code_task": agent_programmer,
    "writing_task": agent_writer,
    "analysis_task": agent_analyst,
    "default": agent_generalist
})
```
Roles and responsibilities are routable.

## Steps — Applying Agentic Stack Patterns to Hermes

### Step 1: Assess Current Hermes Architecture

Map Hermes's existing components to agentic-stack layers:
- **LLM Layer**: Identify which providers are already supported
- **Memory Layer**: What backends are used (built-in, Honcho, Mem0)?
- **Tool Layer**: Inventory of existing tools (filesystem, web, code execution)
- **Orchestration**: Current task queue or planning mechanism

Gap analysis: Which patterns are already present? Which are missing?

### Step 2: Modularize Hermes Tool System

Refactor tools into a discoverable registry:

```python
# Before: Flat tool list
tools = [FileReadTool, SearchTool, ShellTool]

# After: Decorated + metadata
@tool(name="file_read", description="Read file contents")
class FileReadTool(BaseTool):
    parameters = {
        "path": {"type": "string", "required": True}
    }
    async def execute(self, path: str) -> str: ...

# Registry
tool_registry = ToolRegistry()
tool_registry.register(FileReadTool)
all_tools = tool_registry.get_schemas()  # JSON Schema for LLM function-calling
```

**Benefits**: Dynamic loading, per-session tool selection, cleaner documentation.

### Step 3: Implement Layered Memory

Create a unified MemoryBackend abstraction:

```python
class HermesMemory:
    def __init__(self, short_term: WorkingMemory, long_term: VectorMemory, graph: GraphMemory):
        self.stm = short_term  # Context window management
        self.ltm = long_term  # Embedding-based retrieval
        self.graph = graph    # Entity-relationship storage

    async def remember(self, content: str, metadata: dict):
        await self.stm.store(content, metadata)
        await self.ltm.store(content, metadata)  # async background

    async def recall(self, query: str, k: int = 5) -> List[MemoryResult]:
        # Hybrid search: semantic + recency + graph traversal
        return await self.ltm.search(query, k)
```

**Integration**: Replace `HermesMemoryStore` implementations with this abstraction; keep existing backends as adapters.

### Step 4: Add Reflection Loop

Implement self-evaluation for critical tasks:

```python
class ReflectiveAgent:
    async def run_with_reflection(self, task: str, max_iterations: int = 3):
        result = await self.plan(task)
        for i in range(max_iterations):
            critique = await self.critique(result)
            if critique.confidence >= 0.9:
                return result
            result = await self.revise(result, critique)
        return result
```

Apply to: code generation, plan evaluation, risk assessment.

### Step 5: Design Multi-Agent Routing

For complex workflows (research → write → review → edit):

```python
pipeline = Pipeline()
pipeline.add_agent(researcher, name="research")
pipeline.add_agent(writer, name="write", depends_on=["research"])
pipeline.add_agent(reviewer, name="review", depends_on=["write"])
result = await pipeline.run(task)
```

Or dynamic router based on task classification.

### Step 6: Enhance Observability

Add tracing and metrics:

```python
@trace(name="agent_task", attributes={"agent": "researcher"})
async def execute_with_tracing(task: str):
    metrics = AgentMetrics()
    # Record latency, token usage, success rate
```

Export traces to console, file, or telemetry platform (Prometheus, OpenTelemetry).

### Step 7: Gradual Migration Path

1. **Phase 1**: Introduce tool decorator pattern on new tools only (backwards compatible)
2. **Phase 2**: Wrap existing tool invocations with new registry adapters
3. **Phase 3**: Implement MemoryBackend abstraction layer; migrate one backend at a time
4. **Phase 4**: Add reflection loops for specific agent types (e.g., `HermesCoderAgent`)
5. **Phase 5**: Build optional multi-agent orchestrator for complex user requests

## Triggers — When to Apply Specific Patterns

| Pattern | Trigger |
|---------|---------|
| Tool-Decorator | Adding new external integration; need clean schema generation for LLM |
| Memory Abstraction | Supporting multiple memory backends or adding a new vector DB |
| Reflection Loop | Tasks with high failure cost or where quality is subjective |
| Multi-Agent | Workflows with distinct phases requiring different expertise |
| Layered Architecture | Building a new agent subsystem from scratch |
| Observability | Need to debug agent behavior or optimize token usage |

## Pitfalls

- **Over-engineering**: Not every small task needs full agentic-stack machinery. Apply selectively to complex, autonomous behaviors.
- **Abstraction penalty**: Each layer adds indirection, which can complicate debugging. Keep the call stack visible in logs.
- **Memory consistency**: Across multiple memory backends, stale data can cause inconsistencies. Order writes carefully (STM → LTM → graph).
- **Tool registration overhead**: Dynamic discovery is great, but startup time grows with tool count. Lazy-load tools by category; cache schemas.
- **Reflection loop cost**: Each self-evaluation iteration calls the LLM again, doubling/tripling cost. Set a low `max_iterations` (2–3) and a confidence threshold to short-circuit.
- **Multi-agent orchestration complexity**: Routing errors can deadlock. Implement timeouts, fallback agents, and clear error messages.
- **Provider lock-in**: If all code uses provider-specific features, switching becomes hard. Abstract at the LLM call layer; use only features available across target providers.
- **Testing difficulty**: Non-deterministic LLM outputs make unit testing hard. Mock LLM responses for tool/reflection tests; use golden datasets for integration tests.

## Learning Resources

| Component | Study This |
|-----------|------------|
| Tools | `agentic-stack/core/tools/` directory |
| Memory | `agentic-stack/core/memory/` modules |
| Orchestration | `agentic-stack/core/orchestration/` |
| Examples | `agentic-stack/examples/` (minimal agent to multi-agent) |
| Docs | Repository READMEs per sub-project |

## References

- Organization: https://github.com/agentic-stack
- Core Framework: https://github.com/agentic-stack/core
- Tool Registry pattern: See `tools/base.py` and `tools/registry.py`
- Memory backends: `memory/vector.py`, `memory/graph.py`, `memory/stm.py`
