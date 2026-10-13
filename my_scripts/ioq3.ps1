# Usage examples (args in any order, case insensitive; `.ioq3 help` lists them all):
# start like before (the backends / renderer last used are remembered in q3config.cfg):
# .ioq3
#
# pick the gfx device and / or window (the newest build with gfx; ignored when none has it):
# .ioq3 vk glfw
# .ioq3 d3d11
#
# dev map (q3dm0) in a window:
# .ioq3 dev win
#
# another map with bots, on a fresh config, writing qconsole.log:
# .ioq3 map=q3dm17 bots fresh log
#
# timedemo benchmark on renderer_opengl1:
# .ioq3 bench opengl1
#
# the QVMs instead of the game dlls, raw game args after them (from the first + arg on):
# .ioq3 qvm dev +set r_mode 6
#
# print the PowerShell line for this run instead of running it:
# .ioq3 vk dev print

function Write-Label($text) { Write-Host "$text" -ForegroundColor DarkGray }
function Write-Alt  ($text) { Write-Host "$text" -ForegroundColor Magenta  }
function Write-Extra($text) { Write-Host "$text" -ForegroundColor Blue     }
function Write-Warn ($text) { Write-Host "$text" -ForegroundColor DarkYellow }
function Write-Ok   ($text) { Write-Host "$text" -ForegroundColor Green    }
function Write-Err  ($text) { Write-Host "$text" -ForegroundColor Red      }

# When true, missing pk3 files are linked / copied without asking first
$AUTO_COPY_DATA = $false
# When true, a pk3 found on the same volume is hard-linked instead of copied (no extra disk
# space; falls back to a copy when linking fails)
$LINK_SAME_VOLUME = $true

# Build dirs are searched for these config folders; the newest ioquake3 exe wins
# (old builds: ioquake3.x86_64.exe / ioquake3.x86.exe, CMake builds: ioquake3.exe)
$REPO_ROOT = Join-Path -Path $env:code_root_dir -ChildPath "Code2/C/ioq3"
$BUILD_DIR_PATTERN = "build*"
$CONFIG_DIR_PATTERNS = @("*release*", "*relwithdebinfo*", "*debug*")
$CONFIG_SEARCH_DEPTH = 3
$CLIENT_EXE_PATTERN = "ioquake3*.exe"
$BUILD_TIME_FORMAT = "yyyy-MM-dd HH:mm:ss"
$CLIENT_ARGS = @("+set", "sv_pure", "0", "+set", "vm_game", "0", "+set", "vm_cgame", "0", "+set", "vm_ui", "0")

# Game data: <exe dir>/baseq3 needs these. When missing they are reused from another build's
# baseq3 first (a C build here or an ioq3-rs dist dir), then from <any drive>/2024/baseq3
$BASEQ3_DIR_NAME = "baseq3"
$RS_DIST_ROOT = Join-Path -Path $env:code_root_dir -ChildPath "Code2/Rust/ioq3-rs/target/dist"
$BUILD_BASEQ3_SEARCH_DEPTH = 3
$HDD_BASEQ3_SUBPATH = "2024/$BASEQ3_DIR_NAME"
$PK3_PATTERN = "*.pk3"
$REQUIRED_PK3S = 0..8 | ForEach-Object { "pak$_.pk3" }

