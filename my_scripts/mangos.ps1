function Write-Label($text) { Write-Host "$text" -ForegroundColor DarkGray }
#function Write-Cmd  ($text) { Write-Host "$text" -ForegroundColor Cyan     }
function Write-Alt  ($text) { Write-Host "$text" -ForegroundColor Magenta  }
function Write-Extra($text) { Write-Host "$text" -ForegroundColor Blue     }
function Write-Warn ($text) { Write-Host "$text" -ForegroundColor DarkYellow }
function Write-Ok   ($text) { Write-Host "$text" -ForegroundColor Green    }
function Write-Err  ($text) { Write-Host "$text" -ForegroundColor Red      }

# Build dirs are searched for these config folders; the newest mangosd.exe wins
$BUILD_DIR_PATTERN = "build*"
$BIN_DIR_NAME = "bin"
$CONFIG_DIR_PATTERNS = @("*release*", "*relwithdebinfo*", "*debug*")
$CONFIG_SEARCH_DEPTH = 3
$SERVER_EXE = "mangosd.exe"
$BUILD_TIME_FORMAT = "yyyy-MM-dd HH:mm:ss"

# Data dirs each server needs next to its exe
# vmangos never reads a Cameras/ dir (no file access to it in src/)
$VMANGOS_REQUIRED_DIRS        = @("5875", "maps", "mmaps", "vmaps")
$MANGOS_CLASSIC_REQUIRED_DIRS = @("Cameras", "dbc", "maps", "mmaps", "vmaps")
# Buildings/ is only extractor scratch (vmapextract -> vmap_assembler), the server never reads it
$MANGOS_TBC_REQUIRED_DIRS     = @("Cameras", "dbc", "maps")
# Current mangoszero reads tiles/ + gomodels/ (World.cpp) instead of maps/ + vmaps/
$MANGOSZERO_REQUIRED_DIRS     = @("dbc", "gomodels", "mmaps", "tiles")

# Reported but not treated as an error - older mangos-tbc builds ran without these
$MANGOS_TBC_OPTIONAL_DIRS     = @("mmaps", "vmaps")
$NO_OPTIONAL_DIRS             = @()

# Extracted data (finish_*_extraction.py output) is looked for here first; the exe dir is
# the fallback. Each server's dir name is set in its branch below.
$LOCAL_DATA_ROOT = "C:/local"
$SERVER_CONF = "mangosd.conf"

# mangoszero runtime DLLs, searched for under any installed version
$PROGRAM_FILES = if ($env:ProgramW6432) { $env:ProgramW6432 } else { $env:ProgramFiles }
$MYSQL_SERVER_DIR_PATTERN = "MySQL Server *"   # below <Program Files>\MySQL
$MYSQL_DLL_SUBDIRS = @("lib", "bin")
$MYSQL_DLL = "libmysql.dll"
$OPENSSL_DIR_PATTERN = "OpenSSL*"              # e.g. OpenSSL-Win64, OpenSSL-Win64_v4
$OPENSSL_PROVIDER_SUBDIRS = @("bin", "bin/ossl-modules", "lib/ossl-modules", "lib")
$OPENSSL_LEGACY_DLL = "legacy.dll"
$OPENSSL_MODULES_DIR = "ossl-modules"          # where mangosd looks, beside the exe

# vmangos runtime DLLs: the prebuilt deps its own CMake install step copies
$VMANGOS_DEP_LIB_SUBPATH = "dep/windows/lib"   # then <arch>_<config>, e.g. x64_release
$VMANGOS_DLLS = @("libeay32.dll", "libmySQL.dll")
$PE_MACHINE_ARCH = @{ 0x8664 = "x64"; 0x014C = "win32" }

# libmysql check: the libmysql mangosd/realmd load has to log in as the confs' db users.
# libmysql before 8.0 (vmangos ships 5.5) only knows mysql_native_password, not MySQL 8's
# default caching_sha2_password - such a db user is switched to mysql_native_password.
$REALMD_EXE = "realmd.exe"
$REALMD_CONF = "realmd.conf"
$MYSQL_DLL_IMPORT_PATTERN = 'libmysql\.dll'
$MYSQL_SHA2_MIN_MAJOR = 8
$MYSQL_NATIVE_PLUGIN = "mysql_native_password"
$MYSQL_SHA2_PLUGINS = @("caching_sha2_password", "sha256_password")
$MYSQL_CLI = "mysql.exe"
$DB_INFO_PATTERN = '^\s*\w*Database\.?Info\s*=\s*"([^"]*)"'   # host;port;user;password;db
$LOCAL_CONFIG_FILE = "C:/local/config.txt"     # root_user / root_pwd, as the db setup scripts use
$CONFIG_KEY_ROOT_USER = "root_user"
$CONFIG_KEY_ROOT_PWD = "root_pwd"

