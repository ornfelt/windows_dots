Script: *switch-tabs.ps1*
========================

This PowerShell script switches automatically from tab to tab every <n> seconds (by pressing Ctrl + PageDown).

Parameters
----------
```powershell
PS> ./switch-tabs.ps1 [[-timeInterval] <Int32>] [<CommonParameters>]

-timeInterval <Int32>
    Specifies the time interval in seconds (10sec per default)
    
    Required?                    false
    Position?                    1
    Default value                10
    Accept pipeline input?       false
    Accept wildcard characters?  false

[<CommonParameters>]
    This script supports the common parameters: Verbose, Debug, ErrorAction, ErrorVariable, WarningAction, 
    WarningVariable, OutBuffer, PipelineVariable, and OutVariable.
```

Example
-------
```powershell
PS> ./switch-tabs.ps1
⏳ Switching from tab to tab automatically every 10 seconds...
   (click the Web browser to activate it - press <Ctrl C> here to stop it)

```

Notes
-----
Author: Markus Fleschutz / License: CC0

Related Links
-------------
https://github.com/fleschutz/PowerShell

Script Content
--------------
```powershell
<#
.SYNOPSIS
	Switches Web browser tabs
.DESCRIPTION
	This PowerShell script switches automatically from tab to tab every <n> seconds (by pressing Ctrl + PageDown).
.PARAMETER timeInterval
        Specifies the time interval in seconds (10sec per default)
.EXAMPLE
	PS> ./switch-tabs.ps1
	⏳ Switching from tab to tab automatically every 10 seconds...
	   (click the Web browser to activate it - press <Ctrl C> here to stop it)
.NOTES
	Author: Markus Fleschutz / License: CC0
.LINK
	https://github.com/fleschutz/PowerShell
#>

param([int]$timeInterval = 10) # in seconds

try {
	Write-Host "⏳ Switching from tab to tab automatically every $timeInterval seconds..."
	Write-Host "   (click the Web browser to activate it - press <Ctrl C> here to stop it)"
	$obj = New-Object -com wscript.shell
	while ($true) {
		$obj.SendKeys("^{PGDN}")
		Start-Sleep -seconds $timeInterval
	}
	exit 0 # success
} catch {
	"⚠️ Error in line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"
	exit 1
}
```

*(generated by convert-ps2md.ps1 using the comment-based help of switch-tabs.ps1 as of 05/19/2024 10:25:26)*