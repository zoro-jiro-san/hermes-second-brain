# Daily Learnings — April 11, 2026

## Nightly Research Summary

Tonight's research focused on **AI Agent Memory Management** — deep research into 10 academic papers, 7 frameworks, and 3 provider patterns, plus a creative daydream session on stigmergy-inspired agent design and a comprehensive global news digest.

**Missing file:** `RESEARCH-2026-04-11.md` (deep tech research job did not produce a standalone research file tonight)

---

## 1. Deep Research: AI Agent Memory Management

### Papers Analyzed (10)

| Paper | Key Result |
|-------|------------|
| **Mem0** (ECAI 2025) | Graph-enhanced variant: 91% latency reduction |
| **Zep/Graphiti** (Jan 2025) | Temporal Knowledge Graph: 94.8% DMR accuracy |
| **FadeMem** (Jan 2026) | Dual-layer Ebbinghaus decay: 45% storage reduction at 82.1% retention |
| **G-Memory** (NeurIPS 2025) | 3-tier graph hierarchy for multi-agent systems |
| **SimpleMem** (2025) | 50× faster than Mem0 via semantic structured compression |
| **ByteRover** (2026) | Agent-native hierarchical Context Tree, zero external infra |
| **Context-Folding** (Oct 2025) | RL-trained active context management; 32K budget beats 327K baseline |
| **ACON** (2025-26) | Gradient-free compression: 26-54% token reduction |
| **TACITREE** (2025) | Hierarchical tree retrieval: 30% higher accuracy, 40-60% fewer tokens |
| **Adaptive Budgeted Forgetting** (Apr 2026) | Formalized forgetting as constrained optimization |

### Framework Benchmarks (LongMemEval)

| Framework | Accuracy | Pattern |
|-----------|----------|---------|
| Hindsight | 91.4% | Multi-strategy hybrid (semantic + BM25 + graph + temporal + cross-encoder) |
| Supermemory | 84.6% | Unified API with contradiction resolution |
| Zep | 71.2% | Temporal KG with 3-layer hierarchy |
| Mem0 | 66.9% | 4-scope memory with self-editing |
| Full-context baseline | 60.2% | No memory management (worse than selective retrieval!) |

### Key Insight: Full-Context Baselines Underperform
Just stuffing everything in context scores 60.2% on LongMemEval — **worse** than selective retrieval. This validates Hermes's approach of injecting only profile + memory + skills.

### Concrete Proposals for Hermes (7 improvements)

**Must-Have (3):**
1. **Progressive Skill Disclosure** — Inject YAML frontmatter only (~80 tokens/skill), full content on demand. Saves ~1,200 chars/turn.
2. **Memory Decay + Pruning** — Ebbinghaus curve with `strength = e^(-t/S)`, auto-prune at 0.05. Keeps 2,200-char budget focused.
3. **Anchored Iterative Summarization** — Replace simple compression with anchor document (intent, changes, decisions, next_steps).

**Should-Have (3):**
4. **Memory Scoping** — Hierarchical scopes (`/global`, `/platform/telegram`, `/project/hermes`).
5. **Hybrid Session Retrieval** — FTS5 + vector embeddings with RRF merging. 30-40% better recall.
6. **Temporal Awareness** — Bi-temporal timestamps and contradiction detection.

**Nice-to-Have (1):**
7. **Nightly Memory Consolidation** — Cron job to extract facts from daily sessions.

---

## 2. Daydream: Stigmergy-Inspired Agent Architecture

### Seed Concept
**Stigmergy** — how biological systems achieve complex coordination through environmental traces (ant pheromones, slime mold networks, mycorrhizal fungal webs), and what this means for AI agent design.

### Top 5 Insights

1. **Pheromone Decay Rates for Memory** — Different memory categories should have different decay rates (like ants having multiple pheromone types). User preferences: very slow. Task state: fast. Errors: "repellent" traces that prevent repeating failed approaches.

