---
name: vibe-trading
description: Trading risk management and execution reliability patterns — position sizing, stop-losses, circuit breakers, portfolio tracking, and idempotent payment execution for autonomous economic agents.
version: 1.0.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [trading-risk, financial-controls, execution-reliability, position-sizing, circuit-breakers, payment-processing]
    related_skills: [agentic-stack, obscura, toprank]
---

# Vibe-Trading — Financial Risk Controls & Execution Reliability

Vibe-Trading is a modular algorithmic trading framework whose patterns for risk management, portfolio tracking, and robust execution are directly applicable to any autonomous economic agent. Adopt these controls to ensure financial safety, prevent catastrophic losses, and guarantee payment reliability. This skill translates trading-grade safeguards into general-purpose economic agent operations.

## When to Use

Trigger when Hermes:
- Executes financial actions (trading, payments, investments, transfers)
- Manages capital allocation across multiple actions or positions
- Needs disciplined exit strategies (stop-losses, take-profits)
- Operates in volatile or uncertain environments
- Requires audit trails for every monetary transaction
- Must enforce hard limits (max drawdown, per-transaction caps)
- Handles payment processing requiring idempotency and retry logic
- Uses external financial APIs (exchanges, payment gateways, banking)

## Prerequisites

- Basic financial/accounting terminology (equity, P&L, drawdown)
- Access to account/balance information (wallet, bank, exchange API credentials)
- Understanding of risk tolerance (acceptable loss per action, max drawdown threshold)
- Python environment with pandas/numpy for portfolio analytics (optional but recommended)
- Environment variables for API keys/secrets (stored securely)

## Quick Reference

### RiskManager Core API

```python
from hermes.vibe_trading import RiskManager, PositionSizer, CircuitBreaker, FinancialLedger

# Initialize components
risk_mgr = RiskManager(
    max_drawdown_pct=20.0,          # Stop trading if equity falls 20% from peak
    per_trade_risk_pct=1.0,         # Risk at most 1% of equity per trade
    daily_loss_limit_pct=5.0,       # Halt if daily P&L < -5%
    max_position_size=None,         # Optional absolute cap
    vol_kill_threshold=2.5,         # Disable trading if volatility > 2.5σ
)

ledger = FinancialLedger(initial_cash=10000.00)

# Evaluate proposed action before execution
action = {
    "type": "buy",
    "symbol": "BTC/USD",
    "quantity": 0.5,
    "estimated_cost_usd": 15000.00,
}
can_execute, reason = risk_mgr.pre_trade_check(action, ledger.state())
if not can_execute:
    raise RiskViolation(f"Blocked: {reason}")

# Execute (via PaymentExecutor pattern)
result = hermes.payments.execute(
    provider="stripe",
    amount=action['estimated_cost_usd'],
    currency="USD",
    idempotency_key=f"tx_{action['id']}",
    metadata={"action_type": "buy", "symbol": action['symbol']}
)

# Record outcome
ledger.record_trade(
    symbol=action['symbol'],
    quantity=action['quantity'],
    price=result.execution_price,
    fee=result.fee,
    side="buy"
)
risk_mgr.update_post_trade(ledger.state())
```

### Position Sizing Formulas

```python
from hermes.vibe_trading.position_sizing import calculate_position_size

# Fixed fractional (1% risk)
size = calculate_position_size(
    method="fixed_fractional",
    equity=ledger.equity,
    risk_pct=0.01,
    entry_price=30000,
    stop_price=29000  # defines initial risk per share/unit
)
# position_value = equity × risk_pct / ( (entry - stop) / entry )

# Volatility-adjusted (ATR-based)
size = calculate_position_size(
    method="volatility_adjusted",
    equity=ledger.equity,
    risk_pct=0.01,
    entry_price=30000,
    atr=1500,  # average true range
    atr_multiplier=2.0
)

# Kelly Criterion (optimal growth)
size = calculate_position_size(
    method="kelly",
    win_rate=0.55,        # probability of profit
    win_loss_ratio=1.5,   # avg win / avg loss
    kelly_fraction=0.5    # half-Kelly for conservatism
)
```

### Circuit Breaker States

