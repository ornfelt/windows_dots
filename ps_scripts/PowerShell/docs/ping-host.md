The *ping-host.ps1* Script
===========================

This PowerShell script pings the given host.

Parameters
----------
```powershell
/home/markus/Repos/PowerShell/scripts/ping-host.ps1 [[-hostname] <String>] [<CommonParameters>]

-hostname <String>
    Specifies the hostname or IP address to ping (windows.com by default)
    
    Required?                    false
    Position?                    1
    Default value                windows.com
    Accept pipeline input?       false
    Accept wildcard characters?  false

[<CommonParameters>]
    This script supports the common parameters: Verbose, Debug, ErrorAction, ErrorVariable, WarningAction, 
    WarningVariable, OutBuffer, PipelineVariable, and OutVariable.
```

Example
-------
```powershell
PS> ./ping-host.ps1 x.com
✅ x.com is up and running (11ms latency).

```

Notes
-----
Author: Markus Fleschutz | License: CC0

Related Links
-------------
https://github.com/fleschutz/PowerShell

Script Content
--------------
```powershell
<#
.SYNOPSIS
	Pings a host
.DESCRIPTION
	This PowerShell script pings the given host.
.PARAMETER hostname
	Specifies the hostname or IP address to ping (windows.com by default)
.EXAMPLE
	PS> ./ping-host.ps1 x.com
	✅ x.com is up and running (11ms latency).
.LINK
	https://github.com/fleschutz/PowerShell
.NOTES
	Author: Markus Fleschutz | License: CC0
#>

param([string]$hostname = "windows.com")

function GetPingLatency([string]$hostname) {
	$hostsArray = $hostname.Split(",")
	$tasks = $hostsArray | foreach { (New-Object Net.NetworkInformation.Ping).SendPingAsync($_,1500) }
	[Threading.Tasks.Task]::WaitAll($tasks)
	foreach($ping in $tasks.Result) { if ($ping.Status -eq "Success") { return $ping.RoundtripTime } }
	return 1500
}

try {
	[int]$latency = GetPingLatency($hostname)
	if ($latency -eq 1500) {
		Write-Host "⚠️ Host '$hostname' doesn't respond - check the connection or maybe the host is down."
		exit 1
	} 
	Write-Host "✅ $hostname is up and running ($($latency)ms latency)."
	exit 0 # success
} catch {
	"⚠️ Error in line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"
	exit 1
}
```

*(generated by convert-ps2md.ps1 as of 11/20/2024 11:51:59)*