function Find-ServerBuilds($repoRoots) {
	# Every <root>/build*/**/<config>/mangosd.exe and <root>/bin/**/<config>/mangosd.exe,
	# newest build first.
	$found = New-Object System.Collections.Generic.List[object]

	foreach ($root in $repoRoots) {
		if (-not (Test-Path $root)) { continue }

		$searchRoots = Get-ChildItem -Path $root -Directory -ErrorAction SilentlyContinue |
			Where-Object { $_.Name -like $BUILD_DIR_PATTERN -or $_.Name -ieq $BIN_DIR_NAME }

		foreach ($searchRoot in $searchRoots) {
			$dirs = Get-ChildItem -Path $searchRoot.FullName -Directory -Recurse -Depth $CONFIG_SEARCH_DEPTH -ErrorAction SilentlyContinue

			foreach ($dir in $dirs) {
				$isConfigDir = $false
				foreach ($pattern in $CONFIG_DIR_PATTERNS) {
					if ($dir.Name -like $pattern) { $isConfigDir = $true; break }
				}
				if (-not $isConfigDir) { continue }

				$exePath = Join-Path -Path $dir.FullName -ChildPath $SERVER_EXE
				if (Test-Path $exePath) { $found.Add((Get-Item $exePath)) }
			}
		}
	}

	if ($found.Count -eq 0) { return $null }
	return $found.ToArray() | Sort-Object LastWriteTime -Descending
}

function Resolve-ServerPath($repoRoots, $fallbackPath) {
	$builds = Find-ServerBuilds $repoRoots

	if ($builds) {
		$newest = $builds[0]
		Write-Label "Using newest build: $($newest.Directory.FullName)"
		Write-Label "  $SERVER_EXE built $($newest.LastWriteTime.ToString($BUILD_TIME_FORMAT))"

		foreach ($older in ($builds | Select-Object -Skip 1)) {
			Write-Label "  (older: $($older.Directory.FullName) - $($older.LastWriteTime.ToString($BUILD_TIME_FORMAT)))"
		}

		return $newest.Directory.FullName
	}

	if ($fallbackPath) {
		Write-Warn "No $SERVER_EXE was found in the local build dirs. Using fallback path: $fallbackPath"
		return $fallbackPath
	}

	Write-Err "No $SERVER_EXE was found under: $($repoRoots -join ', ')"
	exit 1
}

function Test-RequiredDirs($path, $requiredDirs, $optionalDirs) {
	$missing = New-Object System.Collections.Generic.List[string]

	foreach ($dirName in $requiredDirs) {
		if (Test-Path -Path (Join-Path -Path $path -ChildPath $dirName) -PathType Container) {
			Write-Ok "$dirName/ found."
		} else {
			Write-Err "$dirName/ is missing from $path"
			$missing.Add($dirName)
		}
	}

	foreach ($dirName in $optionalDirs) {
		if (Test-Path -Path (Join-Path -Path $path -ChildPath $dirName) -PathType Container) {
			Write-Ok "$dirName/ found."
		} else {
			Write-Warn "$dirName/ is missing - optional, older builds did not need it."
		}
	}

	if ($missing.Count -gt 0) {
		Write-Warn "$($missing.Count) of $($requiredDirs.Count) required dir(s) missing: $($missing.ToArray() -join ', ')"
	}
}

function Test-DisabledSetting($lines, $setting, $fileName, $clientName) {
	$pattern = '^\s*' + [regex]::Escape($setting) + '\s*=\s*([^\s#]+)'

	foreach ($line in $lines) {
		if ($line -match $pattern) {
			$value = $matches[1]

			if ($value -eq "0") {
				Write-Ok "$setting = 0 in $fileName - correctly disabled."
			} elseif ($value -eq "1") {
				Write-Err "$setting = 1 in $fileName - it needs to be disabled to use custom clients like $clientName."
			} else {
				Write-Warn "$setting has unexpected value '$value' in $fileName."
			}

			return
		}
	}

	Write-Warn "$setting was not found in $fileName."
}