```python
from hermes.vibe_trading.circuit_breakers import CircuitState

circuit = CircuitBreaker(risk_mgr)

if circuit.state == CircuitState.OPEN:
    # Trading halted — reason stored in circuit.trip_reason
    hermes.log.warning(f"Circuit open: {circuit.trip_reason}")
elif circuit.state == CircuitState.HALF_OPEN:
    # Reduced sizing allowed, monitor closely
    allowed = circuit.allow_minor_actions()
```

## Core Patterns

### 1. Position Sizing — Limit Per-Action Exposure

Never risk more than a fixed percentage of total capital on any single action. Prevents total ruin from one bad decision.

**Formulas**:
- **Fixed fractional**: \\(\\text{position\\_value} = \\text{equity} \\times \\text{risk\\_pct} / \\text{initial\\_risk\\_per\\_unit}\\)
  where `initial_risk_per_unit = (entry − stop) / entry`
- **Volatility‑adjusted**: Scale by inverse of recent ATR or standard deviation
- **Kelly**: \\(f^* = \\frac{p \\cdot b - q}{b}\\)  where \\(p\\) = win prob, \\(b\\) = win/loss ratio, \\(q=1-p\\)

**Hermes application**: Any financial decision (buy, invest, pay) should be sized to cap risk.

### 2. Stop-Loss Mechanics — Cut Losses Early

Define exit rules before entry. Enforces discipline and prevents hope‑based holding.

**Types**:
- **Fixed % stop**: Exit if asset drops X% from entry
- **Trailing stop**: Follow price at fixed distance; locks in gains
- **ATR‑based stop**: \\(\\text{stop} = \\text{entry} - n \\times \\text{ATR}\\) adaptive to volatility
- **Time‑based stop**: Exit after N time units if target unmet

**Implementation**: Set stop order immediately upon entry via execution layer.

### 3. Max Drawdown Kill Switches

Stop all activity if cumulative losses exceed threshold:

| Kill Switch | Trigger | Action |
|-------------|---------|--------|
| Per‑trade loss limit | Single loss > X% of equity | Suspend new entries for Y minutes |
| Daily loss limit | Net P&L < −Z% of starting equity | Cease trading for the day |
| Max drawdown circuit breaker | Equity drawdown > threshold (e.g., 20%) | Halt all actions; enter recovery mode |
| Volatility kill switch | Realized volatility > N-day threshold | Reduce position sizes or pause |

**Recovery mode**: After circuit breaker trip, permit only small, low‑risk actions until volatility normalizes.

### 4. Idempotent Execution + Retry Logic

Every payment/order must be uniquely identifiable and safely repeatable:

```python
# Idempotency key derived from task ID prevents duplicate charges
result = execute_payment(
    amount=100.00,
    currency="USD",
    idempotency_key=f"pay_{task_id}",  # same key → same result even if retried
    retry_policy=ExponentialBackoff(max_retries=3, base_delay=1.0)
)
```

**Retry classification**:
- **Transient failures**: timeouts, rate limits, 5xx → retry with backoff + jitter
- **Permanent failures**: insufficient funds, invalid card → do not retry; alert user

### 5. Portfolio Ledger — Single Source of Truth

Centralized `FinancialLedger` maintains:
- Cash balance across all accounts/wallets
- Open positions (quantity, avg cost, current mark‑to‑market)
- Realized & unrealized P&L
- Complete transaction history (timestamp, type, amount, fee, counterparty)

Provides data for: risk metrics, tax reporting, debugging, audit.

### 6. Circuit Breakers (Provider & Market)

**Provider‑level**: After N consecutive failures from payment gateway/exchange API, mark provider unhealthy and route to fallback.

**Market‑level**: If volatility spikes or liquidity dries up, reduce position sizes across all assets.

## Steps — Applying Vibe‑Trading to Hermes

### Step 1: Implement RiskManager Service

Create `hermes.risk` module that evaluates **every** financial action pre‑execution.

```python
class RiskManager:
    def __init__(self, config: RiskConfig):
        self.config = config
        self.circuit = CircuitBreaker()

    def pre_trade_check(self, action: dict, ledger_state: dict) -> tuple[bool, str]:
        """Return (can_proceed, reason_if_blocked)."""

        # 1. Gating: absolute constraints
        if action['amount'] > self.config.max_single_payment:
            return False, f"Exceeds max payment ${self.config.max_single_payment}"

        # 2. Position sizing: ensure risk per action within limit
        risk_pct = self.calculate_risk_pct(action, ledger_state)
        if risk_pct > self.config.per_action_risk_pct:
            return False, f"Risk {risk_pct:.1f}% exceeds limit {self.config.per_action_risk_pct}%"

        # 3. Circuit breaker: check if globally halted
        if self.circuit.is_open():
            return False, f"Circuit open: {self.circuit.trip_reason}"

        # 4. Daily loss limit
        if ledger_state['daily_pnl'] < -self.config.daily_loss_limit_pct * ledger_state['start_equity']:
            return False, "Daily loss limit exceeded"

        return True, "OK"

    def update_post_trade(self, ledger_state):
        """Update internal state after trade completion."""
        # Update drawdown peak, trigger circuit if needed
        self.circuit.check(ledger_state)
```

