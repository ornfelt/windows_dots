Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

# Note: to reload profile, run:
# . $PROFILE

# Oh-My-Posh
#oh-my-posh init pwsh | Invoke-Expression
#$omp_config = Join-Path $PSScriptRoot ".\custom_cobalt.omp.json"
#oh-my-posh --init --shell pwsh --config $omp_config | Invoke-Expression

# PSReadLine
#Install-Module -Name PSReadLine -Force -Scope CurrentUser
Import-Module PSReadLine
Set-PSReadLineOption -BellStyle None
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineOption -EditMode Vi
#Set-PSReadLineOption -EditMode Windows

Set-PSReadLineKeyHandler -Chord 'Ctrl+n' -Function NextSuggestion
Set-PSReadLineKeyHandler -Chord 'Ctrl+p' -Function PreviousSuggestion

# Fzf
#Install-Module -Name PSFzf -Force -Scope CurrentUser
Import-Module PSFzf
# Make FZF be case insensitive
$env:_PSFZF_FZF_DEFAULT_OPTS = '-i'
#Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+f' -PSReadlineChordReverseHistory 'Ctrl+r'

# alt 1: PSFzf with built-in provider
#Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
Set-PsFzfOption -PSReadlineChordProvider 'Alt+t'
Set-PsFzfOption -PSReadlineChordReverseHistory 'Ctrl+r'

# alt 2: custom normalizing, but slow due to Get-ChildItem recursion 
function Test-IsHomeDirPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    return $Path -match 'se-.*-01'
}

function Convert-DisplayPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    # Remove PowerShell provider prefix if present
    $Path = $Path -replace '^Microsoft\.PowerShell\.Core\\FileSystem::', ''

    # Normalize mapped home-directory path to H:
    $Path = $Path -replace '^.*se-.*-01', 'H:'

    # Replace backslashes with forward slashes
    $Path = $Path -replace '\\', '/'

    # Collapse duplicate forward slashes
    $Path = $Path -replace '/+', '/'

    return $Path
}

function Get-FuzzyFileCandidates {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Root
    )

    $ignoredDirs = @('.git', 'bin', 'obj', 'build')

    Get-ChildItem -LiteralPath $Root -Force -ErrorAction SilentlyContinue | ForEach-Object {
        if ($_.PSIsContainer) {
            if ($ignoredDirs -contains $_.Name) {
                return
            }

            $_.FullName
            Get-FuzzyFileCandidates -Root $_.FullName
        }
        else {
            $_.FullName
        }
    }
}

function Invoke-FuzzyProviderNormalized {
    $currentPath = (Get-Location).ProviderPath
    $isHomeDir = Test-IsHomeDirPath $currentPath

    $selected = Get-FuzzyFileCandidates -Root $currentPath |
        ForEach-Object {
            if ($isHomeDir) {
                Convert-DisplayPath $_
            }
            else {
                $_
            }
        } |
        fzf --prompt "Files> "

    if ([string]::IsNullOrWhiteSpace($selected)) {
        return
    }

    # Quote paths with spaces
    if ($selected -match '\s') {
        $selected = '"' + $selected.Replace('"', '\"') + '"'
    }

    [Microsoft.PowerShell.PSConsoleReadLine]::Insert($selected)
}

#Set-PSReadLineKeyHandler -Chord 'Ctrl+t' -ScriptBlock {
#    Invoke-FuzzyProviderNormalized
#}

# alt 3: plain fzf
Set-PSReadLineKeyHandler -Chord 'Ctrl+t' -ScriptBlock {
    $selected = fzf --prompt "Files> "

    if ([string]::IsNullOrWhiteSpace($selected)) {
        return
    }

    # Quote paths with spaces
    if ($selected -match '\s') {
        $selected = '"' + $selected.Replace('"', '\"') + '"'
    }

    [Microsoft.PowerShell.PSConsoleReadLine]::Insert($selected)
}

Set-PSReadLineKeyHandler -Chord 'Alt+c' -ScriptBlock {
    Invoke-FuzzySetLocation
}

Set-PSReadLineKeyHandler -Chord 'Ctrl+f' -ScriptBlock {
    Invoke-PsFzfRipgrep
}

Set-PSReadLineKeyHandler -Chord 'Ctrl+g' -ScriptBlock {
    Invoke-FuzzyGitStatus
    #Invoke-FuzzyEdit
    #Invoke-FuzzyFasd
    #Invoke-FuzzyZLocation
    #Invoke-FuzzyHistory
    #Invoke-FuzzyScoop
    #Set-LocationFuzzyEverything
}

