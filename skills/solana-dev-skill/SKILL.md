---
name: "Solana Dev Skill: Secure Blockchain Integration"
description: "Skills and patterns extracted from the official Solana Developer Skill guide: secure key handling, transaction construction, RPC management, and error recovery for blockchain integration."
trigger: "when working with Solana blockchain integration, transaction signing, or secure wallet management"
---

# Solana Dev Skill: Secure Solana Integration Patterns

## Overview
This skill distills production-grade patterns from the **Solana Developer Skill** guide by the Solana Foundation. It covers the Solana account model, secure key handling, transaction construction with compute budget control, RPC connection management with failover, and robust error handling. These patterns are critical for building reliable, secure blockchain adapters for autonomous agents like Hermes.

## What It Does
Provides patterns and best practices for:
- Wallet/account patterns: fee payer keys, Program Derived Addresses (PDAs), Associated Token Accounts (ATAs), rent-exemption guarantees
- Secure key management: environment-based secrets, encrypted keyfiles, hardware wallet integration, key rotation, memory hygiene
- Transaction construction: recent blockhash handling, versioned transactions, compute budget limits, partial signing, memo program
- RPC connection management: multi-endpoint pooling, health checking, retry with backoff, rate limiting, WebSocket subscriptions
- Error handling: distinguishing system vs program vs client errors, retry policies, circuit breakers, state recovery

## When to Use
- Integrating Hermes or any agent with Solana blockchain
- Building transaction submission services for on-chain operations
- Managing cryptographic keys in automated systems
- Implementing robust, fault-tolerant RPC clients
- Designing secure signing and multi-signature workflows
- Handling token operations, PDAs, and cross-program invocations (CPI)

## Setup
Read the full research at: `/home/tokisaki/work/research-swarm/outputs/research_solana_dev_skill.md`

## Implementation Steps
### 1. Implement a Connection Manager (High Priority)
- Wrap `@solana/web3.js` `Connection` in `SolanaConnectionManager` singleton
- Maintain pool of RPC endpoints with health status tracking
- Expose `getConnection()` and `execute<T>(fn, config?)` with automatic retry
- Centralize RPC concerns (failover, latency tracking)

### 2. Abstract Key Management (High Priority)
- Define `Signer` interface: load from encrypted keyfile, env vars, HSM, remote signer service
- Never keep raw secret in memory longer than needed; overwrite buffers after signing
- Support separate devnet/mainnet keypairs; enforce environment isolation
- Plan for multi-sig integration via Squads or similar for high-value ops

### 3. Transaction Service with Compute Budget & Preflight (Medium Priority)
- Build `SolanaTransactionService`: auto-add `SetComputeUnitLimit` and `SetComputeUnitPrice`
- Use `getLatestBlockhash` with `finalized` commitment
- Enable preflight checks to catch errors before consuming fee
- Handle confirmation with timeout and status monitoring; `Promise.race` with `confirmTransaction`

### 4. Centralized Error Handler (High Priority)
- Map Solana errors to structured enum (INSUFFICIENT_FUNDS, ACCOUNT_NOT_FOUND, PROGRAM_ERROR, RPC_TIMEOUT, RATE_LIMITED, etc.)
- Tag each error as `retryable` or not; use to drive retry logic and circuit breakers
- Translate error codes into user-friendly messages; log with structured JSON

### 5. Validation Helpers for Accounts (Medium Priority)
- Utility functions: `ensureOwner(account, expectedProgramId)`, `ensureDataLength(account, expectedLength)`
- `ensureRentExempt(connection, accountPubkey)`, `validatePDA(pda, seeds, programId)`
- Use before every CPI to prevent corrupted/malicious account data issues

### 6. Observability & Logging (Medium Priority)
- Log: transaction signature, fee, compute units consumed, RPC endpoint used, latency, retries, error types
- Avoid logging raw keys/seeds; use structured logging (JSON) for monitoring systems

