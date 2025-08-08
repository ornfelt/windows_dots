param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Server,

    [Parameter(Mandatory = $false, Position = 1)]
    [ValidateSet('js','ts','py','php')]
    [string]$Lang = 'py'
)

# Usage:
# .\playermap.ps1 acore js
# .\playermap.ps1 cmangos-tbc py
# .\playermap.ps1 mangoszero ts
# with named parameters
# .\playermap.ps1 -Server cmangos -Lang php

# Ensure CODE_ROOT_DIR is set
if (-not $env:CODE_ROOT_DIR) {
    Write-Error "Environment variable CODE_ROOT_DIR is not defined. Exiting."
    exit 1
}

# Normalize server names
switch ($Server.ToLower()) {
    'acore'             { $normalized = 'acore'; break }
    'tcore'             { $normalized = 'tcore'; break }
    'cmangos'           { $normalized = 'cmangos'; break }
    'vmangos'           { $normalized = 'vmangos'; break }
    'mangos0'           { $normalized = 'mangoszero'; break }
    'mangoszero'        { $normalized = 'mangoszero'; break }
    'mangos-tbc'        { $normalized = 'cmangos-tbc'; break }
    'cmangos-tbc'       { $normalized = 'cmangos-tbc'; break }
    'tbc'               { $normalized = 'cmangos-tbc'; break }
    default {
        Write-Error "Unknown server '$Server'. Valid options are: acore, tcore, cmangos, cmangos-tbc, vmangos, mangoszero"
        exit 1
    }
}

# Export the selected server for downstream use
$env:SELECTED_SERVER = $normalized

# Helper to build the path under Code2\Python\wander_nodes_util
function Get-MapPath {
    param($subdir)
    return Join-Path -Path $env:CODE_ROOT_DIR -ChildPath ("Code2\Python\wander_nodes_util\$subdir")
}

# PHP mode (only for acore/tcore)
if ($Lang -eq 'php') {
    if ($normalized -notin @('acore','tcore')) {
        Write-Error "PHP playermap is only supported for acore or tcore."
        exit 1
    }

    Write-Host "Launching $normalized playermap (PHP) on localhost:8000..."

    # reuse your existing logic
    $mapDir = "${normalized}_map\playermap"
    $basePath = Get-MapPath $mapDir

    if (Test-Path $basePath) {
        Set-Location $basePath
    } else {
        Set-Location ~
    }

    # start the PHP built-in server
    php -S localhost:8000
    exit 0
}

# Otherwise must be js, ts, or py
$jsTsPyDirs = @{
    'acore'      = @{ js='js_map';     ts='ts_map';     py='py_map';      pyScript='app.py' }
    'tcore'      = @{ js='js_map';     ts='ts_map';     py='py_map';      pyScript='app.py' }
    'cmangos'    = @{ js='js_map_tbc'; ts='ts_map_tbc'; py='py_map';      pyScript='app_cmangos.py' }
    'cmangos-tbc'= @{ js='js_map_tbc'; ts='ts_map_tbc'; py='py_map';      pyScript='app_cmangos.py' }
    'vmangos'    = @{ js='js_map_tbc'; ts='ts_map_tbc'; py='py_map';      pyScript='app_cmangos.py' }
    'mangoszero' = @{ js='js_map_tbc'; ts='ts_map_tbc'; py='py_map';      pyScript='app_cmangos.py' }
}

if ($jsTsPyDirs.ContainsKey($normalized)) {
    $config = $jsTsPyDirs[$normalized]
    $subdir = $config[$Lang]
    $fullPath = Get-MapPath $subdir

    if (-not (Test-Path $fullPath)) {
        Write-Error "Directory not found: $fullPath"
        exit 1
    }

    Write-Host "Launching $normalized playermap ($Lang) in $fullPath..."
    Set-Location $fullPath

    switch ($Lang) {
        'js' {
            $cmd = 'npm run dev'
            Write-Host "Running: $cmd"
            & npm run dev
        }
        'ts' {
            $cmd = 'npm run dev:watch'
            Write-Host "Running: $cmd"
            & npm run 'dev:watch'
        }
        'py' {
            $script = $config['pyScript']
            $cmd    = "python $script"
            Write-Host "Running: $cmd"
            & python $config['pyScript']
        }
    }
} else {
    # should never happen, but safe-guard
    Write-Error "Unexpected error: no configuration for server '$normalized'"
    exit 1
}

