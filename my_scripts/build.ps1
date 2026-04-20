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

# code2 -> go -> my_web_wow
if (Test-PathContainsInOrder @("code2", "go", "my_web_wow")) {
    Write-Header "Go (my_web_wow)"
    Write-Label  "use this:"
    Write-Cmd    "go build -tags async"
    Write-Label  "or:"
    Write-Cmd    'go build -tags "async cimgui"'
    Write-Label  "or:"
    Write-Cmd    "go build"
    Write-Label  "or:"
    Write-Alt    "go run ."
    Write-Label  "or:"
    Write-Alt    "./build.ps1"
    Write-Label  "or:"
    Write-Cmd    "rm my_web_wow.exe; go build -tags async; ./my_web_wow.exe"
    $matched = $true
}

# code2 -> go -> tbc
elseif (Test-PathContainsInOrder @("code2", "go", "tbc")) {
    Write-Header "Go (tbc)"
    Write-Label  "use this:"
    Write-Cmd    "go build"
    Write-Label  "or:"
    Write-Cmd    'go build; ./my_wow.exe *> test.txt'
    Write-Label  "or:"
    Write-Alt    "go run ."
    $matched = $true
}

# code2 -> rust -> my_web_wow
elseif (Test-PathContainsInOrder @("code2", "rust", "my_web_wow")) {
    Write-Header "Rust (my_web_wow)"
    Write-Cmd    "cargo build --features use_async"
    Write-Cmd    "cargo build"
    Write-Host   ""
    Write-Cmd    "cargo run"
    Write-Cmd    "cargo run --features use_async"
    Write-Cmd    "cargo run --features with_imgui"
    Write-Cmd    'cargo run --features "with_imgui use_async"'
    Write-Alt    "cargo run --release"
    Write-Extra  'cargo run --release *> test.txt'
    Write-Host   ""
    Write-Label  "override expansion (default from server/env):"
    Write-Cmd    "cargo run --features with_imgui -- --expansion tbc"
    Write-Host   ""
    Write-Label  "specific map key (default expansion):"
    Write-Cmd    "cargo run -- --map orgrimmar"
    Write-Cmd    "cargo run -- --map ragnaros"
    Write-Host   ""
    Write-Label  "both map and expansion:"
    Write-Cmd    "cargo run -- --map dragonblight --expansion wotlk"
    Write-Cmd    "cargo run -- --map darkshire --expansion classic"
    Write-Cmd    "cargo run -- --map ragnaros --expansion classic"
    $matched = $true
}

# code2 -> rust -> tbc
elseif (Test-PathContainsInOrder @("code2", "rust", "tbc")) {
    Write-Header "Rust (tbc)"
    Write-Cmd    "cargo build --features use_sound"
    Write-Cmd    'cargo build --features "use_sound threadsafe"'
    Write-Label  "or without features:"
    Write-Cmd    "cargo build"
    Write-Label  "disable all defaults, enable explicitly:"
    Write-Cmd    "cargo build --no-default-features --features threadsafe"
    Write-Host   ""
    Write-Label  "redirect output:"
    Write-Extra  'cargo build *> test.txt'
    Write-Extra  'cargo run *> test.txt'
    Write-Extra  'cargo run --release *> test.txt'
    Write-Host   ""
    Write-Label  "backtrace:"
    Write-Alt    "RUST_BACKTRACE=1 cargo run"
    Write-Alt    "RUST_BACKTRACE=full cargo run"
    Write-Host   ""
    Write-Label  "dt flag (default ON):"
    Write-Cmd    "cargo run --"
    Write-Cmd    "cargo run -- --use-dt"
    Write-Cmd    "cargo run -- --no-use-dt"
    Write-Cmd    "cargo run -- --use-dt=false"
    Write-Host   ""
    Write-Label  "with map:"
    Write-Cmd    "cargo run av"
    Write-Cmd    "cargo run help"
    Write-Cmd    "cargo run -- --map wsg"
    Write-Cmd    "cargo run -- nagrandarena --use-dt=false"
    Write-Cmd    "cargo run -- --map ab --no-use-dt"
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
    Write-Host   ""
    Write-Label  "Also start wow mpq file server"
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
    Write-Header "my_js / MySQL"
    Write-Cmd "node main.js"
    $matched = $true
}

# code2 -> my_js -> navigation
elseif (Test-PathContainsInOrder @("code2", "my_js", "navigation")) {
    Write-Header "my_js / Navigation"
    Write-Cmd "node main.js"
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
    Write-Header "orders_ts"
    Write-Cmd "npm run start"
    $matched = $true
}

# my_notes -> latest-orders-ts
elseif (Test-PathContainsInOrder @("my_notes", "latest-orders-ts")) {
    Write-Header "latest-orders-ts"
    if ($isLinux) {
        Write-Cmd "npx tsc && node ./dist/server.js"
    } else {
        Write-Cmd 'npx tsc; node .\dist\server.js'
    }
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
