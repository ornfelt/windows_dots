﻿<#
.SYNOPSIS
	Installs software updates
.DESCRIPTION
	This PowerShell script installs updates for the local machine (needs admin rights).
.EXAMPLE
	PS> ./install-updates
.LINK
	https://github.com/fleschutz/PowerShell
.NOTES
	Author: Markus Fleschutz | License: CC0
#>

try {
	$StopWatch = [system.diagnostics.stopwatch]::startNew()

	if ($IsLinux) {
		"⏳ (1/4) Querying updates for installed Debian packages..."
		& sudo apt update

		"⏳ (2/4) Upgrading installed Debian packages..."
		& sudo apt upgrade --yes

		"⏳ (3/4) Removing obsolete Debian packages..."
		& sudo apt autoremove --yes

		"⏳ (4/4) Upgrading installed Snap packages..."
		& sudo snap refresh
	} else {
		"⏳ (1/2) Querying application updates..."
		& winget upgrade
		" "
		"⏳ (2/2) Upgrading applications..."
		& winget upgrade --all
	}
	[int]$Elapsed = $StopWatch.Elapsed.TotalSeconds
	"✅ updates installed in $Elapsed sec."
	exit 0 # success
} catch {
	"⚠️ Error in line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"
	exit 1
}