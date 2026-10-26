#!/bin/bash
# Forge pre-commit hook for Antigravity (plugin version).

input=$(cat)
command=$(echo "$input" | python3 -c "
import sys, json
d = json.load(sys.stdin)
args = d.get('toolCall', {}).get('args', {})
print(args.get('CommandLine', args.get('command', '')))
" 2>/dev/null)

if ! echo "$command" | grep -qE 'git\s+commit'; then
  echo '{"decision":"allow"}'
  exit 0
fi

if ! echo "$command" | grep -qE '\[(TASK|WO)-'; then
  echo '{"decision":"allow"}'
  exit 0
fi

PROJECT_DIR="."
# Prefer first workspace path from payload when present
ws=$(echo "$input" | python3 -c "
import sys, json
d = json.load(sys.stdin)
paths = d.get('workspacePaths') or []
print(paths[0] if paths else '')
" 2>/dev/null)
if [ -n "$ws" ]; then
  PROJECT_DIR="$ws"
fi

if [ -f "$PROJECT_DIR/.agents/hooks/forge-pre-commit.sh" ] || [ -f "$PROJECT_DIR/.cursor/hooks/forge-pre-commit.sh" ]; then
  echo '{"decision":"allow"}'
  exit 0
fi

if [ -f "$PROJECT_DIR/.forge-commit-ready" ]; then
  echo '{"decision":"allow"}'
  exit 0
fi

REASON='FORGE PRE-COMMIT CHECKLIST — Complete ALL steps before the commit can proceed.

## Step 0 — Forge MCP
Use your connected Forge MCP server (run /forge-status).

## Step 1 — Unit Tests
Ensure tests exist for staged sources, run them, fix failures when safe.

## Step 2 — Acceptance Criteria
Call work_order(action=get); mark each AC pass/partial/fail; ask user if incomplete.

## Step 3 — Report to Forge
Call work_order(action=update) with commit_summary, test_summary, and metrics.

## Step 4 — Mark Ready
Create .forge-commit-ready in the project root, then retry the git commit.'

python3 -c "import json,sys; print(json.dumps({'decision':'deny','reason':sys.argv[1]}))" "$REASON"
exit 0