function Resolve-DataPath($localDataPath, $exePath, $requiredDirs) {
	# The local extracted-data dir if it holds any of the required dirs, else the exe dir.
	if ($localDataPath -and (Test-Path -Path $localDataPath -PathType Container)) {
		$present = @($requiredDirs | Where-Object {
			Test-Path -Path (Join-Path -Path $localDataPath -ChildPath $_) -PathType Container
		})
		if ($present.Count -gt 0) {
			Write-Label "Using extracted data dir: $localDataPath"
			return $localDataPath
		}
		Write-Warn "$localDataPath holds none of: $($requiredDirs -join ', ') - falling back to the exe dir."
	} elseif ($localDataPath) {
		Write-Warn "$localDataPath not found - falling back to the exe dir."
	}

	Write-Label "Using data in the exe dir: $exePath"
	return $exePath
}

function ConvertTo-ComparablePath($path) {
	$full = [System.IO.Path]::GetFullPath($path)
	return $full.TrimEnd('\', '/').ToLowerInvariant()
}

function Test-ConfDataDir($exePath, $dataPath) {
	# The server only reads DataDir from its conf, so say so when it points elsewhere.
	$confPath = Join-Path -Path $exePath -ChildPath $SERVER_CONF
	if (-not (Test-Path $confPath)) {
		Write-Warn "$SERVER_CONF was not found - cannot check DataDir."
		return
	}

	$line = Get-Content $confPath | Where-Object { $_ -match '^\s*DataDir\s*=\s*"?([^"#]*)"?' } | Select-Object -First 1
	if (-not $line) {
		Write-Warn "DataDir was not found in $SERVER_CONF."
		return
	}

	$null = $line -match '^\s*DataDir\s*=\s*"?([^"#]*)"?'
	$confDataDir = $matches[1].Trim()
	$resolved = if ([System.IO.Path]::IsPathRooted($confDataDir)) { $confDataDir } else { Join-Path -Path $exePath -ChildPath $confDataDir }

	if ((ConvertTo-ComparablePath $resolved) -eq (ConvertTo-ComparablePath $dataPath)) {
		Write-Ok "DataDir in $SERVER_CONF points at the data dir: $confDataDir"
	} else {
		Write-Err "DataDir in $SERVER_CONF is `"$confDataDir`" but the data was found in $dataPath."
	}
}

function Get-FolderVersion($name) {
	# "MySQL Server 8.0" -> 8.0, so the newest install sorts first
	if ($name -match '(\d+(\.\d+)+)') { return [version]$matches[1] }
	if ($name -match '(\d+)') { return [version]"$($matches[1]).0" }
	return [version]"0.0"
}

function Get-ImportedDll($exePath, $pattern) {
	# DLL names an exe imports are plain ASCII in its import table
	$text = [System.Text.Encoding]::ASCII.GetString([System.IO.File]::ReadAllBytes($exePath))
	$match = [regex]::Match($text, $pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
	if ($match.Success) { return $match.Value }
	return $null
}

function Find-LoadedDll($exeDir, $dllName) {
	# Same order the Windows loader uses for a desktop app: exe dir, System32, then PATH
	$dirs = @($exeDir, (Join-Path -Path $env:windir -ChildPath "System32")) + ($env:Path -split ';' | Where-Object { $_ })
	foreach ($dir in $dirs) {
		$candidate = Join-Path -Path $dir -ChildPath $dllName
		if (Test-Path -Path $candidate -PathType Leaf) { return Get-Item $candidate }
	}
	return $null
}

function Copy-IfChanged($source, $destination) {
	if ((Test-Path -Path $destination -PathType Leaf) -and
		((Get-FileHash $source).Hash -eq (Get-FileHash $destination).Hash)) {
		Write-Ok "$destination is up to date."
		return
	}

	$destinationDir = Split-Path -Path $destination -Parent
	if (-not (Test-Path $destinationDir)) { New-Item -ItemType Directory -Path $destinationDir | Out-Null }

	try {
		Copy-Item -Path $source -Destination $destination -Force -ErrorAction Stop
		Write-Ok "Copied $source -> $destination"
	} catch {
		# Usually mangosd/realmd still running and holding the DLL open
		Write-Err "Could not copy $source -> ${destination}: $($_.Exception.Message)"
	}
}

function Copy-MySqlDll($exePath) {
	$mysqlRoot = Join-Path -Path $PROGRAM_FILES -ChildPath "MySQL"
	$servers = Get-ChildItem -Path $mysqlRoot -Directory -Filter $MYSQL_SERVER_DIR_PATTERN -ErrorAction SilentlyContinue |
		Sort-Object { Get-FolderVersion $_.Name } -Descending

	foreach ($server in $servers) {
		foreach ($subDir in $MYSQL_DLL_SUBDIRS) {
			$source = Join-Path -Path $server.FullName -ChildPath "$subDir/$MYSQL_DLL"
			if (Test-Path -Path $source -PathType Leaf) {
				Write-Label "$MYSQL_DLL from $($server.Name) ($((Get-Item $source).VersionInfo.ProductVersion))"
				Copy-IfChanged $source (Join-Path -Path $exePath -ChildPath $MYSQL_DLL)
				return $source
			}
		}
	}

	Write-Err "No $MYSQL_DLL found under $mysqlRoot\$MYSQL_SERVER_DIR_PATTERN\{$($MYSQL_DLL_SUBDIRS -join ',')}"
}

function Copy-OpenSslLegacyProvider($exePath) {
	# legacy.dll has to match the libcrypto mangosd really loads; a newer OpenSSL install
	# (e.g. 4.x next to 3.x) ships a provider that libcrypto-3 cannot load.
	$exe = Join-Path -Path $exePath -ChildPath $SERVER_EXE
	$cryptoName = Get-ImportedDll $exe 'libcrypto-\d+(-x64)?\.dll'
	if (-not $cryptoName) {
		Write-Label "$SERVER_EXE does not import libcrypto - no OpenSSL provider needed."
		return
	}

	$crypto = Find-LoadedDll $exePath $cryptoName
	if (-not $crypto) {
		Write-Err "$SERVER_EXE imports $cryptoName but it was not found beside the exe, in System32 or on PATH."
		return
	}
	$cryptoVersion = $crypto.VersionInfo.ProductVersion
	$cryptoMajor = ($cryptoVersion -split '\.')[0]
	Write-Label "$SERVER_EXE loads $($crypto.FullName) ($cryptoVersion)"

	$candidates = foreach ($root in (Get-ChildItem -Path $PROGRAM_FILES -Directory -Filter $OPENSSL_DIR_PATTERN -ErrorAction SilentlyContinue)) {
		foreach ($subDir in $OPENSSL_PROVIDER_SUBDIRS) {
			$path = Join-Path -Path $root.FullName -ChildPath "$subDir/$OPENSSL_LEGACY_DLL"
			if (Test-Path -Path $path -PathType Leaf) { Get-Item $path }
		}
	}

	$exact = @($candidates | Where-Object { $_.VersionInfo.ProductVersion -eq $cryptoVersion })
	$sameMajor = @($candidates | Where-Object { ($_.VersionInfo.ProductVersion -split '\.')[0] -eq $cryptoMajor })
	if ($exact.Count -gt 0) {
		$source = $exact[0]
	} elseif ($sameMajor.Count -gt 0) {
		$source = $sameMajor[0]
		Write-Warn "No $OPENSSL_LEGACY_DLL $cryptoVersion found; using $($source.VersionInfo.ProductVersion) from the same major version."
	} else {
		$seen = ($candidates | ForEach-Object { "$($_.FullName) ($($_.VersionInfo.ProductVersion))" }) -join ', '
		Write-Err "No $OPENSSL_LEGACY_DLL matching OpenSSL $cryptoVersion under $PROGRAM_FILES\$OPENSSL_DIR_PATTERN. Found: $(if ($seen) { $seen } else { 'none' })"
		return
	}

	Write-Label "$OPENSSL_LEGACY_DLL from $($source.FullName) ($($source.VersionInfo.ProductVersion))"
	Copy-IfChanged $source.FullName (Join-Path -Path $exePath -ChildPath "$OPENSSL_MODULES_DIR/$OPENSSL_LEGACY_DLL")
}

function Get-PeArch($exePath) {
	# "x64" / "win32" from the PE header's machine field, or $null
	$stream = [System.IO.File]::OpenRead($exePath)
	try {
		$header = New-Object byte[] 4096
		$read = $stream.Read($header, 0, $header.Length)
	} finally {
		$stream.Dispose()
	}
	if ($read -lt 0x40 -or $header[0] -ne 0x4D -or $header[1] -ne 0x5A) { return $null }
	$peOffset = [System.BitConverter]::ToInt32($header, 0x3C)
	if ($peOffset -lt 0 -or $peOffset + 6 -gt $read) { return $null }
	if ([System.Text.Encoding]::ASCII.GetString($header, $peOffset, 4) -ne "PE`0`0") { return $null }
	return $PE_MACHINE_ARCH[[int][System.BitConverter]::ToUInt16($header, $peOffset + 4)]
}

function Copy-VmangosDlls($exePath, $repoRoots) {
	# libeay32.dll + libmySQL.dll from the repo's prebuilt deps, matching the exe's arch and config
	$arch = Get-PeArch (Join-Path -Path $exePath -ChildPath $SERVER_EXE)
	if (-not $arch) {
		Write-Err "Could not read the architecture of $SERVER_EXE in $exePath."
		return
	}
	# The deps only come in release/debug; RelWithDebInfo uses the release DLLs like CMake does
	$config = if ((Split-Path -Path $exePath -Leaf) -ieq "debug") { "debug" } else { "release" }

	$exeFull = ConvertTo-ComparablePath $exePath
	$repoRoot = $repoRoots | Where-Object {
		(Test-Path $_) -and $exeFull.StartsWith((ConvertTo-ComparablePath $_) + [System.IO.Path]::DirectorySeparatorChar)
	} | Select-Object -First 1
	if (-not $repoRoot) {
		Write-Err "$exePath is not inside any of: $($repoRoots -join ', ')"
		return
	}

	$depRoot = Join-Path -Path $repoRoot -ChildPath $VMANGOS_DEP_LIB_SUBPATH
	$depDir = Get-ChildItem -Path $depRoot -Directory -ErrorAction SilentlyContinue |
		Where-Object { $_.Name -ieq "${arch}_$config" } | Select-Object -First 1
	if (-not $depDir) {
		Write-Err "No ${arch}_$config dir under $depRoot"
		return
	}

	Write-Label "From $($depDir.FullName)"
	$mysqlSource = $null
	foreach ($dll in $VMANGOS_DLLS) {
		$source = Join-Path -Path $depDir.FullName -ChildPath $dll
		if (Test-Path -Path $source -PathType Leaf) {
			Copy-IfChanged $source (Join-Path -Path $exePath -ChildPath $dll)
			if ($dll -match $MYSQL_DLL_IMPORT_PATTERN) { $mysqlSource = $source }
		} else {
			Write-Err "$dll is missing from $($depDir.FullName)"
		}
	}
	# The libmysql the exes should load, for Test-MySqlClient
	return $mysqlSource
}

function Get-DllMajor($file) {
	# "5.5.62.0" -> 5, or $null when the DLL carries no version
	$version = $file.VersionInfo.ProductVersion
	if (-not $version) { $version = $file.VersionInfo.FileVersion }
	if ($version -match '^\s*(\d+)') { return [int]$matches[1] }
	return $null
}

function Get-LocalConfigValue($key) {
	# "key: value" lines, the format config_reader.py reads
	if (-not (Test-Path -Path $LOCAL_CONFIG_FILE -PathType Leaf)) { return $null }
	$prefix = "$($key.ToLowerInvariant()):"
	foreach ($line in (Get-Content $LOCAL_CONFIG_FILE)) {
		$trimmed = $line.Trim()
		if ($trimmed.ToLowerInvariant().StartsWith($prefix)) { return $trimmed.Substring($prefix.Length).Trim() }
	}
	return $null
}

function Find-MySqlCli {
	$command = Get-Command $MYSQL_CLI -ErrorAction SilentlyContinue | Select-Object -First 1
	if ($command) { return $command.Source }

	$mysqlRoot = Join-Path -Path $PROGRAM_FILES -ChildPath "MySQL"
	$servers = Get-ChildItem -Path $mysqlRoot -Directory -Filter $MYSQL_SERVER_DIR_PATTERN -ErrorAction SilentlyContinue |
		Sort-Object { Get-FolderVersion $_.Name } -Descending
	foreach ($server in $servers) {
		$candidate = Join-Path -Path $server.FullName -ChildPath "bin/$MYSQL_CLI"
		if (Test-Path -Path $candidate -PathType Leaf) { return $candidate }
	}
	return $null
}

function ConvertTo-SqlString($value) {
	return "'" + $value.Replace('\', '\\').Replace("'", "''") + "'"
}

function Invoke-MySqlRoot($cli, $rootUser, $rootPwd, $sql) {
	# Result rows as tab-separated strings; throws with mysql's message on failure.
	# The password goes through MYSQL_PWD so it is not on the command line.
	$previousPwd = $env:MYSQL_PWD
	$env:MYSQL_PWD = $rootPwd
	try {
		$output = & $cli -u $rootUser -N -B -e $sql 2>&1 | ForEach-Object { "$_" }
		$exitCode = $LASTEXITCODE
	} finally {
		if ($null -eq $previousPwd) { Remove-Item Env:MYSQL_PWD -ErrorAction SilentlyContinue } else { $env:MYSQL_PWD = $previousPwd }
	}
	if ($exitCode -ne 0) { throw ($output -join " ") }
	return @($output | Where-Object { $_ -and $_ -notmatch '^mysql: \[Warning\]' })
}

function Get-DbLogins($exePath) {
	# user -> password from the *Database*Info lines of the confs beside the exe
	$logins = [ordered]@{}
	foreach ($conf in @($SERVER_CONF, $REALMD_CONF)) {
		$confPath = Join-Path -Path $exePath -ChildPath $conf
		if (-not (Test-Path -Path $confPath -PathType Leaf)) { continue }
		foreach ($line in (Get-Content $confPath)) {
			if ($line -notmatch $DB_INFO_PATTERN) { continue }
			$parts = $matches[1] -split ';'
			if ($parts.Count -ge 4 -and -not $logins.Contains($parts[2])) { $logins[$parts[2]] = $parts[3] }
		}
	}
	return $logins
}

function Repair-DbAuthPlugins($exePath) {
	# Switch the confs' db users to mysql_native_password, which a pre-8.0 libmysql can use.
	$logins = Get-DbLogins $exePath
	if ($logins.Count -eq 0) {
		Write-Warn "No *DatabaseInfo lines in $SERVER_CONF / $REALMD_CONF - cannot check the db users."
		return
	}

	$cli = Find-MySqlCli
	$rootUser = Get-LocalConfigValue $CONFIG_KEY_ROOT_USER
	$rootPwd = Get-LocalConfigValue $CONFIG_KEY_ROOT_PWD
	if (-not $cli -or -not $rootUser -or $null -eq $rootPwd) {
		Write-Warn "Cannot check the db users (needs $MYSQL_CLI and $CONFIG_KEY_ROOT_USER / $CONFIG_KEY_ROOT_PWD in $LOCAL_CONFIG_FILE). If the login fails, run as root:"
		foreach ($user in $logins.Keys) {
			Write-Extra "  ALTER USER '$user'@'localhost' IDENTIFIED WITH $MYSQL_NATIVE_PLUGIN BY '<password>';"
		}
		return
	}

	try {
		$status = @(Invoke-MySqlRoot $cli $rootUser $rootPwd "SELECT PLUGIN_STATUS FROM information_schema.PLUGINS WHERE PLUGIN_NAME = '$MYSQL_NATIVE_PLUGIN';")
		if (-not $status -or $status[0] -ne "ACTIVE") {
			Write-Err "The server's $MYSQL_NATIVE_PLUGIN plugin is not active - set $MYSQL_NATIVE_PLUGIN=ON under [mysqld] in my.ini (MySQL 8.4) and restart MySQL."
			return
		}

		foreach ($user in $logins.Keys) {
			$rows = @(Invoke-MySqlRoot $cli $rootUser $rootPwd "SELECT host, plugin FROM mysql.user WHERE user = $(ConvertTo-SqlString $user);")
			if (-not $rows) {
				Write-Err "The db user '$user' from the confs does not exist."
				continue
			}
			foreach ($row in $rows) {
				$userHost, $plugin = $row -split "`t"
				$account = "'$user'@'$userHost'"
				if ($plugin -eq $MYSQL_NATIVE_PLUGIN) {
					Write-Ok "$account uses $plugin."
				} elseif ($MYSQL_SHA2_PLUGINS -contains $plugin) {
					$alter = "ALTER USER $(ConvertTo-SqlString $user)@$(ConvertTo-SqlString $userHost) IDENTIFIED WITH $MYSQL_NATIVE_PLUGIN BY $(ConvertTo-SqlString $logins[$user]);"
					Invoke-MySqlRoot $cli $rootUser $rootPwd $alter | Out-Null
					Write-Ok "$account switched from $plugin to $MYSQL_NATIVE_PLUGIN (password from the conf)."
				} else {
					Write-Warn "$account uses $plugin - left as it is."
				}
			}
		}
	} catch {
		Write-Err "MySQL check failed: $($_.Exception.Message)"
	}
}

