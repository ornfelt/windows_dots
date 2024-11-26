#cd ~

$basePath = Join-Path -Path $HOME -ChildPath "Documents\my_notes"
if (Test-Path $basePath) {
    $path = $basePath
} elseif (Test-Path "C:\Users\jonas\OneDrive\Documents\my_notes") {
	$path = "C:\Users\jonas\OneDrive\Documents\my_notes"
} elseif (Test-Path "C:\ornfelt\my_notes") {
	$path = "C:\ornfelt\my_notes"
} else {
	$path = "~/"
}

cd $path

