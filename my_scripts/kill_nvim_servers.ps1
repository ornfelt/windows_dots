<#
.SYNOPSIS
    Kills the headless Neovim servers started by the wezterm integration and
    clears their state directory, so you can start from a clean slate.

.DESCRIPTION
    Servers are found by looking for running nvim processes whose command line
    contains "--listen <address>" where the address starts with -Pattern
    (default "nvim-wez-", the prefix used by ~/.wezterm/nvim_server.lua).

    Plain interactive nvim sessions are never touched: they either have no
    --listen at all, or listen on nvim's own "nvim.<pid>.0" address, neither of
    which matches the prefix. Note that nvim 0.12 runs every server as a parent
    plus an --embed child, so the process count is about twice the server count.

.PARAMETER StateDir
    Directory holding the <name>.pid and <name>.lease files.
    Defaults to ~/.wezterm/nvim-servers. Can also be given positionally.

.PARAMETER Scope
    All      every managed server (default)
    Pane     only per-pane servers, nvim-wez-<wezterm pid>-<pane id>
    Pool     only pooled servers, nvim-wez-pool-*
    Orphans  only per-pane servers whose owning wezterm is no longer running,
             which is the safe option while you are still using wezterm

.PARAMETER Instance
    Only servers belonging to this wezterm instance (its process id).

.PARAMETER Pattern
    Server name prefix to match. Widen it at your own risk.

.PARAMETER KeepStateDir
    Leave the .pid/.lease files alone instead of cleaning them up.

.PARAMETER Force
    Do not ask for confirmation.

.PARAMETER DryRun
    Show what would be killed and print the equivalent commands, then stop.

.EXAMPLE
    .\kill_nvim_servers.ps1 -DryRun
.EXAMPLE
    .\kill_nvim_servers.ps1 -Scope Orphans -Force
.EXAMPLE
    .\kill_nvim_servers.ps1 -Scope Pool
#>

param(
    [Parameter(Position = 0)]
    [Alias('Dir')]
    [string]$StateDir,

    [ValidateSet('All', 'Pane', 'Pool', 'Orphans')]
    [string]$Scope = 'All',

    [string]$Instance,

    [string]$Pattern = 'nvim-wez-',

    [switch]$KeepStateDir,
    [switch]$Force,
    [switch]$DryRun
)

function Write-Ok      ([string]$m) { Write-Host $m -ForegroundColor Green }
function Write-Err     ([string]$m) { Write-Host $m -ForegroundColor Red }
function Write-Warn    ([string]$m) { Write-Host $m -ForegroundColor DarkYellow }
function Write-Info    ([string]$m) { Write-Host $m -ForegroundColor Cyan }
function Write-InfoAlt ([string]$m) { Write-Host $m -ForegroundColor Magenta }
function Write-Dim     ([string]$m) { Write-Host $m -ForegroundColor DarkGray }

if (-not $StateDir) {
    $homeDir = if ($env:USERPROFILE) { $env:USERPROFILE } else { $HOME }
    $StateDir = Join-Path $homeDir '.wezterm\nvim-servers'
}

Write-InfoAlt "== kill nvim servers =="
Write-Dim     "   state dir : $StateDir"
Write-Dim     "   scope     : $Scope$(if ($Instance) { "  instance=$Instance" })"
Write-Dim     "   pattern   : $Pattern*"
Write-Host ''

# --- discover -------------------------------------------------------------

$procs = @(Get-CimInstance Win32_Process -Filter "Name='nvim.exe'" -ErrorAction SilentlyContinue |
    Where-Object { $_.CommandLine -and $_.CommandLine -like '*--listen*' })

$live = @(Get-CimInstance Win32_Process -Filter "Name='wezterm-gui.exe'" -ErrorAction SilentlyContinue |
    ForEach-Object { [string]$_.ProcessId })

# Derived from -Pattern rather than hardcoded, so overriding the prefix still
# classifies pool vs per-pane servers and still finds the owning instance
$escaped = [regex]::Escape($Pattern)
$paneRe = '^' + $escaped + '(\d+)-\d+$'
$poolRe = '^' + $escaped + 'pool-(\d+)-\d+$'