function Test-MySqlClient($exePath, $expectedDll) {
	# The libmysql mangosd/realmd really load: the expected file, the exe's arch, and a version
	# that can log in with the db users' auth plugin (the users are fixed when it cannot).
	$checked = 0
	$oldClient = $null
	foreach ($exeName in @($SERVER_EXE, $REALMD_EXE)) {
		$exe = Join-Path -Path $exePath -ChildPath $exeName
		if (-not (Test-Path -Path $exe -PathType Leaf)) { continue }

		$dllName = Get-ImportedDll $exe $MYSQL_DLL_IMPORT_PATTERN
		if (-not $dllName) {
			Write-Label "$exeName does not import libmysql."
			continue
		}
		$dll = Find-LoadedDll $exePath $dllName
		if (-not $dll) {
			Write-Err "$exeName imports $dllName but it was not found beside the exe, in System32 or on PATH."
			continue
		}
		$checked++

		$version = $dll.VersionInfo.ProductVersion
		$exeArch = Get-PeArch $exe
		$dllArch = Get-PeArch $dll.FullName
		Write-Label "$exeName loads $($dll.FullName) ($version, $dllArch)"
		if ($exeArch -and $dllArch -and $exeArch -ne $dllArch) {
			Write-Err "$dllName is $dllArch but $exeName is $exeArch - it cannot be loaded."
		}
		if ($expectedDll -and (Test-Path -Path $expectedDll -PathType Leaf) -and
			((Get-FileHash $dll.FullName).Hash -ne (Get-FileHash $expectedDll).Hash)) {
			Write-Err "$($dll.FullName) is not $expectedDll ($((Get-Item $expectedDll).VersionInfo.ProductVersion)) - stop mangosd/realmd and run this again so it gets copied."
		}

		$major = Get-DllMajor $dll
		if ($null -eq $major) {
			Write-Warn "$($dll.FullName) carries no version - cannot tell which auth plugins it supports."
		} elseif ($major -lt $MYSQL_SHA2_MIN_MAJOR) {
			$oldClient = "$dllName $version"
		}
	}

	if ($checked -eq 0) { return }
	if (-not $oldClient) {
		Write-Ok "libmysql supports MySQL 8's caching_sha2_password."
		return
	}
	Write-Warn "$oldClient predates MySQL 8 - the db users need $MYSQL_NATIVE_PLUGIN, not caching_sha2_password."
	Repair-DbAuthPlugins $exePath
}

