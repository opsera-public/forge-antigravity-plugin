---
name: work-orders
description: >-
  Manage Forge work orders — list, pick, update, transition, and complete
  development tasks. Use when the user asks about their current task, next work
  item, wants to update progress, create PRs, prepare commits, post comments,
  ask clarifications, or manage workflow stages.
---

# Work Orders

All tools are MCP tools on your **connected Forge MCP server** (discover via `/forge-status` — typically `user-forge` or `forge`; tools as `Forge MCP tool by name (server-scoped in Antigravity)`).

## When to Use

Activate this skill when the user:
- Asks "what should I work on next?" or "what's my current task?"
- Wants to browse or filter work orders by status or priority
- Wants to update progress or report dev activity after a commit
- Is ready to commit and wants a formatted commit message
- Wants to create a PR linked to their work order
- Asks about workflow stages or work order statistics
- Wants to post or read comments on a work order
- Needs to ask a clarification question visible in the Forge UI

## Tools

| Tool | Purpose |
|------|---------|
| `work_order(action=list)` | List tasks; filter by `status`, `priority`; `include_unassigned=true` for claimable stories |
| `work_order(action=get)` | Enriched details — `implementation_brief`, dependencies, models, RTM; accepts `WO-NNN` or UUID |
| `work_order(action=start)` | 0/1/many gate — resume one assigned, ask when multiple, list unblocked unassigned when none; pass `work_order_id` after user picks to claim/start; `dry_run=true` for read-only |
| `work_order(action=update)` | Update fields and report post-commit dev activity |
| `work_order(action=transition)` | Manually move to the next valid workflow stage |
| `work_order(action=complete)` | Mark done (requires synced merged PR, or `user_confirmed_complete_without_merged_pr: true`) |
| `work_order(action=workflow_stages)` | Canonical stage definitions, order, and allowed transitions |
| `work_order_delivery(action=prepare_commit)` | Generate `[WO-...]` commit message (requires `work_order_id`) |
| `work_order_delivery(action=create_pr)` | Generate PR title/body, record activity, return CLI command — does not open the PR on the host |
| `clarifications(action=ask)` | Post a clarification question (visible in Forge UI for team answers) |
| `clarifications(action=list)` | List clarification Q&A for the project |
| `work_order_comments(action=comment)` | Post a comment on a work order thread (optional AI reply) |
| `work_order_comments(action=reply)` | Reply to an existing work order comment (no AI) |
| `work_order_comments(action=list)` | List all comments and AI responses on a work order |

## Tool Distinctions

- **`work_order(action=start)`** — **0/1/many gate**: multiple incomplete assigned → `needs_user_choice` (ask which WO); one assigned → resume/start it; zero assigned → `unassigned_stories` (unblocked only). After the user picks, call again with `work_order_id` to claim (if needed) and start — dual-writes assignee so the ALM board Assignee updates. Use `dry_run=true` for a read-only preview.
- **`work_order(action=transition)`** — manual stage move. Call **`work_order(action=workflow_stages)`** first for valid `status` keys and transition rules.
- **`work_order(action=update)`** — post-commit activity report with git-derived fields and `rtm_drift_summary`. **Not** the same as `work_order(action=complete)`.
- **`work_order(action=complete)`** — terminal step after PR is merged and synced (or explicit user override).
- **`clarifications(action=ask)`** vs **`work_order_comments(action=comment)`** — clarifications for team Q&A (`clarifications(action=ask)` / `clarifications(action=list)`) vs threaded WO discussion (`work_order_comments(action=comment)` / `work_order_comments(action=list)`).
- **ID formats:** `work_order(action=get)` (and most WO tools) accept `work_order_id` as **`WO-NNN` or UUID**. Comment tools use `wo_id` (human label, e.g. `WO-001`). `clarifications(action=list)` filters by `task_id` (UUID) or `artifact_id`.

## Enriched `work_order(action=get)` response

Treat these fields as first-class when implementing:

| Field | How to use |
|-------|------------|
| `implementation_brief` | **Primary implement guide** — reading order, execution protocol, present/missing fields |
| `custom_instructions` | User requirements **beyond** acceptance criteria — honor them |
| `dependency_status` / `dependency_warning` | Check blockers before coding; warn user if deps incomplete |
| `recommended_models` | Optional model hints from complexity |
| Hydrated story fields | `current_behavior`, `target_behavior`, `technical_details`, `implementation_hints`, `edge_cases`, etc. |
| `traceability` | RTM rows when available |
| `wo_id` | Human-readable label echoed when resolved from `WO-NNN` |

## Parameters

### `work_order(action=get)`
- `work_order_id` — **`WO-003` or UUID**
- `project_id` — optional if project context is set

### `work_order(action=list)`
- `status` — workflow status key (call `work_order(action=workflow_stages)` for valid values)
- `priority` — `critical`, `high`, `medium`, `low`

### `work_order(action=transition)`
- `work_order_id` — `WO-NNN` or UUID
- `status` — must be the **next** valid stage from current status
- `notes` — optional transition note

### `work_order_comments(action=comment)`
- `wo_id` — human work order label (e.g. `WO-001`), not UUID
- `content` — comment text
- `trigger_ai` — `true` (default) triggers an AI reply; `false` posts only

### `work_order_comments(action=reply)`
- `wo_id`, `comment_id`, `content`

### `work_order_comments(action=list)`
- `wo_id` — human work order label

