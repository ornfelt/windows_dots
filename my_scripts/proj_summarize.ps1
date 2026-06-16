# proj_summarize.ps1 - Language dispatcher for proj_summarize scripts

function Write-Ok      ([string]$m) { Write-Host $m -ForegroundColor Green }
function Write-Err     ([string]$m) { Write-Host $m -ForegroundColor Red }
function Write-Warn    ([string]$m) { Write-Host $m -ForegroundColor DarkYellow }
function Write-Info    ([string]$m) { Write-Host $m -ForegroundColor Cyan }
function Write-InfoAlt ([string]$m) { Write-Host $m -ForegroundColor Magenta }

# --- Validate args -----------------------------------------------------------

if ($args.Count -eq 0) {
    Write-Err "Usage: proj_summarize.ps1 <language> [args...]"
    Write-Info "Supported languages: c, cs, c#, csharp, cpp, c++, go, golang, java, js, javascript, ts, typescript, py, python, rust, rs"
    exit 1
}

$langInput = $args[0]

if ($args.Count -gt 1) {
    $forwardArgs = $args[1..($args.Count - 1)]
} else {
    $forwardArgs = @()
}

# --- Language map (case-insensitive via .ToLower()) --------------------------

$languageMap = @{
    'c'          = 'c'
    'cs'         = 'cs'
    'c#'         = 'cs'
    'csharp'     = 'cs'
    'cpp'        = 'cpp'
    'c++'        = 'cpp'
    'go'         = 'go'
    'golang'     = 'go'
    'java'       = 'java'
    'js'         = 'js'
    'javascript' = 'js'
    'ts'         = 'ts'
    'typescript' = 'ts'
    'py'         = 'py'
    'python'     = 'py'
    'rust'       = 'rs'
    'rs'         = 'rs'
}

$langKey = $langInput.ToLower()

if (-not $languageMap.ContainsKey($langKey)) {
    Write-Err "Unknown language: '$langInput'"
    Write-Info "Supported: $($languageMap.Keys -join ', ')"
    exit 1
}

$langDir = $languageMap[$langKey]

# --- Resolve my_notes_path ---------------------------------------------------

$notesPath = $env:my_notes_path

if (-not $notesPath) {
    Write-Err "Environment variable 'my_notes_path' is not set."
    exit 1
}

$scriptPath = Join-Path $notesPath "scripts\files\proj_summarize\$langDir\proj_summarize.ps1"

if (-not (Test-Path $scriptPath)) {
    Write-Warn "No proj_summarize script found for language '$langDir'."
    Write-Warn "Expected: $scriptPath"
    exit 1
}

# --- Report file map ---------------------------------------------------------

$reportFileMap = @{
    'cs'   = 'csproj-summary.txt'
    'go'   = 'go-summary.txt'
    'java' = 'java-summary.txt'
    'js'   = 'package-summary.txt'
    'ts'   = 'package-summary.txt'
    'py'   = 'python-summary.txt'
    'rs'   = 'rust-summary.txt'
    'c'    = 'c-summary.txt'
    'cpp'  = 'cpp-summary.txt'
}

# --- Dispatch ----------------------------------------------------------------

Write-Info "Dispatching to [$langDir] -> $scriptPath"

if ($forwardArgs.Count -gt 0) {
    Write-InfoAlt "Forwarding args: $forwardArgs"
}

& $scriptPath @forwardArgs
#exit $LASTEXITCODE
# prompt to see if user wants to keep report before exiting...
$exitCode = $LASTEXITCODE

# Only ask if the language script succeeded
if ($exitCode -eq 0) {
    if ($reportFileMap.ContainsKey($langDir)) {
        $reportFileName = $reportFileMap[$langDir]
        $reportFilePath = Join-Path (Get-Location) $reportFileName

        if (Test-Path $reportFilePath) {
            #Write-Info "Summary file produced: $reportFilePath"
            $answer = Read-Host "Keep this summary file? Type yes/y to keep"

            if ($answer.Trim() -match '^(?i:y|yes)$') {
                Write-Ok "Keeping summary file: $reportFilePath"
            }
            else {
                Remove-Item $reportFilePath -Force
                Write-Warn "Deleted summary file: $reportFilePath"
            }
        }
        else {
            Write-Warn "Expected summary file was not found: $reportFilePath"
        }
    }
    else {
        Write-Warn "No report file mapping configured for language '$langDir'."
    }
}

exit $exitCode