# Launch options (Show-Help). The gfx backends only reach a client built with USE_GFX (the gfx
# branch): renderer_gfx is built into its exe, so the exe holds its cvar names. A gfx arg picks
# the newest build with gfx over a newer one without.
$SCRIPT_INVOCATION = $MyInvocation.InvocationName
$HELP_TOKENS = @("help", "h")
$PRINT_TOKENS = @("print", "onlyprint", "showcmd")
$GFX_DEVICES = @("gl4", "gl3", "gles3", "vk", "d3d11", "d3d12")
$GFX_DEVICE_ALIASES = @{ "vulkan" = "vk"; "dx11" = "d3d11"; "dx12" = "d3d12" }
$GFX_WINDOWS = @("sdl", "glfw", "win32")
$GFX_RENDERER = "gfx"
$RENDERERS = @($GFX_RENDERER, "opengl1", "opengl2")
$GFX_EXE_MARKER = "r_gfxDevice"
$OPTION_VALUE_SEPARATOR = "="
$PASSTHROUGH_PREFIX = "+"
$DEV_MAP = "q3dm0"
$BOTS = @("sarge", "doom")
$BOT_SKILL = "2"
$BOT_WAIT_FRAMES = "200"
$WINDOWED_ARGS = @("+set", "r_fullscreen", "0", "+set", "r_mode", "4")
$QVM_ARGS = @("+set", "vm_game", "2", "+set", "vm_cgame", "2", "+set", "vm_ui", "2")
$LOG_ARGS = @("+set", "logfile", "2")
$NO_BOTS_ARGS = @("+set", "bot_enable", "0")
$TEAM_ARENA_ARGS = @("+set", "fs_game", "missionpack")
$BENCH_ARGS = @("+set", "r_mode", "-1", "+set", "r_customwidth", "1920", "+set", "r_customheight", "1080",
	"+set", "r_swapInterval", "0", "+set", "com_maxfps", "0", "+timedemo", "1", "+demo", "four")
$FRESH_HOME_DIR = Join-Path -Path $env:TEMP -ChildPath "ioq3-fresh"

function Show-Help {
	Write-Alt "ioq3 - start the newest C ioq3 build under $REPO_ROOT/$BUILD_DIR_PATTERN"
	Write-Host @"

Usage: $SCRIPT_INVOCATION [options] [+game args...]
Options are case insensitive, in any order, with or without leading dashes.

gfx backends (used only when the built client supports gfx, ignored otherwise):
  $($GFX_DEVICES -join ' | ')   r_gfxDevice (vulkan = vk, dx11 / dx12 = d3d11 / d3d12)
  $($GFX_WINDOWS -join ' | ')               r_gfxWindow (d3d11 / d3d12 always use win32)
  Either one also sets cl_renderer $GFX_RENDERER and picks the newest build with gfx (USE_GFX). Both
  cvars are remembered in q3config.cfg, so a start without them uses the last ones.

Renderer:
  $($RENDERERS -join ' | ')     cl_renderer ($GFX_RENDERER only on a gfx build)

Starting:
  dev                    +devmap $DEV_MAP (skips the menu)
  dev=<map>, map=<map>   +devmap <map>
  bots                   +addbot $($BOTS -join ', ') (skill $BOT_SKILL) on the map (dev map if none given)
  nobots                 bot_enable 0
  connect=<address>      +connect <address> (instead of a map)
  bench                  timedemo 1 of demo four at 1920x1080, vsync / fps cap off, logfile on
  win                    windowed 800x600 (r_fullscreen 0, r_mode 4)
  qvm                    run the QVMs from the paks instead of the game dlls
  ta                     Team Arena (fs_game missionpack; needs its paks in missionpack/)
  fresh                  empty fs_homepath at $FRESH_HOME_DIR (cleared each run)
  log                    logfile 2 (qconsole.log in <home>/baseq3)

Other:
  +...                   this arg and all after it go to the game as they are
  $($PRINT_TOKENS -join ' | ')  print the PowerShell line for this run instead of running it
  $($HELP_TOKENS -join ' | ') (also -help, --help)  this help

Examples:
  $SCRIPT_INVOCATION vk glfw dev win
  $SCRIPT_INVOCATION map=q3dm17 bots fresh log
  $SCRIPT_INVOCATION bench d3d12
  $SCRIPT_INVOCATION opengl1 dev +set r_mode 6
"@
}

