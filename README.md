# Forge for Antigravity

Work orders, journey progress, artifacts, ForgeScore, dev activity, and project context for AI-assisted development in [Forge](https://app.softwareforge.ai).

This plugin ships workflow skills, an agent, rules, and lifecycle hooks. Forge MCP is bundled via `mcp_config.json`; your API token is prompted on install and kept in the OS keychain.

## Install

Clone and install from a local path:

```bash
git clone https://github.com/opsera-public/forge-antigravity-plugin.git
agy plugin install ./forge-antigravity-plugin
```

Or in the Antigravity app: **Customizations → Plugins → + Install from URL** and paste `https://github.com/opsera-public/forge-antigravity-plugin`.

When published to the official Antigravity Marketplace:

```bash
agy plugin install forge@antigravity-plugins-official
```

Confirm with `agy plugin list`, then reload the Antigravity window if skills do not appear.

## Connect Forge MCP (required)

The plugin bundles `mcp_config.json` (server `forge-mcp`). On install, Antigravity prompts for your **Forge API Token** and stores it in the OS keychain — no secrets live in the plugin. Create a token under **Connect IDE** → **API Tokens** at [app.softwareforge.ai](https://app.softwareforge.ai).

To use a different server definition instead, configure it manually (`serverUrl`, not `url` / `httpUrl`) in `~/.gemini/config/mcp_config.json` (user) or `.agents/mcp_config.json` (project).

## Skills & slash entry points

| Slash | Purpose |
|-------|---------|
| `/forge-connect` | Connect MCP, configure session, select project |
| `/forge-status` | Validate MCP and print a readiness report |
| `/forge-create` | Create or modernize a Forge project |
| `/forge-context` | Load journey, repos, and key artifacts |
| `/forge-artifacts` | Fetch, search, comment on, or update artifacts |
| `/forge-journey` | Journey stages, approvals, generation, chat |
| `/forge-score` | ForgeScore health metrics |
| `/forge-orders` | Browse work orders |
| `/forge-sync` | Sync commits/PRs to Forge |
| `/work` | Pick or show the next work order |
| `/start-work` | Full implement → commit → PR → complete flow |

Domain skills (progressive disclosure): `work-orders`, `project-context`, `journey`, `artifact-collaboration`, `dev-activity`, `forge-score`.

Hooks enforce the same safety policies via Antigravity `PreToolUse` (on `run_command` / `view_file`) and `Stop` events.

## First session

1. Run `/forge-status` (or `/forge-connect` if disconnected).
2. Call `repo_setup(action=configure)` once per session when this plugin is installed:

```json
{
  "ide": "antigravity",
  "hooks_already_present": true,
  "workspace_project_id": "<optional: first line of .forge/project-id>",
  "hook_version": <integer from .forge/hook-version if present>
}
```

Pass `hook_version` as a **JSON number** from `.forge/hook-version` when present.

## Author & links

| | |
|--|--|
| **Author** | Forge (`hi@softwareforge.ai`) |
| **Homepage** | https://app.softwareforge.ai |
| **Repository** | https://github.com/opsera-public/forge-antigravity-plugin |
| **License** | Apache-2.0 |
