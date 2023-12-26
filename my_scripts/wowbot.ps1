$userProfile = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::UserProfile)

# Check if the script is running with administrative privileges
if (-Not ([System.Security.Principal.WindowsPrincipal] [System.Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([System.Security.Principal.WindowsBuiltInRole] "Administrator")) {
    # Relaunch the script as an administrator
	#Start-Process powershell.exe -ArgumentList " -NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Start-Process wt.exe -ArgumentList "-d `"$userProfile`"" -Verb RunAs
    exit
}

# Define your environment variable
$base_dir = [System.Environment]::GetEnvironmentVariable("code_root_dir", [System.EnvironmentVariableTarget]::User)

# If the user-level environment variable is not set, check the machine-level environment variable
if ([string]::IsNullOrWhiteSpace($base_dir)) {
    $base_dir = [System.Environment]::GetEnvironmentVariable("code_root_dir", [System.EnvironmentVariableTarget]::Machine)
}

if ([string]::IsNullOrWhiteSpace($base_dir)) {
    $base_dir = $env:code_root_dir
}

# Check if the environment variable is set
if ([string]::IsNullOrWhiteSpace($base_dir)) {
    Write-Host "The 'code_root_dir' environment variable is not set."
    exit
}

# Construct the full path to your executable
$exePath = Join-Path -Path $base_dir -ChildPath "Code2\C#\WowBot\WowBot\bin\Debug\WowBot.exe"

# Check if the executable file exists
if (-Not (Test-Path -Path $exePath -PathType Leaf)) {
    Write-Host "The executable file '$exePath' does not exist."
    exit
}

# Invoke the executable with administrative privileges
Start-Process -FilePath $exePath -Verb RunAs