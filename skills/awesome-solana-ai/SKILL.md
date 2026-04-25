---
name: Awesome Solana AI
description: Solana-based AI agent patterns for wallet management, on-chain verification, tokenized identity, and 24/7 agent infrastructure
trigger: Need to implement secure, policy-based financial operations, agent identity, and verifiable AI actions on Solana blockchain
---

## Overview

The Solana Foundation's Awesome Solana AI repository is a curated collection of projects and resources at the intersection of artificial intelligence and the Solana blockchain. Solana's high throughput (65,000+ TPS), low transaction costs (~$0.00025), and mature DeFi infrastructure make it an ideal platform for autonomous AI agent economies requiring frequent, low-cost interactions.

The research focused on patterns related to autonomous AI agents: wallet and identity management, on-chain AI verification (proof-of-inference), token/credit systems, MPC/key management, and 24/7 agent infrastructure. Key projects include Mizu (policy-based wallets), Ritual Net (zk-inference receipts), Modelfarm (token-curated model marketplace), Lit Protocol (decentralized key management), and Agent-Infra (persistent agent operations).

These patterns directly inform Hermes's Solana USDC adapter and agent identity layer, addressing critical needs for secure delegation, verifiable actions, and continuous operation.

## Integration Opportunities

### Pattern 1: Tiered Wallet Control with Delegation
**Projects**: Mizu, Lit Protocol, OpenZeppelin

Many AI agent platforms implement a two-tier wallet architecture:
- ** Holder/Controller key** — Human-controlled, high-security, sets policy
- ** Agent execution key** — Lower privilege, time-locked, revocable

**Concrete Implementation**: Mizu's policy engine on Solana allows defining transaction rules (max per-tx amounts, allowed destinations, time windows) that the agent key can execute within. The policy is stored on-chain and enforced via a smart contract wallet (Solana program) requiring agent signatures subject to policy checks.

**Why adopt**: Hermes could implement similar policy enforcement in its Solana USDC adapter, allowing users to create agent sub-wallets with spending limits and destination whitelisting, improving security for autonomous operations.

### Pattern 2: On-Chain Inference Receipts with zk-Verification
**Projects**: Ritual Net, zkLLM, Modulus Labs

Projects provide ways to prove that AI inference occurred and matches expected computations without revealing private model weights or input data. The typical flow:
1. Agent submits inference job with a commit hash of model weights
2. ZK circuit proves "output y came from running model M on input x"
3. Proof is posted on-chain as NFT/receipt
4. Validation program checks proof validity against model registry

**Why adopt**: If Hermes ever performs AI-driven decisions or needs to prove to Solana that an external action was AI-verified (e.g., a trade decision), it could store an inference receipt as proof. This adds auditability and trust, especially valuable for agent-to-agent interactions and governance.

### Pattern 3: Token-Based Agent Identity & Credit System
**Projects**: Modelfarm, Token Metrics

AI agents on Solana increasingly have their own tokenized identity—an agent is not just a wallet address but an on-chain entity with its own token or credit score. Key aspects:
- **Agent NFTs**: Unique identity tokens representing the agent; used to authenticate interactions
- **Credit/Stake**: Agents hold native tokens or staked SOL to prove reliability; slashed for misbehavior
- **Reputation**: On-chain record of completed tasks; builds future trust

**Why adopt**: Hermes could issue agent identity tokens representing different capability sets; users could stake to "upgrade" their agent's permissions. This creates a verifiable, tradable agent identity layer useful for cross-protocol authorizations.

### Pattern 4: 24/7 Agent Infrastructure with Fault Tolerance
**Projects**: Agent-Infra, Autonolas, Wayfinder

Infrastructure stacks exist specifically for persistent Solana agents, including monitoring, health-checks, and auto-restart mechanisms. Key capabilities:
- **Health monitoring**: Continuous liveness checks with automatic restart on failure
- **State persistence**: Regular snapshots to recover from crashes without loss
- **Failover coordination**: Distributed agent coordination with uptime guarantees
- **Fleet management**: Treasure fleet architecture for running multiple agents in a managed fleet

**Why adopt**: Hermes's 24/7 operation requirement directly benefits from these production-grade reliability patterns. Adopting infrastructure-level fault tolerance ensures continuous operation even during node failures or network partitions.

## Steps

