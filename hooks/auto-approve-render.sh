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
  *delete*|*remove*|*restart*|*create*|*deploy*|*update*|*set*|*suspend*|*resume*|*scale*|*stop*|*start*|*rollback*|*promote*|*cancel*)
    exit 0
    ;;
esac

# Whitelist of safe, read-only operations that should be auto-approved
# Uses word boundaries where possible to avoid false matches

# Extract the subcommand (second word) for easier matching
subcommand=$(echo "$command" | awk '{print $2}')
action=$(echo "$command" | awk '{print $3}')

case "$subcommand" in
  # Info commands - always safe
  version|help|--help|-h|--version|-v|whoami|regions)
    ;;

  # Resource listing and viewing
  services|deploys|postgres|redis|keyval|jobs|cron|blueprints|env|domains|headers|routes|disks)
    case "$action" in
      list|show|get|info|tail|""|--*)
        # Empty action or flags after resource = likely a list/show operation
        ;;
      *)
        exit 0
        ;;
    esac
    ;;

  # Logs - viewing is safe
  logs)
    ;;

  # Workspace operations - list/show/current are safe
  workspace)
    case "$action" in
      list|current|show|get|""|--*)
        ;;
      *)
        exit 0
        ;;
    esac
    ;;

  # SSH/shell access - requires explicit permission
  ssh|shell|exec)
    exit 0
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
