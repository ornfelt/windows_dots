Script: *uninstall-git-extensions.ps1*
========================

This PowerShell script uninstalls Git Extensions from the local computer.

Parameters
----------
```powershell
PS> ./uninstall-git-extensions.ps1 [<CommonParameters>]

[<CommonParameters>]
    This script supports the common parameters: Verbose, Debug, ErrorAction, ErrorVariable, WarningAction, 
    WarningVariable, OutBuffer, PipelineVariable, and OutVariable.
```

Example
-------
```powershell
PS> ./uninstall-git-extensions

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
	Uninstalls Git Extensions
.DESCRIPTION
	This PowerShell script uninstalls Git Extensions from the local computer.
.EXAMPLE
	PS> ./uninstall-git-extensions
.LINK
	https://github.com/fleschutz/PowerShell
.NOTES
	Author: Markus Fleschutz | License: CC0
#>

try {
	"Uninstalling Git Extensions, please wait..."

	& winget uninstall --id GitExtensionsTeam.GitExtensions
	if ($lastExitCode -ne "0") { throw "Can't uninstall Git Extensions, is it installed?" }

	"Git Extensions is uninstalled now."
	exit 0 # success
} catch {
	"⚠️ Error in line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"
	exit 1
}
```

*(generated by convert-ps2md.ps1 using the comment-based help of uninstall-git-extensions.ps1 as of 08/15/2024 09:50:55)*