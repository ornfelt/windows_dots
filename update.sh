#!/bin/bash

# Source directory (the trailing slash is important to copy the contents)
src="./nvim/"
# Target directory
dest="$HOME/.config/nvim"

# Create target directory if it doesn't exist
mkdir -p "$dest"

# Copy all files and directories recursively from source to destination
cp -r "$src"* "$dest"

echo "Files copied successfully from $src to $dest"

