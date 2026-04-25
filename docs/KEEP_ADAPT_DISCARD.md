# KEEP / ADAPT / DISCARD — Hermes Core Integration Recommendations

**Synthesis Date:** 2026-04-26  
**Source Reports:** obscura, claude-task-master, claude-ads, agentic-stack  
**Purpose:** Evaluate patterns and tools from research for integration into Hermes Agent core.

---

## Executive Summary

| Category | Keep | Adapt | Discard |
|----------|------|-------|---------|
| **Architectural Patterns** | 8 | 5 | 1 |
| **Tooling & Libraries** | 6 | 6 | 2 |
| **Workflow Processes** | 4 | 3 | 0 |
| **Infrastructure & Ops** | 3 | 2 | 1 |
| **Content & Prompting** | 2 | 4 | 0 |

**Total recommendations:** Keep 23, Adapt 20, Discard 4

**Bottom line:** The research reveals four highly complementary systems that can significantly strengthen Hermes. **Obscura** offers synthetic data for ML augmentation; **TaskMaster** provides structured AI planning; **Claude Ads** demonstrates multi-stage, safety-first content generation; and **Agentic Stack** presents an elegant modular agent framework. Integration should be incremental, starting with the least invasive patterns (tool decoration, prompt engineering) before tackling deeper architectural changes (DAG planning, memory abstraction).

---

## 1. ARCHITECTURAL PATTERNS

### 1.1 Task & Workflow Management

| Pattern | Recommendation | Rationale | Effort |
|---------|----------------|-----------|--------|
| **Recursive task decomposition** (TaskMaster) | **ADAPT** | Hermes already understands task breakdown, but lacks persistent DAG and auto-prioritization. Implement a lightweight version within Hermes core without external dependency. | Medium |
| **DAG-based dependency tracking** (TaskMaster) | **ADAPT** | Ensures correct execution order and prevents circular dependencies. Build a native DAG scheduler; don't embed TaskMaster itself (language mismatch). | Medium |
| **Session snapshots & isolation** (TaskMaster) | **KEEP** (learn) | Conceptually valuable for long-running projects; may overcomplicate Hermes's simpler session model. Keep as inspiration for future "project mode" feature. | Low |
| **Artifact-as-task-output** (TaskMaster) | **KEEP** | Close alignment with Hermes's file-generation workflows. Adopt this pattern: each Hermes job can produce tracked artifacts with version links. | Low |
| **Progressive elaboration** (TaskMaster) | **KEEP** | Top-down planning with lazy expansion matches Hermes's exploratory style. Use when user requests are vague; expand details as implementation proceeds. | Low |
| **Multi-stage pipeline** (Claude Ads: Strategy→Draft→Refine→Validate) | **KEEP** | Excellent template for complex content generation workflows in Hermes. Implement as pipeline abstraction with staging hooks. | Medium |
| **Reflection/self-correction loop** (Agentic Stack) | **KEEP** | Valuable for high-stakes tasks (code review, safety-critical analysis). Implement optional reflection pass after initial completion. | Medium |
| **Layered architecture** (Agentic Stack) | **KEEP** (learn) | The separation of Application/Orchestration/Tool/Memory/LLM is instructive. Use as documentation/design guide rather than immediate restructuring. | Low |

**Discard:** None significant. All patterns provide learning value.

---

### 1.2 Agent & Tool Patterns

| Pattern | Recommendation | Rationale | Effort |
|---------|----------------|-----------|--------|
| **Agent-as-function** (agentic-stack) | **KEEP** | Treats agents as callable units; aligns with Hermes's skill/tool model. Document and promote this mental model in Hermes docs. | Low |
| **Tool-Decorator with metadata** (agentic-stack) | **KEEP** | CLEAR WIN. Replace Hermes's current era/function-based tool registry with decorated tool classes that include rich metadata (description, examples, parameters). Enables LLM-driven discovery. | High |
| **Tool versioning & compatibility** (inferred from agentic-stack) | **ADAPT** | Tools evolve; need version negotiation with LLM. Add `tool_version` field to tool schemas; track breaking changes. | Low |
| **Agent protocol compatibility** (agentic-stack standardization) | **ADAPT** | Future-proofing: If agentic-stack's agent protocol gains adoption, implement a compatibility layer in Hermes. Not urgent yet. | Low |
| **Router-based dynamic flow** (agentic-stack) | **ADAPT** | Useful for complex workflows. Add a `Router` primitive to Hermes that can dispatch tasks to specific sub-agents or toolchains based on classification. | Medium |

