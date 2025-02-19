$mappedDrives = Get-WmiObject -Class Win32_LogicalDisk -Filter "DriveType=4"

if ($mappedDrives) {
    $mappedDrives | Select-Object `
        DeviceID,          # The drive letter (e.g., H:)
        ProviderName,      # The UNC path the drive is mapped to (e.g., \\server\share)
        VolumeName,        # The volume label
        @{Name="FreeSpace(GB)"; Expression={[math]::Round($_.FreeSpace/1GB,2)}},
        @{Name="Size(GB)"; Expression={[math]::Round($_.Size/1GB,2)}}
} else {
    Write-Host "No mapped network drives found."
}

# For debugging:
# You can try to Test-Connection {path} or ping {path} where path is the server, like seusers.ia.corp.xxx.com
# or do Test-Path {path} wher path is the mapped UNC path

