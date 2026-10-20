$user_arg = $args[0]

function Info($msg)    { Write-Host $msg -ForegroundColor Cyan }
function Success($msg) { Write-Host $msg -ForegroundColor Green }
function Warn($msg)    { Write-Host $msg -ForegroundColor Yellow }
function Err($msg)     { Write-Host $msg -ForegroundColor Red }

$WORLD_PORT = 8085
$REALM_PORT = 3724
$WORLD_PROCS = @("mangosd", "worldserver")
$REALM_PROCS = @("realmd", "authserver")

# Server binary path patterns -> name and expansion (tbc checked before plain cmangos)
# The local checkouts don't carry the server name: vmangos is Code2\C++\core, MangosZero Code2\C++\server
$SERVER_TYPES = @(
    @{ Patterns = @("*cmangos-tbc*", "*mangos-tbc*");               Name = "mangos-tbc";     Expansion = "tbc" },
    @{ Patterns = @("*mangoszero*", "*mangos-zero*", "*\Code2\C++\server\*"); Name = "mangoszero"; Expansion = "classic" },
    @{ Patterns = @("*vmangos*", "*\Code2\C++\core\*");             Name = "vmangos";        Expansion = "classic" },
    @{ Patterns = @("*cmangos*", "*mangos-classic*");               Name = "mangos-classic"; Expansion = "classic" },
    @{ Patterns = @("*acore*", "*azerothcore*");                    Name = "azerothcore";    Expansion = "wotlk" },
    @{ Patterns = @("*tcore*", "*trinitycore*", "*trinity*");       Name = "trinitycore";    Expansion = "wotlk" }
)

function Get-ServerType($exe) {
    if (-not $exe) { return $null }
    foreach ($type in $SERVER_TYPES) {
        foreach ($pattern in $type.Patterns) {
            if ($exe -like $pattern) { return $type }
        }
    }
    return $null
}

# Resolve a pid to its binary path; Path is empty for elevated processes, so fall back to CIM
function Get-PidExe($id) {
    $proc = Get-Process -Id $id -ErrorAction SilentlyContinue
    if ($proc -and $proc.Path) { return $proc.Path }
    $cim = Get-CimInstance Win32_Process -Filter "ProcessId = $id" -ErrorAction SilentlyContinue
    if ($cim -and $cim.ExecutablePath) { return $cim.ExecutablePath }
    if ($cim) { return $cim.CommandLine }
    return $null
}

function Test-PortOpen($port) {
    $client = New-Object Net.Sockets.TcpClient
    try { return $client.ConnectAsync("127.0.0.1", $port).Wait(1000) } catch { return $false } finally { $client.Close() }
}

# Candidate pids: server processes by name plus whatever listens on the world/realm ports
$server_pids = @(Get-Process -Name ($WORLD_PROCS + $REALM_PROCS) -ErrorAction SilentlyContinue | ForEach-Object { $_.Id })
$server_pids += @(Get-NetTCPConnection -State Listen -LocalPort $WORLD_PORT, $REALM_PORT -ErrorAction SilentlyContinue | ForEach-Object { $_.OwningProcess })
$server_pids = @($server_pids | Sort-Object -Unique)

$server_name = $null
$server_expansion = $null
foreach ($id in $server_pids) {
    $type = Get-ServerType (Get-PidExe $id)
    if (-not $type) { continue }
    # A world server decides the expansion; a realm server only if no world server is found
    $proc_name = (Get-Process -Id $id -ErrorAction SilentlyContinue).ProcessName
    if (($WORLD_PROCS -contains $proc_name) -or -not $server_name) {
        $server_name = $type.Name
        $server_expansion = $type.Expansion
    }
}

$world_up = Test-PortOpen $WORLD_PORT
$realm_up = Test-PortOpen $REALM_PORT

if ($server_name) {
    Success "$server_name server is running ($server_expansion) - world port ${WORLD_PORT}: $world_up, realm port ${REALM_PORT}: $realm_up"
} elseif ($world_up -or $realm_up) {
    Warn "A server is listening (world port ${WORLD_PORT}: $world_up, realm port ${REALM_PORT}: $realm_up) but its type is unknown"
} else {
    Err "No server is running"
}

# No client given: pick the one matching the running server
if (-not $user_arg -and $server_expansion) {
    $user_arg = $server_expansion
    Info "Using the $user_arg client for $server_name"
}

if ($user_arg -ieq "classic" -or $user_arg -ieq "c") {
    if ($env:wow_classic_dir -and (Test-Path $env:wow_classic_dir)) {
        $path = $env:wow_classic_dir
    } elseif (Test-Path "C:\Users\jonas\OneDrive\Documents\Games\wow_classic") {
		$path = "C:\Users\jonas\OneDrive\Documents\Games\wow_classic"
	} elseif (Test-Path "D:\My files\wow_classic") {
		$path = "D:\My files\wow_classic"
	} elseif (Test-Path "C:\Users\jonas\Downloads\wow_classic") {
		$path = "C:\Users\jonas\Downloads\wow_classic"
	} else {
		$path = "~/"
	}

	#cd $path
	echo "$path/Wow.exe"

	#Invoke-Expression "& '$path\Wow.exe'"
	$path = $path -replace ' ','` '
	Invoke-Expression "$path/WoW.exe"

} elseif ($user_arg -ieq "tbc" -or $user_arg -ieq "t") {
    if ($env:wow_tbc_dir -and (Test-Path $env:wow_tbc_dir)) {
        $path = $env:wow_tbc_dir
	} else {
		$path = "~/"
	}

	#cd $path
	echo "$path/Wow.exe"

	#Invoke-Expression "& '$path\Wow.exe'"
	$path = $path -replace ' ','` '
	Invoke-Expression "$path/WoW.exe"

} elseif ($user_arg -ieq "cata") {
    if ($env:wow_cata_dir -and (Test-Path $env:wow_cata_dir)) {
        $path = $env:wow_cata_dir
	} else {
		$path = "~/"
	}

	#cd $path
	echo "$path/Wow.exe"

	#Invoke-Expression "& '$path\Wow.exe'"
	$path = $path -replace ' ','` '
	Invoke-Expression "$path/WoW.exe"

} else {
    # wotlk
	if (Test-Path "C:\Users\jonas\OneDrive\Documents\Games\wow") {
		$path = "C:\Users\jonas\OneDrive\Documents\Games\wow"
	} elseif (Test-Path "D:\My files\World of Warcraft 3.3.5a") {
		$path = "D:\My files\World of Warcraft 3.3.5a"
	} elseif (Test-Path "C:\Users\jonas\Downloads\wow") {
		$path = "C:\Users\jonas\Downloads\wow"
	} else {
		$path = "~/"
	}

	#cd $path
	echo "$path/Wow.exe"

	#Invoke-Expression "& '$path\Wow.exe'"
	$path = $path -replace ' ','` '
	Invoke-Expression "$path/Wow.exe"
}

