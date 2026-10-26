---
name: forge-create
description: Create a Forge project from the IDE — build something new or modernize legacy code (same as the web home page).
---

# Forge Create

Create a journey project via MCP — same options as the Forge web home page (**Build something new** / **Modernize legacy code**). After create, give the user the project URL; they continue journey phases in the web UI. This command does **not** generate artifacts.

## MCP prerequisite

Try `project(action=list)`. If unavailable or auth fails, **stop** and tell the user to run **`/forge-connect`**.

Confirm `create_project` is available. If the tool is missing, tell the user their Forge API is outdated (needs the create/modernize MCP tools) and to restart the API / reconnect MCP.

## Ask the user (if not already clear)

1. **Mode**
   - **new** — build something new
   - **refactor** — modernize legacy code
2. **Project name** (required)
3. **Intent draft** — required only for **new** (product idea). Do **not** ask for intent when modernizing.

Do **not** invent a product idea. Ask if missing.

## Steps

### Build something new

1. Call `create_project` with:
   - `project_type`: `"new"`
   - `project_name`
   - `intent_draft`
2. Print `project_url` from the response.
3. Tell the user to open that URL in the Forge web UI to continue journey phases.
4. **Stop** — do not poll journey progress, `trigger_stage_generation`, `journey_stage(action=approve)`, or advance the pipeline from the IDE.

### Modernize legacy code

1. Call `list_my_connectors`.
2. **STOP and ask** (do not call `create_project` until they answer):
   - If the list is **non-empty**: present git connectors (GitHub, GitLab, Bitbucket, Azure DevOps) and ask the user to pick one **or** paste a public HTTPS git URL.
   - If the list is **empty**: they may still paste a public HTTPS git URL. Also print `connectors_url` so they can add a Git provider for private repos.
   - If they pick a connector, ask for `owner/repo` (GitLab: `group/project`) and optional branch (default `main`).
3. Do not proceed without a public URL **or** connector + repo. ZIP/folder/DB sources are out of scope here.
4. Call `create_project` with:
   - `project_type`: `"refactor"`
   - `project_name`
   - Do **not** pass `intent_draft` (server fills `Modernize: <project_name>`)
5. Call `ingest_refactor_sources` with the chosen public URL or connector repo. This does **not** start assessment or generation.
6. Print `project_url` from the create (or ingest) response.
7. Tell the user to open that URL in the Forge web UI to continue journey phases.
8. **Stop** — do not `trigger_stage_generation`, poll journey progress, or `journey_stage(action=approve)`.

## Output

Always print:

```
Forge Create
────────────
Mode            new | refactor
Project         <name> (<project_id>)
Session set     yes
Project URL     <project_url>
Next            open project URL in the Forge web UI
```

For modernize with no connectors, also print `Connectors URL` from `list_my_connectors`.

## MCP tools

`create_project`, `project(action=list)`, `list_my_connectors`, `ingest_refactor_sources`

## Important

- Do not create a **new** project without an explicit name and product intent from the user.
- For **refactor**, require an explicit name and a source (public git URL or connector + repo).
- After create, the MCP session project is set automatically — no separate `project(action=set)` needed unless switching.
- Do **not** run journey generation, polling, `journey_stage(action=approve)`, or `advance_journey` as part of `/forge-create`.
