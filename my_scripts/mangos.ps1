function Write-Label($text) { Write-Host "$text" -ForegroundColor DarkGray }
#function Write-Cmd  ($text) { Write-Host "$text" -ForegroundColor Cyan     }
function Write-Alt  ($text) { Write-Host "$text" -ForegroundColor Magenta  }
function Write-Extra($text) { Write-Host "$text" -ForegroundColor Blue     }
function Write-Warn ($text) { Write-Host "$text" -ForegroundColor DarkYellow }
function Write-Ok   ($text) { Write-Host "$text" -ForegroundColor Green    }
function Write-Err  ($text) { Write-Host "$text" -ForegroundColor Red      }

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
	$basePath = Join-Path -Path $env:code_root_dir -ChildPath "Code2/C++/server/build/src/mangosd/RelWithDebInfo"
	$altBasePath = Join-Path -Path $env:code_root_dir -ChildPath "Code2/C++/mangoszero/server/build/src/mangosd/RelWithDebInfo"

	if (Test-Path $basePath) {
		$path = $basePath
		Write-Label "Using primary path: $path"
    } elseif (Test-Path $altBasePath) {
		$path = $altBasePath
		Write-Label "Using alternative path: $path"
	} else {
		$path = "~/mangoszero/bin"
		Write-Warn "Local build paths were not found. Using fallback path: $path"
	}

# Cmangos
} elseif ($server -ieq "c") {
	Write-Alt "Cmangos chosen..."
	$basePath = Join-Path -Path $env:code_root_dir -ChildPath "Code2/C++/mangos-classic/build/bin/x64_RelWithDebInfo"
	$altBasePath = Join-Path -Path $env:code_root_dir -ChildPath "Code2/C++/cmangos/mangos-classic/build/bin/x64_RelWithDebInfo"

	if (Test-Path $basePath) {
		$path = $basePath
		Write-Label "Using primary path: $path"
    } elseif (Test-Path $altBasePath) {
		$path = $altBasePath
		Write-Label "Using alternative path: $path"
	} else {
		$path = "~/cmangos/run/bin"
		Write-Warn "Local build paths were not found. Using fallback path: $path"
	}

} elseif ($server -ieq "tbc") {
	Write-Alt "Cmangos tbc chosen..."
	$basePath = Join-Path -Path $env:code_root_dir -ChildPath "Code2/C++/mangos-tbc/build/bin/x64_RelWithDebInfo"

	if (Test-Path $basePath) {
		$path = $basePath
		Write-Label "Using path: $path"
    } else {
        Write-Warn "Base path does not exist: $basePath"
        exit 1
    }

# Default to Vmangos
} else {
	Write-Alt "Vmangos chosen..."
	$basePath = Join-Path -Path $env:code_root_dir -ChildPath "Code2/C++/core/bin/RelWithDebInfo"
	$altBasePath = Join-Path -Path $env:code_root_dir -ChildPath "Code2/C++/vmangos/core/bin/RelWithDebInfo"
	
	if (Test-Path $basePath) {
		$path = $basePath
		Write-Label "Using primary path: $path"
    } elseif (Test-Path $altBasePath) {
		$path = $altBasePath
		Write-Label "Using alternative path: $path"
	} else {
		$path = "~/vmangos/bin"
		Write-Warn "Local build paths were not found. Using fallback path: $path"
	}
}

cd $path

Write-Label "Current directory: $path"

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
