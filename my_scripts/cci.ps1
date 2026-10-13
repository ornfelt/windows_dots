# cci.ps1 - Claude Code usage, printed like the awesome bar widget prints it:
#   <starburst> 5h 5% . 7d 89% . F 0%
# Same data, same text and same colours as ~/.config/awesome/claude_usage on Linux:
# the starburst in Claude orange, the numbers in orange too, red from 90 %, grey
# while there is an error and no data. A flag is appended while a running session
# waits for you. Without VT support in the console the colours become DarkYellow,
# Red and Gray. Linux counterpart: ~/.local/bin/my_scripts/2025/cci.sh.
#
# Where the numbers come from, in this order (like claude_usage/cli.lua):
#   1. the last result, if younger than -MaxAge seconds (default 300)
#   2. the statusLine cache written by claude_usage/contrib/statusline-cache.sh, if
#      younger than two minutes
#   3. the OAuth usage endpoint (skipped while backing off after a 429/network error)
#   4. the statusLine cache at any age, then the cachedUsageUtilization in ~/.claude.json
# The result and the backoff live in ~/.cache/claude-usage/last.json (or
# $env:XDG_CACHE_HOME\claude-usage), so calling this often does not hammer the
# rate-limited endpoint.
#
# Usage examples:
#   .cci
# always fetch (the backoff is still honoured):
#   .cci -MaxAge 0
# cache files only, never call the API:
#   .cci -NoNetwork
param(
    [int]$MaxAge = 300,
    [switch]$NoNetwork
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'  # no Invoke-WebRequest progress bar

# ------------------------------------------------------------------ config --
# Same values as claude_usage/config.lua and the awesome theme.
$Version = '0.5.3'
$UserAgent = "awesome-claude-usage/$Version (+https://github.com/derblub/awesome-claude-usage)"
$ApiUrl = 'https://api.anthropic.com/api/oauth/usage'
$BetaHeader = 'oauth-2025-04-20'
$TimeoutSec = 15
$Backoff = @(300, 600, 1200, 1800)
$StaleAfter = 3600
$FreshCacheMaxAge = 120
$CredentialsPath = Join-Path $HOME '.claude\.credentials.json'
$ClaudeJsonPath = Join-Path $HOME '.claude.json'
$SessionsDir = Join-Path $HOME '.claude\sessions'
$CacheDir = if ($env:XDG_CACHE_HOME) { Join-Path $env:XDG_CACHE_HOME 'claude-usage' } else { Join-Path $HOME '.cache\claude-usage' }
$StatuslineCache = Join-Path $CacheDir 'rate_limits.json'
$LastPath = Join-Path $CacheDir 'last.json'
$WarnAt = 75
$CritAt = 90

$Icon = [string][char]0x273B        # stands in for the drawn starburst
$Dot = [string][char]0x00B7         # " . " separator
$Flag = [string][char]0x2691        # session needs attention
$ColorNormal = '#D97757'
$ColorIcon = '#D97757'
$ColorWarn = '#D97757'              # same as normal in the theme
$ColorCrit = '#C8442E'
$ColorError = '#9C9A93'

$Now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
$Inv = [Globalization.CultureInfo]::InvariantCulture

# ----------------------------------------------------------------- helpers --
# Property or key of a JSON object, $null when missing (also under Set-StrictMode).
# The leading comma keeps a one-element array from being unrolled into its element.
function Get-Prop($obj, $name) {
    if ($null -eq $obj) { return $null }
    if ($obj -is [Collections.IDictionary]) { return , $obj[$name] }
    $p = $obj.PSObject.Properties[$name]
    if ($p) { return , $p.Value }
    return $null
}

function Test-Object($v) { return ($v -is [Collections.IDictionary]) -or ($v -is [Management.Automation.PSCustomObject]) }

# Lua tonumber: numbers and numeric strings, else $null.
function ConvertTo-Number($v) {
    if ($null -eq $v -or $v -is [bool]) { return $null }
    if ($v -is [ValueType]) { return [double]$v }
    $d = 0.0
    if ([double]::TryParse([string]$v, [Globalization.NumberStyles]::Float, $Inv, [ref]$d)) { return $d }
    return $null
}

function Get-Percent($v) {
    $n = ConvertTo-Number $v
    if ($null -eq $n) { return $null }
    if ($n -lt 0) { return 0.0 }
    return $n
}

function Get-EpochSeconds($v) {
    $n = ConvertTo-Number $v
    if ($null -eq $n) { return $null }
    if ($n -gt 1e11) { $n = $n / 1000 }
    return [long][math]::Floor($n)
}

# "2026-09-23T15:00:00.261688+00:00" / "2026-07-26T15:50:00Z" -> epoch seconds
function ConvertFrom-Iso8601($s) {
    # PowerShell 7's ConvertFrom-Json already turned it into a DateTime
    if ($s -is [DateTime]) { return ([DateTimeOffset]$s).ToUnixTimeSeconds() }
    if ($s -isnot [string]) { return $null }
    $m = [regex]::Match($s, '^\s*(\d{4})-(\d{2})-(\d{2})[Tt ](\d{2}):(\d{2})(?::(\d{2}))?(?:[.,]\d+)?([Zz]|[+-]\d{2}:?\d{2})?\s*$')
    if (-not $m.Success) { return $null }
    $sec = if ($m.Groups[6].Success) { [int]$m.Groups[6].Value } else { 0 }
    $offset = [TimeSpan]::Zero
    $z = $m.Groups[7].Value
    if ($z -and $z -ne 'Z' -and $z -ne 'z') {
        $o = [regex]::Match($z, '([+-])(\d{2}):?(\d{2})')
        $offset = New-Object TimeSpan ([int]$o.Groups[2].Value), ([int]$o.Groups[3].Value), 0
        if ($o.Groups[1].Value -eq '-') { $offset = $offset.Negate() }
    }
    try {
        $dto = New-Object DateTimeOffset ([int]$m.Groups[1].Value), ([int]$m.Groups[2].Value), ([int]$m.Groups[3].Value),
            ([int]$m.Groups[4].Value), ([int]$m.Groups[5].Value), $sec, $offset
        return $dto.ToUnixTimeSeconds()
    } catch { return $null }
}

function New-Window($pct, $resetsAt) {
    if ($null -eq $pct) { return $null }
    return [ordered]@{ percent = $pct; resets_at = $resetsAt }
}

function Get-Money($obj) {
    if ($obj -is [ValueType] -and $obj -isnot [bool]) { return [double]$obj }
    if (-not (Test-Object $obj)) { return $null }
    $minor = Get-Prop $obj 'amount_minor'
    if ($minor -isnot [ValueType] -or $minor -is [bool]) { return $null }
    $exp = ConvertTo-Number (Get-Prop $obj 'exponent')
    if ($null -eq $exp) { $exp = 2 }
    return $minor / [math]::Pow(10, $exp)
}

function Read-JsonFile($path) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { return $null }
    try {
        $content = [IO.File]::ReadAllText($path)
        if ([string]::IsNullOrWhiteSpace($content)) { return $null }
        $data = $content | ConvertFrom-Json
        if (Test-Object $data) { return $data }
    } catch { }
    return $null
}