function Read-Options($argList) {
	# The launch options from the script args; exits on an unknown one
	$opts = @{
		Help = $false; PrintOnly = $false; Device = $null; Window = $null; Renderer = $null
		Map = $null; Bots = $false; NoBots = $false; Connect = $null; Bench = $false
		Windowed = $false; Qvm = $false; TeamArena = $false; Fresh = $false; Log = $false
		Extra = @()
	}

	for ($i = 0; $i -lt $argList.Count; $i++) {
		$raw = [string]$argList[$i]
		if ($raw.StartsWith($PASSTHROUGH_PREFIX)) {
			$opts.Extra = @($argList | Select-Object -Skip $i | ForEach-Object { [string]$_ })
			break
		}

		$name, $value = $raw.TrimStart("-") -split $OPTION_VALUE_SEPARATOR, 2
		$name = $name.ToLowerInvariant()
		if ($GFX_DEVICE_ALIASES.ContainsKey($name)) { $name = $GFX_DEVICE_ALIASES[$name] }

		if ($HELP_TOKENS -contains $name) { $opts.Help = $true }
		elseif ($PRINT_TOKENS -contains $name) { $opts.PrintOnly = $true }
		elseif ($GFX_DEVICES -contains $name) { $opts.Device = $name }
		elseif ($GFX_WINDOWS -contains $name) { $opts.Window = $name }
		elseif ($RENDERERS -contains $name) { $opts.Renderer = $name }
		elseif ($name -eq "dev") { $opts.Map = $(if ($value) { $value } else { $DEV_MAP }) }
		elseif ($name -eq "map" -and $value) { $opts.Map = $value }
		elseif ($name -eq "connect" -and $value) { $opts.Connect = $value }
		elseif ($name -eq "bots") { $opts.Bots = $true }
		elseif ($name -eq "nobots") { $opts.NoBots = $true }
		elseif ($name -eq "bench") { $opts.Bench = $true }
		elseif ($name -eq "win") { $opts.Windowed = $true }
		elseif ($name -eq "qvm") { $opts.Qvm = $true }
		elseif ($name -eq "ta") { $opts.TeamArena = $true }
		elseif ($name -eq "fresh") { $opts.Fresh = $true }
		elseif ($name -eq "log") { $opts.Log = $true }
		else {
			Write-Err "Unknown arg: $raw (map= / dev= / connect= need a value) - see '$SCRIPT_INVOCATION help'."
			exit 1
		}
	}

	if ($opts.Bots -and -not $opts.Map) { $opts.Map = $DEV_MAP }
	return $opts
}

function Test-GfxBuild($exePath) {
	# True when the client was built with USE_GFX (see the launch options above)
	$exeText = [System.Text.Encoding]::ASCII.GetString([System.IO.File]::ReadAllBytes($exePath))
	return $exeText.Contains($GFX_EXE_MARKER)
}

function Test-GfxWanted($opts) {
	# True when a gfx arg was given
	return [bool]($opts.Device -or $opts.Window -or $opts.Renderer -eq $GFX_RENDERER)
}

function Resolve-GfxOptions($opts, $gfxBuild) {
	# Drops the gfx options on a build without gfx; on a gfx build a backend also picks renderer_gfx
	if (-not $gfxBuild) {
		$ignored = @(@($opts.Device, $opts.Window) | Where-Object { $_ })
		if ($opts.Renderer -eq $GFX_RENDERER) { $ignored += $opts.Renderer; $opts.Renderer = $null }
		Write-Label "The client is built without gfx."
		if ($ignored.Count -gt 0) { Write-Warn "Ignoring the gfx arg(s): $($ignored -join ', ')" }
		$opts.Device = $null
		$opts.Window = $null
		return
	}

	Write-Label "The client is built with gfx."
	if (-not ($opts.Device -or $opts.Window)) { return }
	if (-not $opts.Renderer) {
		$opts.Renderer = $GFX_RENDERER
	} elseif ($opts.Renderer -ne $GFX_RENDERER) {
		Write-Warn "cl_renderer $($opts.Renderer) ignores r_gfxDevice / r_gfxWindow."
	}
}