$servers = @{}
foreach ($p in $procs) {
    if ($p.CommandLine -notmatch '--listen\s+"?([^\s"]+)') { continue }
    $addr = $Matches[1]
    $name = $addr -replace '^\\\\\.\\pipe\\', '' -replace '\.sock$', ''
    $name = $name.Substring($name.LastIndexOf('\') + 1)
    if (-not $name.StartsWith($Pattern)) { continue }

    if (-not $servers.ContainsKey($name)) {
        $kind = 'pane'
        $inst = $null
        $owned = $true
        if ($name -like ($Pattern + 'pool-*')) {
            $kind = 'pool'
            # Pool servers spawned from lua carry the instance that started
            # them, so -Instance can select them too; they are still shared
            if ($name -match $poolRe) { $inst = $Matches[1] }
        }
        elseif ($name -match $paneRe) {
            $inst = $Matches[1]
            $owned = $live -contains $inst
        }
        $servers[$name] = [pscustomobject]@{
            Name = $name; Kind = $kind; Instance = $inst
            OwnerAlive = $owned; Pids = @(); Bytes = 0
        }
    }
    $servers[$name].Pids += [int]$p.ProcessId
    $servers[$name].Bytes += [int64]$p.WorkingSetSize
}

$all = @($servers.Values | Sort-Object Name)

# --- filter ---------------------------------------------------------------

# The @() around the switch matters: a switch that yields a single object
# unrolls it, and $targets.Count on a bare PSCustomObject is empty
$targets = @(switch ($Scope) {
    'Pane'    { $all | Where-Object { $_.Kind -eq 'pane' } }
    'Pool'    { $all | Where-Object { $_.Kind -eq 'pool' } }
    'Orphans' { $all | Where-Object { $_.Kind -eq 'pane' -and -not $_.OwnerAlive } }
    default   { $all }
})
if ($Instance) {
    $targets = @($targets | Where-Object { $_.Instance -eq $Instance })
}

# --- report ---------------------------------------------------------------

if ($all.Count -eq 0) {
    Write-Ok 'No managed nvim servers are running.'
}
else {
    # Count only the processes behind matched servers, not every listening nvim
    $matched = ($all | ForEach-Object { $_.Pids.Count } | Measure-Object -Sum).Sum
    Write-Info "Found $($all.Count) managed server(s) across $matched process(es):"
    foreach ($s in $all) {
        $mark = if ($targets -contains $s) { '  KILL ' } else { '  keep ' }
        $owner = switch ($s.Kind) {
            'pool'  { 'pool (shared)' }
            default { "instance $($s.Instance) $(if ($s.OwnerAlive) { '(alive)' } else { '(DEAD)' })" }
        }
        $line = ('{0}{1,-34} {2,-26} pids={3,-14} {4,6:N0} MB' -f
            $mark, $s.Name, $owner, ($s.Pids -join ','), ($s.Bytes / 1MB))
        if ($targets -contains $s) {
            if ($s.Kind -eq 'pane' -and -not $s.OwnerAlive) { Write-Warn $line } else { Write-Host $line }
        }
        else { Write-Dim $line }
    }
}

$staleFiles = @()
if (Test-Path -LiteralPath $StateDir) {
    $staleFiles = @(Get-ChildItem -LiteralPath $StateDir -File -Include '*.pid', '*.lease' -Recurse -ErrorAction SilentlyContinue)
}

Write-Host ''
$killPids = @($targets | ForEach-Object { $_.Pids })
$freed = ($targets | Measure-Object -Property Bytes -Sum).Sum
if ($null -eq $freed) { $freed = 0 }
Write-Info ("Will kill {0} server(s) / {1} process(es), freeing about {2:N0} MB" -f
    $targets.Count, $killPids.Count, ($freed / 1MB))
if (-not $KeepStateDir) {
    Write-Info "Will remove $($staleFiles.Count) file(s) from the state directory"
}
else {
    Write-Dim  'State directory will be left alone (-KeepStateDir)'
}

if ($targets.Count -eq 0 -and ($KeepStateDir -or $staleFiles.Count -eq 0)) {
    Write-Host ''
    Write-Ok 'Nothing to do.'
    exit 0
}

# --- dry run --------------------------------------------------------------

if ($DryRun) {
    Write-Host ''
    Write-InfoAlt 'Dry run, nothing was changed. Equivalent commands:'
    if ($killPids.Count -gt 0) {
        Write-Host ("  Stop-Process -Force -Id {0}" -f ($killPids -join ','))
    }
    if (-not $KeepStateDir -and $staleFiles.Count -gt 0) {
        Write-Host ("  Remove-Item -Force '{0}\*.pid','{0}\*.lease'" -f $StateDir)
    }
    exit 0
}

# --- confirm --------------------------------------------------------------

if (-not $Force) {
    Write-Host ''
    Write-Warn 'Unsaved buffers in these servers will be lost (nvim swap files survive).'
    $answer = Read-Host 'Proceed? [y/N]'
    if ($answer -notmatch '^(y|yes)$') {
        Write-Err 'Aborted.'
        exit 1
    }
}

# --- kill -----------------------------------------------------------------

Write-Host ''
$failed = 0
foreach ($s in $targets) {
    $bad = @()
    foreach ($processId in $s.Pids) {
        try { Stop-Process -Id $processId -Force -ErrorAction Stop }
        catch {
            # Already gone counts as success; nvim's parent takes its child with it
            if (Get-Process -Id $processId -ErrorAction SilentlyContinue) { $bad += $processId }
        }
    }
    if ($bad.Count -gt 0) { Write-Err "  failed: $($s.Name) (pids $($bad -join ','))"; $failed++ }
    else { Write-Ok "  killed: $($s.Name)" }
}

# --- clean up state files -------------------------------------------------

$removed = 0
if (-not $KeepStateDir -and (Test-Path -LiteralPath $StateDir)) {
    # Only drop files whose server is really gone, so a server we deliberately
    # kept does not lose the pid file that makes it findable
    foreach ($file in $staleFiles) {
        $name = $file.BaseName
        $stillRunning = $servers.ContainsKey($name) -and ($targets -notcontains $servers[$name])
        if ($stillRunning) { continue }
        try { Remove-Item -LiteralPath $file.FullName -Force -ErrorAction Stop; $removed++ } catch { }
    }
    Write-Ok "  removed $removed state file(s)"
}

Write-Host ''
if ($failed -gt 0) {
    Write-Err "Done with $failed failure(s)."
    exit 1
}
Write-Ok ("Done. Killed {0} server(s), freed about {1:N0} MB." -f $targets.Count, ($freed / 1MB))
exit 0
