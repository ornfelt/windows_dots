The *check-admin.ps1* Script
===========================

This PowerShell script checks if the user has administrator rights.

Parameters
----------
```powershell
/home/markus/Repos/PowerShell/scripts/check-admin.ps1 [<CommonParameters>]

[<CommonParameters>]
    This script supports the common parameters: Verbose, Debug, ErrorAction, ErrorVariable, WarningAction, 
    WarningVariable, OutBuffer, PipelineVariable, and OutVariable.
```

Example
-------
```powershell
PS> ./check-admin.ps1
✅ Yes, Markus has admin rights.

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
        Check for admin rights
.DESCRIPTION
        This PowerShell script checks if the user has administrator rights.
.EXAMPLE
        PS> ./check-admin.ps1
        ✅ Yes, Markus has admin rights.
.LINK
        https://github.com/fleschutz/PowerShell
.NOTES
        Author: Markus Fleschutz | License: CC0
#>

try {
	if ($IsLinux) {
		# todo
	} else {
		$user = [Security.Principal.WindowsIdentity]::GetCurrent()
		$principal = (New-Object Security.Principal.WindowsPrincipal $user)
		if ($principal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
			"✅ Yes, $USERNAME has admin rights."
		} elseif ($principal.IsInRole([Security.Principal.WindowsBuiltinRole]::Guest)) {
			"⚠️ No, $USERNAME, has guest rights only."
		} else {
			"⚠️ No, $USERNAME has normal user rights only."
		}
	}  
	exit 0 # success
} catch {
	"⚠️ Error: $($Error[0]) (in script line $($_.InvocationInfo.ScriptLineNumber))"
	exit 1
}	
```

*(generated by convert-ps2md.ps1 as of 11/20/2024 11:51:50)*