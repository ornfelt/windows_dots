# Usage examples (nothing runs without `run` as the first arg; the args after it in any order,
# case insensitive; `.stk help` lists them all):
# cd into the repo and print how to run it, through this script and by hand (runs nothing):
# .stk
#
# the newest build, at the menu:
# .stk run
#
# a race right away on lighthouse as tux, 3 laps, windowed at 1600x900:
# .stk run now track=lighthouse kart=tux laps=3 win size=1600x900
#
# a time trial on expert, skipping ready-set-go and the music:
# .stk run race mode=tt difficulty=expert track=zengarden
#
# the benchmark on graphics preset 7, from build-debug, built first:
# .stk run bench preset=7 tree=build-debug build
#
# any supertuxkart arg as it is (a dashed arg the script does not know, or all after a quoted '--'):
# .stk run --enable-ssao --seed=42 '--' --server-password=secret
#
# print the PowerShell line for this run instead of running it:
# .stk run now track=lighthouse print

function Write-Label($text) { Write-Host "$text" -ForegroundColor DarkGray }
function Write-Alt  ($text) { Write-Host "$text" -ForegroundColor Magenta  }
function Write-Extra($text) { Write-Host "$text" -ForegroundColor Blue     }
function Write-Warn ($text) { Write-Host "$text" -ForegroundColor DarkYellow }
function Write-Ok   ($text) { Write-Host "$text" -ForegroundColor Green    }
function Write-Err  ($text) { Write-Host "$text" -ForegroundColor Red      }

# The checkout: the first of these that exists (stk-code is the Linux layout; the last two are
# older checkouts)
$REPO_ROOT_CANDIDATES = @(
	(Join-Path -Path $env:code_root_dir -ChildPath "Code2/C++/stk/stk-code"),
	(Join-Path -Path $env:code_root_dir -ChildPath "Code2/C++/stk-code"),
	"D:\My files\svea_laptop\Downloads\SuperTuxKart-dev\stk-code",
	"C:\Users\jonas\OneDrive\Documents\Code\stk\stk-code"
)
$REPO_ROOT = $REPO_ROOT_CANDIDATES | Where-Object { Test-Path -Path $_ -PathType Container } | Select-Object -First 1
if (-not $REPO_ROOT) { $REPO_ROOT = $REPO_ROOT_CANDIDATES[0] }
# Build dirs are searched this deep for the exe (build/bin/<Config>/supertuxkart.exe, a Ninja
# tree's build/bin/supertuxkart.exe); the newest one wins
$BUILD_DIR_PATTERN = "build*"
$EXE_SEARCH_DEPTH = 3
$CLIENT_EXE_NAME = "supertuxkart.exe"
$BUILD_TIME_FORMAT = "yyyy-MM-dd HH:mm:ss"

# `build` builds the exe's build dir (tree= when given, else build/, configured when missing)
# in the config of the exe's dir (Release when it is none of these)
$DEFAULT_BUILD_DIR = "build"
$CMAKE_CACHE_NAME = "CMakeCache.txt"
$CONFIGURE_ARGS = @("-A", "x64")
$BUILD_CONFIGS = @("Release", "RelWithDebInfo", "Debug", "MinSizeRel")

# stk takes data/ from the current dir first and its assets from data/../../<one of these>,
# unless SUPERTUXKART_DATADIR / SUPERTUXKART_ASSETS_DIR say otherwise
$ASSETS_DIR_NAMES = @("stk-assets", "supertuxkart-assets")
$ASSETS_SVN_URL = "https://svn.code.sf.net/p/supertuxkart/code/stk-assets"
# Where stk writes its config and stdout.log
$CONFIG_DIR = Join-Path -Path $env:APPDATA -ChildPath "supertuxkart/config-0.10"
# STATUS_DLL_NOT_FOUND: the exe could not be started (a missing dll)
$EXIT_DLL_NOT_FOUND = -1073741515

# Launch options (Show-Help)
$SCRIPT_INVOCATION = $MyInvocation.InvocationName
$RUN_COMMAND = "run"
$HELP_TOKENS = @("help", "h")
$PRINT_TOKENS = @("print", "onlyprint", "showcmd")
$OPTION_VALUE_SEPARATOR = "="
$PASSTHROUGH_PREFIX = "-"
$PASSTHROUGH_ALL = "--"
# --mode= / --difficulty= take the index of these names
$MODE_NAMES = @("normal", "tt", "battle", "soccer", "ftl", "ctf")
$DIFFICULTY_NAMES = @("beginner", "intermediate", "expert", "supertux")

