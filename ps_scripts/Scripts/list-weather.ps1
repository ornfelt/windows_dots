﻿<#
.SYNOPSIS
	Lists the weather report
.DESCRIPTION
	This PowerShell script lists the hourly weather report in a nice table.
.PARAMETER Location
	Specifies the location to use (determined automatically per default)
.EXAMPLE
	PS> ./list-weather
.LINK
	https://github.com/fleschutz/PowerShell
.NOTES
	Author: Markus Fleschutz | License: CC0
#>

param([string]$Location = "") # empty means determine automatically

function GetDescription { param([string]$Text)
	switch($Text) {
	"Blizzard"			{ return "❄️ blizzard ⚠️" }
	"Clear"				{ return "🌙 clear" }
	"Cloudy"			{ return "☁️ cloudy" }
	"Fog"				{ return "🌫  fog" }
	"Heavy snow"			{ return "❄️ heavy snow ⚠️" }
	"Light drizzle"			{ return "💧 light drizzle" }
	"Light rain"			{ return "💧 light rain" }
	"Light rain shower"		{ return "💧 light rain shower" }
	"Light sleet"			{ return "❄️ light sleet" }
	"Light snow"			{ return "❄️ light snow" }
	"Light snow showers"		{ return "❄️ light snow showers" }
	"Moderate snow"			{ return "❄️ moderate snow" }
	"Mist"				{ return "🌫  misty" }
	"Overcast"			{ return "☁️ overcast" }
	"Partly cloudy"			{ return "⛅️partly cloudy" }
	"Patchy light rain"     	{ return "💧 patchy light rain" }
	"Patchy rain possible"  	{ return "💧 patchy rain possible" }
	"Sunny"				{ return "☀️ sunny" }
	"Thundery outbreaks possible"	{ return "⚡️thundery outbreaks possible" }
	default				{ return "$Text" }
	}
}

function GetWindDir { param([string]$Text)
	switch($Text) {
	"NW"	{ return "↘" }
	"NNW"	{ return "↓" }
	"N"	{ return "↓" }
	"NNE"	{ return "↓" }
	"NE"	{ return "↙" }
	"ENE"	{ return "←" }
	"E"	{ return "←" }
	"ESE"	{ return "←" }
	"SE"	{ return "↖" }
	"SSE"	{ return "↑" }
	"S"	{ return "↑" }
	"SSW"	{ return "↑" }
	"SW"	{ return "↗" }
	"WSW"	{ return "→" }
	"W"	{ return "→" }
	"WNW"	{ return "→" }
	default { return "$Text" }
	}
}

try {
	$Weather = (Invoke-WebRequest -URI http://wttr.in/${Location}?format=j1 -userAgent "curl" -useBasicParsing).Content | ConvertFrom-Json
	$Area = $Weather.nearest_area.areaName.value
	$Region = $Weather.nearest_area.region.value
	$Country = $Weather.nearest_area.country.value	
	[int]$Day = 0
	foreach($Hourly in $Weather.weather.hourly) {
		$Hour = $Hourly.time / 100
		$Temp = $(($Hourly.tempC.toString()).PadLeft(2))
		$Precip = $Hourly.precipMM
		$Humidity = $(($Hourly.humidity.toString()).PadLeft(3))
		$Pressure = $Hourly.pressure
		$WindSpeed = $(($Hourly.windspeedKmph.toString()).PadLeft(2))
		$WindDir = GetWindDir $Hourly.winddir16Point
		$UV = $Hourly.uvIndex
		$Clouds = $(($Hourly.cloudcover.toString()).PadLeft(3))
		$Visib = $(($Hourly.visibility.toString()).PadLeft(2))
		$Desc = GetDescription $Hourly.weatherDesc.value
		if ($Hour -eq 0) {
			if ($Day -eq 0) {
				Write-Host -foregroundColor green "TODAY  🌡°C  ☂️mm  💧  💨km/h ☀️UV  ☁️  👁km  at $Area ($Region, $Country)"
			} elseif ($Day -eq 1) {
				Write-Host -foregroundColor green "TOMORROW"
			} else {
				Write-Host -foregroundColor green "Day after tomorrow"
			}
			$Day++
		}
		"$(($Hour.toString()).PadLeft(2))°°  $Temp°   $Precip  $Humidity%  $WindSpeed $WindDir   $UV   $Clouds%  $Visib  $Desc"
	}
	exit 0 # success
} catch {
	"⚠️ Error in line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"
	exit 1
}