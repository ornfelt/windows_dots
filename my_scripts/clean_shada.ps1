# PowerShell script to delete all files in the shada directory
$shadaPath = "$env:LOCALAPPDATA\nvim-data\shada"
Remove-Item "$shadaPath\*" -Force

# Or:
# Remove-Item "$env:LOCALAPPDATA\nvim-data\shada\*" -Force


# Notes
# nvim shada issue:
# rm ~/.local/share/nvim/shada/*
# rm  ~/.local/state/nvim/shada/* fixed the issue.
# Windows: %LOCALAPPDATA%\nvim-data
# vim.opt.shadafile = "NONE"
# probably shouldnt disable it though...

