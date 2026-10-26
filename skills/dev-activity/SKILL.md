---
name: dev-activity
description: >-
  Sync and validate developer activity in Forge — pull commits and PRs from
  linked repos, verify data consistency, and replay missed events. Use when the
  user wants to sync development activity, validate commit history, or recover
  from missed events.
---

# Developer Activity

All tools are MCP tools on your **connected Forge MCP server** (discover via `/forge-status` — typically `user-forge` or `forge`; tools as `<server>/<tool> (e.g. forge_mcp/work_order)`).

## When to Use

Activate this skill when the user:
- Asks to sync their commits or PRs to Forge
- Wants to verify that activity data is up to date
- Mentions gaps in tracked activity or missing events
- Asks about commit history alignment with Forge
- Is about to call `work_order(action=complete)` and needs merged PR data synced

## Tools

| Tool | Purpose |
|------|---------|
| `dev_activity(action=sync)` | Pull commits and PRs from linked repos, then replay projected events |
| `dev_activity(action=validate)` | Verify activity data is consistent and complete |
| `dev_activity(action=replay)` | Replay missed activity events for gap recovery |

## Lifecycle Placement

| When | Tool |
|------|------|
| After push or PR creation | `dev_activity(action=sync)` |
| Before `work_order(action=complete)` | `dev_activity(action=sync)` (ensure merged PR is visible; connector complete can also live-verify) |
| After PR merge | `dev_activity(action=sync)` → `work_order(action=complete)` → verify `work_order(action=get)` status |
| Suspected missing events | `dev_activity(action=validate)`, then `dev_activity(action=replay)` |
| Agent session ends | Plugin hook reminds to sync and complete merged WOs |

`work_order(action=update)` records commit/PR details at commit time; `dev_activity(action=sync)` keeps Forge's repo-level view current and can auto-complete linked merged PRs onto the board. Still call `work_order(action=complete)` and verify status.

## Workflow

1. Call `repo_setup(action=configure)` and `project(action=set)` before dev-activity tools.
2. After push/PR: `dev_activity(action=sync)` (optional: `repo_name`, `mode`, `from_timestamp`, `dry_run`).
3. If inconsistencies are suspected: `dev_activity(action=validate)` (optional: `repo_name`, `since`, `forge_only`).
4. For gap recovery: `dev_activity(action=replay)` (`mode`: `missing_only`, `from_timestamp`, or `full_project`).

## Parameters

**`dev_activity(action=sync)`**
- `repo_name` — optional `owner/repo` scope
- `mode` — `missing_only`, `from_timestamp`, or `full_project` (replay phase)
- `from_timestamp` — ISO lower bound when `mode=from_timestamp`
- `forge_only` — only treat forge-verified events as valid (default: true)
- `include_unverified` — include unverified events in replay (default: false)
- `dry_run` — preview replay changes without writing data
- `max_rows` — max canonical rows scanned per entity type

**`dev_activity(action=validate)`**
- `repo_name` — optional `owner/repo` scope
- `since` — ISO timestamp lower bound
- `forge_only` — apply forge-only validity policy (default: true)
- `max_rows` — max canonical rows scanned per entity type

**`dev_activity(action=replay)`**
- `repo_name`, `mode`, `from_timestamp`, `forge_only`, `include_unverified`, `dry_run`, `max_rows`
