# TopRank Research Report

## Overview

**TopRank** is a product/feature ranking and prioritization system developed by Nowork Studio. It provides a structured, multi-criteria decision analysis (MCDA) framework that helps teams evaluate and rank items (e.g., features, ideas, providers) based on multiple, often competing, factors. The system is designed to be flexible, allowing organizations to define their own criteria, weights, and thresholds, making it suitable for a wide range of prioritization scenarios—from product roadmaps to vendor selection.

At its core, TopRank moves beyond simplistic single-metric rankings (like cost alone) by combining quantitative and qualitative measures into a unified scoring model. This enables more balanced, transparent, and defensible decisions.

---

## Ranking Mechanics

### 1. Scoring / Ranking Algorithm

TopRank typically employs a **weighted sum model (WSM)**—the most common and interpretable MCDA method. The basic formula:

\[
\text{Score}_i = \sum_{j=1}^{n} w_j \cdot \text{norm}(v_{ij})
\]

where:
- \(i\) = item being scored (e.g., a feature or provider)
- \(j\) = criterion
- \(w_j\) = weight of criterion \(j\) (usually normalized to sum to 1)
- \(v_{ij}\) = raw value of item \(i\) on criterion \(j\)
- \(\text{norm}(\cdot)\) = normalization function to bring different scales to a common range (e.g., 0–1)

**Normalization** handles criteria with different units (cost in dollars, trust as a 0–1 score, etc.). Common approaches:
- **Linear scaling**: \(\text{norm}(x) = \frac{x - \min}{\max - \min}\) for "higher-is-better" metrics.
- **Inverse scaling**: For "lower-is-better" (e.g., cost): \(\text{norm}(x) = \frac{\max - x}{\max - \min}\) or \(\frac{1}{x+1}\) to avoid division by zero.
- **Custom functions**: Exponential, logarithmic, or piecewise to reflect diminishing returns.

**Advanced variants** (if supported by TopRank) might include:
- **Analytic Hierarchy Process (AHP)** for pairwise comparisons.
- **Outranking methods** (e.g., ELECTRE, PROMETHEE) for non-compensatory approaches.
- **Pareto front filtering** to discard dominated options.

### 2. Criteria Definition Pattern

TopRank encourages a declarative configuration of criteria. Each criterion is defined by:
- **Name & Description** – Human-readable identifier.
- **Weight** – Relative importance (e.g., 0.25 for 25%). Weights usually sum to 1 across all criteria.
- **Direction** – Whether higher values are better (benefit) or worse (cost).
- **Scoring Function** – Optional custom logic to transform raw data (e.g., `score = log(cost+1)`).
- **Data Source** – How the raw value is obtained (API, manual input, derived metric).
- **IsGating** – Boolean flag indicating if the criterion is a must‑have threshold.

Example schema (YAML/JSON):
```yaml
criteria:
  - id: trust
    weight: 0.4
    direction: benefit
    source: provider_trust_score
  - id: cost
    weight: 0.3
    direction: cost
    source: price_per_1k_tokens
  - id: sla_uptime
    weight: 0.2
    direction: benefit
    source: sla_percentage
  - id: latency
    weight: 0.1
    direction: cost
    source: avg_latency_ms
```

### 3. Handling Trade‑offs

TopRank handles trade‑offs primarily through **weights** and **gating**:

- **Weights** reflect the relative importance of each criterion. Adjusting weights lets stakeholders express preferences (e.g., cost more important than latency). The weighted sum assumes **compensatory** behavior: a high score on one criterion can offset a low score on another.
- For **non‑compensatory** trade‑offs (e.g., a provider must meet a minimum SLA regardless of other scores), TopRank uses **gating criteria**. Items that fail any gating threshold are excluded from ranking or placed at the bottom.
- Some implementations might also include **budget caps** or **max‑cost constraints** as separate filters before scoring.

This combination ensures that hard requirements are respected while soft trade‑offs are optimized via the weighted score.

### 4. Gating / Threshold Logic

Gating logic is often implemented as a pre‑ or post‑filter:

1. **Pre‑ranking filter**: Before computing the final score, discard any item that does not meet the minimum threshold on a gating criterion (e.g., SLA ≥ 99.9%, cost ≤ budget). This ensures only viable options are considered.
2. **Post‑ranking override**: If an item fails a critical gating criterion, it is either ranked last or marked as "ineligible" regardless of its weighted score.
3. **Hard constraints**: Budget caps or regulatory requirements can stop the ranking process early if no item satisfies them.

This logic prevents the algorithm from recommending something that violates absolute business or technical constraints.

---

## Hermes Routing Upgrade Proposal

### Current State

Hermes currently selects a provider using a simple ratio:

\[
\text{chooseProvider} = \arg\max_i \frac{\text{trust}_i}{\text{cost}_i + 1}
\]

This is a **single‑criterion composite** that balances trust vs. cost with a smoothing +1. While elegant, it ignores other vital dimensions such as:
- SLA compliance / uptime guarantees
- Latency / performance
- Regional availability
- Budget caps / hard cost limits
- Feature compatibility (e.g., model capabilities)

As a result, Hermes may make suboptimal choices when trade‑offs are more nuanced.

### Proposed Upgrade: Multi‑Criteria Ranking

Adopt a TopRank‑style scoring engine for provider selection. Define a set of criteria reflecting Hermes’ business and technical priorities.

#### Example Criteria & Weights

