#!/usr/bin/env bash

set -euo pipefail

file="${1:-my_scripts/cmake.ps1}"
n="${2:-5}"
out="${3:-}"

if ! [[ "$n" =~ ^[0-9]+$ ]]; then
    echo "N must be an integer"
    exit 1
fi

if [[ -z "$out" ]]; then
    safe_file="${file//\\/_}"   # replace backslashes
    safe_file="${safe_file//\//_}"  # replace forward slashes
    out="${safe_file}_${n}.diff"
fi

if ! git rev-parse --verify "HEAD~$n" >/dev/null 2>&1; then
    echo "Not enough commits for HEAD~$n"
    exit 1
fi

git diff "HEAD~$n..HEAD" -- "$file" > "$out"
echo "Wrote diff to: $out"
