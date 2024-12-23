﻿<#
.SYNOPSIS
        Checks the GPU status
.DESCRIPTION
        This PowerShell script queries the GPU status and prints it.
.EXAMPLE
        PS> ./check-gpu.ps1
	✅ NVIDIA Quadro P400 GPU (2GB RAM, 3840x2160 pixels, 32-bit, 59Hz, driver 31.0.15.1740) - status OK
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
        return "$($Bytes)TB"
}

try {
	if ($IsLinux) {
		# TODO
	} else {
		$Details = Get-WmiObject Win32_VideoController
		$Model = $Details.Caption
		$RAMSize = $Details.AdapterRAM
		$ResWidth = $Details.CurrentHorizontalResolution
		$ResHeight = $Details.CurrentVerticalResolution
		$BitsPerPixel = $Details.CurrentBitsPerPixel
		$RefreshRate = $Details.CurrentRefreshRate
		$DriverVersion = $Details.DriverVersion
		$Status = $Details.Status
		Write-Host "✅ $Model GPU ($(Bytes2String $RAMSize) RAM, $($ResWidth)x$($ResHeight) pixels, $($BitsPerPixel)-bit, $($RefreshRate)Hz, driver $DriverVersion) - status $Status"
	}
	exit 0 # success
} catch {
        "⚠️ Error in line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"
        exit 1
}
