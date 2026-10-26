---
name: forge-artifacts
description: Fetch, search, download, comment on, or update Forge journey artifacts — PRD, PRD-Spec, BRD, architecture, RTM, and more.
---

# Forge Artifacts

Retrieve, search, export, or collaborate on project artifacts from Forge.

## MCP prerequisite

Try `project(action=list)`. If unavailable or auth fails, **stop** and tell the user to run **`/forge-connect`**.

Ensure a project is set (`project(action=set)`).

## Usage

If the user did not specify what they want, ask:
- **Type** — `intent`, `prd`, `prd_spec`, `brd`, `architecture`, `ui_design`, `work_orders`, or `rtm`
- **Or search** — keywords to run `get_artifact(query=...)`
- **Or action** — download formatted doc, add section comment, or update content

## Steps

### Fetch by type

Call `get_artifact` with the requested `type`:

| Type | Document |
|------|----------|
| `intent` | Intent profile |
| `prd` | Product requirements |
| `prd_spec` | Product requirements specification |
| `brd` | Business requirements |
| `architecture` | Architecture options |
| `ui_design` | UI design specification |
| `work_orders` | Task breakdown |
| `rtm` | Requirements traceability matrix |

Return markdown content. Summarize long docs unless the user asked for the full document.

### Formatted download

Call `get_artifact(format=markdown)` when the user wants a fully formatted markdown export with headers and metadata.

Supported download types: `assessment`, `intent`, `prd`, `prd_spec`, `brd`, `architecture`, `ui_design`, `work_orders`, `rtm`.

### Search

Call `get_artifact(query=...)` with `query` (min 2 characters). Show matching snippets and artifact types.

### Section comments

- `section_comments(action=list)` — list comments for an artifact type
- `section_comments(action=add)` — post inline feedback on a section
- `section_comments(action=resolve)` — mark resolved

Artifact types for comments: `INTENT_PROFILE`, `PRD_DRAFT`, `PRD_SPEC_DRAFT`, `BRD_DRAFT`, `ARCHITECTURE_OPTIONS`, `UI_DESIGN_SPEC`, `TASK_BREAKDOWN`.

### Update artifact

1. `update_artifact(dry_run=true)` with `proposed_changes` — show impact
2. Confirm with user
3. `update_artifact` with full `updated_markdown` (intent, prd, prd_spec, brd only)

Architecture, ui_design, and work_orders require `trigger_stage_generation` via `/forge-journey`.

### UX references

If the user asks for design refs, call `get_artifact(ux_references=true)` (includes download URLs).

## Note

`get_artifact` and `get_artifact(format=markdown)` return the **latest** version only.
