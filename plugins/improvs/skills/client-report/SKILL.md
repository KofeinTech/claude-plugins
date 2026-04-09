---
name: Client Report
description: Generate a branded weekly progress report HTML for a client project from Jira and GitHub data.
---

# Client Weekly Report

Project key is provided as $ARGUMENTS. If no argument given, ask for it.

## Step 1 — Gather inputs

Ask:
- "Prepared by (your name):"
- "Week: last week or specific date? (default: last week)"

Calculate the date range:
- "last" (default) = last Monday 00:00 to Sunday 23:59
- Specific date = the Monday–Sunday week containing that date

## Step 2 — Read Jira data

Via Jira MCP, fetch for the project and date range:

**Completed tickets:**
Search: `project = $KEY AND status changed to "Done" DURING ($START, $END)`
For each: key, title, type, time logged (sum of worklogs in period).

**In Progress tickets:**
Search: `project = $KEY AND status = "In Progress"`
For each: key, title, assignee, time logged, original estimate.
Calculate progress: if original estimate exists → time logged / estimate × 100%.
If no estimate → show hours logged only, no percentage.

**Blockers:**
Search: `project = $KEY AND (priority = Blocker OR status = "Blocked"
OR (updated < -3d AND status = "In Progress"))`
Include stale tickets (>3 days no update) as potential blockers.

**Upcoming work:**
First, check if the project uses sprints:
Search: `project = $KEY AND sprint in openSprints()`

If sprints exist → fetch next sprint tickets:
Search: `project = $KEY AND sprint in futureSprints() ORDER BY priority`

If NO sprints (kanban) → fetch top backlog items:
Search: `project = $KEY AND status = "To Do" ORDER BY priority, rank ASC`
Limit to top 5-10 items.

If any query returns no results, note it — don't skip the section.

## Step 3 — Calculate metrics

**Total hours:** sum of all worklogs in date range. Round to nearest 0.5h.

**Progress metric (depends on project type):**
- If sprints: completed / total sprint tickets × 100%
- If kanban: just show completed count this week (no percentage)

When replacing template placeholders:
- Sprint project: {{SPRINT_PROGRESS}} = "65%", {{PROGRESS_LABEL}} = "Sprint progress"
- Kanban project: {{SPRINT_PROGRESS}} = "7", {{PROGRESS_LABEL}} = "Completed"

**Health status:**
- "On Track" — no blockers, work progressing
- "At Risk" — blockers exist or progress stalled
- "Blocked" — critical blockers without resolution

## Step 4 — Generate HTML report

Read the template file: `templates/report.html`

Replace all {{PLACEHOLDERS}} with actual data:
- {{PROJECT_NAME}} — project name from Jira
- {{DATE_RANGE}} — e.g. "March 31 – April 6, 2026"
- {{PREPARED_BY}} — PM name from Step 1
- {{GENERATED_DATE}} — today's date
- {{TOTAL_HOURS}} — total hours, rounded to 0.5h
- {{SPRINT_PROGRESS}} — percentage (sprint) or count (kanban)
- {{PROGRESS_LABEL}} — "Sprint progress" or "Completed"
- {{HEALTH_STATUS}} — On Track / At Risk / Blocked
- {{HEALTH_COLOR}} — #10b981 for On Track, #f59e0b for At Risk, #ef4444 for Blocked
- {{COMPLETED_ROWS}} — HTML rows for completed tickets
- {{COMPLETED_COUNT}} — number of completed tickets
- {{IN_PROGRESS_ROWS}} — HTML rows for in-progress tickets
- {{BLOCKERS_CONTENT}} — blocker items or "No blockers this week"
- {{NEXT_WEEK_ROWS}} — HTML rows for planned tickets

For {{COMPLETED_ROWS}}, generate per ticket as an accomplishment card:
```html
<div class="accomplishment">
  <div class="content">
    <span class="badge">COMPLETED</span>
    <h3>$CLIENT_FRIENDLY_TITLE</h3>
    <p>$CLIENT_FRIENDLY_DESCRIPTION</p>
  </div>
</div>
```
Write the title and description in client-friendly language.
"Refactored auth middleware" -> "Improved login security".
Never include Jira ticket keys — clients don't need internal references.

For {{IN_PROGRESS_ROWS}}, generate per ticket:
```html
<div class="accomplishment in-progress">
  <div class="content">
    <span class="badge badge--progress">IN PROGRESS</span>
    <h3>$CLIENT_FRIENDLY_TITLE</h3>
    <p>$CLIENT_FRIENDLY_DESCRIPTION</p>
    <span class="hours">$LOGGEDh logged${IF estimate: " of ~${ESTIMATE}h"}</span>
  </div>
</div>
```

For {{NEXT_WEEK_ROWS}}, generate as a bullet list:
```html
<li><strong>$CLIENT_FRIENDLY_TITLE</strong> &mdash; $SHORT_DESCRIPTION</li>
```

Group tickets by feature area if more than 5 in any section.

Save as: `reports/weekly-$PROJECT-$DATE.html`

## Step 5 — Present to PM

```
REPORT GENERATED
━━━━━━━━━━━━━━━━
Project:     $PROJECT_NAME
Period:      $DATE_RANGE
Hours:       Xh total
Sprint:      X% complete
Status:      On Track / At Risk / Blocked
Completed:   N tickets
In Progress: N tickets
Blockers:    N items

File: reports/weekly-$PROJECT-$DATE.html

Review before sending to client.
```

## Rules

- Report must be **non-technical**. Clients are not developers.
  Write in plain business language they understand.
  "Refactored auth middleware" -> "Improved login security".
  "Fixed null pointer in push handler" -> "Fixed app crash when opening notifications".
  "Added Riverpod state management" -> "Added user session handling".
- NEVER include Jira ticket keys (PINK-42, SOL-123, etc.) in the report.
  Clients don't use Jira and internal references confuse them.
- NEVER use technical jargon: no "refactor", "endpoint", "migration", "provider",
  "middleware", "API", "webhook", "state management", "null check", etc.
- Round all hours to nearest 0.5h.
- If no blockers, write "No blockers this week" — never omit the section.
- Always include Next Week so clients know what to expect.
- If no data for the week, write "No activity recorded" — don't guess.
- NEVER send reports directly to clients. PM reviews first.
- For In Progress without estimates, show hours only — no fake percentages.
