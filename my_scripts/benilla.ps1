# Usage examples (nothing runs without `run` as the first arg; the args after it in any order,
# case insensitive; `.benilla help` lists them all):
# cd into the repo and print how to run it, through this script and by hand (runs nothing):
# .benilla
#
# the release build (target/release) on the platform's window (win32 / x11) and the gfx
# library's default device:
# .benilla run
#
# pick the gfx device and / or window:
# .benilla run d3d12 win32
# .benilla run vk sdl
#
# the play profile (release + incremental), rebuilt first, with the debug panel open:
# .benilla run play build panel
#
# log in as the checkout's .probe-identity, on another server and realm:
# .benilla run probe host=192.168.1.10 realm=Elysium
#
# a server-less capture, and the list of capture scenarios:
# .benilla run capture=water-noon vk
# .benilla run capture=list
#
# the engine viewer over Goldshire:
# .benilla run at=-9460,62
#
# windowed for this run, at the client's default 1600x900 or a size of your own:
# .benilla run win
# .benilla run size=1280x720
#
# any other env var (an upper-case name with an underscore) as it is:
# .benilla run WOW_MSAA=4 WOW_FARCLIP=800
#
# print the PowerShell lines for this run instead of running it:
# .benilla run vk debug print

function Write-Label($text) { Write-Host "$text" -ForegroundColor DarkGray }
function Write-Alt  ($text) { Write-Host "$text" -ForegroundColor Magenta  }
function Write-Extra($text) { Write-Host "$text" -ForegroundColor Blue     }
function Write-Warn ($text) { Write-Host "$text" -ForegroundColor DarkYellow }
function Write-Ok   ($text) { Write-Host "$text" -ForegroundColor Green    }
function Write-Err  ($text) { Write-Host "$text" -ForegroundColor Red      }

$REPO_ROOT = Join-Path -Path $env:code_root_dir -ChildPath "Code2/Wow/tools/benilla"
$BUILD_TIME_FORMAT = "yyyy-MM-dd HH:mm:ss"

# The cargo profiles (RUNNING.md), picked by name. The player build has no `dev` feature, so it
# gets its own target dir instead of replacing target/release's client. The names shared with
# cenilla.ps1 mean the same there: release / rel the default optimized build, debug, player, and
# ship the fastest one.
$DEFAULT_PROFILE = "release"
$PROFILE_NAMES = @("release", "debug", "play", "ship", "player")
$PROFILE_DIRS = @{ "release" = "target/release"; "debug" = "target/debug"; "play" = "target/play"; "ship" = "target/ship"; "player" = "target/player/release" }
$PROFILE_ALIASES = @{ "rel" = "release"; "dev" = "debug"; "lto" = "ship" }
$PROFILE_INFO = @{
	"release" = "optimized: the measured build (also: rel)"
	"debug"   = "dev profile: the frozen reference cenilla is compared against (also: dev)"
	"play"    = "release + incremental compilation: the edit-and-run loop"
	"ship"    = "fat LTO, one codegen unit: the shipped binary (also: lto)"
	"player"  = "release without the dev feature: no dev tools"
}
$PROFILE_BUILD_ARGS = @{
	"release" = @("--release")
	"debug"   = @()
	"play"    = @("--profile", "play")
	"ship"    = @("--profile", "ship")
	"player"  = @("--release", "--no-default-features", "--target-dir", "target/player")
}
$BUILD_COMMAND = "cargo"
$CLIENT_EXE_NAME = "benilla.exe"
$WORLDVIEW_EXE_NAME = "benilla-worldview.exe"

# The gfx library (crates/benilla-gfx/build.rs): $env:GFX_DIR, else gfx_benilla when it exists,
# else gfx; GFX_CONFIGURATION, else Release when built, else Debug. The build copies it (and
# SDL2.dll) beside the client (a cargo build after the library changed copies it again).
$GFX_DLL_ROOT = Join-Path -Path $env:code_root_dir -ChildPath "Code2/General/gfx/gfx_dll"
$GFX_DIR_NAMES = @("gfx_benilla", "gfx")
$GFX_CONFIGURATIONS = @("Release", "Debug")
$GFX_LIB_NAME = "gfx.dll"

