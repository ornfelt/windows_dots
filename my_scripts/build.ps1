# This script prints relevant build commands based on cwd
# see:
# {my_notes_path}/scripts/build_script_desc.txt

$cwd = (Get-Location).Path.ToLower()
$cwdFull = (Get-Location).Path

$isLinux = $IsLinux -or ($PSVersionTable.Platform -eq 'Unix')

# Helpers

function Write-Label($text) {
    Write-Host "  $text" -ForegroundColor DarkGray
}

function Write-Cmd($text) {
    Write-Host "  $text" -ForegroundColor Cyan
}

function Write-Alt($text) {
    Write-Host "  $text" -ForegroundColor Magenta
}

function Write-Extra($text) {
    Write-Host "  $text" -ForegroundColor Blue
}

function Write-Warn($text) {
    # Closest to orange in PowerShell's ConsoleColor is DarkYellow
    Write-Host $text -ForegroundColor DarkYellow
}

function Write-Header($text) {
    Write-Host ""
    Write-Host "  === $text ===" -ForegroundColor White
    Write-Host ""
}

# Check that keywords appear in the path in the given order (case-insensitive)
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

# Match rules

$matched = $false

# code2 -> my_web_wow -> go
if (Test-PathContainsInOrder @("code2", "go", "my_web_wow")) {
    Write-Header "Go (my_web_wow)"
    Write-Label  "use this:"
    Write-Cmd    "go build -tags async"
    Write-Host   ""
    Write-Cmd    "go build"
    Write-Alt    "go run ."
    $matched = $true
}

# code2 -> my_web_wow -> rust
elseif (Test-PathContainsInOrder @("code2", "rust", "my_web_wow")) {
    Write-Header "Rust (my_web_wow)"
    Write-Label  "use this:"
    Write-Cmd    "cargo build --features use_async"
    Write-Host   ""
    Write-Cmd    "cargo build"
    Write-Alt    "cargo run"
    Write-Alt    "cargo run --release"
    Write-Extra  'cargo run --release *> test.txt'
    $matched = $true
}

# code2 -> webwowviewer
elseif (Test-PathContainsInOrder @("code2", "webwowviewer")) {
    Write-Header "Web WoW Viewer (npm)"
    Write-Label  "use this:"
    Write-Cmd    "npm run start"
    Write-Host   ""
    Write-Cmd    "npm run server"
    Write-Alt    "npm run build"
    Write-Extra  "npm run build:prod"
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