Set-PSReadLineKeyHandler -Chord 'Ctrl+k' -ScriptBlock {
    Invoke-FuzzyKillProcess
}

# disable v -> vim
Set-PSReadLineKeyHandler -ViMode Command -Key 'v' -ScriptBlock { }

# Vi mode yank -> Windows clipboard
Set-PSReadLineKeyHandler -ViMode Command -Chord 'y','y' -ScriptBlock {
    [Microsoft.PowerShell.PSConsoleReadLine]::ViYankLine()
    #Copy-PSReadLineYankToClipboard
    try {
        # debug test
        #Set-Clipboard -Value "test"

        # copy from PS:
        $buffer = $null
        $cursor = 0
        # Get full current command line buffer + cursor position
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$buffer, [ref]$cursor)
        if ([string]::IsNullOrEmpty($buffer)) { return }

        # Copy only the line the cursor is on (works even for multi-line)
        $before = if ($cursor -gt 0) { $buffer.Substring(0, $cursor) } else { "" }

        $start = $before.LastIndexOf("`n")
        if ($start -lt 0) { $start = 0 } else { $start += 1 }

        $end = $buffer.IndexOf("`n", $cursor)
        if ($end -lt 0) { $end = $buffer.Length }

        $line = $buffer.Substring($start, $end - $start).TrimEnd("`r")
        Set-Clipboard -Value $line
    } catch { }
}

# Note:
# scripts in my_scripts without "dot-commands":
# Note, the three cd scripts below are used through yazi
# {ps_profile_path}/my_scripts/cd_code_root_dir.ps1
# {ps_profile_path}/my_scripts/cd_my_notes_path.ps1
# {ps_profile_path}/my_scripts/cd_ps_profile_path.ps1
# {ps_profile_path}/my_scripts/chrome_s.ps1
# {ps_profile_path}/my_scripts/closeApplication.ps1
# {ps_profile_path}/my_scripts/copy_path.ps1
# {ps_profile_path}/my_scripts/get_fonts.ps1
# {ps_profile_path}/my_scripts/llama_old.ps1
# {ps_profile_path}/my_scripts/map_util.ps1
# {ps_profile_path}/my_scripts/network_names.ps1
# {ps_profile_path}/my_scripts/playermap_old.ps1
# {ps_profile_path}/my_scripts/task_commands.ps1
# {ps_profile_path}/my_scripts/trust_dirs.ps1
# {ps_profile_path}/my_scripts/unblock_files.ps1
$aliases = @(
    ".cdn", ".cdc", ".cdp", ".ioq3", ".show_wifi", ".list_files", ".list_files_gui", 
    ".list_p", ".list_pm", ".acore", ".tcore", ".wcell", ".playermap", ".openmw", 
    ".stk", ".wow", ".wowbot", ".network_devices", ".network_devices_ping",
	".mangos", ".llama", ".update_nvim_from_linux", ".docs", ".down", ".cdh", ".clean_shada",
    ".acore_update", ".tcore_update", ".gen_plant", ".gen_merm", ".git_push", ".git_pull",
    ".cava", ".wc", ".list_mapped_drives", ".wow_wtf_update", ".wow_wtf_fix", ".mangos_update",
    ".cmake", ".cmangos_update", ".mw", ".mww", ".mwr", ".list_colors", ".list_std_colors",
    ".list_all_colors", ".git_ignore", ".help", ".mwd", ".search_conf", ".dump_files",
    ".diff_shader_git", ".build", ".build_py", ".pkg", ".proc", ".copy_git_msg", ".sln",
    ".cmake_old", ".cmake_py", ".fr", ".fr_py", ".fr_cs", ".dots", ".search_env", ".gs",
    ".clean", ".proj_summarize", ".find_files", ".dir_sizes", ".gb", ".go_flags", ".rs_flags",
    ".geo", ".map", ".trans", ".mov", ".mov_py", ".book", ".gfx", ".utils", ".git_diff",
    ".search", ".help_old", ".srclist", ".arg_tests", ".gr", ".gp", "nvcs", ".cmake_build",
    ".audit_diff_commit_info", ".audit_diff_restore", ".gen_commit_msg", ".kill_nvim_servers",
    ".script_helper"
)

foreach ($alias in $aliases) {
    $scriptName = $alias.TrimStart(".")
    Set-Alias -Name $alias -Value "$PSScriptRoot\my_scripts\$scriptName.ps1"
}

