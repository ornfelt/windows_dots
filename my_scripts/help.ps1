param(
    [Parameter(Position = 0)]
    [string]$Language
)

# Map all aliases -> normalized name
$languageMap = @{
    # code langs
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

    # other args
    'git'        = 'git'
    'grep'       = 'grep'
    'gitgrep'    = 'gitgrep'
    'ggrep'      = 'gitgrep'
    'ripgrep'    = 'ripgrep'
    'rgrep'      = 'ripgrep'
    'ps'         = 'other'
    'x'          = 'other'
    'other'      = 'other'
    'scripts'    = 'scripts'
    'script'     = 'scripts'
    'path'       = 'paths'
    'paths'      = 'paths'
    'p'          = 'paths'
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

# IMPORTANT: When no arg (or unknown arg), print ONLY the available args and nothing else.
function Show-Args {
    $args = @(
        # code langs
        'c'
        'cs / c# / csharp'
        'cpp / c++'
        'go / golang'
        'java'
        'js / javascript'
        'ts / typescript'
        'py / python'
        'rust / rs'

        # other groups
        'git'
        'grep'
        'gitgrep / ggrep'
        'ripgrep / rgrep'
        'ps / x / other'
        'scripts / script'
        'paths / path / p'
    )

    foreach ($a in $args) {
        Write-Host "  $a" -ForegroundColor Magenta
    }
}

function Show-Git-Help {
    Write-Host "Git commands:" -ForegroundColor Yellow
    Write-Host ""

    Write-CodeLine 'git push https://$env:GITHUB_TOKEN@github.com/ornfelt/small_games'
    Write-CodeLine 'git clone --recurse-submodules -j8 https://$GITHUB_TOKEN@github.com/ornfelt/my_wow_docs'
    Write-Host ""

    # Existing useful git commands moved here
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
}

function Show-RipGrep-Help {
    Write-Host "## ripgrep" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "Basic Recursive Search" -ForegroundColor DarkGray
    Write-CodeLine 'rg "your_search_text"'
    Write-Host ""

    Write-Host "Non-Recursive Search" -ForegroundColor DarkGray
    Write-CodeLine 'rg --max-depth 1 "your_search_text"'
    Write-Host ""

    Write-Host "Search Only in Files with Specific Extensions" -ForegroundColor DarkGray
    Write-CodeLine 'rg "your_search_text" -g "*.txt"'
    Write-Host "Use -g (glob) to include only .txt files." -ForegroundColor DarkGray
    Write-Host ""

    Write-Host "Multiple extensions:" -ForegroundColor DarkGray
    Write-CodeLine 'rg "your_search_text" -g "*.txt" -g "*.md"'
    Write-Host "You can add multiple -g filters." -ForegroundColor DarkGray
    Write-Host ""

    Write-Host "Exclude Specific File Extensions" -ForegroundColor DarkGray
    Write-CodeLine 'rg "your_search_text" -g "!*.log"'
    Write-Host "The ! negates the glob, so it excludes .log files." -ForegroundColor DarkGray
    Write-Host ""

    Write-Host "Exclude multiple:" -ForegroundColor DarkGray
    Write-CodeLine 'rg "your_search_text" -g "!*.log" -g "!*.tmp"'
    Write-Host ""

    Write-Host "Combine Include and Exclude" -ForegroundColor DarkGray
    Write-Host "Only .cs files but exclude .Designer.cs ones:" -ForegroundColor DarkGray
    Write-CodeLine 'rg "your_search_text" -g "*.cs" -g "!*.Designer.cs"'
    Write-Host ""

    Write-Host "Search in a Specific Directory" -ForegroundColor DarkGray
    Write-CodeLine 'rg "your_search_text" path/to/directory'
    Write-Host ""

    Write-Host "Show Only File Names with Matches" -ForegroundColor DarkGray
    Write-CodeLine 'rg -l "your_search_text"'
    Write-Host ""

    Write-Host "Show Line Numbers" -ForegroundColor DarkGray
    Write-CodeLine 'rg -n "your_search_text"'
    Write-Host ""

    Write-Host "Case-Insensitive Search" -ForegroundColor DarkGray
    Write-CodeLine 'rg -i "your_search_text"'
    Write-Host ""

    Write-Host "Literal Search (no regex)" -ForegroundColor DarkGray
    Write-CodeLine 'rg -F "literal_text"'
    Write-Host ""

    Write-Host "Recursive + case-insensitive, excluding common build dirs" -ForegroundColor DarkGray
    Write-CodeLine 'rg -i "your_search_text" -g "!build/**" -g "!out/**" -g "!node_modules/**" -g "!.git/**" -g "!bin/**"'
    Write-Host ""

    Write-Host "CMake: only CMakeLists.txt" -ForegroundColor DarkGray
    Write-CodeLine 'rg "your_search_text" -g "CMakeLists.txt"'
    Write-Host ""

    Write-Host "CMake: only *.cmake" -ForegroundColor DarkGray
    Write-CodeLine 'rg "your_search_text" -g "*.cmake"'
    Write-Host ""

    Write-Host "CMake: CMakeLists.txt + *.cmake" -ForegroundColor DarkGray
    Write-CodeLine 'rg "your_search_text" -g "CMakeLists.txt" -g "*.cmake"'
    Write-Host ""

    Write-Host 'CMake-ish filenames: name contains "cmake" but NOT ending with .cmake' -ForegroundColor DarkGray
    Write-CodeLine 'rg "your_search_text" -g "*cmake*" -g "!*.cmake"'
    Write-Host "CMake-ish filenames (case-insensitive filename glob):" -ForegroundColor DarkGray
    Write-CodeLine 'rg "your_search_text" --iglob "*cmake*" --iglob "!*.cmake"'
    Write-Host ""

    Write-Host "Context search -> save to temp file -> second grep on output -> delete temp file" -ForegroundColor DarkGray
    Write-Host "PowerShell version:" -ForegroundColor DarkGray
    Write-CodeLine '$tmp = New-TemporaryFile; rg -in -C 3 "FIRST" . > $tmp; rg -i "SECOND" $tmp; Remove-Item $tmp'
}

function Show-GitGrep-Help {
    Write-Host "## git grep" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "Basic Recursive Search" -ForegroundColor DarkGray
    Write-CodeLine 'git grep "your_search_text"'
    Write-Host ""

    Write-Host "Non-Recursive Search" -ForegroundColor DarkGray
    Write-CodeLine 'git grep "your_search_text" -- "./*"'
    Write-Host ""

    Write-Host "Search Only in Files with Specific Extensions" -ForegroundColor DarkGray
    Write-CodeLine 'git grep "your_search_text" -- "*.txt"'
    Write-Host ""

    Write-Host "Multiple extensions:" -ForegroundColor DarkGray
    Write-CodeLine 'git grep "your_search_text" -- "*.txt" "*.md"'
    Write-Host ""

    Write-Host "Exclude Specific File Extensions" -ForegroundColor DarkGray
    Write-CodeLine 'git grep "your_search_text" -- ":!*.log"'
    Write-Host ""

    Write-Host "Exclude multiple:" -ForegroundColor DarkGray
    Write-CodeLine 'git grep "your_search_text" -- ":!*.log" ":!*.tmp"'
    Write-Host ""

    Write-Host "Combine Include and Exclude" -ForegroundColor DarkGray
    Write-Host "Only .cs files but exclude .Designer.cs ones:" -ForegroundColor DarkGray
    Write-CodeLine 'git grep "your_search_text" -- "*.cs" ":!*.Designer.cs"'
    Write-Host ""

    Write-Host "Search in a Specific Directory" -ForegroundColor DarkGray
    Write-CodeLine 'git grep "your_search_text" -- path/to/directory'
    Write-Host ""

    Write-Host "Show Only File Names with Matches" -ForegroundColor DarkGray
    Write-CodeLine 'git grep -l "your_search_text"'
    Write-Host ""

    Write-Host "Show Line Numbers" -ForegroundColor DarkGray
    Write-CodeLine 'git grep -n "your_search_text"'
    Write-Host ""

    Write-Host "Case-Insensitive Search" -ForegroundColor DarkGray
    Write-CodeLine 'git grep -i "your_search_text"'
    Write-Host ""

    Write-Host "Literal Search (no regex)" -ForegroundColor DarkGray
    Write-CodeLine 'git grep -F "literal_text"'
    Write-Host ""

    Write-Host "Recursive + case-insensitive, excluding common build dirs" -ForegroundColor DarkGray
    Write-CodeLine 'git grep -i "your_search_text" -- ":(exclude)build/**" ":(exclude)out/**" ":(exclude)node_modules/**" ":(exclude).git/**" ":(exclude)bin/**"'
    Write-Host ""

    Write-Host "CMake: only CMakeLists.txt" -ForegroundColor DarkGray
    Write-CodeLine 'git grep "your_search_text" -- "CMakeLists.txt"'
    Write-Host ""

    Write-Host "CMake: only *.cmake" -ForegroundColor DarkGray
    Write-CodeLine 'git grep "your_search_text" -- "*.cmake"'
    Write-Host ""

    Write-Host "CMake: CMakeLists.txt + *.cmake" -ForegroundColor DarkGray
    Write-CodeLine 'git grep "your_search_text" -- "CMakeLists.txt" "*.cmake"'
    Write-Host ""

    Write-Host 'CMake-ish filenames: name contains "cmake" but NOT ending with .cmake' -ForegroundColor DarkGray
    Write-CodeLine 'git grep "your_search_text" -- "*cmake*" ":(exclude)*.cmake"'
    Write-Host "CMake-ish filenames (case-insensitive path match):" -ForegroundColor DarkGray
    Write-CodeLine 'git grep "your_search_text" -- ":(icase)*cmake*" ":(exclude)*.cmake"'
    Write-Host ""

    Write-Host "Context search -> save to temp file -> second grep on output -> delete temp file" -ForegroundColor DarkGray
    Write-Host "PowerShell version:" -ForegroundColor DarkGray
    Write-CodeLine '$tmp = New-TemporaryFile; git grep -in -C 3 "FIRST" -- . > $tmp; git grep -i "SECOND" $tmp; Remove-Item $tmp'
}

function Show-Grep-Help {
    Write-Host "## grep" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "Basic Recursive Search" -ForegroundColor DarkGray
    Write-CodeLine 'grep -r "your_search_text" .'
    Write-Host ""

    Write-Host "Non-Recursive Search" -ForegroundColor DarkGray
    Write-CodeLine 'grep "your_search_text" *'
    Write-Host ""

    Write-Host "Search Only in Files with Specific Extensions" -ForegroundColor DarkGray
    Write-CodeLine 'grep -r --include="*.txt" "your_search_text" .'
    Write-Host ""

    Write-Host "Multiple extensions:" -ForegroundColor DarkGray
    Write-CodeLine 'grep -r --include="*.txt" --include="*.md" "your_search_text" .'
    Write-Host ""

    Write-Host "Exclude Specific File Extensions" -ForegroundColor DarkGray
    Write-CodeLine 'grep -r --exclude="*.log" "your_search_text" .'
    Write-Host ""

    Write-Host "Exclude multiple:" -ForegroundColor DarkGray
    Write-CodeLine 'grep -r --exclude="*.log" --exclude="*.tmp" "your_search_text" .'
    Write-Host ""

    Write-Host "Combine Include and Exclude" -ForegroundColor DarkGray
    Write-Host "Only .cs files but exclude .Designer.cs ones:" -ForegroundColor DarkGray
    Write-CodeLine 'grep -r --include="*.cs" --exclude="*.Designer.cs" "your_search_text" .'
    Write-Host ""

    Write-Host "Search in a Specific Directory" -ForegroundColor DarkGray
    Write-CodeLine 'grep -r "your_search_text" path/to/directory'
    Write-Host ""

    Write-Host "Show Only File Names with Matches" -ForegroundColor DarkGray
    Write-CodeLine 'grep -rl "your_search_text" .'
    Write-Host ""

    Write-Host "Show Line Numbers" -ForegroundColor DarkGray
    Write-CodeLine 'grep -rn "your_search_text" .'
    Write-Host ""

    Write-Host "Case-Insensitive Search" -ForegroundColor DarkGray
    Write-CodeLine 'grep -ri "your_search_text" .'
    Write-Host ""

    Write-Host "Literal Search (no regex)" -ForegroundColor DarkGray
    Write-CodeLine 'grep -rF "literal_text" .'
    Write-Host ""

    Write-Host "Recursive + case-insensitive, excluding common build dirs" -ForegroundColor DarkGray
    Write-CodeLine 'grep -rIn --exclude-dir={build,out,node_modules,.git,bin} "your_search_text" .'
    Write-Host ""

    Write-Host "CMake: only CMakeLists.txt" -ForegroundColor DarkGray
    Write-Host "Original:" -ForegroundColor DarkGray
    Write-CodeLine 'grep -R --line-number --with-filename "your_search_text" --include="CMakeLists.txt" .'
    Write-Host "Shortened:" -ForegroundColor DarkGray
    Write-CodeLine 'grep -RIn --include="CMakeLists.txt" "your_search_text" .'
    Write-Host ""

    Write-Host "CMake: only *.cmake" -ForegroundColor DarkGray
    Write-Host "Original:" -ForegroundColor DarkGray
    Write-CodeLine 'grep -R -n "your_search_text" --include="*.cmake" .'
    Write-Host "Shortened:" -ForegroundColor DarkGray
    Write-CodeLine 'grep -Rn --include="*.cmake" your_search_text .'
    Write-Host ""

    Write-Host "CMake: CMakeLists.txt + *.cmake" -ForegroundColor DarkGray
    Write-Host "Original:" -ForegroundColor DarkGray
    Write-CodeLine 'grep -R -n "your_search_text" --include="CMakeLists.txt" --include="*.cmake" .'
    Write-Host "Shortened:" -ForegroundColor DarkGray
    Write-CodeLine 'grep -Rn --include="CMakeLists.txt" --include="*.cmake" your_search_text .'
    Write-Host ""

    Write-Host 'CMake-ish filenames: name contains "cmake" but NOT ending with .cmake' -ForegroundColor DarkGray
    Write-Host "Grep (simple):" -ForegroundColor DarkGray
    Write-CodeLine 'grep -Rn --include="*cmake*" --exclude="*.cmake" "your_search_text" .'
    Write-Host "Find + grep (case-insensitive filename match):" -ForegroundColor DarkGray
    Write-CodeLine 'find . -type f -iname "*cmake*" ! -iname "*.cmake" -exec grep -n "your_search_text" {} +'
    Write-Host ""

    Write-Host "Context search -> save to temp file -> second grep on output -> delete temp file" -ForegroundColor DarkGray
    Write-CodeLine 'tmp="$(mktemp)" && grep -rIn -C 3 "FIRST" . >"$tmp" && grep -i "SECOND" "$tmp" && rm -f "$tmp"'
}

# Moved: all dot commands / scripts
function Show-Scripts-Help {
    Write-Host "Some useful dot commands:" -ForegroundColor Yellow

    Write-Host ""
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
    Write-CommandWithDescription ".git_ignore" "helper script for git ignore"                  'Cyan'
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
}

# Other commands
function Show-Other-Help {
    Write-Host "Other useful commands:" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "  . `$PROFILE" -ForegroundColor Green
    Write-Host "  keepawake" -ForegroundColor Green
    Write-Host "  vim `$env:code_root_dir/Code2/Wow/tools/my_wow/wow.conf" -ForegroundColor Green
    Write-Host "  cd `$env:my_notes_path; .\check_dirs.ps1" -ForegroundColor Green
    Write-Host "  (Get-Location).Path | Set-Clipboard" -ForegroundColor Green
    Write-Host "  (Get-Command go).Source" -ForegroundColor Green

    Write-Host ""
    Write-Host "PS file/dir operations:" -ForegroundColor Yellow

    Write-Host ""
    Write-Host "List only directories:" -ForegroundColor Yellow
    Write-CodeLine "ls -Directory                                   # shorthand (PowerShell 3.0+)"
    Write-CodeLine "ls | Where-Object {`$_.PSIsContainer}           # works in all versions"
    Write-CodeLine "Get-ChildItem -Directory                        # explicit"

    Write-Host ""
    Write-Host "List only files:" -ForegroundColor Yellow
    Write-CodeLine "ls -File                                        # shorthand (PowerShell 3.0+)"
    Write-CodeLine "ls | Where-Object {!`$_.PSIsContainer}          # works in all versions"
    Write-CodeLine "Get-ChildItem -File                             # explicit"

    Write-Host ""
    Write-Host "Filter by keyword:" -ForegroundColor Yellow
    Write-CodeLine "ls | Select-String 'keyword'                    # searches file contents, like grep"
    Write-CodeLine "ls | Select-String -CaseSensitive keyword       # case-sensitive"
    Write-CodeLine "ls | Where-Object {`$_.Name -like '*keyword*'}   # filter by name (case-insensitive)"
    Write-CodeLine "ls | Where-Object {`$_.Name -clike '*keyword*'}  # filter by name (case-sensitive)"
    Write-CodeLine "ls | Where-Object {`$_.Name -match 'keyword'}    # regex match (case-insensitive)"
    Write-CodeLine "ls | Where-Object {`$_.Name -cmatch 'keyword'}   # regex match (case-sensitive)"

    Write-Host ""
    Write-Host "Search recursively:" -ForegroundColor Yellow
    Write-CodeLine "Get-ChildItem -Path ./ -Recurse -ErrorAction SilentlyContinue -Filter 'filename.ext' | Select-Object -ExpandProperty FullName  # find file"
    Write-CodeLine "Get-ChildItem -Path C:\ -Recurse -Directory -ErrorAction SilentlyContinue -Filter 'dirname'  # find directory"

    Write-Host ""
    Write-Host "View file content:" -ForegroundColor Yellow
    Write-CodeLine "Get-Content -Path .\file.txt -TotalCount 10     # first 10 lines"
    Write-CodeLine "gc .\file.txt | Select-Object -First 10         # first 10 lines (shorthand)"
    Write-CodeLine "Get-Content -Path .\file.txt -Tail 10           # last 10 lines"
    Write-CodeLine "gc .\file.txt | Select-Object -Last 10          # last 10 lines (shorthand)"

    Write-Host ""
    Write-Host "Count items:" -ForegroundColor Yellow
    Write-CodeLine "Get-ChildItem -File | Measure-Object | Select-Object -ExpandProperty Count       # count files (full)"
    Write-CodeLine "Get-ChildItem -Directory | Measure-Object | Select-Object -ExpandProperty Count  # count directories (full)"
    Write-CodeLine "Get-ChildItem | Measure-Object | Select-Object -ExpandProperty Count             # count all items (full)"
    Write-CodeLine "gci -File | measure | select -exp Count         # count files (shorthand)"
    Write-CodeLine "gci -Directory | measure | select -exp Count    # count directories (shorthand)"
    Write-CodeLine "(gci -File).Count                               # count files (shortest)"
    Write-CodeLine "(gci -File -Recurse).Count                      # count files recursive"
    Write-CodeLine "(gci -Directory).Count                          # count directories (shortest)"
    Write-CodeLine "(gci -Directory -Recurse -ErrorAction SilentlyContinue).Count  # count dirs (recursive and suppress permission errors)"
    Write-CodeLine "(gci).Count                                     # count all items (shortest)"
}

function Show-Paths-Help {
    Write-Host "Common config paths:" -ForegroundColor Yellow
    Write-Host ""

    # print the literal $env:… strings
    Write-Host "nvim config path:" -ForegroundColor DarkGray
    Write-Host '$Env:localappdata/nvim/init.lua' -ForegroundColor Green
    Write-Host ""

    Write-Host "wezterm config path:" -ForegroundColor DarkGray
    Write-Host '$Env:userprofile/.wezterm.lua' -ForegroundColor Green
    Write-Host ""

    Write-Host "wezterm session manager path:" -ForegroundColor DarkGray
    Write-Host '$Env:userprofile/.wezterm/wezterm-session-manager/session-manager.lua' -ForegroundColor Green
    Write-Host ""

    Write-Host "alacritty config path:" -ForegroundColor DarkGray
    Write-Host '$Env:appdata/alacritty/alacritty.toml' -ForegroundColor Green
    Write-Host ""

    Write-Host "lf config path:" -ForegroundColor DarkGray
    Write-Host '$Env:localappdata/lf/lfrc' -ForegroundColor Green
    Write-Host ""

    Write-Host "yazi config path:" -ForegroundColor DarkGray
    Write-Host '$Env:appdata/yazi/config/keymap.toml' -ForegroundColor Green
    Write-Host ""

    Write-Host "vs code config path:" -ForegroundColor DarkGray
    Write-Host '$Env:appdata/Code/User/keybindings.json' -ForegroundColor Green
    Write-Host ""

    # actual resolved paths:

    Write-Host "autohotkey path:" -ForegroundColor DarkGray
    $startupDir  = [System.IO.Path]::Combine($env:APPDATA, "Microsoft\Windows\Start Menu\Programs\Startup")
    $startupPath = Join-Path $startupDir "caps_v2.ahk"
    Write-Host $startupPath -ForegroundColor Green
    Write-Host ""

    Write-Host "vimrc path:" -ForegroundColor DarkGray
    if (Test-Path -Path "H:\") {
        Write-Host "H:\.vimrc" -ForegroundColor Green
    } else {
        $vimrc = Join-Path $Env:USERPROFILE ".vimrc"
        Write-Host $vimrc -ForegroundColor Green
    }
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
    Write-CodeLine "dotnet build -c Release"
    Write-CodeLine "# Errors only, no warnings/analyzers"
    Write-CodeLine "dotnet build -consoleLoggerParameters:ErrorsOnly -p:WarningLevel=0 -p:RunAnalyzersDuringBuild=false"
    Write-CodeLine "dotnet run -c Release"
    Write-CodeLine "dotnet run --framework net9.0"
    Write-CodeLine "dotnet run -f net7.0"
    Write-CodeLine "dotnet run *> test.txt                  # Run and capture output to test.txt"
    Write-CodeLine "dotnet test                             # Run tests (from solution dir)"
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
    Write-CodeLine '  # fix package.json (add "start" script, etc.)' -CommandColor DarkGray
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

# Main argument handling
# If no argument: print ONLY available args and exit
if (-not $Language) {
    Show-Args
    exit 0
}

# Normalize & validate argument (case-insensitive)
$key = $Language.Trim().ToLower()
if (-not $languageMap.ContainsKey($key)) {
    Show-Args
    exit 1
}

$normalizedLanguage = $languageMap[$key]

Write-Host "Selected: " -NoNewline
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

    'git'        { Show-Git-Help }
    'grep'       { Show-Grep-Help }
    'gitgrep'    { Show-GitGrep-Help }
    'ripgrep'    { Show-RipGrep-Help }
    'scripts'    { Show-Scripts-Help }
    'other'      { Show-Other-Help }
    'paths'      { Show-Paths-Help }

    default      { }  # Shouldn't happen
}

