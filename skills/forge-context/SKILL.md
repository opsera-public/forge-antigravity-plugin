---
name: forge-context
description: Load Forge project context — journey progress, linked repos, and key journey artifacts (intent, PRD, PRD-Spec, architecture, RTM).
---

# Forge Context

Load project context before implementing work or answering requirements questions.

## MCP prerequisite

Try `project(action=list)`. If unavailable or auth fails, **stop** and tell the user to run **`/forge-connect`**.

1. Call `repo_setup(action=configure)` with `{ "ide": "antigravity", "hooks_already_present": true }` plus `workspace_project_id` / `hook_version` from `.forge/*` when present.
2. Ensure a project is set; prefer restore from configure, else `project(action=list)` → `project(action=set)`.

## Steps

1. Call `get_journey_progress` — summarize journey step, stage status, blockers, and staleness (fallback: `get_journey_progress(include_raw_state=true)` if journey tools unavailable).
2. Call `project_repos(action=list)` — list repos to clone/work in.
3. Load artifacts (latest versions):
   - `get_artifact` type `intent`
   - `get_artifact` type `prd`
   - `get_artifact` type `prd_spec` (if project uses PRD-Spec stage)
   - `get_artifact` type `architecture`
   - `get_artifact` type `ui_design` (if UI design stage is present)
   - `get_artifact` type `rtm` (summarize row count / key requirements; full doc if user asks)
4. If the user asked about a specific topic, also call `get_artifact(query=...)` with their keywords.

## Output

Present a concise briefing:
- Active project and journey status
- Linked repos
- One-paragraph summary per artifact loaded (not full dumps unless requested)
- Suggested next step: **`/work`**, **`/start-work`**, **`/forge-journey`**, or **`/forge-artifacts`**

## Optional

- `get_artifact(ux_references=true)` if the user mentions design or UI
- `project_repos(action=link)` only if the user explicitly asks to link a new repository
