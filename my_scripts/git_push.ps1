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

$commands = New-Object System.Collections.Generic.List[String]

function Add-UpstreamIfMissing {
    param(
        [string]$UpstreamUrl
    )

    $existingUpstream = git remote get-url upstream 2>$null
    if (-not $existingUpstream) {
        $commands.Add("git remote add upstream $UpstreamUrl")
    }
}

if ($repoOwner -eq "ornfelt") {

    switch ($repoName) {

        "dwm" {
            Add-UpstreamIfMissing -UpstreamUrl "https://git.suckless.org/dwm"
            $commands.Add('git fetch upstream')
            $commands.Add('git diff upstream/master...master > diff_upstream.diff')
            $commands.Add('git diff origin/bkp -- . ":(exclude)*.diff" ":(exclude)config.def.h" ":(exclude).gitignore" ":(exclude)patches/**" ":(exclude)patches_git/**" > diff_bkp.diff')
            $commands.Add('git diff origin/new -- . ":(exclude)*.diff" ":(exclude)config.def.h" ":(exclude).gitignore" ":(exclude)patches/**" ":(exclude)patches_git/**" > diff_new.diff')
            $commands.Add('git add -A')
            $commands.Add('git commit -m "update diff files"')
        }

        "dmenu" {
            Add-UpstreamIfMissing -UpstreamUrl "https://git.suckless.org/dmenu"
            $commands.Add('git fetch upstream')
            $commands.Add('git diff upstream/master...master > diff_upstream.diff')
            $commands.Add('git diff origin/bkp -- . ":(exclude)*.diff" ":(exclude)config.def.h" ":(exclude).gitignore" ":(exclude)patches/**" ":(exclude)patches_git/**" > diff_bkp.diff')
            $commands.Add('git add -A')
            $commands.Add('git commit -m "update diff files"')
        }

        "awsm" {
            Add-UpstreamIfMissing -UpstreamUrl "https://github.com/lcpz/awesome-copycats"
            $commands.Add('git fetch upstream')
            $commands.Add('git diff upstream/master...master > diff_upstream.diff')
            $commands.Add('git diff origin/bkp -- . ":(exclude)*.diff" ":(exclude).gitignore" ":(exclude)patches/**" ":(exclude)patches_git/**" > diff_bkp.diff')
            $commands.Add('git diff origin/tarneaux -- . ":(exclude)*.diff" ":(exclude).gitignore" ":(exclude)patches/**" ":(exclude)patches_git/**" > diff_tarneaux.diff')
            $commands.Add('git add -A')
            $commands.Add('git commit -m "update diff files"')
        }

        "st" {
            Add-UpstreamIfMissing -UpstreamUrl "https://git.suckless.org/st"
            $commands.Add('git fetch upstream')
            $commands.Add('git diff upstream/master...master > diff_upstream.diff')
            $commands.Add('git diff bkp -- . ":(exclude)*.diff" ":(exclude)config.def.h" ":(exclude).gitignore" ":(exclude)patches/**" ":(exclude)patches_git/**" > diff_bkp.diff')
            $commands.Add('git add -A')
            $commands.Add('git commit -m "update diff files"')
        }
    }
}

if ($repoName -eq 'AzerothCore-wotlk-with-NPCBots') {
    Add-UpstreamIfMissing -UpstreamUrl "https://github.com/trickerer/AzerothCore-wotlk-with-NPCBots"
    $commands.Add('git fetch upstream')

    if ($currentBranch -eq 'linux') {
        $commands.Add('git diff upstream/npcbots_3.3.5...linux -- . ":(exclude)*.conf" ":(exclude)*.patch" ":(exclude)*.diffx" | Set-Content -Encoding utf8 .\acore.diffx')
    }
    else {
        $commands.Add('git diff upstream/npcbots_3.3.5...npcbots_3.3.5 -- . ":(exclude)*.conf" ":(exclude)*.patch" ":(exclude)*.diffx" | Set-Content -Encoding utf8 .\acore.diffx')
    }
}

if ($repoName -eq 'TrinityCore-3.3.5-with-NPCBots') {
    Add-UpstreamIfMissing -UpstreamUrl "https://github.com/trickerer/TrinityCore-3.3.5-with-NPCBots"
    $commands.Add('git fetch upstream')
    $commands.Add('git diff upstream/npcbots_3.3.5...npcbots_3.3.5 -- . ":(exclude)*.conf" ":(exclude)*.patch" ":(exclude)*.diffx" | Set-Content -Encoding utf8 .\tcore.diffx')
}

if ($OutputOnly) {
    foreach ($cmd in $commands[0..($commands.Count - 2)]) {
        Write-Output $cmd
    }
}
else {
    foreach ($cmd in $commands) {
        Write-Host "Executing: $cmd"
        Invoke-Expression $cmd
    }
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

if ($OutputOnly) {
    Write-Output $pushCommandDisplay
} else {
    Invoke-Expression $pushCommandActual
}

