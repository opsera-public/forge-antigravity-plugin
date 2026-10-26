#!/bin/bash
# Forge Dangerous Operations Guard (Antigravity)

input=$(cat)
command=$(echo "$input" | python3 -c "
import sys, json
d = json.load(sys.stdin)
args = d.get('toolCall', {}).get('args', {})
print(args.get('CommandLine', args.get('command', '')))
" 2>/dev/null)

deny() {
  python3 -c "import json,sys; print(json.dumps({'decision':'deny','reason':sys.argv[1]}))" "$1"
  exit 0
}

ask() {
  python3 -c "import json,sys; print(json.dumps({'decision':'ask','reason':sys.argv[1]}))" "$1"
  exit 0
}

if echo "$command" | grep -qE 'git\s+push\s+.*--force'; then
  deny "Force push blocked by Forge safety guard. Ask the user to confirm and run it manually if needed."
fi

if echo "$command" | grep -qE 'rm\s+-rf\s+/'; then
  deny "Blocked: attempted recursive deletion from root filesystem."
fi

if echo "$command" | grep -qE 'kubectl\s+.*apply.*prod'; then
  ask "kubectl apply targeting a production namespace — review carefully before approving."
fi

echo '{"decision":"allow"}'
exit 0
