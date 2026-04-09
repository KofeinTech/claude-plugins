---
name: docs
description: Generate or update project documentation -- README, API docs, architecture, deployment guide, env variables, and database schema.
---

# Project Documentation Generator

Type is provided as $ARGUMENTS. If empty, default to "all".

All documentation in English.

## Step 1 — Detect what exists

Scan the project for existing documentation:
```
docs/
README.md
ARCHITECTURE.md
DEPLOYMENT.md
API.md or openapi.yaml or swagger.json
.env.example
docker-compose.yml
```

Report what was found:
```
EXISTING DOCS
━━━━━━━━━━━━━
README.md (last modified: date)
docker-compose.yml
No API documentation
No architecture document
No deployment guide
No .env.example

Generate missing docs? (all / pick specific)
```

If docs already exist, UPDATE them — do not overwrite.
Add new sections, update outdated info, preserve custom content.

## Step 2 — Read the codebase

Based on requested doc type, read relevant parts:

**For README:** package.json/pubspec.yaml/requirements.txt, docker-compose.yml,
project CLAUDE.md, directory structure.

**For API docs:** scan route files, controllers, endpoints. Look for:
- FastAPI: files with `@app.get/post/put/delete` or `APIRouter`
- .NET: Controllers, `[HttpGet]`/`[HttpPost]` attributes
- Next.js: `app/api/` routes
- Flutter: not applicable (client-side)

**For Architecture:** project structure, main modules, dependencies between them,
external services, database connections, state management.

**For Deploy:** docker-compose.yml, Dockerfile(s), CI/CD config (.github/workflows/),
environment-specific configs.

**For Env:** all references to `process.env`, `os.environ`, `Environment`,
`dotenv`, `--env-file`. Cross-reference with docker-compose.yml.

**For Schema:** ORM models (EF Core entities, SQLAlchemy/Alembic models,
Prisma schema), migration files.

## Document types

### README.md

```markdown
# Project Name

Brief description from CLAUDE.md or package metadata.

## Tech Stack

- Language / Framework
- Database
- Key libraries

## Prerequisites

- Docker & Docker Compose
- (stack-specific: Node.js, Flutter SDK, .NET SDK, Python)

## Getting Started

# Clone the repo
git clone <repo-url>
cd <project>

# Start with Docker Compose
docker-compose up --build

# App is running at http://localhost:XXXX

## Project Structure

src/
  module-a/     — description
  module-b/     — description
  ...

## Available Commands

Command                              | Description
-------------------------------------|------------------
docker-compose up                    | Start the app
docker-compose exec app <test-cmd>   | Run tests
docker-compose exec app <lint-cmd>   | Run linter
docker-compose build                 | Rebuild containers

## Environment Variables

See `.env.example` for all required variables.

## Documentation

- [API Documentation](docs/API.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Deployment Guide](docs/DEPLOYMENT.md)
```

Read actual commands from CLAUDE.md. Don't guess.

### API Documentation (docs/API.md + openapi.yaml)

Scan all API endpoints and generate:

**docs/API.md** — human-readable:
```markdown
# API Documentation

Base URL: `http://localhost:XXXX/api`

## Authentication

How auth works (JWT, API key, session, etc.)

## Endpoints

### Users

#### GET /api/users
Description of what it does.

**Query Parameters:**
| Parameter | Type   | Required | Description       |
|-----------|--------|----------|-------------------|
| page      | int    | no       | Page number       |
| limit     | int    | no       | Items per page    |

**Response 200:**
{json example from actual code/types}

#### POST /api/users
...
```

**openapi.yaml** — if the project already has one, update it.
If not, generate from discovered endpoints.
For FastAPI projects, check if `/docs` or `/openapi.json` auto-generation
is already configured — if yes, note it instead of duplicating.

### Architecture (docs/ARCHITECTURE.md)

```markdown
# Architecture

## Overview

Brief description of the system, what it does, main components.

## System Diagram

(describe the components and how they connect — Claude cannot draw,
but can provide a mermaid diagram or textual description)

## Components

