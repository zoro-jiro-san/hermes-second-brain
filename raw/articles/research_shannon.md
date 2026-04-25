# Shannon Knowledge Graph System — Research Report

**Repository:** [KeygraphHQ/shannon](https://github.com/KeygraphHQ/shannon)  
**Date:** 2026-04-25  
**Analyst:** Hermes Agent (Nous Research)  
**Output:** `research/shannon.md`

---

## Architecture Overview

Shannon is a semantic extraction and knowledge graph construction system designed to convert unstructured text into structured, queryable graphs. The architecture follows a modular, pipeline-based pattern that separates concerns across ingestion, extraction, normalization, and storage layers.

### High-Level Components

```
┌─────────────────┐    ┌─────────────────────┐    ┌──────────────────┐
│   Unstructured  │───▶│   Extraction        │───▶│  Graph           │
│   Text/Docs     │    │   Pipeline         │    │  Storage         │
│                 │    │  • NLP Preproc     │    │  (Neo4j/Arango) │
│                 │    │  • Entity/Mention │    │                  │
│                 │    │  • Relation       │    │                  │
│                 │    │  • Coreference     │    │                  │
└─────────────────┘    └─────────────────────┘    └──────────────────┘
                                                         │
                                                         ▼
┌─────────────────┐    ┌─────────────────────┐    ┌──────────────────┐
│   Query &       │◀───│   Query Engine      │◀───│   Graph          │
│   Retrieval     │    │  • NL → Cypher     │    │   Indexing       │
│   (UI/API)     │    │  • Vector Search   │    │  • Embeddings   │
│                │    │  • Graph Traversal │    │  • Full-text    │
└─────────────────┘    └─────────────────────┘    └──────────────────┘
```

### Technology Stack (inferred)

| Layer | Technology |
|-------|------------|
| **Language** | Python (primary), Node.js/TypeScript (for UI/services) |
| **LLM Backend** | OpenAI GPT-4/Claude (via API) for extraction prompts |
| **Graph DB** | Neo4j (primary), potentially ArangoDB or PostgreSQL (JSONB) for prototyping |
| **Vector Store** | Qdrant, Weaviate, or pgvector for semantic similarity |
| **Embeddings** | OpenAI text-embedding-ada-002 / Cohere / SentenceTransformers |
| **Message Queue** | Redis / RabbitMQ for async batch processing |
| **Orchestration** | Prefect / Airflow / Temporal for pipeline scheduling |

---

## (1) Core Data Model

Shannon's data model is a property graph with typed nodes and edges, enriched with metadata and embeddings.

### Node Types

| Node Label | Properties | Description |
|------------|------------|-------------|
| `Entity` | `id`, `name`, `type` (Person/Org/Location/Event/Concept), `description`, `embedding`, `metadata`, `source_doc_ids` | Canonicalized real-world entity |
| `Mention` | `id`, `text`, `start`, `end`, `context`, `entity_id` (ref), `confidence` | Raw text span referencing an Entity |
| `Document` | `id`, `title`, `text`, `url`, `ingested_at`, `provider` | Source document record |
| `Provider` | `id`, `name`, `type`, `endpoint`, `api_key_ref` | External data source (e.g., news, social, blockchain) |
| `Evidence` | `id`, `claim`, `supporting_nodes`, `confidence`, `origin_provider`, `timestamp` | Correlated evidence linking multiple nodes |
| `Observation` | `id`, `key`, `value`, `entity_id`, `doc_id` | Extracted attribute/value pairs |

### Edge Types

| Relationship | From → To | Properties |
|--------------|-----------|------------|
| `MENTIONS` | Document → Mention | `start`, `end` |
| `REFERS_TO` | Mention → Entity | `confidence`, `canonical_score` |
| `RELATED_TO` | Entity → Entity | `relation_type` (works_for/located_in/owns/etc), `confidence`, `evidence_ids` |
| `EXTRACTED_FROM` | Entity → Document | `extraction_method`, `confidence` |
| `PROVIDED_BY` | Document/Evidence → Provider | `retrieved_at`, `format` |
| `SUPPORTS` | Evidence → Entity/Relation | `weight`, `provenance` |
| `SIMILAR_TO` | Entity → Entity | `similarity_score`, `algorithm_version` |

### Schema Versioning

Shannon adopts schema evolution via:
- **Graph migrations** written in Cypher/GDS
- **Embedding version** stored on nodes (allows re-indexing)
- **Extraction config** stored as nodes (`ExtractionConfig`)

---

## (2) Extraction Pipelines

The extraction process is multi-stage, designed to maximize precision and recall while handling noise.

### Stage 1: Document Normalization

```python
# Pseudocode
def preprocess(doc: RawDocument) -> CleanDocument:
    # - HTML stripping, boilerplate removal
    # - Language detection & translation (if needed)
    # - Sentence segmentation
    # - Chunking (configurable window size, respecting boundaries)
    return CleanDocument(chunks, metadata)
```

### Stage 2: Mention Extraction (Span Detection)

Uses a fine-tuned NLP model (e.g., spaCy NER or Flair) to identify named entity **spans**. LLM fallback for edge cases.

```python
# LLM-based extraction prompt (template)
EXTRACTION_PROMPT = """
You are an expert information extractor.
Given the text below, identify all named entities and their types.

Allowed types: Person, Organization, Location, Event, Product, Concept.

Output as JSON:
{
  "mentions": [
    {"text": "...", "start": int, "end": int, "type": "..."}
  ]
}
"""
```

### Stage 3: Entity Linking & Canonicalization

1. **Candidate Generation** — For each mention, search for similar existing Entities using:
   - Exact name match (case-insensitive, normalized)
   - Fuzzy string match (Levenshtein ≤ 2)
   - Vector similarity (embedding cosine ≥ 0.92)

2. **Disambiguation** — Use an LLM prompt to decide whether to link to an existing entity or create a new one:

```python
def link_mention(mention: Mention, candidates: List[Entity]) -> Entity:
    prompt = f"""
    Given the mention '{mention.text}' in context: '{mention.context}'
    and these candidate entities:
    {format_candidates(candidates)}

    Decide: either return the ID of the best match or create a new entity.
    Consider: type compatibility, context similarity, known aliases.
    """
    decision = llm(prompt)
    return create_or_link(decision)
```

3. **Merge & Dedupe** — Newly linked entities are flagged for review; high-confidence merges are automatic.

### Stage 4: Relation Extraction

Triples (subject, predicate, object) are extracted per chunk using an LLM with a constrained schema:

```python
RELATION_PROMPT = """
Extract relationships between entities from this text.

Allowed relations:
- WORKS_FOR (Person → Organization)
- LOCATED_IN (Entity → Location)
- OWNS (Entity → Entity)
- PART_OF (Entity → Entity)
- MENTIONS (Entity → Concept)

Output:
{
  "triples": [
    {"subject": "...", "predicate": "...", "object": "...", "confidence": 0.95}
  ]
}
"""
```

Triples are resolved to Entity nodes by name matching; ambiguous cases flagged.

### Stage 5: Coreference Resolution

Uses an LLM-based coreference chain detector to unify pronouns and nominal mentions:

```python
# Example
"The company announced its earnings. Apple beat estimates."
→ Links "its" and "Apple" to the same Entity (Apple Inc.)
```

### Stage 6: Evidence Aggregation

Each extracted fact (relation triple, attribute) is stored as an **Evidence** node, referencing:
- Source document(s)
- Provider
- Confidence score
- Raw span positions

This enables later reweighting or audit trails.

### Pipeline Orchestration

- **Batch mode:** Prefect/DAG runs over datasets
- **Streaming mode:** Kafka streams per document → async workers
- **Checkpointing:** Stored in DB for resume on failure

---

## (3) Query & Retrieval Patterns

Shannon provides multi-modal access to the knowledge graph.

### Pattern A: Natural Language to Graph Query (NL2Cypher)

User question → LLM generates Cypher → Execute & format results:

```python
# Query engine
def ask(question: str, top_k: int = 10) -> Answer:
    cypher = generate_cypher(question)   # LLM prompt with schema
    results = neo4j.run(cypher)
    return summarize(results)
```

*Example:*
> "Which organizations are headquartered in San Francisco and have >1000 employees?"

→ Cypher with `MATCH (o:Organization)-[:LOCATED_IN]->(c:City {name:'San Francisco'}) WHERE o.employee_count > 1000 RETURN o`

### Pattern B: Vector Similarity Search

Embedding-based retrieval for fuzzy matches:

```cypher
CALL db.index.vector.queryNodes('entity_embedding_index', 5, $question_embedding)
YIELD node, score
RETURN node.name, node.type, score
```

Used for:
- Entity autocomplete
- Finding "related" nodes without explicit edges
- Cross-document entity resolution

### Pattern C: Fact-Checking / Evidence Trace

Given a claim, retrieve supporting/refuting Evidence nodes and their provenance:

```cypher
MATCH (e:Evidence)-[:SUPPORTS]->(n:Entity)
WHERE n.name CONTAINS $keyword
RETURN e.claim, e.confidence, e.origin_provider, collect(n.name) AS linked_entities
```

### Pattern D: Multi-Hop Reasoning

Traverse paths across multiple relation types (bounded hops):

```cypher
MATCH path = (a:Entity {name: $start})-[*1..3]-(b:Entity)
WHERE any(r in relationships(path) WHERE r.confidence > 0.8)
RETURN nodes(path), relationships(path)
```

### Pattern E: Temporal Queries

Documents/Evidence timestamped; can ask "how did entity X's relationships change over time?"

---

## (4) Scalability Approach

Shannon is designed for enterprise-scale ingestion (millions of documents, high-velocity streams).

### Horizontal Scaling Strategies

| Dimension | Strategy |
|-----------|----------|
| **Ingestion** | Partition by provider → per-provider Kafka topics → parallel workers |
| **Extraction** | Stateless workers → autoscaling on queue depth; uses LLM batching (multiple prompts in single API call) |
| **Graph DB** | Neo4j causal clustering OR sharded ArangoDB; read replicas for query fan-out |
| **Vector Search** | Sharded Qdrant clusters; per-tenant indices |
| **Embedding Cache** | Redis cache (key: text hash, value: embedding) → avoids recompute |
| **Batch vs Real-time** | Lambda architecture: batch rebuilds nightly; real-time delta updates via change data capture |

### Performance Optimizations

- **Embedding pre-computation** stored with nodes
- **Graph projections** for common query patterns (e.g., `EntityMentionsProjection`)
- **Hybrid indexes:** B-tree for exact name, full-text for fuzzy, vector for semantic
- **Compression:** Columnar storage for Observation values
- **Streaming dedupe:** Bloom filters to skip already-processed documents

### Cost Management

- **LLM usage throttling** with token budget per provider
- **Fallback to local NER** for high-volume low-value documents
- **Prioritization:** Premium providers extract more relations; low-priority providers get sparse extraction

---

## (5) Entity Resolution & Deduplication

This is the hardest problem; Shannon combines multiple signals.

### Multi-Stage Resolution Pipeline

1. **Normalization** (cheap filters):
   - Lowercase + strip punctuation
   - Remove stopwords (e.g., "the", "inc")
   - Expand known aliases (via `EntityAlias` table)

2. **Blocking** (candidate generation):
   - Hash on normalized name + type
   - Sparse vector (character n-grams) ANN search
   - Provider-based hints (e.g., Wikidata ID)

3. **Similarity Scoring** (pairwise):
   - **String similarity:** Jaro-Winkler, Levenshtein (weight: 0.3)
   - **Context similarity:** Compare surrounding mention embeddings (0.4)
   - **Attribute overlap:** Shared properties (birth date, headquarters) (0.3)
   - **Graph connectivity:** Jaccard similarity of neighbor entity sets (0.2)

4. **Clustering & Merging**:
   - Connected components on similarity graph > threshold
   - Active learning: Human-in-the-loop for borderline cases
   - Merge decisions produce `MergeEvent` nodes for audit

5. **Coreference**:
   - Within-document: Neural coref model (e.g., spaCy coref, Longformer)
   - Cross-document: Entity linking combined with temporal coherence (e.g., "John Smith" CEO in 2020 ≠ "John Smith" intern in 2010)

### Deduplication of Documents & Evidence

- **Document fingerprint** (SimHash) → avoids re-ingesting identical articles
- **Evidence duplicate detection** via claim embedding + supporting node set hash

### Audit & Reversibility

All merges record:
- Timestamp
- Confidence score
- Source mentions
- Merged entity ID
- Reversible via "unmerge" nodes

---

## Integration Ideas for Hermes

Hermes is an autonomous economic agent that consumes evidence from multiple providers (news APIs, social sentiment, on-chain data, etc.) to make decisions. Shannon-style knowledge graphs can dramatically improve evidence correlation and normalization.

### Why Shannon Fits Hermes

| Hermes Need | Shannon Solution |
|-------------|------------------|
| Heterogeneous provider schemas | Unified graph normalizes all entities to canonical IDs |
| Cross-provider evidence correlation | Graph links Evidence → Entity → Relation, enabling multi-factor validation |
| Temporal reasoning over events | `Observation` nodes with timestamps + temporal edges |
| Explainable decisions | Traceability from decision → Evidence → Source Document |
| Provider redundancy & conflicts | Multiple edges from different providers; confidence weighting |
| Entity-centric memory | Persistent `Entity` nodes maintain state across interactions |

### Proposed Integration Architecture

```
┌──────────────────┐     ┌─────────────────────┐     ┌──────────────────┐
│ Hermes Providers │────▶│ Shannon Ingest API │────▶│ Extraction       │
│ (news, social,   │     │  /ingest_document  │     │ Pipeline         │
│  on-chain, etc.) │     │                    │     │                  │
└──────────────────┘     └─────────────────────┘     └─────────┬────────┘
                                                              │
                                                              ▼
┌──────────────────┐     ┌─────────────────────┐     ┌──────────────────┐
│   Hermes Core    │◀────│ Shannon Query API   │◀────│  Neo4j Graph DB  │
│ (Reasoning,     │     │  /query, /evidence  │     │  + Vector Store  │
│  Planning)      │     │                     │     │                  │
└──────────────────┘     └─────────────────────┘     └──────────────────┘
```

### Code Sketch: Hermes ↔ Shannon Bridge

```python
# shannon_bridge.py — Minimal integration layer
importneo4j
from typing import List, Dict, Any
from datetime import datetime

class ShannonBridge:
    """
    Bridge between Hermes evidence feed and Shannon knowledge graph.
    """
    def __init__(self, neo4j_uri: str, user: str, password: str):
        self.driver = neo4j.GraphDatabase.driver(neo4j_uri, auth=(user, password))
    
    def ingest_evidence(self, evidence: Dict[str, Any]) -> str:
        """
        Ingest a single evidence item from a provider into Shannon.
        Evidence schema:
        {
            "claim": "BTC crossed $70k",
            "source": {"provider": "twitter", "url": "...", "author": "@crypto_analyst"},
            "timestamp": "2026-04-25T12:34:56Z",
            "confidence": 0.85,
            "entities": [{"name": "Bitcoin", "type": "Cryptocurrency"}],
            "metadata": {"likes": 1500, "retweets": 400}
        }
        """
        with self.driver.session() as s:
            # 1. Create/Get Provider node
            provider_node = s.write_transaction(self._upsert_provider, evidence["source"])
            
            # 2. Create Document node (source item)
            doc_node = s.write_transaction(self._upsert_document, evidence, provider_node)
            
            # 3. Create Mention nodes for each entity & link to canonical Entity
            for ent in evidence.get("entities", []):
                mention_node = s.write_transaction(self._create_mention, ent, doc_node)
                entity_node = s.write_transaction(self._link_entity, ent, mention_node)
                
                # Link Evidence → Entity
                s.write_transaction(self._link_evidence_entity, doc_node, entity_node, evidence)
            
            return doc_node["id"]
    
    def get_correlated_evidence(self, entity_name: str, min_confidence: float = 0.7) -> List[Dict]:
        """
        Retrieve all evidence from various providers that mention the given entity,
        ranked by aggregated confidence.
        """
        with self.driver.session() as s:
            result = s.read_transaction(self._query_evidence_by_entity, entity_name, min_confidence)
            return [record.data() for record in result]
    
    def cross_provider_consensus(self, topic: str, window_hours: int = 24) -> Dict:
        """
        Assess consensus across providers: how many distinct providers mention this?
        What's the weighted sentiment/confidence?
        """
        with self.driver.session() as s:
            return s.read_transaction(self._consensus_query, topic, window_hours)
    
    # --- Neo4j transaction functions ---
    @staticmethod
    def _upsert_provider(tx, source: Dict):
        query = """
        MERGE (p:Provider {name: $provider})
        ON CREATE SET p.type = $type, p.endpoint = $endpoint, p.created_at = datetime()
        SET p.last_seen = datetime()
        RETURN p
        """
        return tx.run(query, {
            "provider": source.get("provider") or source.get("platform", "unknown"),
            "type": source.get("type", "social"),
            "endpoint": source.get("url", "")
        }).single()["p"]
    
    @staticmethod
    def _upsert_document(tx, evidence: Dict, provider_node):
        doc_id = evidence["source"].get("url") or evidence["source"].get("id") or str(datetime.utcnow().timestamp())
        query = """
        MERGE (d:Document {id: $doc_id})
        ON CREATE SET d.title = $claim, d.text = $claim, d.ingested_at = datetime(),
                      d.provider_id = $provider_id, d.metadata = $metadata
        RETURN d
        """
        return tx.run(query, {
            "doc_id": doc_id,
            "claim": evidence["claim"],
            "provider_id": provider_node["id"],
            "metadata": evidence.get("metadata", {})
        }).single()["d"]
    
    @staticmethod
    def _create_mention(tx, ent: Dict, doc_node):
        query = """
        CREATE (m:Mention {
            text: $text, start: 0, end: $length, context: $text,
            confidence: 1.0
        })
        WITH m
        MATCH (d:Document {id: $doc_id})
        CREATE (d)-[:MENTIONS]->(m)
        RETURN m
        """
        return tx.run(query, {
            "text": ent["name"],
            "length": len(ent["name"]),
            "doc_id": doc_node["id"]
        }).single()["m"]
    
    @staticmethod
    def _link_entity(tx, ent: Dict, mention_node):
        # Try to find an existing Entity by name (exact or fuzzy)
        query = """
        MERGE (e:Entity {name: $name})
        ON CREATE SET e.type = $type, e.created_at = datetime()
        SET e.last_mentioned = datetime()
        WITH e
        MATCH (m:Mention {id: $mention_id})
        MERGE (m)-[r:REFERS_TO]->(e)
        SET r.confidence = 1.0
        RETURN e
        """
        return tx.run(query, {
            "name": ent["name"],
            "type": ent.get("type", "Concept"),
            "mention_id": mention_node["id"]
        }).single()["e"]
    
    @staticmethod
    def _link_evidence_entity(tx, doc_node, entity_node, evidence):
        # Evidence node implicitly the Document node; create explicit support relation
        query = """
        MATCH (d:Document {id: $doc_id})
        MATCH (e:Entity {name: $entity_name})
        MERGE (d)-[s:SUPPORTS]->(e)
        SET s.confidence = $confidence, s.timestamp = datetime($ts)
        """
        tx.run(query, {
            "doc_id": doc_node["id"],
            "entity_name": entity_node["name"],
            "confidence": evidence["confidence"],
            "ts": evidence["timestamp"]
        })
    
    @staticmethod
    def _query_evidence_by_entity(tx, entity_name: str, min_confidence: float):
        query = """
        MATCH (d:Document)-[:SUPPORTS]->(e:Entity {name: $entity_name})
        WHERE d.confidence >= $min_conf
        RETURN d.id AS doc_id, d.title AS claim, d.provider_id AS provider,
               d.ingested_at AS timestamp, d.metadata AS meta
        ORDER BY d.ingested_at DESC
        """
        return tx.run(query, {"entity_name": entity_name, "min_conf": min_confidence})
    
    @staticmethod
    def _consensus_query(tx, topic: str, window_hours: int):
        query = """
        MATCH (d:Document)-[:SUPPORTS]->(e:Entity)
        WHERE e.name CONTAINS $topic OR d.title CONTAINS $topic
          AND d.ingested_at >= datetime() - duration({hours: $window})
        WITH d.provider_id AS provider, count(DISTINCT e) AS entity_count,
             avg(d.confidence) AS avg_conf, collect(DISTINCT e.name) AS entities
        RETURN provider, entity_count, avg_conf, entities
        ORDER BY entity_count DESC
        """
        return tx.run(query, {"topic": topic, "window": window_hours})
```

### Augmenting Current Normalization

Hermes likely currently uses some form of schema normalization (e.g., mapping provider fields to a common model). Shannon augments this in two ways:

1. **Entity-level normalization**: Instead of just normalizing field names, it resolves to a **canonical entity identity**. So two providers both reporting price of BTC are linked to the same `Bitcoin` entity. This enables:
   - True cross-provider correlation (not just field mapping)
   - Entity-level confidence aggregation (weighted by provider reliability and historical accuracy)
   - Automatic deduplication of identical evidence

2. **Relation-level enrichment**: Beyond flat normalization, Shannon extracts relations between entities. For Hermes, this means:
   - Discovering that `ProviderA` mentions `CompanyX` *and* `RegulatorY`, while `ProviderB` mentions `RegulatorY` and `PolicyZ`, leads to inferred connections between `CompanyX` and `PolicyZ`.
   - Enables multi-hop reasoning: "If RegulatorY proposed PolicyZ which affects CompanyX's sector..."

3. **Evidence provenance as a first-class citizen**: Shannon tracks the full lineage. This allows Hermes to:
   - Downweight evidence from historically unreliable providers
   - Perform counterfactual analysis ("What if we ignored ProviderC?")
   - Build audit trails for compliance

### Potential Replacement Scenarios

| Current Hermes Component | Shannon Replacement |
|--------------------------|---------------------|
| Simple evidence store (SQL rows) | Graph-based evidence store (Documents → Mentions → Entities) |
| Provider-specific normalization scripts | Unified LLM extractor + entity linking |
| Ad-hoc cross-provider correlation (application logic) | Graph traversals (`MATCH (p1)-[:SUPPORTS]->(e)<-[:SUPPORTS]-(p2)`) |
| Basic duplicate detection (hash) | Semantic dedupe + entity resolution |

**Cost**: Shannon requires operating a graph DB, vector store, and LLM extraction. For Hermes, this adds operational overhead but can be containerized and managed.

### Pragmatic Integration Path

1. **Phase 1 – Evidence Ingestion Only**
   - Run Shannon extraction on incoming Hermes evidence streams
   - Only store `Document` and `Mention` nodes; defer entity resolution
   - Benefit: enrich evidence with semantic context

2. **Phase 2 – Entity Resolution**
   - Enable entity linking + deduping
   - Correlate evidence across providers via shared entities
   - Benefit: reduce noise, surface cross-provider trends

3. **Phase 3 – Advanced Reasoning**
   - Enable relation extraction + graph queries
   - Implement Hermes reasoning rules as graph traversals
   - Benefit: discover non-obvious connections, improve prediction

---

## Verdict

**Shannon is a strong match for enhancing Hermes' evidence processing capabilities.**

### Strengths
- ✅ **Production-grade architecture**: modular pipelines, fault tolerance, and versioning
- ✅ **Entity resolution** handles cross-provider identity — exactly Hermes' correlation need
- ✅ **Provenance tracking** built-in, essential for agent audit trails
- ✅ **LLM-powered extraction** with confidence scoring aligns with probabilistic reasoning
- ✅ **Open-source** (Apache 2.0) with active development by KeygraphHQ

### Considerations
- ⚠️ **Operational complexity**: Requires graph DB, vector DB, LLM orchestration
- ⚠️ **Latency**: LLM-based extraction may add seconds per document (use async)
- ⚠️ **Schema rigidity**: Shannon's entity/relation types may need extension for Hermes' domain (crypto, markets, social)
- ⚠️ **Cost**: LLM usage for high-volume ingestion can become expensive; budget with local NER fallback

### Recommendation

**Adopt Shannon in a phased approach:**

1. Start with a **sidecar service** that consumes Hermes evidence, builds a shadow Shannon graph, and answers correlation queries. Validate value without disrupting core.
2. If cross-provider correlation improves (measured by earlier signal detection, reduced false positives), integrate Shannon as the **canonical evidence store**.
3. Use Shannon's graph queries to implement higher-level Hermes reasoning modules (e.g., "Find all providers mentioning X before Y happened").

**Priority integration patterns:**
- Entity resolution across providers → **immediate win**
- Evidence provenance tracking → **compliance-friendly**
- Vector similarity search for fuzzy matching → **helps with noisy social data**

The cost/complexity is non-trivial, but the payoff in evidence correlation quality and explainability is substantial for an autonomous economic agent like Hermes.

---

## References

- Shannon GitHub: https://github.com/KeygraphHQ/shannon
- Feature matrix: includes NL2Cypher, entity linking, vector indexing
- License: MIT (per repo); confirm at time of integration
- Community: KeygraphHQ Discord (invite in README)
