---
name: Cognee
description: Cognitive architecture framework with graph-based reasoning, tiered memory, reward learning, and hierarchical planning for enhancing agent decision-making
trigger: Need to improve agent reasoning quality, memory utilization, confidence calibration, and goal-directed planning in complex autonomous workflows
---

## Overview

Cognee is an open-source cognitive AI framework developed by topoteretes that implements a human-like cognitive architecture enabling AI agents to reason, remember, learn, and plan. It is built around four core components:

- **CognitiveGraph (CogniGraph)**: A directed acyclic graph (DAG) representing thoughts, reasoning steps, and intermediate conclusions. It provides transparent chain-of-thought orchestration and full traceability of the reasoning process.
- **Memory Subsystem**: A tiered memory model distinguishing working memory (short-term, volatile) from long-term memory (persistent, vector- or graph-backed). Supports encoding, retrieval, and consolidation operations.
- **RewardEngine**: A reinforcement learning component that learns from feedback, attributing rewards to specific reasoning steps and adjusting future behavior accordingly.
- **GoalPlanner**: A hierarchical planner that decomposes high-level goals into executable sub-tasks, monitors progress, and dynamically replans when needed.

Cognee is model-agnostic, integrating with LLMs and traditional ML components, and emphasizes explainability through graph-based reasoning traces.

## Cognitive Patterns

### 1. Reasoning / Chain-of-Thought Orchestration

Cognee structures reasoning as a graph of **ThoughtNodes**. Each node encapsulates:
- A specific operation (LLM call, tool use, computation)
- Input data (including context from memory)
- Output result
- Metadata (confidence, timestamps, dependencies)

**Orchestration patterns**:
- **Sequential Chaining**: Nodes executed in linear order, passing output as input to next node
- **Parallel Branches**: Independent reasoning tracks executed concurrently; results merged by synthesis node
- **Backtracking**: If a node fails or yields low confidence, revert to earlier nodes and explore alternative paths
- **Meta-Reasoning**: Special nodes monitor the reasoning process itself (e.g., "Is the current path consistent?") and trigger adjustments like gathering more information

The **CognitiveEngine** dynamically constructs and traverses these graphs, enabling flexible and adaptive reasoning pipelines.

### 2. Memory Management (Working & Long-Term)

Cognee employs a multi-tier memory architecture:

- **Working Memory**: Volatile buffer holding current context, recent intermediate results, and active thoughts. Capacity-limited with LRU eviction.
- **Long-Term Memory (LTM)**: Persistent store, typically backed by vector database (Chroma, Weaviate) or graph DB, storing:
  - *Episodic memories*: specific experiences (completed job executions)
  - *Semantic memories*: facts, concepts, and learned relationships
  - *Procedural memories*: "how-to" knowledge (successful reasoning patterns)

**Memory operations**: Store (encode and store relevant information), Retrieve (query via similarity search or graph traversal), Consolidation (transfer important working memories to LTM and compress old memories).

### 3. Learning from Feedback / Rewards

Cognee incorporates reinforcement learning:
- **Reward Signals**: After task completion, assign reward based on outcome quality, user feedback, or automated metrics
- **Credit Assignment**: Attribute reward to specific ThoughtNodes using eligibility traces or Monte Carlo returns
- **Policy Update**: Adjust node selection probabilities or parameters to favor high-reward pathways
- **Reward Shaping**: Define intermediate rewards to encourage desirable intermediate states
- **Experience Replay**: Replay past episodes with updated rewards to reinforce learning without full retraining

This closed-loop enables continuous improvement of reasoning and decision-making.

### 4. Goal-Directed Planning

Cognee's **GoalPlanner** handles hierarchical planning:
- **Goal Decomposition**: Parse high-level goals into sub-goals with preconditions and effects (rule-based or LLM-driven)
- **Task Scheduling**: Order sub-goals respecting dependencies; assign to specialized modules or tools
- **Monitoring & Replanning**: Track progress; if sub-goal fails or circumstances change, re-plan by selecting alternatives or backtracking
- **Tool Integration**: Sub-goals can invoke APIs, execute code, or call external services

The planner works with the CognitiveEngine to ensure reasoning serves overarching goals and plans adapt to new information.

## Integration Opportunities

### Current Limitations in Typical Agent Normalization

Many agent systems have simplistic decision logic:
- **`normalize()` decision logic**: Aggregates multiple signals (rule-based scores, model confidences, heuristics) into single value via deterministic formula. This oversimplifies context dependencies and misses nuanced interactions.
- **Confidence calculation**: Produces raw score without considering the reasoning path that led to it or past similar situations, leading to over/under-confident estimates.
- **Job history recall**: Typically a simple list or basic keyword/date search, making it hard to efficiently surface relevant past experiences.

### Proposed Cognee-Style Enhancements

#### 1. Chain-of-Thought-Assisted Normalization

Replace monolithic `normalize()` with a **cognitive micro-chain**:
- **Context Extraction Node**: Analyze contextual signals (input type, source reliability, recent trends, user preferences) to produce dynamic weighting factors
- **Consistency Validation Node**: Check internal consistency across reasoning steps. If inconsistencies detected, flag uncertainty or trigger deeper analysis
- **Calibration Adjustment Node**: Apply learned calibration mapping (from historical reward signals) that transforms raw scores into well-calibrated probabilities

This layered reasoning yields more nuanced confidence estimates, and the chain itself can be updated via reinforcement learning.

#### 2. Reward-Modulated Confidence

Integrate Cognee's reward learning loop: After decisions are validated via external feedback, assign a reward that adjusts the parameters of the normalization chain (weights, calibration curves). Over time, the agent becomes better calibrated and context-aware.

