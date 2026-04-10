---
name: review
description: Review current branch against Improvs rules and Jira acceptance criteria. Hard-blocks secrets, dispatches code reviewer, verifies AC coverage.
---

# Code Review

No arguments. Reviews the current branch against its base branch.

## Step 1 — Determine target

Current branch:

```bash
BRANCH=$(git rev-parse --abbrev-ref HEAD)
```

Base branch: read from the project's CLAUDE.md (look for "base branch", "default
branch", or "PR target"). Default to `develop`. **Exception:** if the Jira
ticket has label `hotfix`, the base is `main`.

If the current branch is `main`, `develop`, or another protected branch,
abort: "Cannot /review from $BRANCH. Switch to a feature branch first."

## Step 2 — Extract Jira key

The branch must match `^[A-Z]{2,}-[0-9]+-`. Extract `$KEY` (e.g. `PINK-42`).

If no Jira key found, abort: "Branch $BRANCH has no Jira key. /review needs
a Jira ticket to compare against acceptance criteria."

## Step 3 — Read the Jira ticket

Via Jira MCP, read $KEY. Extract:

- Title
- Type (Bug / Task / Epic)
- Priority
- Acceptance Criteria / AC (this is the source of truth for Step 8)
- Description (for context)

If the ticket has no acceptance criteria, warn: "Ticket $KEY has no AC.
Review will run but AC coverage check will be skipped." Continue.

If Jira MCP fails, abort with the error message and tell the developer to
check their Jira MCP authentication.

## Step 4 — Hard-block secret scan

Get the diff against the base branch:

```bash
BASE_SHA=$(git merge-base origin/$BASE_BRANCH HEAD)
HEAD_SHA=$(git rev-parse HEAD)
git diff $BASE_SHA..$HEAD_SHA
```

Scan the diff for these patterns (case-insensitive):

| Pattern | What it catches |
|---------|----------------|
| `password\s*=\s*['"][^'"]+['"]` | Hardcoded password literal |
| `api[_-]?key\s*=\s*['"][^'"]+['"]` | Hardcoded API key |
| `secret\s*=\s*['"][^'"]+['"]` | Hardcoded secret literal |
| `AKIA[0-9A-Z]{16}` | AWS access key ID |
| `-----BEGIN [A-Z ]*PRIVATE KEY-----` | Private key file content |
| `bearer\s+[a-zA-Z0-9_\-\.]{20,}` | Bearer token |

If ANY pattern matches in added (`+`) lines, abort with:

```
BLOCKED: hardcoded secret detected
File: $FILE
Line: $LINE
Pattern: $WHICH_PATTERN

Move this value to an environment variable and re-run /review.
Never commit secrets to git. See security-rules.md.
```

Do NOT proceed to the actual review until secrets are removed.

## Step 5 — Build the requirements block

Construct the spec passed to the superpowers code reviewer:

```
## Jira Ticket (source of truth)
$KEY — $TITLE
Type: $TYPE | Priority: $PRIORITY

Description:
$DESCRIPTION

Acceptance Criteria:
- $AC1
- $AC2
- $AC3
...

## Improvs project rules to enforce
Read all files in .claude/rules/*.md in this project before reviewing.
Apply both global rules (security, conventions) and stack-specific rules
(Flutter / .NET / Python / Docker patterns).

## Mode
${IF Jira ticket has label "hotfix":
   "HOTFIX MODE: focus on correctness, safety, and minimal scope. Skip style
    nitpicks and refactoring suggestions. The fix needs to ship now."
 ELSE:
   "STANDARD MODE: full review."}
```

## Step 6 — Invoke superpowers code reviewer

Use the Skill tool to invoke `superpowers:requesting-code-review`. Pass:

- `BASE_SHA` from Step 4
- `HEAD_SHA` from Step 4
- `WHAT_WAS_IMPLEMENTED`: a 1-2 sentence summary read from the most recent
  commit messages on the branch
- `PLAN_OR_REQUIREMENTS`: the requirements block from Step 5
- `DESCRIPTION`: $KEY — $TITLE

The superpowers skill dispatches its own `superpowers:code-reviewer` subagent
in fresh context. It returns a structured review with Strengths, Issues by
severity (Critical / Important / Minor), Recommendations, and an Assessment
verdict (Yes / No / With fixes).

## Step 6a — Fallback: inline review

If the superpowers skill invocation fails for any reason (plugin not installed,
timeout, error), perform the review inline instead of aborting.