# PSCustomObject from ConvertFrom-Json -> nested ordered hashtables, so it can be edited.
function ConvertTo-Hash($v) {
    if ($v -is [Management.Automation.PSCustomObject]) {
        $h = [ordered]@{}
        foreach ($p in $v.PSObject.Properties) { $h[$p.Name] = ConvertTo-Hash $p.Value }
        return $h
    }
    if ($v -is [Array]) {
        $list = @(foreach ($item in $v) { ConvertTo-Hash $item })
        return , $list
    }
    return $v
}

# ---------------------------------------------------------------- normalize --
# Ports of normalize.lua.
function ConvertFrom-ApiUsage($raw, $now) {
    $st = [ordered]@{ scoped = @(); fetched_at = $now }
    if (-not (Test-Object $raw)) { return $st }

    $limits = Get-Prop $raw 'limits'
    foreach ($l in @($limits)) {
        if (-not (Test-Object $l)) { continue }
        $w = New-Window (Get-Percent (Get-Prop $l 'percent')) (ConvertFrom-Iso8601 (Get-Prop $l 'resets_at'))
        if ($null -eq $w) { continue }
        $kind = Get-Prop $l 'kind'
        $w.kind = $kind
        $w.is_active = ((Get-Prop $l 'is_active') -eq $true)
        if ($kind -eq 'session') {
            if ($null -eq $st.five_hour) { $st.five_hour = $w }
        } elseif ($kind -eq 'weekly_all') {
            if ($null -eq $st.seven_day) { $st.seven_day = $w }
        } elseif ($kind -eq 'weekly_scoped') {
            $scope = Get-Prop $l 'scope'
            $model = if (Test-Object $scope) { Get-Prop $scope 'model' } else { $null }
            $name = $null
            if (Test-Object $model) {
                $name = Get-Prop $model 'display_name'
                if (-not $name) { $name = Get-Prop $model 'id' }
            }
            if ($name) {
                $w.name = $name
                $st.scoped += , $w
            }
        }
    }

    # Legacy fields fill in whatever limits[] did not provide.
    foreach ($key in 'five_hour', 'seven_day') {
        $v = Get-Prop $raw $key
        if ($null -eq $st[$key] -and (Test-Object $v)) {
            $st[$key] = New-Window (Get-Percent (Get-Prop $v 'utilization')) (ConvertFrom-Iso8601 (Get-Prop $v 'resets_at'))
        }
    }
    if ($st.scoped.Count -eq 0) {
        foreach ($entry in @(@('Opus', 'seven_day_opus'), @('Sonnet', 'seven_day_sonnet'))) {
            $v = Get-Prop $raw $entry[1]
            if (Test-Object $v) {
                $w = New-Window (Get-Percent (Get-Prop $v 'utilization')) (ConvertFrom-Iso8601 (Get-Prop $v 'resets_at'))
                if ($w) {
                    $w.name = $entry[0]
                    $st.scoped += , $w
                }
            }
        }
    }

    # Scoped weekly windows share the weekly reset; fill it in when the API left it null.
    foreach ($w in $st.scoped) {
        if ($null -eq $w.resets_at -and $st.seven_day) { $w.resets_at = $st.seven_day.resets_at }
    }

    $s = Get-Prop $raw 'spend'
    $e = Get-Prop $raw 'extra_usage'
    if (Test-Object $s) {
        $used = Get-Prop $s 'used'
        $pct = Get-Percent (Get-Prop $s 'percent')
        $cur = if (Test-Object $used) { Get-Prop $used 'currency' } else { $null }
        $st.spend = [ordered]@{
            enabled = ((Get-Prop $s 'enabled') -eq $true)
            percent = if ($null -ne $pct) { $pct } else { 0 }
            used = Get-Money $used
            currency = if ($cur) { $cur } else { 'USD' }
            limit = Get-Money (Get-Prop $s 'limit')
        }
    } elseif ((Test-Object $e) -and $null -ne (Get-Prop $e 'is_enabled')) {
        $pct = Get-Percent (Get-Prop $e 'utilization')
        $cur = Get-Prop $e 'currency'
        $st.spend = [ordered]@{
            enabled = ((Get-Prop $e 'is_enabled') -eq $true)
            percent = if ($null -ne $pct) { $pct } else { 0 }
            used = ConvertTo-Number (Get-Prop $e 'used_credits')
            currency = if ($cur) { $cur } else { 'USD' }
            limit = ConvertTo-Number (Get-Prop $e 'monthly_limit')
        }
    }

    $b = Get-Prop $raw 'seven_day_breakdown'
    $bRows = Get-Prop $b 'rows'
    if ((Test-Object $b) -and $bRows -is [Array]) {
        $rows = @(foreach ($r in $bRows) {
                $pct = Get-Percent (Get-Prop $r 'percent')
                $dn = Get-Prop $r 'display_name'
                if ($null -ne $pct -and $dn) { [ordered]@{ name = $dn; percent = $pct } }
            })
        if ($rows.Count -gt 0) { $st.breakdown = $rows }
    }
    return $st
}

