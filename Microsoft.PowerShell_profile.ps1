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

# Note:
# scripts in my_scripts without "dot-commands":
# {ps_profile_path}/my_scripts/cd_code_root_dir.ps1
# {ps_profile_path}/my_scripts/cd_my_notes_path.ps1
# {ps_profile_path}/my_scripts/cd_ps_profile_path.ps1
# {ps_profile_path}/my_scripts/chrome_s.ps1
# {ps_profile_path}/my_scripts/closeApplication.ps1
# {ps_profile_path}/my_scripts/copy_path.ps1
# {ps_profile_path}/my_scripts/get_fonts.ps1
# {ps_profile_path}/my_scripts/llama_old.ps1
# {ps_profile_path}/my_scripts/list_processes.ps1
# {ps_profile_path}/my_scripts/list_processes_mem.ps1
# {ps_profile_path}/my_scripts/map_util.ps1
# {ps_profile_path}/my_scripts/network_names.ps1
# {ps_profile_path}/my_scripts/playermap_old.ps1
# {ps_profile_path}/my_scripts/task_commands.ps1
# {ps_profile_path}/my_scripts/trust_dirs.ps1
$aliases = @(
    ".cdn", ".cdc", ".cdp", ".ioq3", ".show_wifi", ".list_files", ".list_files_gui", 
    ".list_p", ".list_pm", ".acore", ".tcore", ".wcell", ".playermap", ".openmw", 
    ".stk", ".wow", ".wowbot", ".network_devices", ".network_devices_ping",
	".mangos", ".llama", ".update_nvim_from_linux", ".docs", ".down", ".cdh", ".clean_shada",
    ".acore_update", ".tcore_update", ".gen_plant", ".gen_merm", ".git_push", ".git_pull",
    ".cava", ".wc", ".list_mapped_drives", ".wow_wtf_update", ".wow_wtf_fix", ".mangos_update",
    ".cmake", ".cmangos_update"
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
    "${osc7}PS $p$('>' * ($nestedPromptLevel + 1)) ";
}

# Load all scripts
#Get-ChildItem (Join-Path ('$PSScriptRoot') \my_scripts\) | Where `
#    { $_.Name -notlike '__*' -and $_.Name -like '*.ps1'} | ForEach `
#    { . $_.FullName }

# Source env vars
$Env:EDITOR = "nvim"
$Env:YAZI_FILE_ONE = "C:\Program Files\Git\usr\bin\file.exe"

. "$PSScriptRoot\env.ps1"

