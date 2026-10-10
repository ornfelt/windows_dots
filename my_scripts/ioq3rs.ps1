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

# The Rust port; `cargo xtask dist --release` puts ioquake3.exe, the renderer dlls, SDL2.dll and
# the Rust modules (baseq3/, missionpack/) in target/dist/release - built when the exe is missing
$REPO_ROOT = Join-Path -Path $env:code_root_dir -ChildPath "Code2/Rust/ioq3-rs"
$DIST_SUBPATH = "target/dist/release"
$CLIENT_EXE_NAME = "ioquake3.exe"
$BUILD_COMMAND = "cargo"
$BUILD_ARGS = @("xtask", "dist", "--release")
$BUILD_TIME_FORMAT = "yyyy-MM-dd HH:mm:ss"
$CLIENT_ARGS = @("+set", "sv_pure", "0", "+set", "vm_game", "0", "+set", "vm_cgame", "0", "+set", "vm_ui", "0")

# Game data: <exe dir>/baseq3 needs these. They are reused from a C ioq3 build's baseq3 first,
# then from <any drive>/2024/baseq3
$BASEQ3_DIR_NAME = "baseq3"
$HDD_BASEQ3_SUBPATH = "2024/$BASEQ3_DIR_NAME"
$PK3_PATTERN = "*.pk3"
$REQUIRED_PK3S = 0..8 | ForEach-Object { "pak$_.pk3" }
$C_REPO_ROOT = Join-Path -Path $env:code_root_dir -ChildPath "Code2/C/ioq3"
$C_BUILD_DIR_PATTERN = "build*"
$C_BASEQ3_SEARCH_DEPTH = 3

# SDL2.dll next to the exe must match its architecture (a 32-bit one makes a 64-bit exe exit at
# once with 0xC000007B); the right one is taken from the C tree's thirdparty libs
$SDL_DLL_NAME = "SDL2.dll"
$SDL_LIBS_SUBPATH = "code/thirdparty/libs"
$PE_MACHINE_DIRS = @{ "x64" = "win64"; "x86" = "win32" }

# The game is started detached; when it exits within this many ms its exit code is reported
$STARTUP_CHECK_MS = 5000
$STATUS_INVALID_IMAGE_FORMAT = -1073741701