function Get-LaunchArgs($opts) {
	# The game args: the defaults, then the cvars of the options, then the commands
	$launchArgs = @($CLIENT_ARGS)
	if ($opts.Qvm) { $launchArgs += $QVM_ARGS }
	if ($opts.TeamArena) { $launchArgs += $TEAM_ARENA_ARGS }
	if ($opts.Fresh) { $launchArgs += @("+set", "fs_homepath", $FRESH_HOME_DIR) }
	if ($opts.Renderer) { $launchArgs += @("+set", "cl_renderer", $opts.Renderer) }
	if ($opts.Device) { $launchArgs += @("+set", "r_gfxDevice", $opts.Device) }
	if ($opts.Window) { $launchArgs += @("+set", "r_gfxWindow", $opts.Window) }
	if ($opts.Windowed) { $launchArgs += $WINDOWED_ARGS }
	if ($opts.Log -or $opts.Bench) { $launchArgs += $LOG_ARGS }
	if ($opts.NoBots) { $launchArgs += $NO_BOTS_ARGS }

	if ($opts.Bench) {
		if ($opts.Map -or $opts.Connect) { Write-Warn "bench plays a demo - ignoring the map / connect." }
		$launchArgs += $BENCH_ARGS
	} elseif ($opts.Connect) {
		if ($opts.Map) { Write-Warn "connect joins a server - ignoring the map." }
		$launchArgs += @("+connect", $opts.Connect)
	} elseif ($opts.Map) {
		$launchArgs += @("+devmap", $opts.Map)
		if ($opts.Bots) {
			$launchArgs += @("+wait", $BOT_WAIT_FRAMES)
			foreach ($bot in $BOTS) { $launchArgs += @("+addbot", $bot, $BOT_SKILL) }
		}
	}

	return @($launchArgs + $opts.Extra)
}

function Reset-FreshHome {
	# The `fresh` fs_homepath is emptied first, so no q3config.cfg or *.pid carries over
	if (Test-Path -Path $FRESH_HOME_DIR) {
		Remove-Item -Path $FRESH_HOME_DIR -Recurse -Force -ErrorAction SilentlyContinue
	}
	Write-Label "Fresh home: $FRESH_HOME_DIR"
}

function Format-ShellArg($arg) {
	# Single-quotes an arg PowerShell would split or expand
	if ($arg -match '^[\w.\-+:\\/=]+$') { return $arg }
	return "'" + ($arg -replace "'", "''") + "'"
}

function Find-ClientBuilds($repoRoot) {
	# Every <root>/build*/**/<config>/ioquake3*.exe, newest build first.
	$found = New-Object System.Collections.Generic.List[object]

	$searchRoots = Get-ChildItem -Path $repoRoot -Directory -ErrorAction SilentlyContinue |
		Where-Object { $_.Name -like $BUILD_DIR_PATTERN }

	foreach ($searchRoot in $searchRoots) {
		$dirs = Get-ChildItem -Path $searchRoot.FullName -Directory -Recurse -Depth $CONFIG_SEARCH_DEPTH -ErrorAction SilentlyContinue

		foreach ($dir in $dirs) {
			$isConfigDir = $false
			foreach ($pattern in $CONFIG_DIR_PATTERNS) {
				if ($dir.Name -like $pattern) { $isConfigDir = $true; break }
			}
			if (-not $isConfigDir) { continue }

			Get-ChildItem -Path $dir.FullName -File -Filter $CLIENT_EXE_PATTERN -ErrorAction SilentlyContinue |
				ForEach-Object { $found.Add($_) }
		}
	}

	if ($found.Count -eq 0) { return $null }
	return $found.ToArray() | Sort-Object LastWriteTime -Descending
}

function Resolve-ClientExe($repoRoot, $opts) {
	# The newest build (the newest with gfx when a gfx arg was given and one has it)
	if (-not (Test-Path $repoRoot)) {
		Write-Err "ioq3 repo not found: $repoRoot"
		exit 1
	}

	$builds = @(Find-ClientBuilds $repoRoot)
	if ($builds.Count -eq 0 -or -not $builds[0]) {
		Write-Err "No $CLIENT_EXE_PATTERN was found under $repoRoot/$BUILD_DIR_PATTERN in a $($CONFIG_DIR_PATTERNS -join ' / ') dir."
		exit 1
	}

	$newest = $builds[0]
	if ((Test-GfxWanted $opts) -and -not (Test-GfxBuild $newest.FullName)) {
		$gfxBuild = $builds | Select-Object -Skip 1 | Where-Object { Test-GfxBuild $_.FullName } | Select-Object -First 1
		if ($gfxBuild) {
			Write-Label "The newest build has no gfx - using the newest one with gfx."
			$builds = @($gfxBuild) + @($builds | Where-Object { $_.FullName -ne $gfxBuild.FullName })
			$newest = $gfxBuild
		}
	}
	Write-Label "Using newest build: $($newest.FullName)"
	Write-Label "  built $($newest.LastWriteTime.ToString($BUILD_TIME_FORMAT))"

	foreach ($older in ($builds | Select-Object -Skip 1)) {
		Write-Label "  (older: $($older.FullName) - $($older.LastWriteTime.ToString($BUILD_TIME_FORMAT)))"
	}

	return $newest
}

