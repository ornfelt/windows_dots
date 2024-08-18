﻿<#
.SYNOPSIS
	Lists the weather of cities world-wide 
.DESCRIPTION
	This PowerShell script lists the current weather conditions of cities world-wide (west to east).
.EXAMPLE
	PS> ./list-city-weather.ps1
.LINK
	https://github.com/fleschutz/PowerShell
.NOTES
	Author: Markus Fleschutz | License: CC0
#>

function ListCityWeather {
	$Cities="Hawaii","Los Angeles","Mexico City","Dallas","Miami","New York","Rio de Janeiro","Paris","London","Berlin","Cape Town","Dubai","Mumbai","Singapore","Hong Kong","Perth","Peking","Tokyo","Sydney"

	foreach($City in $Cities) {
		$Temp = (Invoke-WebRequest http://wttr.in/${City}?format="%t %c " -UserAgent "curl" -useBasicParsing).Content
		$Rain = (Invoke-WebRequest http://wttr.in/${City}?format="%p %h" -UserAgent "curl" -useBasicParsing).Content
		$Wind = (Invoke-WebRequest http://wttr.in/${City}?format="%w" -UserAgent "curl" -useBasicParsing).Content
		$Sun = (Invoke-WebRequest http://wttr.in/${City}?format="%S → %s" -UserAgent "curl" -useBasicParsing).Content
		New-Object PSObject -Property @{ City="$City"; Temp="$Temp"; Rain="$Rain"; Wind="$Wind"; Sun="$Sun" }
	}
}

try {
	ListCityWeather | Format-Table -property @{e='City';width=17},@{e='Temp';width=13},@{e='Rain';width=15},@{e='Wind';width=12},@{e='Sun';width=20}
	exit 0 # success
} catch {
	"⚠️ Error in line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"
	exit 1
}