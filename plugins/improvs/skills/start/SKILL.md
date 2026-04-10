---
name: start
description: Begin working on a Jira task. Reads ticket, evaluates complexity, creates branch, updates Jira, records start time. Handles trivial to complex tasks with appropriate workflow.
---

# Start Task

## Jira status workflow

All Improvs projects use these statuses in order:
**To Do** → **In Progress** → **In Review** → **Done**

Additional statuses: **Blocked** (can be set from any active status).
This skill transitions tickets to **In Progress**.

---

Ticket key is provided as $ARGUMENTS. If no argument given, ask the developer
for the Jira ticket key.

**First-time check:** If `ONBOARDING.md` does not exist in the repo root,
suggest: "Looks like your first time on this project. Run /onboard $PROJECT
first for a full briefing?" Continue if they decline.

## Step 1 — Read the Jira ticket

Use Jira MCP to read the ticket. Extract and display to the developer:

```
TICKET: $KEY
Title: ...
Priority: ...
Type: ... (bug / feature / task / etc.)

Description:
...

Acceptance Criteria:
- ...
- ...

Linked tickets: ... (if any)
```

If the ticket has no Acceptance Criteria (AC), STOP and tell the developer:
"This ticket has no AC. Please add acceptance criteria before starting work,
or tell me the AC now and I will add it to the Jira ticket."

Do NOT proceed without clear acceptance criteria.

## Step 2 — Bug investigation (only if ticket type is Bug)

If the Jira ticket type from Step 1 is `Bug`:

1. Search the codebase for keywords from the bug description, error messages,
   or affected feature area.
2. Read the most likely 1–3 source files.
3. If there is a stack trace, follow it to the source.
4. Print this exact block before proceeding:

   ```
   INVESTIGATION: $KEY
   Likely root cause: $FILE_PATH (~line $LINE)
   Reason: $ONE_SENTENCE_EXPLANATION
   Confidence: High / Medium / Low
   ```

If you cannot identify a likely root cause from code alone, print confidence
Low and ask the developer for help locating it before classifying complexity.

For non-Bug ticket types (Task, Epic, etc.), skip this step entirely
and proceed to Step 3.

## Step 3 — Detect hotfix (production emergency)

Check if this is a production emergency:
- Jira priority is **Critical** or **Blocker**, OR
- Jira labels include `hotfix`, OR
- Ticket title/description contains "production", "prod down", "prod broken", "urgent fix"

**If hotfix detected:**

Set `$IS_HOTFIX = true`. Override the base branch to `main` (regardless of
what CLAUDE.md says). Display:

```
HOTFIX DETECTED
━━━━━━━━━━━━━━
Ticket:  $KEY — $TITLE
Priority: $PRIORITY
Reason:  $WHY_HOTFIX (e.g. "Priority: Critical" or "Label: hotfix")

Branching from main for emergency fix.
```

Skip complexity evaluation — hotfixes are always treated as **simple** (TDD mode).
Proceed to Step 4 (skip UI check for hotfixes), then Step 5 with `main` as base.

The `/finish` skill reads `$IS_HOTFIX` from the Jira comment and creates **two PRs**:
one targeting `main` (the urgent fix) and one targeting `develop` (sync).

**If not a hotfix:** proceed to Step 4 normally.

## Step 4 — Evaluate task complexity (skip if hotfix)

Analyze the ticket and classify by objective complexity signs.
Do NOT estimate hours — you have no sense of time. Count tangible things instead.

**Trivial task** — ALL of the following are true:
- 1 file to modify
- Change is purely cosmetic, textual, or config (no logic change)
- 1 acceptance criterion
- No new functions, methods, or classes
- No behavior change that could break anything

Examples: fix typo in UI, change color/size/spacing, update text/label,
change config value, rename variable, add/remove a flag, make API values
lowercase, adjust padding. If in doubt — it's NOT trivial, classify as Simple.

