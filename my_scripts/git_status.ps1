param(
    [Alias('o')]
    [switch]$OutputOnly,
    [Alias('h')]
    [switch]$Help
)

function Write-Ok   ([string]$m) { Write-Host $m -ForegroundColor Green }
function Write-Warn ([string]$m) { Write-Host $m -ForegroundColor DarkYellow }
function Write-Bold ([string]$m) { Write-Host $m -ForegroundColor White }

function Show-Usage {
    $scriptName = Split-Path -Leaf $PSCommandPath
    Write-Host @"
Usage: $scriptName [-OutputOnly]
       $scriptName help | --help | -h

Show git status for the current branch and check it against the branch on
GitHub (origin), which git status alone doesn't do. It can suggest:
  - the update-ref sync command git_push.ps1 runs, when origin/<branch> is out
    of date because the branch was pushed to a URL
  - a fetch, when origin has commits that aren't fetched yet
  - a fast-forward merge or a rebase, when the branch is behind origin, or
    behind the local branch it tracks (like main)
  - git_push.ps1, when there are commits that aren't pushed
Each command is printed, and run only if you answer y or yes. After it has
run, the branch is checked again and the next command (if any) is suggested.

Talks to GitHub with a token from the environment (GITHUB_TOKEN, or
ALT_GITHUB_TOKEN for archornf repos) like git_push.ps1, or through the origin
remote as-is if there is no token.

Options:
  -OutputOnly (-o)  Print the first suggested command without asking to run it.
  -Help, -h, help   Show this help.
"@
}

# `help` and `--help` are not parameter names, so they end up in $args
if ($Help -or ($args.Count -gt 0 -and $args[0] -in @('help', '--help'))) {
    Show-Usage
    exit 0
}

if ($args.Count -gt 0) {
    Write-Host "Unknown argument(s): $args" -ForegroundColor Red
    Show-Usage
    exit 1
}

# Never hang on a username/password prompt, fail instead
$env:GIT_TERMINAL_PROMPT = '0'

git rev-parse --git-dir 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Not in a git repository."
    exit 1
}

git -c color.status=always status --short --branch

$currentBranch = git symbolic-ref --short -q HEAD 2>$null
if (-not $currentBranch) {
    Write-Host "HEAD is detached, no branch to check."
    exit 1
}

$originUrl = git remote get-url origin 2>$null
if (-not $originUrl) {
    Write-Host "No origin remote, nothing to compare with."
    exit 1
}

# Where to reach origin: through a token URL when there is a token for it (the
# same owners and tokens as git_push.ps1), otherwise through the remote itself
$remoteUrl        = "origin"
$remoteUrlDisplay = "origin"
if ($originUrl -match "github.com[:/](?<owner>[^/]+)/(?<repo>[^/]+)(\.git)?$") {
    $repoOwner = $Matches['owner']
    $repoName  = $Matches['repo']
    $tokenEnvVarName = $null
    switch ($repoOwner) {
        "ornfelt"    { $tokenEnvVarName = "GITHUB_TOKEN" }
        "sveawebpay" { $tokenEnvVarName = "GITHUB_TOKEN" }
        "rewow"      { $tokenEnvVarName = "GITHUB_TOKEN" }
        "archornf"   { $tokenEnvVarName = "ALT_GITHUB_TOKEN" }
    }
    if (($repoName -replace '\.git$', '') -eq 'my_notes') {
        $tokenEnvVarName = "GITHUB_TOKEN"
    }
    $tokenValue = $null
    if ($tokenEnvVarName) {
        $tokenValue = [System.Environment]::GetEnvironmentVariable($tokenEnvVarName)
    }
    if ($tokenValue) {
        $remoteUrl        = "https://${tokenValue}@github.com/$repoOwner/$repoName"
        $remoteUrlDisplay = "https://`$env:$tokenEnvVarName@github.com/$repoOwner/$repoName"
    }
}

if ($remoteUrl -eq "origin") {
    $fetchCommandActual  = "git fetch origin"
    $fetchCommandDisplay = "git fetch origin"
} else {
    # A URL fetch only updates origin/* with an explicit refspec
    $fetchCommandActual  = "git fetch $remoteUrl '+refs/heads/*:refs/remotes/origin/*'"
    $fetchCommandDisplay = "git fetch $remoteUrlDisplay '+refs/heads/*:refs/remotes/origin/*'"
}

$pushScript = Join-Path $PSScriptRoot 'git_push.ps1'

# Set by Get-NextStep: why, and the command to suggest (display has no token in it)
$script:stepReason  = ""
$script:stepDisplay = ""
$script:stepActual  = ""

function Set-Step {
    param(
        [string]$Reason,
        [string]$Display,
        [string]$Actual
    )
    $script:stepReason  = $Reason
    $script:stepDisplay = $Display
    if ($Actual) {
        $script:stepActual = $Actual
    } else {
        $script:stepActual = $Display
    }
}