function RunChatGPT {
	# python -m revChatGPT.V3 --api_key $env:OPENAI_API_KEY --submit_key enter
    python -m revChatGPT.V3 --api_key $env:OPENAI_API_KEY
}
Set-Alias -Name chatgpt -Value RunChatGPT

$nvimPath = (Get-Command nvim).Source
if ($nvimPath) {
    Set-Alias -Name vim -Value $nvimPath
    Set-Alias -Name vi -Value $nvimPath
}

function run_vimu {
    nvim -u NONE $args
}
Set-Alias -Name vimu -Value run_vimu

# ---------------------------------------------------------------------------
# Headless nvim servers (wezterm)
#
# ~/.wezterm/nvim_server.lua keeps `nvim --headless --listen ...` servers warm
# and tells every pane about them through WEZ_NVIM_*, so nothing has to be
# configured twice here. Attaching a UI to a warm server costs ~60ms instead of
# the ~2.4s a cold nvim costs with this config.
#
#   vim                 attach to this pane's server (or lease a pooled one)
#   vim file1 file2     the same, opening those files first
#   nvim                always a plain nvim, never a server
#
# Falls back to a plain nvim whenever no server can be reached.
# ---------------------------------------------------------------------------

# Hard-coded switch: let `vim` attach to a headless server. With this off,
# `vim` opens a plain nvim exactly like `nvim` does.
$VimUseNvimServer = $true

# Ask the server to :cd here before attaching. Off, so a reused pool server is
# left exactly as its previous user left it; file arguments are passed as
# absolute paths either way.
#$NvimServerSyncCwd = $false
$NvimServerSyncCwd = $true
# How long to wait for a server that is still starting up
$NvimServerWaitMs = 8000

function Get-NvimServerAddress([string]$Name) {
    if ($env:OS -eq 'Windows_NT') { return "\\.\pipe\$Name" }
    return (Join-Path $env:WEZ_NVIM_DIR "$Name.sock")
}

