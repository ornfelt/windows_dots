$basePath = Join-Path -Path $env:code_root_dir -ChildPath "Code2\C\ioq3\build\release-mingw32-x86_64"


if (Test-Path $basePath) {
    $path = $basePath
} elseif (Test-Path (Join-Path -Path $env:code_root_dir -ChildPath "Code2\C\ioq3\build\release-msvc142-x86"))
	$path = (Join-Path -Path $env:code_root_dir -ChildPath "Code2\C\ioq3\build\release-msvc142-x86")
} elseif (Test-Path "C:\Users\jonas\source\repos\ioq3\build\release-msvc142-x86") {
    $path = "C:\Users\jonas\source\repos\ioq3\build\release-msvc142-x86"
} elseif (Test-Path "D:\My files\svea_laptop\code_hdd\ioq3\build\release-msvc142-x86") {
    $path = "D:\My files\svea_laptop\code_hdd\ioq3\build\release-msvc142-x86"
} else {
    $path = "~/"
}

#C:\Users\Svea" "User\source\repos\ioq3\build\debug-msvc142-x86\ioquake3.x86.exe +set sv_pure 0 +set vm_game 0 +set vm_cgame 0 +set vm_ui 0
#C:\Users\Svea" "User\source\repos\ioq3\build\release-msvc142-x86\ioquake3.x86.exe +set sv_pure 0 +set vm_game 0 +set vm_cgame 0 +set vm_ui 0

#cd $path

# The -match operator in PowerShell is case-insensitive by default
if ($path -match "x86_64") {
    echo "$path\ioquake3.x86_64.exe +set sv_pure 0 +set vm_game 0 +set vm_cgame 0 +set vm_ui 0"
	Invoke-Expression "$path\ioquake3.x86_64.exe +set sv_pure 0 +set vm_game 0 +set vm_cgame 0 +set vm_ui 0"
} else {
    echo "$path\ioquake3.x86.exe +set sv_pure 0 +set vm_game 0 +set vm_cgame 0 +set vm_ui 0"
	Invoke-Expression "$path\ioquake3.x86.exe +set sv_pure 0 +set vm_game 0 +set vm_cgame 0 +set vm_ui 0"
}