2. **Slime Mold Context Management** — Context window as a **flow network** where nodes (semantic units) compete for fixed "biomass" (context budget). Frequently-used pathways thicken; unused ones atrophy. Replaces the sharp cliff of summarization with a smooth gradient of relevance.

3. **Mycorrhizal Cross-Session Sharing** — Past sessions form a "fungal web" where successful patterns spread laterally. Sessions that are productive contribute more to the network than struggling ones.

4. **Stigmergic Tool Orchestration** — Tools leave traces in a shared workspace that make the next useful action obvious. The conversation state after each tool call should suggest the next step through its structure, not require explicit reasoning.

5. **"Use the World as Its Own Model"** — Rodney Brooks (1991) applied to cognitive agent design. A stigmergic agent offloads planning intelligence into the environment — the workspace, files, tool traces become the plan.

### Most Applicable Ideas

| Priority | Idea | Effort |
|----------|------|--------|
| 🔴 High | Pheromone decay rates for memory categories | Medium |
| 🔴 High | "Repellent traces" for failed approaches | Low |
| 🟡 Medium | Stigmergic tool workspace | High |
| 🟡 Medium | Flow-based context budgeting | High |
| 🟢 Exploratory | Cross-session mycorrhizal knowledge diffusion | Very High |

---

## 3. News Digest Highlights

### AI & Machine Learning
- **Microsoft Agent Framework 1.0** — Production-ready SDK for multi-agent AI workflows (.NET + Python). Unifies Semantic Kernel + AutoGen. First-class Microsoft product with LTS.
- **Google Gemma 4** — "Byte for byte, most capable open models" built from Gemini 3 technology. 400M+ downloads.
- **MiniMax M1** — First open-source hybrid-attention reasoning model.
- **White House AI Policy Framework** — Legislative recommendations for national AI regulation. Uncertain path through Congress.

### Crypto & Blockchain
- **Solana STRIDE** — Ecosystem-wide security overhaul after $286M Drift exploit. Formal verification requirements, multi-audit standards.
- **Aave V4** — Hub-and-spoke architecture decoupling asset storage from risk management. Biggest DeFi protocol upgrade this cycle.
- **Polymarket Overhaul** — Rebuilt trading stack + new stablecoin.
- **Ethereum ZK Roadmap** — EIP-8025 transitions from transaction re-execution to ZK proof verification for block validation.
- **BTC at $68.5K** — Between $67K support and $75.9K resistance. Extreme fear. CLARITY Act Senate markup mid-April is key catalyst.

### Fintech
- **SoFi 24/7 Business Banking** — First regulated US bank with native crypto settlement (including Solana). TradFi + crypto convergence at product level.
- **9fin $170M Series C** — AI-native credit market platform. One of the largest fintech AI rounds of 2026.
- **Variance $21.5M** — AI agents for compliance workflows. New category emerging.

### Privacy & Security
- **Niobium "The Fog"** — First FHE (Fully Homomorphic Encryption) cloud for AI. Process encrypted data without ever decrypting. If it performs, changes the game for AI privacy.

### Trending Themes
1. AI Agents → Production (MS Framework, compliance agents, credit AI)
2. Crypto Security Hardening (STRIDE, Aave V4 risk management)
3. Fiat-Crypto Convergence (SoFi, Polymarket stablecoin, CLARITY Act)
4. Privacy Tech Commercialization (FHE cloud, Ethereum ZK roadmap)

---

## Open Questions for Next Session

1. How to implement progressive skill disclosure without breaking existing skill loading?
2. What's the optimal decay rate (λ) for Hermes's memory categories?
3. Should we build our own anchored compressor or use Anthropic's server-side compaction API?
4. Can sqlite-vec provide hybrid retrieval or do we need a separate vector store?
5. What would a "repellent pheromone" system for agent error avoidance look like in practice?

---

*Consolidated by Toki • April 11, 2026*
