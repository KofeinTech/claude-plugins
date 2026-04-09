---
name: Create Bug
description: Structured bug report creation in Jira with reproduction steps, severity, environment, and expected vs actual behavior.
---

# Create Bug Ticket

Guide the user through creating a properly structured Jira bug ticket. Ensures all critical information is captured: reproduction steps, environment, severity.

Usable by PMs, CEO, and developers.

## Usage

```
/create-bug <JIRA_PROJECT_KEY>
```

Example: `/create-bug PINK`

Valid project keys: FANT, PINK, CUE, REW, TRAD, SOL, IMP

## What this skill does

### Step 1 -- Gather the bug report

Use AskUserQuestion: "Describe the bug. What's happening that shouldn't be?"

Read the user's response and identify what's known and what's missing.

### Step 2 -- Ask for missing details

Use AskUserQuestion to fill in gaps. Ask only what's missing -- don't re-ask what the user already provided.

**Always needed (ask if missing):**
- "How do you reproduce this? Step by step."
- "What should happen instead?"
- "Which platform and version? (iOS/Android, app version, OS version)"
- "How often does it happen? (Every time / Sometimes / Once)"

**Ask if relevant:**
- "Is there an error message or crash log?"
- "Which user account or data triggers this?"
- "Did this work before? If so, when did it break?"
- "Do you have a screenshot or screen recording?"

Keep it to 3-4 questions max. Note missing info as "TBD" in the ticket rather than over-questioning.

### Step 3 -- Generate the structured bug ticket

**Title:** Start with the symptom, include context.
- Good: "App crashes on notification tap (Android 14)"
- Bad: "Crash bug" or "Notifications broken"

**Type:** Bug

**Description:** Structure the Jira description using proper ADF nodes. Never embed raw Markdown syntax (`##`, `**`, `- [ ]`, `\n`) inside plain text nodes.

ADF structure for the description:

- **heading** (level 2): "Bug Report"
- **paragraph** with **strong** mark: "Summary:" followed by plain text (one sentence describing the issue)
- **heading** (level 2): "Steps to Reproduce"
- **orderedList** with **listItem** nodes for each reproduction step
- **heading** (level 2): "Expected Behavior"
- **paragraph**: what should happen
- **heading** (level 2): "Actual Behavior"
- **paragraph**: what actually happens -- include error messages if available
- **heading** (level 2): "Environment"
- **bulletList** with **listItem** nodes:
  - Platform: iOS / Android / Web / All
  - OS Version: e.g., Android 14, iOS 17.2
  - App Version: e.g., 2.3.1
  - Device: e.g., Pixel 7, iPhone 15 (if relevant)
- **heading** (level 2): "Frequency"
- **paragraph**: Every time / Sometimes (~X% of attempts) / Once / Unknown
- **heading** (level 2): "Additional Context"
- **paragraph**: Screenshots, logs, related tickets, workarounds if any

**Priority:** Auto-suggest based on severity:
- **Critical:** App crash, data loss, security vulnerability, blocks core user flow
- **High:** Feature broken but workaround exists, affects many users
- **Medium:** UI glitch, minor feature broken, affects some users
- **Low:** Cosmetic issue, typo, edge case with easy workaround

### Step 4 -- Present for review

Show the complete ticket:
```
BUG TICKET for {PROJECT_KEY}

Title: {title}
Type: Bug
Priority: {priority} ({reason})

{full description}

Create this ticket in Jira?
```

Use AskUserQuestion to confirm:
- "Create as shown"
- "I want to adjust something"
- "Add to current sprint" (for high/critical) vs "Add to backlog" (for medium/low)

### Step 5 -- Create in Jira

Via Jira MCP:
- Create the ticket with all fields
- Set priority based on severity assessment
- Add label "bug"
- If Critical: add to current sprint automatically and note "Critical bug -- added to current sprint"
- Output: "Created {KEY}: {title} -- {jira_url}"

## Rules

- **ADF formatting:** Always write Jira description content as properly structured ADF nodes (heading, bulletList, orderedList, taskList, paragraph, strong marks). Never embed raw Markdown syntax (e.g. `## headings`, `- [ ]`, `**bold**`, `\n`) inside plain text nodes.
- Every bug ticket MUST have reproduction steps. If the user can't provide them, write "Reproduction steps unknown -- needs investigation" and set a label "needs-repro".
- Every bug ticket MUST have expected vs actual behavior. This is what makes bugs actionable.
- Auto-suggest priority but let the user override. Explain your reasoning: "Suggesting High because this crashes the app, but there's a workaround."
- If the user reports multiple bugs at once ("the app crashes AND the login is slow"), create separate tickets for each. Ask: "This sounds like 2 separate issues. Should I create 2 tickets?"
- Don't add technical root cause speculation to bug tickets. That's the developer's job during `/bug`.
- If the user mentions the bug is already known or has a duplicate, search Jira first (if possible) and link to the existing ticket instead of creating a new one.
- Language should be neutral and factual. No blame, no drama. "App crashes" not "App is completely broken and unusable."
