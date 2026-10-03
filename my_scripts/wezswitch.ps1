# Pick which wezterm variant the pinned WezTerm taskbar icon starts - the
# Windows side of dotfiles/bin/wezswitch on Linux.
#
#   system   C:\Program Files\WezTerm\wezterm-gui.exe (the installed wezterm)
#   fork     the wezterm fork, $env:code_root_dir\Code2\Rust\wezterm\target\release
#            (build it with: wez --build --no-run)
#   wecterm  the C port, $env:code_root_dir\Code2\C\WecTerm\build-rel\bin\Release
#            (build it with: wec --build --no-run)
#
# The taskbar pin is a shortcut (WezTerm.lnk under
# %APPDATA%\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar);
# switching rewrites its target, so the pin itself is the stored choice. The
# shortcut keeps its AppUserModelID (org.wezfurlong.wezterm), which all three
# variants set on their windows, so whichever one runs groups under the pin.
# Its icon stays the installed wezterm's.
#
# The switch applies to the next click; windows that are already open keep
# running what they were started with. The three can run side by side: a new
# window is only handed to an already running instance of the same executable.
#
# Usage examples:
# show the current variant and which ones are built:
# wezswitch
# wezswitch status
#
# switch:
# wezswitch wecterm
# wezswitch fork
# wezswitch system
#
# switch to a variant that is not built yet:
# wezswitch fork -Force
#
# print what would change instead of changing it:
# wezswitch wecterm -ShowCmd
#
# one line per variant for scripts:
# "<variant> <TAB> <current 0|1> <TAB> <built 0|1> <TAB> <exe> <TAB> <build hint>"
# wezswitch -Porcelain
#
# help:
# wezswitch help
# wezswitch -h

param(
    [Parameter(Position = 0)]
    [string]$Command = 'status',
    [Alias('f')]
    [switch]$Force,
    [switch]$ShowCmd,
    [switch]$Porcelain,
    [Alias('h')]
    [switch]$Help
)

function Write-Ok([string]$Message) { Write-Host $Message -ForegroundColor Green }
function Write-Err([string]$Message) { Write-Host $Message -ForegroundColor Red }
function Write-Warn([string]$Message) { Write-Host $Message -ForegroundColor Yellow }
function Write-Info([string]$Message) { Write-Host $Message -ForegroundColor Cyan }
function Write-InfoAlt([string]$Message) { Write-Host $Message -ForegroundColor Magenta }
function Write-Dim([string]$Message) { Write-Host $Message -ForegroundColor DarkGray }

$Root = if ($env:code_root_dir) { $env:code_root_dir } else { $env:USERPROFILE }
$SystemExe = Join-Path $env:ProgramFiles 'WezTerm\wezterm-gui.exe'
$PinPath = Join-Path $env:APPDATA 'Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\WezTerm.lnk'
$Variants = @('system', 'fork', 'wecterm')

function Get-ExeFor([string]$Variant) {
    switch ($Variant) {
        'system' { return $SystemExe }
        'fork' { return (Join-Path $Root 'Code2\Rust\wezterm\target\release\wezterm-gui.exe') }
        'wecterm' {
            # run-custom-wecterm.ps1 builds build-rel (bin\Release with Visual
            # Studio generators, bin with Ninja/NMake); a plain
            # `cmake --build build --config Release` lands in build\bin\Release
            $candidates = @(
                (Join-Path $Root 'Code2\C\WecTerm\build-rel\bin\Release\wecterm-gui.exe'),
                (Join-Path $Root 'Code2\C\WecTerm\build-rel\bin\wecterm-gui.exe'),
                (Join-Path $Root 'Code2\C\WecTerm\build\bin\Release\wecterm-gui.exe')
            )
            foreach ($candidate in $candidates) {
                if (Test-Path $candidate) { return $candidate }
            }
            return $candidates[0]
        }
    }
    return $null
}

function Get-BuildHint([string]$Variant) {
    switch ($Variant) {
        'fork' { return 'wez --build --no-run' }
        'wecterm' { return 'wec --build --no-run' }
        default { return 'install wezterm from https://wezterm.org' }
    }
}

function Get-PinTarget {
    if (-not (Test-Path $PinPath)) { return $null }
    $shell = New-Object -ComObject WScript.Shell
    return $shell.CreateShortcut($PinPath).TargetPath
}

function Get-CurrentVariant {
    $target = Get-PinTarget
    if (-not $target) { return $null }
    foreach ($variant in $Variants) {
        if ([string]::Equals($target, (Get-ExeFor $variant), [StringComparison]::OrdinalIgnoreCase)) {
            return $variant
        }
    }
    # another wecterm build dir than the one Get-ExeFor picked
    if ((Split-Path $target -Leaf) -ieq 'wecterm-gui.exe') { return 'wecterm' }
    return 'unknown'
}

