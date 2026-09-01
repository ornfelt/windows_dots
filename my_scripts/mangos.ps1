function Write-Label($text) { Write-Host "$text" -ForegroundColor DarkGray }
#function Write-Cmd  ($text) { Write-Host "$text" -ForegroundColor Cyan     }
function Write-Alt  ($text) { Write-Host "$text" -ForegroundColor Magenta  }
function Write-Extra($text) { Write-Host "$text" -ForegroundColor Blue     }
function Write-Warn ($text) { Write-Host "$text" -ForegroundColor DarkYellow }
function Write-Ok   ($text) { Write-Host "$text" -ForegroundColor Green    }
function Write-Err  ($text) { Write-Host "$text" -ForegroundColor Red      }

# Build dirs are searched for these config folders; the newest mangosd.exe wins
$BUILD_DIR_PATTERN = "build*"
$BIN_DIR_NAME = "bin"
$CONFIG_DIR_PATTERNS = @("*release*", "*relwithdebinfo*", "*debug*")
$CONFIG_SEARCH_DEPTH = 3
$SERVER_EXE = "mangosd.exe"
$BUILD_TIME_FORMAT = "yyyy-MM-dd HH:mm:ss"

# Data dirs each server needs next to its exe
$VMANGOS_REQUIRED_DIRS        = @("5875", "Cameras", "maps", "mmaps", "vmaps")
$MANGOS_CLASSIC_REQUIRED_DIRS = @("Cameras", "dbc", "maps", "mmaps", "vmaps")
$MANGOS_TBC_REQUIRED_DIRS     = @("Buildings", "Cameras", "dbc", "maps")
$MANGOSZERO_REQUIRED_DIRS     = @("dbc", "maps", "mmaps", "vmaps")

# Reported but not treated as an error - older mangos-tbc builds ran without these
$MANGOS_TBC_OPTIONAL_DIRS     = @("mmaps", "vmaps")
$NO_OPTIONAL_DIRS             = @()

function Find-ServerBuilds($repoRoots) {
	# Every <root>/build*/**/<config>/mangosd.exe and <root>/bin/**/<config>/mangosd.exe,
	# newest build first.
	$found = New-Object System.Collections.Generic.List[object]

	foreach ($root in $repoRoots) {
		if (-not (Test-Path $root)) { continue }

		$searchRoots = Get-ChildItem -Path $root -Directory -ErrorAction SilentlyContinue |
			Where-Object { $_.Name -like $BUILD_DIR_PATTERN -or $_.Name -ieq $BIN_DIR_NAME }

		foreach ($searchRoot in $searchRoots) {
			$dirs = Get-ChildItem -Path $searchRoot.FullName -Directory -Recurse -Depth $CONFIG_SEARCH_DEPTH -ErrorAction SilentlyContinue

			foreach ($dir in $dirs) {
				$isConfigDir = $false
				foreach ($pattern in $CONFIG_DIR_PATTERNS) {
					if ($dir.Name -like $pattern) { $isConfigDir = $true; break }
				}
				if (-not $isConfigDir) { continue }

				$exePath = Join-Path -Path $dir.FullName -ChildPath $SERVER_EXE
				if (Test-Path $exePath) { $found.Add((Get-Item $exePath)) }
			}
		}
	}

	if ($found.Count -eq 0) { return $null }
	return $found.ToArray() | Sort-Object LastWriteTime -Descending
}

function Resolve-ServerPath($repoRoots, $fallbackPath) {
	$builds = Find-ServerBuilds $repoRoots

	if ($builds) {
		$newest = $builds[0]
		Write-Label "Using newest build: $($newest.Directory.FullName)"
		Write-Label "  $SERVER_EXE built $($newest.LastWriteTime.ToString($BUILD_TIME_FORMAT))"

		foreach ($older in ($builds | Select-Object -Skip 1)) {
			Write-Label "  (older: $($older.Directory.FullName) - $($older.LastWriteTime.ToString($BUILD_TIME_FORMAT)))"
		}

		return $newest.Directory.FullName
	}

	if ($fallbackPath) {
		Write-Warn "No $SERVER_EXE was found in the local build dirs. Using fallback path: $fallbackPath"
		return $fallbackPath
	}

	Write-Err "No $SERVER_EXE was found under: $($repoRoots -join ', ')"
	exit 1
}

function Test-RequiredDirs($path, $requiredDirs, $optionalDirs) {
	$missing = New-Object System.Collections.Generic.List[string]

	foreach ($dirName in $requiredDirs) {
		if (Test-Path -Path (Join-Path -Path $path -ChildPath $dirName) -PathType Container) {
			Write-Ok "$dirName/ found."
		} else {
			Write-Err "$dirName/ is missing from $path"
			$missing.Add($dirName)
		}
	}

	foreach ($dirName in $optionalDirs) {
		if (Test-Path -Path (Join-Path -Path $path -ChildPath $dirName) -PathType Container) {
			Write-Ok "$dirName/ found."
		} else {
			Write-Warn "$dirName/ is missing - optional, older builds did not need it."
		}
	}

	if ($missing.Count -gt 0) {
		Write-Warn "$($missing.Count) of $($requiredDirs.Count) required dir(s) missing: $($missing.ToArray() -join ', ')"
	}
}

