# OS name and version plus general OS/PC info, then the PC specs: CPU, RAM,
# GPU, storage, network and battery. Everything is read through CIM (WMI) and
# the registry, no admin needed.
#
# Usage:
# .\pc_info.ps1

function Write-Ok      ([string]$m) { Write-Host $m -ForegroundColor Green }
function Write-Warn    ([string]$m) { Write-Host $m -ForegroundColor Yellow }
function Write-Info    ([string]$m) { Write-Host $m -ForegroundColor Cyan }
function Write-Section ([string]$m) { Write-Host ""; Write-Host "== $m ==" -ForegroundColor Magenta }

# width of the label column in the "label: value" lines
$LABEL_WIDTH = 18
$GB = 1GB
# the device class every display adapter is listed under in the registry
$DISPLAY_CLASS_KEY = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}"
$WINDOWS_VERSION_KEY = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"

function Write-Field ([string]$label, $value) {
    Write-Host ("  {0,-$LABEL_WIDTH}" -f "${label}:") -ForegroundColor Gray -NoNewline
    Write-Host " $value"
}

function Format-Gb ($bytes) { "{0:N1} GB" -f ($bytes / $GB) }

function Format-Uptime ([TimeSpan]$t) { "{0}d {1}h {2}m" -f $t.Days, $t.Hours, $t.Minutes }

# Win32_VideoController.AdapterRAM is a uint32 and stops at 4 GB, so read the
# 64-bit size the driver writes to its own class key, matched on the driver
# description; falls back to AdapterRAM
function Get-GpuMemory ($gpu) {
    $keys = Get-ChildItem $DISPLAY_CLASS_KEY -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -match '^\d{4}$' }
    foreach ($k in $keys) {
        $p = Get-ItemProperty $k.PSPath -ErrorAction SilentlyContinue
        if ($p.DriverDesc -eq $gpu.Name -and $p.'HardwareInformation.qwMemorySize') {
            return [uint64]$p.'HardwareInformation.qwMemorySize'
        }
    }
    return [uint64]$gpu.AdapterRAM
}

$os   = Get-CimInstance Win32_OperatingSystem
$cs   = Get-CimInstance Win32_ComputerSystem
$bios = Get-CimInstance Win32_BIOS
$board = Get-CimInstance Win32_BaseBoard
$winVer = Get-ItemProperty $WINDOWS_VERSION_KEY

# ---------------------------------------------------------------- OS
Write-Section "Operating system"
Write-Field "OS" $os.Caption
# DisplayVersion (24H2, 25H2 ...) only exists from 20H2 on; ReleaseId before that
$release = if ($winVer.DisplayVersion) { $winVer.DisplayVersion } else { $winVer.ReleaseId }
Write-Field "Version" "$release (build $($os.BuildNumber).$($winVer.UBR))"
Write-Field "Kernel version" $os.Version
Write-Field "Architecture" $os.OSArchitecture
Write-Field "Edition ID" $winVer.EditionID
Write-Field "Installed" $os.InstallDate.ToString("yyyy-MM-dd HH:mm")
Write-Field "Last boot" $os.LastBootUpTime.ToString("yyyy-MM-dd HH:mm")
Write-Field "Uptime" (Format-Uptime ((Get-Date) - $os.LastBootUpTime))
Write-Field "Firmware" $env:firmware_type
Write-Field "System dir" $os.SystemDirectory
Write-Field "Locale" (Get-Culture).Name
Write-Field "Time zone" (Get-TimeZone).DisplayName
Write-Field "PowerShell" "$($PSVersionTable.PSVersion) ($($PSVersionTable.PSEdition))"

# ---------------------------------------------------------------- PC
Write-Section "Computer"
Write-Field "Name" $env:COMPUTERNAME
Write-Field "User" "$env:USERDOMAIN\$env:USERNAME"
Write-Field $(if ($cs.PartOfDomain) { "Domain" } else { "Workgroup" }) $(if ($cs.PartOfDomain) { $cs.Domain } else { $cs.Workgroup })
Write-Field "Manufacturer" $cs.Manufacturer
Write-Field "Model" $cs.Model
Write-Field "System type" $cs.SystemType
Write-Field "Motherboard" "$($board.Manufacturer) $($board.Product)".Trim()
Write-Field "BIOS" "$($bios.Manufacturer) $($bios.SMBIOSBIOSVersion) ($($bios.ReleaseDate.ToString('yyyy-MM-dd')))"

