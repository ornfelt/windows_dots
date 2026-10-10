# Windows version of hash_pc.sh: hashes the CPU and GPU model names into a short
# hardware hash (first 10 hex chars of sha256).
# Note: the CPU/GPU names differ from what lscpu/lspci report on Linux, so the
# same PC gets a different hash on Windows than with hash_pc.sh.
#
# Usage:
# .\hash_pc.ps1

function Write-Ok     ([string]$m) { Write-Host $m -ForegroundColor Green }
function Write-Err    ([string]$m) { Write-Host $m -ForegroundColor Red }
function Write-Info   ([string]$m) { Write-Host $m -ForegroundColor Cyan }

# Include the MachineGuid in the hash to make it per machine (not just per
# CPU/GPU model) - note that the MachineGuid changes on an OS reinstall
$include_machine_id = $false

# Windows equivalent of /etc/machine-id, readable without admin
$MachineGuidKey = "HKLM:\SOFTWARE\Microsoft\Cryptography"

# Function to get CPU info (equivalent of the lscpu 'Model name')
function Get-CpuInfo {
    $cpu = Get-CimInstance -ClassName Win32_Processor | Select-Object -First 1
    return "$($cpu.Name)".Trim()
}

# Function to get GPU info (equivalent of the first VGA/3D line from lspci).
# Only PCI devices, like lspci - skips virtual adapters (remote desktop,
# Parsec, ...) - sorted by device id so the pick is stable.
function Get-GpuInfo {
    $gpu = Get-CimInstance -ClassName Win32_VideoController |
        Where-Object { $_.PNPDeviceID -like "PCI\*" } |
        Sort-Object PNPDeviceID |
        Select-Object -First 1
    return "$($gpu.Name)".Trim()
}

# Same as: echo -n "$combined_info" | sha256sum | cut -c1-10
function Get-ShortHash ([string]$text) {
    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    $bytes = $sha256.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($text))
    $hex = [System.BitConverter]::ToString($bytes).Replace("-", "").ToLower()
    return $hex.Substring(0, 10)
}

Write-Info "Using CIM (WMI) for retrieving hardware info:"
$cpu_info = Get-CpuInfo
$gpu_info = Get-GpuInfo

# Print CPU and GPU info
Write-Host "CPU: $cpu_info"
Write-Host "GPU: $gpu_info"
if (-not $cpu_info -or -not $gpu_info) {
    Write-Err "Could not read the CPU and/or GPU name - the hash will not be reliable."
}

# Combine and hash the information
$combined_info = "${cpu_info}_${gpu_info}"
if ($include_machine_id) {
    $machine_id = (Get-ItemProperty -Path $MachineGuidKey -Name MachineGuid).MachineGuid
    Write-Host "Machine ID: $machine_id"
    $combined_info = "${combined_info}_${machine_id}"
}
$hash = Get-ShortHash $combined_info

Write-Ok "Unique hardware hash: $hash"