### Component A
- Purpose: what it does
- Location: src/module-a/
- Dependencies: Component B, External Service X
- Key files: service.py, models.py, routes.py

### Component B
...

## Data Flow

How data moves through the system:
1. Client sends request to API
2. API validates with middleware
3. Service layer processes business logic
4. Repository layer accesses database
5. Response returned

## External Services

| Service      | Purpose            | Config              |
|-------------|-------------------|----------------------|
| PostgreSQL  | Primary database  | DATABASE_URL         |
| Redis       | Caching / queues  | REDIS_URL            |
| S3          | File storage      | AWS_* vars           |

## Key Decisions

| Decision             | Choice      | Reason                        |
|---------------------|-------------|-------------------------------|
| State management    | Riverpod    | Testability, code generation  |
| API architecture    | REST        | Client requirement            |
| Database            | PostgreSQL  | Relational data, ACID         |
```

Read actual code structure, don't template generic architecture.

### Deployment Guide (docs/DEPLOYMENT.md)

```markdown
# Deployment Guide

## Environments

| Environment | URL                    | Branch  |
|-------------|------------------------|---------|
| Development | http://localhost:XXXX  | develop |
| Staging     | https://staging.xxx    | staging |
| Production  | https://xxx            | main    |

## Docker Setup

Full docker-compose.yml explanation:
- What each service does
- Volumes and their purpose
- Networks
- Port mappings

## CI/CD Pipeline

Describe what GitHub Actions workflows do:
- On PR: what checks run
- On merge to develop: what happens
- On merge to main: what happens

## Manual Deployment

Step-by-step if manual deploy is needed.

## Rollback

How to rollback a deployment.
```

Read from docker-compose.yml and .github/workflows/.

### Environment Variables (.env.example)

Generate from all env var references found in code:

```env
# Database
DATABASE_URL=postgresql://user:password@localhost:5432/dbname

# Redis
REDIS_URL=redis://localhost:6379

# Auth
JWT_SECRET=your-secret-here
JWT_EXPIRATION=3600

# External Services
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
S3_BUCKET_NAME=

# App
PORT=3000
NODE_ENV=development
```

Every variable must have a comment explaining what it's for.
Use placeholder values, never real secrets.

### Database Schema (docs/SCHEMA.md)

```markdown
# Database Schema

## Tables

### users
| Column     | Type         | Constraints          |
|-----------|--------------|----------------------|
| id        | UUID         | PK, auto-generated   |
| email     | VARCHAR(255) | UNIQUE, NOT NULL     |
| name      | VARCHAR(100) | NOT NULL             |
| created_at| TIMESTAMP    | DEFAULT now()        |

### posts
...

## Relationships

- users 1:N posts (user_id FK)
- posts 1:N comments (post_id FK)
- users N:N roles (through user_roles)

## Migrations

How to run migrations:
docker-compose exec app <migration-command>
```

Read from ORM models, not from raw SQL.

## Step 3 — Generate and save

Create files in `docs/` directory (except README.md which goes to root).
If files exist, show diff of what will change and ask before overwriting.

```
DOCS GENERATED
━━━━━━━━━━━━━━
Created:
  README.md (updated)
  docs/API.md (new)
  docs/ARCHITECTURE.md (new)
  docs/DEPLOYMENT.md (new)
  .env.example (new)

Skipped:
  docs/SCHEMA.md — no database found in project
```

## Rules

- NEVER guess endpoints, env vars, or architecture. Read the code.
- NEVER overwrite existing docs without showing diff first.
- NEVER include real secrets or credentials in .env.example.
- Read commands from CLAUDE.md — don't hardcode docker-compose commands.
- Read the active stack rules (flutter-rules, react-rules, python-rules,
  dotnet-rules) for platform-specific documentation patterns, conventions,
  and which doc types are relevant for this stack.
- If a doc type doesn't apply to the current platform, skip it and explain why.
- For projects with auto-generated API docs (FastAPI /docs, .NET Swagger),
  don't duplicate — reference the existing auto-generated docs instead.
