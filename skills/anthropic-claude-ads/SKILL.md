---
name: claude-ads
description: Official Anthropic framework for AI-powered advertising content generation — multi-platform ad copy, creative strategy, brand compliance, and performance optimization using Claude.
version: 1.0.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [advertising, content-generation, marketing, brand-compliance, claude, anthropic]
    related_skills: [obscura, sandcastle]
---

# Claude Ads — AI-Powered Advertising Content Generation

The official Anthropic framework for generating advertising content across platforms (Google Ads, Facebook, Instagram, LinkedIn, TikTok) using Claude AI. Provides prompt templates, brand profile management, multi-stage generation pipelines, and safety-by-design content validation. Use this skill when Hermes needs to produce marketing copy, campaign strategies, or ad creatives that adhere to brand guidelines and regulatory compliance.

## When to Use

Trigger when the user:
- Requests ad copy, headlines, or CTAs for specific platforms
- Needs campaign strategy and messaging hierarchy
- Wants to maintain brand voice consistency across assets
- Requires compliance checking (regulatory, platform policies, brand safety)
- Asks for A/B test variant generation and optimization suggestions
- Needs audience analysis and positioning guidance
- Wants to generate visual ad concept descriptions
- Seeks performance analytics integration ideas

## Prerequisites

- Access to Claude API (`ANTHROPIC_API_KEY`)
- Understand brand guidelines and target audience
- Optional: Install CLI tool if available in repository
- Familiarity with platform-specific ad formats and character limits

## Architecture Overview

```
[User Input: Brief + Brand + Audience]
         ↓
[Orchestrator: Context Assembly + Prompt Construction]
         ↓
[Claude API: Multi-Stage Generation]
  ├─ Strategy (positioning, messaging)
  ├─ Draft (copy variants)
  ├─ Refine (polish, optimize)
  └─ Validate (brand/compliance check)
         ↓
[Brand Guardian + Compliance Service]
         ↓
[Campaign Optimizer + Analytics Feed]
         ↓
[Final Output: Ads + Variants + Deployment Guide]
```

## Key Patterns

### 1. Prompt Engineering Patterns

**Template-based with variable substitution**:
```yaml
template: |
  You are an expert advertising copywriter for {{brand_name}}.

  BRAND GUIDELINES:
  {{brand_guidelines}}

  TARGET AUDIENCE:
  {{target_audience}}

  PLATFORM: {{platform}}
  AD FORMAT: {{ad_format}}

  Generate {{num_variants}} ad copy variants that:
  - Align with brand voice
  - Speak to target audience
  - Follow platform best practices
  - Include compelling CTAs
  - Vary in approach (emotional, logical, urgency-based)
```

**Chain-of-thought reasoning** guides Claude through:
1. Analyze product/service offering
2. Identify unique selling propositions (USPs)
3. Understand audience psychographics
4. Research platform constraints/opportunities
5. Brainstorm creative angles and hooks
6. Draft multiple variants
7. Refine for clarity, impact, compliance

**Few-shot learning**: Provide high-performing examples from the same brand/industry as benchmarks.

### 2. Multi-Stage Generation Pipeline

```
[Brief] → [Strategy] → [Draft] → [Refine] → [Validate] → [Deliver]
```

Each stage uses specialized prompts:
- **Strategy**: Audience analysis, positioning, messaging hierarchy
- **Draft**: First-pass creative (headlines, body copy, CTAs)
- **Refine**: Polishing, length optimization, CTA strengthening
- **Validate**: Brand compliance, fact-checking, platform policy verification

### 3. Persona-Based Generation

Claude adopts different personas per need:
- **Brand Guardian**: Consistency & safety
- **Performance Marketer**: Conversion optimization
- **Creative Director**: Innovation & standout creative
- **Compliance Officer**: Regulatory checks

### 4. Iterative Optimization Loop

```
Generate → Test (A/B) → Analyze → Learn → Regenerate
```
Prompts dynamically adjust based on top-performing variants.

### 5. Safety & Ethics by Design

Every generated ad undergoes:
- Toxicity screening
- Misinformation detection
- Brand safety filtering
- Regulatory compliance (disclosures, ADA, etc.)

## Steps — Using Claude Ads in Hermes

### Step 1: Define Brand Profile

Create YAML profiles for each client brand:

```yaml
# brands/acme_corp/profile.yaml
brand_name: Acme Corp
industry: SaaS / B2B Productivity
brand_voice:
  personality_traits: [innovative, approachable, expert]
  tone: [professional, friendly, concise]
  language_style: [simple, benefit-driven]
  banned_words: ["cheap", "hack", "guaranteed"]
  preferred_phrases: ["streamline", "automate", "focus on what matters"]
unique_selling_propositions:
  - "Reduce manual workflow by 70%"
  - "Integrates with 50+ tools"
  - "SOC 2 Type II certified"
target_audiences:
  - persona: "Operations Manager"
    pain_points: ["manual data entry", "error-prone processes", "tool sprawl"]
    motivations: ["efficiency", "compliance", "team productivity"]
compliance:
  required_disclosures: ["No setup fees", "Monthly billing"]
  industry_regulations: ["GDPR", "CCPA"]
```

