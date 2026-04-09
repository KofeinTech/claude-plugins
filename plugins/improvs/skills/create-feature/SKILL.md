---
name: Create Feature
description: Guided creation of a well-structured Jira feature ticket with acceptance criteria, description, and technical notes.
---

# Create Feature Ticket

Guide the user through creating a properly structured Jira feature ticket. Asks clarifying questions, generates acceptance criteria, and creates the ticket in Jira.

Usable by PMs, CEO, and developers.

## Usage

```
/create-feature <JIRA_PROJECT_KEY>
```

Example: `/create-feature PINK`

Valid project keys: FANT, PINK, CUE, REW, TRAD, SOL, IMP

## What this skill does

### Step 1 -- Gather the idea

Use AskUserQuestion: "Describe the feature you need. What should the user be able to do?"

Read the user's response and identify:
- The core user action
- The value it provides
- Any mentioned constraints or requirements

### Step 2 -- Ask clarifying questions

Based on the feature description, ask 2-4 clarifying questions via AskUserQuestion. Focus on what's ambiguous or missing:

Common clarifications:
- Scope: "Should this work on both iOS and Android, or one platform first?"
- UX details: "Should there be a confirmation dialog before this action?"
- Edge cases: "What happens if the user has no internet connection during this?"
- Dependencies: "Does this depend on any existing feature or API?"
- Design: "Is there a Figma design for this, or should we create a ticket for design first?"

Do NOT ask more than 4 questions. If more info is needed, note it in the ticket description as "TBD -- needs PM decision."

### Step 3 -- Generate the structured ticket

Build the ticket with these fields:

**Title:** Clear, concise action statement. Start with a verb.
- Good: "Add QR code profile sharing"
- Bad: "QR code feature" or "PINK-123 QR"

**Type:** Story

**Description:** Structure the Jira description using proper ADF nodes. Never embed raw Markdown syntax (`##`, `**`, `- [ ]`, `\n`) inside plain text nodes.

ADF structure for the description:

- **paragraph** with **strong** marks: "As a" [user role], "I want to" [action], "so that" [value/benefit] (bold the keywords, plain text for the values)
- **heading** (level 2): "Context"
- **paragraph**: 2-3 sentences explaining the background and motivation
- **heading** (level 2): "Acceptance Criteria"
- **taskList** with **taskItem** nodes (state: "TODO") for each criterion
- **heading** (level 2): "Technical Notes"
- **paragraph**: relevant APIs, packages, architectural considerations. If applicable: "UI changes required -- Figma design needed before implementation"
- **heading** (level 2): "Out of Scope"
- **bulletList** with **listItem** nodes for each exclusion

**Acceptance criteria rules:**
- Each AC must be testable (a QA engineer can verify it with a yes/no answer)
- Include both happy path and key error cases
- Include platform specifics if relevant (iOS, Android, web)
- 3-7 acceptance criteria. If more than 7, the feature should be broken down.

### Step 4 -- Present for review

Show the complete ticket to the user:
```
FEATURE TICKET for {PROJECT_KEY}

Title: {title}
Type: Story
Priority: {suggested priority}

{full description with AC}

Create this ticket in Jira?
```

Use AskUserQuestion to confirm:
- "Create as shown"
- "I want to adjust something" (then ask what to change)
- "Add to current sprint" vs "Add to backlog"

### Step 5 -- Create in Jira

Via Jira MCP:
- Create the ticket with all fields
- Set priority (default: Medium unless user specified)
- Add to backlog or current sprint based on user's choice
- Output: "Created {KEY}: {title} -- {jira_url}"

## Rules

- **ADF formatting:** Always write Jira description content as properly structured ADF nodes (heading, bulletList, orderedList, taskList, paragraph, strong marks). Never embed raw Markdown syntax (e.g. `## headings`, `- [ ]`, `**bold**`, `\n`) inside plain text nodes.
- Language must be clear and jargon-free. PMs, devs, and stakeholders all read these tickets.
- Never create a ticket without user confirmation. Always show the full ticket first.
- If the feature sounds like it needs design work, add "Figma design needed" in technical notes and suggest creating a design task first.
- If the feature is too large for one ticket (more than 7 AC), suggest breaking it down: "This looks like it could be 2-3 separate tickets. Want me to break it down?"
- Acceptance criteria must be testable. "App should be fast" is not an AC. "Screen loads within 2 seconds on 4G" is.
- Always include an "Out of Scope" section to prevent scope creep.
- Suggested priority logic:
  - Critical: affects revenue or blocks users
  - High: important feature on roadmap
  - Medium: default for new features
  - Low: nice-to-have, no deadline
