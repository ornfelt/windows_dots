# Dirs to add to the safe directory list
$directories = @(".\Code", ".\Code2")

function Contains-GitRepo {
    param (
        [string]$path
    )

    return Test-Path -Path (Join-Path -Path $path -ChildPath ".git")
}

function Add-SafeDirectory {
    param (
        [string]$path
    )

    # Full path
    $fullPath = Resolve-Path -Path $path

    if (Contains-GitRepo -path $fullPath) {
        git config --global --add safe.directory "$fullPath"
    }

    # Process subdirectories recursively...
    Get-ChildItem -Path $path -Directory -Recurse | ForEach-Object {
        if (Contains-GitRepo -path $_.FullName) {
            git config --global --add safe.directory "$($_.FullName)"
        }
    }
}

foreach ($dir in $directories) {
    Add-SafeDirectory -path $dir
}

# ------------------------------------------------------------

# To see trusted dirs:
# git config --global --get-all safe.directory

# git config --global --unset-all safe.directory
# Or, if you want to set it to an empty value explicitly:
# git config --global --add safe.directory ""

# To opt-out of the security check and trust all directories:
# git config --global --add safe.directory '*'

