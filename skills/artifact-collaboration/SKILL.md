---
name: artifact-collaboration
description: >-
  Display, edit, and collaborate on Forge journey artifacts — formatted downloads,
  markdown updates, impact analysis, and inline section comments. Use when the
  user wants to view formatted artifacts, update PRD/BRD/intent, comment on
  artifact sections, or analyze downstream impact of changes.
---

# Artifact Collaboration

All tools are MCP tools on your **connected Forge MCP server** (discover via `/forge-status` — typically `user-forge` or `forge`; tools as `Forge MCP tool by name (server-scoped in Antigravity)`).

## When to Use

Activate this skill when the user:
- Wants a **formatted** artifact document (headers, metadata) — use `get_artifact(format=markdown)`
- Needs raw/latest artifact content quickly — use `get_artifact` (project-context skill)
- Plans to **edit** intent, prd, prd_spec, or brd markdown
- Wants to **comment** on a specific section of an artifact
- Asks what happens if they change an upstream artifact (impact analysis)

## Tools

| Tool | Purpose |
|------|---------|
| `get_artifact(format=markdown)` | Fully rendered markdown with headers and metadata |
| `update_artifact(dry_run=true)` | Preview downstream impact before editing |
| `update_artifact` | Write new markdown version (append-only; clears stage approval) |
| `section_comments(action=add)` | Inline comment on an artifact section |
| `section_comments(action=list)` | List comments for an artifact or section |
| `section_comments(action=resolve)` | Mark a section comment resolved |

## `get_artifact` vs `get_artifact(format=markdown)`

| Need | Tool |
|------|------|
| Agent briefing, quick read | `get_artifact` |
| Shareable formatted doc, export-style view | `get_artifact(format=markdown)` |

`get_artifact(format=markdown)` types: `assessment`, `intent`, `prd`, `prd_spec`, `brd`, `architecture`, `ui_design`, `work_orders`, `rtm`.

`get_artifact` types: `intent`, `prd`, `prd_spec`, `brd`, `architecture`, `ui_design`, `work_orders`, `rtm` (use `get_artifact(format=markdown)` for `assessment`).

## `update_artifact` Scope

Updatable via markdown: `intent`, `prd`, `prd_spec`, `brd` only.

`architecture`, `ui_design`, and `work_orders` require regeneration via `trigger_stage_generation` (journey skill).

## Section Comment `artifact_type` Values

| Value | Artifact |
|-------|----------|
| `INTENT_PROFILE` | Intent |
| `PRD_DRAFT` | PRD |
| `PRD_SPEC_DRAFT` | PRD-Spec |
| `BRD_DRAFT` | BRD |
| `ARCHITECTURE_OPTIONS` | Architecture |
| `UI_DESIGN_SPEC` | UI design |
| `TASK_BREAKDOWN` | Work orders breakdown |

## Parameters

### `update_artifact(dry_run=true)`
- `type` — `intent`, `prd`, `prd_spec`, or `brd`
- `proposed_changes` — natural language description of planned edits

### `update_artifact`
- `type` — `intent`, `prd`, `prd_spec`, or `brd`
- `updated_markdown` — full replacement markdown body

### `section_comments(action=add)`
- `artifact_type` — enum above
- `section_id` — section title or index
- `content` — comment text
- `highlighted_text` — optional annotated excerpt

### `section_comments(action=list)`
- `artifact_type` — required
- `section_id` — optional filter

### `section_comments(action=resolve)`
- `comment_id` — UUID of comment to resolve

## Workflows

### Safe artifact edit
1. `get_artifact` or `get_artifact(format=markdown)` — load current content
2. `update_artifact(dry_run=true)` with `proposed_changes` — show affected stages and approval resets
3. Confirm with user
4. `update_artifact` with full `updated_markdown`
5. Warn about downstream staleness; suggest `trigger_stage_generation` if needed

### Section comment thread
1. `section_comments(action=list)` for `artifact_type` (and optional `section_id`)
2. `section_comments(action=add)` to post new feedback
3. `section_comments(action=resolve)` when addressed

## Important

- **RBAC:** `update_artifact` and section comment tools require write access — confirm user intent.
- `update_artifact` clears the stage's approval flag and may stale downstream artifacts.
- Always run `update_artifact(dry_run=true)` before `update_artifact` unless the user explicitly skips impact review.
