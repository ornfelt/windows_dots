#!/usr/bin/env bash
# Marks / unmarks the wezterm pane this Claude Code session is running in.
#
# Wired up from ~/.claude/settings.json:
#   Stop             -> wezterm-claude-status.sh done
#   StopFailure      -> wezterm-claude-status.sh failed
#   UserPromptSubmit -> wezterm-claude-status.sh clear
#
# ~/.wezterm/claude.lua polls the state directory and shows a robot icon on the
# tab containing this pane until that tab is visited (a dead robot when the
# turn ended on an API error instead). Windows equivalent:
# wezterm-claude-status.ps1 (same state directory and file layout).

set -u

action="${1:-done}"

# Not running inside wezterm: nothing to mark
[ -n "${WEZTERM_PANE:-}" ] || exit 0

state_dir="${HOME}/.wezterm/claude-status"
marker="${state_dir}/${WEZTERM_PANE}.done"
# "<label>\n<error type>" while the last turn of this pane ended on an API error
failed_marker="${state_dir}/${WEZTERM_PANE}.failed"

if [ "$action" = "clear" ]; then
  rm -f "$marker" "$failed_marker"
  exit 0
fi

# Claude Code passes the hook payload as JSON on stdin; cwd is the project dir
payload="$(cat 2>/dev/null || true)"
cwd="$(printf '%s' "$payload" | sed -n 's/.*"cwd"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1)"
[ -n "$cwd" ] || cwd="$PWD"

# Stop also fires when a turn ends only to wait for background work (shells,
# agents, monitors); the payload lists those in background_tasks. Only mark the
# pane once nothing is still running - the final Stop comes after they finish.
# Quotes inside last_assistant_message are escaped, so these patterns only match
# the real keys.
if [ "$action" = "done" ] && printf '%s' "$payload" | sed -n 's/.*"background_tasks"[[:space:]]*:\(.*\)/\1/p' \
    | grep -Eq '"status"[[:space:]]*:[[:space:]]*"(running|pending)"'; then
  exit 0
fi

# StopFailure: rate_limit, billing_error, server_error, ... (whitespace squeezed
# out, so it can't break the tab separated trail line below)
error_type=""
if [ "$action" = "failed" ]; then
  error_type="$(printf '%s' "$payload" | sed -n 's/.*"error"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1 | tr -s '[:space:]' '_')"
  [ -n "$error_type" ] || error_type="unknown"
fi

mkdir -p "$state_dir"
label="$(basename "$cwd")"
# One marker per pane: a failure replaces a finished marker and vice versa
if [ "$action" = "failed" ]; then
  printf '%s\n%s' "$label" "$error_type" > "$failed_marker"
  rm -f "$marker"
else
  printf '%s' "$label" > "$marker"
  rm -f "$failed_marker"
fi

# Append-only trail of finished responses: "<unix ms>\t<pane>\t<label>", and
# "<unix ms>\t<pane>\t<label>\tStopFailure\t<error type>" for a failed one.
# The marker above is short lived -- claude.lua removes it again as soon as the
# tab it belongs to is the active one -- so anything that wants to *wait* for a
# response to finish (send_hotkey.py) reads this instead. claude.lua only globs
# *.done / *.failed, so the log is invisible to it. A single short line with >>
# is written atomically, so parallel sessions can't interleave.
trail="${state_dir}/history.log"
now_ms="$(date +%s%3N 2>/dev/null)"
case "$now_ms" in *N*|"") now_ms="$(( $(date +%s) * 1000 ))";; esac
if [ -n "$error_type" ]; then
  printf '%s\t%s\t%s\tStopFailure\t%s\n' "$now_ms" "$WEZTERM_PANE" "$label" "$error_type" >> "$trail"
else
  printf '%s\t%s\t%s\n' "$now_ms" "$WEZTERM_PANE" "$label" >> "$trail"
fi

# Keep it from growing forever
if [ "$(wc -c < "$trail" 2>/dev/null || echo 0)" -gt 65536 ]; then
  tail -n 200 "$trail" > "${trail}.tmp" && mv -f "${trail}.tmp" "$trail"
fi

exit 0
