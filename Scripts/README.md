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

# Commands:
```
There are 156 run commands at mypchell.com.
Here is a more complete list including the Windows Environment Commands (e.g. %temp%, %HomeDrive%, etc)
Windows Environment Path Variables

%AllUsersProfile% - Open the All User's Profile C:\ProgramData
%AppData% - Opens AppData folder C:\Users\{username}\AppData\Roaming
%CommonProgramFiles% - C:\Program Files\Common Files
%CommonProgramFiles(x86)% - C:\Program Files (x86)\Common Files
%HomeDrive% - Opens your home drive C:\
%LocalAppData% - Opens local AppData folder C:\Users\{username}\AppData\Local
%ProgramData% - C:\ProgramData
%ProgramFiles% - C:\Program Files or C:\Program Files (x86)
%ProgramFiles(x86)% - C:\Program Files (x86)
%Public% - C:\Users\Public
%SystemDrive% - C:
%SystemRoot% - Opens Windows folder C:\Windows
%Temp% - Opens temporary file Folder C:\Users\{Username}\AppData\Local\Temp
%UserProfile% - Opens your user's profile C:\Users\{username}
%AppData%\Microsoft\Windows\Start Menu\Programs\Startup - Opens Windows 10 Startup location for program shortcuts

Win+R
Run commands

Calc - Calculator
Cfgwiz32 - ISDN Configuration Wizard
Charmap - Character Map
Chkdisk - Repair damaged files
Cleanmgr - Cleans up hard drives
Clipbrd - Windows Clipboard viewer
Cmd - Opens a new Command Window (cmd.exe)
Control - Displays Control Panel
Dcomcnfg - DCOM user security
Debug - Assembly language programming tool
Defrag - Defragmentation tool
Drwatson - Records programs crash & snapshots
Dxdiag - DirectX Diagnostic Utility
Explorer - Windows Explorer
Fontview - Graphical font viewer
Ftp - ftp.exe program
Hostname - Returns Computer's name
Ipconfig - Displays IP configuration for all network adapters
Jview - Microsoft Command-line Loader for Java classes
MMC - Microsoft Management Console
Msconfig - Configuration to edit startup files
Msinfo32 - Microsoft System Information Utility
Nbtstat - Displays stats and current connections using NetBios over TCP/IP
Netstat - Displays all active network connections
Nslookup - Returns your local DNS server
Odbcad32 - ODBC Data Source Administrator
Ping - Sends data to a specified host/IP
Regedit - registry Editor
Regsvr32 - register/de-register DLL/OCX/ActiveX
Regwiz - Registration wizard
Sfc /scannow - System File Checker
shutdown /r -t 60 - restart the computer in 60 seconds
Sndrec32 - Sound Recorder
Sndvol32 - Volume control for soundcard
Sysedit - Edit system startup files (config.sys, autoexec.bat, win.ini, etc.)
Systeminfo - display various system information in text console
Taskmgr - Task manager
Telnet - Telnet program
Taskkill - kill processes using command line interface
Tskill - reduced version of Taskkill from Windows XP Home
Tracert - Traces and displays all paths required to reach an internet host
Winchat - simple chat program for Windows networks
Winipcfg - Displays IP configuration

Microsoft Office suite

winword - Microsoft Word
excel - Microsoft Excel
powerpnt - Microsoft PowerPoint
msaccess - Microsoft Access
outlook - Microsoft Outlook
ois - Microsoft Picture Manager
winproj - Microsoft Project
Management Consoles

certmgr.msc - Certificate Manager
ciadv.msc - Indexing Service
compmgmt.msc - Computer management
devmgmt.msc - Device Manager
dfrg.msc - Defragment
diskmgmt.msc - Disk Management
fsmgmt.msc - Folder Sharing Management
eventvwr.msc - Event Viewer
gpedit.msc - Group Policy (< XP Pro)
iis.msc - Internet Information Services
lusrmgr.msc - Local Users and Groups
mscorcfg.msc - Net configurations
ntmsmgr.msc - Removable Storage
perfmon.msc - Performance Manager
secpol.msc - Local Security Policy
services.msc - System Services
wmimgmt.msc - Windows Management
Control Panel utilities

access.cpl - Accessibility Options
hdwwiz.cpl - Add New Hardware Wizard
appwiz.cpl - Add/Remove Programs
timedate.cpl - Date and Time Properties
desk.cpl - Display Properties
inetcpl.cpl - Internet Properties
joy.cpl - Joystick Properties
main.cpl keyboard - Keyboard Properties
main.cpl - Mouse Properties
ncpa.cpl - Network Connections
ncpl.cpl - Network Properties
telephon.cpl - Phone and Modem options
powercfg.cpl - Power Management
intl.cpl - Regional settings
mmsys.cpl sounds - Sound Properties
mmsys.cpl - Sounds and Audio Device Properties
sysdm.cpl - System Properties
nusrmgr.cpl - User settings
firewall.cpl - Firewall Settings (sp2)
wscui.cpl - Security Center (sp2)
Wupdmgr - Takes you to Microsoft Windows Update
```