**Discard:** None. All agent patterns are relevant.

---

### 1.3 Memory Patterns

| Pattern | Recommendation | Rationale | Effort |
|---------|----------------|-----------|--------|
| **Memory abstraction layer** (agentic-stack) | **ADAPT** | Hermes already supports multiple backends (built-in, Honcho, Mem0). Formalize the abstraction as an internal interface; ingest agentic-stack adapters as plugins. | Medium |
| **Three-tier memory** (STM / LTM / Graph) | **KEEP** | Good conceptual model. Hermes may not need all three immediately; prioritize unified search over separate tiers. | Low |
| **Episodic, semantic, procedural separation** | **DISCARD** (overengineered) | Too academic for Hermes's practical needs. Use simpler taxonomy: session memory, persistent knowledge, learned procedures. | N/A |

---

## 2. TOOLING & LIBRARIES

### 2.1 External Services

| Tool / Service | Recommendation | Rationale | Integration Path |
|----------------|----------------|-----------|-----------------|
| **Obscura AI (synthetic data)** | **KEEP** | Valuable for Hermes's ML augmentation capabilities — privacy-safe demo data, scenario testing, domain randomization. | Install SDK; add `obscura` tool wrapper; store API key in `.env`. |
| **Claude Ads framework** | **KEEP** | Effective for marketing-related user requests. Provides ready-made templates, brand profile system, platform adapters. | Import as Python module; register `claude_ads` skill; cache brand profiles locally. |
| **TaskMaster CLI (external)** | **ADAPT via native reimplementation** | TaskMaster's Node.js runtime conflicts with Hermes's Python base. Reimplement core patterns (DAG, recursive breakdown) natively; borrow prompt templates. | Phase 1: Call taskmaster CLI via subprocess (quick PoC). Phase 2: Build native `hermes.planner` module. |
| **Agentic Stack core** | **KEEP (selective)** | Valuable patterns, but full framework may be heavyweight. Extract individual patterns (tool decorator, memory abstraction) rather than adopting wholesale. | Implement patterns as Hermes libraries; don't add agentic-stack as runtime dependency. |

### 2.2 Platform & Infrastructure

| Component | Recommendation | Rationale |
|-----------|----------------|-----------|
| **Vector databases** (Chroma, Pinecone, Weaviate, Qdrant) | **KEEP** (as optional backends) | Hermes already supports multiple memory backends; continue expanding options. |
| **Redis** | **KEEP** | Excellent for shared state, caching, pub/sub between Hermes instances. Already used in some deployments; formalize integration. |
| **Docker / Kubernetes** | **KEEP** | Deployment best practices unchanged; ensure Hermes container images include new integrations (obscura, claude-ads). |
| **Terraform** | **ADAPT** | Consider Terraform modules for reproducible Hermes infrastructure (VM, networking, secrets). Not core to agent functionality. |
| **Prometheus / OpenTelemetry** | **KEEP** | Strongly recommended for observability; adopt agentic-stack's tracing patterns to instrument Hermes execution flows. |
| **HuggingFace Inference API** | **KEEP** | Useful for local model fallback and specialized tasks. Already supported; maintain. |
| **Weights & Biases** | **DISCARD** | ML experiment tracking is out of scope for Hermes agent core. Users can integrate separately if needed. |

---

## 3. WORKFLOW & PROCESS PATTERNS