function Format-NamedIndexes($names) {
	# "name (0) | name (1) | ..."
	return (0..($names.Count - 1) | ForEach-Object { "$($names[$_]) ($_)" }) -join ' | '
}

function Show-Help {
	Write-Alt "stk - start the newest SuperTuxKart build under $REPO_ROOT/$BUILD_DIR_PATTERN"
	Write-Host @"

Usage: $SCRIPT_INVOCATION $RUN_COMMAND [options] [-supertuxkart args...] ['$PASSTHROUGH_ALL' supertuxkart args...]
Nothing runs without $RUN_COMMAND as the first arg; a bare $SCRIPT_INVOCATION cds into the repo and prints how to run it.
Options are case insensitive, in any order, with or without leading dashes.

Build (default: the newest $CLIENT_EXE_NAME under $BUILD_DIR_PATTERN/, $EXE_SEARCH_DEPTH levels deep):
  tree=<dir>             the newest one in this build dir instead (relative to the repo, or absolute)
  build                  build that dir first (cmake --build; $DEFAULT_BUILD_DIR/ is configured when missing)

Window:
  win, windowed          --windowed
  full, fullscreen       --fullscreen
  size=<W>x<H>           --screensize=<W>x<H>
  preset=<1-7>           --gfx-preset=<n> (the graphics settings preset)

Race:
  now                    -N: start a race right away, no menu
  race                   -R: like now, also skipping ready-set-go and the music
  track=<name>           --track=<name> (a dir name in stk-assets/tracks)
  gp=<name>              --gp=<name> (a Grand Prix)
  kart=<name>            --kart=<name> (a dir name in stk-assets/karts)
  karts=<n>              --numkarts=<n>
  laps=<n>               --laps=<n>
  reverse                --reverse
  mode=<name|n>          --mode: $(Format-NamedIndexes $MODE_NAMES)
  difficulty=<name|n>    --difficulty: $(Format-NamedIndexes $DIFFICULTY_NAMES)
  unlock                 --unlock-all (saved in the config)

Network:
  connect=<ip[:port]>    --connect-now=<ip[:port]>
  lan=<name>             --lan-server=<name> (hosts a LAN server instead of playing)

Other:
  bench                  --benchmark (saves the results and exits)
  log=<0-5>              --log=<n> (0 debug .. 5 only fatal)
  version                -v
  -...                   any other dashed arg goes to supertuxkart as it is ($SCRIPT_INVOCATION $RUN_COMMAND '$PASSTHROUGH_ALL' --help lists them)
  '$PASSTHROUGH_ALL'                   all args after it go to supertuxkart as they are (quoted: PowerShell keeps a bare $PASSTHROUGH_ALL)
  $($PRINT_TOKENS -join ' | ')  print the PowerShell line for this run instead of running it
  $($HELP_TOKENS -join ' | ') (also -help, --help)  this help

It runs from the repo root (data/ there, the assets in ../$($ASSETS_DIR_NAMES -join ' or ../'));
its config and stdout.log are in $CONFIG_DIR.

Examples:
  $SCRIPT_INVOCATION $RUN_COMMAND now track=lighthouse kart=tux laps=3 win
  $SCRIPT_INVOCATION $RUN_COMMAND race mode=tt difficulty=expert track=zengarden
  $SCRIPT_INVOCATION $RUN_COMMAND bench preset=7 build
  $SCRIPT_INVOCATION $RUN_COMMAND --enable-ssao '$PASSTHROUGH_ALL' --seed=42

"@
	Show-ManualRun
}

function Show-Usage {
	# A bare call: how to run stk from the repo, through this script and by hand
	Write-Alt "stk - $REPO_ROOT"
	Write-Label "Run it through this script (the options after $RUN_COMMAND; '$SCRIPT_INVOCATION help' lists them):"
	Write-Extra "$SCRIPT_INVOCATION $RUN_COMMAND"
	Show-ManualRun
}

