The *install-thunderbird.ps1* Script
===========================

This PowerShell script installs Mozilla Thunderbird.

Parameters
----------
```powershell
/home/markus/Repos/PowerShell/scripts/install-thunderbird.ps1 [<CommonParameters>]

[<CommonParameters>]
    This script supports the common parameters: Verbose, Debug, ErrorAction, ErrorVariable, WarningAction, 
    WarningVariable, OutBuffer, PipelineVariable, and OutVariable.
```

Example
-------
```powershell
PS> ./install-thunderbird.ps1

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
	Installs Thunderbird
.DESCRIPTION
	This PowerShell script installs Mozilla Thunderbird.
.EXAMPLE
	PS> ./install-thunderbird.ps1
.LINK
	https://github.com/fleschutz/PowerShell
.NOTES
	Author: Markus Fleschutz | License: CC0
#>

try {
	"Installing Mozilla Thunderbird, please wait..."

	& winget install --id Mozilla.Thunderbird --accept-package-agreements --accept-source-agreements
	if ($lastExitCode -ne "0") { throw "'winget install' failed" }

	"Mozilla Thunderbird installed successfully."
	exit 0 # success
} catch {
	"Sorry: $($Error[0])"
	exit 1
}
```

*(generated by convert-ps2md.ps1 as of 11/20/2024 11:51:54)*