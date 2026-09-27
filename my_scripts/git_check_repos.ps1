# Lists git repos with work that isn't saved upstream yet: modified or untracked
# files, staged but uncommitted changes, stashes, commits that aren't pushed
# (also ones made on a detached HEAD) and unfinished rebases, merges etc.
# Also lists branches that are behind their upstream (or, without one, the
# branch of the same name on the remote), i.e. that have something to pull.
#
#   git_check_repos.ps1 [-NoFetch] [-All] [CATEGORY|DIR...]
#
#   CATEGORY  which of the known repos to check (case insensitive, can be combined)
#               all          everything (the default without CATEGORY and DIR)
#               wow          WoW servers, cores and tools
#               term         terminals (also: terminal)
#               dots         term + the dotfiles and WindowsPowerShell repos
#               other, x     everything that's in none of the categories above
#   DIR       where to look for repos, up to 4 levels deep
#   -NoFetch, -n   don't fetch first (offline); the ahead/behind counts are then
#             as of the last fetch, and pushing to a URL (like git_push.ps1 does)
#             doesn't update them, so pushed commits can still show as not pushed
#   -All, -a  also list the clean repos
#   -h, help  show this help
#
# Examples:
#   git_check_repos.ps1                    check every known repo
#   git_check_repos.ps1 wow -n             the WoW repos, without fetching first
#   git_check_repos.ps1 -a dots            the dotfiles repos, clean ones too
#   git_check_repos.ps1 wow other          two categories at once
#   git_check_repos.ps1 C:\src             every repo under C:\src, 4 levels deep
#
# Known repos that don't exist (yet) or aren't git repos are skipped with a warning.
# A fetch that takes longer than $env:GIT_CHECK_TIMEOUT seconds (default 60) is
# stopped and warned about.
# Exits with 1 if any repo has something to commit, push or pull, and with 2 on
# an unknown option, category or directory.

param(
    [Alias('n')]
    [switch]$NoFetch,
    [Alias('a')]
    [switch]$All,
    [Alias('h')]
    [switch]$Help,
    # categories and/or directories; unknown -options end up here as well
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Targets
)

function Write-Ok   ([string]$m) { Write-Host $m -ForegroundColor Green }
function Write-Err  ([string]$m) { Write-Host $m -ForegroundColor Red }
function Write-Warn ([string]$m) { Write-Host "[warn] $m" -ForegroundColor DarkYellow }
function Write-Dim  ([string]$m) { Write-Host $m -ForegroundColor DarkGray }

# The comment block at the top of this file, up to the first empty line
function Show-Usage {
    foreach ($line in Get-Content -LiteralPath $PSCommandPath) {
        if ($line -notmatch '^#') { break }
        Write-Host ($line -replace '^# ?', '')
    }
}

$DefaultFetchTimeout = 60
$MaxRepoDepth        = 4
$ExitUsage           = 2

$fetchTimeout = $DefaultFetchTimeout
if ($env:GIT_CHECK_TIMEOUT) { $fetchTimeout = [int]$env:GIT_CHECK_TIMEOUT }
$codeRootDir   = if ($env:code_root_dir) { $env:code_root_dir } else { $HOME }
$myNotesPath   = if ($env:my_notes_path) { $env:my_notes_path } else { Join-Path $HOME 'Documents\my_notes' }
$psProfilePath = if ($env:ps_profile_path) { $env:ps_profile_path } else { Split-Path $PSScriptRoot -Parent }

