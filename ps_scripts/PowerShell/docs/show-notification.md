The *show-notification.ps1* Script
===========================

This PowerShell script shows a toast-message notification for the Windows Notification Center.

Parameters
----------
```powershell
/home/markus/Repos/PowerShell/scripts/show-notification.ps1 [[-text] <String>] [[-title] <String>] [[-duration] <Int32>] [<CommonParameters>]

-text <String>
    Specifies the text to show ('Hello World' by default)
    
    Required?                    false
    Position?                    1
    Default value                Hello World
    Accept pipeline input?       false
    Accept wildcard characters?  false

-title <String>
    Specifies the title to show ('NOTE' by default)
    
    Required?                    false
    Position?                    2
    Default value                NOTE
    Accept pipeline input?       false
    Accept wildcard characters?  false

-duration <Int32>
    Specifies the view duration in milliseconds (5000 by default)
    
    Required?                    false
    Position?                    3
    Default value                5000
    Accept pipeline input?       false
    Accept wildcard characters?  false

[<CommonParameters>]
    This script supports the common parameters: Verbose, Debug, ErrorAction, ErrorVariable, WarningAction, 
    WarningVariable, OutBuffer, PipelineVariable, and OutVariable.
```

Example
-------
```powershell
PS> ./show-notification.ps1

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
	Shows a notification
.DESCRIPTION
	This PowerShell script shows a toast-message notification for the Windows Notification Center.
.PARAMETER text
	Specifies the text to show ('Hello World' by default)
.PARAMETER title
	Specifies the title to show ('NOTE' by default)
.PARAMETER duration
	Specifies the view duration in milliseconds (5000 by default)
.EXAMPLE
	PS> ./show-notification.ps1
.LINK
	https://github.com/fleschutz/PowerShell
.NOTES
	Author: Markus Fleschutz | License: CC0
#>

param([string]$text = "Hello World", [string]$title = "NOTE", [int]$duration = 5000)

try {
	Add-Type -AssemblyName System.Windows.Forms 
	$global:balloon = New-Object System.Windows.Forms.NotifyIcon
	$path = (Get-Process -id $pid).Path
	$balloon.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($path) 
	$balloon.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::Info
	$balloon.BalloonTipText = $text
	$balloon.BalloonTipTitle = $title 
	$balloon.Visible = $true 
	$balloon.ShowBalloonTip($duration)
	exit 0 # success
} catch {
	"⚠️ Error in line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"
	exit 1
}
```

*(generated by convert-ps2md.ps1 as of 11/20/2024 11:52:00)*