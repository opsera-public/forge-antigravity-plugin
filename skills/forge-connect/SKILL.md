---
name: forge-connect
description: Install and connect the Forge MCP server (one-click install), verify auth, configure session, and select your project.
---

# Forge Connect

Set up the **live** Forge MCP connection (separate from this Antigravity plugin) and select your active project.

This plugin ships hooks, skills, and commands only — **MCP is configured in user or project Antigravity settings**, not bundled with the plugin.

## Step 0 — Discover Forge MCP servers

Before any Forge tool call, find which MCP server is connected. Check **both** config scopes and merge results:

| Scope | Config file |
|-------|-------------|
| **User / global** | `~/.gemini/config/mcp_config.json` |
| **Project** | `.agents/mcp_config.json` in the workspace root (if present) |

Run (or equivalent):

```bash
for f in "$HOME/.gemini/config/mcp_config.json" ".agents/mcp_config.json"; do
  [ -f "$f" ] && echo "=== $f ===" && jq -r '.mcpServers // {} | to_entries[] | "\(.key)\t\(.value.url // .value.serverUrl // "")"' "$f" 2>/dev/null
done
```

Collect server names that match **any** of:
- name is `user-forge` or `forge`
- name contains `forge` (case-insensitive)
- `url` or `serverUrl` contains `forge.opsera.ai` or ends with `/api/mcp`

Also add any **enabled Forge MCP servers** visible in this Antigravity session (e.g. under **Customizations → MCP / Plugins**, or MCP tool descriptors whose server name/id contains `forge`).

**Try order** (dedupe, first match wins):
1. `user-forge` — Forge **Install in IDE → Antigravity** (most common)
2. `forge` — manual `~/.gemini/config/mcp_config.json`
3. Any other Forge servers from user config, then project config
4. Any remaining Forge servers from the session tool list

Record the server that succeeds as **`active_forge_mcp`** — use it for all Forge tools this session (`Forge MCP tool by name (server-scoped in Antigravity)`).

## Step 1 — Test connection

Call **`project(action=list)`** on each candidate server in try order until one succeeds.

| Result | Action |
|--------|--------|
| Returns project list | Note **`active_forge_mcp`**; skip to Step 3 |
| Tool not found on all candidates | Go to Step 2 |
| 401 / auth error | Go to Step 2 |

**Never** infer connection status from UI alone — the tool call is the only truth.

## Step 2 — Guide MCP install (stop and wait)

Do **not** call Forge tools until MCP is connected. Print this to the user:

---

**Forge MCP is not connected yet.** Connect it once using Forge one-click install:

1. Open [https://forge.opsera.ai](https://forge.opsera.ai) and sign in.
2. Go to **Connect IDE** using any of:
   - **Application Context** → **Connect IDE** tab
   - **Project Settings** → **Connect IDE**
   - **User Settings** (avatar menu) → **API Tokens**
3. Click **Install in IDE** → choose **Antigravity**.
   - Forge creates a `forge_...` API token and opens Antigravity automatically.
   - Accept the MCP install prompt in Antigravity.
4. Confirm **Customizations → MCP / Plugins** shows a Forge server connected (green) — usually **`user-forge`**.

**Alternative (same tab):** **Create an API Token** → copy token → click **Install in Antigravity** under **One-Click Install**.

**Manual fallback — user/global** (`~/.gemini/config/mcp_config.json`):

```json
{
  "mcpServers": {
    "forge": {
      "serverUrl": "https://app.softwareforge.ai/api/mcp",
      "headers": {
        "Authorization": "Bearer forge_..."
      }
    }
  }
}
```

**Manual fallback — project-only** (`.agents/mcp_config.json` in repo root): same JSON shape; use when a team pins Forge MCP per project. Forge **Install in IDE** may write an equivalent shape — prefer that when available.

After installing, **reload Antigravity** (reload the Antigravity window or restart the agent) if tools still do not appear.

Reply **"done"** or run **`/forge-connect`** again when **Customizations → MCP / Plugins** shows a Forge server green.

---

Wait for the user to confirm before continuing.

## Step 3 — Configure session hooks (with workspace restore)

Before calling `repo_setup(action=configure)`, gather optional workspace context:

1. If **`.forge/project-id`** exists at the workspace root, read its first line → `workspace_project_id` (auto-restores project without `project(action=set)`).
2. If **`.forge/hook-version`** exists, read it as a **JSON number** → `hook_version` (server compares against its current version).

Call `repo_setup(action=configure)` on **`active_forge_mcp`** with (marketplace plugin installed):

```json
{
  "ide": "antigravity",
  "hooks_already_present": true,
  "workspace_project_id": "<from .forge/project-id if present>",
  "hook_version": <integer from .forge/hook-version if present>
}
```

- Always pass `hook_version` as a **JSON number** (never a string). Read the integer from `.forge/hook-version` — do not hardcode a constant.
- Omit `workspace_project_id` when `.forge/project-id` is absent.
- Omit `hook_version` only when `.forge/hook-version` is absent — the server treats a missing version as `0`, so with `hooks_already_present: true` the first call typically returns **`needs_update`** (expected bootstrap). Write all returned files (including `.forge/hook-version`), then later sessions pass that file's number for `already_configured`.
- Use `{ "ide": "antigravity" }` without `hooks_already_present` only if the marketplace plugin is **not** installed.

| Response `status` | Action |
|-------------------|--------|
| `already_configured` | Session ready; note returned `project_id` / `project_name` / `linked_repos` if auto-restored |
| `needs_update` | Overwrite **all** returned files (`.forge/hook-version`, workspace `.agents/*`, native git hooks, rules); `chmod +x` scripts; merge `gitignore_entries` into `.gitignore`. Marketplace `pre-commit-validate.sh` defers when `.agents/hooks/forge-pre-commit.sh` exists. |
| `needs_setup` (no plugin / fresh) | Write files, `chmod +x` scripts, then continue |

Honor `workspace_project_warning` / `workspace_project_note` if present — fall through to Step 4 when restore fails or is invalid.

## Step 4 — Select project (if not already set)

Skip this step when Step 3 already set a project via `workspace_project_id`.

1. Call `project(action=list)` on **`active_forge_mcp`** (optional: `search`, `limit`, `offset`, `project_type`, `completion` filters).
2. If the user names a project, try `project(action=list)(query=...)` with their query first.
3. Show the list and ask which project to use.
4. Call `project(action=set)` with the chosen project ID.

## Step 5 — Confirm ready

Call `project_repos(action=list)` and report:

- MCP server: **`active_forge_mcp`**
- MCP connected: yes (forge-mcp v2.0.0)
- Session configured: yes
- Active project: name + ID (restored from workspace or user-selected)
- Linked repos: list or "none — link repos in Forge"

Suggest **`/work`**, **`/start-work`**, **`/forge-context`**, **`/forge-journey`**, **`/forge-score`**, or **`/forge-orders`** as the next step.
