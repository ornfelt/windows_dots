The *open-vpn-settings.ps1* Script
===========================

This PowerShell script launches the VPN settings of Windows.

Parameters
----------
```powershell
/home/markus/Repos/PowerShell/scripts/open-vpn-settings.ps1 [<CommonParameters>]

[<CommonParameters>]
    This script supports the common parameters: Verbose, Debug, ErrorAction, ErrorVariable, WarningAction, 
    WarningVariable, OutBuffer, PipelineVariable, and OutVariable.
```

Example
-------
```powershell
PS> ./open-vpn-settings

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
	Opens the VPN settings
.DESCRIPTION
	This PowerShell script launches the VPN settings of Windows.
.EXAMPLE
	PS> ./open-vpn-settings
.LINK
	https://github.com/fleschutz/PowerShell
.NOTES
	Author: Markus Fleschutz | License: CC0
#>

Start-Process ms-settings:network-vpn
exit 0 # success
```

*(generated by convert-ps2md.ps1 as of 11/20/2024 11:51:59)*