function Show-Usage {
    Write-InfoAlt "wezswitch - pick which wezterm variant the pinned WezTerm taskbar icon starts"
    Write-Host ""
    Write-Info "Usage:"
    Write-Host "  wezswitch [status]"
    Write-Host "  wezswitch <system|fork|wecterm> [-Force] [-ShowCmd]"
    Write-Host ""
    Write-Info "Variants:"
    Write-Host "  system    $SystemExe"
    Write-Host "  fork      `$env:code_root_dir\Code2\Rust\wezterm\target\release\wezterm-gui.exe"
    Write-Host "  wecterm   `$env:code_root_dir\Code2\C\WecTerm\build-rel\bin\Release\wecterm-gui.exe"
    Write-Host "            (or build-rel\bin, or build\bin\Release, whichever exists)"
    Write-Host ""
    Write-Info "Options:"
    Write-Host "  -Force       switch even if the variant is not built"
    Write-Host "  -ShowCmd     print what would change instead of changing it"
    Write-Host "  -Porcelain   one tab-separated line per variant, for scripts"
    Write-Host "  -h, help     show this help"
    Write-Host ""
    Write-Warn "Notes:"
    Write-Warn "  The switch applies to the next click on the pin; open windows keep their variant."
    Write-Warn "  The pin is $PinPath"
}

function Show-Status {
    $current = Get-CurrentVariant
    if (-not $current) {
        Write-Err "No WezTerm pin on the taskbar: $PinPath"
        Write-Warn "Pin the installed WezTerm to the taskbar once, then run wezswitch again."
        return
    }
    Write-InfoAlt "The taskbar pin runs: $current"
    Write-Dim "  ($(Get-PinTarget))"
    Write-Host ""
    foreach ($variant in $Variants) {
        $exe = Get-ExeFor $variant
        $mark = if ($variant -eq $current) { '* ' } else { '  ' }
        if (Test-Path $exe) {
            Write-Host ("{0}{1,-8} {2}" -f $mark, $variant, $exe) -ForegroundColor Green
        } else {
            Write-Host ("{0}{1,-8} {2} " -f $mark, $variant, $exe) -ForegroundColor Yellow -NoNewline
            Write-Host "(not built: $(Get-BuildHint $variant))" -ForegroundColor DarkGray
        }
    }
}

function Show-Porcelain {
    $current = Get-CurrentVariant
    foreach ($variant in $Variants) {
        $exe = Get-ExeFor $variant
        $isCurrent = if ($variant -eq $current) { 1 } else { 0 }
        $isBuilt = if (Test-Path $exe) { 1 } else { 0 }
        Write-Output ("{0}`t{1}`t{2}`t{3}`t{4}" -f $variant, $isCurrent, $isBuilt, $exe, (Get-BuildHint $variant))
    }
}

if ($Help -or @('help', '-help', '--help', '/h', '/help', '/?', '-?') -contains $Command.ToLower()) {
    Show-Usage
    exit 0
}
if ($Porcelain -or $Command -ieq '--porcelain') {
    Show-Porcelain
    exit 0
}

$target = $Command.ToLower()
if ($target -eq 'status' -or $target -eq '') {
    Show-Status
    exit 0
}
if ($Variants -notcontains $target) {
    Write-Err "Unknown argument: $Command"
    Show-Usage
    exit 1
}

if (-not (Test-Path $PinPath)) {
    Write-Err "No WezTerm pin on the taskbar: $PinPath"
    Write-Warn "Pin the installed WezTerm to the taskbar once, then run wezswitch again."
    exit 1
}

$exe = Get-ExeFor $target
if (-not (Test-Path $exe) -and -not $Force) {
    Write-Err "$target is not built: $exe"
    Write-Warn "Build it with: $(Get-BuildHint $target)   (or pass -Force to switch anyway)"
    exit 1
}

$exeDir = Split-Path $exe -Parent
# keep the installed wezterm's icon so the pin looks the same whatever it runs
$icon = if (Test-Path $SystemExe) { "$SystemExe,0" } else { "$exe,0" }

if ($ShowCmd) {
    Write-InfoAlt "# equivalent of: wezswitch $target"
    Write-Host ('$link = (New-Object -ComObject WScript.Shell).CreateShortcut(''{0}'')' -f $PinPath)
    Write-Host ('$link.TargetPath = ''{0}''' -f $exe)
    Write-Host ('$link.WorkingDirectory = ''{0}''' -f $exeDir)
    Write-Host ('$link.IconLocation = ''{0}''' -f $icon)
    Write-Host '$link.Save()'
    exit 0
}

$previous = Get-CurrentVariant
try {
    # Saving through WScript.Shell keeps the shortcut's other properties,
    # including System.AppUserModel.ID
    $link = (New-Object -ComObject WScript.Shell).CreateShortcut($PinPath)
    $link.TargetPath = $exe
    $link.WorkingDirectory = $exeDir
    $link.IconLocation = $icon
    $link.Save()
} catch {
    Write-Err "Could not update $PinPath : $($_.Exception.Message)"
    exit 1
}

if ($previous -eq $target) {
    Write-Ok "The taskbar pin already runs $target"
} else {
    Write-Ok "The taskbar pin now runs $target (was $previous)"
}
if (-not (Test-Path $exe)) {
    Write-Warn "Not built yet, clicking the pin fails until it is: $(Get-BuildHint $target)"
}
Write-Dim "Applies to the next click; open windows keep their variant."
