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
Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'

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
    ".list_all_colors", ".git_ignore", ".help", ".mwd"
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
}

function run_vimu {
    nvim -u NONE $args
}
Set-Alias -Name vimu -Value run_vimu

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

