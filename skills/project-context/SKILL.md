---
name: project-context
description: >-
  Set up and query Forge project context — create new or modernize projects,
  select projects, list linked repos, manage artifacts, and configure
  repositories. Use when the user asks about project setup, creating a project
  from the IDE, modernizing legacy code, linked repositories, artifacts,
  UX references, journey state, project search, or wants to switch between projects.
---

# Project Context

All tools are MCP tools on your **connected Forge MCP server** (discover via `/forge-status` — typically `user-forge` or `forge`; tools as `<server>/<tool> (e.g. forge_mcp/work_order)`).

## When to Use

Activate this skill when the user:
- Wants to **build something new** or **modernize legacy code** from the IDE
- Asks "which project am I on?" or wants to switch projects
- Needs to list or link repositories
- Asks about project artifacts (PRD, BRD, architecture, RTM, work orders breakdown)
- Wants to search across project documentation
- Wants to search for a project by name or ref code
- Needs UX/design references or basic journey metadata
- Must load requirements before implementing a work order

## Tools

| Tool | Purpose |
|------|---------|
| `create_project` | Create a journey project (`new` or `refactor`) — returns `project_url`; does not generate artifacts |
| `list_my_connectors` | List Git connectors (no project required); empty → public URL still OK, or `connectors_url` for setup |
| `ingest_refactor_sources` | Ingest git/connector repos into a modernize project (does not start generation) |
| `project(action=set)` | Set active project for this MCP session |
| `project(action=list)` | List accessible projects with pagination and filters |
| `project(action=list)(query=...)` | Search projects by name, ref_code, intent, or type (up to 10 matches) |
| `project_repos(action=list)` | Repos linked to the current project |
| `project_repos(action=link)` | Link a new repository (ALM only — does not ingest code for assessment) |
| `get_journey_progress(include_raw_state=true)` | Basic journey step, ref code, and metadata |
| `repo_setup(action=configure)` | Session hooks gate; optionally restore project from `.forge/project-id` and upgrade hooks via `hook_version` |
| `get_artifact` | Retrieve the **latest** version of a journey artifact |
| `get_artifact(ux_references=true)` | UX/design reference images with download URLs |
| `get_artifact(query=...)` | Full-text search across all project artifacts |

## Create from the IDE

Same entry points as the Forge web home page Quick Start cards. Prefer **`/forge-create`**. After create, give the user `project_url` and stop — journey generation continues in the web UI, not from this command.

### Build something new

```
create_project with project_type="new", project_name="...", intent_draft="..."
```

- Sets session project automatically
- Returns `project_url` — tell the user to open it in the Forge web UI
- Does **not** start intent analysis or poll journey progress from the IDE

### Modernize legacy code

```
list_my_connectors
create_project with project_type="refactor", project_name="..."
ingest_refactor_sources with sources=[public_url or connector repo]
```

- Call `list_my_connectors` first, then **STOP and ask**. Do not call `create_project` until the user gives a public HTTPS git URL **or** a connector plus `owner/repo` (GitLab: `group/project`) and optional branch
- Show the connector list when non-empty; if empty, still allow a public git URL and print `connectors_url`
- No `intent_draft` required on create (server fills `Modernize: <project_name>`)
- `/forge-create` **does** call `ingest_refactor_sources` after create so the project has sources — do not send the user to the web UI to add sources
- Does **not** start assessment or any journey generation — return `project_url` and stop

## MCP Resources (read-only)

When a project is set, these URIs are also available as MCP resources:

- `forge://docs/introduction` — Forge overview
- `forge://docs/tools` — available MCP tools list
- `forge://project/{projectId}/intent` — latest intent profile
- `forge://project/{projectId}/prd` — latest PRD
- `forge://project/{projectId}/prd_spec` — latest PRD-Spec
- `forge://project/{projectId}/architecture` — latest architecture doc
- `forge://project/{projectId}/ui_design` — latest UI design spec

No MCP resource URI for `brd` — use `get_artifact` with `type: "brd"`. Prefer **`get_artifact`** in agent workflows; resources are useful for direct reads.

## `get_artifact` Types

The `type` parameter accepts:

| `type` value | Document |
|--------------|----------|
| `intent` | Intent profile / problem statement |
| `prd` | Product requirements document |
| `prd_spec` | Product requirements specification |
| `brd` | Business requirements document |
| `architecture` | Architecture options and decisions |
| `ui_design` | UI design specification |
| `work_orders` | Full task breakdown (epics/stories) |
| `rtm` | Requirements traceability matrix |

Returns the **latest** version only. Use `get_artifact(query=...)` to find content by keyword across artifacts.

## Parameters

### `create_project`
- `project_type` — required: `new` or `refactor`
- `project_name` — required display name
- `intent_draft` — required for `new` (product idea); omit for `refactor` (defaults to `Modernize: <project_name>`)
- `team_id` — optional team UUID
- `enabled_stages` — optional stage policy override