# Usage (no server name = vmangos):
#   mangos.ps1
#   mangos.ps1 tbc        (same as t, mangos-tbc, mangostbc, cmangos-tbc)
#   mangos.ps1 classic    (same as c, cm, cmangos, mangos-classic)
#   mangos.ps1 zero       (same as 0, z, mz, mangos0, mangoszero)
# Server name -> accepted names, matched lower-cased with '-', '_', '.' and spaces dropped.
# Keep in sync with {my_notes_path}/scripts/wow/update_conf_classic.py and dotfiles/bin/my_scripts/mangos.sh.
$SERVER_ALIASES = [ordered]@{
	"vmangos"     = @("v", "vm", "vmangos")
	"cmangos"     = @("c", "cm", "classic", "cmangos", "cmangosclassic", "mangosclassic")
	"cmangos-tbc" = @("t", "tbc", "mangostbc", "cmangostbc")
	"mangoszero"  = @("0", "z", "zero", "mz", "mangos0", "mangoszero")
}
$SERVER_NAMES_HELP = "vmangos (v, vm), cmangos (c, cm, classic, mangos-classic), cmangos-tbc (t, tbc, mangos-tbc), mangoszero (0, z, zero, mz, mangos0)"
$DEFAULT_SERVER = "vmangos"

function Resolve-ServerName($name) {
	$key = "$name".ToLowerInvariant() -replace '[-_.\s]', ''
	foreach ($canonical in $SERVER_ALIASES.Keys) {
		if ($SERVER_ALIASES[$canonical] -contains $key) { return $canonical }
	}
	return $null
}

