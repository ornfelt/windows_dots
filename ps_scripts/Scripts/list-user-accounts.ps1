﻿<#
.SYNOPSIS
	Lists user accounts
.DESCRIPTION
	This PowerShell script lists the user accounts on the local computer.
.EXAMPLE
	PS> ./list-user-accounts
.LINK
	https://github.com/fleschutz/PowerShell
.NOTES
	Author: Markus Fleschutz | License: CC0
#>

try {
	& net user
	exit 0 # success
} catch {
	"⚠️ Error in line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"
	exit 1
}