# The install's Data dir, always passed as WOW_DATA: data= (or a WOW_DATA= arg), else
# $env:WOW_DATA, else $env:wow_classic_dir/Data; the run stops when it does not exist (an empty
# WOW_DATA is "no install", as the client reads it)
$WOW_DATA_VAR = "WOW_DATA"
$WOW_DATA_SUBDIR = "Data"
# A scripted login only as this account (WOW_USER=, WOW_PASS=, WOW_CHAR=, one per line)
$PROBE_IDENTITY_NAME = ".probe-identity"
$PROBE_FIELDS = @("WOW_USER", "WOW_PASS", "WOW_CHAR")
$SECRET_VARS = @("WOW_PASS")
$SECRET_MASK = "***"
# The printed line setting the probe's fields from its file ({PATH}, {KEYS} filled in)
$PROBE_LINE_TEMPLATE = 'Get-Content {PATH} | ForEach-Object { $k, $v = $_ -split ''='', 2; if ($k.Trim() -in @({KEYS})) { Set-Item "Env:$($k.Trim())" $v.Trim().Trim(''"'') } }'
# A capture writes into the repo; target/ is gitignored there (captures hold Blizzard imagery)
$CAPTURE_OUT_SUBDIR = "target/visual"
$CAPTURE_LIST = "list"
$VALIDATE_ENV = @{ "VK_INSTANCE_LAYERS" = "VK_LAYER_KHRONOS_validation" }

# Launch options (Show-Help)
$SCRIPT_INVOCATION = $MyInvocation.InvocationName
$RUN_COMMAND = "run"
$HELP_TOKENS = @("help", "h")
$PRINT_TOKENS = @("print", "onlyprint", "showcmd")
$GFX_DEVICES = @("gl4", "gl3", "gles3", "vk", "d3d11", "d3d12")
# A d3d device opens only in a win32 window; with any other the window is never created
$D3D_DEVICES = @("d3d11", "d3d12")
$D3D_WINDOW = "win32"
$GFX_DEVICE_ALIASES = @{ "vulkan" = "vk"; "dx11" = "d3d11"; "dx12" = "d3d12" }
$GFX_WINDOWS = @("win32", "sdl", "glfw", "x11")
# The window when none is named as an arg (a window option or a WOW_GFX_WINDOW= arg), even over
# a WOW_GFX_WINDOW left in the environment: the platform's own, win32 on
# Windows and x11 on Linux (PowerShell 7's $IsLinux); elsewhere the library's first.
$DEFAULT_GFX_WINDOW = $(if ($env:OS -eq "Windows_NT") { "win32" } elseif ($IsLinux) { "x11" } else { $null })
$OPTION_VALUE_SEPARATOR = "="
$ENV_ARG_PATTERN = '^[A-Z][A-Z0-9]*_[A-Z0-9_]*='
# win / size=: WOW_WIN=<W>x<H> runs the client windowed at that size for this run only (never
# saved; the in-game Windowed Mode, gxWindow 1, is what persists); win alone takes the client's
# default windowed size (DEFAULT_WINDOWED, gxResolution's default)
$WINDOWED_DEFAULT_SIZE = "1600x900"
$WINDOW_SIZE_PATTERN = '^[0-9]+x[0-9]+$'

