The *open-microsoft-solitaire.ps1* Script
===========================

This script launches the Microsoft Solitaire application.

Parameters
----------
```powershell
/home/markus/Repos/PowerShell/scripts/open-microsoft-solitaire.ps1 [<CommonParameters>]

[<CommonParameters>]
    This script supports the common parameters: Verbose, Debug, ErrorAction, ErrorVariable, WarningAction, 
    WarningVariable, OutBuffer, PipelineVariable, and OutVariable.
```

Example
-------
```powershell
PS> ./open-microsoft-solitaire

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
	Launches Microsoft Solitaire 
.DESCRIPTION
	This script launches the Microsoft Solitaire application.
.EXAMPLE
	PS> ./open-microsoft-solitaire
.LINK
	https://github.com/fleschutz/PowerShell
.NOTES
	Author: Markus Fleschutz | License: CC0
#>

Start-Process xboxliveapp-1297287741:
exit 0 # success
```

*(generated by convert-ps2md.ps1 as of 11/20/2024 11:51:58)*