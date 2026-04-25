---
name: toprank
description: Multi-criteria decision analysis (MCDA) framework for ranking and prioritizing items based on weighted criteria — ideal for provider selection, feature prioritization, and resource allocation.
version: 1.0.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [decision-making, ranking, prioritization, mcdm, multi-criteria, optimization]
    related_skills: [claude-task-master, agentic-stack]
---

# TopRank — Multi-Criteria Ranking & Prioritization

TopRank is a structured multi-criteria decision analysis (MCDA) framework for evaluating and ranking items (features, providers, ideas) across multiple competing factors. Use this skill when Hermes needs to make balanced, transparent, and defensible decisions that go beyond simple single-metric comparisons.

## When to Use

Trigger when the user:
- Needs to choose between multiple LLM providers, APIs, or services based on multiple factors
- Wants to prioritize features or tasks by balancing cost, reliability, performance, and strategic value
- Must make trade-offs between competing criteria (e.g., budget vs. SLA, speed vs. cost)
- Requires explainable, auditable ranking decisions with adjustable weights
- Needs to incorporate both quantitative (cost, latency) and qualitative (trust, brand fit) criteria
- Wants to set hard gating thresholds (must-haves) alongside soft preference weights
- Is building a decision-support system for product, vendor, or resource selection

## Prerequisites

- Define the items to rank (providers, features, options)
- Identify relevant criteria (cost, trust, latency, SLA, etc.)
- Collect or estimate values for each criterion per item
- Determine criterion weights (must sum to 1.0)
- Decide on gating criteria (must-have thresholds)
- Python with pandas/numpy for calculations (optional but helpful)

## Quick Reference

```python
import pandas as pd
import numpy as np

def normalize(value, min_val, max_val, is_cost=False):
    """Min-max normalization to [0, 1]."""
    if max_val == min_val:
        return 0.5
    if is_cost:
        return (max_val - value) / (max_val - min_val)
    else:
        return (value - min_val) / (max_val - min_val)

# Define criteria configuration
criteria = [
    {"id": "trust", "weight": 0.35, "direction": "benefit", "source": "trust_score"},
    {"id": "cost", "weight": 0.25, "direction": "cost", "source": "price_per_1k"},
    {"id": "sla", "weight": 0.20, "direction": "benefit", "source": "sla_percentage"},
    {"id": "latency", "weight": 0.15, "direction": "cost", "source": "avg_latency_ms"},
    {"id": "budget_fit", "weight": 0.05, "direction": "benefit", "source": "within_budget"},
]

# Sample provider data
providers = [
    {"name": "Provider A", "trust_score": 0.95, "price_per_1k": 0.50, "sla_percentage": 99.9, "avg_latency_ms": 120, "within_budget": True},
    {"name": "Provider B", "trust_score": 0.85, "price_per_1k": 0.30, "sla_percentage": 99.5, "avg_latency_ms": 200, "within_budget": True},
    {"name": "Provider C", "trust_score": 0.90, "price_per_1k": 0.80, "sla_percentage": 99.99, "avg_latency_ms": 80, "within_budget": False},
]

# Compute min/max for normalization
df = pd.DataFrame(providers)
global_stats = {
    'trust_min': df['trust_score'].min(), 'trust_max': df['trust_score'].max(),
    'cost_min': df['price_per_1k'].min(), 'cost_max': df['price_per_1k'].max(),
    'sla_min': df['sla_percentage'].min(), 'sla_max': df['sla_percentage'].max(),
    'latency_min': df['avg_latency_ms'].min(), 'latency_max': df['avg_latency_ms'].max(),
}

# Apply gating: exclude providers that fail critical criteria
viable = [p for p in providers if p['within_budget']]  # budget is gating

# Score viable providers
def score_provider(p, stats):
    trust_norm = normalize(p['trust_score'], stats['trust_min'], stats['trust_max'], is_cost=False)
    cost_norm = normalize(p['price_per_1k'], stats['cost_min'], stats['cost_max'], is_cost=True)
    sla_norm = p['sla_percentage'] / 100.0  # already normalized 0-1
    latency_norm = normalize(p['avg_latency_ms'], stats['latency_min'], stats['latency_max'], is_cost=True)
    budget_ok = 1.0 if p['within_budget'] else 0.0

    return (0.35 * trust_norm + 0.25 * cost_norm +
            0.20 * sla_norm + 0.15 * latency_norm + 0.05 * budget_ok)

ranked = sorted(viable, key=lambda p: score_provider(p, global_stats), reverse=True)
print(f"Winner: {ranked[0]['name']}")
```

