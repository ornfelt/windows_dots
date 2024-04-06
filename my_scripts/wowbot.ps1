$userProfile = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::UserProfile)

# Check if the script is running with administrative privileges
if (-Not ([System.Security.Principal.WindowsPrincipal] [System.Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([System.Security.Principal.WindowsBuiltInRole] "Administrator")) {
    # Relaunch the script as an administrator
	#Start-Process powershell.exe -ArgumentList " -NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Start-Process wt.exe -ArgumentList "-d `"$userProfile`"" -Verb RunAs
    exit
}

$base_dir = [System.Environment]::GetEnvironmentVariable("code_root_dir", [System.EnvironmentVariableTarget]::User)

# If the user-level environment variable is not set, check the machine-level environment variable
if ([string]::IsNullOrWhiteSpace($base_dir)) {
    $base_dir = [System.Environment]::GetEnvironmentVariable("code_root_dir", [System.EnvironmentVariableTarget]::Machine)
}

if ([string]::IsNullOrWhiteSpace($base_dir)) {
    $base_dir = $env:code_root_dir
}

if ([string]::IsNullOrWhiteSpace($base_dir)) {
    Write-Host "The 'code_root_dir' environment variable is not set."
    exit
}

$exePath = Join-Path -Path $base_dir -ChildPath "Code2\C#\WowBot\WowBot\bin\Debug\WowBot.exe"

if (-Not (Test-Path -Path $exePath -PathType Leaf)) {
    Write-Host "The executable file '$exePath' does not exist. Checking Release dir..."
	$exePath = Join-Path -Path $base_dir -ChildPath "Code2\C#\WowBot\WowBot\bin\Release\WowBot.exe"
}

if (-Not (Test-Path -Path $exePath -PathType Leaf)) {
    Write-Host "The executable file '$exePath' does not exist."
    exit
}

$settingsPath = Join-Path -Path $base_dir -ChildPath "Code2\C#\BloogBot\Bot\bootstrapperSettings.json"

if (-Not (Test-Path -Path $settingsPath -PathType Leaf)) {
    Write-Host "Bloogbot settings file '$settingsPath' does not exist. Have you compiled BloogBot?"
    exit
}

$jsonContent = Get-Content -Path $settingsPath | ConvertFrom-Json
$pathToWoW = $jsonContent.PathToWoW

if (-Not (Test-Path -Path $pathToWoW)) {
    Write-Host "WoW.exe does not exist at the path: $pathToWoW. Please check the path in '$settingsPath'"
    exit
} else {
    Write-Host "WoW.exe found at the path: $pathToWoW"
}

# Start WowBot with remote argument if any argument is provided to this script.
# This will launch bloogbot without verifying that the player is online through the db.
if ($args.Count -gt 0) {
    $user_arg = $args[0]

    #if ($user_arg -eq 'remote') {
        Start-Process -FilePath $exePath -ArgumentList 'remote' -Verb RunAs
    #}
} else {
	# Good to go. Invoke executable with administrative privileges
	Start-Process -FilePath $exePath -Verb RunAs
}
