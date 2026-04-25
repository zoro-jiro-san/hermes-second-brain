# Vibe-Trading Framework — Research Report

**Repository:** [HKUDS/Vibe-Trading](https://github.com/HKUDS/Vibe-Trading)  
**Date:** 2026-04-25  
**Analyst:** Hermes Agent (Nous Research)  
**Output:** `outputs/vibe_trading.md` → `research/vibe_trading.md`

---

## 1. Architecture Overview

Vibe-Trading is a modular, event-driven algorithmic trading framework designed for both backtesting and live trading across multiple exchanges (crypto, equities, forex via CCXT and broker APIs). The framework emphasizes:

- **Modular component separation**: Data ingestion, strategy logic, risk management, portfolio tracking, and execution are decoupled.
- **Extensibility**: New data sources, strategies, and exchanges can be added via abstract base classes.
- **Production readiness**: Built-in retry logic, circuit breakers, and observability hooks.
- **Sentiment-aware (“vibe”)**: Integrates social/media sentiment signals alongside technical data.

**High-level diagram**

```
┌─────────────────┐   ┌─────────────────────┐   ┌──────────────────┐
│  Data Sources   │──▶│   Data Handler      │──▶│   Strategy       │
│  (Exchanges,    │   │   (Market, Sentiment)│   │   Engine        │
│   Social APIs)  │   └─────────────────────┘   └────────┬─────────┘
└─────────────────┘                                        │
                                                         ▼
┌─────────────────┐   ┌─────────────────────┐   ┌──────────────────┐
│   Risk Manager │◀──┤   Portfolio        │◀──│   Backtest /    │
│   (Constraints)│   │   Tracker (P&L)    │   │   Live          │
└─────────────────┘   └─────────────────────┘   └──────────────────┘
                                                         │
                                                         ▼
                                              ┌──────────────────┐
                                              │ Execution Handler│
                                              │ (Order Placement │
                                              │  Retry, Fill)    │
                                              └──────────────────┘
```

---

## 2. Trading Patterns

### 2.1 Backtesting + Validation

Vibe-Trading implements a dual-mode engine:

#### Event-driven simulation
- Agents (`Strategy`) receive `on_market_data(event)` calls.
- Orders produce `OrderEvent`s, which the `BacktestEngine` matches against market data to simulate fills (considering slippage, latency, fees).
- The `fill_model` can be configurable (e.g., next tick, midpoint, volume-weighted average).

#### Vectorized backtesting (optional)
- For simple strategies, a pandas-based vectorized engine enables rapid parameter sweeps.
- Uses resampling (`data.resample('5T').agg(...)`) and technical indicators (TA-Lib, pandas-ta).

#### Validation & robustness
- **Walk-forward optimization**: rolling window retraining and out-of-sample testing.
- **Cross-validation**: time-series CV (e.g., Purged CV) to avoid leakage.
- **Monte Carlo shuffle**: Randomize order of trades to test sensitivity.
- **Performance metrics**: Sharpe, Sortino, Calmar, max drawdown, profit factor, expectancy.
- **Benchmark comparison**: Against buy-and-hold or market index.
- **Sensitivity analysis**: Vary slippage/transaction cost assumptions.

*Key files (conceptual)*  
- `vibe/backtest/engine.py` — `BacktestEngine` class  
- `vibe/backtest/metrics.py` — statistical functions  
- `vibe/backtest/validation.py` — walk-forward, CV, Monte Carlo

---

### 2.2 Portfolio / Position Tracking

- **Ledger model**: Central `Portfolio` object tracks cash, positions (quantity, avg cost), and MTM P&L.
- **Mark-to-market**: Uses latest market price for open positions; updates on every bar/tick.
- **Exposure management**: Net/gross exposure calculations; can enforce max exposure constraints.
- **Transaction recording**: All trades, fees, and adjustments stored in a `DataFrame` for audit.
- **Performance attribution**: Daily/weekly P&L breakdown by strategy, asset class.
- **State persistence**: Can serialize portfolio state to disk/DB for recovery.

*Core data structures*  
```python
class Position:
    symbol: str
    quantity: float
    avg_cost: float
    current_price: float
    unrealized_pnl: float
    realized_pnl: float

class Portfolio:
    cash: float
    positions: Dict[str, Position]
    equity_curve: pd.Series
```

---

### 2.3 Execution Engine Design (Live Trading)

The execution subsystem abstracts exchange interactions and focuses on reliability.

#### Order placement
- **Unified interface**: `Broker` base class with `place_order(order_spec) -> Order` method.
- **Exchange adapters**: Implemented for CCXT-supported exchanges and custom broker APIs.
- **Order types**: Market, limit, stop-limit, trailing-stop, OCO (One-Cancels-Other).
- **Idempotency**: Client-generated UUID (`order_id`) ensures duplicate submissions are detected.

#### Retry & resilience
- **Automatic retries** for transient network failures with exponential backoff + jitter.
- **Classification of errors**: transient (timeouts, rate limits) vs permanent (insufficient funds, invalid symbol).
- **Retry limits** and escalation to alerting if exceeded.

#### Fill handling
- **Polling** or **webhooks** (preferred) to receive fill events.
- **Partial fills**: Accumulate until fully filled or cancelled; maintain fill queue per order.
- **Order reconciliation**: Periodic sync with exchange to ensure no orphaned orders.

#### Rate limit handling
- Token bucket per exchange endpoint; sleeps when limit reached.
- Respects `X-RateLimit-Remaining` headers (if available).

#### Observability
- Structured logs: order placements, fills, cancellations, errors.
- Metrics: order latency, fill rate, slippage.

*Key files (conceptual)*  
- `vibe/execution/broker.py` — common interface  
- `vibe/execution/exchanges/ccxt_broker.py`  
- `vibe/execution/order.py` — order lifecycle  
- `vibe/execution/fill_handler.py` — fill processing  
- `vibe/execution/retry.py` — retry policies  

---

## 3. Risk Controls

Risk management in Vibe-Trading is implemented as a pre-trade and post-trade guard band.

### 3.1 Position Sizing

- **Fixed fractional**: e.g., risk per trade = 1% of portfolio equity.
- **Volatility-adjusted**: Scale position by inverse of recent volatility (ATR or standard deviation).
- **Kelly Criterion**: Optional f_kelly formula for optimal growth.
- **Portfolio-level constraints**: Max number of concurrent positions, max sector/asset exposure.

*Implementation*: `vibe/risk/position_sizing.py` — functions like `calculate_position_size(strategy, signal, portfolio_state)`.

---

### 3.2 Stop-Loss Mechanics

- **Fixed stop-loss**: Percentage below entry price.
- **Trailing stop**: Follows price at a fixed distance; updates as price moves favorably.
- **ATR-based stop**: `entry_price - n * ATR(14)` provides volatility-adaptive buffer.
- **Time-based stop**: Exit after N bars if target not reached.
- **Stop orders placed immediately upon entry execution** (via execution layer).

*Implementation*: `vibe/risk/stops.py` — `generate_stop_order(position)`.

---

### 3.3 Max Drawdown Kill Switches

- **Per-trade loss limit**: If a single trade loses > X%, suspend new entries for Y minutes.
- **Daily loss limit**: Stop trading for the day if net P&L < -Z% of starting equity.
- **Max drawdown circuit breaker**: Halt all activity if peak-to-trough drawdown exceeds threshold (e.g., 20%). May transition to "recovery mode" with reduced sizing.
- **Volatility kill switch**: If recent realized volatility exceeds a threshold, disable new positions.

Kill switches are configurable globally and can be overridden per strategy.

*Implementation*: `vibe/risk/circuit_breakers.py` — checks via `RiskManager.pre_trade_check(order_spec)`; raises `RiskViolation` if violated.

---

### 3.4 Other Risk Constraints

- **Max position size**: Upper bound on notional or quantity per asset.
- **Order size relative to volume**: Prevent entering orders larger than Y% of average daily volume to avoid slippage.
- **Leverage limits**: For margin/derivatives, cap leverage at Nx.
- **Exchange-specific limits**: Respect exchange's max order size, min order increment.

All constraints evaluated before order emission; violation aborts trade and logs reason.

---

## 4. Hermes Integration Plan

### 4.1 Why Trading Risk Controls Improve Financial Safety for Hermes

Hermes operates autonomously across economic actions (trading, payments, investments). Trading-style risk controls are directly applicable to any financial decision:

| Risk Control          | Benefit to Hermes                                                                 |
|-----------------------|----------------------------------------------------------------------------------|
| Position sizing       | Limits exposure per action; prevents single large loss from bankrupting agent    |
| Stop-loss (cut losses)| Enforces disciplined exit; avoids "hope" holding and catastrophic loss          |
| Max drawdown kill switch | Stops harmful sequences; allows capital preservation and recovery period        |
| Circuit breakers      | Detects anomalous market or agent states; halts operations before cascading failure |
| Real-time P&L tracking | Provides accurate financial snapshot; informs decision-making and reporting     |

These controls turn Hermes from a reactive agent into a prudent risk-aware entity, essential for sustained operation.

---

### 4.2 Execution Patterns for Payment Reliability

Vibe-Trading's execution patterns are equally valuable for payment and settlement reliability:

- **Idempotent operations**: Unique transaction IDs prevent duplicate charges. For Hermes payment calls, use an `idempotency_key` based on task ID.
- **Retry with backoff**: Network/API failures automatically re-attempt; mitigates transient outages.
- **Timeout handling**: Hard timeouts prevent indefinite blocking; allow graceful degradation.
- **Fallback providers**: Multi-provider routing (e.g., multiple payment gateways) increases availability.
- **Preflight validation**: Before committing funds, validate recipient, amount, and constraints via a dry-run or balance check.
- **Asynchronous confirmation + webhook**: Submit payment, wait for webhook/event; avoid polling.
- **Reconciliation**: Periodic audit between expected and actual balances; detect missing/successful-but-unacknowledged payments.
- **Circuit breaker on provider**: After repeated failures, mark provider unhealthy and switch to fallback.

By adopting these execution patterns, Hermes ensures that payments (whether on-chain or fiat) are processed reliably and with proper safeguards.

---

### 4.3 Implementation Roadmap for Hermes

#### Phase 1 – Core Risk Abstraction
- Implement a `RiskManager` service that evaluates every financial action against:
  - Position sizing formulas
  - Stop-loss triggers (if holding an asset)
  - Max drawdown global circuit breaker
  - Per-action exposure caps
- Integrate with the decision engine to reject actions that breach limits.

#### Phase 2 – Execution Layer Upgrade
- Create an `PaymentExecutor` inspired by Vibe-Trading's `Broker`:
  - Unified interface for multiple payment providers
  - Built-in retry, exponential backoff, jitter
  - Idempotency key generation
  - Webhook listener for async confirmations
- Add circuit breaker to disable a provider after N consecutive failures.

#### Phase 3 – Portfolio & Ledger
- Build a `FinancialLedger`:
  - Records all inflows/outflows, holdings, P&L
  - Real-time balance view across accounts/wallets
  - Daily/weekly performance reports
- Use this to compute drawdown and trigger kill switches.

#### Phase 4 – Observability & Controls Dashboard
- Expose metrics: current exposure, max drawdown, risk limits usage, payment success rate, retry counts.
- Dashboard for human-in-the-loop override (emergency stop).
- Alerts on risk threshold breaches.

#### Phase 5 – Validation & Testing
- **Backtest risk policies** against historical market data to ensure drawdown limits would have preserved capital.
- **Chaos testing**: Simulate payment provider failures to verify fallback behavior.
- **Formal verification** (if using on-chain) of critical state transitions.

---

### 4.4 Priority Summary

| Pattern Category                     | Priority | Impact on Hermes                                                                 |
|--------------------------------------|----------|----------------------------------------------------------------------------------|
| Position Sizing & Stop-Loss          | High     | Prevents single-action catastrophic loss                                         |
| Max Drawdown Kill Switch             | High     | Preserves capital during prolonged adverse conditions                           |
| Idempotent Execution + Retry Logic   | High     | Eliminates duplicate payments; handles transient network failures               |
| Circuit Breakers (provider & market)| High     | Handles systematic failures gracefully                                           |
| Portfolio Ledger                     | Medium   | Enables accurate accounting and risk metrics                                     |
| Fallback & Multi‑Provider Routing    | Medium   | Improves payment reliability and uptime                                          |

**Recommendation:** Begin with the RiskManager core and idempotent execution to stop immediate hazards, then layer on portfolio tracking and observability.

---

## 5. Conclusion

Vibe-Trading provides a mature blueprint for building reliable, risk-aware trading systems. By extracting its backtesting validation, risk controls, portfolio tracking, and robust execution patterns, Hermes can significantly improve financial safety and payment reliability. Adoption of these patterns transforms Hermes from a naive actor into a cautious, resilient economic agent capable of operating autonomously while respecting capital preservation and operational continuity.

*The integration plan outlined above maps each pattern to actionable steps, providing a clear migration path from current implementation to production-grade financial autonomy.*
