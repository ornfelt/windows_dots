# see:
# $env:my_notes_path/scripts/files/rs_flags/rs_flags.py
$notes = $env:my_notes_path

if ([string]::IsNullOrWhiteSpace($notes)) {
    Write-Host "Environment variable 'my_notes_path' is not set."
    exit 1
}

function Write-Err {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Red
}

function Get-PythonExe {
    $candidates = @(
        @{ Cmd = "py";      Args = @("-3", "-c", "import sys; print(sys.executable)") }
        @{ Cmd = "python";  Args = @("-c", "import sys; print(sys.executable)") }
        @{ Cmd = "python3"; Args = @("-c", "import sys; print(sys.executable)") }
    )

    foreach ($candidate in $candidates) {
        $cmd = $candidate.Cmd

        $commands = Get-Command $cmd -All -ErrorAction SilentlyContinue
        if (-not $commands) {
            continue
        }

        foreach ($command in $commands) {
            $source = $command.Source

            if ([string]::IsNullOrWhiteSpace($source)) {
                continue
            }

            # Skip known broken Microsoft Store aliases
            if ($source -like "*\AppData\Local\Microsoft\WindowsApps\python*.exe") {
                continue
            }

            try {
                $output = & $source @($candidate.Args) 2>$null
                $exitCode = $LASTEXITCODE

                if ($exitCode -ne 0) {
                    continue
                }

                $realExe = ($output | Select-Object -First 1).ToString().Trim()

                if ([string]::IsNullOrWhiteSpace($realExe)) {
                    continue
                }

                if (-not (Test-Path $realExe)) {
                    continue
                }

                # Final sanity check
                & $realExe --version *> $null

                if ($LASTEXITCODE -eq 0) {
                    return $realExe
                }
            }
            catch {
                continue
            }
        }
    }

    Write-Err "Python not found in PATH. Install Python 3 or ensure it is on PATH."
    return $null
}

$python = Get-PythonExe

if (-not $python) {
    exit 1
}

#python "$notes/scripts/files/rs_flags/rs_flags.py"
# Forward all script arguments to python
#python "$notes/scripts/files/rs_flags/rs_flags.py" @args
& $python "$notes/scripts/files/rs_flags/rs_flags.py" @args
