# Usage:
# .\llama.ps1
# .\llama.ps1 cli
# .\llama.ps1 server

param(
    [string]$mode = "server" # Default to "server" if no argument is provided
)

$basePath = Join-Path -Path $env:code_root_dir -ChildPath "Code\ml\llama.cpp\build\bin\Release"

# Define potential model paths
$modelPaths = @(
    "../../../models/Meta-Llama-3.1-8B-Instruct/Meta-Llama-3.1-8B-Instruct-ggml-model-Q4_K_M.gguf",
    "../../../models/meta-llama-3.1-8b-instruct-q4_k_m-gguf\meta-llama-3.1-8b-instruct-q4_k_m.gguf",
    "../../../models/Meta-Llama-3.1-8B/Meta-Llama-3.1-8B-ggml-model-Q4_K_M.gguf",
    "D:/2024/ollama/llama.cpp/models/Meta-Llama-3.1-8B/Meta-Llama-3.1-8B-ggml-model-Q4_K_M.gguf"
)

# https://huggingface.co/meta-llama/Meta-Llama-3-70B
# https://huggingface.co/meta-llama/Meta-Llama-3.1-405B
# https://huggingface.co/meta-llama/Meta-Llama-3.1-405B-Instruct
# https://huggingface.co/meta-llama/Llama-2-7b-chat
# https://huggingface.co/meta-llama/CodeLlama-13b-Python-hf
# https://huggingface.co/meta-llama/CodeLlama-34b-Instruct-hf
# https://huggingface.co/meta-llama/Meta-Llama-3-8B
# https://huggingface.co/meta-llama/Meta-Llama-3-8B-Instruct
# https://huggingface.co/meta-llama/Llama-2-13b-chat-hf
# https://huggingface.co/meta-llama/Llama-2-7b-hf
# https://huggingface.co/meta-llama/Meta-Llama-3.1-70B-Instruct
# https://huggingface.co/meta-llama/Meta-Llama-3-70B
# https://huggingface.co/meta-llama/Llama-2-7b-chat-hf
# 
# https://huggingface.co/microsoft/Phi-3-mini-4k-instruct
# https://huggingface.co/microsoft/Phi-3-mini-128k-instruct
# 
# https://huggingface.co/google/gemma-2-9b-it
# https://huggingface.co/google/gemma-7b-it
# https://huggingface.co/google/gemma-2b
# https://huggingface.co/MaziyarPanahi/Mistral-7B-Instruct-v0.3-GGUF
# https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF

# Check for model existence case-insensitively
function Get-ModelPath {
    param (
        [string[]]$paths
    )
    foreach ($path in $paths) {
        $fullPath = Join-Path -Path $basePath -ChildPath $path
        if (Test-Path -LiteralPath $fullPath -PathType Leaf) {
            return $fullPath
        }
    }
    return $null
}

# Get model path
$modelPath = Get-ModelPath -paths $modelPaths

if (-not $modelPath) {
    Write-Error "Model file not found in any of the specified locations."
    exit 1
}
Write-output "Model found at: $modelPath"

# cd into dir
Set-Location -Path $basePath

# Run llama.cpp based on the given argument
switch ($mode) {
    "cli" {
        .\llama-cli.exe -m $modelPath --threads $([System.Environment]::ProcessorCount) -c 2048 -cnv -p "you are a helpful assistant"
    }
    "server" {
        .\llama-server.exe -m $modelPath --threads $([System.Environment]::ProcessorCount) -c 2048
    }
    default {
        Write-Error "Invalid mode specified. Use 'cli' or 'server'."
    }
}

