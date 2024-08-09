﻿<#
.SYNOPSIS
	Check for pending reboots
.DESCRIPTION
	This PowerShell script queries pending operating system reboots and prints it.
.EXAMPLE
	./check-pending-reboot.ps1
	✅ No pending reboot
.LINK
        https://github.com/fleschutz/PowerShell
.NOTES
        Author: Markus Fleschutz | License: CC0
#>

function Test-RegistryValue { param([parameter(Mandatory=$true)][ValidateNotNullOrEmpty()]$Path, [parameter(Mandatory=$true)] [ValidateNotNullOrEmpty()]$Value)
	try {
		Get-ItemProperty -Path $Path -Name $Value -EA Stop
		return $true
	} catch {
		return $false
	}
}

try {
	$Reason = ""
	if ($IsLinux) {
		if (Test-Path "/var/run/reboot-required") {
			$Reason = "found: /var/run/reboot-required"
			Write-Host "⚠️ Pending reboot ($Reason)"
		}
	} else {
		if (Test-Path -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired") {
			$Reason += ", ...\Auto Update\RebootRequired"
		}
		if (Test-Path -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\PostRebootReporting") {
			$Reason += ", ...\Auto Update\PostRebootReporting"
		}
		if (Test-Path -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending") {
			$Reason += ", ...\Component Based Servicing\RebootPending"
		}
		if (Test-Path -Path "HKLM:\SOFTWARE\Microsoft\ServerManager\CurrentRebootAttempts") {
			$Reason += ", ...\ServerManager\CurrentRebootAttempts"
		}
		if (Test-RegistryValue -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing" -Value "RebootInProgress") {
			$Reason += ", ...\CurrentVersion\Component Based Servicing with 'RebootInProgress'"
		}
		if (Test-RegistryValue -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing" -Value "PackagesPending") {
			$Reason += ", '...\CurrentVersion\Component Based Servicing' with 'PackagesPending'"
		}
		if (Test-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" -Value "PendingFileRenameOperations2") {
			$Reason += ", '...\CurrentControlSet\Control\Session Manager' with 'PendingFileRenameOperations2'"
		}
		if (Test-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" -Value "DVDRebootSignal") {
			$Reason += ", '...\Windows\CurrentVersion\RunOnce' with 'DVDRebootSignal'"
		}
		if (Test-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon" -Value "JoinDomain") {
			$Reason += ", '...\CurrentControlSet\Services\Netlogon' with 'JoinDomain'"
		}
		if (Test-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon" -Value "AvoidSpnSet") {
			$Reason += ", '...\CurrentControlSet\Services\Netlogon' with 'AvoidSpnSet'"
		}
		if ($Reason -ne "") {
			Write-Host "⚠️ Pending reboot (registry got $($Reason.substring(2)))"
		}
	}
	if ($Reason -eq "") {
		Write-Host "✅ No pending reboot"
	}
	exit 0 # success
} catch {
        "⚠️ Error in line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"
        exit 1
}