#### 3. Episodic Memory for Job History

Implement vector-indexed episodic memory store:
- Each completed job encoded into dense embedding (job type, parameters, outcome, duration, success metrics, context)
- Store in vector database with metadata tags
- For new job, retrieve *k* most similar past jobs via semantic similarity and feed as context to reasoning chain
- Provides precedents, warns of past pitfalls, suggests proven strategies

#### 4. Goal-Aware Memory Consolidation

Link memory retention to goal relevance: Jobs contributing to high-level goals get prioritized in LTM; routine tasks may be compressed or archived. Focuses recall on what matters.

### Expected Benefits

- **Robust confidence estimates** that account for reasoning context and past performance, improving trust and decision quality
- **Faster, more relevant job history recall**, reducing planning overhead and increasing success rates
- **Continuous, automatic improvement** via reward-driven adaptation, without needing full retraining

## Steps

1. **Implement multi-tier memory architecture** (Week 1-2)
   - Set up vector database (Chroma, Weaviate, or Pinecone) for long-term memory storage
   - Design embedding model for job experiences: encode job type, parameters, outcomes, success metrics, context into dense vectors
   - Build working memory buffer with LRU eviction policy and capacity limits
   - Implement Store/Retrieve/Consolidation APIs
   - Add metadata tagging for efficient filtering (date range, success/failure, asset type, etc.)
   - Write memory backend tests for encoding fidelity and retrieval relevance

2. **Build cognitive reasoning graph engine** (Week 3-4)
   - Design ThoughtNode data structure: operation type, inputs, outputs, metadata, confidence, dependencies
   - Implement CognitiveGraph as DAG with node addition, edge creation, and topological traversal
   - Create node types: LLM call, tool invocation, computation, validation, synthesis
   - Build CognitiveEngine that dynamically constructs graphs based on task requirements
   - Support sequential chaining, parallel branches with merge, and backtracking on failure
   - Develop graph visualization/debugging tools to inspect reasoning traces

3. **Develop normalization chain with context awareness** (Week 5-6)
   - Replace existing `normalize()` with multi-stage pipeline:
     - Stage 1: Context extraction module that analyzes input context and produces dynamic signal weights
     - Stage 2: Consistency validator that computes aggregate confidence and uncertainty measures
     - Stage 3: Calibrator that applies learned sigmoid/logistic mapping to produce final probability
   - Implement learning mechanism: store normalized decisions and subsequent outcomes to train calibration parameters
   - Add reward attribution: link final decision outcome back to specific reasoning nodes
   - Create evaluation suite to measure calibration quality (reliability diagrams, Brier scores)

4. **Implement goal planner and task decomposition** (Week 7-8)
   - Define goal representation: hierarchical tree with preconditions, effects, success criteria
   - Build GoalPlanner module that parses high-level goals into executable sub-tasks
   - Implement dependency tracking and topological ordering
   - Add dynamic replanning on sub-goal failure or environment change
   - Integrate with tool registry: map sub-tasks to available tools/APIs
   - Develop planning heuristics: cost estimation, risk assessment, success probability

5. **Integrate reward learning and continuous improvement** (Week 9-10)
   - Design feedback collection: gather outcomes (success/failure, profit/loss, user ratings) for completed jobs
   - Implement reward calculation function that maps outcomes to numerical rewards
   - Build credit assignment mechanism: attribute reward to individual ThoughtNodes using eligibility traces
   - Create policy update routine: adjust reasoning parameters (weights, thresholds) based on accumulated rewards
   - Set up experience replay buffer to periodically retrain on historical episodes
   - Monitor improvement over time: track decision accuracy, confidence calibration, plan success rate

## Pitfalls

- **Graph complexity explosion**: Dynamic graph construction can generate overly complex reasoning paths with too many nodes. Implement depth/size limits and pruning strategies.
- **Memory retrieval noise**: Vector search may return irrelevant memories if embeddings are poorly tuned. Invest in embedding model selection and potentially fine-tune on domain-specific data.
- **Reward sparsity**: Financial outcomes may be delayed or ambiguous, making credit assignment difficult. Design intermediate reward signals for partial progress.
- **Learning instability**: Reinforcement learning can lead to oscillating policies. Use conservative update rules and sufficient replay buffer sizes.
- **Working memory capacity**: Limited working memory may cause important context to be evicted prematurely. Implement priority-based retention rather than pure LRU.
- **Planning horizon limits**: Hierarchical planning works best for medium-horizon tasks; very long-term planning may require different approaches. Plan for hybrid methods.
- **Exploration vs exploitation**: Reward-driven adaptation may converge to suboptimal local optima. Consider epsilon-greedy exploration or intrinsic motivation signals.
- **Debugging complexity**: Graph-based reasoning is harder to debug than linear chains. Invest heavily in visualization and traceability tools from the start.

## References

- Cognee Repository: https://github.com/topoteretes/cognee
- CognitiveArchitecture Concepts: https://en.wikipedia.org/wiki/Cognitive_architecture
- Chain-of-Thought Paper (Wei et al. 2022): https://arxiv.org/abs/2201.11903
- ReAct Paper (Yao et al. 2022): https://arxiv.org/abs/2210.03629
- Hierarchical Task Networks (HTN): https://en.wikipedia.org/wiki/Hierarchical_task_network
- Reinforcement Learning: An Introduction (Sutton & Barto): http://incompleteideas.net/book/the-book.html
- Vector Databases: https://github.com/awesome-vector-databases/awesome-vector-databases
- Weaviate: https://weaviate.io
- Chroma: https://www.trychroma.com
- Pydantic (for structured data): https://docs.pydantic.dev
