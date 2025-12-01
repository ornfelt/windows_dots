param(
    [Parameter(Position = 0)]
    [string]$Language
)

# Map all aliases -> normalized language name
$languageMap = @{
    'c'          = 'c'
    'cs'         = 'csharp'
    'c#'         = 'csharp'
    'csharp'     = 'csharp'
    'cpp'        = 'cpp'
    'c++'        = 'cpp'
    'go'         = 'go'
    'golang'     = 'go'
    'java'       = 'java'
    'js'         = 'javascript'
    'javascript' = 'javascript'
    'ts'         = 'typescript'
    'typescript' = 'typescript'
    'py'         = 'python'
    'python'     = 'python'
    'rust'       = 'rust'
    'rs'         = 'rust'
}

function Write-CommandWithDescription {
    param(
        [string]$Command,
        [string]$Description,
        [ConsoleColor]$Color
    )

    Write-Host "  " -NoNewline
    Write-Host $Command -ForegroundColor $Color -NoNewline
    if ($Description) {
        Write-Host " - $Description"
    }
    else {
        Write-Host ""
    }
}

# Helper: write a code line, with any comment part ('#...') in gray
function Write-CodeLine {
    param(
        [string]$Text,
        [ConsoleColor]$CommandColor = [ConsoleColor]::Green,
        [ConsoleColor]$CommentColor = [ConsoleColor]::DarkGray
    )

    $hashIndex = $Text.IndexOf('#')
    if ($hashIndex -ge 0) {
        $before  = $Text.Substring(0, $hashIndex)
        $comment = $Text.Substring($hashIndex)

        if ($before.Trim().Length -gt 0) {
            Write-Host $before -ForegroundColor $CommandColor -NoNewline
        }
        Write-Host $comment -ForegroundColor $CommentColor
    } else {
        Write-Host $Text -ForegroundColor $CommandColor
    }
}

