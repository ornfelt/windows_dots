# Get the ARP table
$arpTable = arp -a

# Split the output into lines
$lines = $arpTable -split "\r?\n"

# Filter out irrelevant lines and parse the remaining ones
$devices = $lines | Where-Object { $_ -match "(\d{1,3}(\.\d{1,3}){3})\s+([\da-fA-F-]{17})" } | ForEach-Object {
    $parts = $_ -split "\s+", 0, "simplematch"
    $ip = $parts[0]

    # Attempt to get the DNS name using nslookup
    $nslookupOutput = nslookup $ip
    $nameLine = $nslookupOutput | Select-String "Name:\s+"
    $name = if ($nameLine -ne $null) { ($nameLine -split ":")[1].Trim() } else { "Unknown" }

    [PSCustomObject]@{
        IP = $ip
        MAC = $parts[1]
        Name = $name
    }
}

# Display the results
$devices | Format-Table -AutoSize