Returns `project_id`, `project_url`, `connectors_url`, `session_project_set`.

### `list_my_connectors`
- No parameters. Returns `connectors` (`id`, `label`, `type`), `connectors_url`, `ask_user`, `next`, and a setup `message` when empty.
- Empty does **not** block modernize — a public git URL is always allowed. After this call, **STOP and ask** for a source before `create_project`. Show the list when non-empty.

### `ingest_refactor_sources`
- `project_id` — optional if session project is set
- `sources` — required array of source objects
- `also_link_alm` — default `true`

Used by `/forge-create` after creating a refactor project. Ingests sources and may link ALM repos; does **not** start assessment or any journey generation.

### `project(action=list)`
- `limit` — max projects (default 20)
- `offset` — pagination skip (default 0)
- `search` — filter by name, intent, ref_code, or type
- `project_type` — `new`, `refactor`, or `migrate`
- `team_id` — filter by team UUID
- `completion` — `not_started`, `in_progress`, or `complete`

Returns `current_project`, `projects`, `total`, `limit`, `offset`.

### `project(action=list)(query=...)`
- `query` — search string (min 2 characters); returns up to 10 matches

### `repo_setup(action=configure)`
- `ide` — required; use `"antigravity"` for this plugin
- `hooks_already_present` — `true` when the marketplace plugin (or workspace hooks) already provide Forge guards
- `workspace_project_id` — optional; first line of `.forge/project-id` if present (auto-restores project context)
- `hook_version` — optional **JSON number** from `.forge/hook-version`. Missing/`non-number` is treated as `0`. With `hooks_already_present: true`, version below the server (currently **3**) returns `needs_update` even when marketplace hooks are present — write/overwrite returned files (including `.forge/hook-version`) so the next call can return `already_configured`.

Responses: `already_configured` (ready; may include restored `project_id` / `linked_repos`), `needs_update` / `needs_setup` (write or overwrite returned files, `chmod +x` scripts, merge `gitignore_entries`).

### `project_repos(action=link)`
Provide either:
- `git_url` — HTTPS clone URL (public repos), or
- `repo_full_name` (`owner/repo`) + `connector_id` (connector-based repos)

Optional: `default_branch` (defaults to `main`).

### `get_artifact(query=...)`
- `query` — search string (minimum 2 characters)

### `get_journey_progress(include_raw_state=true)`
Returns `current_step`, `ref_code`, `metadata`, and `project_name` for the active project.

## Pre-Implementation Context Load

Before coding on a work order:

1. `get_journey_progress(include_raw_state=true)` — basic journey step and ref code (use `get_journey_progress` from journey skill for full stage status)
2. `get_artifact` type `intent` — goals and scope
3. `get_artifact` type `prd` — product requirements
4. `get_artifact` type `architecture` — technical decisions
5. `get_artifact` type `ui_design` — when UI/design stage is present
6. `get_artifact` type `rtm` — traceability matrix (required for drift check before commit)
7. `get_artifact(query=...)` — when the user asks about a specific requirement by keyword
8. `get_artifact(ux_references=true)` — design refs; entries include `download_url` paths

## RTM Drift Check (before commit)

1. Call `get_artifact` with `type: "rtm"`
2. Find RTM rows linked to the current work order (also returned by `work_order(action=get)` as `traceability`)
3. For each row, compare implementation against linked PRD sections and architecture components
4. Record results in `work_order(action=update)` field `rtm_drift_summary` — per Req ID: artifacts compared, drift yes/no, details, resolution. If clean: `No drift detected — all RTM rows aligned with artifacts.`

## Workflow

1. Call `repo_setup(action=configure)` once per MCP session before work order operations:
   - Read `.forge/project-id` → pass as `workspace_project_id` when present
   - Read `.forge/hook-version` → pass as `hook_version` when present
   - **Marketplace plugin installed**: `{ "ide": "antigravity", "hooks_already_present": true, ...optional restore fields }`
   - **No plugin / fresh clone**: `{ "ide": "antigravity", ...optional restore fields }` — write returned hook files to the workspace
   - If `status` is `needs_update`, overwrite **all** returned files
2. Call `project(action=set)` only if project context was not restored (no `project_id` in configure response / no valid `.forge/project-id`).
3. After setting the project, call `project_repos(action=list)` to know which repos to work with.
4. Load artifacts with `get_artifact` before implementing scoped work.
5. When the user asks about design references, use `get_artifact(ux_references=true)`.

## Important

- All subsequent tool calls use the active project unless `project_id` is overridden.
- Linked repos are the ONLY repos that should be used for commits and PRs.
- Clone all linked repos before making code changes.
- Prefer `.forge/project-id` restore over re-prompting for project selection when the file is valid.
