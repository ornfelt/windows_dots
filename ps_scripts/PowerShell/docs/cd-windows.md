The *cd-windows.ps1* Script
===========================

This PowerShell script changes the working directory to the Windows directory.

Parameters
----------
```powershell
/home/markus/Repos/PowerShell/scripts/cd-windows.ps1 [<CommonParameters>]

[<CommonParameters>]
    This script supports the common parameters: Verbose, Debug, ErrorAction, ErrorVariable, WarningAction, 
    WarningVariable, OutBuffer, PipelineVariable, and OutVariable.
```

Example
-------
```powershell
PS> ./cd-windows
📂C:\Windows

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
	Sets the working directory to the Windows directory
.DESCRIPTION
	This PowerShell script changes the working directory to the Windows directory.
.EXAMPLE
	PS> ./cd-windows
	📂C:\Windows
.LINK
	https://github.com/fleschutz/PowerShell
.NOTES
	Author: Markus Fleschutz | License: CC0
#>

try {
	$path = Resolve-Path "$env:WINDIR"
	if (-not(Test-Path "$path" -pathType container)) { throw "Windows directory at 📂$path doesn't exist" }
	Set-Location "$path"
	"📂$path"
	exit 0 # success
} catch {
	"⚠️ Error in line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"
	exit 1
}
```

*(generated by convert-ps2md.ps1 as of 11/20/2024 11:51:50)*