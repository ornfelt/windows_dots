The *speak-polish.ps1* Script
===========================

This PowerShell script speaks the given text with a Polish text-to-speech (TTS) voice.

Parameters
----------
```powershell
/home/markus/Repos/PowerShell/scripts/speak-polish.ps1 [[-text] <String>] [<CommonParameters>]

-text <String>
    Specifies the Polish text to speak
    
    Required?                    false
    Position?                    1
    Default value                
    Accept pipeline input?       false
    Accept wildcard characters?  false

[<CommonParameters>]
    This script supports the common parameters: Verbose, Debug, ErrorAction, ErrorVariable, WarningAction, 
    WarningVariable, OutBuffer, PipelineVariable, and OutVariable.
```

Example
-------
```powershell
PS> ./speak-polish.ps1 cześć

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
	Speaks text in Polish
.DESCRIPTION
	This PowerShell script speaks the given text with a Polish text-to-speech (TTS) voice.
.PARAMETER text
	Specifies the Polish text to speak
.EXAMPLE
	PS> ./speak-polish.ps1 cześć
.LINK
	https://github.com/fleschutz/PowerShell
.NOTES
	Author: Markus Fleschutz | License: CC0
#>

param([string]$text = "")

try {
	if ($text -eq "") { $text = Read-Host "Enter the Polish text to speak" }

	$TTS = New-Object -ComObject SAPI.SPVoice
	foreach ($voice in $TTS.GetVoices()) {
		if ($voice.GetDescription() -like "*- Polish*") { 
			$TTS.Voice = $voice
			[void]$TTS.Speak($text)
			exit 0 # success
		}
	}
	throw "No Polish text-to-speech voice found - please install one"
} catch {
	"⚠️ Error in line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"
	exit 1
}
```

*(generated by convert-ps2md.ps1 as of 11/20/2024 11:52:01)*