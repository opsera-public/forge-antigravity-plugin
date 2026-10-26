---
name: forge-status
description: Validate Forge MCP connection and print a readiness status report — includes install steps if disconnected.
---

# Forge Status

Validate the **live** Forge MCP connection and print a status report.

This plugin **bundles** the Forge MCP server (shown as `forge_mcp`). On enable, Antigravity prompts for your Forge API token — paste only the token (starts with `forge_`), without a `Bearer` prefix. Servers from user/global (`~/.gemini/config/mcp_config.json`) or project (`.agents/mcp_config.json`) config also count — discover all of them before testing.

## Critical rule — tool call is the only truth

**Never** mark MCP connected or disconnected based on:
- **Settings → Plugins** (plugin hooks/skills only — no MCP credentials)
- A red/errored row in **Customizations → MCP / Plugins** without trying a tool call
- Assuming tools must be named `<server>/<tool> (e.g. forge_mcp/work_order)` when they may be `<server>/<tool> (e.g. forge_mcp/work_order)`

**Always** discover servers from config + session, then **call `project(action=list)`** until one succeeds.

## Discover Forge MCP servers

Check **both** scopes and merge server names:

| Scope | Config file | Typical server name |
|-------|-------------|---------------------|
| User / global | `~/.gemini/config/mcp_config.json` | `user-forge` (one-click) or `forge` (manual) |
| Project | `.agents/mcp_config.json` (workspace root) | team-defined name, often `forge` |

```bash
for f in "$HOME/.gemini/config/mcp_config.json" ".agents/mcp_config.json"; do
  [ -f "$f" ] && echo "=== $f ===" && jq -r '.mcpServers // {} | to_entries[] | "\(.key)\t\(.value.url // .value.serverUrl // "")"' "$f" 2>/dev/null
done
```

Include a server if:
- name is `user-forge`, `forge`, or contains `forge`, OR
- `url` or `serverUrl` contains `forge.opsera.ai` or `/api/mcp`

Also include enabled Forge MCP servers visible in this session (MCP tool list / **Customizations → MCP / Plugins**).

**Try order:** `forge_mcp` (bundled with this plugin) → `user-forge` → `forge` → other user-config servers → project-config servers → session-only servers.

First server where **`project(action=list)`** succeeds = **`active_forge_mcp`**.

## Validation sequence

Run these checks in order. Record pass/fail for each.

### 1. MCP tool availability

Call **`project(action=list)`** on each candidate in try order.

| Result | Status | Meaning |
|--------|--------|---------|
| Returns project list | **pass** | Live Forge MCP connected and authenticated |
| Tool not found on all candidates | **fail** | No Forge MCP in user/project config or session |
| 401 / unauthorized | **fail** | Token missing, invalid, or expired |

If **fail**, skip remaining checks. Print install steps (see below) and the status report with overall **Not ready**.

### 2. Session hooks gate (only if Step 1 passed)

Try `work_order(action=list)` on **`active_forge_mcp`**.

| Result | Status |
|--------|--------|
| Returns data | **pass** — session configured |
| Error mentioning `repo_setup(action=configure)` | **fail** — report **needed**; recommend `/forge-connect` |

Do not call `repo_setup(action=configure)` automatically unless the user asks. When advising a fix, include workspace restore:

```json
{
  "ide": "antigravity",
  "hooks_already_present": true,
  "workspace_project_id": "<.forge/project-id if present>",
  "hook_version": <integer from .forge/hook-version if present>
}
```

Pass `hook_version` as a **JSON number** from `.forge/hook-version` (omit the field if that file is missing — expect `needs_update` on first bootstrap). Do not hardcode the version.

### 3. Active project (only if Step 1 passed)

From `project(action=list)` response, read `current_project` if present; otherwise call `get_journey_progress(include_raw_state=true)` on **`active_forge_mcp`**.

Also note whether **`.forge/project-id`** / **`.forge/hook-version`** exist in the workspace (informational — enables auto-restore on next `/forge-connect`).

| Result | Status |
|--------|--------|
| Project name/ID available | **pass** |
| No project set | **warn** — user should run `/forge-connect` (or restore via `.forge/project-id`) |

## If MCP validation failed — install steps

Print this and stop further validation:

---

**Forge MCP is not connected.**

1. [https://forge.opsera.ai](https://forge.opsera.ai) → **Install in IDE** → **Antigravity**
   - Application Context → **Connect IDE**, **Project Settings** → **Connect IDE**, or **User Settings** → **API Tokens**
2. Accept the MCP install prompt in Antigravity (writes to **`~/.gemini/config/mcp_config.json`**)
3. Confirm **Customizations → MCP / Plugins** shows a Forge server **green** (`user-forge` or `forge`)
4. Run **`/forge-status`** again

**Project-scoped alternative:** add `.agents/mcp_config.json` in the repo with the same Forge server JSON (see `/forge-connect`).

---

## Status report (always print this)

After validation, print a concise report like this:

```
Forge Status
────────────
MCP connection      ✅ Connected  |  ❌ Not connected  |  ⚠️ Auth failed
MCP server used     user-forge  (active_forge_mcp — whichever answered project(action=list))
MCP server version  forge-mcp (60 tools: 27 core / 33 shipping)
Config sources      user: ~/.gemini/config/mcp_config.json  |  project: .agents/mcp_config.json (present/absent)
API endpoint        https://forge.opsera.ai/api/mcp
Projects accessible ✅ N projects  |  ❌
Session configured  ✅ / ⚠️ Needed / ❓ Unknown
Active project      <name + ref or "not set">
Workspace restore   .forge/project-id: present/absent  |  .forge/hook-version: <n or absent>
Plugin (workflow)   ✅ Installed (marketplace) / ❓ Check Settings → Plugins → Forge
Optional tools      ForgeScore / Journey / Artifact edit — probe if user needs them

Overall             ✅ Ready for /work  |  ⚠️ Almost ready  |  ❌ Not ready

Next step           /work  |  /forge-context  |  /forge-journey  |  /forge-connect  |  Install MCP (steps above)
```

Use plain text if emoji are not appropriate. **Only mark Connected if `project(action=list)` succeeded** on a discovered server.

### Optional capability probes (if user asks)

After core checks pass, optionally probe one tool per category — report pass or "not available":
- Journey: `get_journey_progress`
- ForgeScore: `get_forge_score`
- Artifact edit: `section_comments(action=list)` with a known artifact type (or skip if no project)

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| No Forge server in user or project mcp.json | Forge → **Install in IDE → Antigravity** (user/global) |
| Project mcp.json exists but tools missing | reload Antigravity; confirm server URL is `https://forge.opsera.ai/api/mcp` |
| `<server>/<tool> (e.g. forge_mcp/work_order)` not found but `user-forge` tools exist | Use **user-forge** — connection is fine; prefix follows server name |
| User says connected but tool fails | Re-run discovery on both mcp.json files; call `project(action=list)` — do not trust UI alone |
| Work orders blocked after MCP ok | Run `repo_setup(action=configure)` with `hooks_already_present: true` (+ `workspace_project_id` / `hook_version` from `.forge/*` if present) |
| Project lost after reload / pod restart | Read `.forge/project-id` → `repo_setup(action=configure)` with `workspace_project_id` |
| Hooks outdated (`needs_update`) | Overwrite returned files; keep `.forge/hook-version` in sync |
| Token expired | Forge → **Connect IDE** → new token → reinstall in Antigravity |