function Show-Help {
	Write-Alt "benilla - start benilla from a cargo profile under $REPO_ROOT (built when missing)"
	Write-Host @"

Usage: $SCRIPT_INVOCATION $RUN_COMMAND [options] [VAR_NAME=value...]
Nothing runs without $RUN_COMMAND as the first arg; a bare $SCRIPT_INVOCATION cds into the repo and prints how to run it.
Options are case insensitive, in any order, with or without leading dashes.

Profile (default $DEFAULT_PROFILE):
"@
	foreach ($name in $PROFILE_NAMES) {
		Write-Host ("  {0,-8} {1,-22} {2}" -f $name, "$($PROFILE_DIRS[$name])/", $PROFILE_INFO[$name])
	}
	Write-Host @"
  build                  cargo build first (copies a newer gfx library beside the client too)

gfx backends (WOW_GFX_DEVICE / WOW_GFX_WINDOW; the device unset is the library's first, the
window $(if ($DEFAULT_GFX_WINDOW) { $DEFAULT_GFX_WINDOW } else { "the library's first" }) unless named as an arg, even over a WOW_GFX_WINDOW in the environment):
  $($GFX_DEVICES -join ' | ')   (vulkan = vk, dx11 / dx12 = d3d11 / d3d12)
  $($GFX_WINDOWS -join ' | ')
  x11 is Linux only, d3d11 / d3d12 need win32; a name the library lacks stops the boot, listing its names.

Window (this run only; the in-game Windowed Mode / gxWindow 1 is what is saved):
  win                    windowed at $WINDOWED_DEFAULT_SIZE (WOW_WIN; also: windowed)
  size=<W>x<H>           windowed at that size (WOW_WIN=<W>x<H>)

Dev tools:
  panel                  the debug panel open at boot (WOW_PANEL=1)
  hud                    the perf HUD at boot (WOW_PERF_HUD=1)
  worldview              the engine viewer ($WORLDVIEW_EXE_NAME) instead of the client
  at=<x>,<y>[,<z>]       the engine viewer at raw WoW coordinates (WOW_WORLDVIEW_AT)

Server / login:
  host=<host[:port]>     the server (WOW_HOST, default localhost:3724)
  realm=<name>           the realm (WOW_REALM)
  char=<name>            the character (WOW_CHAR)
  probe                  log in as the checkout's $PROBE_IDENTITY_NAME (WOW_USER / WOW_PASS / WOW_CHAR)
  nosound                WOW_NOSOUND=1
  unattended             WOW_UNATTENDED=1 (reconnect, exit non-zero on a failed login)

Testing:
  capture=<scenario>     a server-less capture (WOW_CAPTURE); capture=$CAPTURE_LIST lists the scenarios
  out=<png>              where the capture goes (default $CAPTURE_OUT_SUBDIR/<scenario>.png)
  fps=<frames>           the live frame-time probe: samples that many frames, reports, exits
  exit=<seconds>         exit after that many seconds (WOW_PROBE_EXIT_AT)
  soft                   off the GPU (llvmpipe / lavapipe) - Linux only, ignored here
  validate               the Vulkan validation layer (needs the Vulkan SDK)

Other:
  data=<dir>             the WoW install's Data dir (WOW_DATA; default `$env:wow_classic_dir/Data, or `$env:WOW_DATA when set)
  VAR_NAME=value         any env var with an upper-case name holding an underscore, as it is
  $($PRINT_TOKENS -join ' | ')  print the PowerShell lines for this run instead of running it
  $($HELP_TOKENS -join ' | ') (also -help, --help)  this help

The gfx library must be built first: $GFX_DLL_ROOT/$($GFX_DIR_NAMES[0])/bin/<Release|Debug>_x64/$GFX_LIB_NAME.
Windows is written but not built in benilla yet (GFX.md).

Examples:
  $SCRIPT_INVOCATION $RUN_COMMAND d3d12 win32 panel
  $SCRIPT_INVOCATION $RUN_COMMAND play build probe
  $SCRIPT_INVOCATION $RUN_COMMAND capture=felwood-night gl4
  $SCRIPT_INVOCATION $RUN_COMMAND worldview at=-9460,62 vk

"@
	Show-ManualRun
}

function Show-ManualRun {
	# Prints how to start the default profile's client by hand, without this script
	$package = [System.IO.Path]::GetFileNameWithoutExtension($CLIENT_EXE_NAME)
	Write-Label "Or run it manually (from $REPO_ROOT):"
	Write-Extra "`$env:$WOW_DATA_VAR=`"`$env:wow_classic_dir/$WOW_DATA_SUBDIR`"; $BUILD_COMMAND run $($PROFILE_BUILD_ARGS[$DEFAULT_PROFILE] -join ' ') -p $package"
}

function Show-Usage {
	# A bare call: how to run benilla from the repo, through this script and by hand
	Write-Alt "benilla - $REPO_ROOT"
	Write-Label "Run it through this script (the options after $RUN_COMMAND; '$SCRIPT_INVOCATION help' lists them):"
	Write-Extra "$SCRIPT_INVOCATION $RUN_COMMAND"
	Show-ManualRun
}

function Read-Command($arg) {
	# Returns on run; help shows the help, anything else the usage, and exits
	$name = ([string]$arg).TrimStart("-").ToLowerInvariant()
	if ($name -eq $RUN_COMMAND) { return }
	if ($HELP_TOKENS -contains $name) {
		Show-Help
		exit 0
	}
	Write-Err "Nothing runs without $RUN_COMMAND as the first arg (got: $arg)."
	Show-Usage
	exit 1
}

