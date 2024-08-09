# Script will disable saving or offering to save to Onedrive when saving in office.

if (Get-PackageProvider -Name NuGet) {
    Write-Output "NuGet Already Installed"
} 
else {
    Write-Host "Installing NuGet"
    Install-PackageProvider -Name NuGet -Force
} 
 
if (Get-Module -ListAvailable -Name RunAsUser) {
    Write-Output "RunAsUser Already Installed"
} 
else {
    Write-Output "Installing RunAsUser"
    Install-Module -Name RunAsUser -Force
}

If (!(test-path "$env:programdata\Tactical RMM\temp\")) {
    New-Item -ItemType Directory -Force -Path "$env:programdata\Tactical RMM\temp\"
}

If (!(test-path "$env:programdata\Tactical RMM\temp\curpsxpolicy.txt")) {
    $curexpolicy = Get-ExecutionPolicy

    (
        Write-Output $curexpolicy
    )>"$env:programdata\Tactical RMM\temp\curpsxpolicy.txt"
}
Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell -Name ExecutionPolicy -Value Unrestricted


Invoke-AsCurrentUser -scriptblock {
    $ofc = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
    $OfficeInstall = Get-ChildItem -Path $ofc -Recurse | Where-Object {
    $_.GetValue('DisplayName') -like "Microsoft Office*" -or $_.GetValue('DisplayName') -like "Microsoft 365 Apps*"}
    $Version = $OfficeInstall.GetValue('DisplayVersion')[0..3] -join ""
    New-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Office\$Version\Common\General -Name PreferCloudSaveLocations -Value 0  -PropertyType DWORD
    New-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Office\$Version\Common\Internet -Name OnlineStorage -Value 3  -PropertyType DWORD
}

$curpsxpol = Get-Content -Path "$env:programdata\Tactical RMM\temp\curpsxpolicy.txt";
    
Set-ExecutionPolicy -ExecutionPolicy $curpsxpol