function Show-Usage {
    Write-Host "Available code language arguments (case-insensitive):"

    # Code language keywords in magenta / purple
    $languages = @(
        'c'
        'cs / c# / csharp'
        'cpp / c++'
        'go / golang'
        'java'
        'js / javascript'
        'ts / typescript'
        'py / python'
        'rust / rs'
    )

    foreach ($lang in $languages) {
        Write-Host "  $lang" -ForegroundColor Magenta
    }

    Write-Host ""
    Write-Host "Some useful dot commands:"

    # Dot commands: command in cyan, description in default color
    Write-Host "  Navigation / cd helpers:" -ForegroundColor DarkGray
    Write-CommandWithDescription ".cdn"   "cd into my_notes_path"             'Cyan'
    Write-CommandWithDescription ".cdc"   "cd into code_root_dir"             'Cyan'
    Write-CommandWithDescription ".cdp"   "cd into ps_profile_path"           'Cyan'
    Write-CommandWithDescription ".docs"  "cd into Documents"                 'Cyan'
    Write-CommandWithDescription ".down"  "cd into Downloads"                 'Cyan'
    Write-CommandWithDescription ".cdh"   "cd into home dir"                  'Cyan'
    Write-CommandWithDescription ".acore" "cd into acore dir"                 'Cyan'
    Write-CommandWithDescription ".tcore" "cd into tcore dir"                 'Cyan'
    Write-CommandWithDescription ".wcell" "cd into wcell dir"                 'Cyan'
    Write-CommandWithDescription ".playermap" "cd into playermap dir and run" 'Cyan'
    Write-CommandWithDescription ".mangos" "cd into mangos dir"               'Cyan'

    Write-Host ""
    Write-Host "  Run / launcher helpers:" -ForegroundColor DarkGray
    Write-CommandWithDescription ".ioq3"  "run ioq3"                          'Cyan'
    Write-CommandWithDescription ".openmw" "run openmw"                       'Cyan'
    Write-CommandWithDescription ".stk"   "run SuperTuxKart (stk)"            'Cyan'
    Write-CommandWithDescription ".wow"   "run World of Warcraft client"      'Cyan'
    Write-CommandWithDescription ".wowbot" "run wowbot"                       'Cyan'
    Write-CommandWithDescription ".llama" "run llama"                         'Cyan'
    Write-CommandWithDescription ".cava"  "run cava visualizer"               'Cyan'
    Write-CommandWithDescription ".wc"    "run wow client (wc)"               'Cyan'
    Write-CommandWithDescription ".mw"    "my_wow: cd_and_print"              'Cyan'
    Write-CommandWithDescription ".mww"   "my_web_wow: cd_and_print"          'Cyan'
    Write-CommandWithDescription ".mwr"   "my_wow: run_with_args.ps1 with args" 'Cyan'

    Write-Host ""
    Write-Host "  Listing helpers:" -ForegroundColor DarkGray
    Write-CommandWithDescription ".list_colors"      "print colors"                            'Cyan'
    Write-CommandWithDescription ".list_all_colors"  "print all colors"                        'Cyan'
    Write-CommandWithDescription ".list_std_colors"  "print standard colors"                   'Cyan'
    Write-CommandWithDescription ".list_files"       "list largest files recursively (CLI)"    'Cyan'
    Write-CommandWithDescription ".list_files_gui"   "list largest files recursively via GUI"  'Cyan'
    Write-CommandWithDescription ".list_p"           "list processes"                          'Cyan'
    Write-CommandWithDescription ".list_pm"          "list processes by memory usage"          'Cyan'
    Write-CommandWithDescription ".list_mapped_drives" "list mapped drives"                    'Cyan'

    Write-Host ""
    Write-Host "  Network helpers:" -ForegroundColor DarkGray
    Write-CommandWithDescription ".show_wifi"           "print stored Wi-Fi settings"          'Cyan'
    Write-CommandWithDescription ".network_devices"     "list network devices"                 'Cyan'
    Write-CommandWithDescription ".network_devices_ping" "ping common network devices"         'Cyan'

    Write-Host ""
    Write-Host "  Build / tools / maintenance:" -ForegroundColor DarkGray
    Write-CommandWithDescription ".cmake"   "helper script for cmake"                          'Cyan'
    Write-CommandWithDescription ".git_push"  "helper script for git push"                     'Cyan'
    Write-CommandWithDescription ".git_pull"  "helper script for git pull"                     'Cyan'
    Write-CommandWithDescription ".gen_plant" "generate PlantUML image"                        'Cyan'
    Write-CommandWithDescription ".gen_merm"  "generate Mermaid image"                         'Cyan'
    Write-CommandWithDescription ".acore_update"  "update acore repo"                          'Cyan'
    Write-CommandWithDescription ".tcore_update"  "update tcore repo"                          'Cyan'
    Write-CommandWithDescription ".mangos_update" "update mangos repo"                         'Cyan'
    Write-CommandWithDescription ".cmangos_update" "update cmangos repo"                       'Cyan'
    Write-CommandWithDescription ".update_nvim_from_linux" "update neovim config from Linux dots" 'Cyan'
    Write-CommandWithDescription ".clean_shada" "clean neovim shada data"                      'Cyan'
    Write-CommandWithDescription ".wow_wtf_update" "copy WoW WTF files into wow_addons repo"   'Cyan'
    Write-CommandWithDescription ".wow_wtf_fix"    "copy WoW WTF files from wow_addons repo to local WoW dir" 'Cyan'

    Write-Host ""
    Write-Host "Useful git commands:"

    Write-Host "# Display history with graph and decorate:" -ForegroundColor DarkGray
    Write-Host "git log --graph --decorate" -ForegroundColor Blue

    Write-Host "# Generate diff showing changes from latest commit:" -ForegroundColor DarkGray
    Write-Host "git show HEAD | Set-Content -Encoding UTF8 latest_changes.diff" -ForegroundColor Blue

    Write-Host "# Generate diff showing changes from second latest commit (use HEAD^^ for third etc.):" -ForegroundColor DarkGray
    Write-Host "git show HEAD^ | Set-Content -Encoding UTF8 latest_changes.diff" -ForegroundColor Blue

    Write-Host "# Generate diff for specified commit id, filtering on specific file type:" -ForegroundColor DarkGray
    Write-Host "git show c7aa908 -- '*.go' | Set-Content -Encoding UTF8 go_fixes.diff" -ForegroundColor Blue

    Write-Host "# Generate diff between specific commit and now, filtering on specific file types:" -ForegroundColor DarkGray
    Write-Host "git diff cbceb5a..HEAD -- '**/*.java' '*.cs' > new_java_cs_changes.diff" -ForegroundColor Blue

    Write-Host "# Apply patch:" -ForegroundColor DarkGray
    Write-Host 'cd $env:code_root_dir/Code2/C#/dotnet-integration; git apply $env:my_notes_path/notes/svea/diffs/testshop_dev.diff --verbose' -ForegroundColor Blue

    Write-Host ""
    Write-Host "Other useful commands:"

    # Other useful commands: entire command in green
    Write-Host "  . `$PROFILE" -ForegroundColor Green
    Write-Host "  keepawake" -ForegroundColor Green
    Write-Host "  vim `$env:code_root_dir/Code2/Wow/tools/my_wow/wow.conf" -ForegroundColor Green
    Write-Host "  cd `$env:my_notes_path; .\check_dirs.ps1" -ForegroundColor Green
}