function Read-Options($argList) {
	# The launch options from the script args; exits on an unknown one
	$opts = @{
		Help = $false; PrintOnly = $false; Profile = $DEFAULT_PROFILE; Build = $false
		Device = $null; Window = $null; Win = $false; Size = $null; Panel = $false; Hud = $false; Worldview = $false; At = $null
		Host = $null; Realm = $null; Char = $null; Probe = $false; NoSound = $false; Unattended = $false
		Capture = $null; Out = $null; Fps = $null; Exit = $null; Soft = $false; Validate = $false
		Data = $null; DataSet = $false; Env = @()
	}

	foreach ($item in $argList) {
		$raw = [string]$item
		if ($raw.StartsWith("$WOW_DATA_VAR$OPTION_VALUE_SEPARATOR")) {
			$opts.Data = $raw.Substring($WOW_DATA_VAR.Length + $OPTION_VALUE_SEPARATOR.Length)
			$opts.DataSet = $true
			continue
		}
		if ($raw -cmatch $ENV_ARG_PATTERN) {
			$opts.Env += $raw
			continue
		}

		$name, $value = $raw.TrimStart("-") -split $OPTION_VALUE_SEPARATOR, 2
		$name = $name.ToLowerInvariant()
		if ($GFX_DEVICE_ALIASES.ContainsKey($name)) { $name = $GFX_DEVICE_ALIASES[$name] }
		if ($PROFILE_ALIASES.ContainsKey($name)) { $name = $PROFILE_ALIASES[$name] }

		if ($HELP_TOKENS -contains $name) { $opts.Help = $true }
		elseif ($PRINT_TOKENS -contains $name) { $opts.PrintOnly = $true }
		elseif ($GFX_DEVICES -contains $name) { $opts.Device = $name }
		elseif ($GFX_WINDOWS -contains $name) { $opts.Window = $name }
		elseif ($PROFILE_NAMES -contains $name) { $opts.Profile = $name }
		elseif ($name -eq "build") { $opts.Build = $true }
		elseif ($name -eq "panel") { $opts.Panel = $true }
		elseif ($name -eq "win" -or $name -eq "windowed") { $opts.Win = $true }
		elseif ($name -eq "size" -and $value) { $opts.Size = $value.ToLowerInvariant() }
		elseif ($name -eq "hud") { $opts.Hud = $true }
		elseif ($name -eq "worldview") { $opts.Worldview = $true }
		elseif ($name -eq "at" -and $value) { $opts.At = $value; $opts.Worldview = $true }
		elseif ($name -eq "host" -and $value) { $opts.Host = $value }
		elseif ($name -eq "realm" -and $value) { $opts.Realm = $value }
		elseif ($name -eq "char" -and $value) { $opts.Char = $value }
		elseif ($name -eq "probe") { $opts.Probe = $true }
		elseif ($name -eq "nosound") { $opts.NoSound = $true }
		elseif ($name -eq "unattended") { $opts.Unattended = $true }
		elseif ($name -eq "capture" -and $value) { $opts.Capture = $value }
		elseif ($name -eq "out" -and $value) { $opts.Out = $value }
		elseif ($name -eq "fps" -and $value) { $opts.Fps = $value }
		elseif ($name -eq "exit" -and $value) { $opts.Exit = $value }
		elseif ($name -eq "soft") { $opts.Soft = $true }
		elseif ($name -eq "validate") { $opts.Validate = $true }
		elseif ($name -eq "data" -and $value) {
			$opts.Data = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($value)
			$opts.DataSet = $true
		}
		else {
			Write-Err "Unknown arg: $raw (size= / at= / host= / realm= / char= / capture= / out= / fps= / exit= need a value) - see '$SCRIPT_INVOCATION help'."
			exit 1
		}
	}

	if ($opts.Out -and -not $opts.Capture) { Write-Warn "out= is for a capture - ignoring it." }
	if ($opts.Size -and $opts.Size -notmatch $WINDOW_SIZE_PATTERN) {
		Write-Err "size= takes <W>x<H>, e.g. size=$WINDOWED_DEFAULT_SIZE (got: $($opts.Size))."
		exit 1
	}
	if ($opts.Worldview -and $opts.Capture) {
		Write-Warn "A capture runs in the client - ignoring worldview / at=."
		$opts.Worldview = $false; $opts.At = $null
	}
	if ($opts.Soft) {
		Write-Warn "soft (llvmpipe / lavapipe) is Linux only - ignoring it."
		$opts.Soft = $false
	}
	return $opts
}

