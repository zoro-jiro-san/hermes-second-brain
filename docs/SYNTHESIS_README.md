# Research Reports Knowledge Graph

This knowledge graph connects entities across 24 research reports covering AI agent systems, frameworks, patterns, and infrastructure. The graph is built from synthesis reports on tools, architectures, and integration opportunities relevant to Hermes Agent and autonomous systems.

## Schema

### Node Types

| Type | Description | Example |
|------|-------------|---------|
| `repo` | GitHub repository / open-source project | `anthropic/claude-ads` |
| `company` | Organization/company developing technology | `Obscura AI` |
| `person` | Individual contributor/researcher | `Eyal Toledo` |
| `tool` | Specific tool, CLI, or utility | `taskmaster` CLI |
| `framework` | Software framework or platform | `LangChain`, `CrewAI` |
| `concept` | Abstract idea, pattern, or methodology | `Recursive Decomposition` |
| `pattern` | Reusable design/architectural pattern | `Plugin Architecture` |
| `tech_stack` | Technology component or stack | `Docker`, `Cloudflare Workers` |
| `skill` | Capability or competence definition | `code_interpreter` |
| `service` | External API/service/cloud provider | `OpenAI API`, `Solana` |

### Edge Types (Relationships)

| Relation | Meaning | Example |
|----------|---------|---------|
| `uses` | Entity utilizes/integrates technology | Hermes → uses → LangChain callbacks |
| `integrates_with` | Bidirectional integration | Claude Ads → integrates_with → Google Ads API |
| `inspired_by` | Derives from/pattern borrowed | TaskMaster → inspired_by → Claude AI |
| `part_of` | Component relationship | SDK → part_of → Obscura platform |
| `extends` | Adds functionality to base | Fork → extends → Original repo |
| `implements` | Realizes a concept/pattern | Cognee → implements → CognitiveGraph |
| `produces` | Outputs/generates | Agent → produces → Synthetic data |
| `targets` | Goal or domain focus | Vibe-Trading → targets → Algorithmic trading |
| `compatible_with` | Works with standard/protocol | Skill → compatible_with → MCP protocol |
| `requires` | Dependency / prerequisite | Skill A → requires → Skill B |

### Source Attribution

Each node includes a `source` field indicating which research report(s) it was extracted from. This enables traceability back to original findings.

## File Structure

- `graph.nodes.json` — List of node objects: `{id, type, label, source, url?}`
- `graph.edges.json` — List of edge objects: `{from, to, relation, weight?}`
- `README.md` — This schema documentation

## Usage

Load the graph into a graph database (Neo4j, NetworkX, etc.) or use in-memory structures:

```python
import json

with open('graph.nodes.json') as f:
    nodes = {n['id']: n for n in json.load(f)}

with open('graph.edges.json') as f:
    edges = json.load(f)

# Build adjacency
from collections import defaultdict
adj = defaultdict(list)
for edge in edges:
    adj[edge['from']].append((edge['to'], edge['relation']))
```

Query patterns:

- Find all tools a project `uses`: filter edges where `to` matches tool type
- Find integration paths: traverse `integrates_with` edges
- Find patterns relevant to Hermes: filter nodes with source containing "Hermes"

## Notes

- Node IDs are lowercase, snake_cased entity labels (e.g., `anthropic_claude_ads`, `obscura_ai`)
- Duplicate entities across reports are merged
- Relationships are directional; invert for bidirectional queries
- Weights are optional; currently unassigned (future: citation frequency, relevance score)
