﻿<#
.SYNOPSIS
	Query the app status
.DESCRIPTION
	This PowerShell script queries the installed applications and prints it.
.EXAMPLE
	PS> ./check-apps.ps1
	⚠️ 150 Win apps installed, 72 upgrades available, 5 crash dump(s) found
.LINK
	https://github.com/fleschutz/PowerShell
.NOTES
	Author: Markus Fleschutz | License: CC0
#>

function CountCrashDumps {
	[string]$path = Resolve-Path -Path "~\AppData\Local\CrashDumps"
	$files = (Get-ChildItem -path "$path\*.dmp" -attributes !Directory)
	return $files.Count
}

try {
	$status = "✅"
	if ($IsLinux) {
		Write-Progress "Querying installed applications..."
		$numPkgs = (apt list --installed 2>/dev/null).Count
		$numSnaps = (snap list).Count - 1
		Write-Progress -completed "Done."
		$reply = "$numPkgs Debian packages, $numSnaps snaps installed"
	} else {
		Write-Progress "Querying installed apps..."
		$apps = Get-AppxPackage
		Write-Progress -completed "Done."
		$reply = "$($apps.Count) Win apps installed"

		[int]$numNonOk = 0
		foreach($app in $apps) { if ($app.Status -ne "Ok") { $numNonOk++ } }
		if ($numNonOk -gt 0) { $status = "⚠️"; $reply += ", $numNonOk non-ok" }

		[int]$numErrors = (Get-AppxLastError)
		if ($numErrors -gt 0) { $status = "⚠️"; $reply += ", $numErrors errors" }

		$numUpdates = (winget upgrade --include-unknown).Count - 5
		$reply += ", $numUpdates upgrades available"

		$numCrashDumps = CountCrashDumps
		if ($numCrashDumps -ne 0) { $status = "⚠️"; $reply += ", $numCrashDumps crash dump(s) found" }
	}
	Write-Host "$status $reply"
	exit 0 # success
} catch {
	"⚠️ Error in line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"
	exit 1
}