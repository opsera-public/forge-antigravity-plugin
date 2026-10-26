---
name: work
description: Show your current work order or pick the next one — quickly see what to work on.
---

# Work

Show the current work order or pick the next available task.

## Steps

0. **MCP prerequisite**: Try `project(action=list)`. If the tool is unavailable or returns auth errors, **stop immediately**. Tell the user to run **`/forge-connect`** — or use Forge **Install in IDE → Antigravity** at [app.softwareforge.ai](https://app.softwareforge.ai), then confirm **`forge`** is green under **Customizations → MCP / Plugins**. Do not proceed until MCP works.

1. Call `repo_setup(action=configure)` with `{ "ide": "antigravity", "hooks_already_present": true }` plus `workspace_project_id` / `hook_version` from `.forge/*` when present.

2. Ensure a project is set. Prefer restore from configure; otherwise call `project(action=list)`, ask the user to choose, then `project(action=set)`.

3. **Pick or browse:**
   - Default: call `work_order(action=start)` (0/1/many gate; after user picks from `needs_user_choice` or `unassigned_stories`, call again with `work_order_id`).
   - Browse: call `work_order(action=workflow_stages)`, then `work_order(action=list)` with `status` / `priority` filters, then `work_order(action=get)` with `work_order_id` (`WO-NNN` or UUID).

4. Display the work order with:
   - Title and description
   - Priority and status
   - **`implementation_brief`** summary (or point the user that it is available)
   - **`custom_instructions`** if present
   - **`dependency_status`** / warnings
   - Acceptance criteria (if any)
   - RTM traceability (from `work_order(action=get)` response when available)
   - `recommended_models` when present
   - Linked repositories

5. Offer context loading: `get_artifact` (`intent`, `prd`, `prd_spec`, `architecture`, `ui_design`, `rtm`) or `work_order_comments(action=list)` if the user wants discussion history.

6. Ask the user if they want to start working. If yes and the task is not already in progress:
   - If you used `work_order(action=start)` (without `dry_run`), it may already be claimed/started.
   - Otherwise call `work_order(action=start)` with `work_order_id`, or `work_order(action=workflow_stages)` then `work_order(action=transition)` with the valid next `status`.

8. Call `project_repos(action=list)` and remind the user to ensure all repos are cloned locally.

9. Suggest **`/start-work`** for the full implement → commit → PR workflow.

## Clarifications and comments

- WO comments: `work_order_comments(action=list)` with `wo_id` (e.g. `WO-001`)
- Post comment: `work_order_comments(action=comment)` with `wo_id`, `content`, optional `trigger_ai: false`
- Team Q&A: `clarifications(action=ask)` or `clarifications(action=list)`