### 7. Incremental Integration
- Prioritize: Connection Manager → Secure Key Abstraction → Error Handler
- Then adopt transaction and account patterns per program interaction
- Implement circuit breakers after consecutive failures from same RPC endpoint

## Key Patterns Extracted
### Core Wallet / Account Patterns
- **Keypair as fee payer & authority**: dedicated keypair; never reuse main wallet keys
- **PDAs**: `PublicKey.findProgramAddress(seeds, programId)`; no private key; program-controlled via CPI
- **ATAs**: `getAssociatedTokenAddress(...)` ensures canonical token account per owner/mint
- **Rent-exemption**: `getMinimumBalanceForRentExemption(accountDataLength)` before account creation
- **Ownership verification**: validate `account.owner` equals expected program ID
- **Batch reads**: `getMultipleAccounts` for multiple token accounts or program states

### Secure Key Handling
- Never hardcode secrets: use env vars, encrypted configs, secret managers (AWS/GCP/Vault)
- `.env` only for local dev; gitignore
- Encrypted keyfiles: `solana-keygen new --outfile ~/.config/solana/agent.json --passphrase "strong-phrase"`
- Key rotation: design for authority changes; hot key for frequent ops, cold key for admin
- Multi-sig for critical actions (Squads, multisig programs)
- Memory hygiene: overwrite key buffers after use

### Transaction Construction
```ts
const { blockhash } = await connection.getLatestBlockhash();
const message = new TransactionMessage({
  payerKey, recentBlockhash: blockhash, instructions,
}).compileToV0Message();
const tx = new VersionedTransaction(message);
tx.sign(keypairs);
const sig = await connection.sendTransaction(tx, { skipPreflight: false, preflightCommitment: 'confirmed' });
await connection.confirmTransaction(sig, 'finalized');
```
- Compute budget: prepend `SetComputeUnitLimit` and `SetComputeUnitPrice`
- Partial signing: build → partial sign → serialize → additional signatures → send raw
- Memo program for auditing (order ID, task ID)
- Transaction size awareness (≤1232 bytes); use address lookup tables if needed
- Retry-friendly: fresh blockhash each retry; idempotent operations

### Error Handling & Recovery
- Distinguish: RpcError (transient), Program Error (non-transient), Client Error (invalid args)
- Retry with exponential backoff + jitter (max 3-5 attempts) only for transient
- Confirmation timeouts via `Promise.race(timeout)`
- Preflight checks: catches errors before fee consumption
- Error mapping to actionable messages (e.g., "InsufficientFunds" → top up wallet)
- Circuit breakers: pause after consecutive failures; alert operator
- State recovery: write "intent" record (on-chain PDA or off-chain DB) for idempotency

### RPC Connection Management
- Multiple endpoints & failover: pool of Helius/QuickNode/private validator; random or round-robin
- Health checking: `getHealth` / `getVersion`; track latency and error rates; demote unhealthy
- Retry with backoff; respect rate limits (token bucket)
- WebSocket subscriptions: `onAccountChange`, `logsSubscribe`; reconnection with backoff
- Commitment selection: `confirmed` for quick reads, `finalized` for critical ops, `processed` for fastest balance checks
- Timeouts; connection pooling / keep-alive (reuse HTTP connections)

## Pitfalls
- Blockhash reuse >2 minutes leads to failure; always fetch fresh blockhash for retries
- Rate limiting: implement proper token bucket; avoid bans from providers
- Duplicate transaction submission: use `skipPreflight` and deduplication strategies
- Compute budget too low → transaction fails; too high → wasted fees; calibrate per instruction complexity
- Network partitions: distinguish transient vs permanent; don't retry non-retryable program errors indefinitely
- Private key exposure: zero buffers after use; use secure enclaves where possible

## References
- Research: `research_solana_dev_skill.md`
- Solana Docs: https://docs.solana.com/
- Solana Web3.js: https://github.com/solana-labs/solana-web3.js