function ConvertFrom-Statusline($raw, $now) {
    $st = [ordered]@{ scoped = @(); fetched_at = $now }
    if (-not (Test-Object $raw)) { return $st }
    $rl = Get-Prop $raw 'rate_limits'
    if (Test-Object $rl) {
        # a missing window next to a present one means "0 %, not started yet"
        foreach ($key in 'five_hour', 'seven_day') {
            $v = Get-Prop $rl $key
            if (Test-Object $v) {
                $st[$key] = New-Window (Get-Percent (Get-Prop $v 'used_percentage')) (Get-EpochSeconds (Get-Prop $v 'resets_at'))
            } else {
                $st[$key] = [ordered]@{ percent = 0; resets_at = $null; assumed = $true }
            }
        }
        $sl = Get-Prop $rl 'spend_limit'
        if ((Test-Object $sl) -and $null -ne (Get-Percent (Get-Prop $sl 'used_percentage'))) {
            $st.spend = [ordered]@{ enabled = $true; percent = (Get-Percent (Get-Prop $sl 'used_percentage')); currency = 'USD' }
        }
    }
    $ts = Get-EpochSeconds (Get-Prop $raw 'ts')
    if ($null -ne $ts) { $st.fetched_at = $ts }
    return $st
}

function Read-StatuslineCache {
    $raw = Read-JsonFile $StatuslineCache
    if ($raw -and ((Test-Object (Get-Prop $raw 'rate_limits')) -or (Test-Object (Get-Prop $raw 'context')))) { return $raw }
    return $null
}

