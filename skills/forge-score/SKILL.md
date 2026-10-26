---
name: forge-score
description: >-
  Query ForgeScore codebase health metrics for a project — composite score,
  dimension breakdown, findings, and history. Use when the user asks about
  code health, ForgeScore, maturity level, or score trends over time.
---

# ForgeScore

All tools are MCP tools on your **connected Forge MCP server** (discover via `/forge-status` — typically `user-forge` or `forge`; tools as `<server>/<tool> (e.g. forge_mcp/work_order)`).

Backend may return `"ForgeScore not available in this deployment"` when scoring is not configured, or `"No ForgeScore available"` when no score has been run yet — suggest running a score from the Forge web UI first.

## When to Use

Activate this skill when the user:
- Asks about codebase health, quality score, or maturity
- Wants ForgeScore dimensions, findings, or surgical strikes
- Needs score history or trend over recent runs

## Tools

| Tool | Purpose |
|------|---------|
| `get_forge_score` | Latest scorecard: composite score, maturity, 8 dimensions, findings, strengths, surgical strikes |
| `get_forge_score(include_history=true)` | Recent scores showing how health changed over time |

## Parameters

### `get_forge_score`
- `project_id` — optional if project context is set

Returns: `composite_score`, `composite_maturity`, `dimensions`, `top_findings`, `top_strengths`, `surgical_strikes`, `scored_at`

### `get_forge_score(include_history=true)`
- `project_id` — optional if project context is set
- `limit` — optional (default 5, max 20)

## Workflow

1. `repo_setup(action=configure)` + `project(action=set)` if not done
2. `get_forge_score` — present summary stats and top findings
3. If user asks about trends: `get_forge_score(include_history=true)` with desired `limit`
4. Link findings to work orders via `/work` or `/forge-orders` if user wants remediation tasks

## Important

- ForgeScore must be generated at least once in the Forge web UI before MCP tools return data.
- Scores are read-only via MCP — no tool to trigger a new score run.

---

## Slash command workflow (`/forge-score`)

# Forge Score

Display the latest ForgeScore for the active project and optional score history.

## MCP prerequisite

Try `project(action=list)`. If unavailable or auth fails, **stop** and tell the user to run **`/forge-connect`**.

1. Call `repo_setup(action=configure)` with `{ "ide": "antigravity", "hooks_already_present": true }` plus `workspace_project_id` / numeric `hook_version` from `.forge/*` when present.
2. Ensure a project is set; if not, call `project(action=list)`, let the user choose, then `project(action=set)`.

## Steps

1. Call `get_forge_score` on the active project.
2. If no score exists, tell the user to run a ForgeScore from the Forge web UI first.
3. Present: composite score, maturity level, dimension breakdown, top findings, strengths, surgical strikes, `scored_at`.
4. If the user asks about trends, call `get_forge_score(include_history=true)` (default `limit`: 5).

## Output

Concise health briefing with actionable findings. Link remediation to `/work` or `/forge-orders` if the user wants tasks.

## MCP tools

`get_forge_score`, `get_forge_score(include_history=true)`

## Important

- ForgeScore is read-only via MCP — cannot trigger a new score run from the IDE.
- Handle `"ForgeScore not available in this deployment"` gracefully.