function Resolve-Exe($opts) {
	# The cargo package of the binary and its exe path
	$exeName = $(if ($opts.Worldview) { $WORLDVIEW_EXE_NAME } else { $CLIENT_EXE_NAME })
	$profileDir = Join-Path -Path $REPO_ROOT -ChildPath $PROFILE_DIRS[$opts.Profile]
	return @{
		Package = [System.IO.Path]::GetFileNameWithoutExtension($exeName)
		ExePath = Join-Path -Path $profileDir -ChildPath $exeName
	}
}

function Resolve-GfxLibrary {
	# The gfx library the build links (see GFX_DLL_ROOT above)
	$gfxDir = $env:GFX_DIR
	if (-not $gfxDir) {
		foreach ($name in $GFX_DIR_NAMES) {
			$gfxDir = Join-Path -Path $GFX_DLL_ROOT -ChildPath $name
			if (Test-Path -Path $gfxDir -PathType Container) { break }
		}
	}

	$config = $env:GFX_CONFIGURATION
	if (-not $config) {
		foreach ($config in $GFX_CONFIGURATIONS) {
			if (Test-Path -Path (Join-Path -Path $gfxDir -ChildPath "bin/${config}_x64") -PathType Container) { break }
		}
	}

	return @{ Dir = $gfxDir; Lib = Join-Path -Path $gfxDir -ChildPath "bin/${config}_x64/$GFX_LIB_NAME" }
}

function Test-GfxLibrary($gfx) {
	# Exits when the gfx library is not built
	if (-not (Test-Path -Path $gfx.Lib -PathType Leaf)) {
		Write-Err "The gfx library is not built: $($gfx.Lib)"
		Write-Err "Build it first (or set GFX_DIR / GFX_CONFIGURATION):"
		Write-Extra "Push-Location $(Format-ShellArg $gfx.Dir); cmake -S . -B build -A x64; cmake --build build --config Release; Pop-Location"
		exit 1
	}
	Write-Ok "gfx library: $($gfx.Lib)"
	Write-Label "  built $((Get-Item -Path $gfx.Lib).LastWriteTime.ToString($BUILD_TIME_FORMAT))"
}

function Test-GfxCopy($gfx, $exePath) {
	# Exits when the client has no copy of the gfx library beside it; warns when it differs
	$copy = Join-Path -Path (Split-Path -Path $exePath -Parent) -ChildPath $GFX_LIB_NAME
	if (-not (Test-Path -Path $copy -PathType Leaf)) {
		Write-Err "No $GFX_LIB_NAME beside $exePath - run with 'build' (the build copies it there)."
		exit 1
	}
	if ((Get-FileHash -Path $gfx.Lib).Hash -eq (Get-FileHash -Path $copy).Hash) {
		Write-Label "  the copy beside the client is the same"
	} elseif ((Get-Item -Path $gfx.Lib).LastWriteTime -gt (Get-Item -Path $copy).LastWriteTime) {
		Write-Warn "The gfx library is newer than the copy beside the client - add 'build' to copy it again."
	} else {
		Write-Warn "The copy beside the client differs from $($gfx.Lib) (another GFX_DIR / configuration?)."
	}
}

function Get-BuildArgs($exe, $opts) {
	# cargo's args building the binary of the profile
	return @("build") + $PROFILE_BUILD_ARGS[$opts.Profile] + @("-p", $exe.Package)
}

function Build-Client($exe, $opts) {
	if (-not (Get-Command $BUILD_COMMAND -ErrorAction SilentlyContinue)) {
		Write-Err "$BUILD_COMMAND not found on PATH - install the Rust toolchain (rustup) first."
		exit 1
	}

	$buildArgs = Get-BuildArgs $exe $opts
	Write-Extra "Push-Location $(Format-ShellArg $REPO_ROOT); $BUILD_COMMAND $($buildArgs -join ' '); Pop-Location"
	Push-Location $REPO_ROOT
	try {
		& $BUILD_COMMAND @buildArgs
		$exitCode = $LASTEXITCODE
	} finally {
		Pop-Location
	}

	if ($exitCode -ne 0) {
		Write-Err "Build failed (exit code $exitCode)."
		exit 1
	}
	Write-Ok "Build done."
}