$TERM_REPOS = @(
    (Join-Path $codeRootDir 'Code2\Rust\wezterm')
    (Join-Path $codeRootDir 'Code2\C\WecTerm')
)
# 'dots' is these plus TERM_REPOS
$DOTS_REPOS = @(
    (Join-Path $codeRootDir 'Code2\General\dotfiles')
    $psProfilePath
)
$WOW_REPOS = @(
    (Join-Path $codeRootDir 'Code2\Wow\tools\my_wow')
    (Join-Path $codeRootDir 'Code2\Rust\azerothcore-wotlk-rs')
    (Join-Path $codeRootDir 'Code2\C#\mangos-tbc-cs')
    (Join-Path $codeRootDir 'Code2\C#\vmangos_cs')
    (Join-Path $codeRootDir 'Code2\C#\azerothcore-wotlk-cs')
    (Join-Path $codeRootDir 'Code2\C++\AzerothCore-wotlk-with-NPCBots')
    (Join-Path $codeRootDir 'Code2\C++\Trinitycore-3.3.5-with-NPCBots')
    (Join-Path $codeRootDir 'Code2\C++\mangos-tbc')
    (Join-Path $codeRootDir 'Code2\C++\mangos-tbc\src\modules\PlayerBots')
    (Join-Path $codeRootDir 'Code2\C++\mangos-classic')
    (Join-Path $codeRootDir 'Code2\C++\mangos-classic\src\modules\PlayerBots')
    (Join-Path $codeRootDir 'Code2\C++\server')
    (Join-Path $codeRootDir 'Code2\C++\core')
    (Join-Path $codeRootDir 'Code2\C++\azerothcore-wotlk')
    (Join-Path $codeRootDir 'Code2\C++\azerothcore-wotlk-playerbots')
    (Join-Path $codeRootDir 'Code2\C++\azerothcore-wotlk-playerbots\modules\mod-playerbots')
)
# 'other' is these plus the repos in OTHER_DIRS that are in no other category
$OTHER_REPOS = @(
    (Join-Path $codeRootDir 'Code2\General\utils')
    (Join-Path $codeRootDir 'Code2\C#\my_cs')
    (Join-Path $codeRootDir 'Code2\C#\my_csharp')
    (Join-Path $codeRootDir 'Code2\Python\my_py')
    (Join-Path $codeRootDir 'Code2\General\gfx')
    (Join-Path $codeRootDir 'Code2\C++\space')
    (Join-Path $codeRootDir 'Code2\C++\my_cplusplus')
    (Join-Path $codeRootDir 'Code2\Python\wander_nodes_util')
    (Join-Path $codeRootDir 'Code2\C++\stk-code')
    (Join-Path $codeRootDir 'Code2\Sql\my_sql')
    (Join-Path $codeRootDir 'Code2\C\ioq3')
    $myNotesPath
)
# git_check_repos.sh scans ~/.config here; nothing to scan on Windows
$OTHER_DIRS = @()

$fetch   = -not $NoFetch
$showAll = [bool]$All
$want    = @{}
$dirs    = New-Object System.Collections.Generic.List[String]

if ($Help) { Show-Usage; exit 0 }

foreach ($arg in $Targets) {
    switch ($arg.ToLower()) {
        { $_ -in 'help', '--help' } { Show-Usage; exit 0 }
        'all'      { $want['term'] = 1; $want['dots'] = 1; $want['wow'] = 1; $want['other'] = 1; break }
        { $_ -in 'wow', 'dots', 'other' } { $want[$_] = 1; break }
        { $_ -in 'term', 'terminal' } { $want['term'] = 1; break }
        'x'        { $want['other'] = 1; break }
        { $_.StartsWith('-') } {
            # combined single-letter options like -na, as in git_check_repos.sh
            foreach ($opt in $arg.Substring(1).ToCharArray()) {
                switch ($opt) {
                    'n' { $fetch = $false }
                    'a' { $showAll = $true }
                    'h' { Show-Usage; exit 0 }
                    default {
                        Write-Host "unknown option: $arg`n"
                        Show-Usage
                        exit $ExitUsage
                    }
                }
            }
            break
        }
        default {
            # absolute, so a repo reached through a relative path isn't listed twice
            $dir = Resolve-Path -LiteralPath $arg -ErrorAction SilentlyContinue
            if (-not $dir -or -not (Test-Path -LiteralPath $dir -PathType Container)) {
                Write-Host "unknown category or directory: $arg (see -h)"
                exit $ExitUsage
            }
            $dirs.Add($dir.ProviderPath)
        }
    }
}
if ($want.Count -eq 0 -and $dirs.Count -eq 0) {
    $want['term'] = 1; $want['dots'] = 1; $want['wow'] = 1; $want['other'] = 1
}
if ($want['dots']) { $want['term'] = 1 }

# Never hang on a username/password prompt, fail instead
$env:GIT_TERMINAL_PROMPT = '0'

