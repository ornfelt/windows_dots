#!/bin/bash

# Source directory (the trailing slash is important to copy the contents)
src="./nvim/"
# Target dir
dest="$HOME/.config/nvim"

# Create target dir if it doesn't exist
mkdir -p "$dest"

# Copy files and dirs recursively from source to destination
cp -r "$src"* "$dest"
echo "nvim files copied successfully from $src to $dest"

# wezterm config
src="./.wezterm.lua/"
dest="$HOME/"
cp "$src" "$dest"
echo -e "\nwezterm config copied successfully from $src to $dest"