function Read-ClaudeJson($now) {
    if (-not (Test-Path -LiteralPath $ClaudeJsonPath -PathType Leaf)) { return $null }
    $content = [IO.File]::ReadAllText($ClaudeJsonPath)
    if (-not $content.Contains('"cachedUsageUtilization"')) { return $null }
    try { $data = $content | ConvertFrom-Json } catch { return $null }
    $cu = Get-Prop $data 'cachedUsageUtilization'
    if (-not (Test-Object $cu) -or -not (Test-Object (Get-Prop $cu 'utilization'))) { return $null }
    $st = ConvertFrom-ApiUsage (Get-Prop $cu 'utilization') $now
    $fetched = Get-EpochSeconds (Get-Prop $cu 'fetchedAtMs')
    if ($null -ne $fetched) { $st.fetched_at = $fetched }
    return $st
}

# ------------------------------------------------------------------- format --
# Ports of the bar parts of format.lua, with the theme's options.
function Test-HasData($st) {
    if ($null -eq $st) { return $false }
    return ($null -ne $st.five_hour) -or ($null -ne $st.seven_day) -or ($null -ne $st.scoped -and @($st.scoped).Count -gt 0)
}

function Get-MaxPercent($st) {
    $best = $null
    foreach ($w in @($st.five_hour, $st.seven_day) + @($st.scoped | Where-Object { $null -ne $_ })) {
        $p = Get-Prop $w 'percent'
        if ($p -is [ValueType] -and $p -isnot [bool] -and ($null -eq $best -or $p -gt $best)) { $best = $p }
    }
    return $best
}

function Get-PctText($w) {
    $p = Get-Prop $w 'percent'
    if ($p -is [ValueType] -and $p -isnot [bool]) { return ('{0}%' -f [math]::Floor($p + 0.5)) }
    return '--'
}

$ShortError = @{
    unauthorized = '!auth'; no_credentials = '!cred'; rate_limited = '!429'
    network = '!net'; parse = '!parse'; no_source = '!none'
}

function Get-BarText($st) {
    if (-not (Test-HasData $st)) {
        if ($st.error) {
            $s = $ShortError[[string](Get-Prop $st.error 'code')]
            if ($s) { return $s }
            return '!err'
        }
        return '--'
    }
    $parts = @(('5h ' + (Get-PctText $st.five_hour)), ('7d ' + (Get-PctText $st.seven_day)))
    foreach ($w in @($st.scoped | Where-Object { $null -ne $_ })) {
        $name = [string](Get-Prop $w 'name')
        $len = if ($name.Length -ge 2 -and [char]::IsHighSurrogate($name[0])) { 2 } else { [math]::Min(1, $name.Length) }
        $parts += $name.Substring(0, $len) + ' ' + (Get-PctText $w)
    }
    $text = $parts -join " $Dot "
    if ((Get-Prop $st.sessions 'attention') -gt 0) { $text += " $Flag" }
    return $text.Trim()
}

# normal | warn | crit | error, the level that picks the text colour (format.color_for)
function Get-Level($st) {
    if (-not (Test-HasData $st)) {
        if ($st.error) { return 'error' }
        return 'normal'
    }
    $m = Get-MaxPercent $st
    if ($null -eq $m) { return 'normal' }
    if ($m -ge $CritAt) { return 'crit' }
    if ($m -ge $WarnAt) { return 'warn' }
    return 'normal'
}

# -------------------------------------------------------------------- fetch --
$last = ConvertTo-Hash (Read-JsonFile $LastPath)
if ($null -eq $last) { $last = [ordered]@{} }
$state = $null
$err = $null

# 1) recent result
if ($last.state -and $null -ne $last.fetched_at -and ($Now - $last.fetched_at) -le $MaxAge) {
    $state = $last.state
}

