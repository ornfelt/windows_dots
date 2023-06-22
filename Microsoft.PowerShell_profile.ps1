oh-my-posh init pwsh | Invoke-Expression

#$omp_config = Join-Path $PSScriptRoot ".\custom_1_shell.omp.json"
#oh-my-posh --init --shell pwsh --config $omp_config | Invoke-Expression

#$omp_config = Join-Path $PSScriptRoot ".\custom_tokyonight_storm.omp.json"
#oh-my-posh --init --shell pwsh --config $omp_config | Invoke-Expression

#$omp_config = Join-Path $PSScriptRoot ".\powerline.omp.json"
#oh-my-posh --init --shell pwsh --config $omp_config | Invoke-Expression

$omp_config = Join-Path $PSScriptRoot ".\custom_cobalt2.omp.json"
oh-my-posh --init --shell pwsh --config $omp_config | Invoke-Expression

# PSReadLine
Import-Module PSReadLine
Set-PSReadLineOption -BellStyle None
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineOption -EditMode Vi

# Fzf
Import-Module PSFzf
Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+f' -PSReadlineChordReverseHistory 'Ctrl+r'

$path = "C:\Users\jonas\OneDrive\Documents\WindowsPowerShell"

# Alias
Set-Alias -Name .cdh -Value "$path.\Scripts\cdh.ps1"
Set-Alias -Name .cdc -Value "$path.\Scripts\cdc.ps1"
Set-Alias -Name .cdp -Value "$path.\Scripts\cdp.ps1"
Set-Alias -Name .ioq3 -Value "$path.\Scripts\ioq3.ps1"
Set-Alias -Name .show-wifi -Value "$path.\Scripts\show-wifi.ps1"
Set-Alias -Name .list_files -Value "$path.\Scripts\list_files.ps1"
Set-Alias -Name .list_files_gui -Value "$path.\Scripts\list_files_gui.ps1"
Set-Alias -Name .list_p -Value "$path.\Scripts\list_processes.ps1"
Set-Alias -Name .list_pm -Value "$path.\Scripts\list_processes_mem.ps1"
Set-Alias -Name .acore -Value "$path.\Scripts\acore.ps1"
Set-Alias -Name .tcore -Value "$path.\Scripts\tcore.ps1"
Set-Alias -Name .playermap -Value "$path.\Scripts\playermap.ps1"
Set-Alias -Name .openmw -Value "$path.\Scripts\openmw.ps1"
Set-Alias -Name .stk -Value "$path.\Scripts\stk.ps1"

# Load all scripts
#Get-ChildItem (Join-Path ('C:\Users\Svea User\Documents\WindowsPowerShell') \Scripts\) | Where `
#    { $_.Name -notlike '__*' -and $_.Name -like '*.ps1'} | ForEach `
#    { . $_.FullName }
