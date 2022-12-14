# My scripts:

cdc, cdh cdp: used for changing dirs quickly

chrome_s: starts chrome without security (used for Cross-Origin Resource Sharing (CORS)).

list_files: List largest files in current dir.

list_processes: lists processes...

map_util: some commands on mapping network drives in Windows and seeing security groups.

Then I have some other util scripts for tasks and network.

# Other stuff:
cmd as admin, then:

sfc /scannow

(check for damaged system files and automatically repair)

If it fails to repair, restart computer and try:

DISM /Online /Cleanup-Image /RestoreHealth then restart and run asfc /scannow again

Check for disk errors ( /r will check for bad sectors):

chkdsk C: /r

List tasks, similar to task manager:

tasklist 

taskkill

taskkill /f /t /im notepad.exe OR taskkill /f /t /pid 23136

powercfg /energy (generate error report file related to system power)

powercfg /batteryreport