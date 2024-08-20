# Oh-My-Posh
oh-my-posh init pwsh | Invoke-Expression
$omp_config = Join-Path $PSScriptRoot ".\custom_cobalt.omp.json"
oh-my-posh --init --shell pwsh --config $omp_config | Invoke-Expression

# PSReadLine
# Install-Module -Name PSReadLine -Force
Import-Module PSReadLine
Set-PSReadLineOption -BellStyle None
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineOption -EditMode Vi

# Fzf
# Install-Module -Name PSFzf -Force
Import-Module PSFzf
Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+f' -PSReadlineChordReverseHistory 'Ctrl+r'

# Alias
$aliases = @(
    ".cdn", ".cdc", ".cdp", ".ioq3", ".show-wifi", ".list_files", ".list_files_gui", 
    ".list_p", ".list_pm", ".acore", ".tcore", ".wcell", ".playermap", ".openmw", 
    ".stk", ".wow", ".wowbot", ".network_devices", ".network_devices_ping",
	".mangos", ".update_nvim_from_linux"
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

# Load all scripts
#Get-ChildItem (Join-Path ('$PSScriptRoot') \my_scripts\) | Where `
#    { $_.Name -notlike '__*' -and $_.Name -like '*.ps1'} | ForEach `
#    { . $_.FullName }

# Source env vars
. "$PSScriptRoot\env.ps1"