# 2) fresh statusLine cache
if (-not $state) {
    $raw = Read-StatuslineCache
    $ts = if ($raw) { ConvertTo-Number (Get-Prop $raw 'ts') } else { $null }
    if ($null -ne $ts -and ($Now - $ts) -le $FreshCacheMaxAge) {
        $state = ConvertFrom-Statusline $raw $Now
        $state.source = 'statusline'
    }
}

# 3) API, unless backing off
if (-not $state -and -not $NoNetwork) {
    if ($null -ne $last.retry_at -and $Now -lt $last.retry_at) {
        $err = [ordered]@{ code = 'rate_limited'; message = 'backing off'; retry_at = $last.retry_at; at = $Now }
    } else {
        $creds = $null
        $content = $null
        try { $content = [IO.File]::ReadAllText($CredentialsPath) } catch { }
        if ([string]::IsNullOrEmpty($content)) {
            $err = [ordered]@{ code = 'no_credentials'; message = "cannot read $CredentialsPath"; at = $Now }
        } else {
            $data = $null
            try { $data = $content | ConvertFrom-Json } catch { }
            $oauth = Get-Prop $data 'claudeAiOauth'
            $token = Get-Prop $oauth 'accessToken'
            if (-not (Test-Object $data)) {
                $err = [ordered]@{ code = 'no_credentials'; message = 'credentials file is not valid JSON'; at = $Now }
            } elseif ($token -isnot [string] -or $token -eq '') {
                $err = [ordered]@{ code = 'no_credentials'; message = 'no claudeAiOauth.accessToken in credentials'; at = $Now }
            } else {
                $expiresAt = ConvertTo-Number (Get-Prop $oauth 'expiresAt')
                if ($null -ne $expiresAt -and $expiresAt -gt 1e11) { $expiresAt = $expiresAt / 1000 }
                if ($null -ne $expiresAt -and $expiresAt -le $Now) {
                    $err = [ordered]@{ code = 'unauthorized'; message = 'access token expired'; at = $Now }
                } else {
                    $creds = @{ token = $token; subscription = (Get-Prop $oauth 'subscriptionType') }
                }
            }
        }

        if ($creds) {
            try {
                [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
            } catch { }
            $http = $null
            $body = $null
            try {
                $resp = Invoke-WebRequest -Uri $ApiUrl -UseBasicParsing -TimeoutSec $TimeoutSec -UserAgent $UserAgent -Headers @{
                    'Authorization' = "Bearer $($creds.token)"
                    'anthropic-beta' = $BetaHeader
                    'Accept' = 'application/json'
                }
                $http = [int]$resp.StatusCode
                $body = $resp.Content
                if ($body -is [byte[]]) { $body = [Text.Encoding]::UTF8.GetString($body) }
            } catch {
                $r = $_.Exception.Response
                if ($r -and $r.StatusCode) {
                    $http = [int]$r.StatusCode
                } else {
                    $msg = $_.Exception.Message
                    if (-not $msg) { $msg = 'request failed' }
                    $err = [ordered]@{ code = 'network'; message = $msg; at = $Now }
                }
            }

            if ($null -ne $http) {
                if ($http -eq 200) {
                    $data = $null
                    try { $data = $body | ConvertFrom-Json } catch { }
                    if (Test-Object $data) {
                        $state = ConvertFrom-ApiUsage $data $Now
                        $state.source = 'api'
                        $state.subscription = $creds.subscription
                        $last.Remove('retry_at')
                        $last.backoff_attempt = 0
                    } else {
                        $err = [ordered]@{ code = 'parse'; message = 'response is not valid JSON'; http = $http; at = $Now }
                    }
                } else {
                    $code = if ($http -eq 401 -or $http -eq 403) { 'unauthorized' }
                    elseif ($http -eq 429) { 'rate_limited' }
                    elseif ($http -ge 500) { 'network' }
                    else { 'parse' }
                    $err = [ordered]@{ code = $code; message = "HTTP $http"; http = $http; at = $Now }
                }
            }

            # back off after a 429 or a network error, like the widget
            if ($err -and ($err.code -eq 'rate_limited' -or $err.code -eq 'network')) {
                $prev = if ($null -ne $last.backoff_attempt) { [int]$last.backoff_attempt } else { 0 }
                $attempt = [math]::Min($prev + 1, $Backoff.Count)
                $last.backoff_attempt = $attempt
                $last.retry_at = $Now + $Backoff[$attempt - 1]
                $err.retry_at = $last.retry_at
            }
        }
    }
}

# 4) fallbacks
if (-not $state) {
    $raw = Read-StatuslineCache
    if ($raw) {
        $state = ConvertFrom-Statusline $raw $Now
        $state.source = 'statusline'
    }
}
if (-not $state) {
    $state = Read-ClaudeJson $Now
    if ($state) { $state.source = 'claude_json' }
}
if (-not $state -and $last.state) { $state = $last.state }
if (-not $state) { $state = [ordered]@{ scoped = @() } }

# ----------------------------------------------------------------- sessions --
# ~/.claude/sessions/<pid>.json of live processes; waiting/needs_input = needs you.
$sessions = [ordered]@{ total = 0; working = 0; idle = 0; attention = 0 }
if (Test-Path -LiteralPath $SessionsDir -PathType Container) {
    foreach ($f in Get-ChildItem -LiteralPath $SessionsDir -File -Filter '*.json') {
        if ($f.Name -notmatch '^\d+\.json$') { continue }
        $data = Read-JsonFile $f.FullName
        $sessionPid = Get-Prop $data 'pid'
        if ($null -eq $sessionPid) { continue }
        if (-not (Get-Process -Id $sessionPid -ErrorAction SilentlyContinue)) { continue }
        $status = [string](Get-Prop $data 'status')
        $sessions.total++
        if ($status -eq 'busy') { $sessions.working++ }
        elseif ($status -eq 'waiting' -or $status -eq 'needs_input') { $sessions.attention++ }
        else { $sessions.idle++ }
    }
}

if ($null -eq $state.scoped) { $state.scoped = @() }
$state.error = $err
$state.stale = ($null -ne $state.fetched_at) -and (($Now - $state.fetched_at) -gt $StaleAfter)
$state.sessions = $sessions

# persist for the next call (only real fetches refresh the timestamp)
if ($state.source -eq 'api' -or $state.source -eq 'statusline') {
    $last.state = $state
    $last.fetched_at = if ($null -ne $state.fetched_at) { $state.fetched_at } else { $Now }
}
try {
    if (-not (Test-Path -LiteralPath $CacheDir)) { New-Item -ItemType Directory -Path $CacheDir -Force | Out-Null }
    $tmp = "$LastPath.tmp"
    [IO.File]::WriteAllText($tmp, ($last | ConvertTo-Json -Depth 10 -Compress))
    Move-Item -LiteralPath $tmp -Destination $LastPath -Force
} catch { }

# ------------------------------------------------------------------- output --
$text = Get-BarText $state
$color = switch (Get-Level $state) {
    'crit' { $ColorCrit }
    'warn' { $ColorWarn }
    'error' { $ColorError }
    default { $ColorNormal }
}

if ($env:NO_COLOR -or [Console]::IsOutputRedirected) {
    "$Icon $text"
    return
}

# Truecolor where the console does VT sequences (Windows Terminal, WezTerm, conhost
# with VT on), else the nearest console colours.
$vt = $false
try { $vt = [bool]$Host.UI.SupportsVirtualTerminal } catch { }
if ($env:WT_SESSION -or $env:TERM_PROGRAM -or $env:COLORTERM -match 'truecolor|24bit') { $vt = $true }

$prevEncoding = $null
try {
    $prevEncoding = [Console]::OutputEncoding
    [Console]::OutputEncoding = New-Object Text.UTF8Encoding $false
} catch { }
try {
    if ($vt) {
        $esc = [char]27
        function Get-Ansi($hex) {
            $h = $hex.TrimStart('#')
            '{0}[38;2;{1};{2};{3}m' -f $esc, [Convert]::ToInt32($h.Substring(0, 2), 16),
                [Convert]::ToInt32($h.Substring(2, 2), 16), [Convert]::ToInt32($h.Substring(4, 2), 16)
        }
        Write-Host ('{0}{1}{2}[0m {3}{4}{2}[0m' -f (Get-Ansi $ColorIcon), $Icon, $esc, (Get-Ansi $color), $text)
    } else {
        $console = @{ $ColorCrit = 'Red'; $ColorError = 'Gray' }
        $fg = $console[$color]
        if (-not $fg) { $fg = 'DarkYellow' }
        Write-Host $Icon -ForegroundColor DarkYellow -NoNewline
        Write-Host ' ' -NoNewline
        Write-Host $text -ForegroundColor $fg
    }
} finally {
    if ($prevEncoding) { try { [Console]::OutputEncoding = $prevEncoding } catch { } }
}
