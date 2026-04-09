---
name: Test
description: Run independent test generation on the current branch. Dispatches test subagent that writes tests from Jira AC, not from implementation.
---

# Test

No arguments. Runs against the current branch.

## What this skill does

Dispatches the `test` subagent using the **Agent tool** with
`subagent_type: "test"` (defined at `improvs-claude-private/subagents/test.md`).
The subagent operates in fresh context with no visibility into the current
conversation, so it cannot be biased by the implementation discussion — that
independence is the entire point of running tests this way.

The subagent:

1. Reads the Jira ticket key from the current branch name
2. Reads the ticket via Jira MCP — Acceptance Criteria (AC) are the source of truth
3. Reads the changed files via `git diff $BASE_BRANCH --name-only`
4. Writes one test group per AC item, using the project's existing test
   framework (Flutter / pytest / xUnit / vitest, auto-detected from project files)
5. Adds edge case tests for null / empty / boundary / invalid type / error states
6. Runs the tests via the command in the project's CLAUDE.md
7. Reports failing tests as **potential bugs** — does not "fix" them silently

See `improvs-claude-private/subagents/test.md` for the full subagent
specification, including the rules about what tests to keep vs reject.

## Why a separate subagent

The mandatory rule is: *"NEVER read the implementation first. Always read
Jira AC first."* Putting the test agent in a separate fresh-context subagent
is the only reliable way to enforce that — if it ran in the main conversation,
it would inevitably absorb the implementation context and start writing tests
that confirm the code works, instead of tests that verify the AC is met.

## Rules

- NEVER skip /test for simple or complex tasks. /finish will block PR creation
  if no test files were added or modified on the branch.
- For trivial tasks, /test is skipped — there is no AC and no logic to test.
- The subagent reports failing tests as potential bugs. Do NOT modify the
  generated tests to make them pass. Investigate whether the test or the
  code is wrong, then fix the actual issue.
