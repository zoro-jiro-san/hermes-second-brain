---
name: "Shannon: Knowledge Graph Construction & Entity Resolution"
description: "Skills and patterns extracted from Shannon research: semantic knowledge graph construction, entity resolution, multi-provider evidence correlation, and graph-based reasoning."
trigger: "when working with knowledge graphs, entity extraction, evidence correlation, or semantic reasoning over unstructured data"
---

# Shannon: Knowledge Graph & Evidence Correlation Patterns

## Overview
This skill extracts patterns from **Shannon** (by KeygraphHQ), a semantic extraction and knowledge graph construction system that converts unstructured text into structured, queryable graphs. It is highly relevant for autonomous agents like Hermes that must ingest heterogeneous evidence from multiple providers and reason over correlated facts.

## What It Does
Provides end-to-end patterns for:
- **Document ingestion & normalization**: HTML stripping, boilerplate removal, chunking
- **Entity/Mention extraction**: NLP-based span detection with LLM fallback
- **Entity linking & canonicalization**: Candidate generation, LLM-based disambiguation, merge/dedupe
- **Relation extraction**: Triple extraction via constrained LLM prompts
- **Coreference resolution**: Within-document and cross-document entity unification
- **Evidence aggregation**: Provenance tracking, confidence scoring, multi-provider correlation
- **Graph construction**: Property graph stored in Neo4j/Arango, with embeddings and indexes
- **Query patterns**: NL2Cypher, vector similarity, multi-hop reasoning, temporal queries

## When to Use
- Building systems that aggregate evidence from multiple sources
- Implementing entity-centric memory or knowledge bases
- Needing explainable reasoning with traceable evidence provenance
- Correlating facts across heterogeneous provider schemas
- Performing multi-hop reasoning or fact-checking on ingested data
- Setting up search/retrieval augmented by vector + graph hybrid indexes

## Setup
Read the full research at: `/home/tokisaki/work/research-swarm/outputs/research_shannon.md`

## Implementation Steps
### Phase 1 — Evidence Ingestion Only
1. Build an ingestion API endpoint that accepts Hermes provider evidence
2. Normalize documents (clean, segment, chunk) and store as `Document` nodes
3. Extract `Mention` spans for entities (use spaCy + LLM fallback)
4. Create `Document → MENTIONS → Mention` edges; defer entity resolution for now
5. Benefit: enriched evidence with semantic context, even before full entity linking

### Phase 2 — Entity Resolution
1. Implement candidate generation: exact match, fuzzy (Levenshtein), vector similarity (cosine ≥ 0.92)
2. Build LLM-based disambiguation prompt: choose existing entity or create new canonical entity
3. Set up merging pipeline with confidence scoring and human-in-the-loop review for borderline cases
4. Link mentions to canonical `Entity` nodes via `REFERS_TO` with confidence
5. Enable cross-provider correlation via shared Entity IDs; weight by provider reliability

### Phase 3 — Relation Extraction & Reasoning
1. Define allowed relation types (e.g., `WORKS_FOR`, `LOCATED_IN`, `OWNS`, `PART_OF`, `MENTIONS`)
2. Run LLM extraction with constrained schema per chunk; store as `RELATED_TO` edges
3. Build `Evidence` nodes linking claims to source documents and providers
4. Implement graph queries:
   - NL2Cypher for natural language questions
   - Vector search for fuzzy entity matching
   - Multi-hop reasoning (bounded path traversal)
   - Temporal queries (by timestamp)
5. Integrate with Hermes reasoning layer: query graph to inform decisions

## Key Patterns Extracted
### Core Data Model
- **Node Types**: `Entity` (canonical), `Mention` (span), `Document` (source), `Provider`, `Evidence`, `Observation`
- **Edge Types**: `MENTIONS`, `REFERS_TO`, `RELATED_TO`, `EXTRACTED_FROM`, `PROVIDED_BY`, `SUPPORTS`, `SIMILAR_TO`
- **Properties**: embeddings, timestamps, confidence scores, provenance metadata

### Extraction Pipeline
1. Preprocess (HTML strip, language detect, segment, chunk)
2. Mention extraction (NER model + LLM fallback)
3. Entity linking (candidates → LLM disambiguation → merge)
4. Relation extraction (LLM with constrained schema)
5. Coreference resolution (within and across documents)
6. Evidence aggregation (track provenance per fact)

### Query & Retrieval
- **NL2Cypher**: LLM generates Cypher from natural language
- **Vector similarity**: embedding-based ANN for fuzzy matching
- **Fact-checking**: trace from evidence → document → provider
- **Multi-hop reasoning**: bounded-length path traversal with confidence thresholds
- **Temporal**: track entity changes over time

### Scalability
- Horizontal partitioning by provider (Kafka topics)
- Stateless extraction workers with LLM batching
- Graph DB clustering or sharding; read replicas
- Vector store sharding (Qdrant clusters)
- Embedding cache (Redis) to avoid recompute
- Lambda architecture: batch nightly rebuilds + real-time delta updates

### Entity Resolution
- Multi-stage: normalization → blocking → pairwise scoring → clustering → coreference
- Signals: string similarity, context similarity, attribute overlap, graph connectivity
- Active learning for borderline cases; merge audit trail for reversibility

## Pitfalls
- Operational overhead: requires graph DB, vector store, LLM orchestration, message queue
- LLM extraction latency: use async pipelines, prioritize high-value providers, fallback to local NER for high-volume low-value docs
- Schema rigidity: Shannon's entity types may need extension for crypto/markets; build extensible type system
- Cost management: LLM token budgets per provider; batching; throttle low-priority sources
- Merge conflicts: establish clear conflict resolution policies; enable manual override

## References
- Research: `research_shannon.md`
- GitHub: https://github.com/KeygraphHQ/shannon
- License: MIT (confirm at integration time)