function Get-NvimServerNames([string]$Prefix) {
    if ($env:OS -eq 'Windows_NT') {
        return @([System.IO.Directory]::GetFiles('\\.\pipe\') |
            ForEach-Object { $_.Substring($_.LastIndexOf('\') + 1) } |
            Where-Object { $_.StartsWith($Prefix) })
    }
    return @(Get-ChildItem -LiteralPath $env:WEZ_NVIM_DIR -Filter "$Prefix*.sock" -ErrorAction SilentlyContinue |
        ForEach-Object { $_.BaseName })
}

function Test-NvimServerReady([string]$Name) {
    if ($env:OS -eq 'Windows_NT') {
        return ([System.IO.Directory]::GetFiles('\\.\pipe\') -contains "\\.\pipe\$Name")
    }
    return (Test-Path -LiteralPath (Get-NvimServerAddress $Name))
}

function Wait-NvimServer([string]$Name, [int]$TimeoutMs) {
    $deadline = (Get-Date).AddMilliseconds($TimeoutMs)
    while ((Get-Date) -lt $deadline) {
        if (Test-NvimServerReady $Name) { return $true }
        Start-Sleep -Milliseconds 50
    }
    return $false
}

function New-NvimServerName {
    return 'nvim-wez-pool-' + [guid]::NewGuid().ToString('N').Substring(0, 12)
}

function Start-NvimServerProcess([string]$Name) {
    $dir = $env:WEZ_NVIM_DIR
    $addr = Get-NvimServerAddress $Name
    $pidFile = "$dir/$Name.pid"
    # Same bootstrap as in ~/.wezterm/nvim_server.lua: the server records its
    # own pid so wezterm can find and kill it later, and removes it on exit
    $boot = "lua local d=[[$dir]] local p=[[$pidFile]] vim.fn.mkdir(d,[[p]]) " +
            "vim.fn.writefile({tostring(vim.fn.getpid())},p) " +
            "vim.api.nvim_create_autocmd('VimLeavePre',{callback=function() vim.fn.delete(p) end})"
    $argLine = '--headless --listen "{0}" --cmd "{1}"' -f $addr, $boot
    Start-Process -FilePath 'nvim' -ArgumentList $argLine -WindowStyle Hidden
}

function Get-NvimServerUiCount([string]$Name) {
    # --headless matters here: without it the client starts a whole TUI
    $out = & nvim --headless --server (Get-NvimServerAddress $Name) --remote-expr 'len(nvim_list_uis())' 2>$null
    if ($LASTEXITCODE -ne 0) { return -1 }
    $count = 0
    if ([int]::TryParse((($out | Out-String).Trim()), [ref]$count)) { return $count }
    return -1
}

function New-NvimServerLease([string]$Path) {
    # CreateNew is atomic, so two panes cannot claim the same server
    try {
        $stream = [System.IO.File]::Open($Path, [System.IO.FileMode]::CreateNew,
            [System.IO.FileAccess]::Write, [System.IO.FileShare]::None)
        $bytes = [System.Text.Encoding]::UTF8.GetBytes("pid=$PID pane=$env:WEZTERM_PANE")
        $stream.Write($bytes, 0, $bytes.Length)
        $stream.Dispose()
        return $true
    }
    catch { return $false }
}

function Request-NvimServerFromPool {
    $dir = $env:WEZ_NVIM_DIR
    if (-not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
    }

    $names = @(Get-NvimServerNames 'nvim-wez-pool-')
    $claim = $null

    # A server with no lease file is free without having to ask it
    foreach ($name in $names) {
        $lease = Join-Path $dir "$name.lease"
        if (Test-Path -LiteralPath $lease) { continue }
        if (New-NvimServerLease $lease) { $claim = @{ Name = $name; Lease = $lease }; break }
    }

    # Otherwise look for a lease left behind by a pane that was killed: the
    # server is still running but nothing is attached to it any more
    if (-not $claim) {
        foreach ($name in $names) {
            if ((Get-NvimServerUiCount $name) -ne 0) { continue }
            $lease = Join-Path $dir "$name.lease"
            Remove-Item -LiteralPath $lease -Force -ErrorAction SilentlyContinue
            if (New-NvimServerLease $lease) { $claim = @{ Name = $name; Lease = $lease }; break }
        }
    }

    # Pool exhausted, so grow it
    if (-not $claim) {
        $name = New-NvimServerName
        Start-NvimServerProcess $name
        if (Wait-NvimServer $name $NvimServerWaitMs) {
            $lease = Join-Path $dir "$name.lease"
            if (New-NvimServerLease $lease) { $claim = @{ Name = $name; Lease = $lease } }
        }
    }

    # Keep a spare ready, but only start one once the pool is nearly empty.
    # Topping straight back up to the prefill size would mean starting an nvim
    # on every single edit and holding that many idle servers forever.
    # One at a time, so a burst of edits does not start a swarm of them.
    $minFree = 1
    if ($env:WEZ_NVIM_POOL_MIN_FREE) { $minFree = [int]$env:WEZ_NVIM_POOL_MIN_FREE }
    $free = @(Get-NvimServerNames 'nvim-wez-pool-' |
        Where-Object { -not (Test-Path -LiteralPath (Join-Path $dir "$_.lease")) })
    if ($free.Count -le $minFree) { Start-NvimServerProcess (New-NvimServerName) }

    return $claim
}

function Invoke-NvimServer {
    $files = @($args)
    $mode = $env:WEZ_NVIM_MODE

    if (-not $mode -or $mode -eq 'off' -or -not $env:WEZ_NVIM_DIR) {
        & nvim @files
        return
    }

    $name = $null
    $lease = $null

    if ($mode -eq 'pool') {
        $claim = Request-NvimServerFromPool
        if ($claim) { $name = $claim.Name; $lease = $claim.Lease }
    }
    elseif ($env:WEZTERM_PANE) {
        $name = "nvim-wez-$($env:WEZ_NVIM_INSTANCE)-$($env:WEZTERM_PANE)"
        if (-not (Test-NvimServerReady $name)) {
            # The reconciler may not have caught up with a brand new pane yet
            Start-NvimServerProcess $name
        }
        if (-not (Wait-NvimServer $name $NvimServerWaitMs)) { $name = $null }
    }

    if (-not $name) {
        Write-Host 'vim: no nvim server available, starting a normal nvim' -ForegroundColor Yellow
        & nvim @files
        return
    }

    $addr = Get-NvimServerAddress $name
    try {
        if ($NvimServerSyncCwd) {
            $cwd = ((Get-Location).ProviderPath -replace '\\', '/').Replace("'", "''")
            & nvim --headless --server $addr --remote-expr "chdir('$cwd')" 2>$null | Out-Null
        }
        if ($files.Count -gt 0) {
            # Made absolute here so they do not depend on the server's own cwd
            $paths = @($files | ForEach-Object {
                $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($_)
            })
            & nvim --headless --server $addr --remote @paths 2>$null | Out-Null
        }
        & nvim --server $addr --remote-ui
    }
    finally {
        if ($lease) { Remove-Item -LiteralPath $lease -Force -ErrorAction SilentlyContinue }
    }
}

# Overrides the plain `vim` alias set further up; `nvim` and `vi` are left
# alone, so there is always a way to start an editor without a server
if ($VimUseNvimServer) {
    Set-Alias -Name vim -Value Invoke-NvimServer
    Set-Alias -Name vi -Value Invoke-NvimServer
}

function Go-Up {
    Set-Location ..
}
Set-Alias .. Go-Up

function Go-Up-Twice {
    Set-Location ../..
}
Set-Alias ... Go-Up-Twice

function run_keepawake {
    python "$env:code_root_dir\Code2\C#\wowbot\keep_awake.py" @args
}
Set-Alias -Name keepawake -Value run_keepawake -Scope Global

function run_health_check {
    & "$env:MY_NOTES_PATH\scripts\health_check.ps1" @args
}

Set-Alias -Name health_check -Value run_health_check -Scope Global
Set-Alias -Name '.health_check' -Value run_health_check -Scope Global

if (-not (Get-Command pwsh.exe -ErrorAction SilentlyContinue)) {
    Set-Alias -Name pwsh -Value powershell.exe
}

function .cc {
    if (Test-Path Env:ANTHROPIC_API_KEY) {
        Remove-Item Env:ANTHROPIC_API_KEY
    }

    claude --permission-mode auto @args
}

# For wezterm cwd
# https://wezfurlong.org/wezterm/shell-integration.html#osc-7-on-windows-with-powershell
function prompt {
    $p = $executionContext.SessionState.Path.CurrentLocation
    $osc7 = ""
    if ($p.Provider.Name -eq "FileSystem") {
        $ansi_escape = [char]27
        $provider_path = $p.ProviderPath -Replace "\\", "/"
        $osc7 = "$ansi_escape]7;file://${env:COMPUTERNAME}/${provider_path}${ansi_escape}\"
    }

    #"${osc7}PS $p$('>' * ($nestedPromptLevel + 1)) ";

    # with color:
    $esc = [char]27
    $psColor = "$esc[38;2;255;140;0m"
    #$pathColor  = "$esc[36m" # cyan
    #$pathColor  = "$esc[34m" # blue
    $pathColor  = "$esc[94m" # bright blue
    $reset = "$esc[0m"

    # Color only the prompt text, keep OSC7 as-is
    # with psColor, pathColor for rest
    #return "${osc7}${psColor}PS ${pathColor}$p$('>' * ($nestedPromptLevel + 1))${reset} "
    # psColor, pathColor and reset for '>'
    #return "${osc7}${psColor}PS ${pathColor}$p${reset}$(' >' * ($nestedPromptLevel + 1)) "
    # username + pathColor
    #return "${osc7}$($env:USERNAME) @ ${pathColor}$p$('>' * ($nestedPromptLevel + 1))${reset} "
    # only use pathColor
    #return "${osc7}${pathColor}PS $p$('>' * ($nestedPromptLevel + 1))${reset} "

    # Only show the leaf directory name, not the full path
    $cwdName = Split-Path -Path $p.ProviderPath -Leaf
    #$cwdName = $cwdName -replace '\\', '/'
    #$cwdName += "/"
    #$cwdName = $cwdName -replace '/+', '/'
    # one-liner:
    $cwdName = ($cwdName -replace '\\', '/') + "/" -replace '/+', '/'
    $user = $env:USERNAME
    $user = $user.Replace('se-', '').Replace('-01', '')
    #return "${osc7}${pathColor}PS $cwdName$('>' * ($nestedPromptLevel + 1))${reset} "
    #return "${osc7}${user} @ ${pathColor}${cwdName}/${reset}> "
    return "${osc7}${user}:${pathColor}${cwdName}${reset} > "
}

# Load all scripts
#Get-ChildItem (Join-Path ('$PSScriptRoot') \my_scripts\) | Where `
#    { $_.Name -notlike '__*' -and $_.Name -like '*.ps1'} | ForEach `
#    { . $_.FullName }

# Source env vars
$Env:EDITOR = "nvim"
$Env:YAZI_FILE_ONE = "C:\Program Files\Git\usr\bin\file.exe"

. "$PSScriptRoot\env.ps1"

