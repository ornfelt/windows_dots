param(
    [Parameter(Position = 0)]
    [string]$Language,

    [Parameter(Position = 1)]
    [string]$Keyword
)

# Load shared JSON data
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$jsonPath = Join-Path $env:my_notes_path "scripts/help_data.json"

if (-not $env:my_notes_path) {
    throw "Environment variable 'my_notes_path' is not set."
}

if (-not (Test-Path -LiteralPath $jsonPath -PathType Leaf)) {
    throw "Could not find help data file: $jsonPath"
}

$data = Get-Content -LiteralPath $jsonPath -Raw | ConvertFrom-Json

# Build alias map from JSON
$languageMap = @{}
foreach ($prop in $data.aliases.PSObject.Properties) {
    $languageMap[$prop.Name] = $prop.Value
}

function Write-CommandWithDescription {
    param(
        [string]$Command,
        [string]$Description,
        [ConsoleColor]$Color = [ConsoleColor]::Cyan
    )

    Write-Host "  " -NoNewline
    Write-Host $Command -ForegroundColor $Color -NoNewline
    if ($Description) {
        Write-Host " - $Description"
    }
    else {
        Write-Host ""
    }
}

# Helper: write a code line, with any comment part ('#...') in gray
function Write-CodeLine {
    param(
        [string]$Text,
        [ConsoleColor]$CommandColor = [ConsoleColor]::Green,
        [ConsoleColor]$CommentColor = [ConsoleColor]::DarkGray
    )

    # Treat # as a comment only when preceded by whitespace.
    $commentMatch = [regex]::Match($Text, '\s+#')

    if ($commentMatch.Success) {
        # The regex includes the whitespace before #.
        $hashIndex = $commentMatch.Index + $commentMatch.Length - 1

        $before  = $Text.Substring(0, $hashIndex)
        $comment = $Text.Substring($hashIndex)

        if ($before.Length -gt 0) {
            Write-Host $before -ForegroundColor $CommandColor -NoNewline
        }

        Write-Host $comment -ForegroundColor $CommentColor
    }
    else {
        Write-Host $Text -ForegroundColor $CommandColor
    }
}

function Write-CleanWarning {
    Write-Host "Be careful: below command(s) hard-delete generated files/folders from the current directory." -ForegroundColor DarkYellow
}

# Helper: check if a section's descriptive text matches the keyword (case-insensitive)
function Test-SectionMatch {
    param(
        [string]$SectionText,
        [string]$Keyword
    )
    if (-not $Keyword) { return $true }
    return $SectionText.ToLower().Contains($Keyword.Trim().ToLower())
}

# Print "Filtered by keyword: ..." header when keyword is provided
function Write-KeywordFilter {
    param(
        [string]$Keyword
    )
    if ($Keyword) {
        Write-Host "Filtered by keyword: $Keyword" -ForegroundColor DarkGray
    }
}

# IMPORTANT: When no arg (or unknown arg), print ONLY the available args and nothing else.
function Show-Args {
    foreach ($a in $data.args_display) {
        Write-Host "  $a" -ForegroundColor Magenta
    }

    Write-Host ""
    Write-Host "  Optional second arg: keyword to filter sections" -ForegroundColor DarkGray
    Write-Host "  Example: .help cs clean" -ForegroundColor DarkGray
    Write-Host "  Example: .help scripts build" -ForegroundColor DarkGray
}

# Check platform filter for an item (windows-only items are shown, linux-only are skipped)
function Test-PlatformMatch {
    param($Item)
    $platform = if ($Item.platform) { $Item.platform } else { "both" }
    return ($platform -ne "linux")
}

# Helper for path-entry keyword filtering (matches on label+path)
function Show-PathEntry {
    param(
        [string]$Label,
        [string]$Path,
        [string]$Keyword
    )

    if ($Keyword) {
        $k = $Keyword.Trim().ToLower()
        $haystack = "$Label $Path".ToLower()
        if (-not $haystack.Contains($k)) {
            return
        }
    }

    Write-Host "${Label}:" -ForegroundColor DarkGray
    Write-Host $Path -ForegroundColor Green
    Write-Host ""
}

# Render a single item from the JSON
function Render-Item {
    param($Item, [string]$Keyword)

    switch ($Item.type) {
        "code"          { Write-CodeLine $Item.text }
        "cmd" {
            $color = if ($Item.color) {
                [ConsoleColor]$Item.color
            }
            else {
                [ConsoleColor]::Cyan
            }

            Write-CommandWithDescription $Item.cmd $Item.desc $color
        }
        "header"        { Write-Host $Item.text -ForegroundColor Yellow }
        "comment"       { Write-Host $Item.text -ForegroundColor DarkGray }
        "blank"         { Write-Host "" }
        "clean_warning" { Write-CleanWarning }
        "path"          { Show-PathEntry $Item.label $Item.path $Keyword }
    }
}

# Generic section renderer: reads mode from JSON, filters by platform and keyword
function Show-Section {
    param(
        [string]$ModeName,
        [string]$Keyword
    )

    $mode = $data.modes.$ModeName
    if (-not $mode) { return }

    # Print mode title
    $title = if ($mode.title_windows) { $mode.title_windows } else { $mode.title }
    if ($mode.leading_blank) { Write-Host "" }
    Write-Host $title -ForegroundColor Yellow
    Write-KeywordFilter $Keyword
    if (-not $mode.leading_blank) { Write-Host "" }

    # Iterate subsections
    foreach ($sub in $mode.subsections) {
        if (-not (Test-SectionMatch $sub.match $Keyword)) { continue }

        foreach ($item in $sub.items) {
            if (-not (Test-PlatformMatch $item)) { continue }
            Render-Item $item $Keyword
        }
    }
}

# Main argument handling
# If no argument: print ONLY available args and exit
if (-not $Language) {
    Show-Args
    exit 0
}

# Normalize & validate argument (case-insensitive)
$key = $Language.Trim().ToLower()
if (-not $languageMap.ContainsKey($key)) {
    Show-Args
    exit 1
}

$normalizedLanguage = $languageMap[$key]

Write-Host "Selected: " -NoNewline
Write-Host $normalizedLanguage -ForegroundColor Magenta
if ($Keyword) {
    Write-Host "Keyword: " -NoNewline
    Write-Host $Keyword -ForegroundColor DarkYellow
}

Show-Section $normalizedLanguage $Keyword
