# param(
#     [string]$OutputOnly
# )
# 
# #if (-not (Test-Path ".git")) {
# #    Write-Error "This is not a git repository."
# #    exit 1
# #}
# 
# $currentBranch = git rev-parse --abbrev-ref HEAD
# $pushUrl = git config --get remote.origin.url
# 
# if (-not $currentBranch -or -not $pushUrl) {
#     Write-Error "Unable to determine current branch or remote URL."
#     exit 1
# }
# 
# if ($pushUrl -match "github.com[:/](?<owner>[^/]+)/") {
#     $repoOwner = $Matches['owner']
# } else {
#     Write-Error "Could not extract owner/organization from remote URL."
#     exit 1
# }
# 
# switch ($repoOwner) {
#     "ornfelt" { $token = $env:GITHUB_TOKEN }
#     "sveawebpay" { $token = $env:GITHUB_TOKEN }
#     "rewow" { $token = $env:GITHUB_TOKEN }
#     "archornf" { $token = $env:ALT_GITHUB_TOKEN }
#     default {
#         Write-Error "Unsupported repository owner: $repoOwner"
#         exit 1
#     }
# }
# 
# if (-not $token) {
#     Write-Error "No token found for repository owner: $repoOwner"
#     exit 1
# }
# 
# $pushCommand = "git push https://${token}@github.com/$repoOwner/$(git config --get remote.origin.url | ForEach-Object { ($_ -split "/")[-1] }) $currentBranch"
# 
# if ($OutputOnly) {
#     Write-Output $pushCommand
# } else {
#     Invoke-Expression $pushCommand
# }
# 

# Function to determine the repository push URL and branch
function Get-GitDetails {
    # Get the remote push URL
    $pushUrl = git remote get-url --push origin 2>$null
    if (-not $pushUrl) {
        Write-Error "Failed to get Git push URL. Ensure you are in a Git repository."
        return $null
    }

    # Get the current branch name
    $branch = git rev-parse --abbrev-ref HEAD 2>$null
    if (-not $branch) {
        Write-Error "Failed to determine the current branch name."
        return $null
    }

    return [PSCustomObject]@{
        PushUrl = $pushUrl
        Branch  = $branch
    }
}

# Main script
$gitDetails = Get-GitDetails
if (-not $gitDetails) {
    exit 1
}

$pushUrl = $gitDetails.PushUrl
$branch = $gitDetails.Branch

# Extract repository owner/organization from the push URL
if ($pushUrl -match "github\.com[:/](?<owner>[^/]+)/") {
    $owner = $Matches['owner']
} else {
    Write-Error "Failed to extract repository owner/organization from the push URL."
    exit 1
}

# Determine which token to use
if ($owner -in @("ornfelt", "sveawebpay", "rewow")) {
    $token = $env:GITHUB_TOKEN
    if (-not $token) {
        Write-Error "GITHUB_TOKEN environment variable is not set."
        exit 1
    }
} elseif ($owner -eq "archornf") {
    $token = $env:ALT_GITHUB_TOKEN
    if (-not $token) {
        Write-Error "ALT_GITHUB_TOKEN environment variable is not set."
        exit 1
    }
} else {
    Write-Error "Unsupported repository owner/organization: $owner"
    exit 1
}

# Construct the Git push command
$pushCommand = "git push https://$token@github.com/$owner/$(basename $pushUrl) $branch"

# Check if the script was called with an argument
if ($args.Count -gt 0) {
    # Print the constructed command
    Write-Output $pushCommand
} else {
    # Execute the constructed command
    Invoke-Expression $pushCommand
}
