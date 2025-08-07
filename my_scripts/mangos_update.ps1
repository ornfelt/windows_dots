param (
    [string]$server
)

# Usage:
# .\mangos_update.ps1 0
# .\mangos_update.ps1 c
# .\mangos_update.ps1 tbc
# .\mangos_update.ps1

$codeRoot = $env:code_root_dir
if (-not $codeRoot) {
    Write-Error "Environment variable 'code_root_dir' is not set."
    exit 1
}

# Normalize slashes
$codeRoot = $codeRoot -replace '\\', '/'

switch -regex ($server) {
    '^(0|z)$' {
        Write-Host "Updating MangosZero..."
        $repoPath = "$codeRoot/Code2/C++/server"
        if (Test-Path $repoPath) {
            Set-Location $repoPath
            git pull
            #pwd
            #ls
        } else {
            Write-Warning "Path not found: $repoPath"
        }
    }
    '^c$' {
        Write-Host "Updating Cmangos..."
        $repoPath = "$codeRoot/Code2/C++/mangos-classic"
        $botPath = "$repoPath/src/modules/PlayerBots"
        if (Test-Path $repoPath) {
            Set-Location $repoPath
            git pull
            if (Test-Path $botPath) {
                Set-Location $botPath
                git pull
                Set-Location $repoPath
            } else {
                Write-Warning "Bot module path not found: $botPath"
            }
        } else {
            Write-Warning "Path not found: $repoPath"
        }
    }
    '^tbc$' {
        Write-Host "Updating Cmangos TBC..."
        $repoPath = "$codeRoot/Code2/C++/mangos-tbc"
        $botPath = "$repoPath/src/modules/PlayerBots"
        if (Test-Path $repoPath) {
            Set-Location $repoPath
            git pull
            if (Test-Path $botPath) {
                Set-Location $botPath
                git pull
                Set-Location $repoPath
            } else {
                Write-Warning "Bot module path not found: $botPath"
            }
        } else {
            Write-Warning "Path not found: $repoPath"
        }
    }
    default {
        Write-Host "Updating Vmangos..."
        $repoPath = "$codeRoot/Code2/C++/core"
        if (Test-Path $repoPath) {
            Set-Location $repoPath
            git pull
            #pwd
            #ls
        } else {
            Write-Warning "Path not found: $repoPath"
        }
    }
}