**Simple task** — ALL of the following are true:
- 1–2 files to create or modify
- Single layer (only UI, or only API, or only business logic)
- 1–3 acceptance criteria
- No new navigation/routing
- No new state management
- No external service integration

Examples: bugfix, add field to form, new simple endpoint, style fix,
add validation, rename/move, simple CRUD.

**Complex task** — ANY of the following is true:
- 3+ files to create or modify
- Multiple layers involved (UI + API, or API + DB, or UI + state + API)
- 4+ acceptance criteria
- New screen or page with navigation
- New state management (provider, store, slice)
- External service integration (payment, auth, third-party API)
- Database schema changes (migrations)
- Significant refactoring across multiple modules

Examples: new feature with screen + backend, auth flow, payment integration,
new CRUD with list/detail/create/edit screens, module refactoring.

## Step 5 — Check for UI changes (skip for trivial and hotfix)

**For trivial tasks:** skip this step entirely. Even if it's a UI text/color
change, you don't need a Figma node — the change is too small.

**For simple and complex tasks:**
Scan the title, description, and acceptance criteria for UI-related keywords:
screen, page, view, modal, dialog, popup, button, toggle, switch, form, input,
dropdown, menu, navigation, layout, icon, animation, style, design, color,
font, image, responsive, mobile, tablet.

If UI keywords found, use AskUserQuestion:
"This task involves UI changes. Please provide the Figma node URL for the design."

If developer provides a URL, try to read the design:

1. **Local export:** Check if `design/screens/` contains a JSON file for this screen
   (match by screen name from the URL or Jira ticket title). If found, read it.

2. **Suggest export:** If no local export exists, suggest:
   "Run `/improvs:figma-export <URL>` to export the design locally, then re-run /start."

From the local design JSON, extract:
- Layout structure (flex, grid, positioning)
- Spacing values (padding, margin, gaps)
- Colors (exact hex or design tokens)
- Typography (font, size, weight)
- Component variants and states
- Interactive behaviors described in design

Save this context — you will need it during implementation and verification.

If developer says there is no Figma design, note this and proceed.

## Step 6 — Create branch

**First, check working tree:**
Run `git status`. If there are uncommitted changes, STOP:
"You have uncommitted changes. Stash or commit them before starting a new task."

**Check base branch is up to date:**
If `$IS_HOTFIX` is true, use `main` as the base branch (always, regardless of CLAUDE.md).
Otherwise, read the project's CLAUDE.md for the base branch name (look for "base branch",
"default branch", or "PR target"). Default to `develop` if not specified.

```bash
git checkout $BASE_BRANCH
git pull
```

If the base branch is behind remote, warn the developer.

**Branch name:**

**For trivial tasks:** auto-generate from ticket title, no question.
Example: "Fix login button color" → `PROJ-42-fix-login-button-color`
Take the title, lowercase, kebab-case, max 4-5 words. Speed is the point.

**For simple and complex tasks:** ask the developer:
"Short branch description (2-4 words, kebab-case):"

Example: if ticket is "Add biometric login for iOS", suggest "biometric-login"
but let the developer choose.

Create the branch:
```bash
git checkout -b $KEY-$DESCRIPTION
```

Example: `PROJ-42-biometric-login`

If the branch already exists, ask: "Branch $KEY-$DESCRIPTION already exists.
Switch to it or create a new name?"

## Step 7 — Push branch to origin

Push the newly created branch so it appears in Jira's development panel
(via the GitHub-Jira integration) and is available for remote tracking:

```bash
git push -u origin $KEY-$DESCRIPTION
```

## Step 8 — Update Jira ticket fields and move to "In Progress"

Via Jira MCP, update **all** of the following. Do NOT add a comment — all
metadata lives in ticket fields so `/finish` and `/review` can read it reliably.

**Transition:** Move ticket to "In Progress".

