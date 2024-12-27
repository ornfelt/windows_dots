param(
    [string]$OutputOnly
)

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

$tokenValue = [System.Environment]::GetEnvironmentVariable($tokenEnvVarName)
if (-not $tokenValue) {
    Write-Error "No token found for repository owner: $repoOwner"
    exit 1
}

$pullCommandActual  = "git pull https://${tokenValue}@github.com/$repoOwner/$repoName $currentBranch"
$pullCommandDisplay = "git pull https://`$env:$($tokenEnvVarName)@github.com/$repoOwner/$repoName $currentBranch"

if ($OutputOnly) {
    Write-Output $pullCommandDisplay
} else {
    Invoke-Expression $pullCommandActual
}

