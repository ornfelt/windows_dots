﻿<#
.SYNOPSIS
	Lists user accounts
.DESCRIPTION
	This PowerShell script lists the user accounts on the local computer.
.EXAMPLE
	PS> ./list-user-accounts.ps1
.LINK
	https://github.com/fleschutz/PowerShell
.NOTES
	Author: Markus Fleschutz | License: CC0
#>

try {
	if ($IsLinux) {
		& getent passwd
	} else {
		& net user
	}
	exit 0 # success
} catch {
	"⚠️ Error in line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"
	exit 1
}
