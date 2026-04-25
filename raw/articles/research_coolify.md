# Coolify Research for Hermes

## Coolify Overview

**Coolify** (by coollabsio) is a self-hosted, Docker-based Platform-as-a-Service (PaaS) that positions itself as an open-source alternative to services like Heroku, Vercel, and Netlify. It enables developers to deploy applications, static sites, and services with minimal infrastructure management by orchestrating Docker containers on user-provided servers (VPS, bare metal, or cloud VM). Key characteristics:

- **Docker-native**: All deployments run as Docker containers; Coolify manages container lifecycle, networking, and storage.
- **Unified control plane**: Web-based UI + API for managing servers (called "destinations"), applications, environments, and databases.
- **Built-in reverse proxy**: Traefik provides automatic HTTPS (Let's Encrypt), routing, and load balancing.
- **Multi-cloud/on-prem flexibility**: Connect any reachable Linux server (via SSH) as a "destination" and deploy across them.
- **Database support**: One-click deployment and management of various databases (PostgreSQL, MySQL, Redis, etc.) as attached services.
- **Open-source**: The core is open-source (AGPL), with optional paid cloud synchronization and enterprise features.

Coolify abstracts away Docker compose details while still allowing direct compose file overrides for advanced users. It is particularly well-suited for teams wanting PaaS-like simplicity without vendor lock-in.

## Multi-Service Orchestration Patterns

Coolify's orchestration model revolves around the concept of an **Application** which can consist of multiple **Services** (Docker containers). Key patterns:

- **Single-service deployment**: The simplest case – one container per application (e.g., a small API or static site). Good for micro-apps.
- **Multi-service (monolith/backend+frontend)**: A typical web app might have a frontend container (React/Next.js), a backend API container (Node/Python), and a database container. Coolify lets you define these as separate services within one application, with internal Docker networking (service discovery via container names) and restart policies defined per service.
- **Microservices across destinations**: Services can be pinned to specific "destinations" (servers). This enables distributing services across multiple machines for isolation or resource optimization. For example, compute-intensive services on a high-CPU server, databases on a high-memory server.
- **Dependency and health management**: Services can declare dependencies (startup order) and health checks. Coolify waits for dependent services to be healthy before starting dependents, reducing race conditions.
- **Internal Traefik proxy**: Services that expose ports can automatically get public URLs (with HTTPS) via Traefik routing rules defined in the UI (e.g., subdomains, path-based routing). This simplifies exposing multiple services behind one IP.
- **Environment-specific scaling**: Each service can be scaled to multiple replicas (container instances) for load distribution, with Traefik distributing traffic.

Under the hood, Coolify generates and manages Docker Compose files per application, but it abstracts this from the user unless they need fine control.

## Environment/Secret Management

Coolify provides a flexible, secure system for managing configuration:

- **Scope hierarchy**: Variables can be set at global (all servers), project (group of apps), or service level. Inheritance flows downward (service can override project/global).
- **Secret masking**: Variables marked as "secret" are encrypted in Coolify's PostgreSQL database and masked in logs/UI (shown as `****`). They are injected as environment variables at runtime.
- **Docker secrets integration**: Coolify can also use Docker's native secrets mechanism for sensitive data, storing them in `/run/secrets/` inside containers.
- **`.env` file support**: Users can upload an `.env` file during app creation, which gets parsed and stored accordingly.
- **Database credentials**: When attaching a Coolify-managed database, credentials are automatically injected as environment variables into connected services.
- **Runtime updates**: Changing a variable triggers a rolling restart of affected services, enabling config changes without downtime (if multiple replicas).
- **API-driven**: Environment variables can be managed via API, allowing CI/CD integration.

This layered approach allows Hermes to store provider API keys (OpenAI, Anthropic, etc.) as service-level secrets, keeping them encrypted at rest and invisible in logs.

## One-Click Deploy Model

Coolify's "one-click deploy" is realized via **Deploy Buttons**:

- **Deploy button generation**: For any application in Coolify, you can generate a custom URL/button that, when clicked, opens a pre-filled deployment wizard. The button can be embedded in GitHub READMEs.
- **Pre-configured parameters**: The button can preset environment variables, resource limits (CPU/memory), destination selection, and even the repository URL or Docker image to use.
- **User flow**: End users (or team members) click the button, review/adjust settings, and click "Deploy". Coolify then clones the repo (if source-based), builds if needed (Dockerfile support), and starts the services.
- **Template repositories**: Projects can be packaged as "templates" – pre-configured Docker Compose setups that others can deploy instantly.
- **API automation**: For headless deployments, Coolify's API can trigger the same flow programmatically (e.g., from a CI/CD pipeline), enabling automated rollouts.

For Hermes, this means you could provide a Deploy Button for a pre-configured Hermes instance (with correct service definitions, Traefik routing, and placeholder secrets) that users can instantiate in minutes.

## Monitoring/Logging Integration

Coolify offers built-in operational insights and integrates with external observability stacks:

- **Real-time metrics**: Per-service CPU, memory, network I/O, and disk usage are displayed in the UI. Historical graphs are available (configurable retention).
- **Container logs**: All stdout/stderr from containers are captured and viewable per service, with filtering and search. Logs persist even after container restarts (depending on log driver).
- **Health checks**: Services can define HTTP/TCP health endpoints; Coolify monitors and auto-restarts unhealthy containers.
- **Event notifications**: Configurable webhook notifications for deployment lifecycle events (start, stop, success, failure) – can integrate with Discord, Slack, email, etc.
- **External integrations**:
  - **Prometheus metrics endpoint**: Coolify exposes metrics that can be scraped by an external Prometheus server, enabling custom Grafana dashboards.
  - **Loki/Elasticsearch**: Docker logging drivers can be configured to forward logs to external systems (if the host's Docker daemon is configured accordingly; Coolify does not enforce but allows configuration).
  - **Uptime monitoring**: Premium integrations (or via API) allow hooking into external monitoring services.
- **Server health**: The Coolify server itself provides system-level metrics (host CPU/memory/disk) to ensure the host is healthy.

While not a full-blown APM, Coolify provides sufficient operational visibility for small-to-medium deployments. For advanced tracing, you would add OpenTelemetry sidecars or instrument application code.

## Hermes Self-Host Recommendation

**Recommendation: Yes – with a phased approach.**

Running each Hermes provider adapter as a separate Coolify service would meaningfully improve isolation and reliability:

- **Isolation**: A crash or memory leak in one adapter (e.g., a third-party API timeout) won't affect the core agent or other adapters; Coolify restarts only the faulty service.
- **Resource allocation**: Each adapter can be assigned tailored CPU/memory limits. Heavy adapters (e.g., Anthropic with large contexts) can get more resources.
- **Independent updates**: Adapters can be updated/restarted individually without downtime for the whole agent.
- **Security**: Secrets for each provider are scoped to that service, reducing blast radius if a single container is compromised.

Coolify also simplifies self-hosting:
- One-click deployments reduce setup friction for new users.
- Built-in HTTPS (via Traefik) exposes the Hermes API securely if needed.
- UI-driven management eliminates manual Docker commands, making operations accessible to non-devops users.
- Centralized logging and metrics speed up debugging.

**Caveats**:
- **Added complexity**: For a single-machine deployment, Coolify introduces an extra control plane (the Coolify server itself) which consumes resources (~1–2 GB RAM, + database).
- **Learning curve**: Team members must learn Coolify concepts (destinations, applications, services).
- **State management**: Hermes adapters may need to share state or persistent storage; careful volume design required.

Given Hermes's modular architecture (provider adapters as independent modules), the isolation benefits align naturally with Coolify's service abstraction. The overhead is justified when running production Hermes instances, especially in multi-tenant or scaled scenarios.

## Migration Sketch

If proceeding, here is a stepwise migration plan:

1. **Containerize Hermes components**
   - Create a Dockerfile for the core Hermes agent (handling job queue, decision engine).
   - Create separate Dockerfiles for each provider adapter (OpenAI, Anthropic, Solana, etc.) *or* a single monolith container with environment flags. For isolation, prefer separate images.
   - Build and push images to a registry (Docker Hub, GitHub Container Registry, or private registry).

2. **Define a docker-compose.yml**
   - Write a compose file that defines:
     - `hermes-core` service
     - `adapter-openai`, `adapter-anthropic`, `adapter-solana`, … services
     - Shared network (bridge) and volumes for persistent data (e.g., SQLite DB, memory caches).
     - Dependencies: core may depend on adapters being healthy if registration mechanism requires it.
   - Example snippet:
     ```yaml
     services:
       core:
         image: yourorg/hermes-core:latest
         depends_on:
           openai-adapter:
             condition: service_healthy
         environment:
           - OPENAI_API_KEY=${OPENAI_API_KEY}
         secrets:
           - openai_key_secret
       openai-adapter:
         image: yourorg/hermes-openai:latest
         healthcheck:
           test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
         environment:
           - OPENAI_API_KEY=${OPENAI_API_KEY}
         secrets:
           - openai_key_secret
     secrets:
       openai_key_secret:
         external: true
     ```

3. **Set up a Coolify server**
   - Provision a Linux VPS (e.g., DigitalOcean, AWS EC2, or bare metal).
   - Install Coolify using their bootstrap script (`curl -fsSL https://get.coolify.io | bash`).
   - Access the Coolify dashboard; configure the server as a "destination".

4. **Create the Hermes application in Coolify**
   - Choose "Application" → "New Application".
   - Use the "Docker Compose" method and point to your GitHub repo containing the compose file, or select "Custom Docker" and manually define each service.
   - Assign the application to the destination (server).
   - Coolify will parse the compose and create each service.

5. **Handle secrets**
   - In Coolify UI, go to "Secrets" → create secrets for each provider API key (e.g., `OPENAI_API_KEY`, `ANTHROPIC_API_KEY`).
   - Bind those secrets to the appropriate services as environment variables or Docker secrets.
   - Remove any hardcoded secrets from the compose file.

6. **Configure networking and persistence**
   - Attach persistent Docker volumes to services that need state (e.g., SQLite DB, vector store). Create volumes in Coolify UI and mount them in containers.
   - Configure Traefik routing if the Hermes API should be publicly accessible (set domain/subdomain, enable HTTPS).

7. **Test and iterate**
   - Deploy and monitor logs for each service via Coolify UI.
   - Verify that adapters register with core and can handle jobs.
   - Test failure scenarios: stop an adapter container to confirm core remains stable and adapter auto-restarts.
   - Adjust resource limits and health checks based on observed usage.

8. **Automate updates**
   - Optionally set up GitHub integration so pushes to the Hermes repo trigger automatic redeploys.
   - Use Coolify's "Deployments" history for rollbacks if needed.

9. **Scale out (optional)**
   - Add additional destinations (servers) and pin specific adapters or core to different machines for load distribution.
   - Use Coolify's scaling to run multiple replicas of stateless adapters.

**Deliverable**: Once stable, the Hermes self-hosting documentation can point users to a one-click Deploy Button that automates steps 4–6, providing a frictionless installation experience.