function Resolve-WowData($opts) {
	# data= / a WOW_DATA= arg, else $env:WOW_DATA, else $env:wow_classic_dir/Data; exits when that
	# dir does not exist
	if ($opts.DataSet) {
		$wowData = $opts.Data; $source = "the args"
	} elseif (Test-Path -Path "Env:$WOW_DATA_VAR") {
		$wowData = [Environment]::GetEnvironmentVariable($WOW_DATA_VAR); $source = "`$env:$WOW_DATA_VAR"
	} elseif ($env:wow_classic_dir) {
		$wowData = Join-Path -Path $env:wow_classic_dir -ChildPath $WOW_DATA_SUBDIR; $source = "`$env:wow_classic_dir"
	} else {
		Write-Warn "wow_classic_dir is not set - set it to the WoW install, or pass data=<WoW Data dir>."
		exit 1
	}

	if (-not $wowData) {
		Write-Label "WoW data: none ($WOW_DATA_VAR is empty, from $source)"
		return ""
	}
	if (-not (Test-Path -Path $wowData -PathType Container)) {
		Write-Warn "The WoW Data dir does not exist: $wowData (from $source) - pass data=<WoW Data dir>."
		exit 1
	}
	Write-Label "WoW data: $wowData (from $source)"
	return $wowData
}