CLI equivalent (if implementing as tool):
```bash
hermes toprank rank --config criteria.yaml --data providers.csv --gate budget_fit
```

## Ranking Mechanics

### Weighted Sum Model (WSM)

The core scoring formula:

\\[
\\text{Score}_i = \\sum_{j=1}^{n} w_j \\cdot \\text{norm}(v_{ij})
\\]

where \\(w_j\\) = criterion weight, \\(v_{ij}\\) = raw value, \\(\\text{norm}(\\)\\) = normalization to 0–1 scale.

**Normalization approaches**:
- **Linear scaling** (benefit): \\(\\text{norm}(x) = \\frac{x - \\min}{\\max - \\min}\\) → higher is better
- **Inverse scaling** (cost): \\(\\text{norm}(x) = \\frac{\\max - x}{\\max - \\min}\\) → lower is better
- **Custom functions**: log, exponential, piecewise for diminishing returns

**Advanced variants** (if needed):
- Analytic Hierarchy Process (AHP) for pairwise comparisons
- ELECTRE/PROMETHEE for non-compensatory outranking
- Pareto front filtering to eliminate dominated options

### Criteria Definition Pattern

Each criterion in YAML configuration:

```yaml
criteria:
  - id: trust_score
    weight: 0.35
    direction: benefit          # "benefit" = higher better, "cost" = lower better
    source: provider.trust      # data source path
    normalization: minmax       # minmax, log, custom
    min: 0.0                    # optional: explicit bounds
    max: 1.0
    is_gating: false            # if true, item must pass threshold to be considered
    threshold: null             # required if is_gating=true
  - id: cost_per_1k
    weight: 0.25
    direction: cost
    source: provider.cost
    normalization: inverse      # 1/(x+1) style
    max: 10.0                   # cap extreme values
    is_gating: true
    threshold: 5.0              # cost must be ≤ $5/1k tokens
```

### Gating & Threshold Logic

Gating filters out items that violate absolute constraints:

1. **Pre-ranking filter**: Remove items failing gating criteria before scoring
2. **Post-ranking override**: Demote failing items to bottom, regardless of score
3. **Hard stop**: Abort if no viable options exist

Example gating criteria:
- Cost ≤ allocated budget (must)
- SLA ≥ 99.5% (must for production)
- Region = US-only (data residency requirement)
- Compliance certification = SOC2 (must for enterprise)

## Steps — Integrating TopRank with Hermes

### Step 1: Define Use Case & Criteria

Common Hermes ranking scenarios:

**LLM Provider Selection**:
- Trust (historical uptime, reputation)
- Cost (price per token/request)
- Latency (P50, P95 response times)
- SLA (guaranteed uptime)
- Capabilities (vision, function-calling, context length)
- Regional availability (data residency)

**Feature Prioritization**:
- User value (estimated impact)
- Implementation effort (person-weeks)
- Strategic alignment (company OKR fit)
- Technical risk (uncertainty, unknowns)
- Dependencies (blocks other work)

**Task Scheduling**:
- Priority (user-stated importance)
- Urgency (deadline proximity)
- Estimated duration
- Blocking status (is task a dependency?)
- Resource availability (required tools/models)

### Step 2: Implement Scoring Engine

Create `hermes.ranking` module:

```python
class Criterion:
    def __init__(self, id, weight, direction, source, normalize_fn, is_gating=False, threshold=None):
        ...

class RankingEngine:
    def __init__(self, criteria: List[Criterion]):
        self.criteria = criteria

    def compute_stats(self, items: List[dict]) -> dict:
        """Calculate min/max per metric for normalization."""
        ...

    def apply_gating(self, items: List[dict]) -> List[dict]:
        """Filter out items failing any gating criterion."""
        ...

    def normalize(self, value, criterion, stats):
        """Apply normalization function per criterion."""
        ...

    def score(self, item, stats) -> float:
        """Weighted sum across all criteria."""
        return sum(
            criterion.weight * self.normalize(item[criterion.source], criterion, stats)
            for criterion in self.criteria
        )

    def rank(self, items: List[dict]) -> List[tuple]:
        """Return items sorted by descending score."""
        viable = self.apply_gating(items)
        stats = self.compute_stats(viable)
        scored = [(item, self.score(item, stats)) for item in viable]
        return sorted(scored, key=lambda x: x[1], reverse=True)
```

