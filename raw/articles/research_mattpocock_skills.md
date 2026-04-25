# Research: mattpocock/skills — Teaching/Educational Skill Patterns

## Overview
The [`mattpocock/skills`](https://github.com/mattpocock/skills) repository is a curated collection of **skill‑pattern definitions** for teaching software engineering and other technical disciplines. It provides a systematic framework for:

* Breaking down complex domains into **composable skill units**.
* Sequencing those units via **prerequisite graphs**.
* Defining **progressive difficulty levels** within each skill.
* Establishing **assessment** and **validation** criteria.
* Creating **feedback loops** for continuous improvement.

The repo is the foundation for structured learning paths, career development ladders, and competency‑based education. Its patterns are directly applicable to agent training and skill management in systems like Hermes.

## Teaching Patterns

### 1. Skill Structure & Sequencing
- **Modular Skill Units**  
  Each skill is a standalone entity stored as a markdown (or YAML) file. The front‑matter captures metadata: `name`, `description`, `category`, `levels`, `prerequisites`, and tags.

- **Prerequisite Graph (DAG)**  
  Skills form a directed acyclic graph. Advanced skills list the IDs of prerequisite skills, enforcing that foundational knowledge is acquired first. This graph drives automatic sequencing and personalized learning paths.

- **Domain Grouping**  
  Skills are organized into top‑level directories (e.g., `frontend/`, `backend/`, `devops/`, `testing/`), making discovery intuitive and allowing domain‑specific proficiency tracking.

- **Granular Progression**  
  Early levels address broad concepts, while later levels drill into specifics. For example, a **Testing** skill might start with “Write a simple unit test” (level 1) and advance to “Design a comprehensive test strategy” (level 5).

### 2. Progressive Difficulty Curve Design
- **Level‑Based Mastery**  
  Each skill defines explicit, observable criteria for every level (often using “can‑do” statements). Learners must demonstrate competence at a level before progressing.

- **Incremental Complexity**  
  The curve is intentionally **shallow at first**, then steepens as integration of multiple skills occurs. This reduces cognitive overload while building confidence.

- **Skill Layering**  
  Basic skills (e.g., “Read code”, “Version control basics”) are prerequisites for many others, creating a layered architecture where mastery of fundamentals unlocks more complex domains.

- **Adaptive Specialisation**  
  After core requirements are met, learners can branch into specialisation tracks (e.g., Frontend vs. Backend), enabling personalised trajectories while maintaining a solid common foundation.

### 3. Assessment & Validation Patterns
- **Checklist Criteria**  
  Every level includes a binary checklist of behaviours or deliverables (e.g., “Can mock external services in tests”). This removes ambiguity and enables objective evaluation.

- **Project‑Based Validation**  
  Higher levels often require completing a small integrative project (e.g., “Build a CRUD app with tests and CI”). This demonstrates the ability to combine multiple skills.

- **Peer / Mentor Review**  
  Assessment is frequently performed by a mentor or peer who verifies the checklist and provides qualitative feedback, fostering a community of practice.

- **Automated Testing**  
  For technical skills, the repository links to automated test suites or coding challenges that can be run in CI pipelines, providing fast, objective validation.

### 4. Feedback Loops
- **Short‑Cycle Reviews**  
  Learners submit work frequently (e.g., weekly) for rapid feedback, preventing error accumulation and reinforcing habits.

- **Skill Retrospectives**  
  After completing a skill, learners reflect on what was easy/hard. These insights drive improvements to skill descriptions, resources, and difficulty curves.

- **Community‑Driven Evolution**  
  The repository is open‑source; users propose new skills, update criteria, and add resources. This creates a living curriculum that evolves with technology.

- **Metrics‑Guided Iteration**  
  Maintainers track which skills are commonly failed or take excessive time. Data‑driven tweaks to level thresholds or teaching material keep the curriculum effective.

## Hermes Application

### Could skill‑teaching patterns help structure our agent training or improve the skill interface?
Yes — the patterns map naturally onto **Hermes’ skill registry**:

- **Explicit Skill Definitions** – Replace loosely‑defined tools with well‑structured skills containing clear levels, prerequisites, and verification steps. This makes the agent’s capabilities self‑documenting and evolvable.
- **Incremental Learning** – Adopt a mastery model: agents train on simpler skills before unlocking more complex ones, reducing deployment failures.
- **Skill Graph Navigation** – Automatically select the next skill to acquire based on the agent’s goals and current proficiency, enabling autonomous curriculum learning.
- **Standardised Interface** – The skill‑pattern format (metadata + instructions + verification) becomes the canonical way to package capabilities, simplifying contribution, review, and versioning.

### Could skill sequencing improve plan templates?
Absolutely. Plan templates often assume a flat task list; skill sequencing introduces **dependency awareness**:

- **Skill‑Aware Task Assignment** – Generate plans that respect the agent’s current skill level, avoiding tasks that are too advanced.
- **Dynamic Sub‑Plan Insertion** – If a prerequisite skill is missing, the system inserts a “training sub‑plan” to acquire it first, ensuring a smooth learning curve.
- **Multi‑Agent Orchestration** – Match agents to tasks according to their skill graphs, maximising team efficiency and resilience.
- **Adaptive Difficulty** – Adjust task difficulty in real time based on the agent’s evolving proficiency, following the progressive curve principles.

## Concrete Suggestion

#### 1. Adopt the Skill‑Pattern Format
Extend Hermes’ skill registry to store skills as structured markdown/YAML using the `mattpocock/skills` schema (`name`, `description`, `category`, `levels`, `prerequisites`, `verification`, `resources`). This unifies documentation, machine readability, and human maintainability.

#### 2. Build a Skill Graph Engine
Implement a graph database (or use an existing one) that tracks:
- **Skill nodes** with attributes (`difficulty`, `domain`, `mastery_threshold`).
- **Edges** representing `prerequisite` relationships.
- **Agent nodes** with `proficiency` scores per skill.
Expose a query API: “What is the next recommended skill for agent X given goal Y?”.

#### 3. Progressive Skill Unlocking
When an agent attempts a skill it hasn’t mastered, require completion of a *validation task* (e.g., mini‑project, automated test, or simulation). Successful completion increases proficiency and unlocks downstream skills, mirroring mastery learning.

#### 4. Integrate into Plan Templates
Enhance the plan generator to:
- Check each step against the agent’s skill graph.
- Insert “skill‑acquisition” steps when prerequisites are missing.
- Vary task complexity dynamically based on current proficiency.
- Support branching specialisations after core competencies are achieved.

#### 5. Feedback Loop & Evolution
- Log outcomes of skill usage (success/failure, time, errors).  
- Periodically analyse logs to identify skills that are too easy/hard and refine level criteria.  
- Allow agents to propose skill improvements via a `skill_manage` action (create/patch), enabling continuous evolution of the skill library.

By embedding these educational patterns into Hermes, we transform the agent from a static tool‑user into a **lifelong learner**, capable of deliberate practice and systematic improvement — exactly what a well‑designed curriculum fosters in human engineers.
