<#
.SYNOPSIS
    Process management helper.

.DESCRIPTION
    Lists, searches, inspects, kills, counts and exports processes.
    Supports confirmation prompts, partial-name matching and verbose output.
    Includes chart commands (stats, monitor, live, livetop, tree) via an
    external Python script (proc_stats.py, requires psutil).

    Available actions:
      list      List all processes (default)
      search    Find processes by name pattern
      kill      Kill process(es) by name or PID
      info      Detailed info for a process
      top       Show top N processes by CPU or memory
      count     Count matching processes
      export    Export process list to CSV or JSON

    Chart actions (require Python + psutil + chart backend):
      stats     Snapshot pie/bar/tree chart (via -Chart sub-type)
      monitor   Real-time timeline of specific processes (by name or PID)
      live      Live-updating top-N bar chart (re-ranked each refresh)
      livetop   Live timeline of top-N processes over time (line chart with history)
      tree      Shortcut for stats -Chart tree

    Chart parameters:
      -Backend    plotext | termplotlib | matplotlib  (default: plotext)
      -Theme      dark | light                        (default: dark / gruvbox-dark)
      -Metric     cpu | memory                        (default: cpu)
      -Top        Number of top processes             (default: 10)
      -Chart      pie | top | tree  (for stats only)  (default: pie)
      -PlotWidth  Plot width in characters            (default: 100)
      -PlotHeight Plot height in characters           (default: 25)
      -Interval   Sampling interval in seconds        (default: 2; monitor/live/livetop)
      -Duration   Total duration in seconds           (default: 0 = indefinite; monitor/live/livetop)

.EXAMPLE
    .\proc.ps1 list -SortBy CPU -v
    .\proc.ps1 search chrome
    .\proc.ps1 kill chrome
    .\proc.ps1 kill -Id 1234 -Force
    .\proc.ps1 top -Top 15 -SortBy Memory
    .\proc.ps1 export -OutFile procs.csv

    # Chart commands (require Python + psutil)
    .\proc.ps1 stats
    .\proc.ps1 stats -Metric Memory -Backend matplotlib -Theme light
    .\proc.ps1 stats -Chart pie -Metric cpu -Top 20
    .\proc.ps1 stats -Chart top -Metric Memory -Top 15
    .\proc.ps1 stats -Chart tree -Metric Memory
    .\proc.ps1 monitor chrome firefox -Metric cpu -Interval 2
    .\proc.ps1 monitor -Id 1234,5678 -Metric Memory -Duration 120
    .\proc.ps1 monitor -Name python node -Backend termplotlib
    .\proc.ps1 live
    .\proc.ps1 live -Metric Memory -Top 20 -Interval 1
    .\proc.ps1 live -Duration 60 -Backend termplotlib -Theme light
    .\proc.ps1 livetop
    .\proc.ps1 livetop -Metric Memory -Top 15 -Interval 3
    .\proc.ps1 livetop -Metric cpu -Top 5 -Duration 120 -Backend matplotlib
#>

[CmdletBinding()]
param(
    # Not using ValidateSet here on purpose: we want to handle unknown values
    # ourselves (show help instead of a parser error).
    [Parameter(Position = 0)]
    [string]$Action = 'list',

    [Parameter(Position = 1, ValueFromRemainingArguments = $true)]
    [string[]]$NameArgs,

    [int[]]$Id,

    # When killing multiple matches: target every one (still confirmed once).
    [switch]$All,

    # Skip every confirmation prompt.
    [switch]$Force,

    [ValidateSet('CPU','Memory','Name','Id')]
    [string]$SortBy = 'Memory',

    [int]$Top = 10,

    [string]$OutFile,

    # --- Chart / stats parameters ---

    # Chart sub-type for the stats command: pie, top, tree (default: pie)
    [ValidateSet('pie','top','tree')]
    [string]$Chart = 'pie',

    # Metric for chart commands
    [ValidateSet('cpu','memory')]
    [string]$Metric = 'cpu',

    # Charting backend
    [ValidateSet('plotext','termplotlib','matplotlib')]
    [string]$Backend = 'plotext',

    # Color theme
    [ValidateSet('dark','light')]
    [string]$Theme = 'dark',

    # Sampling interval for monitor (seconds)
    [double]$Interval = 2.0,

    # Duration for monitor (seconds, 0 = indefinite)
    [int]$Duration = 0,

    # Plot dimensions
    [int]$PlotWidth = 100,
    [int]$PlotHeight = 25,

    # -v as a short alias. Named differently than the built-in -Verbose
    # so it doesn't get hijacked by CmdletBinding's common parameters.
    [Alias('v')]
    [switch]$VerboseMode,

    [Alias('h')]
    [switch]$Help
)

