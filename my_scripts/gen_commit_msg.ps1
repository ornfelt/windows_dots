$codeRootDir = $env:code_root_dir

if ([string]::IsNullOrWhiteSpace($codeRootDir)) {
    Write-Host "Environment variable 'code_root_dir' is not set."
    exit 1
}

#python "$codeRootDir/Code2/General/utils/ai/git_commit_msg/gen_commit_msg.py"
# Forward all script arguments to python
python "$codeRootDir/Code2/General/utils/ai/git_commit_msg/gen_commit_msg.py" @args