| Workflow | Recommendation | Details |
|----------|----------------|---------|
| **Configuration-as-Code** (Obscura, TaskMaster) | **KEEP** | All Hermes config already YAML-based. Extend to skill parameters and dataset definitions. |
| **Deterministic seeding** (Obscura) | **KEEP** | Critical for reproducible AI behavior. Ensure all random operations (prompt sampling, tool selection) accept a seed; store seed in session metadata. |
| **Privacy by Design** (Obscura) | **KEEP** | Synthetic data avoids PII; extends to Hermes's data handling — minimize logging of sensitive inputs, offer local-only mode. |
| **A/B testing & optimization loop** (Claude Ads) | **ADAPT** | Useful for prompt optimization. Create a `prompt_ab_test` tool that runs variants and scores outputs; use for Hermes's self-improvement. |
| **Brand / policy compliance** (Claude Ads multi-layer filters) | **KEEP** | Adapt the safety filter architecture for Hermes: pre-execution validation, post-execution audit, user-configurable guardrails. |
| **Iterative improvement** (feedback → learn → regenerate) | **KEEP** | Core to Hermes's learning. Formalize feedback collection (thumbs up/down, corrections) and use to refine future behavior. |
| **User preference collection** (Claude Ads audience analysis) | **KEEP** | Hermes already uses profiles; enhance with structured preference schemas and automatic application. |
| **Daily consolidation cron** (seen in daily-learnings skill) | **KEEP** | Existing pattern in Hermes ecosystem (nightly research pipeline). Maintain and extend to other aggregation tasks. |

---

## 4. PROMPTING & CONTENT STRATEGIES

| Strategy | Recommendation | Implementation |
|----------|----------------|---------------|
| **Template-based prompting with variable substitution** | **KEEP** | Hermes already uses templates; extract into a dedicated `PromptTemplate` library with Jinja2 syntax, validation, and examples. |
| **Chain-of-thought** | **KEEP** | Default for complex reasoning tasks; ensure Hermes's system prompts include CoT instructions when appropriate. |
| **Few-shot learning** (Claude Ads) | **KEEP** | Maintain a curated example bank per skill; LLM selects relevant examples dynamically based on task similarity. |
| **Persona-based generation** (Claude Ads) | **ADAPT** | Useful for role-play or style-specific outputs. Implement `--persona` flag or system prompt override on a per-skill basis. |
| **Multi-model racing** (ULTRAPLINIAN concept) | **ADAPT** | Useful for finding least-censored or highest-quality response. Implement parallel calls to multiple LLM providers; return best via criteria selector. Add cost-aware routing. |
| **Input-side obfuscation** (Parseltongue pattern) | **DISCARD** | Though interesting for red-teaming, bypassing safety filters conflicts with Hermes's responsible AI principles. Exclude from core. |

---

## 5. SPECIFIC RECOMMENDATIONS BY RESEARCH REPORT

### 5.1 Obscura AI Integration

**KEEP:**
- Synthetic data generation as a first-class Hermes capability
- Scene description DSL (JSON/YAML-based) for reproducible scenario definition
- Domain randomization for robust model training
- Automatic annotation generation (bounding boxes, segmentation)
- Deterministic seeding for reproducible results

**ADAPT:**
- The asset library concept — maintain a Hermes-specific library of common scene templates (code snippets, config templates, example datasets)
- Remote job queueing with async callbacks — apply to long-running Hermes tasks (training, large downloads)
- "Hermes-as-Obscura-client" pattern — wrapper that translates natural language scene descriptions into Obscura JSON

**DISCARD:**
- No major discards; Obscura's patterns are clean and applicable.

**Implementation Priority:** MEDIUM — Useful but niche; enable for users in ML/CV domains; not core to general Hermes usage.

---

### 5.2 Claude Task Master Integration

**KEEP:**
- Task entity model (id, title, description, status, priority, dependencies, subtasks, artifacts)
- DAG-based dependency resolution and topological sorting
- "Next task" recommendation algorithm (readiness = no incomplete deps + highest priority)
- Artifact file tracking tied to task completion
- Markdown/JSON/Mermaid export for user-facing progress reports