# Language-specific helpers
function Show-C-Help {
    Write-Host ""
    Write-Host "C / gcc quick examples:" -ForegroundColor Yellow

    Write-Host ""
    Write-Host "Version / help:" -ForegroundColor Yellow
    Write-CodeLine "gcc --version"
    Write-CodeLine "gcc --help"

    Write-Host ""
    Write-Host "Compile & run:" -ForegroundColor Yellow
    Write-CodeLine "gcc -Wall -Wextra -pedantic -std=c17 -o main main.c  # Compile C program"
    Write-CodeLine "./main  # Run binary"
    Write-Host ""
    Write-CodeLine "gcc -g -O0 -Wall -Wextra -std=c17 -o main_debug main.c  # Debug build"
}

function Show-CSharp-Help {
    Write-Host ""
    Write-Host "C# / .NET quick examples:" -ForegroundColor Yellow

    Write-Host ""
    Write-Host "Version / help:" -ForegroundColor Yellow
    Write-CodeLine "dotnet --version"
    Write-CodeLine "dotnet -h"

    Write-Host ""
    Write-Host "Create new projects:" -ForegroundColor Yellow
    Write-CodeLine "dotnet new console -o MyConsoleApp      # Console app"
    Write-CodeLine "dotnet new classlib -o MyLibrary        # Class library"
    Write-CodeLine "dotnet new webapi -o MyWebApi           # ASP.NET Core Web API"
    Write-CodeLine "dotnet new worker -o MyWorkerService    # Background worker service"

    Write-Host ""
    Write-Host "Useful dotnet commands:" -ForegroundColor Yellow
    Write-CodeLine "dotnet --list-runtimes"
    Write-CodeLine "dotnet --list-sdks"
    Write-CodeLine "dotnet build"
    Write-CodeLine "dotnet run --framework net9.0"
    Write-CodeLine "dotnet run -f net7.0"
    Write-CodeLine "dotnet run *> test.txt                  # Run and capture output to test.txt"
}

function Show-CPP-Help {
    Write-Host ""
    Write-Host "C++ / g++ quick examples:" -ForegroundColor Yellow

    Write-Host ""
    Write-Host "Version / help:" -ForegroundColor Yellow
    Write-CodeLine "g++ --version"
    Write-CodeLine "g++ --help"

    Write-Host ""
    Write-Host "Compile & run:" -ForegroundColor Yellow
    Write-CodeLine "g++ -O2 -Wall -Wextra -std=c++20 -o main main.cpp  # Compile optimized"
    Write-CodeLine "./main  # Run binary"
    Write-Host ""
    Write-CodeLine "g++ -g -O0 -Wall -Wextra -std=c++20 -o main_debug main.cpp  # Debug build"
}

