---
name: forge-sync
description: Sync commits and PRs from linked repos to Forge — run after push or before completing a work order.
---

# Forge Sync

Sync developer activity from linked repositories into Forge.

## MCP prerequisite

Try `project(action=list)`. If unavailable or auth fails, **stop** and tell the user to run **`/forge-connect`**.

1. Call `repo_setup(action=configure)` with `{ "ide": "antigravity", "hooks_already_present": true }` plus `workspace_project_id` / numeric `hook_version` from `.forge/*` when present.
2. Ensure a project is set (`project(action=set)`); if not, run **`/forge-connect`** first.

## Steps

1. Call `dev_activity(action=sync)` (optional: `repo_name` as `owner/repo`, `mode`: `missing_only` | `from_timestamp` | `full_project`).
2. If the user reports missing events or stale data, call `dev_activity(action=validate)`.
3. If validation shows gaps, call `dev_activity(action=replay)` with `mode: missing_only` (or `from_timestamp` if they give a date).

## Report

Print a short summary:
- Repos synced (or scoped repo)
- Whether validation passed
- Whether replay was needed
- Reminder: run again after the next push or before `work_order(action=complete)`

## When to use

- After `git push` or creating a PR
- Before `work_order(action=complete)` (merged PR must be visible in Forge)
- When Forge activity looks out of date
