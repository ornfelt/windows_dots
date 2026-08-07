param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$InputDir,

    [Parameter(Mandatory = $false, Position = 1)]
    [string]$OutputFile = (Join-Path (Get-Location) "dumped_files.txt"),

    [Parameter(Mandatory = $false, Position = 2)]
    [bool]$Recursive = $false,

    [Parameter(Mandatory = $false, Position = 3)]
    [bool]$UseFullPaths = $false,

    [Parameter(Mandatory = $false, Position = 4)]
    [string[]]$Extensions = @(),

    # Directory names to skip when recursing, e.g. @("obj", "bin")
    [Parameter(Mandatory = $false, Position = 5)]
    [string[]]$ExcludeDirs = @(),

    # Only keep files whose name matches one of these globs, e.g. @("*Controller*.cs")
    [Parameter(Mandatory = $false)]
    [string[]]$IncludePatterns = @(),

    # Skip files whose name matches one of these globs, e.g. @("*.g.cs", "*.Designer.cs")
    [Parameter(Mandatory = $false)]
    [string[]]$ExcludePatterns = @(),

    # Write the metadata header at the top of the dump (overrides the hard-coded toggle below)
    [Parameter(Mandatory = $false)]
    [switch]$MetadataHeader,

    # Print the command that would be run instead of running it.
    # NOTE: -Debug is reserved by PowerShell, so this is -DebugCommand (or -ShowCmd / -DebugC).
    [Parameter(Mandatory = $false)]
    [Alias('ShowCmd')]
    [switch]$DebugCommand
)

# Example usage:
# Only required arg (non-recursive, file names only, output to dumped_files.txt in current dir)
# .\dump_files.ps1 $Env:code_root_dir/Code2/C++/space/cs/BlackholeGfx/shaders/gl
# Specify output file:
# .\dump_files.ps1 "$Env:code_root_dir/Code2/C++/space/cs/BlackholeGfx/shaders/gl" "C:/temp/shader_dump.txt"
# Recursive:
# .\dump_files.ps1 "$Env:code_root_dir/Code2/C++/space/cs/BlackholeGfx/shaders" "C:/temp/shader_dump.txt" $true
# Recursive + full paths in headers:
# .\dump_files.ps1 "$Env:code_root_dir/Code2/C++/space/cs/BlackholeGfx/shaders" "C:/temp/shader_dump.txt" $true $true
# Filter by extension:
# .\dump_files.ps1 "$Env:code_root_dir/Code2/Wow/tools/my_wow/c++/my_web_wow/src" "C:/temp/dump.txt" $true $false @(".cpp", ".h")
# Use cwd and only .cs files:
# .\dump_files.ps1 . -Extensions ".cs"
# cpp example:
# .\dump_files.ps1 "$Env:code_root_dir/Code2/Wow/tools/my_wow/c++/my_web_wow/src" -Extensions @(".cpp", ".c", ".h", ".hpp")
#
# New options:
# All .cs files recursively, ignoring the "obj" and "bin" dirs:
# .\dump_files.ps1 . -Recursive $true -Extensions ".cs" -ExcludeDirs @("obj", "bin")
# .\dump_files.ps1 . "" $true $false ".cs" @("obj", "bin")
# Same, but also skipping generated files:
# .\dump_files.ps1 . -Recursive $true -Extensions ".cs" -ExcludeDirs @("obj", "bin") -ExcludePatterns @("*.g.cs", "*.Designer.cs")
# Only files matching a name pattern (recursive):
# .\dump_files.ps1 . -Recursive $true -IncludePatterns @("*Controller*.cs", "*Service*.cs")
# Print the command instead of running it (copy/paste it to see what would be dumped):
# .\dump_files.ps1 . -Recursive $true -Extensions ".cs" -ExcludeDirs @("obj", "bin") -DebugCommand

# Colored print helpers
function Write-Ok     ([string]$m) { Write-Host $m -ForegroundColor Green }
function Write-Err    ([string]$m) { Write-Host $m -ForegroundColor Red }
function Write-Warn   ([string]$m) { Write-Host $m -ForegroundColor DarkYellow }
function Write-Info   ([string]$m) { Write-Host $m -ForegroundColor Cyan }
function Write-InfoAlt([string]$m) { Write-Host $m -ForegroundColor Magenta }
function Write-Dim    ([string]$m) { Write-Host $m -ForegroundColor DarkGray }

