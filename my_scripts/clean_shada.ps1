# PowerShell script to delete all files in the shada directory
$shadaPath = "$env:LOCALAPPDATA\nvim-data\shada"
Remove-Item "$shadaPath\*" -Force

# Or:
# Remove-Item "$env:LOCALAPPDATA\nvim-data\shada\*" -Force