1. **Implement policy-based sub-wallet creation for USDC operations** (Week 1-2)
   - Build a Solana program (smart contract) that acts as a "wallet factory"
   - Allow primary user wallet to create controlled agent sub-wallets with enforceable policies
   - Policy features: per-transaction limits (e.g., max 500 USDC), daily/weekly caps, destination whitelisting, time window restrictions
   - Implement policy checks at the program level so even compromised Hermes instances cannot violate rules
   - Create JavaScript/TypeScript client library to interact with the wallet program
   - Test with various policy configurations and edge cases

2. **Design and issue agent identity NFTs** (Week 3-4)
   - Create Metaplex-compliant NFT standard (or SPL token variant) for agent identity
   - NFT metadata schema: name, capabilities list (supported operations), model hash (sha256 of agent code), trust score, registration timestamp, owner address
   - Implement registry program to mint non-transferable identity NFTs tied to agent keypairs
   - Enable capability-based authorization: other protocols can verify an agent's NFT to check allowed operations
   - Add reputation scoring mechanism that updates based on successful/failed transactions
   - Develop UI/UX for displaying and verifying agent credentials

3. **Develop inference receipt system (optional, advanced)** (Week 5-6)
   - Research and integrate with existing proof-of-inference networks (Ritual Net, zkLLM) or build custom solution
   - Create receipt schema: `{model_id, input_commitment, output_action, timestamp, executor, proof}`
   - Implement receipt generation and submission flow: after AI decision, create cryptographic receipt and submit to Solana program
   - Optionally generate ZK proofs using circom/cairo circuits if privacy is required
   - Store receipt hashes on-chain with full proof available off-chain or in program account
   - Use receipts for audit trails, governance evidence, and reputation building

4. **Implement key management and security layer** (Week 7)
   - Integrate Lit Protocol or build custom MPC-based key management for agent wallets
   - Design key rotation policies and recovery mechanisms
   - Implement multi-signature requirements for high-value operations
   - Add time-locked vaults for treasury management
   - Create emergency revocation procedures for compromised agent keys
   - Document security assumptions and threat model

5. **Set up 24/7 infrastructure with monitoring** (Week 8)
   - Deploy Hermes nodes with process supervisors (systemd, PM2, or dedicated agent-infra patterns)
   - Implement health check endpoints for liveness and readiness probes
   - Set up automated restart policies and crash recovery
   - Configure monitoring: metrics (Prometheus), logs (structured JSON), alerts (Slack/PagerDuty)
   - Implement state snapshotting: periodic persistence of agent state for fast recovery
   - Design failover: hot standby nodes that can take over if primary fails
   - Test failure scenarios: network outage, process crash, database corruption

## Pitfalls

- **Policy enforcement bypass**: Smart contract bugs could allow agent to bypass spending limits. Conduct thorough security audits and formal verification where possible.
- **On-chain storage costs**: Storing inference receipts or NFT metadata on Solana, while cheap at individual transaction level, can accumulate. Implement efficient data structures and consider off-chain storage with on-chain anchors.
- **Key compromise risk**: If agent execution key is stolen, attacker can act within policy limits. Use MPC or multi-sig for high-value operations; implement rapid revocation mechanisms.
- **ZK proof generation overhead**: Generating zero-knowledge proofs can be computationally expensive and slow. Reserve for high-value/high-trust scenarios where benefits justify cost.
- **Identity accrual costs**: Building reputation through on-chain activity requires actual transactions and time. Plan initial bootstrapping strategy.
- **Policy rigidity**: Overly restrictive policies may prevent legitimate profitable actions. Implement adaptive policies that adjust based on performance and trust metrics.
- **Cross-chain complexity**: If Hermes operates across multiple blockchains, identity and wallet abstraction layers become more complex. Design for multi-chain from the start.
- **Regulatory uncertainty**: Tokenized agent identities and on-chain AI verification may face regulatory scrutiny. Consult legal counsel and design for compliance flexibility.

## References

- Awesome Solana AI: https://github.com/solana-foundation/awesome-solana-ai
- Mizu: https://github.com/mizu-ai/mizu
- Solana Agent Kit: https://github.com/solana-labs/solana-agent-kit
- zkLLM: https://github.com/zkllm-project/zkllm
- Ritual Net: https://github.com/ritual-net/ritual
- Modulus Labs: https://github.com/ModulusLabs/modulus
- Modelfarm: https://github.com/modelfarm/modelfarm
- Lit Protocol: https://github.com/LIT-Protocol/LIT
- Agent-Infra: https://github.com/agent-infra/agent-infra
- Autonolas: https://github.com/autonolas/autonolas
- Solana Documentation: https://docs.solana.com
- Anchor Framework: https://github.com/coral-xyz/anchor
- Metaplex: https://metaplex.com
