---
name: onboard
description: Generate a project briefing for a new team member (developer or PM). Reads Jira project info, analyzes codebase, shows current work in flight.
---

# Onboard

Project key is provided as $ARGUMENTS. If no argument given, detect from
current repo's CLAUDE.md or branch name. If unclear, ask.

## Step 1 — Determine audience

Ask: "Are you a developer or PM on this project?"

This changes what to emphasize:
- **Developer** — architecture, codebase, commands, where things are
- **PM** — team, active Epics, client, deadlines, process

## Step 2 — Read project-level info

**From Jira** — via Jira MCP, read the project description for $PROJECT.
Extract operational info: repos, client, contacts, links, deadlines, team.

**From Wiki** — via GitHub MCP or `gh` CLI, read from `KofeinTech/wiki`
in the `$PROJECT/` folder. This contains permanent knowledge:
architecture decisions, setup guides, API contracts, how things work.

```bash
gh api repos/KofeinTech/wiki/contents/$PROJECT --jq '.[].name'
```

Read relevant files (README.md, architecture.md, setup.md, etc.).

If Jira description or wiki is empty, note what's missing.
Suggest the PM or lead fills in the Jira project description and/or wiki.

## Step 3 — Read current repo (developers only)

Skip this step for PMs.

**Read CLAUDE.md** for project-specific conventions, commands, base branch.

**Analyze codebase structure:**
- Run `ls` on root and key directories to understand the layout
- Detect the tech stack from project files (pubspec.yaml, *.csproj, package.json, etc.)
- Identify architecture pattern (feature-based, clean architecture, etc.)
- Find key files: router/routes, API client, theme/design tokens, main entry point,
  dependency injection / service registration, database config

**Map the codebase** — identify and describe:
- Where features/modules live
- Where shared/core code lives
- Where data layer lives (models, repos, API clients)
- Where tests live
- Where config/environment files live

## Step 4 — Read current state from Jira

Via Jira MCP:

**Active Epics** (what's in flight right now):
- Epic name + short status (count of Tasks Done / Total)
- Which Epic is the "current" focus (the one with Tasks in In Progress)

**Current work:**
- Tickets in In Progress grouped by assignee
- Top items in To Do (what will be pulled next)

**Team:**
- Who's working on what (In Progress tickets grouped by assignee)

**Blockers:**
- Any blocked or stale tickets

## Step 5 — Check for existing ONBOARDING.md

If `ONBOARDING.md` exists in the repo root:
- Read it
- Compare with current data
- If stale (team changed, active Epics changed, architecture evolved),
  note what's outdated and update it
- If still accurate, show it to the developer with current work state appended

If it doesn't exist, generate a new one.

## Step 6 — Generate briefing

### For developers:

```markdown
# Project Briefing: $PROJECT_NAME

## Project Overview
Client: $CLIENT
Repos:
- $REPO_1 ($STACK) — $PURPOSE
- $REPO_2 ($STACK) — $PURPOSE

Key links:
- API docs: $URL
- Staging: $URL
- Logs: $LOCATION
- CI/CD: $TOOL

## This Repository ($CURRENT_REPO)

**Stack:** $STACK_DETAILS
**Architecture:** $PATTERN

### Directory Map
```
$DIRECTORY_STRUCTURE_WITH_DESCRIPTIONS
```

### Key Files
- `$PATH` — $DESCRIPTION (routing, API client, theme, etc.)

### Commands
- Run: `$COMMAND`
- Test: `$COMMAND`
- Build: `$COMMAND`
- Lint: `$COMMAND`

### Conventions
- $KEY_CONVENTIONS (from CLAUDE.md and rules)

## Current Work

Active Epic(s):
- $EPIC_KEY $EPIC_NAME ($DONE_TASKS/$TOTAL_TASKS tasks done)
- $EPIC_KEY $EPIC_NAME ($DONE_TASKS/$TOTAL_TASKS tasks done)

In Progress:
- $KEY $TITLE → @$ASSIGNEE

Next up (top of To Do):
- $KEY $TITLE

Blockers:
- $BLOCKER_OR_NONE

## Team
$TEAM_MEMBERS_AND_CURRENT_WORK

## Tips
- $USEFUL_THINGS_DISCOVERED (populated over time)
```

### For PMs:

Same structure but skip the "This Repository" section (architecture, key files,
commands, conventions). Emphasize team, active Epics, client info, deadlines.

## Step 7 — Save and present

Save the briefing as `ONBOARDING.md` in the repo root.

Tell the developer:
```
ONBOARDING COMPLETE
━━━━━━━━━━━━━━━━━━
Project:  $PROJECT_NAME
Stack:    $STACK
Active:   $CURRENT_EPIC_NAME ($DONE/$TOTAL tasks done)
Team:     $N members active

Saved: ONBOARDING.md (update it when you discover useful info)

Tip: Use the PM subagent (@pm) for ongoing questions about
active Epics, tickets, blockers, and team.
```

## Rules

- NEVER include secrets, passwords, API keys, or tokens in the briefing.
- NEVER guess about architecture. Read the actual code structure.
- If Jira project description is empty, still generate what you can from
  the codebase and current work data. Note what's missing so it can be filled in.
- If ONBOARDING.md already exists, update it — don't overwrite tips or
  notes that developers added manually.
- Keep the briefing scannable — developers should get value in 5 minutes.
- For multi-repo projects, focus the codebase analysis on the CURRENT repo
  but include cross-repo links and info from Jira project description.
