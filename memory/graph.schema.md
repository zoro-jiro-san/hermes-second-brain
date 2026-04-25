# Knowledge Graph Schema

## Node Types
| Type | Description |
| repo | GitHub repository |
| person | Human contributor |
| tech | Tool/library/framework |
| pattern | Architectural/design pattern |

## Edge Types
| Relation | From → To | Meaning |
| uses | repo → tech | Repository uses this tool |
| implements | tech → pattern | Tech implements pattern |
| created | person → repo | Person created repo |
| related_to | repo → repo | Repos are related |

## Stats
- Nodes: 202
- Edges: 384
- Sources: 24 research reports
- Unresolved edges: 1