# Help/usage if first arg looks like help
if ($InputDir -match '^(?i:help)$' -or $InputDir -in '-', '-h', '--help') {
    Write-InfoAlt "Usage: .\dump_files.ps1 <InputDir> [OutputFile] [Recursive] [UseFullPaths] [Extensions] [ExcludeDirs]"
    Write-InfoAlt "       [-IncludePatterns ...] [-ExcludePatterns ...] [-MetadataHeader] [-DebugCommand]"
    Write-Host ""
    Write-InfoAlt "Options:"
    Write-Info "  -InputDir <dir>             Input directory"
    Write-Info "  -OutputFile <file>          Output file (default: .\dumped_files.txt)"
    Write-Info "  -Recursive `$true/`$false     Recurse into sub directories (default: `$false)"
    Write-Info "  -UseFullPaths `$true/`$false  Full paths in the per-file headers (default: `$false)"
    Write-Info "  -Extensions @(...)          Extension filter, e.g. `".cs`" or @(`".cpp`", `".h`")"
    Write-Info "  -ExcludeDirs @(...)         Dir names to skip, e.g. @(`"obj`", `"bin`") (recursive only)"
    Write-Info "  -IncludePatterns @(...)     File name globs to keep, e.g. @(`"*Controller*.cs`")"
    Write-Info "  -ExcludePatterns @(...)     File name globs to skip, e.g. @(`"*.g.cs`", `"*.Designer.cs`")"
    Write-Info "  -MetadataHeader             Write the metadata header at the top of the dump"
    Write-Info "  -DebugCommand (-ShowCmd)    Print the command that would be run instead of running it"
    Write-Host ""
    Write-InfoAlt "Extension/pattern matching is case-insensitive; patterns match the file name, not the path."
    Write-Host ""
    Write-InfoAlt "Example usage:"
    Write-InfoAlt "  Only required arg (non-recursive, file names only, output to dumped_files.txt in current dir)"
    Write-Info "    .\dump_files.ps1 `"`$Env:code_root_dir/Code2/C++/space/cs/BlackholeGfx/shaders/gl`""
    Write-Host ""
    Write-InfoAlt "  Specify output file:"
    Write-Info "    .\dump_files.ps1 `"`$Env:code_root_dir/Code2/C++/space/cs/BlackholeGfx/shaders/gl`" `"C:/temp/shader_dump.txt`""
    Write-Host ""
    Write-InfoAlt "  Recursive:"
    Write-Info "    .\dump_files.ps1 `"`$Env:code_root_dir/Code2/C++/space/cs/BlackholeGfx/shaders`" `"C:/temp/shader_dump.txt`" `$true"
    Write-Host ""
    Write-InfoAlt "  Recursive + full paths in headers:"
    Write-Info "    .\dump_files.ps1 `"`$Env:code_root_dir/Code2/C++/space/cs/BlackholeGfx/shaders`" `"C:/temp/shader_dump.txt`" `$true `$true"
    Write-Host ""
    Write-InfoAlt "  Filter by extension:"
    Write-Info "    .\dump_files.ps1 `"`$Env:code_root_dir/Code2/C++/myproject`" `"C:/temp/dump.txt`" `$true `$false @(`".cpp`", `".h`")"
    Write-Host ""
    Write-InfoAlt "  Use cwd and only .cs files:"
    Write-Info "    .\dump_files.ps1 . -Extensions `".cs`""
    Write-Host ""
    Write-InfoAlt "  C++ files (named params):"
    Write-Info "    .\dump_files.ps1 `"`$Env:code_root_dir/Code2/Wow/tools/my_wow/c++/my_web_wow/src`" -Extensions @(`".cpp`", `".c`", `".h`", `".hpp`")"
    Write-Host ""
    Write-InfoAlt "  Recursive + named params:"
    Write-Info "    .\dump_files.ps1 `"`$Env:code_root_dir/Code2/C++/myproject`" -OutputFile `"C:/temp/dump.txt`" -Recursive `$true"
    Write-Host ""
    Write-InfoAlt "  Recursive + extension filter (named params):"
    Write-Info "    .\dump_files.ps1 `"`$Env:code_root_dir/Code2/C++/myproject`" -OutputFile `"C:/temp/dump.txt`" -Recursive `$true -Extensions @(`".cpp`", `".h`")"
    Write-Host ""
    Write-InfoAlt "  Recursive + full paths + extension filter (named params):"
    Write-Info "    .\dump_files.ps1 `"`$Env:code_root_dir/Code2/C++/myproject`" -OutputFile `"C:/temp/dump.txt`" -Recursive `$true -UseFullPaths `$true -Extensions @(`".cpp`", `".h`")"
    Write-Host ""
    Write-InfoAlt "  All .cs files recursively, ignoring the `"obj`" and `"bin`" dirs:"
    Write-Info "    .\dump_files.ps1 . -Recursive `$true -Extensions `".cs`" -ExcludeDirs @(`"obj`", `"bin`")"
    Write-Info "    .\dump_files.ps1 . `"`" `$true `$false `".cs`" @(`"obj`", `"bin`")   # same thing, positional"
    Write-Info "    .\dump_files.ps1 . -OutputFile `"C:/temp/cs_dump.txt`" -Recursive `$true -Extensions `".cs`" -ExcludeDirs @(`"obj`", `"bin`")"
    Write-Host ""
    Write-InfoAlt "  Same, but also skipping generated files:"
    Write-Info "    .\dump_files.ps1 . -Recursive `$true -Extensions `".cs`" -ExcludeDirs @(`"obj`", `"bin`") -ExcludePatterns @(`"*.g.cs`", `"*.Designer.cs`")"
    Write-Host ""
    Write-InfoAlt "  Only files matching a name pattern (recursive):"
    Write-Info "    .\dump_files.ps1 . -Recursive `$true -IncludePatterns @(`"*Controller*.cs`", `"*Service*.cs`")"
    Write-Host ""
    Write-InfoAlt "  Skip node_modules and dist when dumping a TS project:"
    Write-Info "    .\dump_files.ps1 . -Recursive `$true -Extensions @(`".ts`", `".tsx`") -ExcludeDirs @(`"node_modules`", `"dist`")"
    Write-Host ""
    Write-InfoAlt "  Print the command instead of running it:"
    Write-Info "    .\dump_files.ps1 . -Recursive `$true -Extensions `".cs`" -ExcludeDirs @(`"obj`", `"bin`") -DebugCommand"
    exit 0
}

# Hard-coded toggle: when $true, prints metadata header at top of dump file
$IncludeMetadataHeader = $false
# ...or turn it on per run with -MetadataHeader
if ($MetadataHeader) { $IncludeMetadataHeader = $true }

# Validate input dir
if (-not (Test-Path -LiteralPath $InputDir -PathType Container)) {
    Write-Err "Input directory does not exist or is not a directory: $InputDir"
    exit 1
}

if ($ExcludeDirs.Count -gt 0 -and -not $Recursive) {
    Write-Warn "Note: -ExcludeDirs only has an effect when -Recursive is `$true."
}

# Resolve paths (nice for consistent output)
$resolvedInputDir = (Resolve-Path -LiteralPath $InputDir).Path

# Ensure output directory exists
$outputParent = Split-Path -Parent $OutputFile
if ([string]::IsNullOrWhiteSpace($outputParent)) {
    $outputParent = (Get-Location).Path
    $OutputFile = Join-Path $outputParent $OutputFile
}
elseif (-not (Test-Path -LiteralPath $outputParent)) {
    New-Item -ItemType Directory -Path $outputParent -Force | Out-Null
}

# Normalise extensions to lowercase with leading dot (done up front so -DebugCommand can print them)
$normalizedExts = @()
if ($Extensions.Count -gt 0) {
    $normalizedExts = @($Extensions | ForEach-Object { if ($_ -notmatch '^\.' ) { ".$_" } else { $_ } } | ForEach-Object { $_.ToLower() })
}

# Regex matching any excluded dir name as a whole path segment below the input dir, e.g. "/bin/" or "\obj\"
$excludeDirsRegex = $null
if ($ExcludeDirs.Count -gt 0) {
    $excludeDirsRegex = '[\\/](' + (($ExcludeDirs | ForEach-Object { [regex]::Escape($_) }) -join '|') + ')[\\/]'
}

# Debug: print the command(s) instead of running anything
if ($DebugCommand) {
    Write-InfoAlt "[debug] Resolved options:"
    Write-Info "  InputDir:        $resolvedInputDir"
    Write-Info "  OutputFile:      $OutputFile"
    Write-Info "  Recursive:       $Recursive"
    Write-Info "  UseFullPaths:    $UseFullPaths"
    Write-Info "  Extensions:      $(if ($normalizedExts.Count -gt 0) { $normalizedExts -join ' ' } else { '<all>' })"
    Write-Info "  ExcludeDirs:     $(if ($ExcludeDirs.Count -gt 0) { $ExcludeDirs -join ' ' } else { '<none>' })"
    Write-Info "  IncludePatterns: $(if ($IncludePatterns.Count -gt 0) { $IncludePatterns -join ' ' } else { '<none>' })"
    Write-Info "  ExcludePatterns: $(if ($ExcludePatterns.Count -gt 0) { $ExcludePatterns -join ' ' } else { '<none>' })"
    Write-Info "  MetadataHeader:  $IncludeMetadataHeader"
    Write-Host ""

    # The file collection pipeline, printed so it can be pasted straight into a terminal
    $collectionParts = @("Get-ChildItem -LiteralPath '$resolvedInputDir' -File" + $(if ($Recursive) { " -Recurse" } else { "" }))
    if ($excludeDirsRegex) {
        $collectionParts += "Where-Object { ('/' + `$_.FullName.Substring($($resolvedInputDir.Length)).TrimStart('\','/')) -notmatch '$excludeDirsRegex' }"
    }
    if ($normalizedExts.Count -gt 0) {
        $extList = ($normalizedExts | ForEach-Object { "'$_'" }) -join ','
        $collectionParts += "Where-Object { @($extList) -contains `$_.Extension.ToLower() }"
    }
    if ($IncludePatterns.Count -gt 0) {
        $incClause = ($IncludePatterns | ForEach-Object { "`$_.Name -like '$_'" }) -join ' -or '
        $collectionParts += "Where-Object { $incClause }"
    }
    if ($ExcludePatterns.Count -gt 0) {
        $excClause = ($ExcludePatterns | ForEach-Object { "`$_.Name -notlike '$_'" }) -join ' -and '
        $collectionParts += "Where-Object { $excClause }"
    }
    $collectionParts += "Sort-Object FullName"
    Write-InfoAlt "[debug] File collection command (lists the files that would be dumped):"
    Write-Dim ("  " + ($collectionParts -join ' | '))
    Write-Host ""

    # The same run, expressed as a single self-contained invocation of this script
    $scriptPath = $PSCommandPath
    if ([string]::IsNullOrWhiteSpace($scriptPath)) { $scriptPath = '.\dump_files.ps1' }
    $invocationCommand = "& '$scriptPath' '$resolvedInputDir' '$OutputFile' " +
        $(if ($Recursive) { '$true' } else { '$false' }) + " " +
        $(if ($UseFullPaths) { '$true' } else { '$false' })
    if ($Extensions.Count -gt 0)      { $invocationCommand += " -Extensions @("      + (($Extensions      | ForEach-Object { "'$_'" }) -join ',') + ")" }
    if ($ExcludeDirs.Count -gt 0)     { $invocationCommand += " -ExcludeDirs @("     + (($ExcludeDirs     | ForEach-Object { "'$_'" }) -join ',') + ")" }
    if ($IncludePatterns.Count -gt 0) { $invocationCommand += " -IncludePatterns @(" + (($IncludePatterns | ForEach-Object { "'$_'" }) -join ',') + ")" }
    if ($ExcludePatterns.Count -gt 0) { $invocationCommand += " -ExcludePatterns @(" + (($ExcludePatterns | ForEach-Object { "'$_'" }) -join ',') + ")" }
    if ($IncludeMetadataHeader)       { $invocationCommand += " -MetadataHeader" }
    Write-InfoAlt "[debug] Equivalent invocation (writes the dump):"
    Write-Dim "  $invocationCommand"
    exit 0
}

# Collect files
if ($Recursive) {
    $files = @(Get-ChildItem -LiteralPath $resolvedInputDir -File -Recurse | Sort-Object FullName)
}
else {
    $files = @(Get-ChildItem -LiteralPath $resolvedInputDir -File | Sort-Object Name)
}

# Skip anything living under one of the excluded dir names
if ($excludeDirsRegex) {
    $files = @($files | Where-Object {
        ('/' + $_.FullName.Substring($resolvedInputDir.Length).TrimStart('\', '/')) -notmatch $excludeDirsRegex
    })
}

# Filter by extension if specified (normalise to lowercase with leading dot)
if ($normalizedExts.Count -gt 0) {
    $files = @($files | Where-Object { $normalizedExts -contains $_.Extension.ToLower() })
}

# Keep only files whose name matches one of the include patterns
if ($IncludePatterns.Count -gt 0) {
    $files = @($files | Where-Object { $name = $_.Name; @($IncludePatterns | Where-Object { $name -like $_ }).Count -gt 0 })
}

# Skip files whose name matches any of the exclude patterns
if ($ExcludePatterns.Count -gt 0) {
    $files = @($files | Where-Object { $name = $_.Name; @($ExcludePatterns | Where-Object { $name -like $_ }).Count -eq 0 })
}

# Build output
# Using StringBuilder is faster/cleaner than repeated string concatenation
$sb = New-Object System.Text.StringBuilder

# Optional metadata header
if ($IncludeMetadataHeader) {
    [void]$sb.AppendLine("Dump generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
    [void]$sb.AppendLine("InputDir: $resolvedInputDir")
    [void]$sb.AppendLine("Recursive: $Recursive")
    [void]$sb.AppendLine("UseFullPaths: $UseFullPaths")
    [void]$sb.AppendLine("ExcludeDirs: $(if ($ExcludeDirs.Count -gt 0) { $ExcludeDirs -join ' ' } else { '<none>' })")
    [void]$sb.AppendLine("IncludePatterns: $(if ($IncludePatterns.Count -gt 0) { $IncludePatterns -join ' ' } else { '<none>' })")
    [void]$sb.AppendLine("ExcludePatterns: $(if ($ExcludePatterns.Count -gt 0) { $ExcludePatterns -join ' ' } else { '<none>' })")
    [void]$sb.AppendLine(("=" * 80))
    [void]$sb.AppendLine()
}

foreach ($file in $files) {
    if ($UseFullPaths) {
        $headerName = $file.FullName
    }
    else {
        if ($Recursive) {
            # Relative path from input dir (keeps nested folder structure in dump headers)
            $relativePath = $file.FullName.Substring($resolvedInputDir.Length).TrimStart('\','/')
            $headerName = $relativePath
        }
        else {
            # Non-recursive: just file name + extension
            $headerName = $file.Name
        }
    }

    [void]$sb.AppendLine("$($headerName):")
    [void]$sb.AppendLine()

    try {
        # Read raw so formatting/newlines are preserved as much as possible
        $content = Get-Content -LiteralPath $file.FullName -Raw -ErrorAction Stop

        if ($null -ne $content) {
            [void]$sb.Append($content)
        }
    }
    catch {
        [void]$sb.AppendLine("[ERROR reading file: $($_.Exception.Message)]")
    }

    # Ensure separation between files
    [void]$sb.AppendLine()
    [void]$sb.AppendLine()
    [void]$sb.AppendLine(("-" * 80))
    [void]$sb.AppendLine()
}

# Write output (UTF-8)
$sb.ToString() | Set-Content -LiteralPath $OutputFile -Encoding utf8

if ($files.Count -eq 0) {
    Write-Warn "No files matched the given filters. Wrote empty dump to: $OutputFile"
}
else {
    Write-Ok "Dumped $($files.Count) file(s) to: $OutputFile"
}
