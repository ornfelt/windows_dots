# This script gracefully terminates all processes with the given name (first
# parameter) when it's run. It will also answer to a confirm message, if the
# process has one, by a given hotkey.
#
# signature: closeApplication.ps1 $ProcessName $ConfirmHotkey
#
# Usage examples:
# closeApplications.ps1 'notepad'      # close all open instances with the process name 'notepad'
# closeApplications.ps1 'winword' '%Y' # close all open instances of word and and send ALT+Y if a confirmation window pops up 

param(
    [parameter(Mandatory=$true)]
    [String]
    $ProcessName,
    
    [String]
    $ConfirmHotkey = "%(N)"
)

$ClosedCount = 0;

foreach($Process in Get-Process -Name $ProcessName -ErrorAction SilentlyContinue) {
    $Process.CloseMainWindow() | Out-Null
    sleep 3
    
    while (! $Process.HasExited){
        Write-Host "'$ProcessName' has open windows. Trying to close now..."
        $wshell = new-object -com wscript.shell
        $wshell.AppActivate($Process.Id) | Out-Null
        $wshell.Sendkeys($ConfirmHotkey) | Out-Null
        sleep 3
    }
    
    $ClosedCount++;
}

Write-Host "Terminated $ClosedCount processes with name '$ProcessName'."