# "$(...)": a bare 0 arrives as the int 0, which would otherwise count as "no argument"
if ($args.Count -eq 0 -or "$($args[0])" -eq "") {
	$server = $DEFAULT_SERVER
} else {
	$server = Resolve-ServerName $args[0]
	if (-not $server) {
		Write-Err "Unknown server '$($args[0])'. Accepted: $SERVER_NAMES_HELP"
		exit 1
	}
}

# MangosZero
if ($server -eq "mangoszero") {
	Write-Alt "MangosZero chosen..."
	$repoRoots = @(
		(Join-Path -Path $env:code_root_dir -ChildPath "Code2/C++/server"),
		(Join-Path -Path $env:code_root_dir -ChildPath "Code2/C++/mangoszero/server")
	)
	$fallbackPath = $null
	$requiredDirs = $MANGOSZERO_REQUIRED_DIRS
	$optionalDirs = $NO_OPTIONAL_DIRS
	$localDataPath = "$LOCAL_DATA_ROOT/mangos_zero_win"

# Cmangos
} elseif ($server -eq "cmangos") {
	Write-Alt "Cmangos chosen..."
	$repoRoots = @(
		(Join-Path -Path $env:code_root_dir -ChildPath "Code2/C++/mangos-classic"),
		(Join-Path -Path $env:code_root_dir -ChildPath "Code2/C++/cmangos/mangos-classic")
	)
	$fallbackPath = "~/cmangos/run/bin"
	$requiredDirs = $MANGOS_CLASSIC_REQUIRED_DIRS
	$optionalDirs = $NO_OPTIONAL_DIRS
	$localDataPath = $null

} elseif ($server -eq "cmangos-tbc") {
	Write-Alt "Cmangos tbc chosen..."
	$repoRoots = @(
		(Join-Path -Path $env:code_root_dir -ChildPath "Code2/C++/mangos-tbc"),
		(Join-Path -Path $env:code_root_dir -ChildPath "Code2/C++/cmangos/mangos-tbc")
	)
	$fallbackPath = $null
	$requiredDirs = $MANGOS_TBC_REQUIRED_DIRS
	$optionalDirs = $MANGOS_TBC_OPTIONAL_DIRS
	$localDataPath = "$LOCAL_DATA_ROOT/mangos_tbc_win"

# Default to Vmangos
} else {
	Write-Alt "Vmangos chosen..."
	$repoRoots = @(
		(Join-Path -Path $env:code_root_dir -ChildPath "Code2/C++/core"),
		(Join-Path -Path $env:code_root_dir -ChildPath "Code2/C++/vmangos/core")
	)
	$fallbackPath = "~/vmangos/bin"
	$requiredDirs = $VMANGOS_REQUIRED_DIRS
	$optionalDirs = $NO_OPTIONAL_DIRS
	$localDataPath = "$LOCAL_DATA_ROOT/vmangos_win"
}

