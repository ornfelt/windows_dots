# Processes by cpu
Get-Process | Where-Object { $_.CPU -gt 100 }