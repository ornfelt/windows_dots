param(
    # Default mode: get value for a specific key
    [Parameter(Position = 0)]
    [string]$Key,

    # Search mode: print all key/values where key OR value contains this string
    [Parameter(Mandatory = $false)]
    [string]$Search,

    # List mode: print all key/values
    [switch]$List
)

# Example usage:
# Get a specific value (default mode):
# .\search_conf.ps1 my_username
# .\search_conf.ps1 "my_username"
# 
# Search in keys and values:
# .\search_conf.ps1 -Search local
# 
# List all key-value pairs:
# .\search_conf.ps1 -List

# Path to config file
$configPath = "C:\local\config.txt"

# Check file existence
if (-not (Test-Path -Path $configPath -PathType Leaf)) {
    Write-Error "Config file not found: $configPath"
    exit 1
}

# Read file, ignore comments and empty/whitespace-only lines
$lines = Get-Content -Path $configPath | Where-Object {
    # Remove leading/trailing whitespace
    $trimmed = $_.Trim()
    # Keep only non-empty, non-comment lines
    $trimmed -ne "" -and -not $trimmed.StartsWith("#")
}

# Parse lines into key/value objects
# Format: key: value
$entries = foreach ($line in $lines) {
    # Split only on the first colon, in case values contain colons
    $parts = $line.Split(":", 2)

    if ($parts.Count -lt 2) {
        # Line does not match "key: value" format; skip or warn if you want
        continue
    }

    $k = $parts[0].Trim()
    $v = $parts[1].Trim()

    # Only include if key is non-empty
    if ($k -ne "") {
        [PSCustomObject]@{
            Key   = $k
            Value = $v
        }
    }
}

# If -List is specified, ignore Key/Search and print everything
if ($List) {
    $entries | ForEach-Object { "$($_.Key): $($_.Value)" }
    exit 0
}

# If -Search is specified, perform substring search on key OR value
if ($Search) {
    $matches = $entries | Where-Object {
        $_.Key   -like "*$Search*" -or
        $_.Value -like "*$Search*"
    }

    if (-not $matches) {
        Write-Host "No entries matching search string: '$Search'"
        exit 0
    }

    $matches | ForEach-Object { "$($_.Key): $($_.Value)" }
    exit 0
}

# Default behavior:
# If a single positional argument is provided (Key), print its value
if ($Key) {
    $match = $entries | Where-Object { $_.Key -eq $Key } | Select-Object -First 1
    if ($match) {
        # Print only the value, as requested
        Write-Output $match.Value
        exit 0
    } else {
        Write-Host "Key not found: '$Key'"
        exit 1
    }
}

# brief usage
Write-Host "Usage:"
Write-Host "  search_conf.ps1 <key>            # Print value for given key"
Write-Host "  search_conf.ps1 -Search <text>   # Search in keys and values (substring)"
Write-Host "  search_conf.ps1 -List            # List all key/value pairs"
exit 0

