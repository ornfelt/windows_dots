# This script prints relevant build commands based on cwd
# see:
# {my_notes_path}/scripts/build_script_desc.txt

param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$FilterArgs
)

$cwd     = (Get-Location).Path.ToLower()
$cwdFull = (Get-Location).Path

$isLinux = $IsLinux -or ($PSVersionTable.Platform -eq 'Unix')

# Output helpers

function Write-Label($text) { Write-Host "  $text" -ForegroundColor DarkGray }
function Write-Cmd  ($text) { Write-Host "  $text" -ForegroundColor Cyan     }
function Write-Alt  ($text) { Write-Host "  $text" -ForegroundColor Magenta  }
function Write-Extra($text) { Write-Host "  $text" -ForegroundColor Blue     }
function Write-Warn ($text) { Write-Host $text    -ForegroundColor DarkYellow }

function Write-Header($text) {
    Write-Host ""
    Write-Host "  === $text ===" -ForegroundColor White
    Write-Host ""
}

function Write-SubHeader($text) {
    Write-Host ""
    Write-Host "  --- $text ---" -ForegroundColor White
}

function Resolve-Filters {
    param([string[]]$RawArgs)
    if (-not $RawArgs -or $RawArgs.Count -eq 0) { return @() }
    $result = @()
    foreach ($a in $RawArgs) {
        if ($null -eq $a) { continue }
        foreach ($p in ($a -split '[,\s]+' | Where-Object { $_ })) {
            $result += $p.ToLower()
        }
    }
    return $result
}

$Filters = Resolve-Filters -RawArgs $FilterArgs


# Path matching helpers

function Test-PathContainsInOrder {
    param([string[]]$keywords)
    $pos = 0
    foreach ($kw in $keywords) {
        $idx = $cwd.IndexOf($kw.ToLower(), $pos)
        if ($idx -lt 0) { return $false }
        $pos = $idx + $kw.Length
    }
    return $true
}

# Usage-example extraction

function Get-CommentSyntax {
    param([string]$Extension)
    switch ($Extension.ToLower()) {
        { $_ -in '.go', '.rs', '.js', '.ts', '.jsx', '.tsx', '.mjs', '.cjs',
                 '.c', '.cpp', '.cc', '.h', '.hpp', '.cs', '.java',
                 '.kt', '.swift', '.php' } {
            return @{ Single = '//'; MultiStart = '/*'; MultiEnd = '*/' }
        }
        '.py'  { return @{ Single = '#';  MultiStart = '"""';    MultiEnd = '"""'  } }
        '.rb'  { return @{ Single = '#';  MultiStart = '=begin'; MultiEnd = '=end' } }
        '.sh'  { return @{ Single = '#';  MultiStart = $null;    MultiEnd = $null  } }
        '.ps1' { return @{ Single = '#';  MultiStart = '<#';     MultiEnd = '#>'   } }
        '.lua' { return @{ Single = '--'; MultiStart = '--[[';   MultiEnd = ']]'   } }
        '.sql' { return @{ Single = '--'; MultiStart = '/*';     MultiEnd = '*/'   } }
        { $_ -in '.html', '.xml' } {
            return @{ Single = $null; MultiStart = '<!--'; MultiEnd = '-->' }
        }
        default { return @{ Single = '//'; MultiStart = '/*'; MultiEnd = '*/' } }
    }
}

