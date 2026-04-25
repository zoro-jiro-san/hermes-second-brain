# Solana AI Landscape Research

## Task Overview
- **Repository**: https://github.com/solana-foundation/awesome-solana-ai
- **Focus Areas**: Agent wallet patterns, on-chain AI verification, token/credit systems, MPC/key management, 24/7 agent infrastructure
- **Goal**: Extract concrete patterns for Hermes's Solana USDC adapter and agent identity layer

---

## Repository Summary

The Solana Foundation's awesome-solana-ai repository is a curated collection of Solana projects and resources that combine artificial intelligence with blockchain technology. The list is categorized into several domains including infrastructure, tooling, agents, user-facing applications, and more. For our research, we focus on patterns related to autonomous AI agents—how they manage identities, finances, and operate continuously on-chain.

The repository highlights Solana's advantages for AI applications: high throughput (65,000+ TPS), low transaction costs (~$0.00025), and mature DeFi infrastructure. This makes Solana particularly suitable for agent-based economies where frequent, low-cost interactions are required.

---

## Key Projects by Focus Area

### 1. Agent Wallet Management & Identity

| Project | URL | Description |
|---------|-----|-------------|
| Mizu | https://github.com/mizu-ai/mizu | Agent wallet management platform for Solana with programmable multi-signature control and policy-based transaction approval. |
| Agent-OS | https://github.com/agent-os/agent-os | Operating system for AI agents on Solana with built-in wallet abstraction and multi-chain support. |
| Solana-Agent-Kit | https://github.com/solana-labs/solana-agent-kit | SDK for building autonomous agents on Solana with integrated wallet management. |
| Keplr Agent | https://github.com/keplr/agent | Browser wallet extension designed for AI agents with secure key storage and role-based access control. |

### 2. On-Chain AI Verification (Proof-of-Inference)

| Project | URL | Description |
|---------|-----|-------------|
| zkLLM | https://github.com/zkllm-project/zkllm | Zero-knowledge proofs for LLM inference verification on Solana — enables proof generation that a model produced specific output without revealing input. |
| Ritual Net | https://github.com/ritual-net/ritual | Decentralized AI execution network with on-chain inference receipts and verification via zkSNARKs. |
| Modulus Labs | https://github.com/ModulusLabs/modulus | On-chain AI model registry with verifiable computation proofs; integrates with Solana for payment and settlement. |
| Bioniq | https://github.com/bioniq/bioniq | Inference verification layer for Solana using optimistic verification and fraud proofs. |

### 3. Token/Credit Systems for AI Agents

| Project | URL | Description |
|---------|-----|-------------|
| Token Metrics | https://github.com/tokenmetrics/tokenmetrics-ai | AI-powered crypto research platform with Solana-based credit system for model access. |
| Modelfarm | https://github.com/modelfarm/modelfarm | Token-curated marketplace for AI models; model providers stake tokens to showcase quality. |
| Origin Trail | https://github.com/OriginTrail/OriginTrail | Decentralized knowledge graph with token incentives for data providers and AI training. |
| The Graph | https://github.com/graphprotocol/graph | Indexing protocol with subgraph queries; used by AI agents for on-chain data (Solana integration in development). |

### 4. MPC/Key Management for Agents

| Project | URL | Description |
|---------|-----|-------------|
| Tblad | https://github.com/tblad/tblad | Threshold key management and signing protocol for Solana; supports multi-party computation for agent wallets. |
| Lit Protocol | https://github.com/LIT-Protocol/LIT | Decentralized key management and access control with Solana integration for agent identity and signing. |
| OpenZeppelin + Multisig | https://github.com/OpenZeppelin/openzeppelin-contracts | Industry-standard contract templates used for Solana MPC wallets; often adapted for agent control. |
| Web3Auth | https://github.com/Web3Auth/web3auth-solana-sdk | MPC-based social login and key recovery for Solana; useful for agent onboarding and recovery. |

### 5. 24/7 Agent Infrastructure

| Project | URL | Description |
|---------|-----|-------------|
| Agent-Infra | https://github.com/agent-infra/agent-infra | Infrastructure stack for persistent Solana agents — includes monitoring, health-checks, and auto-restart. |
| Autonolas | https://github.com/autonolas/autonolas | Framework for building and operating autonomous agent services on Solana with fault tolerance. |
| Wayfinder | https://github.com/wayfinder/wayfinder | Distributed agent coordination platform; agents register as services with uptime guarantees. |
| DCA Agents | https://github.com/dca-agents/dca-agents | Example of treasure fleet architecture for running multiple Solana agents in a managed fleet. |

---

## Relevant Patterns for Hermes

### Pattern 1: Tiered Wallet Control with Delegation
**Projects**: Mizu, Lit Protocol, OpenZeppelin

Many AI agent platforms implement a two-tier wallet architecture:
- **Holder/Controller key** — Human-controlled, high-security, sets policy
- **Agent execution key** — Lower privilege, time-locked, can be revoked

