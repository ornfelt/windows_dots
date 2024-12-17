param (
    [string]$InputFile
)

# Exit if no argument is passed
if (-not $InputFile) {
    Write-Host "Usage: mermaid_script.ps1 <input_file>" -ForegroundColor Red
    exit 1
}

# Ensure Mermaid CLI is installed
$mermaidCli = (Get-Command "npx" -ErrorAction SilentlyContinue)
if (-not $mermaidCli) {
    Write-Host "Error: npx is not installed. Install Node.js and Mermaid CLI." -ForegroundColor Red
    exit 1
}

# Define output file path
$outputFile = [System.IO.Path]::ChangeExtension($InputFile, ".png")

# Run Mermaid CLI
npx @mermaid-js/mermaid-cli@latest -i "$InputFile" -o "$outputFile"

if (Test-Path $outputFile) {
    Write-Host "Mermaid diagram generated: $outputFile" -ForegroundColor Green
} else {
    Write-Host "Error: Failed to generate Mermaid diagram." -ForegroundColor Red
}