function Show-ManualRun {
	# Prints how to start the newest build by hand, without this script
	$exe = @(Find-ClientBuilds @(Get-BuildRoots))[0]
	if (-not $exe) {
		Write-Warn "No $CLIENT_EXE_NAME built under $REPO_ROOT/$BUILD_DIR_PATTERN yet - build it (from $REPO_ROOT):"
		Write-Extra "cmake -B $DEFAULT_BUILD_DIR $($CONFIGURE_ARGS -join ' '); cmake --build $DEFAULT_BUILD_DIR --config $($BUILD_CONFIGS[0]) --target $([System.IO.Path]::GetFileNameWithoutExtension($CLIENT_EXE_NAME)) --parallel"
		return
	}
	Push-Location -Path $REPO_ROOT
	$relativePath = Resolve-Path -Path $exe.FullName -Relative
	Pop-Location
	Write-Label "Or run it manually (from $REPO_ROOT, the newest build; it finds data/ from there):"
	Write-Extra "& $(Format-ShellArg $relativePath)"
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

function Resolve-NamedIndex($raw, $value, $names) {
	# The index of the value in the names (a name, any case, or the index itself); exits on any
	# other value
	$value = $value.ToLowerInvariant()
	if ($value -match '^\d+$' -and [int]$value -lt $names.Count) { return [int]$value }
	$index = [array]::IndexOf($names, $value)
	if ($index -ge 0) { return $index }
	Write-Err "Unknown value: $raw (one of $($names -join ' / '), or 0-$($names.Count - 1))."
	exit 1
}

function Read-Options($argList) {
	# The launch options from the script args; exits on an unknown one. Stk holds the
	# supertuxkart args of the options, Extra the ones passed as they are (after them)
	$opts = @{ Help = $false; PrintOnly = $false; Tree = $null; Build = $false; Stk = @(); Extra = @() }

	for ($i = 0; $i -lt $argList.Count; $i++) {
		$raw = [string]$argList[$i]
		if ($raw -eq $PASSTHROUGH_ALL) {
			$opts.Extra += @($argList | Select-Object -Skip ($i + 1))
			break
		}

		$name, $value = $raw.TrimStart("-") -split $OPTION_VALUE_SEPARATOR, 2
		$name = $name.ToLowerInvariant()

		if ($HELP_TOKENS -contains $name) { $opts.Help = $true }
		elseif ($PRINT_TOKENS -contains $name) { $opts.PrintOnly = $true }
		elseif ($name -eq "tree" -and $value) { $opts.Tree = $value }
		elseif ($name -eq "build") { $opts.Build = $true }
		elseif ($name -eq "win" -or $name -eq "windowed") { $opts.Stk += "--windowed" }
		elseif ($name -eq "full" -or $name -eq "fullscreen") { $opts.Stk += "--fullscreen" }
		elseif ($name -eq "size" -and $value) { $opts.Stk += "--screensize=$value" }
		elseif ($name -eq "preset" -and $value) { $opts.Stk += "--gfx-preset=$value" }
		elseif ($name -eq "now") { $opts.Stk += "-N" }
		elseif ($name -eq "race") { $opts.Stk += "-R" }
		elseif ($name -eq "track" -and $value) { $opts.Stk += "--track=$value" }
		elseif ($name -eq "gp" -and $value) { $opts.Stk += "--gp=$value" }
		elseif ($name -eq "kart" -and $value) { $opts.Stk += "--kart=$value" }
		elseif ($name -eq "karts" -and $value) { $opts.Stk += "--numkarts=$value" }
		elseif ($name -eq "laps" -and $value) { $opts.Stk += "--laps=$value" }
		elseif ($name -eq "reverse") { $opts.Stk += "--reverse" }
		elseif ($name -eq "mode" -and $value) { $opts.Stk += "--mode=$(Resolve-NamedIndex $raw $value $MODE_NAMES)" }
		elseif ($name -eq "difficulty" -and $value) { $opts.Stk += "--difficulty=$(Resolve-NamedIndex $raw $value $DIFFICULTY_NAMES)" }
		elseif ($name -eq "unlock") { $opts.Stk += "--unlock-all" }
		elseif ($name -eq "connect" -and $value) { $opts.Stk += "--connect-now=$value" }
		elseif ($name -eq "lan" -and $value) { $opts.Stk += "--lan-server=$value" }
		elseif ($name -eq "bench") { $opts.Stk += "--benchmark" }
		elseif ($name -eq "log" -and $value) { $opts.Stk += "--log=$value" }
		elseif ($name -eq "version") { $opts.Stk += "-v" }
		elseif ($raw.StartsWith($PASSTHROUGH_PREFIX)) { $opts.Extra += $raw }
		else {
			Write-Err "Unknown arg: $raw (tree= / size= / preset= / track= / gp= / kart= / karts= / laps= / mode= / difficulty= / connect= / lan= / log= need a value) - see '$SCRIPT_INVOCATION help'."
			exit 1
		}
	}
	return $opts
}

function Get-BuildRoots {
	# The repo's build*/ dirs
	return @(Get-ChildItem -Path $REPO_ROOT -Directory -Filter $BUILD_DIR_PATTERN -ErrorAction SilentlyContinue |
		ForEach-Object { $_.FullName })
}

function Find-ClientBuilds($roots) {
	# Every <root>/**/supertuxkart.exe, newest first
	$found = foreach ($root in $roots) {
		if (-not (Test-Path -Path $root -PathType Container)) { continue }
		Get-ChildItem -Path $root -File -Recurse -Depth ($EXE_SEARCH_DEPTH - 1) -Filter $CLIENT_EXE_NAME -ErrorAction SilentlyContinue
	}
	# (a $null $found would go down the pipeline as one item)
	return @($found | Where-Object { $_ } | Sort-Object LastWriteTime -Descending)
}

function Resolve-ClientExe($opts) {
	# Builds (newest first), Exe (the newest, $null when none) and BuildDir (tree=, else the newest
	# one's build dir, else build/)
	if ($opts.Tree) {
		$buildDir = $(if ([System.IO.Path]::IsPathRooted($opts.Tree)) { $opts.Tree } else { Join-Path -Path $REPO_ROOT -ChildPath $opts.Tree })
		$builds = @(Find-ClientBuilds @($buildDir))
	} else {
		$buildDir = Join-Path -Path $REPO_ROOT -ChildPath $DEFAULT_BUILD_DIR
		$roots = @(Get-BuildRoots)
		$builds = @(Find-ClientBuilds $roots)
		if ($builds.Count -gt 0) {
			$buildDir = $roots | Where-Object { $builds[0].FullName.StartsWith($_ + [System.IO.Path]::DirectorySeparatorChar) } | Select-Object -First 1
		}
	}
	return @{ Builds = $builds; Exe = $(if ($builds.Count -gt 0) { $builds[0] } else { $null }); BuildDir = $buildDir }
}

function Get-BuildConfig($exe) {
	# The config of the exe's dir (bin/<Config>/), else the first of BUILD_CONFIGS
	if ($exe -and $BUILD_CONFIGS -contains $exe.Directory.Name) { return $exe.Directory.Name }
	return $BUILD_CONFIGS[0]
}

function Get-BuildCommands($client) {
	# cmake's args configuring (only when the build dir has no CMake cache) and building
	# supertuxkart, one array per cmake run
	$commands = @()
	if (-not (Test-Path -Path (Join-Path -Path $client.BuildDir -ChildPath $CMAKE_CACHE_NAME) -PathType Leaf)) {
		$commands += , (@("-S", $REPO_ROOT, "-B", $client.BuildDir) + $CONFIGURE_ARGS)
	}
	$target = [System.IO.Path]::GetFileNameWithoutExtension($CLIENT_EXE_NAME)
	$commands += , @("--build", $client.BuildDir, "--config", (Get-BuildConfig $client.Exe), "--target", $target, "--parallel")
	# The comma keeps a single run's array from being unrolled into its args
	return , $commands
}

function Build-Client($client) {
	# Configures the build dir when it has no CMake cache, then builds supertuxkart in it
	foreach ($cmakeArgs in (Get-BuildCommands $client)) {
		Write-Extra "cmake $(($cmakeArgs | ForEach-Object { Format-ShellArg $_ }) -join ' ')"
		& cmake @cmakeArgs
		if ($LASTEXITCODE -ne 0) {
			Write-Err "cmake failed (exit code $LASTEXITCODE)."
			exit 1
		}
	}
	Write-Ok "Build done."
}

function Test-Assets {
	# Warns when stk finds no assets (karts, tracks, music) beside the repo
	if ($env:SUPERTUXKART_ASSETS_DIR -or $env:SUPERTUXKART_DATADIR) {
		Write-Label "Data / assets from SUPERTUXKART_DATADIR / SUPERTUXKART_ASSETS_DIR."
		return
	}
	$parent = Split-Path -Path $REPO_ROOT -Parent
	foreach ($name in $ASSETS_DIR_NAMES) {
		$dir = Join-Path -Path $parent -ChildPath $name
		if (Test-Path -Path $dir -PathType Container) {
			Write-Label "Assets: $dir"
			return
		}
	}
	Write-Warn "No $($ASSETS_DIR_NAMES -join ' / ') beside $REPO_ROOT - stk has no karts and tracks without it:"
	Write-Extra "svn checkout $ASSETS_SVN_URL $(Format-ShellArg (Join-Path -Path $parent -ChildPath $ASSETS_DIR_NAMES[0]))"
}

function Format-ShellArg($arg) {
	# Single-quotes an arg PowerShell would split or expand
	if ($arg -match '^[\w.\-+:\\/=,]+$') { return $arg }
	return "'" + ($arg -replace "'", "''") + "'"
}

function Show-LaunchCommand($client, $opts, $launchArgs, $scriptArgs) {
	# Prints the PowerShell lines reproducing this run
	$lines = @("# $SCRIPT_INVOCATION $(($scriptArgs | ForEach-Object { Format-ShellArg ([string]$_) }) -join ' ')")
	if ($opts.Build) {
		foreach ($cmakeArgs in (Get-BuildCommands $client)) {
			$lines += "cmake $(($cmakeArgs | ForEach-Object { Format-ShellArg $_ }) -join ' ')"
		}
	}
	$exePath = $(if ($client.Exe) { $client.Exe.FullName } else { Join-Path -Path $client.BuildDir -ChildPath "bin/$(Get-BuildConfig $null)/$CLIENT_EXE_NAME" })
	$lines += "Push-Location $(Format-ShellArg $REPO_ROOT); & $(Format-ShellArg $exePath) $(($launchArgs | ForEach-Object { Format-ShellArg $_ }) -join ' '); Pop-Location"

	Write-Host
	foreach ($line in $lines) { Write-Extra $line }
}

function Start-Client($exePath, $launchArgs) {
	# Runs the game from the repo root in the foreground (data/ is found from there)
	Push-Location -Path $REPO_ROOT
	try {
		& $exePath @launchArgs
		$exitCode = $LASTEXITCODE
	} finally {
		Pop-Location
	}

	if ($exitCode -eq 0) {
		Write-Label "$CLIENT_EXE_NAME exited (exit code 0)."
		return
	}
	Write-Err ("$CLIENT_EXE_NAME exited with exit code {0} (0x{0:X8})." -f $exitCode)
	if ($exitCode -eq $EXIT_DLL_NOT_FOUND) {
		Write-Err "It could not be started - a dll may be missing beside $exePath."
	}
	Write-Err "See its log: $(Join-Path -Path $CONFIG_DIR -ChildPath 'stdout.log')"
	exit 1
}

if ($args.Count -eq 0) {
	# A bare call cds into the repo (a script's Set-Location stays in the calling shell) and shows
	# how to run it, running nothing
	if (-not (Test-Path -Path $REPO_ROOT -PathType Container)) {
		Write-Err "stk-code repo not found: $($REPO_ROOT_CANDIDATES -join ' or ')"
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

Write-Alt "stk..."

if (-not (Test-Path -Path $REPO_ROOT -PathType Container)) {
	Write-Err "stk-code repo not found: $($REPO_ROOT_CANDIDATES -join ' or ')"
	exit 1
}

$client = Resolve-ClientExe $options
$launchArgs = @($options.Stk) + @($options.Extra)

if ($options.PrintOnly) {
	Show-LaunchCommand $client $options $launchArgs $args
	exit 0
}

if ($options.Build) {
	Build-Client $client
	$client = Resolve-ClientExe $options
}
if (-not $client.Exe) {
	if ($options.Tree) {
		Write-Err "No $CLIENT_EXE_NAME under $($client.BuildDir) - add 'build' to build it there."
	} else {
		Write-Err "No $CLIENT_EXE_NAME under $REPO_ROOT/$BUILD_DIR_PATTERN - add 'build' to build $DEFAULT_BUILD_DIR/ (configured when missing)."
	}
	exit 1
}

Write-Label "Using newest build: $($client.Exe.FullName)"
Write-Label "  built $($client.Exe.LastWriteTime.ToString($BUILD_TIME_FORMAT))"
foreach ($older in @($client.Builds | Select-Object -Skip 1)) {
	Write-Label "  (older: $($older.FullName) - $($older.LastWriteTime.ToString($BUILD_TIME_FORMAT)))"
}
Test-Assets

Write-Host

Write-Extra "Push-Location $REPO_ROOT; & $($client.Exe.FullName) $($launchArgs -join ' '); Pop-Location"
Start-Client $client.Exe.FullName $launchArgs
