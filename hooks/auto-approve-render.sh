#!/bin/bash
# Auto-approve safe Render CLI read operations to reduce permission fatigue
# This hook only auto-approves list/get/read operations - all modifications require permission
#
# An allow decision covers the entire string the shell will run, so the hook
# only vouches for a single plain `render` invocation whose command path it
# can name. Anything else exits with no decision, which leaves Claude Code's
# normal permission checks in place.

# Keep validation and word splitting independent of the user's locale.
export LC_ALL=C

# Only vouch for plain words. Anything the shell treats specially (quotes,
# backslashes, $, backticks, ; & | < > ( ) { } * ? [ ] ~ # !, tabs, CR, LF)
# could make the shell run something other than what the checks below see.
# Validate inside jq before Bash command substitution can strip newlines or
# NULs. Slurp the input to require exactly one object; parse errors, invalid
# envelopes, and missing jq all exit without an approval decision.
command=$(jq -ers '
  select(length == 1) | .[0]
  | select(type == "object")
  | select(.tool_name == "Bash")
  | .tool_input | select(type == "object")
  | .command | select(type == "string")
  | select(startswith("render "))
  | select(test("[^A-Za-z0-9 _.:/=@,-]") | not)
' 2>/dev/null) || exit 0

# Check for destructive keywords first - never auto-approve these
case "$command" in
  *delete*|*remove*|*restart*|*create*|*deploy*|*update*|*set*|*suspend*|*resume*|*scale*|*stop*|*start*|*rollback*|*promote*|*cancel*)
    exit 0
    ;;
esac

# The command is plain words now, so split it the way the shell will and drop
# the leading "render".
set -f
set -- $command
shift

# The CLI (cobra) accepts flags before a subcommand and takes the word after
# a flag as that flag's value, so `render services --output json delete`
# runs `services delete`. Flags ahead of the command path are only safe when
# no later word can name a subcommand, so output formats are the only bare
# words allowed after them.
only_flags() {
  for word in "$@"; do
    case "$word" in
      -*|json|yaml|text) ;;
      *) return 1 ;;
    esac
  done
}

case "$1" in
  # Info flags - safe on their own
  --help|-h|--version|-v)
    [ $# -eq 1 ] || exit 0
    ;;

  # Commands with no subcommands - every later word is an argument or flag
  help|version|whoami|regions|logs)
    ;;

  # Resource listing and viewing
  services|deploys|postgres|redis|keyval|jobs|cron|blueprints|env|domains|headers|routes|disks)
    shift
    case "$1" in
      list|show|get|info|tail) ;;
      *) only_flags "$@" || exit 0 ;;
    esac
    ;;

  # Workspace operations - list/show/current are safe
  workspace)
    shift
    case "$1" in
      list|current|show|get) ;;
      *) only_flags "$@" || exit 0 ;;
    esac
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