function Get-UsageExamples {
    param([string]$FilePath)

    $ret = @{
        FileExists = $false
        Found      = $false
        Lines      = @()
        FilePath   = $FilePath
    }

    if (-not (Test-Path -LiteralPath $FilePath)) { return $ret }
    $ret.FileExists = $true

    $ext       = [System.IO.Path]::GetExtension($FilePath)
    $syntax    = Get-CommentSyntax -Extension $ext
    $single    = $syntax.Single
    $mStart    = $syntax.MultiStart
    $mEnd      = $syntax.MultiEnd
    $hasSingle = -not [string]::IsNullOrEmpty($single)
    $hasMulti  = -not [string]::IsNullOrEmpty($mStart)

    $lines         = @(Get-Content -LiteralPath $FilePath)
    $markerPattern = '(?i)(example\s+usage|usage\s+examples)\s*:'

    $result  = @()
    $inBlock = $false

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        $m    = [regex]::Match($line, $markerPattern)

        if (-not $m.Success) {
            if ($hasMulti) {
                $pos = 0
                while ($true) {
                    if (-not $inBlock) {
                        $sIdx = $line.IndexOf($mStart, $pos)
                        if ($sIdx -lt 0) { break }
                        $inBlock = $true
                        $pos = $sIdx + $mStart.Length
                    } else {
                        $eIdx = $line.IndexOf($mEnd, $pos)
                        if ($eIdx -lt 0) { break }
                        $inBlock = $false
                        $pos = $eIdx + $mEnd.Length
                    }
                }
            }
            continue
        }

        $markerIdx = $m.Index
        $markerEnd = $markerIdx + $m.Length
        $isMulti   = $false
        $isSingle  = $false

        if ($inBlock) {
            $isMulti = $true
        } elseif ($hasMulti) {
            $startIdx = $line.IndexOf($mStart)
            $endIdx   = $line.IndexOf($mEnd)
            if ($startIdx -ge 0 -and $startIdx -lt $markerIdx -and
                ($endIdx -lt 0 -or $endIdx -gt $markerIdx)) {
                $isMulti = $true
            }
        }

        if (-not $isMulti -and $hasSingle) {
            if ($line.TrimStart().StartsWith($single)) { $isSingle = $true }
        }

        if (-not ($isMulti -or $isSingle)) {
            if ($hasMulti) {
                $pos = 0
                while ($true) {
                    if (-not $inBlock) {
                        $sIdx = $line.IndexOf($mStart, $pos)
                        if ($sIdx -lt 0) { break }
                        $inBlock = $true
                        $pos = $sIdx + $mStart.Length
                    } else {
                        $eIdx = $line.IndexOf($mEnd, $pos)
                        if ($eIdx -lt 0) { break }
                        $inBlock = $false
                        $pos = $eIdx + $mEnd.Length
                    }
                }
            }
            continue
        }

        $ret.Found = $true

        if ($isMulti) {
            $rest         = $line.Substring($markerEnd)
            $endPosOnSame = $rest.IndexOf($mEnd)
            if ($endPosOnSame -ge 0) {
                $before = $rest.Substring(0, $endPosOnSame).Trim()
                if ($before) { $result += $before }
                $after  = $rest.Substring($endPosOnSame + $mEnd.Length).Trim()
                if ($after)  { $result += $after }
                $ret.Lines = $result
                return $ret
            } else {
                $restTrim = $rest.Trim()
                if ($restTrim) { $result += $restTrim }
            }

            for ($j = $i + 1; $j -lt $lines.Count; $j++) {
                $l      = $lines[$j]
                $endPos = $l.IndexOf($mEnd)
                if ($endPos -ge 0) {
                    $before      = $l.Substring(0, $endPos)
                    $beforeClean = ($before.TrimStart() -replace '^\*+\s?', '').TrimEnd()
                    if ($beforeClean) { $result += $beforeClean }
                    $after = $l.Substring($endPos + $mEnd.Length).Trim()
                    if ($after)       { $result += $after }
                    break
                } else {
                    $cleaned = ($l.TrimStart() -replace '^\*+\s?', '').TrimEnd()
                    $result += $cleaned
                }
            }

            $ret.Lines = $result
            return $ret
        }

        if ($isSingle) {
            for ($j = $i + 1; $j -lt $lines.Count; $j++) {
                $lTrim = $lines[$j].TrimStart()
                if ($lTrim.StartsWith($single)) {
                    $stripped = $lTrim.Substring($single.Length)
                    if ($stripped.StartsWith(' ')) { $stripped = $stripped.Substring(1) }
                    $result += $stripped.TrimEnd()
                } else {
                    break
                }
            }

            $ret.Lines = $result
            return $ret
        }
    }

    return $ret
}

function Render-UsageFromFile {
    param([string]$FilePath)

    $info = Get-UsageExamples -FilePath $FilePath

    if (-not $info.FileExists) {
        Write-Warn "  [!] File not found:"
        Write-Host "      $FilePath" -ForegroundColor DarkYellow
        return
    }
    if (-not $info.Found) {
        Write-Warn "  [!] No 'example usage:' or 'usage examples:' marker found in:"
        Write-Host "      $FilePath" -ForegroundColor DarkYellow
        return
    }
    if ($info.Lines.Count -eq 0) {
        Write-Warn "  [!] Marker found but no example content extracted from:"
        Write-Host "      $FilePath" -ForegroundColor DarkYellow
        return
    }

    foreach ($ln in $info.Lines) {
        $trimmed = $ln.TrimEnd()

        if ([string]::IsNullOrWhiteSpace($ln)) {
            Write-Host ""
        }
        elseif ($trimmed.EndsWith(':')) {
            Write-Label $ln
        }
        elseif ($trimmed.TrimStart() -match '^(?i)note\s*:') {
            Write-Label $ln
        }
        elseif ($trimmed -notmatch '[A-Za-z]') {
            # no alphabetical chars (e.g. "---", "====", "***") => treat as label
            Write-Label $ln
        }
        else {
            Write-Cmd $ln
        }
    }
}