function Get-MissingFiles($dir, $fileNames) {
	return @($fileNames | Where-Object {
		-not (Test-Path -Path (Join-Path -Path $dir -ChildPath $_) -PathType Leaf)
	})
}

function Find-BuildBaseq3Dirs {
	# Every <C repo>/build*/**/baseq3 and <ioq3-rs>/target/dist/**/baseq3 (a build's game data),
	# newest first
	$found = New-Object System.Collections.Generic.List[object]

	$searchRoots = @(Get-ChildItem -Path $REPO_ROOT -Directory -ErrorAction SilentlyContinue |
		Where-Object { $_.Name -like $BUILD_DIR_PATTERN }) +
		@(Get-Item -Path $RS_DIST_ROOT -ErrorAction SilentlyContinue)

	foreach ($searchRoot in $searchRoots) {
		Get-ChildItem -Path $searchRoot.FullName -Directory -Recurse -Depth $BUILD_BASEQ3_SEARCH_DEPTH -ErrorAction SilentlyContinue |
			Where-Object { $_.Name -ieq $BASEQ3_DIR_NAME } |
			ForEach-Object { $found.Add($_) }
	}

	return @($found.ToArray() | Sort-Object LastWriteTime -Descending | ForEach-Object { $_.FullName })
}

function Find-HddBaseq3Dirs {
	# Every <drive>:/2024/baseq3
	$found = @()
	foreach ($drive in (Get-PSDrive -PSProvider FileSystem | Sort-Object Name)) {
		$candidate = Join-Path -Path $drive.Root -ChildPath $HDD_BASEQ3_SUBPATH
		if (Test-Path -Path $candidate -PathType Container) { $found += $candidate }
	}
	return $found
}

function Find-SourceBaseq3($targetDir) {
	# First baseq3 (builds first, then the drives) that holds every required pk3
	$targetFull = [System.IO.Path]::GetFullPath($targetDir)
	$candidates = @(Find-BuildBaseq3Dirs) + @(Find-HddBaseq3Dirs)

	foreach ($candidate in $candidates) {
		if ([System.IO.Path]::GetFullPath($candidate) -ieq $targetFull) { continue }

		$missing = Get-MissingFiles $candidate $REQUIRED_PK3S
		if ($missing.Count -eq 0) {
			Write-Ok "Found baseq3 data: $candidate"
			return $candidate
		}
		Write-Warn "$candidate is missing $($missing -join ', ') - skipping it."
	}

	return $null
}

function Confirm-Copy($question) {
	if ($AUTO_COPY_DATA) {
		Write-Label "AUTO_COPY_DATA is set - going ahead without asking."
		return $true
	}
	$answer = Read-Host "$question [y/N]"
	return ($answer -ieq "y" -or $answer -ieq "yes")
}

function Add-DataFile($source, $destDir) {
	# Hard-links the file when source and destination share a volume (and LINK_SAME_VOLUME is
	# set), copies it otherwise or when linking fails
	$dest = Join-Path -Path $destDir -ChildPath (Split-Path -Path $source -Leaf)
	$sameVolume = [System.IO.Path]::GetPathRoot($source) -ieq [System.IO.Path]::GetPathRoot($dest)

	if ($LINK_SAME_VOLUME -and $sameVolume) {
		try {
			New-Item -ItemType HardLink -Path $dest -Target $source -ErrorAction Stop | Out-Null
			Write-Ok "Linked $source -> $dest"
			return
		} catch {
			Write-Warn "Could not link $source ($($_.Exception.Message)) - copying instead."
		}
	}

	try {
		Copy-Item -Path $source -Destination $destDir -ErrorAction Stop
		Write-Ok "Copied $source -> $destDir"
	} catch {
		Write-Err "Could not copy $source -> ${destDir}: $($_.Exception.Message)"
	}
}

