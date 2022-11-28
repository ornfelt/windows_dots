<#
.SYNOPSIS
        Installs Unbound (needs admin rights)
.DESCRIPTION
        This PowerShell script installs Unbound, a validating, recursive, caching DNS resolver. It needs admin rights.
.EXAMPLE
        PS> ./install-unbound
.LINK
        https://github.com/fleschutz/PowerShell
.NOTES
	Author: Markus Fleschutz | License: CC0
#>

#Requires -RunAsAdministrator

try {
	$StopWatch = [system.diagnostics.stopwatch]::startNew()

	"⏳ Step 1/10: Updating package infos..."
	& sudo apt update -y
	if ($lastExitCode -ne "0") { throw "'sudo apt update' failed" }

	"⏳ Step 2/10: Installing Unbound package..."
	& sudo apt install unbound -y
	if ($lastExitCode -ne "0") { throw "'sudo apt install unbound' failed" }

	"⏳ Step 3/10: Setting up Unbound..."
	& sudo unbound-control-setup
	if ($lastExitCode -ne "0") { throw "'unbound-control-setup' failed" }

	"⏳ Step 4/10: Updating DNSSEC Root Trust Anchors..."
	& sudo unbound-anchor
	if ($lastExitCode -ne "0") { throw "'unbound-anchor' failed" }

	"⏳ Step 5/10: Checking config file..."
	& unbound-checkconf "$PSScriptRoot/../Data/unbound.conf"
	if ($lastExitCode -ne "0") { throw "'unbound-checkconf' failed - check the syntax" }

	"⏳ Step 6/10: Copying config file to /etc/unbound/unbound.conf ..."
	& sudo cp "$PSScriptRoot/../Data/unbound.conf" /etc/unbound/unbound.conf
	if ($lastExitCode -ne "0") { throw "'cp' failed" }

	"⏳ Step 7/10: Stopping default DNS cache daemon systemd-resolved..."
	& sudo systemctl stop systemd-resolved
	& sudo systemctl disable systemd-resolved

	"⏳ Step 8/10: (Re-)starting Unbound..."
	& sudo unbound-control stop
	& sudo unbound-control start
	if ($lastExitCode -ne "0") { throw "'unbound-control start' failed" }

	"⏳ Step 9/10: Checking Unbound status..."
	& sudo unbound-control status
	if ($lastExitCode -ne "0") { throw "'unbound-control status' failed" }

	"⏳ Step 10/10: Training Unbound with frequently used domain names..."
	& "$PSScriptRoot/check-dns.ps1" 
	if ($lastExitCode -ne "0") { throw "'unbound-control status' failed" }

	[int]$Elapsed = $StopWatch.Elapsed.TotalSeconds
	"✔️ installed Unbound in $Elapsed sec"
	exit 0 # success
} catch {
	"⚠️ Error in line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"
	exit 1
}