# Resolve <env>/<relative path> and render in one step.
function Show-Project {
    param(
        [string]$HeaderText,
        [string]$EnvVarName,
        [string]$RelativePath
    )

    Write-Header $HeaderText

    $root = [Environment]::GetEnvironmentVariable($EnvVarName)
    if ([string]::IsNullOrWhiteSpace($root)) {
        Write-Warn "  [!] Environment variable '`$Env:$EnvVarName' is not set."
        return
    }

    $fullPath = $root
    foreach ($part in ($RelativePath -split '[/\\]' | Where-Object { $_ })) {
        $fullPath = Join-Path $fullPath $part
    }

    Render-UsageFromFile -FilePath $fullPath
}

# Render multiple files under a single header, each preceded by a sub-header.
function Show-ProjectMulti {
    param(
        [string]$HeaderText,
        [string]$EnvVarName,
        [string[]]$RelativePaths,
        [string[]]$Filters
    )

    Write-Header $HeaderText

    $root = [Environment]::GetEnvironmentVariable($EnvVarName)
    if ([string]::IsNullOrWhiteSpace($root)) {
        Write-Warn "  [!] Environment variable '`$Env:$EnvVarName' is not set."
        return
    }

    $selected = $RelativePaths
    if ($Filters -and $Filters.Count -gt 0) {
        $selected = @()
        foreach ($rel in $RelativePaths) {
            $leaf = (Split-Path -Leaf $rel).ToLower()
            foreach ($f in $Filters) {
                if ($leaf.Contains($f)) { $selected += $rel; break }
            }
        }
        if ($selected.Count -eq 0) {
            Write-Warn "  [!] No files matched filter(s): $($Filters -join ', ')"
            Write-Label "Available:"
            foreach ($rel in $RelativePaths) {
                Write-Host "      $(Split-Path -Leaf $rel)" -ForegroundColor DarkYellow
            }
            return
        }
    }

    foreach ($rel in $selected) {
        $fullPath = $root
        foreach ($part in ($rel -split '[/\\]' | Where-Object { $_ })) {
            $fullPath = Join-Path $fullPath $part
        }

        $leaf = Split-Path -Leaf $fullPath
        Write-SubHeader $leaf
        Render-UsageFromFile -FilePath $fullPath
    }
}

# Match rules

$matched = $false

# code2 -> go -> my_web_wow
if (Test-PathContainsInOrder @("code2", "go", "my_web_wow")) {
    Show-Project -HeaderText 'Go (my_web_wow)' `
                 -EnvVarName 'code_root_dir' `
                 -RelativePath 'Code2/Wow/tools/my_wow/go/my_web_wow/main.go'
    $matched = $true
}

# code2 -> go -> tbc
elseif (Test-PathContainsInOrder @("code2", "go", "tbc")) {
    Show-Project -HeaderText 'Go (tbc)' `
                 -EnvVarName 'code_root_dir' `
                 -RelativePath 'Code2/Wow/tools/my_wow/go/tbc/main.go'
    $matched = $true
}

# code2 -> rust -> my_web_wow
elseif (Test-PathContainsInOrder @("code2", "rust", "my_web_wow")) {
    Show-Project -HeaderText 'Rust (my_web_wow)' `
                 -EnvVarName 'code_root_dir' `
                 -RelativePath 'Code2/Wow/tools/my_wow/rust/my_web_wow/src/main.rs'
    $matched = $true
}

# code2 -> rust -> tbc
elseif (Test-PathContainsInOrder @("code2", "rust", "tbc")) {
    Show-Project -HeaderText 'Rust (tbc)' `
                 -EnvVarName 'code_root_dir' `
                 -RelativePath 'Code2/Wow/tools/my_wow/rust/tbc/src/main.rs'
    $matched = $true
}

