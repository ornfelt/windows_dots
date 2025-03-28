The *list-network-shares.ps1* Script
===========================

This PowerShell script lists all network shares (aka "shared folders") of the local computer.

Parameters
----------
```powershell
/home/markus/Repos/PowerShell/scripts/list-network-shares.ps1 [<CommonParameters>]

[<CommonParameters>]
    This script supports the common parameters: Verbose, Debug, ErrorAction, ErrorVariable, WarningAction, 
    WarningVariable, OutBuffer, PipelineVariable, and OutVariable.
```

Example
-------
```powershell
PS> ./list-network-shares.ps1
✅ Network share \\LAPTOP\Public -> D:\Public ("Public folder for file transfer")

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
	Lists the network shares
.DESCRIPTION
	This PowerShell script lists all network shares (aka "shared folders") of the local computer.
.EXAMPLE
	PS> ./list-network-shares.ps1
	✅ Network share \\LAPTOP\Public -> D:\Public ("Public folder for file transfer")
.LINK
	https://github.com/fleschutz/PowerShell
.NOTES
	Author: Markus Fleschutz | License: CC0
#>

try {
	if ($IsLinux) {
		# TODO
	} else {
		$shares = Get-WmiObject win32_share | where {$_.name -NotLike "*$"} 
		foreach ($share in $shares) {
			Write-Output "✅ Network share \\$(hostname)\$($share.Name) -> $($share.Path) (`"$($share.Description)`")"
		}
	}
	exit 0 # success
} catch {
	"⚠️ Error in line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"
	exit 1
}
```

*(generated by convert-ps2md.ps1 as of 11/20/2024 11:51:56)*