function Read-ProbeIdentity {
	# The fields of .probe-identity (quotes stripped), as the smoke scripts read them
	$path = Join-Path -Path $REPO_ROOT -ChildPath $PROBE_IDENTITY_NAME
	if (-not (Test-Path -Path $path -PathType Leaf)) {
		Write-Err "probe needs $path ($($PROBE_FIELDS -join '=, ')=, one per line)."
		exit 1
	}
	$fields = [ordered]@{}
	foreach ($field in $PROBE_FIELDS) {
		$line = Select-String -Path $path -Pattern "^\s*$field=`"*([^`"]*)`"*\s*$" | Select-Object -First 1
		if (-not $line -or -not $line.Matches[0].Groups[1].Value) {
			Write-Err "$PROBE_IDENTITY_NAME has no $field."
			exit 1
		}
		$fields[$field] = $line.Matches[0].Groups[1].Value
	}
	return $fields
}

function Get-RunEnv($opts) {
	# The env vars of the options, in order (a later one wins); ProbeKeys marks the probe's
	$runEnv = [ordered]@{}
	$probeKeys = @()
	$runEnv[$WOW_DATA_VAR] = $opts.WowData
	if ($opts.Probe) {
		$fields = Read-ProbeIdentity
		foreach ($key in $fields.Keys) { $runEnv[$key] = $fields[$key] }
		$probeKeys = @($fields.Keys)
	}

	if ($opts.Device) { $runEnv["WOW_GFX_DEVICE"] = $opts.Device }
	if ($opts.Window) { $runEnv["WOW_GFX_WINDOW"] = $opts.Window }
	elseif ($DEFAULT_GFX_WINDOW) { $runEnv["WOW_GFX_WINDOW"] = $DEFAULT_GFX_WINDOW }
	if ($opts.Size) { $runEnv["WOW_WIN"] = $opts.Size }
	elseif ($opts.Win) { $runEnv["WOW_WIN"] = $WINDOWED_DEFAULT_SIZE }
	if ($opts.Panel) { $runEnv["WOW_PANEL"] = "1" }
	if ($opts.Hud) { $runEnv["WOW_PERF_HUD"] = "1" }
	if ($opts.At) { $runEnv["WOW_WORLDVIEW_AT"] = $opts.At }
	if ($opts.Host) { $runEnv["WOW_HOST"] = $opts.Host }
	if ($opts.Realm) { $runEnv["WOW_REALM"] = $opts.Realm }
	if ($opts.Char) { $runEnv.Remove("WOW_CHAR"); $runEnv["WOW_CHAR"] = $opts.Char; $probeKeys = @($probeKeys | Where-Object { $_ -ne "WOW_CHAR" }) }
	if ($opts.NoSound) { $runEnv["WOW_NOSOUND"] = "1" }
	if ($opts.Unattended) { $runEnv["WOW_UNATTENDED"] = "1" }
	$captureOut = $null
	if ($opts.Capture) {
		$runEnv["WOW_CAPTURE"] = $opts.Capture
		if ($opts.Capture -ne $CAPTURE_LIST) {
			$captureOut = $(if ($opts.Out) { $opts.Out } else { Join-Path -Path $REPO_ROOT -ChildPath "$CAPTURE_OUT_SUBDIR/$($opts.Capture).png" })
			$runEnv["WOW_CAPTURE_OUT"] = $captureOut
		}
	}
	if ($opts.Fps) { $runEnv["WOW_LIVE_FPS"] = $opts.Fps }
	if ($opts.Exit) { $runEnv["WOW_PROBE_EXIT_AT"] = $opts.Exit }
	if ($opts.Validate) { foreach ($key in $VALIDATE_ENV.Keys) { $runEnv[$key] = $VALIDATE_ENV[$key] } }
	foreach ($pair in $opts.Env) {
		$key, $value = $pair -split $OPTION_VALUE_SEPARATOR, 2
		$runEnv.Remove($key)
		$runEnv[$key] = $value
		$probeKeys = @($probeKeys | Where-Object { $_ -ne $key })
	}

	return @{ Vars = $runEnv; ProbeKeys = $probeKeys; CaptureOut = $captureOut }
}

function Format-ShellArg($arg) {
	# Single-quotes an arg PowerShell would split or expand
	if ($arg -match '^[\w.\-+:\\/=,]+$') { return $arg }
	return "'" + ($arg -replace "'", "''") + "'"
}

function Format-EnvLines($runEnv) {
	# The PowerShell lines setting the env vars; the probe's fields are read from its file and
	# secrets are masked, so the printed lines hold no password
	$lines = @()
	if ($runEnv.ProbeKeys.Count -gt 0) {
		$probePath = Format-ShellArg (Join-Path -Path $REPO_ROOT -ChildPath $PROBE_IDENTITY_NAME)
		$keys = "'" + ($runEnv.ProbeKeys -join "', '") + "'"
		$lines += $PROBE_LINE_TEMPLATE.Replace("{PATH}", $probePath).Replace("{KEYS}", $keys)
	}
	foreach ($key in $runEnv.Vars.Keys) {
		if ($runEnv.ProbeKeys -contains $key) { continue }
		$value = $(if ($SECRET_VARS -contains $key) { $SECRET_MASK } else { $runEnv.Vars[$key] })
		$lines += "`$env:$key = $(Format-ShellArg ([string]$value))"
	}
	return $lines
}

function Show-LaunchCommand($exe, $runEnv, $opts, $scriptArgs) {
	# Prints the PowerShell lines reproducing this run (the env vars stay set in that shell)
	$lines = @("# $SCRIPT_INVOCATION $(($scriptArgs | ForEach-Object { Format-ShellArg ([string]$_) }) -join ' ')")
	if ($opts.Build -or -not (Test-Path -Path $exe.ExePath -PathType Leaf)) {
		$lines += "Push-Location $(Format-ShellArg $REPO_ROOT); $BUILD_COMMAND $((Get-BuildArgs $exe $opts) -join ' '); Pop-Location"
	}
	$lines += Format-EnvLines $runEnv
	$lines += "Push-Location $(Format-ShellArg $REPO_ROOT); & $(Format-ShellArg $exe.ExePath); Pop-Location"

	Write-Host
	foreach ($line in $lines) { Write-Extra $line }
}

function Start-Client($exePath, $runEnv) {
	# Runs the client from the repo root in the foreground, with the env vars set for it only (the
	# dev build's state and the default capture paths are relative to the repo root)
	$saved = @{}
	foreach ($key in $runEnv.Vars.Keys) {
		$saved[$key] = [Environment]::GetEnvironmentVariable($key)
		[Environment]::SetEnvironmentVariable($key, [string]$runEnv.Vars[$key])
	}

	Push-Location $REPO_ROOT
	try {
		& $exePath
		$exitCode = $LASTEXITCODE
	} finally {
		Pop-Location
		foreach ($key in $saved.Keys) { [Environment]::SetEnvironmentVariable($key, $saved[$key]) }
	}

	$name = Split-Path -Path $exePath -Leaf
	if ($runEnv.CaptureOut -and (Test-Path -Path $runEnv.CaptureOut -PathType Leaf)) { Write-Ok "Capture: $($runEnv.CaptureOut)" }
	if ($exitCode -eq 0) {
		Write-Label "$name exited (exit code 0)."
		return
	}
	Write-Err ("$name exited with exit code {0} (0x{0:X8})." -f $exitCode)
	exit 1
}

if ($args.Count -eq 0) {
	# A bare call cds into the repo (a script's Set-Location stays in the calling shell) and shows
	# how to run it, running nothing
	if (-not (Test-Path -Path $REPO_ROOT -PathType Container)) {
		Write-Err "benilla repo not found: $REPO_ROOT"
		exit 1
	}
	Set-Location -Path $REPO_ROOT
	Show-Usage
	exit 0
}
Read-Command $args[0]
$runArgs = @($args | Select-Object -Skip 1)
$options = Read-Options $runArgs
if ($options.Help) {
	Show-Help
	exit 0
}

Write-Alt "benilla..."
if ($runArgs.Count -eq 0) { Show-ManualRun }

if (-not (Test-Path -Path $REPO_ROOT -PathType Container)) {
	Write-Err "benilla repo not found: $REPO_ROOT"
	exit 1
}

function Test-GfxPair($vars) {
	# Names a WOW_GFX_WINDOW / WOW_GFX_DEVICE the run takes from the environment (the launch line
	# lists only what this script sets) or a WOW_GFX_WINDOW there it overrides, and warns about a
	# d3d device in a window other than win32
	$window = $vars["WOW_GFX_WINDOW"]
	$device = $vars["WOW_GFX_DEVICE"]
	$hint = ""
	if ($window -and $env:WOW_GFX_WINDOW -and $env:WOW_GFX_WINDOW.ToLowerInvariant() -ne $window.ToLowerInvariant()) {
		Write-Label "WOW_GFX_WINDOW=$env:WOW_GFX_WINDOW in the environment is not used: the window is $window."
	}
	elseif (-not $window -and $env:WOW_GFX_WINDOW) {
		$window = $env:WOW_GFX_WINDOW
		$hint = ", or Remove-Item Env:WOW_GFX_WINDOW"
		Write-Label "WOW_GFX_WINDOW=$window (from the environment)"
	}
	if (-not $device -and $env:WOW_GFX_DEVICE) {
		$device = $env:WOW_GFX_DEVICE
		Write-Label "WOW_GFX_DEVICE=$device (from the environment)"
	}
	if ($device -and ($D3D_DEVICES -contains $device.ToLowerInvariant()) -and $window -and $window.ToLowerInvariant() -ne $D3D_WINDOW) {
		Write-Warn "$device opens only in a $D3D_WINDOW window, not ${window}: its window will not be created - name $D3D_WINDOW$hint."
	}
}

$exe = Resolve-Exe $options
$options.WowData = Resolve-WowData $options
$gfx = Resolve-GfxLibrary
$runEnv = Get-RunEnv $options
Test-GfxPair $runEnv.Vars

if ($options.PrintOnly) {
	Show-LaunchCommand $exe $runEnv $options $args
	exit 0
}

Test-GfxLibrary $gfx
if ($options.Build -or -not (Test-Path -Path $exe.ExePath -PathType Leaf)) {
	if (-not (Test-Path -Path $exe.ExePath -PathType Leaf)) { Write-Warn "No $($exe.ExePath) yet - building it." }
	Build-Client $exe $options
}
if (-not (Test-Path -Path $exe.ExePath -PathType Leaf)) {
	Write-Err "The build finished but $($exe.ExePath) is still missing."
	exit 1
}

$exeItem = Get-Item -Path $exe.ExePath
Write-Label "Using: $($exeItem.FullName)"
Write-Label "  built $($exeItem.LastWriteTime.ToString($BUILD_TIME_FORMAT))"
Test-GfxCopy $gfx $exeItem.FullName

Write-Host

foreach ($line in Format-EnvLines $runEnv) { Write-Extra $line }
Write-Extra "$($exeItem.FullName)"
Start-Client $exeItem.FullName $runEnv