# --- Normalise Name from NameArgs ------------------------------------------
# When the action is NOT 'monitor', $NameArgs[0] is the process name.
# When the action IS 'monitor', $NameArgs can be multiple names.

$Name = if ($NameArgs -and $NameArgs.Count -gt 0) { $NameArgs[0] } else { '' }

# --- output helpers --------------------------------------------------------

function Write-Ok      ([string]$m) { Write-Host $m -ForegroundColor Green }
function Write-Err     ([string]$m) { Write-Host $m -ForegroundColor Red }
function Write-Warn    ([string]$m) { Write-Host $m -ForegroundColor DarkYellow }
function Write-Info    ([string]$m) { Write-Host $m -ForegroundColor Cyan }
function Write-InfoAlt ([string]$m) { Write-Host $m -ForegroundColor Magenta }

# --- core helpers ----------------------------------------------------------

function Get-MatchingProcesses {
    param([string]$Pattern, [int]$ProcessId)

    if ($ProcessId) {
        return Get-Process -Id $ProcessId -ErrorAction SilentlyContinue
    }
    if ([string]::IsNullOrWhiteSpace($Pattern)) {
        return Get-Process
    }
    # If the user passed plain text, treat it as a contains-style match.
    # If they supplied wildcards themselves, respect them.
    $p = $Pattern
    if ($p -notmatch '[\*\?]') { $p = "*$p*" }
    return Get-Process | Where-Object { $_.ProcessName -like $p }
}

function Sort-Procs {
    param($Procs, [string]$By)

    switch ($By) {
        'CPU'    { $Procs | Sort-Object CPU          -Descending }
        'Memory' { $Procs | Sort-Object WorkingSet64 -Descending }
        'Name'   { $Procs | Sort-Object ProcessName }
        'Id'     { $Procs | Sort-Object Id }
        default  { $Procs }
    }
}

function Format-Procs {
    param($Procs, [switch]$Detailed)

    if ($Detailed) {
        $Procs | Select-Object Id, ProcessName,
            @{N='CPU(s)';  E={ if ($_.CPU) { [math]::Round($_.CPU,2) } else { 0 } }},
            @{N='Mem(MB)'; E={ [math]::Round($_.WorkingSet64 / 1MB, 1) }},
            @{N='Threads'; E={ $_.Threads.Count }},
            @{N='Handles'; E={ $_.HandleCount }},
            StartTime,
            @{N='Path';    E={ try { $_.Path } catch { '(access denied)' } }} |
            Format-Table -AutoSize
    }
    else {
        $Procs | Select-Object Id, ProcessName,
            @{N='CPU(s)';  E={ if ($_.CPU) { [math]::Round($_.CPU,2) } else { 0 } }},
            @{N='Mem(MB)'; E={ [math]::Round($_.WorkingSet64 / 1MB, 1) }} |
            Format-Table -AutoSize
    }
}

function Confirm-Action {
    param([string]$Message)
    if ($Force) { return $true }
    Write-Host "$Message [y/N] " -ForegroundColor DarkYellow -NoNewline
    $ans = Read-Host
    return ($ans -match '^(y|yes)$')
}

