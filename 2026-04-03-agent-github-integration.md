# Agent Capabilities & GitHub Integration
**Date:** April 3, 2026
**Source:** Capability exploration and planning session

---

## Summary

Explored what an AI agent can autonomously do on GitHub, evaluated model/API pricing for coding workloads, and discussed multi-agent orchestration approaches.

## 1. Agent Capabilities on GitHub

### Full PR Lifecycle
- Create feature branches from issues
- Write and commit code changes
- Open pull requests with descriptions
- Respond to review comments
- Merge when approved

### Code Review
- Analyze git diffs for bugs, style issues, security vulnerabilities
- Leave inline comments on specific lines
- Approve or request changes
- Suggest improvements with concrete code

### Issue Management
- Create issues from user requests
- Apply labels and assignees
- Triage incoming issues
- Close resolved issues with references to fixing commits

### Repository Maintenance
- Update dependencies (Cargo.toml, package.json)
- Fix CI/CD pipeline failures
- Keep documentation synchronized with code
- Generate changelogs

## 2. Model/API Selection Strategy

### Cost-Conscious Approach
| Tier | Models | Use Case | Cost |
|------|--------|----------|------|
| Premium | Claude Opus, GPT-4 | Complex reasoning, architecture | ~$15/M tokens |
| Mid | Claude Sonnet, GPT-4o-mini | General coding, PR reviews | ~$3/M tokens |
| Budget | Gemini Flash, GLM-4 | Mechanical tasks, formatting | ~$0.1/M tokens |
| Free | OpenRouter free tier | Fallback, testing | $0 |

### Key Insight
API credits beat fixed subscriptions for coding workloads because:
- Sessions can consume hundreds of thousands of tokens
- No hard cap on usage (pay-per-use)
- Can route different tasks to different-priced models
- Free models on OpenRouter provide a safety net

## 3. Multi-Agent Orchestration

### Approaches Considered
1. **open-multi-agent** — Open-source multi-agent orchestration framework
2. **Simple delegation** — One agent delegates subtasks to specialized agents
3. **Direct tool use** — Single agent with all tools (simplest, often sufficient)

### Decision: Keep It Simple
- PAT + SSH already provides full GitHub access
- GitHub Apps add complexity without clear benefit for solo projects
- A single agent with good tools covers 90% of use cases
- Multi-agent is worth it only when tasks are truly parallelizable

## 4. Key Learnings

1. **Start simple, add complexity as needed** — One agent + tools > overengineered multi-agent system
2. **Budget-aware routing** — Use expensive models for hard problems, cheap models for easy ones
3. **SSH > HTTPS+token for git** — More reliable, no token expiration
4. **API credits > subscriptions** — For heavy coding/research workloads
