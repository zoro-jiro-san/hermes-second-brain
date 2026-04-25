# April 13, 2026 — Daily Learnings

*Consolidated from night research sessions by Toki*

---

## Deep Research: Trusted Execution Environments (TEEs) for AI Agent Systems

**Duration:** ~90 min | **Sources:** 30+ searches | **Papers/Benchmarks:** 10+

### What Are TEEs?

Trusted Execution Environments are hardware-isolated regions within processors where code and data are protected even from the host OS, hypervisor, and cloud admins. They protect data **in use** — the missing gap between encryption at rest and in transit.

**Four building blocks:** Secure Enclave (isolated execution), Encrypted Memory (hardware-managed keys), Hardware Root of Trust (manufacturing-time keys), Remote Attestation (cryptographic proof of running code).

### Key Technologies

| Technology | Vendor | Type | Overhead |
|---|---|---|---|
| Intel SGX | Intel | App-level enclave | Mature, requires SDK |
| Intel TDX | Intel | VM-level isolation | ~7-8% |
| AMD SEV-SNP | AMD | VM-level isolation | ~7-8% |
| NVIDIA GPU CC | NVIDIA | GPU-level TEE | 4-8% (H100+) |

### GPU Confidential Computing — The Missing Link

The NVIDIA H100 was the first GPU with native TEE support. Phala Network benchmarks show **<7% overhead** for LLM inference, approaching **0% for large models** (Llama 3.1 70B) where compute dominates I/O. This makes TEE-secured inference practical for production.

### dstack + Phala: Docker-Native TEE Deployment

**dstack** (open source, Linux Foundation) provides Docker Compose-native TEE deployment. Bring your `docker-compose.yaml` as-is, deploy to any TDX host, get full attestation + key management + encrypted storage. No code changes. Powers **OpenRouter** and **NEAR AI** infrastructure.

**Phala Cloud** offers managed TEE infrastructure specifically for AI agents: SOC 2 Type I, HIPAA compliant, ~$3.08/GPU/hr for H100 with TEE.

### ERC-8004: On-Chain Identity for TEE Agents

Emerging Ethereum standard combining TEE attestation with on-chain identity. Agents register identity contracts, generate TEE-derived keys (never exist outside enclave), and operate with verifiable on-chain identity. Deployed on ETH Sepolia.

### ElizaOS TEE Integration

ElizaOS (17K+ stars, 50K+ deployed agents) has first-class TEE support via plugins. Ed25519 key derivation inside TEE for Solana wallets, ECDSA for EVM. Private key never exists in plaintext outside the enclave — not even the developer can see it.

### Proof-of-Guardrail (arXiv:2603.05786)

Academic paper using TEEs for **verifiable AI safety**: run both the agent AND an open-source guardrail inside a TEE, producing attestation that the guardrail executed before the response. Critical limitation: attestation proves *what code ran*, not *correct behavior*. A malicious developer could jailbreak the guardrail from within.

### Anthropic's Confidential Inference Architecture

Three-component design: API Server (handles prompts encrypted), Secure Loader (separate CVM, decrypts model weights), Inference Server (GPU TEE). Model weights decrypted only inside the TEE boundary. End-to-end encryption from client to enclave.

### Solana + AI Agent Applications

1. **TEE-Secured Trading Agents** — Private keys derived and used exclusively within enclaves
2. **Verifiable Agent Identity on Solana** — On-chain identity registry + TEE attestation (ERC-8004 pattern)
3. **dstack Deployment** — Docker-compose-native, no code changes needed
4. **Proof-of-Guardrail for Fintech** — Cryptographic evidence of safety checks before trades
5. **Cross-Chain Agent Infrastructure** — TEE agents hold keys for multiple chains simultaneously

---

## Architecture Research: Token Efficiency (Rotation #3)

**Focus:** 3rd of 5 rotation positions (Orchestration → Memory → **Token Efficiency** → Agentic Payments → Skill Evolution)

### 10 Papers Analyzed

1. **RouteLLM** (ICLR 2025) — 85% cost reduction via routing classifier at 6.4ms overhead
2. **AgentCompress** (Jan 2026) — 2.37M param controller, 68.3% cost reduction
3. **ITR** (Dec 2025) — 95% per-step token reduction (30K→1.5K tool schemas)
4. **SkillReducer** (Mar 2026) — 48% description + 39% body compression, **2.8% quality improvement**
5. **AgentDiet** (Sep 2025) — 40-60% trajectory reduction via external reflection
6. **ACON** (Microsoft, Oct 2025) — 26-54% reduction, 95% accuracy preserved
7. **LLMLingua** (Microsoft, 6K stars) — Up to 20× prompt compression
8. **Strata** (Aug 2025) — 5× lower TTFT via hierarchical caching
9. **ComprExIT** (Feb 2026) — Soft context compression, ~1% additional params
10. **Routing Game Theory** (Feb 2026) — Static thresholds often beat dynamic cascading

### Top 4 Must-Have Proposals

