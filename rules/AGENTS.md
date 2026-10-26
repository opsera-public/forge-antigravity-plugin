---
description: Forge workflow conventions — ensures work order alignment, journey discipline, artifact safety, and proper project context usage
---

forge-conventions:

- Call `repo_setup(action=configure)` once per session before work order tools with `ide: antigravity` and `hooks_already_present: true` when the marketplace plugin is installed. If `.forge/project-id` exists, pass its first line as `workspace_project_id`. If `.forge/hook-version` exists, pass it as a **number** `hook_version`. Omitting `hook_version` is treated as `0` and typically yields `needs_update` — write all returned files. On `needs_update`, overwrite all returned files.
- Prefer workspace project restore via `repo_setup(action=configure)` + `workspace_project_id`; call `project(action=set)` only when restore is unavailable or invalid.
- Use `get_journey_progress` for full stage status, blockers, and staleness; use `get_journey_progress(include_raw_state=true)` only for basic journey metadata.
- Load project artifacts with `get_artifact` (`intent`, `prd`, `prd_spec`, `architecture`, `ui_design`, `rtm`) or `get_artifact(query=...)` before implementing scoped work.
- After `work_order(action=get)`, follow `implementation_brief` as the primary implement guide; honor `custom_instructions` and check `dependency_status` before coding. `work_order_id` accepts `WO-NNN` or UUID.
- Run `update_artifact(dry_run=true)` before `update_artifact`; only call `journey_stage(action=approve)`, `journey_stage(action=reject)`, or `update_artifact` with explicit user intent.
- Only commit to and create PRs against repositories linked to the current project (`project_repos(action=list)`).
- Call `work_order(action=workflow_stages)` before manual `work_order(action=transition)` or filtering `work_order(action=list)` by status.
- Use `work_order_delivery(action=prepare_commit)` before committing to validate that changes align with the assigned work order scope.
- Run an RTM drift check before Forge-tagged commits; include results in `work_order(action=update)` field `rtm_drift_summary`.
- Call `work_order(action=update)` with full dev-activity fields after each meaningful commit — not only at completion.
- Link all pull requests to work orders using `work_order_delivery(action=create_pr)` for automatic progress tracking.
- Sync developer activity with `dev_activity(action=sync)` after push/PR and before `work_order(action=complete)`.
- Use `work_order_comments(action=list)` and `work_order_comments(action=comment)` (param `wo_id`) for WO discussion; use `clarifications(action=ask)` and `clarifications(action=list)` for team clarifications.
- Use `section_comments(action=add)` and `section_comments(action=list)` for artifact section feedback (distinct from work order comments).
- Do not make changes outside the scope of the active work order without explicit user approval.
