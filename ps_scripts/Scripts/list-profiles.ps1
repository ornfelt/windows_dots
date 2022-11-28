﻿<#
.SYNOPSIS
	Lists the user's PowerShell profiles
.DESCRIPTION
	This PowerShell script lists the user's PowerShell profiles.
.EXAMPLE
	PS> ./list-profiles
	
	Level Profile                Location                                                         Existent
	----- -------                --------                                                         --------
	1     AllUsersAllHosts       /opt/PowerShell/profile.ps1                                      no
	2     AllUsersCurrentHost    /opt/PowerShell/Microsoft.PowerShell_profile.ps1                 no
	3     CurrentUserAllHosts    /home/markus/.config/powershell/profile.ps1                      no
	4     CurrentUserCurrentHost /home/markus/.config/powershell/Microsoft.PowerShell_profile.ps1 yes
.LINK
	https://github.com/fleschutz/PowerShell
.NOTES
	Author: Markus Fleschutz | License: CC0
#>

function ListProfile { param([int]$Level, [string]$Profile, [string]$Location)
	if (test-path "$Location") { $Existent = "yes" } else { $Existent = "no" }
	New-Object PSObject -Property @{ 'Level'="$Level"; 'Profile'="$Profile"; 'Location'="$Location"; 'Existent'="$Existent"	}
}

function ListProfiles { 
	ListProfile 1 "AllUsersAllHosts"       $PROFILE.AllUsersAllHosts
	ListProfile 2 "AllUsersCurrentHost"    $PROFILE.AllUsersCurrentHost
	ListProfile 3 "CurrentUserAllHosts"    $PROFILE.CurrentUserAllHosts
	ListProfile 4 "CurrentUserCurrentHost" $PROFILE.CurrentUserCurrentHost
}

try {
	ListProfiles | format-table -property Level,Profile,Location,Existent
	exit 0 # success
} catch {
	"⚠️ Error in line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"
	exit 1
}
