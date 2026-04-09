---
name: finish
description: Complete current task. Checks code is committed and tested, pushes, creates PR, updates Jira status, logs time spent.
---

# Finish Task

## Jira status workflow

All Improvs projects use these statuses in order:
**To Do** → **In Progress** → **In Review** → **Done**

Additional statuses: **Blocked** (can be set from any active status).
This skill transitions tickets to **In Review**.

---

No arguments needed. Works with the current branch.

## Step 1 — Validate current state

**Check branch name:**
Extract Jira ticket key from current branch name.
Branch must match pattern: `KEY-123-description`.

If branch is `main`, `develop`, or has no Jira key:
"You're on branch `$BRANCH` which has no Jira ticket key.
Switch to your feature branch first."
STOP.

**Check for uncommitted changes:**
Run `git status`.

If there are uncommitted changes:
"You have uncommitted changes. Please review your code and commit first.
Then run /finish again."
STOP.

**Check for unpushed commits:**
Run `git log origin/$BRANCH..HEAD` (if remote branch exists)
or `git log --oneline` (if new branch not yet pushed).

If there are no commits at all:
"No commits found on this branch. Nothing to finish."
STOP.

## Step 2 — Code review and test verification

**First, check task metadata.**
Read the Jira ticket comments. Find the /start comment with `⏱ Work started`.
Extract: `Complexity:` value, `Hotfix:` value (true / false), and `Started at:` timestamp.

**Hotfix detection fallback:** If the comment is missing or `Hotfix:` field is not found,
also check if the Jira ticket has the label `hotfix`. This matches `/review`'s detection
logic and ensures hotfix flow works even if `/start` was not used.

**If complexity is "trivial"** → skip review and test verification. Proceed to Step 3.

**If hotfix is "true" (from comment or label):**
Invoke the `/review` skill via the Skill tool (it auto-detects hotfix mode from
the Jira label/comment and focuses on correctness and safety, skipping style nitpicks).

If review finds Critical or Important issues, STOP:
"Code review found issues. Please fix and commit, then run /finish again."
Show the issues list. Do NOT proceed until the developer re-runs /finish
with a clean review.

Skip /test verification entirely — hotfixes ship fast.

**If complexity is "simple" or "complex" (and NOT hotfix):**
Invoke the `/review` skill via the Skill tool (which internally invokes
`superpowers:requesting-code-review` in fresh context).

If review finds issues, STOP:
"Code review found issues. Please fix and commit, then run /finish again."
Show the issues list. Do NOT proceed until the developer re-runs /finish
with a clean review.

**Then verify /test was run:**

Check the git diff (committed files) for test files.
Look for new or modified files matching common test patterns:
- `*_test.dart`, `*_test.go`
- `*.test.ts`, `*.test.tsx`, `*.test.js`
- `test_*.py`, `*_test.py`
- `*Tests.cs`, `*Test.cs`
- Files in directories named `test/`, `tests/`, `__tests__/`

If test files found in diff → proceed.

If NO test files found:
"No test files were added or modified.
The /test sub-agent should be run before finishing.

Run /test now? (yes / skip)"

If developer says "yes" → invoke the `/test` skill via the Skill tool, then continue.
If developer says "skip" → warn: "Proceeding without independent tests."
Continue, but add warning marker in PR body.

## Step 3 — Push

```bash
git push -u origin $BRANCH
```

If push fails, show the error and suggest resolution.
NEVER use `--force`. If push is rejected due to remote changes,
tell the developer to pull and resolve conflicts.

## Step 4 — Create PR via GitHub MCP

Use GitHub MCP to create a pull request.

**Base branch:**
If `$IS_HOTFIX` is true (from Step 2), the base branch is `main` — always,
regardless of what CLAUDE.md says.
Otherwise, read from the project's CLAUDE.md (look for "base branch",
"default branch", or "PR target"). Default to `develop` if not specified.

**PR title:** Use the commit message format from the most recent commit.
If multiple commits, generate title from Jira ticket title:
`feat($SCOPE): $JIRA_TITLE`

Where $SCOPE is derived from the primary directory changed
(e.g., `auth`, `settings`, `api`).

**PR body:** Use this template:

