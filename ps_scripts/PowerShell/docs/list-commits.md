The *list-commits.ps1* Script
===========================

This PowerShell script lists all commits in a Git repository. Supported output formats are: pretty, list, compact, normal or JSON.

Parameters
----------
```powershell
/home/markus/Repos/PowerShell/scripts/list-commits.ps1 [[-RepoDir] <String>] [[-Format] <String>] [<CommonParameters>]

-RepoDir <String>
    Specifies the path to the Git repository.
    
    Required?                    false
    Position?                    1
    Default value                "$PWD"
    Accept pipeline input?       false
    Accept wildcard characters?  false

-Format <String>
    Specifies the output format: pretty|list|compact|normal|JSON (pretty by default)
    
    Required?                    false
    Position?                    2
    Default value                pretty
    Accept pipeline input?       false
    Accept wildcard characters?  false

[<CommonParameters>]
    This script supports the common parameters: Verbose, Debug, ErrorAction, ErrorVariable, WarningAction, 
    WarningVariable, OutBuffer, PipelineVariable, and OutVariable.
```

Example
-------
```powershell
PS> ./list-commits



ID      Date                            Committer               Description
--      ----                            ---------               -----------
ccd0d3e Wed Sep 29 08:28:20 2021 +0200  Markus Fleschutz        Fix typo
...

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
	Lists Git commits
.DESCRIPTION
	This PowerShell script lists all commits in a Git repository. Supported output formats are: pretty, list, compact, normal or JSON.
.PARAMETER RepoDir
	Specifies the path to the Git repository.
.PARAMETER Format
	Specifies the output format: pretty|list|compact|normal|JSON (pretty by default)
.EXAMPLE
	PS> ./list-commits

	ID      Date                            Committer               Description
	--      ----                            ---------               -----------
	ccd0d3e Wed Sep 29 08:28:20 2021 +0200  Markus Fleschutz        Fix typo
	...
.LINK
	https://github.com/fleschutz/PowerShell
.NOTES
	Author: Markus Fleschutz | License: CC0
#>

param([string]$RepoDir = "$PWD", [string]$Format = "pretty")

try {
	if (-not(Test-Path "$RepoDir" -pathType container)) { throw "Can't access directory: $RepoDir" }

	$Null = (git --version)
	if ($lastExitCode -ne "0") { throw "Can't execute 'git' - make sure Git is installed and available" }

	Write-Progress "Fetching latest updates..."
	& git -C "$RepoDir" fetch --all --quiet
	if ($lastExitCode -ne "0") { throw "'git fetch' failed" }
	Write-Progress -Completed "Done."

	if ($Format -eq "pretty") {
		""
		& git -C "$RepoDir" log --graph --format=format:'%C(bold yellow)%s%C(reset)%d by %an 🕘%cs 🔗%h' --all
	} elseif ($Format -eq "list") {
		""
		"Hash            Date            Author                  Description"
		"----            ----            ------                  -----------"
		& git log --pretty=format:"%h%x09%cs%x09%an%x09%s"
	} elseif ($Format -eq "compact") {
		""
		"List of Git Commits"
		"-------------------"
		& git -C "$RepoDir" log --graph --pretty=format:'%Cred%h%Creset%C(yellow)%d%Creset %s %C(bold blue)by %an %cr%Creset' --abbrev-commit
		if ($lastExitCode -ne "0") { throw "'git log' failed" }
	} elseif ($Format -eq "JSON") {
		& git -C "$RepoDir" log --pretty=format:'{%n  "commit": "%H",%n  "abbreviated_commit": "%h",%n  "tree": "%T",%n  "abbreviated_tree": "%t",%n  "parent": "%P",%n  "abbreviated_parent": "%p",%n  "refs": "%D",%n  "encoding": "%e",%n  "subject": "%s",%n  "sanitized_subject_line": "%f",%n  "body": "%b",%n  "commit_notes": "%N",%n  "verification_flag": "%G?",%n  "signer": "%GS",%n  "signer_key": "%GK",%n  "author": {%n    "name": "%aN",%n    "email": "%aE",%n    "date": "%aD"%n  },%n  "commiter": {%n    "name": "%cN",%n    "email": "%cE",%n    "date": "%cD"%n  }%n},'
	} else {
		""
		"List of Git Commits"
		"-------------------"
		& git -C "$RepoDir" log
		if ($lastExitCode -ne "0") { throw "'git log' failed" }
	}
	exit 0 # success
} catch {
	"⚠️ Error in line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"
	exit 1
}
```

*(generated by convert-ps2md.ps1 as of 11/20/2024 11:51:55)*
