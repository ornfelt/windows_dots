if (Test-Path "C:\Users\jonas\source\repos\ioq3\build\release-msvc142-x86") {
    $path = "C:\Users\jonas\source\repos\ioq3\build\release-msvc142-x86"
} elseif (Test-Path "D:\My files\svea_laptop\code_hdd\ioq3\build\release-msvc142-x86") {
    $path = "D:\My files\svea_laptop\code_hdd\ioq3\build\release-msvc142-x86"
} elseif (Test-Path "x") {
	$path = "x"
} else {
    $path = "~/"
}

#C:\Users\Svea" "User\source\repos\ioq3\build\debug-msvc142-x86\ioquake3.x86.exe +set sv_pure 0 +set vm_game 0 +set vm_cgame 0 +set vm_ui 0
#C:\Users\Svea" "User\source\repos\ioq3\build\release-msvc142-x86\ioquake3.x86.exe +set sv_pure 0 +set vm_game 0 +set vm_cgame 0 +set vm_ui 0

#cd $path

echo "$path\ioquake3.x86.exe +set sv_pure 0 +set vm_game 0 +set vm_cgame 0 +set vm_ui 0"
Invoke-Expression "$path\ioquake3.x86.exe +set sv_pure 0 +set vm_game 0 +set vm_cgame 0 +set vm_ui 0"