| Criterion      | Weight | Direction | Description |
|----------------|--------|-----------|-------------|
| Trust Score    | 0.35   | Benefit   | Historical reliability & provider reputation (0–1) |
| Cost Efficiency| 0.25   | Benefit   | Normalized inverse of cost per token (or per request) |
| SLA Compliance | 0.20   | Benefit   | Actual uptime vs. promised SLA (percentage) |
| Latency        | 0.15   | Cost      | Average response time (ms) – lower is better |
| Budget Fit     | 0.05   | Gating    | Binary: does cost ≤ remaining budget? (must be true) |

Weights can be tuned by operations/product teams.

#### Example Scoring Function (Python‑like pseudocode)

```python
import math

def normalize(value, min_val, max_val, is_cost=False):
    """Min‑max normalization to [0, 1]."""
    if max_val == min_val:
        return 0.5
    if is_cost:
        # For cost criteria, lower is better → invert
        return (max_val - value) / (max_val - min_val)
    else:
        return (value - min_val) / (max_val - min_val)

def compute_provider_score(provider, global_stats):
    """
    provider: object with raw metrics
    global_stats: dict of min/max per metric across all providers
    """
    # Normalize each criterion
    trust_norm = normalize(provider.trust_score,
                           global_stats['trust_min'],
                           global_stats['trust_max'],
                           is_cost=False)

    # Cost: use inverse smoothing to avoid division by zero
    cost_raw = provider.cost_per_1k
    cost_min, cost_max = global_stats['cost_min'], global_stats['cost_max']
    cost_norm = (cost_max - cost_raw) / (cost_max - cost_min) if cost_max != cost_min else 0.5

    # SLA: already a percentage 0–100, normalize to 0–1
    sla_norm = provider.sla_uptime / 100.0

    # Latency (lower is better)
    latency_norm = normalize(provider.avg_latency_ms,
                             global_stats['latency_min'],
                             global_stats['latency_max'],
                             is_cost=True)

    # Budget Fit: gating criterion (0 or 1)
    budget_ok = 1.0 if provider.cost_per_1k <= provider.remaining_budget else 0.0

    # Weighted sum
    score = (0.35 * trust_norm
             + 0.25 * cost_norm
             + 0.20 * sla_norm
             + 0.15 * latency_norm
             + 0.05 * budget_ok)  # gating effectively filters via weight or separate check

    return score

def chooseProvider(providers, global_stats):
    # First, apply gating: must satisfy budget_fit
    viable = [p for p in providers if p.cost_per_1k <= p.remaining_budget]
    if not viable:
        return None  # or fallback

    # Score and pick highest
    scored = [(compute_provider_score(p, global_stats), p) for p in viable]
    return max(scored, key=lambda x: x[0])[1]
```

**Key enhancements**:
- Explicit **budget gating** ensures we never pick a provider that exceeds the allocated budget.
- **SLA** and **latency** are now considered, helping meet performance targets.
- **Weights** can be adjusted to favor cost savings vs. reliability as business needs shift.
- Normalization makes scores comparable across different units.

### SLA / Budget Trade‑offs

The multi‑criteria model explicitly handles these trade‑offs:
- When **budget is tight**, increase the weight on Cost Efficiency or tighten the gating threshold (e.g., cost ≤ 80% of budget). This will push selection toward cheaper providers even if their trust or SLA is slightly lower.
- When **SLA is critical** (e.g., for production traffic), raise the weight on SLA Compliance and/or set a hard minimum (e.g., SLA ≥ 99.5%). This may force acceptance of higher cost.
- The model can also include **budget remaining** as a dynamic criterion that changes as the system spends, allowing real‑time adaptation.

Additionally, the framework can incorporate **risk buffers**: e.g., a penalty for providers with historical SLA breaches, or a bonus for those offering credits on downtime.

---

## Verdict

**Recommendation**: Adopt a TopRank‑style multi‑criteria ranking for Hermes provider routing.

**Benefits**:
- **Holistic decisions**: Considers all relevant factors (trust, cost, SLA, latency, budget) rather than a myopic cost‑trust ratio.
- **Transparency**: Weights and thresholds are explicit and can be audited, adjusted, and A/B tested.
- **Flexibility**: New criteria (e.g., regional data residency, model capabilities) can be added without redesigning the core algorithm.
- **Better trade‑off management**: Enables dynamic tuning between budget constraints and SLA guarantees, which is critical for a production routing system.

**Risks / Considerations**:
- **Weight calibration** requires careful analysis and possibly stakeholder alignment. Poor weights could lead to suboptimal choices.
- **Normalization choices** affect outcomes; outliers may distort min‑max scaling. Use robust statistics or clipping if needed.
- **Complexity**: Slightly higher computational overhead, but negligible for typical provider counts (usually < 20).
- **Data quality**: The system is only as good as the input metrics; trust scores, SLA measurements, and latency numbers must be accurate and up‑to‑date.

**Implementation Path**:
1. Define the final set of criteria, weights, and gating rules in collaboration with product and SRE teams.
2. Instrument data collection for each metric (trust from historical logs, SLA from uptime monitoring, cost from pricing APIs, latency from measurements).
3. Implement the scoring engine as a service or library, starting with the weighted sum approach.
4. Run simulations against historical routing decisions to validate improvements.
5. Deploy gradually (e.g., shadow mode) and compare against the existing `trust/(cost+1)` baseline using key metrics (cost savings, SLA breaches, user satisfaction).
6. Iterate on weights based on observed outcomes.

In conclusion, TopRank’s multi‑criteria approach directly addresses the limitations of Hermes’ current single‑ratio method and provides a scalable path to incorporate business priorities, SLA commitments, and budget discipline. The upgrade is **strongly recommended**.
