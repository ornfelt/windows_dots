﻿<#
.SYNOPSIS
	Lists the Fibonacci numbers
.DESCRIPTION
	This PowerShell script lists the first 100 Fibonacci numbers.
.EXAMPLE
	PS> ./list-fibonacci.ps1
	1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, ...
.LINK
	https://github.com/fleschutz/PowerShell
.NOTES
	Author: Markus Fleschutz | License: CC0
#>

function fibo([int]$n) {
    if ($n -lt 2) { return 1 }
    return (fibo($n - 1)) + (fibo($n - 2))
}


foreach ($i in 0..100) {
	Write-Host "$(fibo $i), " -noNewline
}
exit 0 # success
