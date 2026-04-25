# April 10, 2026 — Solana MEV Infrastructure Deep Dive

## Key Takeaways

Comprehensive research into Solana's MEV (Maximal Extractable Value) ecosystem — a $720M+ market dominated by Jito with transformative protocol upgrades underway.

### The MEV Landscape

- **MEV capture exceeded $720M in 2025** on Solana, driven by $1T+ DEX volume
- **Jito controls 97%+ of validator stake** — essentially the monopoly infrastructure layer
- **Daily MEV tips average ~3,800 SOL (~$380K/day)** in early 2026, up 58% from January
- Primary strategies: sandwich attacks, DEX arbitrage, liquidations, token sniping

### Jito's Architecture: The Three Pillars

1. **Jito-Solana (Validator Client)** — Modified Solana validator with `BundleStage` for atomic bundle processing (up to 5 transactions, all-or-nothing)
2. **Block Engine** — Off-chain sealed-bid auction system ranking bundles by tip-per-compute-unit
3. **Tip Distribution Program** — On-chain Merkle tree-based distribution of MEV to validators/stakers

The `dontfront` mechanism is a built-in sandwich protection — any transaction with a `jitodontfront` pubkey is guaranteed to appear first in any bundle.

### BAM: Block Assembly Marketplace

Jito's next-gen system replacing the closed-source Block Engine:
- **TEE-encrypted mempools** — transactions are private until execution
- **Cryptographic attestations** of transaction ordering (verifiable fairness)
- **Plugin framework** — developers build custom transaction ordering logic (CLOB matching, oracle updates, dark pools)
- Open-source, modular, with plugin marketplace economics

### Alpenglow & Constellation: Protocol-Level Rewrite

Two converging upgrades that will fundamentally reshape Solana:
- **Alpenglow**: Replaces Tower BFT + Proof of History → sub-second finality (100-150ms, down from 12.8s)
- **Constellation**: Multi-party ordering replacing single leader model, transparent bid-per-CU ranking
- Combined effect: the time window for MEV collapses, bundle economics shift, new opportunities emerge

### ACE: Application-Controlled Execution

Gives Solana apps control over their own transaction ordering:
- CLOBs ensure maker-priority matching
- Lending protocols define liquidation sequencing
- Oracles update prices in the same block they're consumed
- Four-phase roadmap extends through 2027+

### Jito Restaking & NCNs

Solana's EigenLayer equivalent:
- **Triple yield stack**: Base staking (~5.5-6%) + MEV tips (~2-6%) + Restaking rewards → ~8-12% APY
- **TipRouter NCN** decentralizes $674M in tip distribution via 18 node operators
- **VRTs (Vault Receipt Tokens)** — composable liquid restaking assets

### RL for MEV Bidding

A landmark paper (arXiv:2510.14642) shows RL agents capturing **81% of available profits** in MEV auctions:
- PPO-based bidding with continuous action spaces
- Structurally applicable to Jito's sealed-bid auction
- Could dominate current heuristic/static bidding strategies

### AI Agents & MEV: The Arms Race

"Quantum Predators" — AI systems in millisecond-scale battles:
- Predictive front-running with ML models
- Multi-chain MEV scanning
- AI-on-AI adversarial dynamics approaching Nash equilibria
- Agent-as-a-Service platforms democratize MEV extraction

### Connections to Our Work

- Any Solana DeFi app must handle MEV — Jito Bundles + `dontfront` are table stakes
- BAM Plugins are a new development surface for custom ordering
- RL bidding on Jito is a concrete research + engineering opportunity
- Alpenglow's 150ms finality requires rebuilding transaction pipelines

---

*Note: Daydreaming session, architecture research, and news digest did not run tonight — only deep tech research completed.*
