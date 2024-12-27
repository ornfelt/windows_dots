param(
    [string]$OutputOnly
)

#if (-not (Test-Path ".git")) {
#    Write-Error "This is not a git repository."
#    exit 1
#}

#$currentBranch = git rev-parse --abbrev-ref HEAD
#$pushUrl = git config --get remote.origin.url
$currentBranch = git rev-parse --abbrev-ref HEAD 2>$null
$pushUrl = git remote get-url --push origin 2>$null

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

#$tokenValue = $env:$tokenEnvVarName
$tokenValue = [System.Environment]::GetEnvironmentVariable($tokenEnvVarName)
if (-not $tokenValue) {
    Write-Error "No token found for repository owner: $repoOwner"
    exit 1
}

$pushCommandActual  = "git push https://${tokenValue}@github.com/$repoOwner/$repoName $currentBranch"
$pushCommandDisplay = "git push https://`$env:$($tokenEnvVarName)@github.com/$repoOwner/$repoName $currentBranch"

# 6) Either show the masked command or execute the real push
if ($OutputOnly) {
    Write-Output $pushCommandDisplay
} else {
    Invoke-Expression $pushCommandActual
}

