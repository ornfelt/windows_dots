Script: *ping-local-hosts.ps1*
========================

This PowerShell script pings the computers in the local network and lists which one are up.

Parameters
----------
```powershell
PS> ./ping-local-hosts.ps1 [[-timeout] <Int32>] [<CommonParameters>]

-timeout <Int32>
    
    Required?                    false
    Position?                    1
    Default value                600
    Accept pipeline input?       false
    Accept wildcard characters?  false

[<CommonParameters>]
    This script supports the common parameters: Verbose, Debug, ErrorAction, ErrorVariable, WarningAction, 
    WarningVariable, OutBuffer, PipelineVariable, and OutVariable.
```

Example
-------
```powershell
PS> ./ping-local-hosts.ps1
✅ Up: hippo jenkins01 jenkins02 rocket vega

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
        Pings local hosts
.DESCRIPTION
        This PowerShell script pings the computers in the local network and lists which one are up.
.EXAMPLE
        PS> ./ping-local-hosts.ps1
	✅ Up: hippo jenkins01 jenkins02 rocket vega 
.LINK
        https://github.com/fleschutz/PowerShell
.NOTES
        Author: Markus Fleschutz | License: CC0
#>

param([int]$timeout = 600) # ms ping timeout


try {
	$names = @('accesspoint','AD','AP','amnesiac','archlinux','auriga','berlin','boston','brother','canon','castor','cisco','echodot','epson','epson2550','epson2815','fedora','fireball','firewall','fritz.box','fritz.repeater','gassensor','gateway','hippo','heizung','hodor','homemanager','io','iphone','jarvis','jenkins','LA','laptop','linux','jupiter','mars','mercury','miami','mobile','none','none-1','none-2','NY','octo','office','officepc','paris','PI','pixel-6a','PC','pluto','printer','proxy','R2D2','raspberry','rocket','rome','router','sentinel','server','shelly','shelly1','smartphone','smartwatch','soundbar','sunnyboy','surface','switch','tablet','tau','tigercat','tolino','TV','ubuntu','vega','venus','xrx','zeus') # sorted alphabetically
        $queue = [System.Collections.Queue]::new()
	foreach($name in $names) {
		$ping = [System.Net.Networkinformation.Ping]::new()
		$queue.Enqueue( @{Host=$name; Ping=$ping; Async=$ping.SendPingAsync($name, $timeout)} )
        }

	[string]$up = ""
	Write-Host "✅ Up: " -noNewline
	while ($queue.Count -gt 0) { $obj = $queue.Dequeue()
		try { if ($obj.Async.Wait($timeout)) {
				if ($obj.Async.Result.Status -ne "TimedOut") { Write-Host "$($obj.Host) " -noNewline }
				continue
			}
		} catch { continue }
		$queue.Enqueue($obj)
	}
	exit 0 # success
} catch {
        "⚠️ Error in line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"
        exit 1
}
```

*(generated by convert-ps2md.ps1 using the comment-based help of ping-local-hosts.ps1 as of 08/15/2024 09:50:52)*