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

# --- Dispatch ----------------------------------------------------------------

Write-Info "Dispatching to [$langDir] -> $scriptPath"

if ($forwardArgs.Count -gt 0) {
    Write-InfoAlt "Forwarding args: $forwardArgs"
}

& $scriptPath @forwardArgs
exit $LASTEXITCODE

