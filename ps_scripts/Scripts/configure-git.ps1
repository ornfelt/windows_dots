﻿<#
.SYNOPSIS
	Configures Git 
.DESCRIPTION
	This PowerShell script configures the Git user settings.
.PARAMETER fullName
	Specifies the user's full name
.PARAMETER emailAddress
	Specifies the user's email address
.PARAMETER favoriteEditor
	Specifies the user's favorite text editor
.EXAMPLE
	PS> ./configure-git.ps1 "Joe Doe" joe@doe.com vim
	⏳ (1/6) Searching for Git executable...  git version 2.42.0.windows.1
	⏳ (2/6) Query user settings...
	⏳ (3/6) Saving basic settings (autocrlf,symlinks,longpaths,etc.)...
	⏳ (4/6) Saving user settings (name,email,editor)...
	⏳ (5/6) Saving user shortcuts ('git br', 'git ls', 'git st', etc.)...
	⏳ (6/6) Listing your current settings...
.LINK
	https://github.com/fleschutz/PowerShell
.NOTES
	Author: Markus Fleschutz | License: CC0
#>

param([string]$fullName = "", [string]$emailAddress = "", [string]$favoriteEditor = "")

try {
	Write-Host "⏳ (1/6) Searching for Git executable...  " -noNewline
	& git --version
	if ($lastExitCode -ne "0") { throw "Can't execute 'git' - make sure Git is installed and available" }

	"⏳ (2/6) Query user settings..."
	if ($fullName -eq "") { $fullName = Read-Host "Enter your full name" }
	if ($emailAddress -eq "") { $emailAddress = Read-Host "Enter your e-mail address"}
	if ($favoriteEditor -eq "") { $favoriteEditor = Read-Host "Enter your favorite text editor (atom,code,emacs,nano,notepad,subl,vi,vim,...)" }
	$stopWatch = [system.diagnostics.stopwatch]::startNew()

	"⏳ (3/6) Saving basic settings (autocrlf,symlinks,longpaths,etc.)..."
	& git config --global core.autocrlf false          # don't change newlines
	& git config --global core.symlinks true           # enable support for symbolic link files
	& git config --global core.longpaths true          # enable support for long file paths
	& git config --global init.defaultBranch main      # set the default branch name to 'main'
	& git config --global merge.renamelimit 99999      # raise the rename limit
	& git config --global pull.rebase false
	& git config --global fetch.parallel 0             # enable parallel fetching to improve the speed
	if ($lastExitCode -ne "0") { throw "'git config' failed with exit code $lastExitCode" }

	"⏳ (4/6) Saving user settings (name,email,editor)..."
	& git config --global user.name $fullName
	& git config --global user.email $emailAddress
	& git config --global core.editor $favoriteEditor
	if ($lastExitCode -ne "0") { throw "'git config' failed with exit code $lastExitCode" }

	"⏳ (5/6) Saving user shortcuts ('git br', 'git ls', 'git st', etc.)..."
	& git config --global alias.br "branch"
	& git config --global alias.chp "cherry-pick --no-commit"
	& git config --global alias.ci "commit"
	& git config --global alias.co "checkout"
	& git config --global alias.ls "log -n20 --pretty=format:'%Cred%h%Creset%C(yellow)%d%Creset %s %C(bold blue)by %an%Creset %C(green)%cr%Creset' --abbrev-commit"
	& git config --global alias.mrg "merge --no-commit --no-ff"
	& git config --global alias.pl "pull --recurse-submodules"
	& git config --global alias.ps "push"
	& git config --global alias.smu "submodule update --init"
	& git config --global alias.st "status"
	if ($lastExitCode -ne "0") { throw "'git config' failed" }

	"⏳ (6/6) Listing your current settings..."
	& git config --list
	if ($lastExitCode -ne "0") { throw "'git config --list' failed with exit code $lastExitCode" }

	[int]$elapsed = $stopWatch.Elapsed.TotalSeconds
	"✔️ Saved your Git configuration in $elapsed sec"
	exit 0 # success
} catch {
	"⚠️ Error in line $($_.InvocationInfo.ScriptLineNumber)): $($Error[0])"
	exit 1
}