### `clarifications(action=ask)`
- `question` — required
- `work_order_id` or `artifact_id` — optional attachment

### `clarifications(action=list)`
- `artifact_id` or `task_id` — optional filter

### `work_order_delivery(action=create_pr)`
- `work_order_id` — required
- `branch_name`, `changes_summary`, `repo_url`, `repo_name` — recommended
- `pr_url`, `pr_number` — pass if PR already exists on the host (**required** for public `git_url` links so the public SCM gate can verify)
- Moves the WO to review. `work_order(action=update)` with PR fields alone does **not** change status.

### `work_order(action=update)` (post-commit dev activity)

After committing, call with `work_order_id` plus the dev-activity fields Forge expects:

- `commit_summary` — what changed (files, features, refactors)
- `test_summary` — test results (run, passed, failed, fixes)
- `rtm_drift_summary` — RTM drift check results (see project-context skill)
- `repo_url` — from `git remote get-url origin`
- `repo_name` — `owner/repo` parsed from URL
- `branch_name` — from `git branch --show-current`
- `commit_hash` — from `git rev-parse HEAD`
- `commit_message` — full message used
- `commit_author` — from `git config user.name`
- `files_changed`, `lines_added`, `lines_removed`, `changed_files` — from `git diff HEAD~1`
- `tests_total`, `tests_passed`, `tests_failed`, `tests_skipped`, `test_coverage`
- `pr_url`, `pr_number` — after PR is created

Optional field updates: `status`, `priority`, `title`, `description`, `assignee_id`, `story_points`, `wo_type`.

## Workflows

### Browse tasks
1. `work_order(action=workflow_stages)` — learn valid status keys
2. `work_order(action=list)` with `status` / `priority` filters
3. `work_order(action=get)` with `work_order_id` (`WO-NNN` or UUID) for full details

### Start next task
1. `repo_setup(action=configure)` (pass `workspace_project_id` / `hook_version` from `.forge/*` when present) → `project(action=set)` only if needed
2. `work_order(action=start)` (use `dry_run=true` for read-only)
   - If `needs_user_choice`: present `assigned_stories` and STOP until the user picks a `work_order_id`, then call `work_order(action=start)` with that id
   - If `unassigned_stories`: present the list, STOP until the user picks, then call `work_order(action=start)` with that `work_order_id` to claim and start
   - If a single story is returned: continue
3. `work_order(action=get)` when full context is missing — follow **`implementation_brief`**; check `dependency_status` and `custom_instructions`
4. `project_repos(action=list)` — clone repos before coding

### Comments and clarifications
- **Thread:** `work_order_comments(action=list)` → `work_order_comments(action=comment)` or `work_order_comments(action=reply)`
- **Team Q&A:** `clarifications(action=ask)` → later `clarifications(action=list)`

### Full commit → PR → complete lifecycle
1. `work_order(action=get)` — use `implementation_brief` + AC + `custom_instructions`
2. Load artifacts (see project-context skill): `get_artifact` types `intent`, `prd`, `prd_spec`, `architecture`, `ui_design`, `rtm` as needed
3. Implement and test (honor dependency warnings)
4. RTM drift check — compare implementation against RTM rows linked to this WO
5. `work_order_delivery(action=prepare_commit)` with `work_order_id` → commit with returned `[WO-...]` message
6. `work_order(action=update)` with full dev-activity fields and `rtm_drift_summary`
7. Push
8. Open the PR/MR on the host (`gh` / `glab` / UI), then `work_order_delivery(action=create_pr)` with `pr_url` and/or `pr_number` (required for public git_url links)
9. **`dev_activity(action=sync)`** scrapes PRs/commits for connector-linked and public git_url links (GitHub, GitLab, Bitbucket, Azure DevOps cloud). Retry if blocked. Public create/complete still use the public SCM gate with `pr_number`/`pr_url` when needed.
10. **After PR merges** (you merged or the user said it merged) — do not wait for the user to remind you:
    1. Prefer `work_order_id` as **`WO-NNN`** (not `work_order(action=list).id` / WOI UUID). Use `task_id` only when you need the tasks UUID.
    2. `dev_activity(action=sync)` (retry once if blocked)
    3. `work_order(action=complete)` with `pr_number` when known — connector repos live-verify merge if sync is stale; public git_url uses the public gate
    4. **Verify** with `work_order(action=get)` — stop only when `status === "completed"`. Never tell the user it is done if get still shows `in_progress` / `in_review`. If complete said "already completed" but get disagrees, call `work_order(action=complete)` again (heal) or report the mismatch.

### ID formats (avoid dual-UUID trap)
- Prefer **`WO-NNN`** for all write tools (`work_order(action=complete)`, `work_order(action=update)`, …)
- `work_order(action=list)` / `work_order(action=get)` may return `id` (work_order_items UUID), `task_id` (tasks UUID), and `wo_id` — do not pass WOI `id` when you mean `WO-NNN`

## Prerequisites

0. Call `repo_setup(action=configure)` once per session before any work order tool:
   - **Marketplace plugin installed**: `{ "ide": "antigravity", "hooks_already_present": true }` plus optional `workspace_project_id` / `hook_version` from `.forge/*`
   - **No plugin**: `{ "ide": "antigravity" }` — write returned hook files to the workspace
1. Ensure a project is set (via restore or `project(action=set)`) before querying work orders.