function Test-DisabledSetting($lines, $setting, $fileName, $clientName) {
	$pattern = '^\s*' + [regex]::Escape($setting) + '\s*=\s*([^\s#]+)'

	foreach ($line in $lines) {
		if ($line -match $pattern) {
			$value = $matches[1]

			if ($value -eq "0") {
				Write-Ok "$setting = 0 in $fileName - correctly disabled."
			} elseif ($value -eq "1") {
				Write-Err "$setting = 1 in $fileName - it needs to be disabled to use custom clients like $clientName."
			} else {
				Write-Warn "$setting has unexpected value '$value' in $fileName."
			}

			return
		}
	}

	Write-Warn "$setting was not found in $fileName."
}

$server = $args[0]

# MangosZero
if ($server -ieq "0" -or $server -ieq "z") {
	Write-Alt "MangosZero chosen..."
	$repoRoots = @(
		(Join-Path -Path $env:code_root_dir -ChildPath "Code2/C++/server"),
		(Join-Path -Path $env:code_root_dir -ChildPath "Code2/C++/mangoszero/server")
	)
	$fallbackPath = "~/mangoszero/bin"
	$requiredDirs = $MANGOSZERO_REQUIRED_DIRS
	$optionalDirs = $NO_OPTIONAL_DIRS

# Cmangos
} elseif ($server -ieq "c") {
	Write-Alt "Cmangos chosen..."
	$repoRoots = @(
		(Join-Path -Path $env:code_root_dir -ChildPath "Code2/C++/mangos-classic"),
		(Join-Path -Path $env:code_root_dir -ChildPath "Code2/C++/cmangos/mangos-classic")
	)
	$fallbackPath = "~/cmangos/run/bin"
	$requiredDirs = $MANGOS_CLASSIC_REQUIRED_DIRS
	$optionalDirs = $NO_OPTIONAL_DIRS

} elseif ($server -ieq "tbc") {
	Write-Alt "Cmangos tbc chosen..."
	$repoRoots = @(
		(Join-Path -Path $env:code_root_dir -ChildPath "Code2/C++/mangos-tbc"),
		(Join-Path -Path $env:code_root_dir -ChildPath "Code2/C++/cmangos/mangos-tbc")
	)
	$fallbackPath = $null
	$requiredDirs = $MANGOS_TBC_REQUIRED_DIRS
	$optionalDirs = $MANGOS_TBC_OPTIONAL_DIRS

# Default to Vmangos
} else {
	Write-Alt "Vmangos chosen..."
	$repoRoots = @(
		(Join-Path -Path $env:code_root_dir -ChildPath "Code2/C++/core"),
		(Join-Path -Path $env:code_root_dir -ChildPath "Code2/C++/vmangos/core")
	)
	$fallbackPath = "~/vmangos/bin"
	$requiredDirs = $VMANGOS_REQUIRED_DIRS
	$optionalDirs = $NO_OPTIONAL_DIRS
}

$path = Resolve-ServerPath $repoRoots $fallbackPath

cd $path

Write-Label "Current directory: $path"

Write-Host

Test-RequiredDirs $path $requiredDirs $optionalDirs

if ($server -ieq "tbc") {
    Write-Host

	if (Test-Path "anticheat.conf") {
		$anticheatLines = Get-Content "anticheat.conf"

		$anticheatSection = -1
		for ($i = 0; $i -lt $anticheatLines.Count; $i++) {
			if ($anticheatLines[$i] -match '^\s*\[AnticheatConf\]') {
				$anticheatSection = $i
				break
			}
		}

		if ($anticheatSection -eq -1) {
			Write-Warn "[AnticheatConf] was not found in anticheat.conf."
		} else {
			$sectionLines = $anticheatLines | Select-Object -Skip ($anticheatSection + 1) -First 20
			Test-DisabledSetting $sectionLines "Enable" "anticheat.conf" "wow_client (wc)"
		}

		Test-DisabledSetting $anticheatLines "Warden.Enable" "anticheat.conf" "wow_client (wc)"
	} else {
		Write-Label "anticheat.conf was not found."
	}

	if (Test-Path "realmd.conf") {
		$realmdLines = Get-Content "realmd.conf"
		Test-DisabledSetting $realmdLines "StrictVersionCheck" "realmd.conf" "wow_client (wc)"
	} else {
		Write-Warn "realmd.conf was not found."
	}
} elseif ($server -ine "0" -and $server -ine "z" -and $server -ine "c") {
    Write-Host

	if (Test-Path "realmd.conf") {
		$realmdLines = Get-Content "realmd.conf"
		Test-DisabledSetting $realmdLines "StrictVersionCheck" "realmd.conf" "benilla"
	} else {
		Write-Warn "realmd.conf was not found."
	}
}

Write-Host

#echo "$path/mangosd.exe"
#Invoke-Expression "$path/realmd.exe;"

Write-Extra "$path/realmd.exe; $path/mangosd.exe"
#Invoke-Expression "$path\mangosd.exe"