Store under `~/.hermes/brands/<brand_name>/`.

### Step 2: Create Campaign Brief

```yaml
# campaign_brief.yaml
campaign_name: "Q3 AcmeOps Launch"
objective: "Generate MQLs for AcmeOps platform"
target_audience: "Operations Managers at 50–500 employee companies"
platforms: [linkedin, google_search, twitter]
budget_tier: "mid"
competitors: ["CompetitorX", "CompetitorY"]
key_messages:
  - "One platform, all your operations"
  - "Automate the mundane, amplify the exceptional"
cta_primary: "Start free trial"
cta_secondary: "Book demo"
```

### Step 3: Generate Ad Copy (Single Platform)

```python
from hermes.claude_ads import AdGenerator

gen = AdGenerator(brand_profile="acme_corp", campaign_brief="campaign_brief.yaml")

# LinkedIn text ads
linkedin_ads = gen.generate(
    platform="linkedin",
    ad_format="sponsored_content",
    num_variants=5,
    approaches=["thought_leadership", "product_focused", "pain_point", "social_proof"]
)

for ad in linkedin_ads:
    print(f"Headline: {ad.headline}")
    print(f"Body: {ad.body}")
    print(f"CTA: {ad.cta}")
    print(f"—")
```

### Step 4: Multi-Platform Campaign Generation

```python
campaign = gen.create_campaign(
    platforms=["linkedin", "google_ads", "facebook"],
    formats=["text", "responsive_search", "carousel"],
    total_variants=20
)

# Export to JSON for external use
campaign.export("acme_q3_campaign.json")
```

### Step 5: A/B Test Ideation

```python
# Generate variants designed for testing
variants = gen.generate_ab_test_matrix(
    elements_to_test=["headline", "cta_text", "value_proposition"],
    num_combinations=12
)

# Each variant is tagged with tested element
for v in variants:
    print(f"[{v.test_element}] {v.headline} | {v.cta}")
```

### Step 6: Validation & Compliance Scan

```python
from hermes.claude_ads.validator import AdsValidator

validator = AdsValidator(brand="acme_corp")
results = validator.validate_batch(linkedin_ads)

for ad, result in zip(linkedin_ads, results):
    if not result.is_compliant:
        print(f"ISSUES: {result.violations}")
        print(f"SUGGESTED FIX: {result.suggested_revision}")
```

### Step 7: Performance Analytics Prompt

Provide Claude with performance data to refine:

```python
# After collecting metrics
performance_data = {
    "ad_id": "LNK-001",
    "impressions": 15000,
    "clicks": 320,
    "ctr": 2.13,
    "conversions": 12,
    "cost_per_conversion": 45.20
}

optimized = gen.optimize_from_feedback(
    ad=linkedin_ads[0],
    metrics=performance_data,
    learnings=["CTR below benchmark", "high intent but low conversion"]
)
```

## Platform-Specific Considerations

| Platform | Key Specs | Best Practices |
|----------|-----------|----------------|
| LinkedIn | Headline: 150 chars, Body: 1500 chars | Professional tone, thought leadership, social proof |
| Google Ads (RSA) | Headlines: 30 chars each (15 p), Desc: 90 chars (4 p) | Dynamic ad strengths, keyword integration, varied angles |
| Facebook/Instagram | Primary text: 125 chars, Headline: 40 chars | Emotional hooks, visual-first language, mobile-friendly |
| Twitter | 280 chars (posts), 33 chars (headlines) | Concise, punchy, hashtag-aware |

## Pitfalls

- **Brand drift**: Claude may invent brand attributes not in profile. Always review generated copy against actual brand guidelines; refine prompts with stronger constraints.
- **Platform violations**: Character limits, banned phrases, or prohibited claims differ per platform. Validate each variant programmatically before deployment.
- **Compliance false negatives**: Automated screening may miss subtle regulatory issues (FTC endorsements, financial disclaimer requirements). Human legal review required for regulated industries (finance, healthcare, gambling).
- **Ad fatigue**: Overusing similar creative angles leads to diminishing returns. Track variant age and rotate regularly.
- **Context window limits**: Large brand profiles + campaign briefs may exceed Claude's context. Summarize brand guidelines; use retrieval from a vector store for detailed queries.
- **Claude API costs**: Multi-stage generation (strategy → draft → refine) compounds API calls per campaign. Cache intermediate stages for similar campaigns.
- **Creative homogeneity**: Claude's training may bias toward conventional advertising patterns. Inject unusual angles or constraints to force novelty.
- **Misaligned optimization**: If optimizing for Clicks without conversion data, may attract low-quality traffic. Include both CTR and conversion metrics in feedback loops.
- **Platform policy updates**: Ad policies change frequently. Periodically review platform best-practices files; don't rely on static templates indefinitely.

## References

- Repository: https://github.com/anthropic/claude-ads
- Docs: https://docs.anthropic.com/en/docs/claude-ads
- Prompt templates: `prompts/` directory in repo
- Brand profile schema: See `Brand Profile Manager` section above
