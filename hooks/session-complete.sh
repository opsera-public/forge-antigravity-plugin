#!/bin/bash
# Forge Session Complete Hook (Antigravity Stop event)

set -euo pipefail

input=$(cat)

echo "$input" | python3 -c '
import json
import os
import sys

REMINDER = (
    "Session complete. If you made commits or created PRs, run dev_activity(action=sync) on your Forge MCP server "
    "(see /forge-status). If a PR was merged for a work order, also call work_order(action=complete) with WO-NNN "
    "(and pr_number), then verify with work_order(action=get) that status is completed before ending."
)

def allow_stop() -> None:
    print(json.dumps({"decision": "allow"}))
    sys.exit(0)

try:
    data = json.load(sys.stdin)
except json.JSONDecodeError:
    allow_stop()

# Only remind when the agent is fully idle after a normal stop
if data.get("fullyIdle") is False:
    allow_stop()

termination = data.get("terminationReason") or ""
if termination in ("error", "max_steps_exceeded"):
    allow_stop()

conversation_id = data.get("conversationId") or "unknown"
state_dir = os.path.join(os.path.expanduser("~"), ".gemini", "forge-hook-state")
os.makedirs(state_dir, exist_ok=True)
sentinel = os.path.join(state_dir, f"session-reminder-{conversation_id}")

if os.path.exists(sentinel):
    allow_stop()

with open(sentinel, "w", encoding="utf-8") as f:
    f.write("1\n")

print(json.dumps({"decision": "continue", "reason": REMINDER}))
'

exit 0
