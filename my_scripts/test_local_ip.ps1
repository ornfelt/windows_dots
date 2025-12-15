param(
    [switch]$VerboseDetails
)

# Example usage:
#.\test_local_ip.ps1
#.\test_local_ip.ps1 -VerboseDetails

function Get-LocalIPv4-Verbose {
    Write-Host "=== Get-LocalIPv4 (verbose) ==="

    # Branch 1: Get-NetIPAddress
    if (Get-Command Get-NetIPAddress -ErrorAction SilentlyContinue) {
        Write-Host "[Branch] Using Get-NetIPAddress"

        $candidates = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
            Where-Object {
                $_.IPAddress -ne '127.0.0.1' -and
                $_.IPAddress -notlike '169.254.*' -and
                $_.ValidLifetime -ne ([TimeSpan]::Zero) -and
                $_.InterfaceOperationalStatus -eq 'Up'
            } |
            Sort-Object SkipAsSource, InterfaceMetric

        if ($VerboseDetails) {
            Write-Host "[Info] Candidates after filtering/sorting:"
            $candidates |
                Select-Object IPAddress, InterfaceAlias, InterfaceMetric, SkipAsSource, AddressState, PrefixOrigin |
                Format-Table -AutoSize | Out-String | Write-Host
        }

        $ip = $candidates | Select-Object -First 1 -ExpandProperty IPAddress

        if ($ip) {
            Write-Host "[Return] $ip"
            Write-Host "[From]   Branch: Get-NetIPAddress"
            return $ip
        }

        Write-Host "[Info]  Get-NetIPAddress branch found no suitable IPs, falling back..."
    }
    else {
        Write-Host "[Info]  Get-NetIPAddress not available, falling back to .NET DNS..."
    }

    # Branch 2: .NET DNS fallback
    Write-Host "[Branch] Using .NET DNS host entry fallback"

    $hostEntry = [System.Net.Dns]::GetHostEntry([System.Net.Dns]::GetHostName())

    if ($VerboseDetails) {
        Write-Host "[Info]  All IPv4 addresses from DNS host entry (pre-filter):"
        $hostEntry.AddressList |
            Where-Object { $_.AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork } |
            ForEach-Object { $_.IPAddressToString } |
            ForEach-Object { "  - $_" } | Write-Host
    }

    foreach ($addr in $hostEntry.AddressList) {
        if ($addr.AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork) {
            $ipStr = $addr.IPAddressToString
            if ($ipStr -ne '127.0.0.1' -and $ipStr -notlike '169.254.*') {
                Write-Host "[Return] $ipStr"
                Write-Host "[From]   Branch: .NET DNS fallback"
                return $ipStr
            }
            elseif ($VerboseDetails) {
                Write-Host "[Skip]  $ipStr (loopback or link-local)"
            }
        }
    }

    Write-Host "[Return] 127.0.0.1"
    Write-Host "[From]   Branch: default"
    return '127.0.0.1'
}

# Run
$ip = Get-LocalIPv4-Verbose
Write-Host "=== Final IP: $ip ==="