**ADAPT:**
- Recursive AI breakdown: Use Claude API to decompose complex user requests into sub-tasks, but **reimplement in Python**. Borrow prompt templates from TaskMaster, but don't depend on Node.js runtime. Create `HermesPlanner` module.
- Session snapshots: Lightweight version — snapshot Hermes's memory state and task tree at user-defined checkpoints; enable rollback.
- CLI command set: Consider adding `hermes plan`, `hermes task add`, `hermes task next` if user demand justifies; otherwise keep as internal module.

**DISCARD:**
- Full TaskMaster CLI tool as an external dependency — too much integration friction (Node.js runtime, separate config).
- Complex session isolation model — Hermes already has session management; TaskMaster's may conflict.

**Implementation Path:**
1. Phase 1 (PoC): Call taskmaster CLI via subprocess, parse JSON output.
2. Phase 2: Build `HermesPlanner` native Python class with DAG and recursive breakdown via Claude.
3. Phase 3: Tie planner directly into `hermes chat` — when request complexity > threshold, auto-plan and execute.

---

### 5.3 Claude Ads Integration

**KEEP:**
- Brand profile YAML schema — excellent structure for user preference persistence
- Multi-stage pipeline (strategy → draft → refine → validate)
- Platform-specific adapter pattern (Google Ads, LinkedIn, Facebook specs as YAML)
- Safety layer: toxicity/misinformation/brand safety checks as pre-deployment gate
- A/B testing loop with performance feedback integration

**ADAPT:**
- Campaign brief YAML format — generalize to "project brief" template for non-ad use cases (software projects, research papers, event planning)
- CLI tool as skill: `hermes ads generate ...` — expose subset for marketing users
- Analytics dashboard — deferred; out of scope for core Hermes

**DISCARD:**
- Heavy platform-specific integration code (Google Ads API, Facebook Marketing API) — outside Hermes's mandate (API wrappers exist elsewhere)
- Ad-specific metric tracking (CTR, ROAS) — irrelevant unless Hermes is deployed as marketing agent

**Implementation Priority:** MEDIUM-HIGH — Brand profile system and pipeline pattern broadly applicable. Safety validation pattern also transferable.

---

### 5.4 Agentic Stack Integration

**KEEP (Adopt Patterns):**
- Tool-Decorator pattern — **HIGH PRIORITY**. Replace era-based tool registration with decorated classes.
- Memory abstraction — formalize interfaces; support multiple backends via adapters.
- Reflection loop — optional self-critique after task completion; use Claude call to evaluate output.
- Agent-as-function mental model — document and promote in Hermes developer guide.
- Observability (tracing, metrics, structured logging) — adopt OpenTelemetry standards.

**ADAPT (Implement Selectively):**
- Multi-agent collaboration: Build a lightweight `Router` agent, not full agentic-stack orchestrator.
- Layered architecture document: Use as design doc for Hermes 2.0 architecture review.
- Standardized agent protocol: Monitor; adopt if/when it becomes industry standard.

**DISCARD:**
- The full agentic-stack monorepo as a dependency — Hermes is more mature; don't add large external framework.
- Complex memory tiers (episodic/semantic/procedural) — overkill for current Hermes use cases.
- Most sub-repositories (tools, memory, orchestrator, protocol as separate packages) — unnecessary indirection.

**Implementation Priority:** HIGH — Tool decorator pattern is foundational; memory abstraction and reflection are high-value additions.

---

## 6. PRIORITIZED INTEGRATION ROADMAP

### Phase 1 (Next 2–4 weeks) — Low-Hanging Fruit
- [ ] **Tool Metadata System**: Add `@tool` decorator with description, parameters, examples; auto-generate JSON Schema for LLM.
- [ ] **Deterministic Seeding**: Ensure all random operations accept a global seed; store in session metadata.
- [ ] **Brand Profile System**: Borrow schema from claude-ads; create `~/.hermes/brands/` directory structure; implement profile loading utility.
- [ ] **Safety Validation Layer**: Simple pre-execution filter (toxicity, PII detection) and post-execution audit log; config per user.

