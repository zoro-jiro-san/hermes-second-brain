# GitHub Setup, Identity, & Agentic Engineering
**Date:** April 9, 2026
**Source:** Hands-on setup session

---

## Summary

Set up full GitHub access for the AI agent, established identity system, created first agentic engineering repository, and learned important lessons about token handling.

## 1. GitHub Authentication Setup

### Methods Configured

#### SSH Key (ed25519)
- Generated ed25519 key pair
- Added public key to GitHub account
- Primary method for git clone/push/pull operations
- Validated with `ssh -T git@github.com`

#### Personal Access Token (PAT)
- Fine-grained PAT with repo scope
- Used for GitHub REST API operations (create repos, manage issues)
- Stored in `~/.hermes/.env` as `GITHUB_TOKEN`

#### Git Configuration
```
user.name = zoro-jiro-san
user.email = eth.sarthi@gmail.com
credential.helper = store
```

## 2. Identity System

### Agent Identity
- **Name:** Toki
- **Purpose:** Persistent identity across sessions
- **Storage:** `identity.md` + memory system

### User Identity
- **Name:** Nico
- **Preferences:** Honest critique, concise questions, practical solutions

### Memory System
- Cross-session persistent memory
- User preferences and corrections
- Environment facts (OS, tools, project structure)
- Injected into every conversation automatically

## 3. Agentic Engineering Repository

Created `agentic-engineering-2026-04-09`:
- First project repository managed entirely by the agent
- Pushed via SSH successfully
- Established the pattern: agent creates, commits, and pushes autonomously

## 4. Token Handling Lessons

### The Problem
GitHub PATs are 40-character strings starting with `ghp_`. Shell tools (grep, cut) can truncate or mangle tokens, especially when they contain characters that look like regex or glob patterns.

### The Solution
```python
# DON'T: Use shell pipes to extract tokens
token = subprocess.run("grep GITHUB_TOKEN .env | cut -d= -f2", shell=True)

# DO: Use Python to read and parse
with open('.env') as f:
    for line in f:
        if line.startswith('GITHUB_TOKEN='):
            token = line.split('=', 1)[1].strip()
```

### Validation Pattern
Always validate before use:
```bash
curl -s -H "Authorization: token $TOKEN" https://api.github.com/user
# Should return: {"login": "zoro-jiro-san", ...}
# NOT: {"message": "Bad credentials"}
```

## 5. Key Learnings

1. **SSH is more reliable than HTTPS+token** — No token expiration, no truncation issues
2. **Python subprocess > shell pipes for secrets** — Shell tools mangle strings
3. **Validate tokens immediately** — Don't discover auth failures mid-operation
4. **One .env variable per key** — Duplicate keys (two GITHUB_TOKEN lines) cause confusion
5. **Identity matters** — Having a persistent agent name and memory makes interactions more natural and efficient
