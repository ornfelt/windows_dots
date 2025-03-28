The *open-netflix.ps1* Script
===========================

This script launches the Netflix application.

Parameters
----------
```powershell
/home/markus/Repos/PowerShell/scripts/open-netflix.ps1 [<CommonParameters>]

[<CommonParameters>]
    This script supports the common parameters: Verbose, Debug, ErrorAction, ErrorVariable, WarningAction, 
    WarningVariable, OutBuffer, PipelineVariable, and OutVariable.
```

Example
-------
```powershell
PS> ./open-netflix

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
	Launches the Netflix app
.DESCRIPTION
	This script launches the Netflix application.
.EXAMPLE
	PS> ./open-netflix
.LINK
	https://github.com/fleschutz/PowerShell
.NOTES
	Author: Markus Fleschutz | License: CC0
#>

Start-Process netflix:
exit 0 # success
```

*(generated by convert-ps2md.ps1 as of 11/20/2024 11:51:58)*
