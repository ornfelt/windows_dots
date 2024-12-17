param (
    [string]$InputFile
)

if (-not $InputFile) {
    Write-Host "Usage: plantuml_script.ps1 <input_file>" -ForegroundColor Red
    exit 1
}

$myNotesPath = $env:my_notes_path
if (-not $myNotesPath) {
    Write-Host "Error: Environment variable 'my_notes_path' is not set." -ForegroundColor Red
    exit 1
}

$plantUmlJar = Join-Path -Path $myNotesPath -ChildPath "scripts\plants\plantuml.jar"
if (-not (Test-Path $plantUmlJar)) {
    Write-Host "Error: PlantUML jar not found at $plantUmlJar." -ForegroundColor Red
    exit 1
}

Write-Output "Running command: java -jar $plantUmlJar $InputFile"

java -jar "$plantUmlJar" "$InputFile"
Write-Host "PlantUML diagram generated for $InputFile." -ForegroundColor Green