# code2 -> py -> my_web_wow
elseif (Test-PathContainsInOrder @("code2", "py", "my_web_wow")) {
    Show-Project -HeaderText 'Python (my_web_wow)' `
                 -EnvVarName 'code_root_dir' `
                 -RelativePath 'Code2/Wow/tools/my_wow/python/my_web_wow/main.py'
    $matched = $true
}

# code2 -> py -> tbc
elseif (Test-PathContainsInOrder @("code2", "py", "tbc")) {
    Show-Project -HeaderText 'Python (tbc)' `
                 -EnvVarName 'code_root_dir' `
                 -RelativePath 'Code2/Wow/tools/my_wow/python/tbc/main.py'
    $matched = $true
}

# code2 -> c# -> my_web_wow
elseif (Test-PathContainsInOrder @("code2", "c#", "my_web_wow")) {
    Show-Project -HeaderText 'C# (my_web_wow)' `
                 -EnvVarName 'code_root_dir' `
                 -RelativePath 'Code2/Wow/tools/my_wow/c#/my_web_wow/my_web_wow/Program.cs'
    $matched = $true
}

# code2 -> c# -> tbc
elseif (Test-PathContainsInOrder @("code2", "c#", "tbc")) {
    Show-Project -HeaderText 'C# (tbc)' `
                 -EnvVarName 'code_root_dir' `
                 -RelativePath 'Code2/Wow/tools/my_wow/c#/tbc/tbc/Program.cs'
    $matched = $true
}

# code2 -> gfx -> wc_testing_go   (must come before wc_testing)
elseif (Test-PathContainsInOrder @("code2", "gfx", "wc_testing_go")) {
    Show-ProjectMulti -HeaderText 'WC Testing (Go)' `
                      -EnvVarName 'code_root_dir' `
                      -RelativePaths @(
                          'Code2/General/gfx/wc_testing_go/adt_app.go',
                          'Code2/General/gfx/wc_testing_go/m2_app.go',
                          'Code2/General/gfx/wc_testing_go/wdl_app.go',
                          'Code2/General/gfx/wc_testing_go/wmo_app.go'
                      ) `
                      -Filters $Filters
    $matched = $true
}

# code2 -> gfx -> wc_testing_py   (must come before wc_testing)
elseif (Test-PathContainsInOrder @("code2", "gfx", "wc_testing_py")) {
    Show-ProjectMulti -HeaderText 'WC Testing (Python)' `
                      -EnvVarName 'code_root_dir' `
                      -RelativePaths @(
                          'Code2/General/gfx/wc_testing_py/adt_app.py',
                          'Code2/General/gfx/wc_testing_py/m2_app.py',
                          'Code2/General/gfx/wc_testing_py/wdl_app.py',
                          'Code2/General/gfx/wc_testing_py/wmo_app.py'
                      ) `
                      -Filters $Filters
    $matched = $true
}

# code2 -> gfx -> wc_testing_rs   (must come before wc_testing)
elseif (Test-PathContainsInOrder @("code2", "gfx", "wc_testing_rs")) {
    Show-ProjectMulti -HeaderText 'WC Testing (Rust)' `
                      -EnvVarName 'code_root_dir' `
                      -RelativePaths @(
                          'Code2/General/gfx/wc_testing_rs/src/adt_app.rs',
                          'Code2/General/gfx/wc_testing_rs/src/m2_app.rs',
                          'Code2/General/gfx/wc_testing_rs/src/wdl_app.rs',
                          'Code2/General/gfx/wc_testing_rs/src/wmo_app.rs'
                      ) `
                      -Filters $Filters
    $matched = $true
}

# code2 -> gfx -> wc_testing   (C# variant, plain name)
elseif (Test-PathContainsInOrder @("code2", "gfx", "wc_testing")) {
    Show-ProjectMulti -HeaderText 'WC Testing (C#)' `
                      -EnvVarName 'code_root_dir' `
                      -RelativePaths @(
                          'Code2/General/gfx/wc_testing/AdtApp.cs',
                          'Code2/General/gfx/wc_testing/M2App.cs',
                          'Code2/General/gfx/wc_testing/WdlApp.cs',
                          'Code2/General/gfx/wc_testing/WmoApp.cs'
                      ) `
                      -Filters $Filters
    $matched = $true
}