```markdown
## Jira Ticket
[$KEY](https://improvs.atlassian.net/browse/$KEY)

## What Changed
- Bullet summary of changes (read from git diff --stat and commit messages)

## Acceptance Criteria
- [x] AC item 1 (checked = implemented)
- [x] AC item 2
- [ ] AC item 3 (unchecked = not addressed, explain why)

## Testing
- [x] Unit tests: N added/modified
- [x] Integration tests: N added/modified (if applicable)
- [x] Independent test review (/test sub-agent)
- [x] All tests passing

## Notes
Any additional context, decisions made, or things reviewer should know.
```

If /test was skipped in Step 2, replace the test review line with:
`- [ ] Independent test review (/test sub-agent) -- skipped`

**Read the Jira ticket** via Jira MCP to get the acceptance criteria
for the PR body. Check each AC against the actual implementation.

If any AC is NOT addressed, flag it:
"AC not addressed: '$AC_TEXT'. Was this intentional?"
Let developer confirm before proceeding.

**Hotfix: create a second PR to sync back to develop.**

If `$IS_HOTFIX` is true, create a second PR after the first:
- Base: `develop`
- Head: `$BRANCH`
- Title: `sync: merge hotfix $KEY into develop`
- Body: `Syncing hotfix $KEY ($TITLE) from main back to develop.\n\nSource PR: #$FIRST_PR_NUMBER`

This ensures the hotfix reaches both branches. The `main` PR is merged first
(urgent), and the `develop` sync PR is merged after.

## Step 5 — Update Jira

Via Jira MCP:

**Transition ticket to "In Review"**

**Add comment using proper ADF nodes** (never raw Markdown or `\n` in text nodes):
- **paragraph**: "Work completed"
- **paragraph**: "PR: $PR_URL"
- **paragraph**: "Branch: $BRANCH"
- **paragraph**: "Actual time: Xh Ym"

## Step 6 — Log time in Jira

**Read the /start comment** from the Jira ticket comments.
Look for the comment added by /start that contains `⏱ Work started`.
Extract all three fields (same ones read in Step 2):
- `Complexity:` — trivial / simple / complex
- `Hotfix:` — true / false
- `Started at:` — ISO 8601 timestamp (e.g. `2026-04-05T10:30:00.000+0000`)

**Calculate duration:**
From start timestamp to current time (now).

**Log worklog via Jira MCP:**
```
POST /rest/api/3/issue/$KEY/worklog
{
  "timeSpentSeconds": $DURATION_SECONDS,
  "started": "$START_TIMESTAMP"
}
```

**Display to developer:**
```
TIME LOGGED
━━━━━━━━━━
Ticket:   $KEY
Started:  $START_TIME
Finished: $NOW
Duration: Xh Ym
```

If start comment is not found:
"Could not find start time in Jira comments.
This happens when /start was not used or the comment was deleted.
How long did you work on this task? (e.g., 2h 30m)"

Log the manually provided time.

## Step 7 — Summary

Display final summary:

**Standard tasks:**
```
TASK COMPLETE
━━━━━━━━━━━━━━━
Ticket:   $KEY — $TITLE
Branch:   $BRANCH
PR:       $PR_URL (#$PR_NUMBER)
Status:   In Review
Time:     Xh Ym logged

What's done:
- $CHANGE_SUMMARY

Next: developer or reviewer merges PR.
```

**Hotfix tasks:**
```
HOTFIX COMPLETE
━━━━━━━━━━━━━━━
Ticket:   $KEY — $TITLE
Branch:   $BRANCH
PR (main):    $MAIN_PR_URL (#$MAIN_PR_NUMBER) -- merge ASAP
PR (develop): $DEV_PR_URL (#$DEV_PR_NUMBER) -- merge after main
Status:   In Review
Time:     Xh Ym logged

What's done:
- $CHANGE_SUMMARY

Next: get main PR reviewed and merged urgently. Then merge develop sync PR.
```

## Rules

- **ADF formatting:** Always write Jira comments as properly structured ADF nodes (paragraph, strong marks). Never embed raw Markdown syntax or `\n` inside plain text nodes.
- NEVER commit code. Developer commits manually before running /finish.
- NEVER force push.
- NEVER skip the Jira time logging — this data is critical for estimation.
- NEVER create PR to `main` unless it is a hotfix (detected from Jira comment) or CLAUDE.md explicitly says so.
- If start time is missing, ask developer — don't guess or skip.
- If any AC is not addressed, confirm with developer before creating PR.
