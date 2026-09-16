# Marks / unmarks the wezterm pane this Claude Code session is running in.
#
# Wired up from ~/.claude/settings.json:
#   Stop             -> wezterm-claude-status.ps1 done
#   StopFailure      -> wezterm-claude-status.ps1 failed
#   UserPromptSubmit -> wezterm-claude-status.ps1 clear
#
# ~/.wezterm/claude.lua polls the state directory and shows a robot icon on the
# tab containing this pane until that tab is visited (a dead robot when the
# turn ended on an API error instead). Linux equivalent:
# wezterm-claude-status.sh (same state directory and file layout).

param([ValidateSet('done', 'failed', 'clear')][string]$Action = 'done')

# Not running inside wezterm: nothing to mark
if (-not $env:WEZTERM_PANE) { exit 0 }

$home_dir = if ($env:USERPROFILE) { $env:USERPROFILE } else { $HOME }
$stateDir = Join-Path $home_dir '.wezterm\claude-status'
$marker = Join-Path $stateDir ('{0}.done' -f $env:WEZTERM_PANE)
# "<label>\n<error type>" while the last turn of this pane ended on an API error
$failedMarker = Join-Path $stateDir ('{0}.failed' -f $env:WEZTERM_PANE)

if ($Action -eq 'clear') {
    foreach ($path in @($marker, $failedMarker)) {
        try { Remove-Item -LiteralPath $path -Force -ErrorAction Stop } catch { }
    }
    exit 0
}

# Claude Code passes the hook payload as JSON on stdin; cwd is the project dir
$label = $null
$data = $null
try {
    $payload = [Console]::In.ReadToEnd()
    if ($payload) { $data = $payload | ConvertFrom-Json; $label = $data.cwd }
} catch { }

# Stop also fires when a turn ends only to wait for background work (shells,
# agents, monitors); the payload lists those in background_tasks. Only mark the
# pane once nothing is still running - the final Stop comes after they finish.
$busyStatuses = @('running', 'pending')
if ($Action -eq 'done' -and $data -and ($data.background_tasks | Where-Object { $busyStatuses -contains $_.status })) { exit 0 }
if (-not $label) { $label = (Get-Location).Path }
$label = Split-Path -Leaf $label

# StopFailure: rate_limit, billing_error, server_error, ... (no whitespace, so
# it can't break the tab separated trail line below)
$errorType = $null
if ($Action -eq 'failed') {
    $errorType = if ($data -and $data.error) { [string]$data.error } else { 'unknown' }
    $errorType = $errorType -replace '\s+', '_'
}

if (-not (Test-Path -LiteralPath $stateDir)) {
    New-Item -ItemType Directory -Force -Path $stateDir | Out-Null
}

# WriteAllText gives UTF-8 without a BOM, which keeps the label clean in lua.
# One marker per pane: a failure replaces a finished marker and vice versa.
if ($Action -eq 'failed') {
    [System.IO.File]::WriteAllText($failedMarker, "$label`n$errorType")
    try { Remove-Item -LiteralPath $marker -Force -ErrorAction Stop } catch { }
} else {
    [System.IO.File]::WriteAllText($marker, $label)
    try { Remove-Item -LiteralPath $failedMarker -Force -ErrorAction Stop } catch { }
}

# Append-only trail of finished responses: "<unix ms>\t<pane>\t<label>", and
# "<unix ms>\t<pane>\t<label>\tStopFailure\t<error type>" for a failed one.
# The marker above is short lived -- claude.lua removes it again as soon as the
# tab it belongs to is the active one -- so anything that wants to *wait* for a
# response to finish (send_hotkey.py) reads this instead. claude.lua only globs
# *.done / *.failed, so the log is invisible to it.
$trail = Join-Path $stateDir 'history.log'
$line = "{0}`t{1}`t{2}" -f [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds(), $env:WEZTERM_PANE, $label
if ($errorType) { $line += "`tStopFailure`t$errorType" }
$line += "`n"

# Several sessions can finish at once; retry a few times if the file is locked
foreach ($attempt in 1..5) {
    try {
        [System.IO.File]::AppendAllText($trail, $line)
        break
    } catch {
        Start-Sleep -Milliseconds 50
    }
}

# Keep it from growing forever
try {
    if ((Get-Item -LiteralPath $trail).Length -gt 64KB) {
        $keep = Get-Content -LiteralPath $trail -Tail 200
        [System.IO.File]::WriteAllLines($trail, $keep)
    }
} catch { }

exit 0
