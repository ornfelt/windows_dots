function Write-Label($text) { Write-Host "$text" -ForegroundColor DarkGray }
#function Write-Cmd  ($text) { Write-Host "$text" -ForegroundColor Cyan     }
function Write-Alt  ($text) { Write-Host "$text" -ForegroundColor Magenta  }
function Write-Extra($text) { Write-Host "$text" -ForegroundColor Blue     }
function Write-Warn ($text) { Write-Host "$text" -ForegroundColor DarkYellow }

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

#echo "$path/mangosd.exe"
#Invoke-Expression "$path/realmd.exe;"

Write-Extra "$path/realmd.exe; $path/mangosd.exe"
#Invoke-Expression "$path\mangosd.exe"