### Step 2: Upgrade PaymentExecutor

Wrap all payment/transaction calls with reliability patterns:

```python
class PaymentExecutor:
    def __init__(self):
        self.providers = {}  # provider_name → ProviderAdapter
        self.circuit = ProviderCircuitBreaker()

    def execute(self, provider_name, payment_spec):
        # Circuit check: is provider healthy?
        if not self.circuit.allow(provider_name):
            raise ProviderUnavailable(f"{provider_name} circuit open")

        provider = self.providers[provider_name]
        try:
            result = provider.execute_with_retry(
                amount=payment_spec.amount,
                idempotency_key=payment_spec.idempotency_key,
                timeout=30.0,
                retry=ExponentialBackoff(max_attempts=3)
            )
            self.circuit.record_success(provider_name)
            return result
        except TransientError as e:
            self.circuit.record_failure(provider_name)
            raise  # caller may retry with alternate provider
```

**Fallback routing**: If primary provider fails, automatically retry with secondary.

### Step 3: Build FinancialLedger

Persistent, queryable ledger:

```python
class FinancialLedger:
    def __init__(self, initial_cash=0):
        self.cash = initial_cash
        self.positions = {}  # symbol → Position
        self.trades = []     # list of Trade records
        self.equity_curve = []  # time series of total equity

    def record_trade(self, symbol, quantity, price, fee, side):
        """Update cash, positions, and trade history."""
        cost = quantity * price + fee
        if side == "buy":
            self.cash -= cost
            # update/average position
        elif side == "sell":
            self.cash += (quantity * price - fee)
        self.trades.append(Trade(...))
        self._update_equity_curve()

    def state(self) -> dict:
        """Snapshot for RiskManager."""
        return {
            "cash": self.cash,
            "equity": self.total_equity(),
            "positions": list(self.positions.values()),
            "daily_pnl": self._today_pnl(),
            "peak_equity": self._peak_equity(),
            "drawdown_pct": self._current_drawdown_pct(),
        }

    def total_equity(self) -> float:
        return self.cash + sum(p.market_value() for p in self.positions.values())
```

Persist ledger to disk/DB regularly for crash recovery.

### Step 4: Instrument Observability

Expose metrics for monitoring:

```python
# Prometheus metrics or internal stats
statsd.gauge("hermes.risk.exposure_pct", current_exposure)
statsd.gauge("hermes.risk.max_drawdown_pct", current_drawdown)
statsd.counter("hermes.payment.retry_count", total_retries)
statsd.counter("hermes.payment.failure_count", total_failures, tags={"provider": name})
```

Dashboard displays:
- Current equity curve with drawdown highlighted
- Recent circuit breaker trips and reasons
- Payment success rate by provider
- Top risk limit utilizations (near‑limit warnings)

### Step 5: Add Safety Layer (Hermes Agent)

Configure risk policy per user/agent:

```yaml
# ~/.hermes/risk_profile.yaml
agent_id: hermes_default
max_drawdown_pct: 15.0
per_action_risk_pct: 0.5
daily_loss_limit_pct: 3.0
allowed_asset_classes: [crypto, equity]
blocked_exchanges: [unregulated_market_X]
enforce_knowledge_cutoff: true  # won't trade on pre‑2024 data without override
```

### Step 6: Backtest Risk Policies (Optional)

Simulate historical trades under different risk settings to evaluate effectiveness:

```bash
hermes vibe backtest \
  --trades historical_trades.csv \
  --risk-profile conservative.yaml \
  --output performance_report.html
```

Reports: max drawdown achieved, number of trades taken, hit rate, expectancy, recovery time after circuit trips.

## Integration with Hermes Subsystems