### Step 3: Collect Real-Time Metrics

Connect to monitoring systems:

```python
# Provider metrics from internal monitoring
provider_metrics = {
    "openai": {
        "trust_score": 0.98,           # from historical uptime logs
        "avg_latency_ms": 250,         # from recent request traces
        "sla_percentage": 99.95,       # from SLA tracker
        "price_per_1k": 0.03,          # from pricing API
        "region": "global",
    },
    "anthropic": {...},
    "local": {...},
}
```

Metrics refresh interval: configurable (e.g., every 5 minutes for latency, daily for cost).

### Step 4: Integrate with Hermes Decision Points

**Provider Selection Hook**:

```python
# In hermes/llm/router.py
from hermes.ranking import RankingEngine

def select_provider(request):
    providers = get_available_providers(request)
    engine = RankingEngine(load_criteria('provider_selection.yaml'))
    ranked, winner = engine.rank(providers)
    log_ranking_decision(ranked, winner)
    return winner
```

**Task Prioritization**:

```python
# In hermes/planner.py
def prioritize_tasks(task_list):
    engine = RankingEngine(load_criteria('task_prioritization.yaml'))
    ranked_tasks = engine.rank([t.to_dict() for t in task_list])
    return [task for task, score in ranked_tasks]
```

### Step 5: Persist Criteria & Audit

Store criteria definitions as versioned YAML in `~/.hermes/ranking/`:

```
~/.hermes/ranking/
├── criteria/
│   ├── provider_selection.yaml
│   ├── feature_prioritization.yaml
│   └── task_scheduling.yaml
└── history/
    └── decisions.jsonl   # every ranking decision logged with timestamp, inputs, winner
```

Audit trail enables:
- Debugging why a particular provider was chosen
- A/B testing different weightings
- Compliance review (was budget constraint respected?)

### Step 6: Dynamic Weight Adjustment

Allow runtime tuning:

```bash
# Adjust weights temporarily
hermes ranking set-weights --profile provider_selection \
  --weight trust 0.40 --weight cost 0.20 --weight latency 0.20

# Promote cost savings mode for batch jobs
hermes ranking set-mode --mode cost_optimized
```

### Step 7: Simulation & What-If Analysis

Before deploying new weights, simulate against historical data:

```python
engine = RankingEngine(criteria_v2)
simulation = engine.backtest(historical_decisions)
print(f"Would have saved ${simulation['cost_savings']:.2f} with no SLA breaches")
```

## Pitfalls

- **Poor weight calibration**: Arbitrary weights yield arbitrary results. Use stakeholder surveys, Analytic Hierarchy Process (AHP), or ML-based weight learning from historical outcomes to derive principled weights.
- **Normalization distortion**: Outliers can squash min‑max ranges, making most scores cluster near 0 or 1. Use robust statistics (percentiles) or clipping (winsorize) to limit outlier influence.
- **Gating over‑use**: Too many gating criteria can leave no viable options. Start with 1–2 critical gates max; use weighted penalties for soft constraints.
- **Metric staleness**: Cost, latency, trust scores change over time. Set appropriate TTLs per metric (seconds for latency, days for trust, hours for cost).
- **Criterion correlation**: Highly correlated criteria (e.g., cost and latency) effectively double-count. Check correlation matrix; consider combining or dropping redundant criteria.
- **Over‑complexity**: 10+ criteria become unwieldy. Stick to 3–7 key criteria; group related ones hierarchically if needed.
- **Circular dependencies**: If criteria reference each other (e.g., trust depends on uptime, which depends on provider selection), the system may be ill‑defined. Ensure criteria are independent measurements.
- **Budget gating loophole**: If budget criterion uses `remaining_budget`, it fluctuates as spending occurs, potentially changing rankings mid‑operation. Recompute rankings only at decision boundaries, not continuously.
- **Lack of explainability**: Users may distrust a black‑box ranking. Always surface top contributing criteria per ranked item: `Provider A scored 0.82 (trust: 0.35×0.95, cost: 0.25×0.70, ...)`.

