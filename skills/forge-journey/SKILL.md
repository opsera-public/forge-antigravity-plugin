---
name: forge-journey
description: Load Forge journey progress — stage status, approvals, blockers, staleness — and offer approve, generate, or chat actions.
---

# Forge Journey

Load full journey state and guide next actions for stage approvals, generation, or chat.

## MCP prerequisite

Try `project(action=list)`. If unavailable or auth fails, **stop** and tell the user to run **`/forge-connect`**.

1. Call `repo_setup(action=configure)` with `{ "ide": "antigravity", "hooks_already_present": true }` plus `workspace_project_id` / `hook_version` from `.forge/*` when present.
2. Ensure a project is set; prefer restore from configure, else `project(action=list)` → `project(action=set)`.

## Steps

1. Call `get_journey_progress` — show per-stage unlock, complete, approved, blockers, staleness, and versions (includes **`ui_design`** when enabled for the project).
2. Summarize current step and what is blocked vs ready.
3. Offer actions based on state:
   - **Approve** — `journey_stage(action=approve)` (stages include `ui_design`; only if user explicitly requests)
   - **Reject** — `journey_stage(action=reject)` with optional reason
   - **Generate** — `trigger_stage_generation` for unlocked stages (including `ui_design`)
   - **Chat** — `journey_chat(action=send)` / `journey_chat(action=list)` for a specific step
4. If user wants basic metadata only, `get_journey_progress(include_raw_state=true)` is lighter but omit if `get_journey_progress` already ran.

## Output

Present:
- Active project name/ID
- Current journey step and stage summary table
- Stale stages and blockers (if any)
- Suggested next step: approve, generate, `/forge-context`, `/work`, or `/forge-artifacts`

## MCP tools

`get_journey_progress`, `journey_stage(action=approve)`, `journey_stage(action=reject)`, `trigger_stage_generation`, `journey_chat(action=send)`, `journey_chat(action=list)`, `get_journey_progress(include_raw_state=true)`

## Important

- Do not call `journey_stage(action=approve)` or `journey_stage(action=reject)` without explicit user confirmation.
- If tools return "not available", suggest the Forge web UI for journey management.
