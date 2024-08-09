﻿<#
.SYNOPSIS
	Copy photos sorted by year and month
.DESCRIPTION
	This PowerShell script copies image files from sourceDir to targetDir sorted by year and month.
.PARAMETER sourceDir
	Specifies the path to the source folder
.PARAMTER targetDir
	Specifies the path to the target folder
.EXAMPLE
	PS> ./copy-photos-sorted.ps1 D:\iPhone\DCIM C:\MyPhotos
	⏳ Copying IMG_20230903_134445.jpg to C:\MyPhotos\2023\09 SEP\...
	✔️ Copied 1 photo to 📂C:\MyPhotos in 41 sec
.LINK
	https://github.com/fleschutz/PowerShell
.NOTES
	Author: Markus Fleschutz | License: CC0
#>

param([string]$sourceDir = "", [string]$targetDir = "")

function CopyFile { param([string]$sourcePath, [string]$targetDir, [int]$date, [string]$filename)
	[int]$year = $date / 10000
	[int]$month = ($date / 100) % 100
	$monthDir = switch($month) {
	1  {"01 JAN"}
	2  {"02 FEB"}
	3  {"03 MAR"}
	4  {"04 APR"}
	5  {"05 MAY"}
	6  {"06 JUN"}
	7  {"07 JUL"}
	8  {"08 AUG"}
	9  {"09 SEP"}
	10 {"10 OCT"}
	11 {"11 NOV"}
	12 {"12 DEC"}
	}
	$TargetPath = "$targetDir/$year/$monthDir/$filename"
	if (Test-Path "$TargetPath" -pathType leaf) {
		Write-Host "⏳ Skipping existing $targetDir\$year\$monthDir\$filename..."
	} else {
		Write-Host "⏳ Copying $filename to $targetDir\$year\$monthDir\..."
		New-Item -path "$targetDir" -name "$year" -itemType "directory" -force | out-null
		New-Item -path "$targetDir/$year" -name "$monthDir" -itemType "directory" -force | out-null
		Copy-Item "$sourcePath" "$TargetPath" -force
	}
}

try {
	if ($sourceDir -eq "") { $sourceDir = Read-Host "Enter file path to the source directory" }
	if ($targetDir -eq "") { $targetDir = Read-Host "Enter file path to the target directory" }
	$stopWatch = [system.diagnostics.stopWatch]::startNew()

	Write-Host "⏳ Checking source directory 📂$($sourceDir)..."
	if (-not(Test-Path "$sourceDir" -pathType container)) { throw "Can't access source directory: $sourceDir" }
	$files = (Get-ChildItem "$sourceDir\*.jpg" -attributes !Directory)

	Write-Host "⏳ Checking target directory 📂$($targetDir)..."
	if (-not(Test-Path "$targetDir" -pathType container)) { throw "Can't access target directory: $targetDir" }

	foreach($file in $files) {
		$filename = (Get-Item "$file").Name
		if ("$filename" -like "IMG_*_*.jpg") {
			$Array = $filename.split("_")
			CopyFile "$file" "$targetDir" $Array[1] "$filename"
		} elseif ("$filename" -like "IMG-*-*.jpg") {
			$Array = $filename.split("-")
			CopyFile "$file" "$targetDir" $Array[1] "$filename"
		} elseif ("$filename" -like "PANO_*_*.jpg") {
			$Array = $filename.split("_")
			CopyFile "$file"  "$targetDir" $Array[1] "$filename"
		} elseif ("$filename" -like "PANO-*-*.jpg") {
			$Array = $filename.split("-")
			CopyFile "$file" "$targetDir" $Array[1] "$filename"
		} elseif ("$filename" -like "SAVE_*_*.jpg") {
			$Array = $filename.split("_")
			CopyFile "$file" "$targetDir" $Array[1] "$filename"
		} elseif ("$filename" -like "PXL_*_*.jpg") {
			$Array = $filename.split("_")
			CopyFile "$file" "$targetDir" $Array[1] "$filename"
		} else {
			Write-Host "⏳ Skipping $filename with unknown filename format..."
		}
	}
	[int]$elapsed = $stopWatch.Elapsed.TotalSeconds
	"✔️ Copied $($files.Count) photos to 📂$targetDir in $elapsed sec"
	exit 0 # success
} catch {
	"⚠️ Error in line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"
	exit 1
}
