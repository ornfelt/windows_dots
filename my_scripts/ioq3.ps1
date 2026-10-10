function Write-Label($text) { Write-Host "$text" -ForegroundColor DarkGray }
function Write-Alt  ($text) { Write-Host "$text" -ForegroundColor Magenta  }
function Write-Extra($text) { Write-Host "$text" -ForegroundColor Blue     }
function Write-Warn ($text) { Write-Host "$text" -ForegroundColor DarkYellow }
function Write-Ok   ($text) { Write-Host "$text" -ForegroundColor Green    }
function Write-Err  ($text) { Write-Host "$text" -ForegroundColor Red      }

# When true, missing pk3 files are copied from the HDD without asking first
$AUTO_COPY_DATA = $false

# Build dirs are searched for these config folders; the newest ioquake3 exe wins
# (old builds: ioquake3.x86_64.exe / ioquake3.x86.exe, CMake builds: ioquake3.exe)
$REPO_ROOT = Join-Path -Path $env:code_root_dir -ChildPath "Code2/C/ioq3"
$BUILD_DIR_PATTERN = "build*"
$CONFIG_DIR_PATTERNS = @("*release*", "*relwithdebinfo*", "*debug*")
$CONFIG_SEARCH_DEPTH = 3
$CLIENT_EXE_PATTERN = "ioquake3*.exe"
$BUILD_TIME_FORMAT = "yyyy-MM-dd HH:mm:ss"
$CLIENT_ARGS = @("+set", "sv_pure", "0", "+set", "vm_game", "0", "+set", "vm_cgame", "0", "+set", "vm_ui", "0")

# Game data: <exe dir>/baseq3 needs these, copied from <any drive>/2024/baseq3 when missing
$BASEQ3_DIR_NAME = "baseq3"
$HDD_BASEQ3_SUBPATH = "2024/$BASEQ3_DIR_NAME"
$PK3_PATTERN = "*.pk3"
$REQUIRED_PK3S = 0..8 | ForEach-Object { "pak$_.pk3" }

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

function Resolve-ClientExe($repoRoot) {
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

function Find-HddBaseq3 {
	# First <drive>:/2024/baseq3 that holds every required pk3
	foreach ($drive in (Get-PSDrive -PSProvider FileSystem | Sort-Object Name)) {
		$candidate = Join-Path -Path $drive.Root -ChildPath $HDD_BASEQ3_SUBPATH
		if (-not (Test-Path -Path $candidate -PathType Container)) { continue }

		$missing = Get-MissingFiles $candidate $REQUIRED_PK3S
		if ($missing.Count -eq 0) {
			Write-Ok "Found baseq3 data on drive: $candidate"
			return $candidate
		}
		Write-Warn "$candidate is missing $($missing -join ', ') - skipping it."
	}

	return $null
}

function Confirm-Copy($question) {
	if ($AUTO_COPY_DATA) {
		Write-Label "AUTO_COPY_DATA is set - copying without asking."
		return $true
	}
	$answer = Read-Host "$question [y/N]"
	return ($answer -ieq "y" -or $answer -ieq "yes")
}

function Sync-Baseq3($baseq3Dir) {
	# Copies the HDD's missing pk3 files into baseq3 (after one confirmation), then checks
	# the required ones. Exits when a required pk3 is still missing.
	$hddBaseq3 = Find-HddBaseq3

	if ($hddBaseq3) {
		$sourceNames = @(Get-ChildItem -Path $hddBaseq3 -File -Filter $PK3_PATTERN | Select-Object -ExpandProperty Name)
		$toCopy = Get-MissingFiles $baseq3Dir $sourceNames

		foreach ($name in ($sourceNames | Where-Object { $toCopy -notcontains $_ })) {
			Write-Ok "$name already exists in $baseq3Dir, skipping."
		}

		if ($toCopy.Count -gt 0) {
			Write-Warn "$($toCopy.Count) pk3 file(s) missing from ${baseq3Dir}: $($toCopy -join ', ')"

			if (Confirm-Copy "Copy them from ${hddBaseq3}?") {
				if (-not (Test-Path $baseq3Dir)) { New-Item -ItemType Directory -Path $baseq3Dir | Out-Null }

				foreach ($name in $toCopy) {
					$source = Join-Path -Path $hddBaseq3 -ChildPath $name
					try {
						Copy-Item -Path $source -Destination $baseq3Dir -ErrorAction Stop
						Write-Ok "Copied $name -> $baseq3Dir"
					} catch {
						Write-Err "Could not copy $source -> ${baseq3Dir}: $($_.Exception.Message)"
					}
				}
			} else {
				Write-Warn "Skipped copying."
			}
		}
	} else {
		Write-Warn "No mounted drive has a valid $HDD_BASEQ3_SUBPATH (needs $($REQUIRED_PK3S -join ', '))."
	}

	$stillMissing = Get-MissingFiles $baseq3Dir $REQUIRED_PK3S
	if ($stillMissing.Count -gt 0) {
		Write-Err "Required file(s) missing from ${baseq3Dir}: $($stillMissing -join ', ')"
		if (-not $hddBaseq3) {
			Write-Err "Plug in / map a drive with $HDD_BASEQ3_SUBPATH holding them, or copy them in by hand."
		}
		exit 1
	}

	Write-Ok "All $($REQUIRED_PK3S.Count) required pk3 files found in $baseq3Dir."
}

Write-Alt "ioq3..."

$exe = Resolve-ClientExe $REPO_ROOT
$baseq3Dir = Join-Path -Path $exe.Directory.FullName -ChildPath $BASEQ3_DIR_NAME

Write-Host

Sync-Baseq3 $baseq3Dir

Write-Host

Write-Extra "$($exe.FullName) $($CLIENT_ARGS -join ' ')"
& $exe.FullName @CLIENT_ARGS
