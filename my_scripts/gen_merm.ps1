param (
    [string]$InputFile
)

if (-not $InputFile) {
    Write-Host "Usage: mermaid_script.ps1 <input_file>/all/*" -ForegroundColor Red
    exit 1
}

$Recursive = $false

if ($InputFile -ieq "all" -or $InputFile -ieq "*") {
    Write-Host "Generating Mermaid diagrams for all .md and .mermaid files..." -ForegroundColor Cyan

    # old: only md files in current dir:
    #Get-ChildItem -Filter *.md | ForEach-Object {
    #    & $PSCommandPath $_.Name
    #}
    # new: md and mermaid files with recursive being optional
    Get-ChildItem -Path . -File -Recurse:$Recursive | 
        Where-Object { $_.Extension -in '.md', '.mermaid' } | 
        ForEach-Object {
            # Use FullName so recursion works from any depth
            & $PSCommandPath $_.FullName
        }

    exit 0
}

# If no extension is provided, append .md
if ([IO.Path]::GetExtension($InputFile) -eq "") {
    $InputFile = "$InputFile.md"
    Write-Host "No extension detected; trying input file '$InputFile'..." -ForegroundColor Yellow
}

# Verify file existence
if (-not (Test-Path $InputFile)) {
    Write-Host "Error: Input file '$InputFile' not found." -ForegroundColor Red
    exit 1
}

# Ensure npx/mermaid-cli is available
$mermaidCli = (Get-Command "npx" -ErrorAction SilentlyContinue)
if (-not $mermaidCli) {
    Write-Host "Error: npx is not installed. Install Node.js and Mermaid CLI." -ForegroundColor Red
    exit 1
}

$outputFile = [System.IO.Path]::ChangeExtension($InputFile, ".png")
$outputFileAlt = "$outputFile-1"

#$useScale = $false
$useScale = $true

# npm install -g @mermaid-js/mermaid-cli
# mmdc -i test.md -o test.png
if ($useScale) {
    Write-Output "Running command: npx @mermaid-js/mermaid-cli@latest --scale 2 -i $InputFile -o $outputFile"
    npx @mermaid-js/mermaid-cli@latest --scale 2 -i "$InputFile" -o "$outputFile" -b transparent
} else {
    Write-Output "Running command: npx @mermaid-js/mermaid-cli@latest -i $InputFile -o $outputFile"
    npx @mermaid-js/mermaid-cli@latest -i "$InputFile" -o "$outputFile" -b transparent
}

if ((Test-Path $outputFile) -or (Test-Path $outputFileAlt)) {
    Write-Host "Mermaid diagram generated: $outputFile or $outputFileAlt" -ForegroundColor Green
}
#else {
#    Write-Host "Error: Failed to generate Mermaid diagram." -ForegroundColor Red
#}