function Show-Rust-Help {
    Write-Host ""
    Write-Host "Rust / cargo quick examples:" -ForegroundColor Yellow

    Write-Host ""
    Write-Host "Version / help:" -ForegroundColor Yellow
    Write-CodeLine "rustc --version"
    Write-CodeLine "cargo --version"
    Write-CodeLine "cargo -h"

    Write-Host ""
    Write-Host "Basic usage:" -ForegroundColor Yellow
    Write-CodeLine "cargo new TestProject               # Create new project"
    Write-CodeLine "cd TestProject"
    Write-CodeLine "cargo build                         # Build debug"
    Write-CodeLine "cargo run                           # Run debug build"

    Write-Host ""
    Write-Host "With logs redirected to test.txt:" -ForegroundColor Yellow
    Write-CodeLine "cargo build *> test.txt             # Build and capture output"
    Write-CodeLine "cargo run *> test.txt               # Run and capture output"
    Write-CodeLine "cargo run --release *> test.txt     # Release run and capture output"

    Write-Host ""
    Write-Host "Backtraces:" -ForegroundColor Yellow
    Write-CodeLine "RUST_BACKTRACE=1 cargo run          # Short backtrace"
    Write-CodeLine "RUST_BACKTRACE=full cargo run       # Full backtrace"

    Write-Host ""
    Write-Host "Usage with args (dt flag):" -ForegroundColor Yellow
    Write-CodeLine "cargo run --                        # default dt ON"
    Write-CodeLine "cargo run -- --use-dt               # explicit ON"
    Write-CodeLine "cargo run -- --no-use-dt            # OFF"
    Write-CodeLine "cargo run -- --use-dt=false         # OFF"

    Write-Host ""
    Write-CodeLine '$env:RUSTFLAGS="-Awarnings"         # Allow/suppress all Rust compiler warnings'
}

function Show-Java-Help {
    Write-Host ""
    Write-Host "Java quick examples:" -ForegroundColor Yellow

    Write-Host ""
    Write-Host "Version / help:" -ForegroundColor Yellow
    Write-CodeLine "java -version"
    Write-CodeLine "javac -version"
    Write-CodeLine "java -h"

    Write-Host ""
    Write-Host "Compile & run:" -ForegroundColor Yellow
    Write-CodeLine "javac Main.java                     # Compile"
    Write-CodeLine "java Main                           # Run"
    Write-Host ""
    Write-CodeLine "javac -d out src\Main.java          # Compile into 'out' directory"
    Write-CodeLine "java -cp out Main                   # Run with explicit classpath"
}

function Show-Python-Help {
    Write-Host ""
    Write-Host "Python quick examples:" -ForegroundColor Yellow

    Write-Host ""
    Write-Host "Version / help:" -ForegroundColor Yellow
    Write-CodeLine "python --version"
    Write-CodeLine "python -h"

    Write-Host ""
    Write-Host "Basic usage:" -ForegroundColor Yellow
    Write-CodeLine "python main.py                      # Run script"
    Write-CodeLine "python -m venv .venv                # Create virtual environment"
    Write-CodeLine "source .venv/bin/activate           # Activate venv (Linux/macOS)"
    Write-CodeLine ".venv\Scripts\Activate.ps1          # Activate venv (Windows PowerShell)"
    Write-Host ""
    Write-CodeLine "python -m pip install -r requirements.txt  # Install dependencies"
    Write-CodeLine "python .\main.py *> test.txt        # Run and capture output to test.txt"
}

