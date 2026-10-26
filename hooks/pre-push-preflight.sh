#!/bin/bash
# Forge Pre-Push Preflight (Antigravity) — advisory allow + reason.

input=$(cat)
command=$(echo "$input" | python3 -c "
import sys, json
d = json.load(sys.stdin)
args = d.get('toolCall', {}).get('args', {})
print(args.get('CommandLine', args.get('command', '')))
" 2>/dev/null)

if ! echo "$command" | grep -qE 'git\s+push'; then
  echo '{"decision":"allow"}'
  exit 0
fi

python3 -c 'import json; print(json.dumps({
  "decision": "allow",
  "reason": "Forge reminder: After pushing, run dev_activity(action=sync) (/forge-status). Link the PR with work_order_delivery(action=create_pr). After merge, call work_order(action=complete) (WO-NNN) and verify with work_order(action=get)."
}))'
exit 0
