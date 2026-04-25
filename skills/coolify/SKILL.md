---
name: Coolify
description: Docker-based self-hosted PaaS for simplified deployment, multi-service orchestration, environment management, and observability of Hermes components
trigger: Need to streamline Hermes deployment, achieve service isolation, simplify operations, and provide user-friendly self-hosting experience
---

## Overview

Coolify (by coollabsio) is an open-source, Docker-based Platform-as-a-Service (PaaS) that serves as an alternative to Heroku, Vercel, or Netlify. It enables developers to deploy applications and services with minimal infrastructure management by orchestrating Docker containers on user-provided servers (VPS, bare metal, or cloud VMs).

Key characteristics:
- **Docker-native**: All deployments run as Docker containers; Coolify manages container lifecycle, networking, and storage
- **Unified control plane**: Web-based UI + API for managing servers (called "destinations"), applications, environments, and databases
- **Built-in reverse proxy**: Traefik provides automatic HTTPS (Let's Encrypt), routing, and load balancing
- **Multi-cloud/on-prem flexibility**: Connect any reachable Linux server via SSH as a destination and deploy across them
- **Database support**: One-click deployment of PostgreSQL, MySQL, Redis, etc. as attached services
- **Open-source**: Core is AGPL-licensed with optional paid cloud sync and enterprise features

Coolify abstracts Docker Compose details while still allowing direct compose file overrides. It excels at simplifying self-hosting and operational management without vendor lock-in.

## Multi-Service Orchestration Patterns

Coolify's orchestration model centers on **Application** containing multiple **Services** (Docker containers):

- **Single-service deployment**: One container per application (e.g., small API or static site). Good for micro-apps.
- **Multi-service (monolith/backend+frontend)**: Typical web app with frontend container, backend API container, database container. Services defined separately within one application, with internal Docker networking (service discovery via names) and per-service restart policies.
- **Microservices across destinations**: Services can be pinned to specific destinations (servers). Enables distributing services across machines for isolation or resource optimization (e.g., compute-intensive on high-CPU server, databases on high-memory server).
- **Dependency and health management**: Services declare dependencies (startup order) and health checks. Coolify waits for dependencies to be healthy before starting dependents, reducing race conditions.
- **Internal Traefik proxy**: Services exposing ports automatically get public URLs (with HTTPS) via Traefik routing rules defined in UI (subdomains, path-based routing).
- **Environment-specific scaling**: Each service can be scaled to multiple replicas for load distribution, with Traefik distributing traffic.

Under the hood, Coolify generates and manages Docker Compose files per application but abstracts this unless fine control is needed.

## Environment/Secret Management

Coolify provides flexible, secure configuration management:
- **Scope hierarchy**: Variables at global (all servers), project (group of apps), or service level. Inheritance flows downward (service can override project/global).
- **Secret masking**: Variables marked "secret" are encrypted in PostgreSQL DB and masked in logs/UI. Injected as environment variables at runtime.
- **Docker secrets integration**: Can use Docker's native secrets mechanism, storing them in `/run/secrets/` inside containers.
- **`.env` file support**: Upload `.env` file during app creation; gets parsed and stored accordingly.
- **Database credentials**: Attached Coolify-managed databases automatically inject credentials as environment variables into connected services.
- **Runtime updates**: Changing a variable triggers rolling restart of affected services, enabling config changes without downtime (with multiple replicas).
- **API-driven**: Environment variables managed via API, enabling CI/CD integration.

This layered approach allows Hermes to store provider API keys as service-level secrets, keeping them encrypted at rest and invisible in logs.

## One-Click Deploy Model

Coolify's "one-click deploy" uses Deploy Buttons:
- **Deploy button generation**: For any application, generate custom URL/button that opens a pre-filled deployment wizard. Embeddable in GitHub READMEs.
- **Pre-configured parameters**: Button can preset environment variables, resource limits, destination selection, repository URL or Docker image.
- **User flow**: Users click button, review/adjust settings, click "Deploy". Coolify clones repo (if source-based), builds if needed (Dockerfile support), starts services.
- **Template repositories**: Projects can be packaged as "templates" — pre-configured Docker Compose setups others can deploy instantly.
- **API automation**: Coolify's API can trigger the same flow programmatically (from CI/CD), enabling automated rollouts.

For Hermes, this means providing a Deploy Button for a pre-configured instance with correct service definitions, Traefik routing, and placeholder secrets that users can instantiate in minutes.

## Monitoring/Logging Integration

Coolify offers built-in operational insights and external observability integration:
- **Real-time metrics**: Per-service CPU, memory, network I/O, disk usage displayed in UI with historical graphs.
- **Container logs**: All stdout/stderr captured and viewable per service, with filtering and search. Logs persist across container restarts (depending on log driver).
- **Health checks**: Services define HTTP/TCP health endpoints; Coolify monitors and auto-restarts unhealthy containers.
- **Event notifications**: Configurable webhooks for deployment lifecycle events (start, stop, success, failure) — can integrate with Discord, Slack, email.
- **External integrations**:
  - Prometheus metrics endpoint: Coolify exposes metrics scrapable by external Prometheus for custom Grafana dashboards
  - Loki/Elasticsearch: Docker logging drivers can forward logs to external systems
  - Uptime monitoring: Premium integrations or via API hook into external monitoring services
- **Server health**: Coolify server provides host-level metrics (CPU/memory/disk).

While not a full APM, Coolify provides sufficient visibility for small-medium deployments. Advanced tracing requires OpenTelemetry sidecars or application instrumentation.

## Hermes Self-Host Recommendation

**Recommendation: Yes — with a phased approach.**

Running each Hermes provider adapter as separate Coolify services would meaningfully improve isolation and reliability:
- **Isolation**: A crash or memory leak in one adapter won't affect core or other adapters; Coolify restarts only the faulty service
- **Resource allocation**: Each adapter can be assigned tailored CPU/memory limits (heavy adapters like Anthropic get more resources)
- **Independent updates**: Adapters updated/restarted individually without whole-agent downtime
- **Security**: Secrets scoped per service reduce blast radius if single container compromised
- **Simplified self-hosting**: One-click deployments reduce setup friction; built-in HTTPS exposes Hermes API if needed; UI-driven management accessible to non-devops; centralized logging/metrics speed debugging

**Caveats**:
- **Added complexity**: Coolify server itself consumes resources (~1-2 GB RAM + database)
- **Learning curve**: Team must learn Coolify concepts (destinations, applications, services)
- **State management**: Hermes adapters may need shared state or persistent storage; careful volume design required

Given Hermes's modular architecture (provider adapters as independent modules), isolation benefits align naturally with Coolify's service abstraction. Overhead justified in production, multi-tenant, or scaled scenarios.

## Integration Steps

### Phase 1: Containerization (Week 1-2)
1. **Create Dockerfiles**:
   - Core Hermes agent (job queue, decision engine)
   - Separate Dockerfiles for each provider adapter (OpenAI, Anthropic, Solana, etc.) OR single monolith with env flags (prefer separate for isolation)
   - Build and push images to registry (Docker Hub, GHCR, or private)

2. **Define `docker-compose.yml`**:
   ```yaml
   services:
     core:
       image: yourorg/hermes-core:latest
       depends_on:
         openai-adapter:
           condition: service_healthy
       environment:
         - OPENAI_API_KEY=***
       secrets:
         - openai_key_secret
     openai-adapter:
       image: yourorg/hermes-openai:latest
       healthcheck:
         test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
       environment:
         - OPENAI_API_KEY=***
       secrets:
         - openai_key_secret
   secrets:
     openai_key_secret:
       external: true
   ```

### Phase 2: Coolify Setup (Week 3)
3. **Provision server**: Linux VPS (DigitalOcean, AWS EC2, bare metal)
4. **Install Coolify**: `curl -fsSL https://get.coolify.io | bash`
5. **Configure destination**: Access dashboard, add server as destination

### Phase 3: Application Deployment (Week 4)
6. **Create Hermes application**: 
   - New Application → "Docker Compose" method pointing to GitHub repo, or "Custom Docker" with manual service definition
   - Assign to destination (server)
   - Coolify parses compose and creates each service

7. **Handle secrets**:
   - Secrets → create secrets for each provider API key (`OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, etc.)
   - Bind secrets to appropriate services as environment variables or Docker secrets
   - Remove hardcoded secrets from compose file

8. **Configure networking & persistence**:
   - Attach persistent Docker volumes to services needing state (SQLite DB, vector store)
   - Configure Traefik routing if Hermes API should be public (set domain/subdomain, enable HTTPS)

### Phase 4: Testing & Scaling (Week 5+)
9. **Test**:
   - Deploy and monitor logs via Coolify UI
   - Verify adapters register with core and handle jobs
   - Test failure scenarios: stop adapter container to confirm core remains stable and adapter auto-restarts
   - Adjust resource limits and health checks based on observed usage

10. **Automate updates**:
    - Set up GitHub integration so pushes trigger automatic redeploys
    - Use Coolify deployment history for rollbacks

11. **Scale out** (optional):
    - Add additional destinations (servers); pin specific adapters/core to different machines
    - Use Coolify scaling to run multiple replicas of stateless adapters

**Deliverable**: Once stable, Hermes self-hosting documentation points to a one-click Deploy Button that automates steps 6-8, providing frictionless installation.

## Pitfalls

- **Resource overhead**: Coolify server (+ database) consumes 1-2 GB RAM and CPU. Account for this in server sizing.
- **State sharing complexity**: Adapters needing shared state (e.g., same SQLite DB) must mount shared volumes with careful concurrency handling. Prefer external databases (PostgreSQL) over file-based storage.
- **Service discovery**: Internal Docker networking uses service names as hostnames. Ensure application code uses correct hostnames (e.g., `postgres` not `localhost`).
- **Secret rotation complexity**: Updating a secret requires coordinated service restart across dependent services. Use versioned secrets where possible.
- **Health check misconfiguration**: Missing or incorrect health checks cause premature container restarts or cascading failures. Verify health endpoints return correct status.
- **Traefik routing conflicts**: Path-based routing can interfere with service-specific routing. Plan routing rules carefully and test thoroughly.
- **Database migration handling**: When service code changes require schema migrations, implement migration steps in deployment hooks or separate migration service.
- **Vendor lock-in concerns**: While Docker Compose is portable, Coolify-specific configurations (health checks, secrets, etc.) may require manual extraction if migrating off Coolify. Keep core deployment definition Docker Compose-first.

## References

- Coolify: https://coolify.io
- Coolify Documentation: https://docs.coollabs.io
- Docker Compose: https://docs.docker.com/compose/
- Traefik: https://traefik.io
- Let's Encrypt: https://letsencrypt.org
- Docker Secrets: https://docs.docker.com/engine/swarm/secrets/
- Prometheus: https://prometheus.io
- Grafana Loki: https://grafana.com/oss/loki/
