oh-my-posh init pwsh | Invoke-Expression

$omp_config = Join-Path $PSScriptRoot ".\custom_1_shell.omp.json"
oh-my-posh --init --shell pwsh --config $omp_config | Invoke-Expression

#$omp_config = Join-Path $PSScriptRoot ".\custom_tokyonight_storm.omp.json"
#oh-my-posh --init --shell pwsh --config $omp_config | Invoke-Expression

#$omp_config = Join-Path $PSScriptRoot ".\custom_cobalt2.omp.json"
#oh-my-posh --init --shell pwsh --config $omp_config | Invoke-Expression

#$omp_config = Join-Path $PSScriptRoot ".\powerline.omp.json"
#oh-my-posh --init --shell pwsh --config $omp_config | Invoke-Expression

# PSReadLine
Import-Module PSReadLine
Set-PSReadLineOption -BellStyle None
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineOption -EditMode Vi

# Fzf
Import-Module PSFzf
Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+f' -PSReadlineChordReverseHistory 'Ctrl+r'

# Alias
Set-Alias -Name .cdh -Value C:\Users\Svea" "User\Documents\WindowsPowerShell\Scripts\cdh.ps1
Set-Alias -Name .cdc -Value C:\Users\Svea" "User\Documents\WindowsPowerShell\Scripts\cdc.ps1
Set-Alias -Name .cdp -Value C:\Users\Svea" "User\Documents\WindowsPowerShell\Scripts\cdp.ps1
Set-Alias -Name .ioq3 -Value C:\Users\Svea" "User\Documents\WindowsPowerShell\Scripts\ioq3.ps1
Set-Alias -Name .show-wifi -Value C:\Users\Svea" "User\Documents\WindowsPowerShell\Scripts\show-wifi.ps1

# Load all scripts
#Get-ChildItem (Join-Path ('C:\Users\Svea User\Documents\WindowsPowerShell') \Scripts\) | Where `
#    { $_.Name -notlike '__*' -and $_.Name -like '*.ps1'} | ForEach `
#    { . $_.FullName }