**Update ticket fields:**
- **Start date** (`startDate`): set to today's date in ISO format (`YYYY-MM-DD`)
- **Story points** (`story_points` or `customfield_10016`): set based on complexity:
  - Trivial → **1** story point
  - Simple → **3** story points
  - Complex → **8** story points
- **Labels**: if `$IS_HOTFIX`, add label `hotfix` to existing labels

**Development panel:** The branch automatically appears in the ticket's Development
section because the branch name contains the ticket key (`$KEY-$DESCRIPTION`)
and is pushed to origin. This is handled by the GitHub for Jira integration app.

**No comment.** The `/finish` skill reads metadata from ticket fields:
- **Complexity** — derived from story points (1→trivial, 3→simple, 8→complex)
- **Hotfix** — detected from `hotfix` label
- **Start time** — read from the ticket's changelog / transition history
  (the timestamp when it was moved to "In Progress")

## Step 9 — Present summary and begin

Display the work summary based on complexity:

### For TRIVIAL tasks:

```
READY TO START
━━━━━━━━━━━━━━
Ticket:     $KEY — $TITLE
Branch:     $KEY-$DESCRIPTION (auto)
Complexity: Trivial (cosmetic/text/config change)
Mode:       Direct fix — no TDD, no /review, no /test

Acceptance Criteria:
- [ ] ...

Make the change, commit, and run /finish.
```

No TDD, no /review, no /test required. Developer makes the change, commits, runs /finish.
The /finish skill will skip review and test verification for trivial tasks.

### For SIMPLE tasks:

```
READY TO START
━━━━━━━━━━━━━━
Ticket:     $KEY — $TITLE
Branch:     $KEY-$DESCRIPTION
Complexity: Simple (single layer, 1-2 files)
Mode:       TDD (superpowers:test-driven-development)

Acceptance Criteria:
- [ ] ...
- [ ] ...

Invoking superpowers:test-driven-development via the Skill tool.
```

Then immediately invoke `superpowers:test-driven-development` via the Skill tool.
Do not prompt the developer. The skill enforces the red-green-refactor discipline
(write failing test, verify fail, minimal implementation, verify pass, refactor,
repeat per AC).

### For COMPLEX tasks:

```
READY TO START
━━━━━━━━━━━━━━
Ticket:     $KEY — $TITLE
Branch:     $KEY-$DESCRIPTION
Complexity: Complex ($REASON — e.g. "3 layers: UI + API + DB, 5 AC")
Mode:       Full pipeline (superpowers:brainstorming -> writing-plans -> executing-plans)

Acceptance Criteria:
- [ ] ...
- [ ] ...

Invoking superpowers:brainstorming via the Skill tool.
```

Then immediately invoke `superpowers:brainstorming` via the Skill tool. Do not
prompt the developer. The classification block above shows $REASON, which gives
the developer a natural override window: they can say "actually this is simple,
skip brainstorming" the moment they see the classification, before brainstorming
gets a chance to start. The brainstorming skill chains into writing-plans and
executing-plans on its own — `/start` does not need to invoke them directly.

## Skill invocation convention

- **Improvs skills** (`/start`, `/finish`, `/review`, `/test`, etc.) — invoke via the Skill tool using slash name.
- **Superpowers plugins** (`superpowers:brainstorming`, `superpowers:test-driven-development`, etc.) — invoke via the Skill tool using colon-qualified name.

## Rules

- **No comments.** All metadata goes into Jira ticket fields. Do NOT add comments to the ticket.
- **Fields are the source of truth.** `/finish` and `/review` read complexity from story points, hotfix from labels, and start time from transition history.
- NEVER start coding without reading the Jira ticket first.
- NEVER guess if acceptance criteria are ambiguous. Ask the developer.
- NEVER create a branch without a Jira key prefix.
- NEVER commit code. Developer commits manually.
- For trivial tasks, do NOT ask for branch name or Figma URL — auto-skip these.
- If the developer is already on a branch that matches the ticket key,
  ask: "You're already on branch $BRANCH. Continue on this branch?"
