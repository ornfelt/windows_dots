The *close-calculator.ps1* Script
===========================

This PowerShell script closes the calculator application gracefully.

Parameters
----------
```powershell
/home/markus/Repos/PowerShell/scripts/close-calculator.ps1 [<CommonParameters>]

[<CommonParameters>]
    This script supports the common parameters: Verbose, Debug, ErrorAction, ErrorVariable, WarningAction, 
    WarningVariable, OutBuffer, PipelineVariable, and OutVariable.
```

Example
-------
```powershell
PS> ./close-calculator

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
	Closes the calculator application
.DESCRIPTION
	This PowerShell script closes the calculator application gracefully.
.EXAMPLE
	PS> ./close-calculator
.LINK
	https://github.com/fleschutz/PowerShell
.NOTES
	Author: Markus Fleschutz | License: CC0
#>

Stop-Process -name "CalculatorApp"
exit 0 # success
```

*(generated by convert-ps2md.ps1 as of 11/20/2024 11:51:52)*