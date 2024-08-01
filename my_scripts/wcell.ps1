$basePath = Join-Path -Path $env:code_root_dir -ChildPath "Code2\C#\WCell\Run\Debug"

if (Test-Path $basePath) {
    $path = $basePath
} else {
    $basePath = Join-Path -Path $env:code_root_dir -ChildPath "Code2\C#\wcell_\Run\Debug"
    if (Test-Path $basePath) {
        $path = $basePath
    } elseif (Test-Path "C:\Users\jonas\Code2\C#\wcell_\Run\Debug") {
        $path = "C:\Users\jonas\Code2\C#\wcell_\Run\Debug"
    } elseif (Test-Path "D:\My files\svea_laptop\code_hdd\WCell_\Run\Debug") {
        $path = "D:\My files\svea_laptop\code_hdd\WCell_\Run\Debug"
    } elseif (Test-Path "x") {
        $path = "x"
    } else {
        #$path = "~/"
        Write-Host "Couldn't find wcell build path. Is it compiled?"
            exit 1
    }
}

cd $path

echo "$path\WCell.RealmServerConsole.exe"
#Invoke-Expression "$path\WCell.RealmServerConsole.exe"

#echo "python $path\overwrite.py; $path\WCell.RealmServerConsole.exe"
#Invoke-Expression "python $path\overwrite.py; $path\WCell.RealmServerConsole.exe"

