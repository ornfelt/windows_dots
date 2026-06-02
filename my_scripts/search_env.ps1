param(
    # Default mode: get value for a specific env var name
    [Parameter(Position = 0)]
    [string]$Key,
    # Search mode: print all env vars where name OR value contains this string
    [Parameter(Mandatory = $false)]
    [string]$Search,
    # List mode: print all env vars
    [switch]$List
)
# Example usage:
# Get a specific value (default mode):
# .\search_env.ps1 USERNAME
# .\search_env.ps1 "PATH"
#
# Search in env var names and values:
# .\search_env.ps1 -Search local
#
# List all env vars:
# .\search_env.ps1 -List

# Separator used in PATH (semicolon on Windows, colon on Linux/macOS)
$pathSep = [System.IO.Path]::PathSeparator

# Names treated as path-list variables (expand as needed)
$pathListVars = @("PATH", "Path", "PSModulePath")

function Is-PathListVar([string]$name) {
    return $pathListVars -contains $name
}

function Format-PathEntries([string]$name, [string]$value) {
    $paths = $value.Split($pathSep, [System.StringSplitOptions]::RemoveEmptyEntries)
    $out = "${name}:"
    $i = 0
    foreach ($p in $paths) {
        $i++
        $out += "`n  [$i] $($p.Trim())"
    }
    return $out
}

# Gather all environment variables as key/value objects
$entries = Get-ChildItem Env: | ForEach-Object {
    [PSCustomObject]@{
        Key   = $_.Name
        Value = $_.Value
    }
} | Sort-Object Key

# ── List mode ────────────────────────────────────────────────────────
if ($List) {
    # Print non-path-list vars first
    $normal = $entries | Where-Object { -not (Is-PathListVar $_.Key) }
    $normal | ForEach-Object { "$($_.Key): $($_.Value)" }

    # Print path-list vars at the end, expanded
    $pathEntries = $entries | Where-Object { Is-PathListVar $_.Key }
    if ($pathEntries) {
        Write-Host ""
        $pathEntries | ForEach-Object {
            Write-Host (Format-PathEntries $_.Key $_.Value)
        }
    }
    exit 0
}

# ── Search mode ──────────────────────────────────────────────────────
if ($Search) {
    # Standard search: name or value contains the string
    $found = $entries | Where-Object {
        $_.Key   -like "*$Search*" -or
        $_.Value -like "*$Search*"
    }

    # Also search inside individual PATH entries (if no full-var match on PATH)
    $pathMatches = @()
    foreach ($pv in $pathListVars) {
        $raw = [System.Environment]::GetEnvironmentVariable($pv)
        if (-not $raw) { continue }
        $paths = $raw.Split($pathSep, [System.StringSplitOptions]::RemoveEmptyEntries)
        $hits = $paths | Where-Object { $_ -like "*$Search*" }
        if ($hits) {
            $pathMatches += [PSCustomObject]@{
                VarName = $pv
                Paths   = $hits
            }
        }
    }

    if (-not $found -and -not $pathMatches) {
        Write-Host "No entries matching search string: '$Search'"
        exit 0
    }

    # Print standard matches (skip path-list vars here, we show them expanded below)
    $normalFound = $found | Where-Object { -not (Is-PathListVar $_.Key) }
    $normalFound | ForEach-Object { "$($_.Key): $($_.Value)" }

    # Print any path-list vars that matched as a whole (name match or entire value match)
    $pathVarFound = $found | Where-Object { Is-PathListVar $_.Key }
    # Merge with individual-path matches
    $shownPathVars = @{}
    foreach ($pm in $pathMatches) {
        $shownPathVars[$pm.VarName] = $true
        Write-Host ""
        Write-Host "$($pm.VarName) (matching entries):"
        $i = 0
        foreach ($p in $pm.Paths) {
            $i++
            Write-Host "  [$i] $($p.Trim())"
        }
    }
    # If a path-list var matched by name but had no individual hits, still show it expanded
    foreach ($pv in $pathVarFound) {
        if (-not $shownPathVars.ContainsKey($pv.Key)) {
            Write-Host ""
            Write-Host (Format-PathEntries $pv.Key $pv.Value)
        }
    }
    exit 0
}

# ── Default mode: get value for a specific env var ───────────────────
if ($Key) {
    $match = $entries | Where-Object { $_.Key -eq $Key } | Select-Object -First 1
    if ($match) {
        if (Is-PathListVar $match.Key) {
            # Pretty-print path-list vars
            Write-Output (Format-PathEntries $match.Key $match.Value)
        } else {
            Write-Output $match.Value
        }
        exit 0
    } else {
        Write-Host "Environment variable not found: '$Key'"
        exit 1
    }
}

# ── No arguments: brief usage ───────────────────────────────────────
Write-Host "Usage:"
Write-Host "  search_env.ps1 <name>            # Print value for given env var"
Write-Host "  search_env.ps1 -Search <text>    # Search in names and values (substring)"
Write-Host "  search_env.ps1 -List             # List all env vars"
exit 0
