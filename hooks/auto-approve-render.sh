#!/bin/bash
# Auto-approve safe Render CLI read operations to reduce permission fatigue
# This hook only auto-approves list/get/read operations - all modifications require permission

# Read the input from stdin
input=$(cat)

# Extract tool name and command from the JSON input
tool_name=$(echo "$input" | jq -r '.tool_name // empty')
command=$(echo "$input" | jq -r '.tool_input.command // empty')

# Only process Bash commands
if [ "$tool_name" != "Bash" ]; then
  exit 0
fi

# Only process render CLI commands
case "$command" in
  render\ *) ;;
  *) exit 0 ;;
esac

# Check for destructive keywords first - never auto-approve these
case "$command" in
  *delete*|*restart*|*create*|*deploy*|*update*|*set*|*suspend*|*resume*|*scale*)
    exit 0
    ;;
esac

# Whitelist of safe, read-only operations that should be auto-approved
case "$command" in
  "render services list"*|"render services -o json"*|"render services --output json"*)
    ;;
  "render logs -r"*|"render logs --raw"*)
    ;;
  "render workspace current"*|"render workspace list"*|"render workspace -o json"*|"render workspace --output json"*)
    ;;
  *)
    exit 0
    ;;
esac

# Command is safe - auto-approve it
cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow",
    "permissionDecisionReason": "Render read-only CLI operation auto-approved"
  }
}
EOF

exit 0
