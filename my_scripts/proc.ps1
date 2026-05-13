<#
.SYNOPSIS
    Process management helper.

.DESCRIPTION
    Lists, searches, inspects, kills, counts and exports processes.
    Supports confirmation prompts, partial-name matching and verbose output.

.EXAMPLE
    .\proc.ps1 list -SortBy CPU -v
    .\proc.ps1 search chrome
    .\proc.ps1 kill chrome
    .\proc.ps1 kill -Id 1234 -Force
    .\proc.ps1 top -Top 15 -SortBy Memory
    .\proc.ps1 export -OutFile procs.csv
#>

[CmdletBinding()]
param(
    # Not using ValidateSet here on purpose: we want to handle unknown values
    # ourselves (show help instead of a parser error).
    [Parameter(Position = 0)]
    [string]$Action = 'list',

    [Parameter(Position = 1)]
    [string]$Name,

    [int]$Id,

    # When killing multiple matches: target every one (still confirmed once).
    [switch]$All,

    # Skip every confirmation prompt.
    [switch]$Force,

    [ValidateSet('CPU','Memory','Name','Id')]
    [string]$SortBy = 'Memory',

    [int]$Top = 10,

    [string]$OutFile,

    # -v as a short alias. Named differently than the built-in -Verbose
    # so it doesn't get hijacked by CmdletBinding's common parameters.
    [Alias('v')]
    [switch]$VerboseMode,

    [Alias('h')]
    [switch]$Help
)

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

# --- kill action -----------------------------------------------------------

function Invoke-Kill {

    # -Id takes precedence: most precise input wins.
    if ($Id) {
        $proc = Get-Process -Id $Id -ErrorAction SilentlyContinue
        if (-not $proc) { Write-Err "No process with PID $Id."; return }

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
  proc.ps1 help        (also: -h, --help, -Help)

Flags:
  -h / -Help / --help  Show this help
  -v / -VerboseMode    Show extra columns (path, start time, threads, handles)
  -Force               Skip confirmation prompts
  -All                 When killing multiple matches, target every one
  -SortBy              CPU | Memory | Name | Id  (default: Memory)
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

$knownActions = @('list','search','kill','info','top','count','export')
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
        $procs = if ($Id) {
            @(Get-Process -Id $Id -ErrorAction SilentlyContinue)
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
}