### Phase 2 (1–2 months) — Core Architecture
- [ ] **Native Planner Module**: Build `hermes.planner` with DAG, recursive breakdown via Claude, artifact tracking. Deprecate external taskmaster CLI.
- [ ] **Memory Abstraction Interface**: Define `MemoryBackend` abstract class; wrap existing backends; open plugin system.
- [ ] **Reflection Loop**: Add `--reflect` flag to `hermes chat`; after initial response, invoke self-critique and revision (additional LLM call).
- [ ] **Multi-Stage Pipeline Framework**: Generic `Pipeline` abstraction with stages; apply to content generation (inspired by claude-ads).

### Phase 3 (2–4 months) — Advanced Features
- [ ] **Obscura Integration**: `obscura` tool wrapper; scene DSL parser; dataset generation utility.
- [ ] **Router Agent**: Simple task classifier that routes to specialized sub-agents or toolchains.
- [ ] **A/B Test Prompt Tool**: Run multiple prompt variants, score outputs, select winner.
- [ ] **Session Snapshot & Rollback**: Checkpoint Hermes state; `hermes rollback <snapshot>`.
- [ ] **Observability Stack**: OpenTelemetry integration; structured JSON logs; metrics endpoint for Prometheus.

### Phase 4 (4–6 months) — Ecosystem Polish
- [ ] **Asset Library**: Curated collection of Hermes templates (scene definitions, code snippets, prompt templates).
- [ ] **Platform Adapters**: Generic framework for external API integrations (ads, cloud services); plug in specific adapters as community contributions.
- [ ] **Advanced Safety**: Model mutation detection, jailbreak attempt flagging, policy violation reporting.

---

## 7. RISKS & MITIGATIONS

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| **Over-engineering**: Adding patterns before they're needed | High | Medium | Adopt incrementally; each feature must have a clear user story. |
| **API cost explosion**: Multi-stage pipelines, reflection, A/B testing increase LLM calls | High | High | Token budgeting, caching, user confirmation before expensive operations. |
| **Complexity debt**: More abstractions → harder to maintain | Medium | High | Keep core simple; put advanced patterns behind feature flags, in optional modules. |
| **Vendor lock-in**: Tight coupling to Claude API | Medium | Medium | Abstract LLM calls behind provider interface; document alternatives. |
| **Performance regression**: Additional layers add latency | Medium | Medium | Benchmark before/after; lazy-load optional components. |
| **Abandoned integrations**: Research repos may become unmaintained | Medium | Low | Track fork activity; be prepared to fork/maintain if needed (MIT license permits). |

---

## 8. GLOSSARY

- **DAG**: Directed Acyclic Graph — data structure representing tasks with dependencies, ensuring topological ordering.
- **STM**: Short-Term Memory — context window management for immediate reasoning.
- **LTM**: Long-Term Memory — persistent knowledge store, often vector-based for semantic search.
- **RAG**: Retrieval-Augmented Generation — technique for grounding LLM responses in external knowledge.
- **LLM**: Large Language Model — the AI model powering Hermes (Claude, GPT, etc.).
- **PTY**: Pseudo-terminal — interactive shell session needed for some tools.
- **PII**: Personally Identifiable Information — sensitive data that synthetic data aims to avoid.

---

## 9. NEXT STEPS FOR HERMES CORE TEAM

1. **Review this document** with architecture and product stakeholders.
2. **Prioritize Phase 1 items** in upcoming sprint planning.
3. **Assign owners** for each integration stream (Tool System, Planner, Memory, Safety).
4. **Set up research sandbox**: Clone or fork the four repos; experiment with patterns in isolation.
5. **Schedule bi-weekly syncs** with agentic-stack and TaskMaster maintainers (if outreach feasible).
6. **Update HERMES.md** with integrated knowledge from this synthesis.
7. **Begin implementation** of tool decorator pattern as foundational change; all other modules depend on it.

---

*End of KEEP/ADAPT/DISCARD report.*
