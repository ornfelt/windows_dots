param(
    [string]$OutputOnly,
    [Alias('h')]
    [switch]$Help
)

function Show-Usage {
    $scriptName = Split-Path -Leaf $PSCommandPath
    Write-Host @"
Usage: $scriptName [anything]
       $scriptName help | --help | -h

Pull the current branch from GitHub using a token from the environment
(GITHUB_TOKEN, or ALT_GITHUB_TOKEN for archornf repos).

Arguments:
  (none)            Run the git pull.
  anything else     Print the git pull command instead of running it.
  -Help, -h, help   Show this help.
"@
}

# `help` / `--help` bind to $OutputOnly (first positional argument).
# -in and parameter names are case-insensitive, so HELP / -H also work.
if ($Help -or $OutputOnly -in @('help', '--help')) {
    Show-Usage
    exit 0
}

$currentBranch = git rev-parse --abbrev-ref HEAD 2>$null
$pushUrl       = git remote get-url --push origin 2>$null

if (-not $currentBranch -or -not $pushUrl) {
    Write-Error "Unable to determine current branch or remote URL."
    exit 1
}

if ($pushUrl -match "github.com[:/](?<owner>[^/]+)/(?<repo>[^/]+)(\.git)?$") {
    $repoOwner = $Matches['owner']
    $repoName  = $Matches['repo']
} else {
    Write-Error "Could not extract owner/organization from remote URL."
    exit 1
}

switch ($repoOwner) {
    "ornfelt"    { $tokenEnvVarName = "GITHUB_TOKEN" }
    "sveawebpay" { $tokenEnvVarName = "GITHUB_TOKEN" }
    "rewow"      { $tokenEnvVarName = "GITHUB_TOKEN" }
    "archornf"   { $tokenEnvVarName = "ALT_GITHUB_TOKEN" }
    default {
        Write-Error "Unsupported repository owner: $repoOwner"
        exit 1
    }
}

$cleanedRepoName = $repoName -replace '\.git$', ''

if ($cleanedRepoName -eq 'my_notes') {
    $tokenEnvVarName = "GITHUB_TOKEN" 
}

$tokenValue = [System.Environment]::GetEnvironmentVariable($tokenEnvVarName)
if (-not $tokenValue) {
    Write-Error "No token found for repository owner: $repoOwner"
    exit 1
}

$pullCommandActual  = "git pull https://${tokenValue}@github.com/$repoOwner/$repoName $currentBranch"
$pullCommandDisplay = "git pull https://`$env:$($tokenEnvVarName)@github.com/$repoOwner/$repoName $currentBranch"

# Pulling from a URL instead of from origin doesn't update origin/<branch>, so
# git would say the branch is ahead by the pulled commits. Point it at what was
# fetched (FETCH_HEAD) after a successful pull, like pulling from origin does.
$syncCommand = "git update-ref refs/remotes/origin/$currentBranch FETCH_HEAD"
# A URL pull never sets an upstream either, and without one git status doesn't
# compare the branch with origin at all. Set it once origin/<branch> exists.
git rev-parse -q --verify '@{u}' 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) {
    $syncCommand += "; git branch --set-upstream-to=origin/$currentBranch"
}

# no && in Windows PowerShell 5.1
$pullCommandDisplay = "$pullCommandDisplay; if (`$LASTEXITCODE -eq 0) { $syncCommand }"

if ($OutputOnly) {
    Write-Output $pullCommandDisplay
} else {
    Write-Host "Executing: $pullCommandDisplay"
    Invoke-Expression $pullCommandActual
    if ($LASTEXITCODE -eq 0) {
        Invoke-Expression $syncCommand
    }
}

