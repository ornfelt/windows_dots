#!/bin/bash

RESET='\033[0m'
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
CYAN='\033[36m'
MAGENTA='\033[35m'
DARKGRAY='\033[90m'

write_ok()       { echo -e "${GREEN}${1}${RESET}"; }
write_err()      { echo -e "${RED}${1}${RESET}"; }
write_warn()     { echo -e "${YELLOW}${1}${RESET}"; }
write_info()     { echo -e "${CYAN}${1}${RESET}"; }
write_info_alt() { echo -e "${MAGENTA}${1}${RESET}"; }

# ------------------------------------------------------------
# Copy Neovim files

src="./nvim/"
dest="$HOME/.config/nvim"

mkdir -p "$dest"

cp -r "$src"* "$dest"
write_ok "Neovim files copied successfully from $src to $dest"

# ------------------------------------------------------------
# Copy WezTerm config

src="./.wezterm.lua"
dest="$HOME/"

cp "$src" "$dest"
write_ok "WezTerm config copied successfully from $src to $dest"

# ------------------------------------------------------------
# Copy additional WezTerm files

wezterm_dest="$HOME/.config/wezterm"

if [ -d "$wezterm_dest" ]; then
    write_info "Copying additional WezTerm files..."

    cp "./wezterm/claude.lua" "$wezterm_dest/"
    cp "./wezterm/nvim_server.lua" "$wezterm_dest/"
    cp "./wezterm/status.lua" "$wezterm_dest/"

    write_ok "WezTerm files copied successfully to $wezterm_dest"
else
    write_warn "Skipping additional WezTerm files: $wezterm_dest does not exist."
fi

# ------------------------------------------------------------
# Copy Claude hooks

claude_dest="$HOME/.claude"

if [ -d "$claude_dest" ]; then
    write_info_alt "Copying Claude hooks..."

    cp -r "./.claude/hooks" "$claude_dest/"

    write_ok "Claude hooks copied successfully to $claude_dest/hooks"
else
    write_warn "Skipping Claude hooks: $claude_dest does not exist."
fi