function Stop-OneProcess {
    param($Proc)
    try {
        Stop-Process -Id $Proc.Id -ErrorAction Stop
        Write-Ok ("Killed {0} (PID {1})" -f $Proc.ProcessName, $Proc.Id)
    }
    catch {
        Write-Err ("Failed to kill {0} (PID {1}): {2}" -f `
            $Proc.ProcessName, $Proc.Id, $_.Exception.Message)
    }
}

# --- Python chart helpers --------------------------------------------------

function Get-ProcStatsScript {
    $notesPath = [System.Environment]::GetEnvironmentVariable('my_notes_path')
    if (-not $notesPath -or [string]::IsNullOrWhiteSpace($notesPath)) {
        Write-Err "Environment variable 'my_notes_path' is not set."
        return $null
    }
    #$script = Join-Path $notesPath 'scripts' 'stats' 'proc_stats.py'
    # Join-Path in PowerShell 5.x only takes two positional args (parent 
    # + child). PS 7+ added variadic support. 
    $script = Join-Path (Join-Path (Join-Path $notesPath 'scripts') 'stats') 'proc_stats.py'
    if (-not (Test-Path $script)) {
        Write-Err "Python script not found: $script"
        return $null
    }
    return $script
}

function Get-PythonExeOld {
    # Try python3 first (Linux / WSL / some Windows), then python.
    foreach ($cmd in @('python3', 'python', 'py')) {
        $exe = Get-Command $cmd -ErrorAction SilentlyContinue
        if ($exe) { return $exe.Source }
    }
    Write-Err "Python not found in PATH. Install Python 3 or ensure it is on PATH."
    return $null
}
function Get-PythonExe {
    $candidates = @(
        @{ Cmd = "py";      Args = @("-3", "-c", "import sys; print(sys.executable)") }
        @{ Cmd = "python";  Args = @("-c", "import sys; print(sys.executable)") }
        @{ Cmd = "python3"; Args = @("-c", "import sys; print(sys.executable)") }
    )

    foreach ($candidate in $candidates) {
        $cmd = $candidate.Cmd

        $commands = Get-Command $cmd -All -ErrorAction SilentlyContinue
        if (-not $commands) {
            continue
        }

        foreach ($command in $commands) {
            $source = $command.Source

            if ([string]::IsNullOrWhiteSpace($source)) {
                continue
            }

            # Skip known broken Microsoft Store aliases
            if ($source -like "*\AppData\Local\Microsoft\WindowsApps\python*.exe") {
                continue
            }

            try {
                $output = & $source @($candidate.Args) 2>$null
                $exitCode = $LASTEXITCODE

                if ($exitCode -ne 0) {
                    continue
                }

                $realExe = ($output | Select-Object -First 1).ToString().Trim()

                if ([string]::IsNullOrWhiteSpace($realExe)) {
                    continue
                }

                if (-not (Test-Path $realExe)) {
                    continue
                }

                # Final sanity check
                & $realExe --version *> $null

                if ($LASTEXITCODE -eq 0) {
                    return $realExe
                }
            }
            catch {
                continue
            }
        }
    }

    Write-Err "Python not found in PATH. Install Python 3 or ensure it is on PATH."
    return $null
}

function Invoke-ProcStats {
    param([string[]]$PyArgs)

    $script = Get-ProcStatsScript
    if (-not $script) { return }
    $pyExe = Get-PythonExe
    if (-not $pyExe) { return }

    Write-Info ("Running: {0} {1} {2}" -f $pyExe, $script, ($PyArgs -join ' '))
    & $pyExe $script @PyArgs
}

# --- kill action -----------------------------------------------------------

function Invoke-Kill {

    # -Id takes precedence: most precise input wins.
    if ($Id -and $Id.Count -eq 1) {
        $proc = Get-Process -Id $Id[0] -ErrorAction SilentlyContinue
        if (-not $proc) { Write-Err "No process with PID $($Id[0])."; return }

        if (Confirm-Action ("Kill {0} (PID {1})?" -f $proc.ProcessName, $proc.Id)) {
            Stop-OneProcess $proc
        }
        else { Write-Info "Cancelled." }
        return
    }

    if (-not $Name) {
        Write-Err "Provide -Name <pattern> or -Id <pid> for kill."
        return
    }

    $found = @(Get-MatchingProcesses -Pattern $Name)
    if ($found.Count -eq 0) {
        Write-Warn "No processes matched '$Name'."
        return
    }

    # Single match: straight confirm-and-kill.
    if ($found.Count -eq 1) {
        $p = $found[0]
        if (Confirm-Action ("Kill {0} (PID {1})?" -f $p.ProcessName, $p.Id)) {
            Stop-OneProcess $p
        }
        else { Write-Info "Cancelled." }
        return
    }

    # Multiple matches: show them, then ask what to do.
    Write-InfoAlt ("Found {0} matching processes:" -f $found.Count)
    Format-Procs -Procs $found -Detailed:$VerboseMode

    if ($All) {
        if (Confirm-Action ("Kill ALL {0} matching processes?" -f $found.Count)) {
            foreach ($p in $found) { Stop-OneProcess $p }
        }
        else { Write-Info "Cancelled." }
        return
    }

    Write-Info "Enter PID to kill, 'all' for all, or 'q' to cancel:"
    $choice = Read-Host

    switch -Regex ($choice) {
        '^q(uit)?$' { Write-Info "Cancelled." }

        '^all$' {
            if (Confirm-Action ("Kill ALL {0} matching processes?" -f $found.Count)) {
                foreach ($p in $found) { Stop-OneProcess $p }
            }
            else { Write-Info "Cancelled." }
        }

        '^\d+$' {
            $targetPid = [int]$choice
            $target = $found | Where-Object { $_.Id -eq $targetPid }
            if (-not $target) {
                Write-Err "PID $targetPid is not in the matched set."
                return
            }
            if (Confirm-Action ("Kill {0} (PID {1})?" -f $target.ProcessName, $target.Id)) {
                Stop-OneProcess $target
            }
            else { Write-Info "Cancelled." }
        }

        default { Write-Err "Unrecognised input '$choice'." }
    }
}

# --- stats action ----------------------------------------------------------

function Invoke-Stats {
    $pyArgs = @()

    # Global flags
    $pyArgs += '--backend';  $pyArgs += $Backend
    $pyArgs += '--theme';    $pyArgs += $Theme
    $pyArgs += '--width';    $pyArgs += $PlotWidth.ToString()
    $pyArgs += '--height';   $pyArgs += $PlotHeight.ToString()

    # Subcommand
    $pyArgs += $Chart

    # Subcommand-specific flags
    $pyArgs += '--metric';  $pyArgs += $Metric
    $pyArgs += '--top';     $pyArgs += $Top.ToString()

    Invoke-ProcStats $pyArgs
}

# --- monitor action --------------------------------------------------------

function Invoke-Monitor {
    $pyArgs = @()

    # Global flags
    $pyArgs += '--backend';  $pyArgs += $Backend
    $pyArgs += '--theme';    $pyArgs += $Theme
    $pyArgs += '--width';    $pyArgs += $PlotWidth.ToString()
    $pyArgs += '--height';   $pyArgs += $PlotHeight.ToString()

    $pyArgs += 'monitor'

    $pyArgs += '--metric';    $pyArgs += $Metric
    $pyArgs += '--interval';  $pyArgs += $Interval.ToString()
    $pyArgs += '--duration';  $pyArgs += $Duration.ToString()

    # PIDs from -Id
    if ($Id -and $Id.Count -gt 0) {
        $pyArgs += '--pids'
        foreach ($pid in $Id) { $pyArgs += $pid.ToString() }
    }

    # Names: from $NameArgs (all positional args after 'monitor')
    if ($NameArgs -and $NameArgs.Count -gt 0) {
        $pyArgs += '--names'
        foreach ($n in $NameArgs) { $pyArgs += $n }
    }

    if ((-not $Id -or $Id.Count -eq 0) -and (-not $NameArgs -or $NameArgs.Count -eq 0)) {
        Write-Err "Provide process name(s) or -Id <pid(s)> for monitor."
        Write-Host "  Example: proc.ps1 monitor chrome firefox"
        Write-Host "  Example: proc.ps1 monitor -Id 1234,5678"
        return
    }

    Invoke-ProcStats $pyArgs
}

# --- tree action -----------------------------------------------------------

function Invoke-Tree {
    $pyArgs = @()
    $pyArgs += '--backend';  $pyArgs += $Backend
    $pyArgs += '--theme';    $pyArgs += $Theme
    $pyArgs += '--width';    $pyArgs += $PlotWidth.ToString()
    $pyArgs += '--height';   $pyArgs += $PlotHeight.ToString()
    $pyArgs += 'tree'
    $pyArgs += '--metric';   $pyArgs += $Metric
    $pyArgs += '--top';      $pyArgs += $Top.ToString()

    Invoke-ProcStats $pyArgs
}

# --- live action -----------------------------------------------------------

function Invoke-Live {
    $pyArgs = @()
    $pyArgs += '--backend';   $pyArgs += $Backend
    $pyArgs += '--theme';     $pyArgs += $Theme
    $pyArgs += '--width';     $pyArgs += $PlotWidth.ToString()
    $pyArgs += '--height';    $pyArgs += $PlotHeight.ToString()
    $pyArgs += 'live'
    $pyArgs += '--metric';    $pyArgs += $Metric
    $pyArgs += '--top';       $pyArgs += $Top.ToString()
    $pyArgs += '--interval';  $pyArgs += $Interval.ToString()
    $pyArgs += '--duration';  $pyArgs += $Duration.ToString()

    Invoke-ProcStats $pyArgs
}

# --- livetop action --------------------------------------------------------

function Invoke-LiveTop {
    $pyArgs = @()
    $pyArgs += '--backend';   $pyArgs += $Backend
    $pyArgs += '--theme';     $pyArgs += $Theme
    $pyArgs += '--width';     $pyArgs += $PlotWidth.ToString()
    $pyArgs += '--height';    $pyArgs += $PlotHeight.ToString()
    $pyArgs += 'livetop'
    $pyArgs += '--metric';    $pyArgs += $Metric
    $pyArgs += '--top';       $pyArgs += $Top.ToString()
    $pyArgs += '--interval';  $pyArgs += $Interval.ToString()
    $pyArgs += '--duration';  $pyArgs += $Duration.ToString()

    Invoke-ProcStats $pyArgs
}

# --- help ------------------------------------------------------------------

function Show-Help {
    Write-InfoAlt "Process helper"
    Write-Host @"
Usage:
  proc.ps1 list   [-SortBy CPU|Memory|Name|Id] [-v]
  proc.ps1 search <name> [-SortBy ...] [-v]
  proc.ps1 kill   <name> [-All] [-Force] [-v]
  proc.ps1 kill   -Id <pid> [-Force]
  proc.ps1 info   <name>  | -Id <pid>
  proc.ps1 top    [-Top N] [-SortBy CPU|Memory] [-v]
  proc.ps1 count  <name>  [-v]
  proc.ps1 export -OutFile out.csv|out.json [-Name pattern]

Chart commands (require Python + psutil):
  proc.ps1 stats [-Chart pie|top|tree] [-Metric cpu|memory] [-Top N]
  proc.ps1 monitor <name1> [name2...] [-Metric cpu|memory] [-Interval N] [-Duration N]
  proc.ps1 monitor -Id <pid1,pid2> [-Metric cpu|memory]
  proc.ps1 tree   [-Metric cpu|memory] [-Top N]
  proc.ps1 live    [-Top N] [-Metric cpu|memory] [-Interval N] [-Duration N]
  proc.ps1 livetop [-Top N] [-Metric cpu|memory] [-Interval N] [-Duration N]

Chart flags (shared):
  -Backend    plotext | termplotlib | matplotlib  (default: plotext)
  -Theme      dark | light                        (default: dark / gruvbox-dark)
  -PlotWidth  Plot width in characters            (default: 100)
  -PlotHeight Plot height in characters           (default: 25)
  -Metric     cpu | memory                        (default: cpu)

Monitor / live / livetop specific:
  -Interval   Sampling interval in seconds        (default: 2)
  -Duration   Total duration in seconds            (default: 0 = indefinite)

General flags:
  -h / -Help / --help  Show this help
  -v / -VerboseMode    Show extra columns (path, start time, threads, handles)
  -Force               Skip confirmation prompts
  -All                 When killing multiple matches, target every one
  -SortBy              CPU | Memory | Name | Id  (default: Memory)

Examples:
  proc.ps1 stats                                      # CPU pie chart (plotext, gruvbox dark)
  proc.ps1 stats -Metric memory -Backend matplotlib   # Memory pie via matplotlib
  proc.ps1 stats -Chart top -Metric memory -Top 20    # Top 20 by memory
  proc.ps1 stats -Theme light                         # Light gruvbox theme
  proc.ps1 monitor chrome firefox                     # Monitor chrome+firefox CPU
  proc.ps1 monitor -Id 1234,5678 -Metric memory       # Monitor PIDs by memory
  proc.ps1 tree -Metric memory -Top 20                # Memory resource tree
  proc.ps1 live                                       # Live top-10 CPU bar chart
  proc.ps1 live -Metric memory -Top 20                # Live top-20 by memory
  proc.ps1 live -Interval 1 -Duration 60              # 1s refresh, 60s then stop
  proc.ps1 livetop                                    # Live CPU timeline of top 10
  proc.ps1 livetop -Metric memory -Top 15 -Interval 3 # Memory timeline, top 15
  proc.ps1 livetop -Top 5 -Duration 60                # 60s CPU timeline of top 5
"@
}

# --- main dispatch ---------------------------------------------------------

# Catch help-like inputs in any form: -Help, -h, --help, /?, /help, or
# "help" / "--help" / "-h" arriving as the positional Action argument
# (PowerShell treats unknown --foo tokens as positional values).
$helpTokens = @('help','-h','--help','-help','/?','/help','-?')
if ($Help -or ($Action -and ($helpTokens -contains $Action.ToLower()))) {
    Show-Help
    return
}

$knownActions = @('list','search','kill','info','top','count','export','stats','monitor','live','livetop','tree')
if ($knownActions -notcontains $Action.ToLower()) {
    Write-Err "Unknown action: '$Action'"
    Write-Host ""
    Show-Help
    return
}

switch ($Action.ToLower()) {

    'list' {
        $procs = Sort-Procs -Procs (Get-Process) -By $SortBy
        Write-InfoAlt ("Listing {0} processes (sorted by {1})" -f $procs.Count, $SortBy)
        Format-Procs -Procs $procs -Detailed:$VerboseMode
    }

    'search' {
        if (-not $Name) { Write-Err "Provide a name pattern for search."; return }
        $procs = @(Get-MatchingProcesses -Pattern $Name)
        if ($procs.Count -eq 0) { Write-Warn "No processes matched '$Name'."; return }
        $procs = Sort-Procs -Procs $procs -By $SortBy
        Write-InfoAlt ("Found {0} matching '{1}'" -f $procs.Count, $Name)
        Format-Procs -Procs $procs -Detailed:$VerboseMode
    }

    'kill' { Invoke-Kill }

    'info' {
        $procs = if ($Id -and $Id.Count -eq 1) {
            @(Get-Process -Id $Id[0] -ErrorAction SilentlyContinue)
        }
        else {
            @(Get-MatchingProcesses -Pattern $Name)
        }
        if ($procs.Count -eq 0) { Write-Warn "No matching processes."; return }

        foreach ($p in $procs) {
            Write-InfoAlt ("--- {0} (PID {1}) ---" -f $p.ProcessName, $p.Id)
            $p | Format-List Id, ProcessName, Description, Company, FileVersion,
                Path, StartTime, CPU,
                @{N='Mem(MB)';        E={ [math]::Round($_.WorkingSet64        / 1MB, 1) }},
                @{N='VirtualMem(MB)'; E={ [math]::Round($_.VirtualMemorySize64 / 1MB, 1) }},
                @{N='Threads';        E={ $_.Threads.Count }},
                HandleCount, PriorityClass, Responding
        }
    }

    'top' {
        $by = if ($SortBy -in @('CPU','Memory')) { $SortBy } else { 'Memory' }
        $procs = Sort-Procs -Procs (Get-Process) -By $by | Select-Object -First $Top
        Write-InfoAlt ("Top {0} by {1}" -f $Top, $by)
        Format-Procs -Procs $procs -Detailed:$VerboseMode
    }

    'count' {
        $procs = @(Get-MatchingProcesses -Pattern $Name)
        Write-Ok ("{0} process(es) match '{1}'" -f $procs.Count, $Name)
        if ($VerboseMode -and $procs.Count -gt 0) {
            $procs | Group-Object ProcessName |
                Select-Object Count, Name |
                Sort-Object Count -Descending |
                Format-Table -AutoSize
        }
    }

    'export' {
        if (-not $OutFile) { Write-Err "Provide -OutFile <path>."; return }
        $procs = if ($Name) { Get-MatchingProcesses -Pattern $Name } else { Get-Process }

        $data = $procs | Select-Object Id, ProcessName,
            @{N='CPU';      E={ $_.CPU }},
            @{N='MemoryMB'; E={ [math]::Round($_.WorkingSet64 / 1MB, 1) }},
            StartTime,
            @{N='Path';     E={ try { $_.Path } catch { $null } }}

        $ext = [IO.Path]::GetExtension($OutFile).ToLower()
        switch ($ext) {
            '.csv'  { $data | Export-Csv -Path $OutFile -NoTypeInformation -Encoding UTF8 }
            '.json' { $data | ConvertTo-Json -Depth 4 | Out-File -FilePath $OutFile -Encoding UTF8 }
            default { Write-Err "Unsupported extension '$ext'. Use .csv or .json."; return }
        }
        Write-Ok "Exported $(@($data).Count) entries to $OutFile."
    }

    'stats'   { Invoke-Stats }
    'monitor' { Invoke-Monitor }
    'live'    { Invoke-Live }
    'livetop' { Invoke-LiveTop }
    'tree'    { Invoke-Tree }
}