# my_notes -> scripts -> live_plotext / live_termplot (same file set)
elseif ((Test-PathContainsInOrder @("my_notes", "scripts", "live_plotext")) -or
        (Test-PathContainsInOrder @("my_notes", "scripts", "live_termplot"))) {

    if (Test-PathContainsInOrder @("my_notes", "scripts", "live_plotext")) {
        $folder = 'live_plotext'
    } else {
        $folder = 'live_termplot'
    }

    $liveFiles = @(
        'live_address.py',
        'live_audit.py',
        'live_filejobs.py',
        'live_general.py',
        'live_orders.py',
        'live_pending.py',
        'live_useractionlog.py'
    )
    $relPaths = $liveFiles | ForEach-Object { "notes/svea/scripts/stats/$folder/$_" }

    Show-ProjectMulti -HeaderText $folder `
                      -EnvVarName 'my_notes_path' `
                      -RelativePaths $relPaths `
                      -Filters $Filters
    $matched = $true
}

# code2 -> webwowviewer   (prefer .ts, fall back to .js)
elseif (Test-PathContainsInOrder @("code2", "webwowviewer")) {
    Write-Header 'Web WoW Viewer (npm)'
    $root = [Environment]::GetEnvironmentVariable('code_root_dir')
    if ([string]::IsNullOrWhiteSpace($root)) {
        Write-Warn "  [!] Environment variable '`$Env:code_root_dir' is not set."
    } else {
        $tsPath = Join-Path $root 'Code2/Wow/tools/WebWowViewer/js/application/angular/app_wow.ts'
        $jsPath = Join-Path $root 'Code2/Wow/tools/WebWowViewer/js/application/angular/app_wowjs.js'
        if (Test-Path -LiteralPath $tsPath) {
            Render-UsageFromFile -FilePath $tsPath
        } elseif (Test-Path -LiteralPath $jsPath) {
            Render-UsageFromFile -FilePath $jsPath
        } else {
            Write-Warn "  [!] Neither of these files exist:"
            Write-Host "      $tsPath" -ForegroundColor DarkYellow
            Write-Host "      $jsPath" -ForegroundColor DarkYellow
        }
    }
    $matched = $true
}

# code2 -> spelunker
elseif (Test-PathContainsInOrder @("code2", "spelunker")) {
    Write-Header "Spelunker"
    Write-Label "setup:"
    if ($isLinux) {
        Write-Cmd  'cd $HOME/Documents/my_notes/scripts/wow/spelunker'
        Write-Cmd  "./setup.sh"
    } else {
        Write-Cmd  'cd $Env:my_notes_path/scripts/wow/spelunker'
        Write-Cmd  "./setup.ps1"
    }
    Write-Host ""
    Write-Label "start wow mpq file server and do (in both spelunker-api and spelunker-web):"
    if ($isLinux) {
        Write-Cmd  "source ../../.envrc && npm start"
    } else {
        Write-Cmd  'Push-Location; cd ..\..; .\load_env.ps1; Pop-Location; npm start'
    }
    Write-Host ""
    Write-Label "If needed for file server (if mounted) you might need:"
    Write-Extra "npm install express cors --no-bin-links"
    $matched = $true
}

# code2 -> azeroth-web-proxy  (must come before azeroth-web)
elseif (Test-PathContainsInOrder @("code2", "azeroth-web-proxy")) {
    Write-Header "Azeroth Web Proxy"
    Write-Cmd   "npm start"
    Write-Host  ""
    Write-Label "Also run script in my_notes via:"
    if ($isLinux) {
        Write-Cmd  'cd $HOME/Documents/my_notes/scripts/wow/azeroth-web'
        Write-Cmd  "./setup.sh"
    } else {
        Write-Cmd  'cd $Env:my_notes_path/scripts/wow/azeroth-web'
        Write-Cmd  "./setup.ps1"
    }
    Write-Host ""
    Write-Label "Also start either acore/tcore to be able to login!"
    $matched = $true
}

# code2 -> azeroth-web
elseif (Test-PathContainsInOrder @("code2", "azeroth-web")) {
    Write-Header "Azeroth Web"
    Write-Cmd   "npm install -g typescript"
    Write-Cmd   "npm run dev"
    Write-Host  ""
    Write-Label "Also run script in my_notes via:"
    if ($isLinux) {
        Write-Cmd  'cd $HOME/Documents/my_notes/scripts/wow/azeroth-web'
        Write-Cmd  "./setup.sh"
    } else {
        Write-Cmd  'cd $Env:my_notes_path/scripts/wow/azeroth-web'
        Write-Cmd  "./setup.ps1"
    }
    Write-Host ""
    Write-Label "Also start either acore/tcore to be able to login!"
    $matched = $true
}