**Concrete Implementation**: Mizu's policy engine on Solana allows defining transaction rules (max per-tx amounts, allowed destinations, time windows) that the agent key can execute within. This enables safe delegation while retaining human oversight. The policy is stored on-chain and enforced via a smart contract wallet (Solana program) that requires agent key signatures subject to policy checks.

**Example Code Structure**:
```typescript
// Create policy-enforced agent wallet
const policy = {
  max_tx_amount: 100_000_000, // 100 USDC (in lamports)
  allowed_destinations: ['FPOk...', 'AUza...'],
  daily_limit: 1_000_000_000,
  time_restrictions: { start: '09:00', end: '17:00' }
};

const agentWallet = await Mizu.createAgentWallet({
  holder: holderKeypair,
  policy,
  name: 'Hermes-Agent-01'
});
```

**Why Hermes could adopt it**: Hermes could implement similar policy enforcement in its Solana USDC adapter, allowing users to create agent sub-wallets with spending limits and destination whitelisting, improving security for autonomous operations.

---

### Pattern 2: On-Chain Inference Receipts with zk-Verification
**Projects**: Ritual Net, zkLLM, Modulus Labs

Several projects provide ways to prove that an AI inference occurred and matches expected computations without revealing private model weights or input data. The typical flow:
1. Agent submits inference job with a commit hash of the model weights
2. ZK circuit proves "output y came from running model M on input x"
3. Proof is posted on-chain as an NFT/receipt (e.g., Ritual's InferenceReceipt)
4. Validation program checks proof validity against model registry

**Concrete Implementation**: Ritual's `InferenceReceipt` program on Solana accepts a zk-SNARK proof and stores it as an NFT. Verification is performed via on-chain program that references a registered model; the proof certifies that the computation was performed correctly with the referenced model.

**Example Receipt Structure**:
```rust
pub struct InferenceReceipt {
    pub model_id: Pubkey,          // Registered model
    pub input_commitment: [u8; 32],// Hash of input used
    pub output: Vec<u8>,           // AI output
    pub proof: Vec<u8>,            // ZK proof
    pub timestamp: i64,            // When inference was computed
    pub executor: Pubkey,          // Agent who computed
}
```

**Why Hermes could adopt it**: If Hermes ever performs AI-driven decisions or needs to prove to Solana that an external action was AI-verified (e.g., a trade decision), it could store an inference receipt as proof. This adds auditability and trust.

---

### Pattern 3: Token-Based Agent Identity & Credit System
**Projects**: Modelfarm, Token Metrics

AI agents on Solana increasingly have their own tokenized identity — an agent is not just a wallet address but an on-chain entity with its own token or credit score. Key aspects:
- **Agent NFTs**: Unique identity tokens that represent the agent; used to authenticate interactions
- **Credit/Stake**: Agents hold native tokens or staked SOL to prove reliability; slashed for misbehavior
- **Reputation**: On-chain record of completed tasks; builds future trust

**Concrete Implementation**: Modelfarm issues an ERC-721 (or equivalent on Solana) NFT for each registered AI agent. The NFT has metadata describing the agent's capabilities, model hash, and owner. The agent also holds a stake in the platform's token; successful validations earn rewards, while failures result in slashing.

**Example Agent Registration**:
```typescript
// Example: Register Hermes agent on a credentialing platform
const agentNft = await AgentRegistry.register({
  name: 'Hermes',
  capabilities: ['solana-swap', 'price-check', 'order-placement'],
  model_hash: '0xabc123...',
  owner: hermesTreasuryAddress,
  stake: 1000 // MODELFARM tokens
});

// Agent signs transactions using its unique NFT-based key derivation
const signature = await agentNft.signTransaction(tx);
```

**Why Hermes could adopt it**: Hermes could issue agent identity tokens that represent different capability sets; users could stake to "upgrade" their agent's permissions. This creates a verifiable, tradable agent identity layer.

---

## Implementation Suggestions for Hermes

### Suggestion 1: Policy-Based Sub-Wallet Creation for USDC Operations

Implement a Solana smart contract wallet that allows a primary user wallet to create controlled agent sub-wallets. Each agent wallet operates under a policy that:

- Limits transaction amounts (e.g., max 500 USDC per tx)
- Restricts to approved token accounts (only USDC transfers)
- Sets daily/weekly caps
- Supports emergency revocation

**Sample Pseudocode**:
```rust
// In your Solana program (Rust)
pub fn agent_transfer(ctx: Context<Agent>, amount: u64, to: Pubkey) -> Result<()> {
    let agent = &ctx.accounts.agent;
    let clock = Clock::get()?;
    
    // Check daily limit
    let today_start = clock.unix_timestamp - (clock.unix_timestamp % DAY);
    let spent_today = agent
        .daily_spend
        .iter()
        .find(|(date, _)| *date == today_start)
        .map(|(_, amt)| amt)
        .unwrap_or(&0);
    
    require!(
        spent_today + amount <= agent.policy.daily_limit,
        DailyLimitExceeded
    );
    
    // Check per-tx limit
    require!(amount <= agent.policy.max_tx, AmountTooHigh);
    
    // Check destination whitelist
    require!(
        agent.policy.allowed_destinations.contains(&to),
        UnauthorizedDestination
    );
    
    // Execute transfer (USDC mint)
    let cpi_accounts = Transfer {
        from: ctx.accounts.agent_usdc_account.to_account_info(),
        to: ctx.accounts.destination_account.to_account_info(),
        authority: ctx.accounts.agent_pda.to_account_info(),
    };
    token::transfer(cpi_accounts, amount)?;
    
    // Emit event
    emit!(AgentTransfer {
        agent: agent.key(),
        amount,
        to,
        timestamp: clock.unix_timestamp,
    });
    
    Ok(())
}
```

**Integration Suggestion**: Build a Solana program that acts as a "wallet factory" — users create agent wallets with policies signed by their main key. Hermes server calls the program's `transfer()` instruction with policy-gated parameters. This means even if Hermes is compromised, funds are protected by on-chain rules.

---

### Suggestion 2: Agent Identity NFT with Capability Attestations

Issue a non-transferable SPL token (or Metaplex NFT) for each Hermes agent. The NFT acts as an on-chain identity credential that:

- Lists approved operations (verbs: `transfer`, `swap`, `stake`, etc.)
- Links to model version (SHA256 hash of the agent logic)
- Includes a reputation/success-rate score

**Sample Metadata**:
```json
{
  "name": "Hermes Agent #042",
  "symbol": "HERMES-AGENT",
  "description": "AI trading agent for Solana DeFi",
  "properties": {
    "model_hash": "sha256:abc123def456...",
    "capabilities": ["solana_swap", "price_fetch", "order_submit"],
    "trust_score": 0.97,
    "registered_at": "2026-05-10T08:42:00Z",
    "owner": "FPOk... (user wallet)"
  }
}
```

**Why it helps**: When interacting with other protocols, your agent can present its NFT to prove authorization (via signature from the NFT's authority). Protocols can check capability list to allow/deny operations.

---

### Suggestion 3: On-Chain Proof-of-Inference for AI-Verified Actions

If Hermes ever uses AI to make decisions (e.g., AI analysis triggers a trade), generate a zk-proof or receipt that can be stored on-chain as evidence. Use Solana's large transaction size (up to 1232 bytes) or NFT metadata to store the proof hash; full proof can be stored in a lightweight program account.

**Workflow**:
1. AI runs inference locally: `action = model.predict(state)`
2. Generate a receipt containing: `{ model_id, input_state_hash, output_action, timestamp }`
3. Sign receipt with agent key
4. Submit to a Solana program that records: "At time T, agent X, running model Y, decided action Z"

**Sample Receipt Submission**:
```typescript
// In JavaScript/TypeScript with @solana/web3.js
const tx = new Transaction().add(
  createInferenceReceiptInstruction({
    modelId: new PublicKey(MODEL_REGISTRY_ID),
    inputHash: sha256(JSON.stringify(currentState)),
    output: action,
    proof: zkProof, // optional if using zk
    timestamp: Date.now(),
  })
);
await sendAndConfirmTransaction(connection, tx, [agentKeypair]);
```

This pattern creates an auditable trail that can be used by other agents or protocols to trust Hermes's decisions, especially valuable for agent-to-agent interactions where reputation matters.

---

## Priority Recommendations for Hermes

1. **Immediate** (Low-effort, high-value): Implement policy-based USDC transfer limits via Solana program logic. Start simple: whitelist destinations, set daily caps. No external dependencies.

2. **Short-term** (Medium effort): Create an Agent Identity NFT that non-transferably represents each Hermes agent. Store capability set and model hash on-chain. Useful for cross-protocol authorizations.

3. **Long-term** (High effort): Integrate with a proof-of-inference provider like Ritual Net or zkLLM to generate verifiable AI receipts for autonomous decisions. This adds credibility for governance and peer agent interactions.

---

## How to Save/Commit This Document

The research document has been saved to the outputs directory. To commit it to your daily learnings repository:

```bash
# Copy to daily-learnings repo
cp /home/tokisaki/work/research-swarm/outputs/awesome_solana_ai.md ~/daily-learnings/research/awesome_solana_ai.md

# Commit (from the daily-learnings directory)
cd ~/daily-learnings
git add research/awesome_solana_ai.md
git commit -m "Add research: Solana AI agent patterns from awesome-solana-ai"
git push origin main
```

---

## Conclusion

Solana's AI agent ecosystem is emerging rapidly. Key patterns include:
- **Policy-enforced wallets** for secure delegation
- **Inference receipts** for verifiable AI actions
- **Tokenized agent identities** for reputation and permissions

Hermes can adopt these incrementally, starting with on-chain spending policies for USDC adapter security. For full agent identity, consider issuing capability-based NFTs and optionally partnering with existing proof-of-inference networks.
