---
name: docker-init
description: Set up Docker for a project. Generates Dockerfile, docker-compose.yml, docker-compose.prod.yml, and .dockerignore. Detects stack automatically.
---

# Docker Init

No arguments. Detects everything from project files.

## Step 1 — Check existing files

Look for Dockerfile, docker-compose.yml, docker-compose.prod.yml, .dockerignore.
If any exist, ask: "Docker files found. Overwrite or skip existing?"

## Step 2 — Detect stack and services

**Stack:** detect from project files (pyproject.toml, package.json, *.csproj).
Read actual version from config. If unclear, ask.

**Services:** always `app` + `db` (PostgreSQL). Scan dependencies for extras:

| Dependency | Add |
|-----------|-----|
| celery | celery-worker + redis |
| redis / ioredis | redis |
| elasticsearch | elasticsearch |
| rabbitmq / amqp | rabbitmq |

## Step 3 — Generate files

Follow ALL rules from docker-rules.md and active stack rules.
Read the dev command (uvicorn, runserver, npm run dev) from stack rules.

Generate:
1. **Dockerfile** — multi-stage, following docker-rules
2. **docker-compose.yml** — dev with volumes, reload, exposed ports
3. **docker-compose.prod.yml** — prod overrides (no volumes, no reload, restart policy, resource limits)
4. **.dockerignore** — stack-appropriate
5. **.env.example** — all vars from compose with defaults and comments

## Step 4 — Verify

Run `docker compose config` to validate.

```
DOCKER INITIALIZED
━━━━━━━━━━━━━━━━━━
Stack:    $STACK
Services: $SERVICES

Created:
  Dockerfile
  docker-compose.yml
  docker-compose.prod.yml
  .dockerignore
  .env.example

Try: docker compose up --build
```
