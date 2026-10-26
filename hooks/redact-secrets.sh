#!/bin/bash
# Forge Sensitive File Warning (Antigravity) — non-blocking.

input=$(cat)

file_path=$(echo "$input" | python3 -c "
import sys, json
d = json.load(sys.stdin)
args = d.get('toolCall', {}).get('args', {})
print(args.get('AbsolutePath', args.get('TargetFile', args.get('path', ''))))
" 2>/dev/null)

if [ -z "$file_path" ]; then
  echo '{"decision":"allow"}'
  exit 0
fi

case "$file_path" in
  *.env|*.env.*|*credentials*|*secrets*|*.pem|*.key|*id_rsa*|*id_ed25519*)
    python3 -c "import json,sys; print(json.dumps({'decision':'allow','reason':sys.argv[1]}))" \
      "Warning: Reading a file that may contain secrets ($file_path). Sensitive values may be visible to the AI model."
    exit 0
    ;;
esac

echo '{"decision":"allow"}'
exit 0