| Hermes Component | Vibe‑Trading Pattern Applied |
|------------------|------------------------------|
| **Payment execution** | Idempotent keys, retry, circuit breakers on provider failures |
| **Provider router** | Risk check pre‑selection: does chosen provider violate exposure limits? |
| **Task planner** | Position sizing applied to capital‑allocation tasks |
| **Memory / audit log** | All financial decisions logged with `FinancialLedger` entries |
| **Multi‑agent** | Shared ledger provides consistent global state across agents |
| **Observability** | Metrics/exports for risk dashboard |

## Domain Expansion: Beyond Trading

While originated in trading, these patterns apply broadly:

- **Budget‑constrained resource allocation**: Sizing cloud compute spend per job
- **API rate‑limit management**: Circuit breakers when external API throttles
- **Model inference budget**: Stop generating if cost budget exhausted
- **Time‑based kill switches**: Cease operations after maintenance window
- **Position‑like tracking**: Inventory management, bookkeeping, supply chain

## Pitfalls

- **Over‑conservative sizing**: Risk limits set too low (0.1%) starve agent of opportunity. Tune based on historical volatility and desired growth rate.
- **Stop‑loss whipsaw**: Frequent small stops in noisy markets drain capital via fees. Use ATR‑based or time‑based stops to avoid noise.
- **Circuit breaker hysteresis**: Rapid trip/release cycles; implement cooldown periods (e.g., 1‑hour lockout after trip).
- **Idempotency key collisions**: Poor key generation (non‑unique) blocks legitimate retries. Use UUID or task‑ID space with namespace.
- **Ledger drift**: Out‑of‑sync ledger vs. actual account balance due to missed fills or external transfers. Implement periodic reconciliation jobs.
- **Retry amplification**: Cascading retries across multiple backends can overload already strained services. Add jitter and aggregate retry budgets.
- **Hidden correlation risk**: Multiple positions/assets may be correlated (e.g., all crypto). Portfolio‑level exposure limits needed, not just per‑asset caps.
- **Neglecting slippage & fees**: Backtesting and sizing must account for realistic transaction costs; otherwise P&L overstated.
- **Static thresholds**: Volatility regimes change; static stop distances become inappropriate. Re‑calibrate ATR lookback periods dynamically.

## Configuration Example

```yaml
# ~/.hermes/vibe_trading_config.yaml
risk:
  max_drawdown_pct: 20.0
  per_action_risk_pct: 1.0
  daily_loss_limit_pct: 5.0
  volatility_kill_threshold_sigma: 3.0
  position_concentration_limit: 0.25  # max 25% in single asset

position_sizing:
  default_method: "fixed_fractional"
  fixed_fraction_risk: 0.01
  atr_period: 14
  atr_multiplier: 2.0

circuit_breakers:
  provider_max_failures: 5
  provider_recovery_timeout_seconds: 300
  market_volatility_lookback_days: 20

ledger:
  persistence_path: "~/.hermes/ledger"
  backup_interval_hours: 6
  reconcile_with_external: true  # periodic balance checks against exchange

payment:
  idempotency_key_namespace: "hermes_tx"
  retry:
    max_attempts: 3
    base_delay_seconds: 1.0
    max_delay_seconds: 30.0
    jitter: true
```

## Advanced Topics

### 1. Monte Carlo Validation of Risk Policies

Generate synthetic trade sequences under various market regimes to test whether your risk settings survive extreme events.

### 2. Portfolio‑Level Risk Metrics

- **Value at Risk (VaR)**: Maximum expected loss over time horizon at confidence level
- **Expected Shortfall (CVaR)**: Average loss when VaR is exceeded
- **Beta / correlation**: Hedge systemic risk

### 3. Adaptive Position Sizing

Use reinforcement learning or Bayesian optimization to dynamically adjust risk parameters based on recent performance and market regime.

### 4. Cross‑Provider Redundancy

Route payments through multiple gateways using weighted selection, automatically failing over when circuit breaker trips.

## References

- Vibe‑Trading GitHub: https://github.com/HKUDS/Vibe-Trading
- Trading risk management: Van Tharp's position sizing methodologies
- Kelly criterion: https://en.wikipedia.org/wiki/Kelly_criterion
- Circuit breaker pattern: Martin Fowler's "Circuit Breaker"
- Idempotent operations: Stripe, AWS best practices for payment APIs
- Portfolio theory: Markowitz mean‑variance optimization (advanced)
