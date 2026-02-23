param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$InputDir,

    [Parameter(Mandatory = $false, Position = 1)]
    [string]$OutputFile = (Join-Path (Get-Location) "dumped_files.txt"),

    [Parameter(Mandatory = $false, Position = 2)]
    [bool]$Recursive = $false,

    [Parameter(Mandatory = $false, Position = 3)]
    [bool]$UseFullPaths = $false
)

# Example usage:
# Only required arg (non-recursive, file names only, output to dumped_files.txt in current dir)
# .\dump_files.ps1 $Env:code_root_dir/Code2/C++/space/cs/BlackholeGfxV2/shaders/gl
# Specify output file:
# .\dump_files.ps1 "$Env:code_root_dir/Code2/C++/space/cs/BlackholeGfxV2/shaders/gl" "C:/temp/shader_dump.txt"
# Recursive:
# .\dump_files.ps1 "$Env:code_root_dir/Code2/C++/space/cs/BlackholeGfxV2/shaders" "C:/temp/shader_dump.txt" $true
# Recursive + full paths in headers:
# .\dump_files.ps1 "$Env:code_root_dir/Code2/C++/space/cs/BlackholeGfxV2/shaders" "C:/temp/shader_dump.txt" $true $true

# Hard-coded toggle: when $true, prints metadata header at top of dump file
$IncludeMetadataHeader = $false

# Validate input dir
if (-not (Test-Path -LiteralPath $InputDir -PathType Container)) {
    Write-Error "Input directory does not exist or is not a directory: $InputDir"
    exit 1
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

# Collect files
if ($Recursive) {
    $files = Get-ChildItem -LiteralPath $resolvedInputDir -File -Recurse | Sort-Object FullName
}
else {
    $files = Get-ChildItem -LiteralPath $resolvedInputDir -File | Sort-Object Name
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
# PowerShell 7+: utf8 = UTF-8 without BOM. In Windows PowerShell, behavior differs slightly but this still works.
$sb.ToString() | Set-Content -LiteralPath $OutputFile -Encoding utf8

Write-Host "Dumped $($files.Count) file(s) to: $OutputFile"