# ---------------------------------------------------------------- CPU
Write-Section "CPU"
foreach ($cpu in Get-CimInstance Win32_Processor) {
    Write-Field "Name" "$($cpu.Name)".Trim()
    Write-Field "Cores / threads" "$($cpu.NumberOfCores) / $($cpu.NumberOfLogicalProcessors)"
    # WMI reports the base clock here, not the boost or live one
    Write-Field "Base clock" ("{0:N2} GHz" -f ($cpu.MaxClockSpeed / 1000))
    Write-Field "L2 / L3 cache" ("{0} MB / {1} MB" -f [math]::Round($cpu.L2CacheSize / 1024, 1), [math]::Round($cpu.L3CacheSize / 1024, 1))
    Write-Field "Socket" $cpu.SocketDesignation
    Write-Field "Load" "$($cpu.LoadPercentage)%"
    # reads false while Hyper-V / WSL2 already runs, since the hypervisor owns it then
    $virt = if ($cs.HypervisorPresent) { "in use (hypervisor running)" } elseif ($cpu.VirtualizationFirmwareEnabled) { "enabled" } else { "disabled" }
    Write-Field "Virtualization" $virt
}

# ---------------------------------------------------------------- RAM
Write-Section "Memory (RAM)"
$total = [uint64]$os.TotalVisibleMemorySize * 1KB
$free  = [uint64]$os.FreePhysicalMemory * 1KB
$used  = $total - $free
$modules = @(Get-CimInstance Win32_PhysicalMemory)
$slots = (Get-CimInstance Win32_PhysicalMemoryArray | Measure-Object -Property MemoryDevices -Sum).Sum
# installed is what the modules add up to; usable is that minus what the
# firmware and an integrated GPU reserve
Write-Field "Installed" (Format-Gb ($modules | Measure-Object -Property Capacity -Sum).Sum)
Write-Field "Usable" (Format-Gb $total)
Write-Field "In use" ("{0} ({1:N0}%)" -f (Format-Gb $used), ($used / $total * 100))
Write-Field "Available" (Format-Gb $free)
Write-Field "Slots used" "$($modules.Count) of $slots"
$i = 0
foreach ($m in $modules) {
    $i++
    # the configured speed is what it runs at, Speed is the module's rated speed
    $speed = if ($m.ConfiguredClockSpeed) { "$($m.ConfiguredClockSpeed) MT/s (rated $($m.Speed))" } else { "$($m.Speed) MT/s" }
    # soldered memory often gives every module the same locator, so number them
    Write-Field "  Module $i" ("{0}, {1}, {2} {3} [{4}]" -f (Format-Gb $m.Capacity), $speed, "$($m.Manufacturer)".Trim(), "$($m.PartNumber)".Trim(), "$($m.BankLabel) $($m.DeviceLocator)".Trim())
}

# ---------------------------------------------------------------- GPU
Write-Section "GPU"
foreach ($gpu in Get-CimInstance Win32_VideoController) {
    Write-Info "  $($gpu.Name)"
    Write-Field "Memory" (Format-Gb (Get-GpuMemory $gpu))
    Write-Field "Driver" "$($gpu.DriverVersion) ($($gpu.DriverDate.ToString('yyyy-MM-dd')))"
    if ($gpu.CurrentHorizontalResolution) {
        Write-Field "Mode" ("{0}x{1} @ {2} Hz" -f $gpu.CurrentHorizontalResolution, $gpu.CurrentVerticalResolution, $gpu.CurrentRefreshRate)
    }
    Write-Field "Status" $gpu.Status
}

# ---------------------------------------------------------------- storage
Write-Section "Storage"
foreach ($d in Get-PhysicalDisk -ErrorAction SilentlyContinue | Sort-Object DeviceId) {
    Write-Field "Disk $($d.DeviceId)" ("{0}, {1}, {2} {3}" -f $d.FriendlyName, (Format-Gb $d.Size), $d.MediaType, $d.BusType)
}
foreach ($v in Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3") {
    $pct = if ($v.Size) { ($v.Size - $v.FreeSpace) / $v.Size * 100 } else { 0 }
    $line = "{0} free of {1} ({2:N0}% used), {3} {4}" -f (Format-Gb $v.FreeSpace), (Format-Gb $v.Size), $pct, $v.FileSystem, $v.VolumeName
    if ($pct -ge 90) { Write-Host ("  {0,-$LABEL_WIDTH}" -f "$($v.DeviceID)") -ForegroundColor Gray -NoNewline; Write-Warn " $line" }
    else { Write-Field $v.DeviceID $line }
}

# ---------------------------------------------------------------- network
Write-Section "Network"
foreach ($a in Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object Status -eq "Up" | Sort-Object Name) {
    $ip = (Get-NetIPAddress -InterfaceIndex $a.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue | Select-Object -First 1).IPAddress
    $mac = if ($a.MacAddress) { $a.MacAddress } else { "no MAC" }
    Write-Field $a.Name ("{0}, {1}, {2}, {3}" -f $a.InterfaceDescription, $a.LinkSpeed, $mac, $(if ($ip) { $ip } else { "no IPv4" }))
}

# ---------------------------------------------------------------- battery
$batteries = @(Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue)
if ($batteries.Count) {
    Write-Section "Battery"
    foreach ($b in $batteries) {
        Write-Field $b.Name "$($b.EstimatedChargeRemaining)%"
    }
}

Write-Host ""
Write-Ok "Done."
