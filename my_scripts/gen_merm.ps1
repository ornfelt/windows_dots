param (
    [string]$InputFile
)

if (-not $InputFile) {
    Write-Host "Usage: mermaid_script.ps1 <input_file>" -ForegroundColor Red
    exit 1
}

$mermaidCli = (Get-Command "npx" -ErrorAction SilentlyContinue)
if (-not $mermaidCli) {
    Write-Host "Error: npx is not installed. Install Node.js and Mermaid CLI." -ForegroundColor Red
    exit 1
}

$outputFile = [System.IO.Path]::ChangeExtension($InputFile, ".png")
$outputFileAlt = "$outputFile-1"

# npm install -g @mermaid-js/mermaid-cli
# mmdc -i test.md -o test.png
Write-Output "Running command: npx @mermaid-js/mermaid-cli@latest -i $InputFile -o $outputFile"

npx @mermaid-js/mermaid-cli@latest -i "$InputFile" -o "$outputFile"

if ((Test-Path $outputFile) -or (Test-Path $outputFileAlt)) {
    Write-Host "Mermaid diagram generated: $outputFile or $outputFileAlt" -ForegroundColor Green
} else {
    Write-Host "Error: Failed to generate Mermaid diagram." -ForegroundColor Red
}

