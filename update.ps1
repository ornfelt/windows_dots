# Set the source directory
$src = ".\nvim"
# Set the destination directory, expanding the environment variable
$dest = [System.Environment]::ExpandEnvironmentVariables("%localappdata%\nvim")

# Create the destination directory if it doesn't exist
if (-not (Test-Path $dest)) {
    New-Item -Path $dest -ItemType Directory
}

# Copy all contents from source to destination, forcing overwrite
Copy-Item -Path "$src\*" -Destination $dest -Recurse -Force

Write-Host "Files copied successfully from $src to $dest"

