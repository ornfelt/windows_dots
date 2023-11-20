Get-ChildItem -Path 'C:\Users\Svea User\Documents\code' -Recurse -Force -File |
    Select-Object -Property FullName `
        ,@{Name='SizeGB';Expression={$_.Length / 1GB}} `
        ,@{Name='SizeMB';Expression={$_.Length / 1MB}} `
        ,@{Name='SizeKB';Expression={$_.Length / 1KB}} |
    Sort-Object { $_.SizeKB } -Descending |
    Out-GridView