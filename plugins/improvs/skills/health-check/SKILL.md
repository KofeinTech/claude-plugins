---
name: Health Check
description: Audit project health from Jira board and GitHub repos. Finds stuck tickets, stale PRs, unassigned work, inconsistencies, and blockers.
---

# Project Health Check

## Jira status workflow

All Improvs projects use these statuses in order:
**To Do** → **In Progress** → **In Review** → **Done**

Additional statuses: **Blocked** (can be set from any active status).
This skill queries all statuses but does not modify them.

---

Project key is provided as $ARGUMENTS. If no argument given, ask for it.
Valid keys: FANT, PINK, CUE, REW, TRAD, SOL, IMP

## Step 1 -- Jira board audit

Via Jira MCP, run these checks:

**Stuck tickets:**
Search: `project = $KEY AND status = "In Progress" AND updated <= -2d`
Flag any ticket in progress for 2+ days with no recent updates.

**Stale tickets:**
Search: `project = $KEY AND updated <= -7d AND status != Done`
Flag any ticket untouched for 7+ days that isn't done.

**Unassigned in sprint:**
Search: `project = $KEY AND sprint in openSprints() AND assignee is EMPTY AND status != Done`
Every sprint ticket must have an owner.

**Missing acceptance criteria:**
Search: `project = $KEY AND sprint in openSprints() AND status != Done`
Read each ticket. Flag tickets with no acceptance criteria or vague descriptions.

**Blockers:**
Search: `project = $KEY AND (priority = Blocker OR status = "Blocked")`
List all blocked tickets with reason if available.

**Status inconsistencies:**
- Tickets marked "In Review" with no open PR
- Tickets marked "In Progress" with no branch
- Tickets marked "Done" with no merged PR

## Step 2 -- GitHub audit

Via GitHub MCP, check the project repository:

**Stale PRs:**
PRs open for more than 3 days with no review activity.

**Abandoned branches:**
Branches with no commits in 7+ days that aren't merged.

**PRs without Jira links:**
PRs whose branch name doesn't contain a Jira key.

**Merge conflicts:**
PRs with merge conflicts that need resolution.

## Step 3 -- Report

Output a structured health report:

```
HEALTH CHECK: $KEY
Date: $TODAY

--- CRITICAL (act today) ---
- [PINK-42] Stuck 5 days in "In Progress" -- last update Mon
- PR #47 has merge conflicts, open 4 days

--- WARNINGS (act this week) ---
- [PINK-38] No acceptance criteria -- in current sprint
- Branch PINK-35-old-feature abandoned (12 days, no PR)
- 2 tickets unassigned in sprint

--- INFO ---
- 3 tickets in review, all have open PRs
- Sprint completion: 6/10 tickets done (60%)
- No blockers found

SUMMARY: 2 critical, 3 warnings
```

## Step 4 -- Suggest actions

For each issue, suggest a specific action:
- Stuck ticket -> "Ask developer in Telegram what's blocking them"
- Missing AC -> "Add acceptance criteria before dev starts working"
- Stale PR -> "Ping reviewer: @name"
- Abandoned branch -> "Delete or create PR"

## Rules

- This is a READ-ONLY audit. Do not modify any tickets or PRs.
- If the project has no open sprint, note it: "No active sprint found."
- Run this daily or weekly -- it's designed to be fast.
- Focus on actionable issues. Don't report things that are working fine.