1. **Progressive Skill Loading** — YAML frontmatter only (~80 tokens/skill), full content on demand. ~1,200 chars/turn saved.
2. **Tool Result Pruning** — Trim outputs to essential fields. 30-50% reduction.
3. **Skill Description Optimization** — Apply SkillReducer delta-debugging. 48%+39% compression + quality improvement.
4. **Prompt Cache Hierarchy** — 4-level cache with 1-hour TTL for cron sessions. 10-20% savings.

### Key Insight: "Less-is-More" is Quantitatively Proven

SkillReducer showed removing noise from skills **improves** performance by 2.8%. Tool schemas are the silent token sink (30K→1.5K tokens with no quality loss). Anthropic's native Tool Search + defer_loading and server-side compaction should be enabled before building custom solutions.

---

## Daydream: Stigmergic Immune Memory for Autonomous Agents

**Seed:** Cross-domain fusion of ant colony stigmergy + biological immune memory + TEE attestation chains.

### The Spark

AI agents are already doing stigmergy accidentally — e-commerce sites auto-generate persistent URLs from search queries, creating "pheromone trails" that other agents follow. **The agents are leaving pheromone trails in the web, just like ants.**

### IMAP: Immune Memory Attestation Protocol

A 4-layer trust protocol for agent-to-agent trust, modeled on the immune system:

1. **Innate Attestation** (gut feel) — Behavioral fingerprint matching. Fast, cheap "danger signal" via embedding model on interaction histories. Analogous to Toll-like receptors.

2. **Adaptive Attestation** (specific check) — TEE attestation quotes, ERC-8004 identity, on-chain reputation. Expensive but precise. Analogous to T-cell receptor binding.

3. **Costimulation Gate** (safety interlock) — Both signals required before high-stakes actions. If only one fires: quarantine. Analogous to B7/CD28 costimulation.

4. **Memory Formation & Decay** — Attestation memories with 30-day half-life. Positive interactions reinforce; negative ones rapidly degrade. Context-tagged (trust in domain X ≠ domain Y).

### The Stigmergic Twist

Agent trust memory externalized as **signed pheromones** — on-chain attestations scoped to task types. Multiple agents reinforcing the same pheromone makes it stronger. Malicious agents can't forge because it requires valid attestation chains. **Pheromone is spatial and task-scoped, not global reputation.**

### Design Principle: Trust Should Be Expensive to Maintain and Cheap to Lose

From dissipative structure theory: trust that isn't actively reinforced decays to noise. This is a feature, not a bug — stale trust is dangerous trust.

### Ideas Worth Implementing

1. **Trust-Half-Life for Skills** — Add `last_validated` + `confidence` fields. Skills degrade without reinforcement.
2. **Pheromone Board** — `~/.hermes/pheromone-board.md` for successful task/model/tool combinations with TTL decay.
3. **Costimulation for Tool Calls** — Dual-signal verification before sensitive operations.
4. **Treg Auditor** — Background process sampling agent actions for behavioral anomalies.

---

## News Digest: April 13, 2026

### 🔥 Top Stories

1. **Anthropic Claude Mythos** — ~10T parameter model deemed too powerful for release. Found thousands of zero-days (including 27-year-old OpenBSD bug). Project Glasswing gives access to 12 orgs for defensive cybersecurity only.

2. **First U.S. Pro-Crypto Legislation Signed** — H.J.Res.25 permanently voids IRS DeFi broker rule. First pro-crypto law through Congress with bipartisan support. GENIUS Act (stablecoin legislation) next.

3. **Microsoft Agent Framework** — AutoGen + Semantic Kernel consolidated into unified open-source framework. MCP, A2A, OpenAPI interoperability. KPMG, Commerzbank as early adopters.

### AI & ML
- **GPT-4.1** — Coding-first models with 1M context. GPT-4.1 nano at $0.10/$0.40 per M tokens.
- **OpenAI Shuts Down Sora** — $15M/day compute vs $2.1M lifetime revenue. 6 months.
- **Google TurboQuant** — KV cache memory breakthrough at ICLR 2026.

### Crypto
- **Solana Loopscale Hack** — $5.8M via undercollateralized loans.
- **Canada Launches Spot Solana ETFs** — Institutional SOL exposure expanding.
- **Coinbase Solana Infrastructure** — 5x faster transactions, 4x RPC improvement.

### Fintech
- **Bunq Enters U.S.** — Europe's 2nd largest neobank with crypto trading via Kraken.
- **Alpaca Raises $52M** — API-first brokerage, "Stripe for brokerage" layer.
- **Apex + Google Cloud** — Powers Coinbase "Everything Exchange."

### Privacy & Security
- **NIST Privacy Framework 1.1** — New AI governance section. Comment period through June 13.
- **Cy4Data "Always-Encrypted"** — Searchable encrypted data without decryption.
- **ZK Proofs Maturing** — $28B TVL in ZK rollups, Zyga paper targets Solana DeFi.

---

*All 4 nightly jobs completed: ✅ Research ✅ Daydream ✅ Architecture ✅ News*