function Show-Go-Help {
    Write-Host ""
    Write-Host "Go quick examples:" -ForegroundColor Yellow

    Write-Host ""
    Write-Host "Version / help:" -ForegroundColor Yellow
    Write-CodeLine "go version"
    Write-CodeLine "go help"
    Write-CodeLine "go help <command>                   # e.g. go help build"

    Write-Host ""
    Write-Host "Basic usage:" -ForegroundColor Yellow
    Write-CodeLine "go mod init example.com/myapp       # Initialize module"
    Write-CodeLine "go run main.go                      # Run directly"
    Write-CodeLine "go build ./...                      # Build all packages"
    Write-CodeLine "go test ./...                       # Run tests"

    Write-Host ""
    Write-Host "With output redirected to test.txt:" -ForegroundColor Yellow
    Write-CodeLine "go build; ./my_wow.exe *> test.txt"
    Write-CodeLine "go build; ./my_wow.exe *> test.txt; vim .\test.txt"
}

function Show-JS-Help {
    Write-Host ""
    Write-Host "JavaScript (Node) quick examples:" -ForegroundColor Yellow

    Write-Host ""
    Write-Host "Version / help:" -ForegroundColor Yellow
    Write-CodeLine "node --version"
    Write-CodeLine "node --help"
    Write-CodeLine "npm -v"
    Write-CodeLine "npm help"

    Write-Host ""
    Write-Host "Do this:" -ForegroundColor Yellow
    Write-CodeLine "node main.js"
    Write-Host ""
    Write-Host "Or:" -ForegroundColor Yellow
    Write-CodeLine "npm init -y"
    Write-CodeLine "  # fix package.json (add ""start"" script, etc.)" -CommandColor DarkGray
    Write-Host "Then:" -ForegroundColor Yellow
    Write-CodeLine "npm run start"
    Write-CodeLine "npm start"
}

function Show-TS-Help {
    Write-Host ""
    Write-Host "TypeScript quick examples:" -ForegroundColor Yellow

    Write-Host ""
    Write-Host "Version / help:" -ForegroundColor Yellow
    Write-CodeLine "tsc -v"
    Write-CodeLine "npx tsc --help"

    Write-Host ""
    Write-Host "Do this:" -ForegroundColor Yellow
    Write-CodeLine "npm init -y # init npm"
    Write-CodeLine "# install dev dependencies"
    Write-CodeLine "npm install --save-dev typescript ts-node @types/node"
    Write-CodeLine "# Create tsconfig.json"
    Write-CodeLine "npx tsc --init"
    Write-CodeLine "#  tweak tsconfig.json and npm scripts, then do either of these:"
    Write-CodeLine "#  Compile once + run compiled JS:"
    Write-CodeLine "npm run build  # runs tsc -> creates dist/main.js, dist/config_reader.js"
    Write-CodeLine "npm start      # runs node dist/main.js"
    Write-CodeLine "# Dev mode (no separate build step):"
    Write-CodeLine "npm run dev"
}

# If no argument: show usage/help and exit
if (-not $Language) {
    Show-Usage
    exit 0
}

# Normalize & validate argument (case-insensitive)
$key = $Language.Trim().ToLower()
if (-not $languageMap.ContainsKey($key)) {
    Write-Host "Unknown code language argument: '$Language'" -ForegroundColor Red
    Write-Host ""
    Show-Usage
    exit 1
}

$normalizedLanguage = $languageMap[$key]

Write-Host "Selected code language: " -NoNewline
Write-Host $normalizedLanguage -ForegroundColor Magenta

switch ($normalizedLanguage) {
    'c'          { Show-C-Help }
    'csharp'     { Show-CSharp-Help }
    'cpp'        { Show-CPP-Help }
    'rust'       { Show-Rust-Help }
    'java'       { Show-Java-Help }
    'python'     { Show-Python-Help }
    'go'         { Show-Go-Help }
    'javascript' { Show-JS-Help }
    'typescript' { Show-TS-Help }
    default      { }  # Shouldn't happen
}

