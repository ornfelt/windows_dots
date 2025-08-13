param(
    [string]$Command = "",
    [int]$ModelIndex = 0
)

# Usage:
# .\llama.ps1 help
# .\llama.ps1 cli
# .\llama.ps1 cli 2
# .\llama.ps1 chat
# .\llama.ps1 chat 1
# .\llama.ps1 server
# .\llama.ps1 server 0

# Ensure code_root_dir is set
if (-not $env:code_root_dir -or $env:code_root_dir.Trim() -eq "") {
    Write-Error "Error: Environment variable 'code_root_dir' is not set."
    exit 1
}

# Binary directory
$binaryDir = Join-Path $env:code_root_dir "Code/ml/llama.cpp/build/bin/Release"
if (-not (Test-Path -LiteralPath $binaryDir -PathType Container)) {
    Write-Error "Error: Binary directory not found at $binaryDir"
    exit 1
}

# Define potential model paths
$modelPaths = @(
    "../../../models/Meta-Llama-3.1-8B-Instruct/Meta-Llama-3.1-8B-Instruct-ggml-model-Q4_K_M.gguf",
    "../../../models/meta-llama-3.1-8b-instruct-q4_k_m-gguf/meta-llama-3.1-8b-instruct-q4_k_m.gguf",
    "../../../models/Meta-Llama-3.1-8B/Meta-Llama-3.1-8B-ggml-model-Q4_K_M.gguf",
    "C:/local/ai/models/bartowski_Llama-3.2-3B-Instruct-GGUF_Llama-3.2-3B-Instruct-Q4_K_M.gguf",
    "C:/local/ai/models/ggml-org_gemma-3-1b-it-GGUF_gemma-3-1b-it-Q4_K_M.gguf",
    "C:/local/ai/models/Meta-Llama-3.1-8B-Instruct-ggml-model-Q4_K_M.gguf",
    "C:/local/ai/models/unsloth_DeepSeek-R1-0528-Qwen3-8B-GGUF_DeepSeek-R1-0528-Qwen3-8B-Q4_K_M.gguf",
    "D:/my_files/my_docs/ai/models/bartowski_Llama-3.2-3B-Instruct-GGUF_Llama-3.2-3B-Instruct-Q4_K_M.gguf",
    "D:/my_files/my_docs/ai/models/ggml-org_gemma-3-1b-it-GGUF_gemma-3-1b-it-Q4_K_M.gguf",
    "D:/my_files/my_docs/ai/models/unsloth_DeepSeek-R1-0528-Qwen3-8B-GGUF_DeepSeek-R1-0528-Qwen3-8B-Q4_K_M.gguf",
    "D:/my_files/my_docs/ai/models/Meta-Llama-3.1-8B-Instruct-ggml-model-Q4_K_M.gguf",
    "D:/2024/ollama/llama.cpp/models/Meta-Llama-3.1-8B/Meta-Llama-3.1-8B-ggml-model-Q4_K_M.gguf"
)

# Find all available models
$availableModels = @()
Write-Host "Checking available models:"
foreach ($path in $modelPaths) {
    $resolvedPath = if ([System.IO.Path]::IsPathRooted($path)) {
        $path
    } else {
        Join-Path $binaryDir $path
    }

    if (Test-Path -LiteralPath $resolvedPath -PathType Leaf) {
        Write-Host "- Model available: $resolvedPath"
        $availableModels += $resolvedPath
    }
}

if ($availableModels.Count -eq 0) {
    Write-Error "Error: No model files found in the provided paths."
    exit 1
}

# Validate model index
if ($ModelIndex -lt 0 -or $ModelIndex -ge $availableModels.Count) {
    Write-Error "Error: Invalid model index '$ModelIndex'. Valid indices: 0 to $($availableModels.Count - 1)"
    exit 1
}

$modelPath = $availableModels[$ModelIndex]
Write-Host "Selected model: $modelPath"

# Common args
$commonArgs = "--threads $([Environment]::ProcessorCount) -c 2048"

# For binding to the primary IPv4
function Get-LocalIPv4 {
    # Prefer Get-NetIPAddress (Win8+/Server2012+), fallback to .NET if unavailable
    if (Get-Command Get-NetIPAddress -ErrorAction SilentlyContinue) {
        $ip = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
            Where-Object {
                $_.IPAddress -ne '127.0.0.1' -and
                $_.IPAddress -notlike '169.254.*' -and
                $_.ValidLifetime -ne ([TimeSpan]::Zero) -and
                $_.InterfaceOperationalStatus -eq 'Up'
            } |
            Sort-Object SkipAsSource, InterfaceMetric |
            Select-Object -First 1 -ExpandProperty IPAddress
        if ($ip) { return $ip }
    }

    # Fallback: first non-loopback IPv4 from .NET
    $hostEntry = [System.Net.Dns]::GetHostEntry([System.Net.Dns]::GetHostName())
    foreach ($addr in $hostEntry.AddressList) {
        if ($addr.AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork) {
            $ipStr = $addr.IPAddressToString
            if ($ipStr -ne '127.0.0.1' -and $ipStr -notlike '169.254.*') {
                return $ipStr
            }
        }
    }
    return '127.0.0.1'
}

# Command handler
switch -Regex ($Command.ToLower()) {
    "^(cli|chat)$" {
        Write-Host "Running llama in CLI mode..."
        & "$binaryDir/llama-cli.exe" -m $modelPath $commonArgs -cnv -p "You are a helpful assistant"
    }
    #"^server$" {
    #    Write-Host "Running llama in Server mode..."
    #    & "$binaryDir/llama-server.exe" -m $modelPath $commonArgs
    #}
    "^server$" {
        $hostIp = Get-LocalIPv4
        Write-Host "Running llama in Server mode on host $hostIp ..."
        & "$binaryDir/llama-server.exe" -m $modelPath $commonArgs --host $hostIp
    }
    "^help$" {
        Write-Host "Usage: .\llama.ps1 [cli|chat|server|help] [model_index]"
        Write-Host "Commands:"
        Write-Host "  cli    Run llama in CLI mode"
        Write-Host "  chat   Alias for CLI mode"
        Write-Host "  server Run llama in Server mode"
        Write-Host "  help   Show this help message"
        Write-Host "  model_index Optional, 0-based index to select model."
    }
    default {
        Write-Error "Unknown command: $Command"
        Write-Host "Usage: .\llama.ps1 [cli|chat|server|help] [model_index]"
        exit 1
    }
}

