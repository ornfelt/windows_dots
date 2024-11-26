# This script gracefully terminates all processes with the given name (first parameter) when it's run.
# It will also answer to a confirm message, if the process has one, by a given hotkey.
#
#
# signature: closeApplication.ps1 $ProcessName $ConfirmHotkey
#
#
# some simple examples how to use it:
#  closeApplications.ps1 'notepad'         close all open instances with the process name 'notepad' (you should try this)
#  closeApplications.ps1 'winword' '%Y'    close all open instances of word and and send ALT+Y if a confirmation window pops up 
#
# You are likely looking for this script to terminate software, that blocks licenses when it's not in use.
# One possibility to do this is to register this as scheduled task when locking the workstation:
#  - run taskschd.msc
#  - create a new task
#  - in trigger, add a trigger "On worksation lock" 
#  - in actions, add a new action with the following configuration
#    - Action: start a programm
#    - Programm/script: powershell
#    - Add arguments: -command "& 'C:\closeApplications.ps1' 'notepad' '(%N)'"

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

