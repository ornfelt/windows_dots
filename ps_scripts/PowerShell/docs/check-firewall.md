The *check-firewall.ps1* Script
===========================

This PowerShell script queries the status of the firewall and prints it.

Parameters
----------
```powershell
/home/markus/Repos/PowerShell/scripts/check-firewall.ps1 [<CommonParameters>]

[<CommonParameters>]
    This script supports the common parameters: Verbose, Debug, ErrorAction, ErrorVariable, WarningAction, 
    WarningVariable, OutBuffer, PipelineVariable, and OutVariable.
```

Example
-------
```powershell
PS> ./check-firewall.ps1
✅ Firewall enabled

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
	Checks the firewall status
.DESCRIPTION
	This PowerShell script queries the status of the firewall and prints it.
.EXAMPLE
	PS> ./check-firewall.ps1
	✅ Firewall enabled
.LINK
	https://github.com/fleschutz/PowerShell
.NOTES
	Author: Markus Fleschutz | License: CC0
#>

try {
	if ($IsLinux) {
		Write-Host "✅ Firewall " -noNewline
		& sudo ufw status
	} else {
		$enabled = (gp 'HKLM:\SYSTEM\ControlSet001\Services\SharedAccess\Parameters\FirewallPolicy\DomainProfile').EnableFirewall
		if ($enabled) {
			Write-Host "✅ Firewall enabled"
		} else {
			Write-Host "⚠️ Firewall disabled"
		}
	}
	exit 0 # success
} catch {
	"⚠️ Error in line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"
	exit 1
}
```

*(generated by convert-ps2md.ps1 as of 11/20/2024 11:51:51)*