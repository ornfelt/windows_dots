#!/usr/bin/env bash
# Marks / unmarks the wezterm pane this Claude Code session is running in.
#
# Wired up from ~/.claude/settings.json:
#   Stop             -> wezterm-claude-status.sh done
#   UserPromptSubmit -> wezterm-claude-status.sh clear
#
# ~/.wezterm/claude.lua polls the state directory and shows a robot icon on the
# tab containing this pane until that tab is visited. Windows equivalent:
# wezterm-claude-status.ps1 (same state directory and file layout).

set -u

action="${1:-done}"

# Not running inside wezterm: nothing to mark
[ -n "${WEZTERM_PANE:-}" ] || exit 0

state_dir="${HOME}/.wezterm/claude-status"
marker="${state_dir}/${WEZTERM_PANE}.done"

if [ "$action" = "clear" ]; then
  rm -f "$marker"
  exit 0
fi

# Claude Code passes the hook payload as JSON on stdin; cwd is the project dir
payload="$(cat 2>/dev/null || true)"
cwd="$(printf '%s' "$payload" | sed -n 's/.*"cwd"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1)"
[ -n "$cwd" ] || cwd="$PWD"

mkdir -p "$state_dir"
printf '%s' "$(basename "$cwd")" > "$marker"
exit 0
