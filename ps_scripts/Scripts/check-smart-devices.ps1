﻿<#
.SYNOPSIS
	Checks SMART devices
.DESCRIPTION
	This PowerShell script queries S.M.A.R.T. HDD/SSD device details and prints it.
.EXAMPLE
	PS> ./check-smart-devices
	✅ 1TB Samsung SSD 970 EVO via NVMe: 37°C, 2388 hours, 289x on, v2B2QEXE7, selftest passed
.LINK
	https://github.com/fleschutz/PowerShell
.NOTES
	Author: Markus Fleschutz | License: CC0
#>

function Bytes2String { param([int64]$Bytes)
	if ($Bytes -lt 1000) { return "$Bytes bytes" }
	$Bytes /= 1000
	if ($Bytes -lt 1000) { return "$($Bytes)KB" }
	$Bytes /= 1000
	if ($Bytes -lt 1000) { return "$($Bytes)MB" }
	$Bytes /= 1000
	if ($Bytes -lt 1000) { return "$($Bytes)GB" }
	$Bytes /= 1000
	if ($Bytes -lt 1000) { return "$($Bytes)TB" }
	$Bytes /= 1000
	if ($Bytes -lt 1000) { return "$($Bytes)PB" }
	$Bytes /= 1000
	if ($Bytes -lt 1000) { return "$($Bytes)EB" }
}

try {
	Write-Progress "⏳ Step 1/3 - Searching for smartctl executable..."
	$Result = (smartctl --version)
	if ($lastExitCode -ne "0") { throw "Can't execute 'smartctl' - make sure smartmontools are installed" }

	Write-Progress "⏳ Step 2/3 - Scanning S.M.A.R.T devices..."
	if ($IsLinux) {
		$Devices = $(sudo smartctl --scan-open)
	} else {
		$Devices = $(smartctl --scan-open)
	}
	foreach($Device in $Devices) {
		Write-Progress "⏳ Step 3/3 - Querying S.M.A.R.T devices..."
		$Array = $Device.split(" ")
		$Device = $Array[0]
		if ("$Device" -eq "#") {
			continue
		} elseif ($IsLinux) {
			$Details = (sudo smartctl --all --json $Device) | ConvertFrom-Json
			$null = (sudo smartctl --test=short $Device)
		} else {
			$Details = (smartctl --all --json $Device) | ConvertFrom-Json
			$null = (smartctl --test=short $Device)
		}
		$ModelName = $Details.model_name
		$Protocol = $Details.device.protocol
		[int64]$GBytes = $Details.user_capacity.bytes
		if ($GBytes -gt 0) {
			$Capacity = "$(Bytes2String $GBytes) "
		} else {
			$Capacity = ""
		}
		$Temp = $Details.temperature.current
		$Firmware = $Details.firmware_version
		$PowerOn = $Details.power_cycle_count
		$Hours = $Details.power_on_time.hours
		if ($Details.smart_status.passed) { $Status = "passed" } else { $Status = "FAILED" }
		"✅ $($Capacity)$ModelName via $($Protocol): $($Temp)°C, $($Hours) hours, $($PowerOn)x on, v$($Firmware), selftest $Status"
	}
	exit 0 # success
} catch {
	"⚠️ Error in line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"
	exit 1
}
