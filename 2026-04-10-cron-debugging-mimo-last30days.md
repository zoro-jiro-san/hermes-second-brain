# April 10, 2026 — Cron Pipeline Debugging, MiMo v2 Pro & Last30days v3

**Date:** 2026-04-10  
**Source:** Telegram conversation with Nico (8:51 AM), Hermes agent operations  
**Author:** Toki (Nico's AI agent)

---

## Summary

Daytime session with Nico covered three major topics: (1) debugging the nightly cron pipeline after 3 of 4 jobs failed to execute, (2) researching Xiaomi MiMo v2 Pro — a free trillion-parameter model announced with Hermes v0.8.0, and (3) scraping info about Last30days v3 — an AI agent-led search engine. Additionally, the Hermes agent was found to be 114 commits behind and was updated to v0.8.0.

---

## Key Takeaways

### Cron Pipeline Debugging

1. **3 of 9 cron jobs had never run** — Daily Learnings Update (9 PM), Repo Update Reminder (10 PM), and Hermes Self-Update (7 AM) all showed `last_run_at: null`.

2. **Root cause was a timing issue** — All 9 jobs were created on April 9 between 22:06–22:35. The 9 PM and 10 PM jobs were created *after* their scheduled time that evening, so they missed their slot and wouldn't fire until the next day.

3. **The 7 AM Hermes Self-Update was a genuine bug** — it was created at 22:27 on April 9, should have fired at 07:00 on April 10, but didn't. The scheduler may have a bug with jobs created close to their next run time.

4. **Fix applied**: Manually triggered all 3 stuck jobs to run immediately, resetting their `next_run_at` times and unblocking the schedule going forward.

### Xiaomi MiMo v2 Pro

5. **MiMo v2 Pro** is a trillion-parameter model with a 1M context window, optimized for agentic workloads. Free for 14 days via Nous Portal (no credit card), or free for 1 week on OpenRouter.

6. **Pricing is $1/$3 per million tokens** — 67% cheaper than Claude Sonnet, making it attractive for auxiliary tasks (compression, summarization).

7. **Hermes v0.8.0** auto-uses MiMo for auxiliary tasks on the Nous free tier, but setup requires **OAuth browser login** (`hermes auth`) — can't be completed autonomously by the agent.

8. **Blocker**: OAuth requires Nico's interactive browser session. A reminder cron job was created for 9 PM tonight (job ID: `60b391590b3f`).

### Last30days v3

9. **Last30days v3** is an AI agent-led search engine that scores results by upvotes, likes, and real money. It scrapes Reddit, X, and YouTube with **no API keys needed**.

10. **The tweet by @mvanhorn** mentioned 20K+ GitHub stars and positioned it as a social-first alternative to traditional search.

11. **GitHub repo not found** — attempted URLs `jeffreysperling/last30days` and `slashlast30days/last30days` returned 404. DNS issues also blocked web search at the time. The actual repo URL remains unresolved.

### Hermes Agent Update

12. **Hermes was 114 commits behind** — likely because the Self-Update cron job (7 AM) had never run. Running `hermes update` brought it to the latest version (v0.8.0, build 2026.4.8).

---

## Detailed Breakdown

### 1. Cron Pipeline Debugging Methodology

When Nico noticed missing output from the night's research, the investigation followed this pattern:

**Step 1: List all cron jobs** via the `cronjob` tool to check `last_status` and `last_run_at` for each.

**Step 2: Identify the gap** — 6 jobs had run successfully (showing timestamps), 3 showed `null`:
| Job | Schedule | Created | Why It Failed |
|-----|----------|---------|---------------|
| Daily Learnings | 21:00 | 22:06 (Apr 9) | Created after scheduled time |
| Repo Update Reminder | 22:00 | 22:35 (Apr 9) | Created after scheduled time |
| Hermes Self-Update | 07:00 | 22:27 (Apr 9) | **Genuine bug** — should have fired at 07:00 |

**Step 3: Manual trigger** — Used the `cronjob` tool to run each stuck job immediately, which resets `next_run_at` to the next scheduled occurrence.

**Lesson learned**: When creating cron jobs in batch, verify that each job's next run time is correct *immediately after creation*. Jobs created after their daily slot won't fire until the next day.

### 2. MiMo v2 Pro — Free Agentic Model

From the Hermes v0.8.0 release notes and multiple sources:

| Attribute | Detail |
|-----------|--------|
| **Provider** | Xiaomi (via Nous Portal) |
| **Parameters** | Trillion-scale |
| **Context window** | 1M tokens |
| **Optimized for** | Agentic workloads |
| **Cost** | Free 14 days (Nous) / Free 1 week (OpenRouter), then $1/$3 per M tokens |
| **API format** | OpenAI-compatible (`https://api.xiaomimimo.com/v1`) |
| **Hermes integration** | Auto-used for auxiliary tasks (compression, summarization) |

The key insight is that **auxiliary model selection has a significant impact on total cost** — using a free/cheap model for summarization and compression while reserving expensive models (Claude, GPT-5) for primary reasoning is the right architecture.

**Blocker for activation**: The Nous Portal requires OAuth browser login (`hermes auth`), which can't be completed by the agent autonomously. This is a common pattern — auth flows that need interactive browser sessions create a dependency on the human operator.

### 3. Last30days v3 — AI Agent-Led Search

From the tweet by @mvanhorn:

- **Concept**: Instead of algorithmic search ranking, uses AI agents to find and score content
- **Scoring signals**: Upvotes, likes, and real money (prediction markets?)
- **Data sources**: Reddit, X (Twitter), YouTube — all scraped without API keys
- **Scale**: 20K+ GitHub stars
- **Value proposition**: Social-first search that surfaces what real people care about

**Why it matters for our work**: The `last30days` skill in Hermes does something similar — multi-query social search across Reddit, X, YouTube, and other platforms. Understanding their architecture could improve our own social search pipeline.

**Unresolved**: The actual GitHub repo URL was never found. Attempted guesses returned 404, and DNS issues blocked web search at the time. This remains an open TODO.

### 4. Hermes v0.8.0 Update

The agent was **114 commits behind** the latest version. Key context:
- The Self-Update cron job (7 AM) was one of the 3 jobs that never ran
- Running `hermes update` resolved the gap
- v0.8.0 introduced MiMo v2 Pro integration and auxiliary model auto-routing
- Current config: provider `zai`, model `glm-5.1`

**Operational lesson**: Agent self-maintenance (updates, health checks) should be the most reliable cron job, not the least. Consider adding a fallback check or health monitor that alerts when the update job fails.

---

## Actionable Items

1. **Nico needs to complete Nous Portal OAuth** — reminder set for 9 PM tonight
2. **Find the actual Last30days GitHub repo** — DNS issues blocked this; retry when connectivity is stable
3. **Investigate the cron scheduler bug** — why did the 7 AM job not fire despite being created 8+ hours before its slot?
4. **Add cron health monitoring** — alert when any nightly job fails to produce expected output
5. **Consider upgrading auxiliary model pipeline** — once Nous Portal is auth'd, MiMo v2 Pro could replace the current auxiliary model for compression/summarization

---

*Daytime session learnings from conversation with Nico. See also: [Solana MEV research](./2026-04-10-solana-mev-infrastructure.md) and [Multi-agent orchestration & news](./2026-04-10-multi-agent-orchestration-and-news.md) from the same day.*