# Merge when the branch has nothing of its own, otherwise rebase its commits
# on top. --autostash so uncommitted changes don't block either.
function Set-CatchUpStep {
    param(
        [string]$Reason,
        [string]$Target,
        [int]$Ahead
    )
    if ($Ahead -eq 0) {
        Set-Step "$Reason." "git merge --ff-only --autostash $Target"
    } else {
        Set-Step "$Reason, and has $Ahead commit(s) of its own." "git rebase --autostash $Target"
    }
}

# "<ahead>\t<behind>" from git rev-list --left-right --count, as two ints
function Get-AheadBehind {
    param([string]$Left, [string]$Right)
    $counts = (git rev-list --left-right --count "$Left...$Right") -split '\s+'
    return @([int]$counts[0], [int]$counts[1])
}

$script:remoteChecked = $false
$script:remoteMissing = $false

# Finds the next thing to do for the current branch. Returns $true and sets
# the step if there is one, $false if the branch is in sync.
function Get-NextStep {
    $branchRef   = "refs/heads/$currentBranch"
    $branchSha   = git rev-parse $branchRef
    $upstreamRef = git for-each-ref --format='%(upstream)' $branchRef
    $upstream    = git for-each-ref --format='%(upstream:short)' $branchRef
    if ($upstreamRef -like 'refs/remotes/origin/*') {
        $remoteBranch = $upstreamRef -replace '^refs/remotes/origin/', ''
    } else {
        $remoteBranch = $currentBranch
    }
    $trackingRef = "refs/remotes/origin/$remoteBranch"
    $trackingSha = git rev-parse -q --verify $trackingRef 2>$null

    # 1. Does origin/<branch> match the branch on GitHub? Asked once, after a
    #    sync or fetch it does.
    if (-not $script:remoteChecked) {
        $script:remoteChecked = $true
        $lsOutput = git ls-remote $remoteUrl "refs/heads/$remoteBranch" 2>$null
        if ($LASTEXITCODE -eq 0) {
            $remoteSha = ""
            if ($lsOutput) {
                $remoteSha = ("$lsOutput" -split '\s+')[0]
            }
            if (-not $remoteSha) {
                # suggested below, after catching up with a local upstream
                $script:remoteMissing = $true
            } elseif ($remoteSha -ne $trackingSha) {
                if ($remoteSha -eq $branchSha) {
                    Set-Step "$remoteBranch on origin is already at your $currentBranch, only origin/$remoteBranch is out of date (pushed to a URL?)." `
                        "git update-ref $trackingRef $branchRef"
                } else {
                    Set-Step "origin has changes on $remoteBranch that aren't fetched yet." $fetchCommandDisplay $fetchCommandActual
                }
                return $true
            }
        } else {
            Write-Warn "Couldn't reach origin, comparing with origin/$remoteBranch as of the last fetch."
        }
    }

    # 2. Behind the branch it tracks, when that isn't on origin (like local main)
    if ($upstreamRef -and $upstreamRef -notlike 'refs/remotes/origin/*') {
        git rev-parse -q --verify $upstreamRef 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) {
            $ahead, $behind = Get-AheadBehind $branchRef $upstreamRef
            if ($behind -gt 0) {
                Set-CatchUpStep "$currentBranch is $behind commit(s) behind $upstream, which it tracks" $upstream $ahead
                return $true
            }
        }
    }

    # 3. Behind or ahead of the branch on origin
    if ($script:remoteMissing) {
        $script:remoteMissing = $false
        Set-Step "$remoteBranch doesn't exist on origin yet." "& '$pushScript'"
        return $true
    } elseif (-not $trackingSha) {
        Write-Host "No origin/$remoteBranch to compare with."
        return $false
    }
    $ahead, $behind = Get-AheadBehind $branchRef $trackingRef
    if ($behind -gt 0) {
        Set-CatchUpStep "$currentBranch is $behind commit(s) behind origin/$remoteBranch" "origin/$remoteBranch" $ahead
        return $true
    } elseif ($ahead -gt 0) {
        Set-Step "$currentBranch has $ahead commit(s) that aren't pushed to origin/$remoteBranch." "& '$pushScript'"
        return $true
    }

    Write-Ok "$currentBranch is in sync with origin/$remoteBranch."
    return $false
}

$homePattern = [regex]::Escape($HOME.TrimEnd('\'))

# Bounded, in case a command succeeds without changing anything
foreach ($attempt in 1..6) {
    if (-not (Get-NextStep)) {
        exit 0
    }

    Write-Host
    Write-Warn $script:stepReason
    Write-Bold "  $($script:stepDisplay -replace $homePattern, '~')"
    if ($OutputOnly) {
        exit 1
    }

    $answer = Read-Host "Run it? [y/N]"
    if ($answer.Trim().ToLower() -notin @('y', 'yes')) {
        exit 1
    }

    Write-Host "Executing: $($script:stepDisplay)"
    Invoke-Expression $script:stepActual
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Command failed."
        exit 1
    }
}
