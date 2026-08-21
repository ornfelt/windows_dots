# Marks / unmarks the wezterm pane this Claude Code session is running in.
#
# Wired up from ~/.claude/settings.json:
#   Stop             -> wezterm-claude-status.ps1 done
#   UserPromptSubmit -> wezterm-claude-status.ps1 clear
#
# ~/.wezterm/claude.lua polls the state directory and shows a robot icon on the
# tab containing this pane until that tab is visited. Linux equivalent:
# wezterm-claude-status.sh (same state directory and file layout).

param([ValidateSet('done', 'clear')][string]$Action = 'done')

# Not running inside wezterm: nothing to mark
if (-not $env:WEZTERM_PANE) { exit 0 }

$home_dir = if ($env:USERPROFILE) { $env:USERPROFILE } else { $HOME }
$stateDir = Join-Path $home_dir '.wezterm\claude-status'
$marker = Join-Path $stateDir ('{0}.done' -f $env:WEZTERM_PANE)

if ($Action -eq 'clear') {
    try { Remove-Item -LiteralPath $marker -Force -ErrorAction Stop } catch { }
    exit 0
}

# Claude Code passes the hook payload as JSON on stdin; cwd is the project dir
$label = $null
try {
    $payload = [Console]::In.ReadToEnd()
    if ($payload) { $label = ($payload | ConvertFrom-Json).cwd }
} catch { }
if (-not $label) { $label = (Get-Location).Path }
$label = Split-Path -Leaf $label

if (-not (Test-Path -LiteralPath $stateDir)) {
    New-Item -ItemType Directory -Force -Path $stateDir | Out-Null
}

# WriteAllText gives UTF-8 without a BOM, which keeps the label clean in lua
[System.IO.File]::WriteAllText($marker, $label)
exit 0