function Sync-Baseq3($baseq3Dir) {
	# Links / copies the source's missing pk3 files into baseq3 (after one confirmation), then
	# checks the required ones. Exits when a required pk3 is still missing.
	$missingRequired = Get-MissingFiles $baseq3Dir $REQUIRED_PK3S
	$sourceBaseq3 = $null

	if ($missingRequired.Count -gt 0) {
		$sourceBaseq3 = Find-SourceBaseq3 $baseq3Dir
	}

	if ($sourceBaseq3) {
		$sourceNames = @(Get-ChildItem -Path $sourceBaseq3 -File -Filter $PK3_PATTERN | Select-Object -ExpandProperty Name)
		$toCopy = Get-MissingFiles $baseq3Dir $sourceNames

		foreach ($name in ($sourceNames | Where-Object { $toCopy -notcontains $_ })) {
			Write-Ok "$name already exists in $baseq3Dir, skipping."
		}

		if ($toCopy.Count -gt 0) {
			Write-Warn "$($toCopy.Count) pk3 file(s) missing from ${baseq3Dir}: $($toCopy -join ', ')"

			if (Confirm-Copy "Link / copy them from ${sourceBaseq3}?") {
				if (-not (Test-Path $baseq3Dir)) { New-Item -ItemType Directory -Path $baseq3Dir | Out-Null }

				foreach ($name in $toCopy) {
					Add-DataFile (Join-Path -Path $sourceBaseq3 -ChildPath $name) $baseq3Dir
				}
			} else {
				Write-Warn "Skipped copying."
			}
		}
	} elseif ($missingRequired.Count -gt 0) {
		Write-Warn "No build baseq3 under $REPO_ROOT/$BUILD_DIR_PATTERN or $RS_DIST_ROOT and no mounted drive's $HDD_BASEQ3_SUBPATH holds $($REQUIRED_PK3S -join ', ')."
	}

	$stillMissing = Get-MissingFiles $baseq3Dir $REQUIRED_PK3S
	if ($stillMissing.Count -gt 0) {
		Write-Err "Required file(s) missing from ${baseq3Dir}: $($stillMissing -join ', ')"
		if (-not $sourceBaseq3) {
			Write-Err "Build ioq3 / ioq3-rs with its data, plug in / map a drive with $HDD_BASEQ3_SUBPATH, or copy them in by hand."
		}
		exit 1
	}

	Write-Ok "All $($REQUIRED_PK3S.Count) required pk3 files found in $baseq3Dir."
}

$options = Read-Options $args
if ($options.Help) {
	Show-Help
	exit 0
}

Write-Alt "ioq3..."

$exe = Resolve-ClientExe $REPO_ROOT $options
$baseq3Dir = Join-Path -Path $exe.Directory.FullName -ChildPath $BASEQ3_DIR_NAME
Resolve-GfxOptions $options (Test-GfxBuild $exe.FullName)
$clientArgs = Get-LaunchArgs $options

if ($options.PrintOnly) {
	# The PowerShell lines reproducing this run (the pk3 check is left out)
	Write-Host
	Write-Extra "# $SCRIPT_INVOCATION $(($args | ForEach-Object { Format-ShellArg ([string]$_) }) -join ' ')"
	if ($options.Fresh) {
		Write-Extra "Remove-Item -Recurse -Force $(Format-ShellArg $FRESH_HOME_DIR) -ErrorAction SilentlyContinue"
	}
	Write-Extra "& $(Format-ShellArg $exe.FullName) $(($clientArgs | ForEach-Object { Format-ShellArg $_ }) -join ' ')"
	exit 0
}

Write-Host

Sync-Baseq3 $baseq3Dir
if ($options.Fresh) { Reset-FreshHome }

Write-Host

Write-Extra "$($exe.FullName) $($clientArgs -join ' ')"
& $exe.FullName @clientArgs
