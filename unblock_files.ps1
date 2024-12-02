Get-ChildItem -Path . -Recurse | ForEach-Object {
    if ($_ -is [System.IO.FileInfo]) {
        Unblock-File -Path $_.FullName
    }
}

# One-liner:
#Get-ChildItem -Path . -Recurse -File | Unblock-File