## Configuration Examples

**Provider Selection** (`provider_selection.yaml`):
```yaml
version: 1.0
description: "Select LLM provider for user request"
gating:
  - criterion: within_budget
    operator: "=="
    value: true
  - criterion: region_compatible
    operator: "=="
    value: true
criteria:
  - id: trust_score
    weight: 0.35
    direction: benefit
    source: metrics.trust_score
    normalize: minmax
  - id: cost_efficiency
    weight: 0.25
    direction: benefit
    source: metrics.price_per_1k
    normalize: inverse_log  # log(1/(x+1))
    max: 10.0
  - id: sla_uptime
    weight: 0.20
    direction: benefit
    source: metrics.sla
    normalize: linear
  - id: latency_p50
    weight: 0.15
    direction: cost
    source: metrics.latency_p50_ms
    normalize: minmax
  - id: capabilities_match
    weight: 0.05
    direction: benefit
    source: capabilities.score
    normalize: linear
refresh_interval: 300  # seconds
```

**Feature Prioritization** (`feature_prioritization.yaml`):
```yaml
gating: []
criteria:
  - id: user_value
    weight: 0.40
    direction: benefit
    source: estimate.user_impact_score  # from user research
  - id: effort
    weight: 0.25
    direction: cost
    source: estimate.person_weeks
  - id: strategic_alignment
    weight: 0.20
    direction: benefit
    source: okr_alignment_score
  - id: technical_risk
    weight: 0.10
    direction: cost
    source: risk.uncertainty_score  # 1-10, higher is riskier
  - id: dependencies
    weight: 0.05
    direction: cost
    source: count(blocking_tasks)
```

## Advanced Patterns

### 1. Pairwise Comparison (AHP)

For subjective criteria where pairwise preference judgments are more reliable than absolute scoring:

```python
# Use AHP to derive weights from stakeholder pairwise comparisons
# Compare: "How much more important is trust vs cost?" → 3× more important
# Build comparison matrix, compute eigenvectors → normalized weights
```

Hermes integration: `hermes ranking ahp --criteria "trust,cost,latency" --pairwise-responses file.json`

### 2. Dynamic Weight Adjustment

Adjust weights based on context:
- **Cost‑saving mode**: increase weight on cost, decrease on SLA
- **Production mode**: increase SLA and trust weights, decrease cost
- **Experimental mode**: favor novelty/capability over stability

### 3. Multi-Objective Optimization (Pareto)

Instead of weighted sum, find non‑dominated options:

- An option is **dominated** if another is better on all criteria
- Remaining set is **Pareto frontier** — no single best, requires stakeholder choice

Useful when weights are too subjective to agree upon.

### 4. Monte Carlo Sensitivity Analysis

Vary weights within plausible ranges to test ranking stability:

```python
for _ in range(1000):
    w_trust = random.uniform(0.2, 0.5)
    w_cost = random.uniform(0.1, 0.3)
    # normalize weights to sum 1
    # recompute ranking, record winner
# Report: Provider A wins 70% of simulations, B wins 20%, tie 10%
```

## Hermes Integration Examples

**Example 1: Provider Selection for Chat Request**
```python
# User asks: "Write a Python script"
# Hermes decides which LLM to route to

ranking_result = hermes.ranking.select(
    item_type="llm_provider",
    context={"requires_vision": False, "budget_remaining": 2.50},
    criteria_profile="default"
)
# Returns: {"provider": "openai/gpt-4", "score": 0.87, "breakdown": [...]}
```

**Example 2: Feature Roadmap Prioritization**
```bash
hermes ranking prioritize-features \
  --input features.yaml \
  --criteria feature_prio.yaml \
  --output ranked_features.md
```

**Example 3: Resource Allocation for Sub-agents**
- Multiple sub‑agents available (coder, writer, researcher)
- Rank by: skill_match, current_load, cost_per_call, success_rate
- Pick top‑ranked agent for incoming task type

## References

- Multi‑criteria decision analysis (MCDA): https://en.wikipedia.org/wiki/MCDM
- Weighted sum model: simplest, most interpretable MCDA method
- Analytic Hierarchy Process (AHP): Saaty's pairwise comparison technique
- TopRank (Nowork Studio): https://github.com/nowork-studio/toprank (reference implementation)
- Hermes provider selection design doc: internal documentation
