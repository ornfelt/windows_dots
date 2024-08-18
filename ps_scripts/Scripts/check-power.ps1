﻿<#
.SYNOPSIS
	Checks the power status
.DESCRIPTION
	This PowerShell script queries the power status and prints it.
.EXAMPLE
	PS> ./check-power.ps1
	⚠️ Battery at 9% with 54min remaining · power scheme 'HP Optimized' 
.LINK
	https://github.com/fleschutz/PowerShell
.NOTES
	Author: Markus Fleschutz | License: CC0
#>

try {
	if ($IsLinux) {
		$reply = "✅ AC powered" # TODO, just guessing :-)
	} else {
		Add-Type -Assembly System.Windows.Forms
		$details = [System.Windows.Forms.SystemInformation]::PowerStatus
		[int]$percent = 100 * $details.BatteryLifePercent
		[int]$remaining = $details.BatteryLifeRemaining / 60
		if ($details.PowerLineStatus -eq "Online") {
			if ($details.BatteryChargeStatus -eq "NoSystemBattery") {
				$reply = "✅ AC powered"
			} elseif ($percent -ge 95) {
				$reply = "✅ Battery $percent% full"
			} else {
				$reply = "✅ Battery charging ($percent%)"
			}
		} else { # must be offline
			if (($remaining -eq 0) -and ($percent -ge 60)) {
				$reply = "✅ Battery $percent% full"
			} elseif ($remaining -eq 0) {
				$reply = "✅ Battery at $percent%"
			} elseif ($remaining -le 5) {
				$reply = "⚠️ Battery at $percent% with ONLY $($remaining)min remaining"
			} elseif ($remaining -le 30) {
				$reply = "⚠️ Battery at $percent% with only $($remaining)min remaining"
			} elseif ($percent -lt 10) {
				$reply = "⚠️ Battery at $percent% with $($remaining)min remaining"
			} elseif ($percent -ge 80) {
				$reply = "✅ Battery $percent% full with $($remaining)min remaining"
			} else {
				$reply = "✅ Battery at $percent% with $($remaining)min remaining"
			}
		}
		$powerScheme = (powercfg /getactivescheme)
		$powerScheme = $powerScheme -Replace "^(.*)  \(",""
		$powerScheme = $powerScheme -Replace "\)$",""
		$reply += ", power scheme is '$powerScheme'"
	}
	Write-Host $reply
	exit 0 # success
} catch {
	"⚠️ Error in line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"
	exit 1
}