$homePattern = '^' + [regex]::Escape($HOME.TrimEnd('\'))
function Get-ShortName([string]$Path) { return $Path -replace $homePattern, '~' }

# Prints the repos in the dir, up to 4 levels deep (so their .git up to 5)
function Find-Repos {
    param([string]$Dir, [int]$Depth = 0)
    if (Test-Path -LiteralPath (Join-Path $Dir '.git')) { $Dir }
    if ($Depth -ge $MaxRepoDepth) { return }
    foreach ($sub in Get-ChildItem -LiteralPath $Dir -Directory -Force -ErrorAction SilentlyContinue) {
        # .git holds no repos, and links could loop
        if ($sub.Name -eq '.git' -or ($sub.Attributes -band [IO.FileAttributes]::ReparsePoint)) { continue }
        Find-Repos $sub.FullName ($Depth + 1)
    }
}

function Find-ReposSorted([string]$Dir) {
    $found = @(Find-Repos $Dir)
    [Array]::Sort($found, [StringComparer]::Ordinal)
    return $found
}

$repos = New-Object System.Collections.Generic.List[String]
$seen  = @{}
function Add-Repo([string]$Repo) {
    $Repo = $Repo.TrimEnd('\', '/')
    if ($seen.ContainsKey($Repo)) { return }
    $seen[$Repo] = 1
    if (-not (Test-Path -LiteralPath $Repo -PathType Container)) {
        Write-Warn "$(Get-ShortName $Repo) doesn't exist, skipping"
    } elseif (-not (Test-Path -LiteralPath (Join-Path $Repo '.git'))) {
        Write-Warn "$(Get-ShortName $Repo) is not a git repo, skipping"
    } else {
        $repos.Add($Repo)
    }
}

foreach ($dir in $dirs) {
    foreach ($repo in Find-ReposSorted $dir) { Add-Repo $repo }
}
if ($want['term']) { foreach ($repo in $TERM_REPOS) { Add-Repo $repo } }
if ($want['dots']) { foreach ($repo in $DOTS_REPOS) { Add-Repo $repo } }
if ($want['wow'])  { foreach ($repo in $WOW_REPOS)  { Add-Repo $repo } }
if ($want['other']) {
    foreach ($repo in $OTHER_REPOS) { Add-Repo $repo }
    # repos of the other categories found in OTHER_DIRS aren't 'other', so mark them as seen
    foreach ($repo in ($TERM_REPOS + $DOTS_REPOS + $WOW_REPOS)) { $seen[$repo.TrimEnd('\', '/')] = 1 }
    foreach ($dir in $OTHER_DIRS) {
        foreach ($repo in Find-ReposSorted $dir) { Add-Repo $repo }
    }
}

# One colored line of a repo's report
function New-Line([string]$Text, [string]$Color) {
    return [PSCustomObject]@{ Text = $Text; Color = $Color }
}

# "<ahead>\t<behind>" from git rev-list --left-right --count, as two ints
function Get-AheadBehind([string]$Repo, [string]$Left, [string]$Right) {
    $counts = (git -C $Repo rev-list --left-right --count "$Left...$Right") -split '\s+'
    return @([int]$counts[0], [int]$counts[1])
}

# Returns one line per problem in the repo, nothing if it is clean
function Get-RepoReport([string]$Repo) {
    $out = New-Object System.Collections.Generic.List[Object]

    # 2>$null: git's "LF will be replaced by CRLF" warnings would show up as errors
    $n = @(git -C $Repo diff --name-only 2>$null).Count
    if ($n -gt 0) { $out.Add((New-Line "$n modified file(s) not staged" DarkYellow)) }
    $n = @(git -C $Repo ls-files --others --exclude-standard).Count
    if ($n -gt 0) { $out.Add((New-Line "$n untracked file(s)" DarkYellow)) }
    $n = @(git -C $Repo diff --cached --name-only 2>$null).Count
    if ($n -gt 0) { $out.Add((New-Line "$n staged file(s) not committed" DarkYellow)) }
    $n = @(git -C $Repo stash list).Count
    if ($n -gt 0) { $out.Add((New-Line "$n stash(es)" DarkYellow)) }
    $gitDir = git -C $Repo rev-parse --absolute-git-dir
    $inProgress = @(
        @('rebase-merge', 'rebase'), @('rebase-apply', 'rebase/am'), @('MERGE_HEAD', 'merge'),
        @('CHERRY_PICK_HEAD', 'cherry-pick'), @('REVERT_HEAD', 'revert'), @('BISECT_LOG', 'bisect')
    )
    foreach ($op in $inProgress) {
        if (Test-Path -LiteralPath (Join-Path $gitDir $op[0])) { $out.Add((New-Line "$($op[1]) in progress" DarkYellow)) }
    }

    $remotes = @(git -C $Repo remote)
    if ($remotes.Count -eq 0) {
        $out.Add((New-Line "no remote, nothing is pushed anywhere" Red))
    } else {
        $refs = @(git -C $Repo for-each-ref refs/heads --format='%(refname:short)%09%(upstream)%09%(upstream:short)')
        foreach ($line in $refs) {
            $branch, $upstreamRef, $upstream = $line -split "`t"
            $branchRef = "refs/heads/$branch"
            $behind = 0
            $hasUpstream = $false
            if ($upstream) {
                git -C $Repo rev-parse -q --verify $upstreamRef 2>$null | Out-Null
                $hasUpstream = ($LASTEXITCODE -eq 0)
            }
            if ($hasUpstream) {
                $ahead, $behind = Get-AheadBehind $Repo $branchRef $upstreamRef
                if ($upstreamRef -like 'refs/remotes/*') {
                    if ($ahead -gt 0) { $out.Add((New-Line "${branch}: $ahead commit(s) not pushed to $upstream" Red)) }
                } else {
                    # tracks a local branch, so being ahead of it says nothing about the remotes
                    $ahead = [int](git -C $Repo rev-list --count $branchRef --not --remotes)
                    if ($ahead -gt 0) { $out.Add((New-Line "${branch}: $ahead commit(s) not on any remote (tracks local $upstream)" Red)) }
                }
            } else {
                # no upstream: commits that aren't on any remote branch
                $ahead = [int](git -C $Repo rev-list --count $branchRef --not --remotes)
                if ($ahead -gt 0) { $out.Add((New-Line "${branch}: $ahead commit(s) not on any remote (no upstream)" Red)) }
                # and whether the branch of the same name on the remote (origin first) has moved on
                $upstream = ''
                foreach ($remote in (@('origin') + $remotes)) {
                    git -C $Repo rev-parse -q --verify "refs/remotes/$remote/$branch" 2>$null | Out-Null
                    if ($LASTEXITCODE -eq 0) {
                        $upstream = "$remote/$branch"
                        $behind = [int](git -C $Repo rev-list --count "$branchRef..refs/remotes/$upstream")
                        break
                    }
                }
            }
            if ($behind -gt 0) { $out.Add((New-Line "${branch}: $behind commit(s) behind $upstream" Magenta)) }
        }
        # commits made on a detached HEAD are on no branch, so the loop above misses them
        git -C $Repo symbolic-ref -q HEAD 2>$null | Out-Null
        if ($LASTEXITCODE -ne 0) {
            $ahead = [int](git -C $Repo rev-list --count HEAD --not --branches --remotes)
            if ($ahead -gt 0) { $out.Add((New-Line "detached HEAD: $ahead commit(s) on no branch or remote" Red)) }
        }
    }

    return $out
}

# The name of the env var holding the token for a GitHub remote URL, nothing
# if there isn't one (same mapping as git_push.ps1)
function Get-TokenVar([string]$Url) {
    if ($Url -notmatch 'github\.com[:/]([^/]+)/([^/]+)$') { return $null }
    if (($Matches[2] -replace '\.git$', '') -eq 'my_notes') { return 'GITHUB_TOKEN' }
    switch ($Matches[1]) {
        { $_ -in 'ornfelt', 'sveawebpay', 'rewow' } { return 'GITHUB_TOKEN' }
        'archornf' { return 'ALT_GITHUB_TOKEN' }
    }
    return $null
}

# One argument for a Win32 command line: quoted, with inner quotes escaped
function ConvertTo-CommandLineArg([string]$Arg) {
    return '"' + (($Arg -replace '(\\*)"', '$1$1\"') -replace '(\\+)$', '$1$1') + '"'
}

$gitExe = (Get-Command git).Source

# Starts fetching one remote of the repo in the background, never prompting for
# credentials: private GitHub repos get the owner's token through a credential
# helper that reads it from the environment, so it doesn't show up in the
# process list
function Start-Fetch([string]$Repo, [string]$Remote) {
    $gitArgs = @('-C', $Repo)
    $var = Get-TokenVar (git -C $Repo remote get-url $Remote)
    if ($var -and [System.Environment]::GetEnvironmentVariable($var)) {
        $gitArgs += @('-c', "credential.https://github.com.helper=!f() { echo username=x-access-token; echo `"password=`$$var`"; }; f")
    }
    $gitArgs += @('fetch', '--quiet', $Remote)

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName               = $gitExe
    $psi.Arguments              = ($gitArgs | ForEach-Object { ConvertTo-CommandLineArg $_ }) -join ' '
    $psi.UseShellExecute        = $false
    $psi.CreateNoWindow         = $true
    $psi.RedirectStandardInput  = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError  = $true
    $process = [System.Diagnostics.Process]::Start($psi)
    # drain both streams so a chatty git can't block on a full pipe
    $process.BeginOutputReadLine()
    $process.BeginErrorReadLine()
    $process.StandardInput.Close()
    return $process
}

# Fetch all repos in parallel (the remotes of one repo one after the other, as
# they share its refs), so the ahead/behind counts match the remotes
if ($fetch) {
    $PollIntervalMs = 200
    $jobs = foreach ($repo in $repos) {
        [PSCustomObject]@{
            Repo     = $repo
            Remotes  = New-Object System.Collections.Generic.Queue[String] (,[string[]]@(git -C $repo remote))
            Process  = $null
            Started  = $null
            Failed   = $false
            TimedOut = $false
        }
    }
    do {
        $running = 0
        foreach ($job in $jobs) {
            if ($job.Process) {
                if ($job.Process.HasExited) {
                    if ($job.Process.ExitCode -ne 0) { $job.Failed = $true }
                    $job.Process.Dispose()
                    $job.Process = $null
                } elseif (((Get-Date) - $job.Started).TotalSeconds -gt $fetchTimeout) {
                    # git spawns helpers (git-remote-https), so stop the whole tree
                    taskkill /PID $job.Process.Id /T /F 2>$null | Out-Null
                    $job.Process.WaitForExit()
                    $job.Process.Dispose()
                    $job.Process = $null
                    $job.TimedOut = $true
                    $job.Failed = $true
                }
            }
            if (-not $job.Process -and $job.Remotes.Count -gt 0) {
                $job.Process = Start-Fetch $job.Repo $job.Remotes.Dequeue()
                $job.Started = Get-Date
            }
            if ($job.Process) { $running++ }
        }
        if ($running -gt 0) { Start-Sleep -Milliseconds $PollIntervalMs }
    } while ($running -gt 0)
    foreach ($job in $jobs) {
        if ($job.TimedOut) {
            Write-Warn "fetch timed out after ${fetchTimeout}s for $(Get-ShortName $job.Repo)"
        } elseif ($job.Failed) {
            Write-Warn "fetch failed for $(Get-ShortName $job.Repo)"
        }
    }
}

$dirty = 0
$total = 0
foreach ($repo in $repos) {
    $total++
    $report = Get-RepoReport $repo
    $name = Get-ShortName $repo
    if ($report.Count -gt 0) {
        $dirty++
        $branch = git -C $repo rev-parse --abbrev-ref HEAD 2>$null
        Write-Host $name -ForegroundColor Blue -NoNewline
        Write-Host " ($branch)" -ForegroundColor DarkGray
        foreach ($line in $report) {
            Write-Host "    $($line.Text)" -ForegroundColor $line.Color
        }
    } elseif ($showAll) {
        Write-Host $name -ForegroundColor Blue -NoNewline
        Write-Host " clean" -ForegroundColor Green
    }
}

if ($total -eq 0) {
    Write-Host "No git repos found." -ForegroundColor DarkYellow
} elseif ($dirty -eq 0) {
    Write-Ok "All $total repo(s) are clean and in sync."
} else {
    Write-Host
    Write-Host "$dirty of $total repo(s) have changes to commit, push or pull." -ForegroundColor DarkYellow
    if (-not $fetch) { Write-Dim "Not fetched (-n), ahead/behind counts are as of the last fetch." }
    exit 1
}