1. Read all `.claude/rules/*.md` files in the project (global + stack-specific).
2. Read the full diff (`git diff $BASE_SHA..$HEAD_SHA`).
3. Review the diff against these categories:
   - **Conventions compliance** — does the code follow the project's rules?
   - **Error handling** — are errors caught, logged, and handled properly?
   - **Security** — beyond the hard-block patterns: SQL injection, XSS,
     insecure deserialization, missing input validation
   - **Common issues** — unused imports, dead code, missing null checks,
     hardcoded values, leftover TODOs, commented-out code
4. Produce output in the same structured format as superpowers:
   - Strengths (what the code does well)
   - Issues grouped by Critical / Important / Minor
   - Recommendations
   - Assessment verdict: Yes / No / With fixes
5. Prefix the output with:
   "Note: This review was performed inline (superpowers plugin was unavailable)."

The inline review verdict feeds into Step 8 exactly like a superpowers verdict.

## Step 7 — Acceptance criteria coverage post-pass

After the superpowers review returns, do an explicit AC coverage analysis.
For each AC item:

1. Extract the key concepts from the AC text (nouns, action verbs,
   feature names).
2. Search the diff (`git diff $BASE_SHA..$HEAD_SHA`) for those keywords.
3. Search the changed file paths for related directory or file names.
4. Classify the AC as:
   - **Covered** — diff contains code clearly related to this AC
   - **Partial** — some related changes but not obviously addressing the AC
   - **Not addressed** — no diff content references this AC

If the ticket had no AC (Step 3 warning), skip this step entirely.

## Step 8 — Combined output

Print to the developer:

```
REVIEW: $KEY — $TITLE
Branch: $BRANCH
Base:   $BASE_BRANCH
Mode:   $MODE (standard / hotfix)

--- SECRET SCAN ---
No secrets detected
(or BLOCKED block from Step 4 — in which case nothing below ran)

--- CODE REVIEW ---
[Strengths section]

[Issues section, grouped by Critical / Important / Minor]

[Recommendations section]

[Assessment]

--- ACCEPTANCE CRITERIA COVERAGE ---
[x] AC 1: $AC1_TEXT — covered ($FILES_THAT_TOUCH_IT)
[~] AC 2: $AC2_TEXT — partial ($WHY)
[ ] AC 3: $AC3_TEXT — NOT addressed in diff
AC coverage: 1 covered, 1 partial, 1 missing (1/3 fully covered)
(skipped if ticket had no AC)

--- VERDICT ---
$COMBINED_VERDICT
```

The combined verdict combines the superpowers verdict with the AC coverage:

| Superpowers verdict | AC coverage | Combined verdict |
|---|---|---|
| Yes / Ready to merge | 100% covered | **APPROVED** |
| Yes / Ready to merge | <100% covered | **CHANGES REQUESTED** — missing AC |
| With fixes | any | **CHANGES REQUESTED** — see issues |
| No / Not ready | any | **CHANGES REQUESTED** — see Critical issues |

## Step 9 — Exit semantics

If the combined verdict is **APPROVED**, /review exits cleanly. /finish (which
auto-invokes /review for simple/complex tasks) will then proceed to push and
PR creation.

If the combined verdict is **CHANGES REQUESTED**, /review exits with an error
state that /finish will detect, blocking PR creation. The developer fixes
the issues, commits, and re-runs /review (or just re-runs /finish, which
re-invokes /review).

If /review was hard-blocked at the secret scan in Step 4, the same blocking
behavior applies — /finish will not proceed.

## Rules

- NEVER skip the secret scan. Hardcoded secrets are an automatic block,
  regardless of the rest of the review.
- NEVER fabricate AC coverage. If you cannot tell whether the diff addresses
  an AC, mark it as Partial and explain why — never claim Covered without
  evidence.
- NEVER post the review to GitHub. /review is a local tool. The developer
  reads it in their terminal and decides.
- NEVER block on Minor issues. Only Critical and Important issues from the
  superpowers review affect the verdict.
- For hotfix branches, the requirements block tells the reviewer to skip
  style nitpicks. Do not double-filter on the output side — trust the
  reviewer to follow the mode hint.
- If superpowers is unavailable, the inline fallback MUST still produce a
  structured review with the same severity levels and Assessment verdict.
  Never skip the review entirely because the plugin is missing.
- If the developer pushes back on a finding ("the reviewer is wrong about
  X"), do NOT re-run the review automatically. Tell them to address it
  manually and re-run /review when ready.