function Build-Client($repoRoot) {
	if (-not (Get-Command $BUILD_COMMAND -ErrorAction SilentlyContinue)) {
		Write-Err "$BUILD_COMMAND not found on PATH - install the Rust toolchain (rustup) first."
		exit 1
	}

	Write-Warn "No $CLIENT_EXE_NAME in $repoRoot/$DIST_SUBPATH - building it."
	Write-Extra "$BUILD_COMMAND $($BUILD_ARGS -join ' ')"

	Push-Location $repoRoot
	try {
		& $BUILD_COMMAND @BUILD_ARGS
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

function Resolve-ClientExe($repoRoot) {
	if (-not (Test-Path $repoRoot)) {
		Write-Err "ioq3-rs repo not found: $repoRoot"
		exit 1
	}

	$exePath = Join-Path -Path (Join-Path -Path $repoRoot -ChildPath $DIST_SUBPATH) -ChildPath $CLIENT_EXE_NAME
	if (-not (Test-Path -Path $exePath -PathType Leaf)) {
		Build-Client $repoRoot
		if (-not (Test-Path -Path $exePath -PathType Leaf)) {
			Write-Err "The build finished but $exePath is still missing."
			exit 1
		}
	}

	$exe = Get-Item -Path $exePath
	Write-Label "Using build: $($exe.FullName)"
	Write-Label "  built $($exe.LastWriteTime.ToString($BUILD_TIME_FORMAT))"
	return $exe
}

function Get-MissingFiles($dir, $fileNames) {
	return @($fileNames | Where-Object {
		-not (Test-Path -Path (Join-Path -Path $dir -ChildPath $_) -PathType Leaf)
	})
}

function Find-CBaseq3Dirs {
	# Every <C repo>/build*/**/baseq3 (a C build's game data), newest first
	$found = New-Object System.Collections.Generic.List[object]

	$searchRoots = Get-ChildItem -Path $C_REPO_ROOT -Directory -ErrorAction SilentlyContinue |
		Where-Object { $_.Name -like $C_BUILD_DIR_PATTERN }

	foreach ($searchRoot in $searchRoots) {
		Get-ChildItem -Path $searchRoot.FullName -Directory -Recurse -Depth $C_BASEQ3_SEARCH_DEPTH -ErrorAction SilentlyContinue |
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
	# First baseq3 (C builds first, then the drives) that holds every required pk3
	$targetFull = [System.IO.Path]::GetFullPath($targetDir)
	$candidates = @(Find-CBaseq3Dirs) + @(Find-HddBaseq3Dirs)

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
		Write-Warn "No C build baseq3 under $C_REPO_ROOT and no mounted drive's $HDD_BASEQ3_SUBPATH holds $($REQUIRED_PK3S -join ', ')."
	}

	$stillMissing = Get-MissingFiles $baseq3Dir $REQUIRED_PK3S
	if ($stillMissing.Count -gt 0) {
		Write-Err "Required file(s) missing from ${baseq3Dir}: $($stillMissing -join ', ')"
		if (-not $sourceBaseq3) {
			Write-Err "Build the C ioq3 with its data, plug in / map a drive with $HDD_BASEQ3_SUBPATH, or copy them in by hand."
		}
		exit 1
	}

	Write-Ok "All $($REQUIRED_PK3S.Count) required pk3 files found in $baseq3Dir."
}

function Get-PeMachine($path) {
	# "x64" / "x86" (or the raw machine value) from a PE file's COFF header
	$stream = [System.IO.File]::OpenRead($path)
	try {
		$reader = New-Object System.IO.BinaryReader($stream)
		$stream.Position = 0x3C
		$stream.Position = $reader.ReadInt32() + 4
		$machine = $reader.ReadUInt16()
	} finally {
		$stream.Dispose()
	}
	switch ($machine) {
		0x8664  { return "x64" }
		0x14c   { return "x86" }
		default { return ("0x{0:X}" -f $machine) }
	}
}

function Sync-SdlDll($exe) {
	# Makes sure the SDL2.dll next to the exe has the exe's architecture, copying the right one
	# from the C tree when it is missing or wrong
	$exeMachine = Get-PeMachine $exe.FullName
	$dest = Join-Path -Path $exe.Directory.FullName -ChildPath $SDL_DLL_NAME

	if (Test-Path -Path $dest -PathType Leaf) {
		$dllMachine = Get-PeMachine $dest
		if ($dllMachine -eq $exeMachine) {
			Write-Ok "$SDL_DLL_NAME is $dllMachine, matching the exe."
			return
		}
		Write-Warn "$dest is $dllMachine but the exe is $exeMachine - replacing it."
	} else {
		Write-Warn "No $SDL_DLL_NAME next to the exe."
	}

	if (-not $PE_MACHINE_DIRS.ContainsKey($exeMachine)) {
		Write-Err "No known $SDL_DLL_NAME folder for a $exeMachine exe."
		exit 1
	}
	$source = Join-Path -Path (Join-Path -Path (Join-Path -Path $C_REPO_ROOT -ChildPath $SDL_LIBS_SUBPATH) -ChildPath $PE_MACHINE_DIRS[$exeMachine]) -ChildPath $SDL_DLL_NAME
	if (-not (Test-Path -Path $source -PathType Leaf)) {
		Write-Err "$source not found - put a $exeMachine $SDL_DLL_NAME next to the exe by hand."
		exit 1
	}

	try {
		Copy-Item -Path $source -Destination $dest -Force -ErrorAction Stop
		Write-Ok "Copied $source -> $dest"
	} catch {
		Write-Err "Could not copy $source -> ${dest}: $($_.Exception.Message)"
		exit 1
	}
}

function Start-Client($exe, $clientArgs) {
	# Starts the game detached (as `& exe` does for a GUI app) and reports it when it exits
	# right away, which otherwise looks like nothing happening
	$process = Start-Process -FilePath $exe.FullName -ArgumentList $clientArgs -WorkingDirectory $exe.Directory.FullName -PassThru
	$null = $process.Handle  # Windows PowerShell only fills in ExitCode when the handle was read

	if (-not $process.WaitForExit($STARTUP_CHECK_MS)) {
		Write-Ok "Running (pid $($process.Id))."
		return
	}

	$code = $process.ExitCode
	if ($code -eq 0) {
		Write-Label "The game exited (exit code 0)."
		return
	}

	Write-Err ("The game exited at once with exit code {0} (0x{0:X8})." -f $code)
	if ($code -eq $STATUS_INVALID_IMAGE_FORMAT) {
		Write-Err "0xC000007B: a dll next to the exe has the wrong architecture (32 vs 64-bit)."
	}
	Write-Err "See the console log: $env:APPDATA\Quake3\$BASEQ3_DIR_NAME\qconsole.log (start with +set logfile 2)."
	exit 1
}

Write-Alt "ioq3-rs..."

$exe = Resolve-ClientExe $REPO_ROOT
$baseq3Dir = Join-Path -Path $exe.Directory.FullName -ChildPath $BASEQ3_DIR_NAME

Write-Host

Sync-Baseq3 $baseq3Dir
Sync-SdlDll $exe

Write-Host

Write-Extra "$($exe.FullName) $($CLIENT_ARGS -join ' ')"
Start-Client $exe $CLIENT_ARGS