$path = Resolve-ServerPath $repoRoots $fallbackPath

cd $path

Write-Label "Current directory: $path"

Write-Host

$dataPath = Resolve-DataPath $localDataPath $path $requiredDirs
Test-RequiredDirs $dataPath $requiredDirs $optionalDirs
Test-ConfDataDir $path $dataPath

$expectedMySqlDll = $null
if ($server -eq "mangoszero") {
	Write-Host
	$expectedMySqlDll = Copy-MySqlDll $path
	Copy-OpenSslLegacyProvider $path
} elseif ($server -eq "vmangos") {
	Write-Host
	$expectedMySqlDll = Copy-VmangosDlls $path $repoRoots
}

Write-Host
Test-MySqlClient $path $expectedMySqlDll

if ($server -eq "cmangos-tbc") {
    Write-Host

	if (Test-Path "anticheat.conf") {
		$anticheatLines = Get-Content "anticheat.conf"

		$anticheatSection = -1
		for ($i = 0; $i -lt $anticheatLines.Count; $i++) {
			if ($anticheatLines[$i] -match '^\s*\[AnticheatConf\]') {
				$anticheatSection = $i
				break
			}
		}

		if ($anticheatSection -eq -1) {
			Write-Warn "[AnticheatConf] was not found in anticheat.conf."
		} else {
			$sectionLines = $anticheatLines | Select-Object -Skip ($anticheatSection + 1) -First 20
			Test-DisabledSetting $sectionLines "Enable" "anticheat.conf" "wow_client (wc)"
		}

		Test-DisabledSetting $anticheatLines "Warden.Enable" "anticheat.conf" "wow_client (wc)"
	} else {
		Write-Label "anticheat.conf was not found."
	}

	if (Test-Path "realmd.conf") {
		$realmdLines = Get-Content "realmd.conf"
		Test-DisabledSetting $realmdLines "StrictVersionCheck" "realmd.conf" "wow_client (wc)"
	} else {
		Write-Warn "realmd.conf was not found."
	}
} elseif ($server -eq "vmangos") {
    Write-Host

	if (Test-Path "realmd.conf") {
		$realmdLines = Get-Content "realmd.conf"
		Test-DisabledSetting $realmdLines "StrictVersionCheck" "realmd.conf" "benilla"
	} else {
		Write-Warn "realmd.conf was not found."
	}
}

Write-Host

#echo "$path/mangosd.exe"
#Invoke-Expression "$path/realmd.exe;"

Write-Extra "$path/realmd.exe; $path/mangosd.exe"
#Invoke-Expression "$path\mangosd.exe"
