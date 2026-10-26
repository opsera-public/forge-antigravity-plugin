---
name: forge-orders
description: Browse Forge work orders — stats, filtered list, task details, comments, and clarifications.
---

# Forge Orders

Browse and inspect work orders without starting full implementation.

## MCP prerequisite

Try `project(action=list)`. If unavailable or auth fails, **stop** and tell the user to run **`/forge-connect`**.

1. Call `repo_setup(action=configure)` with `{ "ide": "antigravity", "hooks_already_present": true }` plus `workspace_project_id` / numeric `hook_version` from `.forge/*` when present.
2. Ensure a project is set (`project(action=set)`).

## Steps

1. Call `work_order(action=workflow_stages)` — show valid status keys for filtering.
2. Call `work_order(action=list)`:
   - Apply `status` and/or `priority` filters if the user specified them
   - Otherwise show all accessible work orders (assigned to user, or all if admin)
3. If the user named a specific work order, call `work_order(action=get)` with `work_order_id` (`WO-NNN` or UUID).
4. Optional — comments and clarifications:
   - WO thread: `work_order_comments(action=list)` with `wo_id` (e.g. `WO-001`, not UUID)
   - Post comment: `work_order_comments(action=comment)` with `wo_id`, `content`, optional `trigger_ai: false`
   - Team Q&A: `clarifications(action=list)` or `clarifications(action=ask)`

## Output

- Filtered work order list (title, status, priority, id)
- Full details + RTM traceability when a specific WO was requested
- Comment thread summary if requested

## Next steps

- Start work on a task → **`/work`** or **`/start-work`**
- Load requirements → **`/forge-context`** or **`/forge-artifacts`**
- Sync after commits → **`/forge-sync`**