# code2 -> wowser
elseif (Test-PathContainsInOrder @("code2", "wowser")) {
    Write-Header "Wowser"
    Write-Label "Run script in my_notes via:"
    if ($isLinux) {
        Write-Cmd  'cd $HOME/Documents/my_notes/scripts/wow/wowser'
        Write-Cmd  "./setup.sh"
    } else {
        Write-Cmd  'cd $Env:my_notes_path/scripts/wow/wowser'
        Write-Cmd  "./setup.ps1"
    }
    Write-Host ""
    Write-Cmd   "npm run serve"
    Write-Label "NOTE: specify wow client dir after running npm run serve!"
    Write-Label "you may need this if client dir is wrong:"
    Write-Alt   "npm run reset"
    Write-Label "use:"
    Write-Extra '$Env:wow_dir'
    Write-Host ""
    Write-Label "then, in another shell:"
    Write-Cmd   "npm run web-dev"
    $matched = $true
}

# code2 -> my_js -> mysql
elseif (Test-PathContainsInOrder @("code2", "my_js", "mysql")) {
    Show-Project -HeaderText 'my_js / MySQL' `
                 -EnvVarName 'code_root_dir' `
                 -RelativePath 'Code2/Javascript/my_js/Testing/mysql/main.js'
    $matched = $true
}

# code2 -> my_js -> navigation -> ffi-napi   (must come before plain navigation)
elseif (Test-PathContainsInOrder @("code2", "my_js", "navigation", "ffi-napi")) {
    Show-Project -HeaderText 'my_js / Navigation (ffi-napi)' `
                 -EnvVarName 'code_root_dir' `
                 -RelativePath 'Code2/Javascript/my_js/Testing/navigation/ffi-napi/main.js'
    $matched = $true
}

# code2 -> my_js -> navigation
elseif (Test-PathContainsInOrder @("code2", "my_js", "navigation")) {
    Show-Project -HeaderText 'my_js / Navigation' `
                 -EnvVarName 'code_root_dir' `
                 -RelativePath 'Code2/Javascript/my_js/Testing/navigation/main.js'
    $matched = $true
}

# code2 -> my_js -> keybinds
elseif (Test-PathContainsInOrder @("code2", "my_js", "keybinds")) {
    Write-Header "my_js / Keybinds"
    Write-Label "do this:"
    Write-Cmd   "npm run dev"
    Write-Host  ""
    Write-Alt   "npm run start"
    $matched = $true
}

# my_notes -> orders_ts
elseif (Test-PathContainsInOrder @("my_notes", "orders_ts")) {
    Show-Project -HeaderText 'orders_ts' `
                 -EnvVarName 'my_notes_path' `
                 -RelativePath 'notes/svea/scripts/orders_ts/src/orders.ts'
    $matched = $true
}

# my_notes -> latest-orders-ts
elseif (Test-PathContainsInOrder @("my_notes", "latest-orders-ts")) {
    Show-Project -HeaderText 'latest-orders-ts' `
                 -EnvVarName 'my_notes_path' `
                 -RelativePath 'notes/svea/scripts/stats/latest-orders-ts/app/src/server.ts'
    $matched = $true
}

# Fallback: check files in current directory
else {
    $files = Get-ChildItem -Name -ErrorAction SilentlyContinue

    if (($files -contains "worldserver.exe") -and ($files -contains "authserver.exe")) {
        Write-Header "World Server"
        if ($isLinux) {
            Write-Cmd   "python overwrite.py && ./worldserver.exe"
            Write-Host  ""
            Write-Label "Linux gdb:"
            Write-Alt   "python overwrite.py && gdb -x gdb.conf --batch ./worldserver"
        } else {
            Write-Cmd   'python overwrite.py; .\worldserver.exe'
        }
        $matched = $true
    }
    elseif (($files -contains "cors_server.js") -and ($files -contains "cors_server.py")) {
        Write-Header "CORS Server"
        Write-Cmd  "node ./cors_server.js"
        Write-Alt  "python ./cors_server.py"
        $matched = $true
    }
}

# No match

if (-not $matched) {
    Write-Host ""
    Write-Warn "  [!] No build commands matched for:"
    Write-Host "      $cwdFull" -ForegroundColor DarkYellow
    Write-Host ""
}
