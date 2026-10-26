---
name: start-work
description: Full end-to-end workflow — select project, pick work order, implement, test, commit, push, create PR, and update status.
---

# Start Work

Complete end-to-end development workflow from task selection to PR creation.

## Steps

0. **MCP prerequisite**: Try `project(action=list)`. If the tool is unavailable or returns auth errors, **stop immediately**. Tell the user to run **`/forge-connect`** — Forge **Install in IDE → Antigravity** (Application Context, Project Settings, or User Settings → API Tokens). Do not start the workflow until **`forge`** is connected under **Customizations → MCP / Plugins**.

1. **Configure hooks**: Call `repo_setup(action=configure)` with `{ "ide": "antigravity", "hooks_already_present": true }` plus `workspace_project_id` / `hook_version` from `.forge/project-id` and `.forge/hook-version` when present. On `needs_update`, overwrite returned files.

2. **Select project**: Skip if configure restored a project. Otherwise call `project(action=list)`, let the user choose, then `project(action=set)`.

3. **Pick work order**: Call `work_order(action=start)` (0/1/many gate; after user picks, call again with `work_order_id` to claim/start). Call `work_order(action=get)` when full context is missing (accepts `WO-NNN` or UUID). Confirm with the user after reviewing:
   - **`implementation_brief`** (primary implement guide)
   - **`custom_instructions`** (beyond AC — must honor)
   - **`dependency_status` / `dependency_warning`**
   - Acceptance criteria and RTM traceability

4. **Load project context**: Call `get_journey_progress(include_raw_state=true)` or `get_journey_progress`, then load artifacts as needed:
   - `get_artifact` type `intent`, `prd`, `prd_spec`, `architecture`, `ui_design`, `rtm`
   - `get_artifact(query=...)` if the user asks about a specific requirement by keyword
   - `get_artifact(ux_references=true)` if design refs are relevant

5. **List repos**: Call `project_repos(action=list)` to identify which repos to work in. Ensure they're cloned.

6. **Implement**: Follow `implementation_brief` and acceptance criteria; honor `custom_instructions` and dependency warnings.

7. **Test**: Run relevant tests to verify the implementation.

8. **RTM drift check**: Call `get_artifact` type `rtm`. Compare implementation against RTM rows linked to this work order. Prepare `rtm_drift_summary` for `work_order(action=update)`.

9. **Prepare commit**: Call `work_order_delivery(action=prepare_commit)` with `work_order_id` to generate the commit message. Fix any scope issues flagged.

10. **Commit**: Commit using the `[WO-...]` message from `work_order_delivery(action=prepare_commit)`.

11. **Report dev activity**: Call `work_order(action=update)` with `work_order_id` and full dev-activity fields (`commit_summary`, `test_summary`, `rtm_drift_summary`, repo/branch/commit stats, test counts).

12. **Push**: Push the branch to the remote.

13. **Create PR**: Call `work_order_delivery(action=create_pr)` with `work_order_id`, `branch_name`, `changes_summary`, and repo details. Run the returned CLI command (e.g. `gh pr create`) or create the PR manually and pass `pr_url` / `pr_number`.

14. **Sync activity**: Call `dev_activity(action=sync)` so Forge has the latest commit/PR data (retry if blocked).

15. **Complete after merge**: When the PR is merged (you merged it or the user said so), without waiting for a reminder:
    1. Prefer `work_order_id` as **`WO-NNN`**
    2. `dev_activity(action=sync)` again if needed
    3. `work_order(action=complete)` with `pr_number` when known
    4. **`work_order(action=get)`** — only finish when `status === "completed"`. If complete said already completed but get still shows in progress, retry complete (heal) or report the mismatch.
    If no merged PR proof exists, warn the user and only use `user_confirmed_complete_without_merged_pr: true` after explicit confirmation.

## Comments and clarifications (optional)

- WO thread: `work_order_comments(action=list)` → `work_order_comments(action=comment)` (param `wo_id`, e.g. `WO-001`)
- Team Q&A: `clarifications(action=ask)` → `clarifications(action=list)`

## Important

- `work_order(action=start)` auto-transitions; use `work_order(action=workflow_stages)` + `work_order(action=transition)` only for manual stage changes.
- Always validate scope with `work_order_delivery(action=prepare_commit)` before committing.
- Call `work_order(action=update)` after commit — do not skip straight to PR creation.
- Link all PRs to the work order for traceability.
- Only commit to linked repositories.
