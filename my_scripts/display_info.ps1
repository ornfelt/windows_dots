# What the display actually is, and what a non-DPI-aware app (the win32 and sdl
# gfx backends) is handed instead. Run on each machine and compare.
$c = @'
using System;using System.Runtime.InteropServices;
public class D{
 [DllImport("user32.dll")]public static extern bool SetProcessDPIAware();
 [DllImport("user32.dll")]public static extern int GetSystemMetrics(int n);
 [DllImport("user32.dll")]public static extern IntPtr GetDC(IntPtr h);
 [DllImport("gdi32.dll")]public static extern int GetDeviceCaps(IntPtr d,int i);}
'@
Add-Type -TypeDefinition $c -ErrorAction SilentlyContinue
[void][D]::SetProcessDPIAware()
$h = [D]::GetDC([IntPtr]::Zero)
$dpi = [D]::GetDeviceCaps($h, 88)

# Every monitor on the desktop: its current mode and its physical size, read from
# its EDID in the registry. Its own class, so a session that already loaded D above
# does not miss the new members.
$c2 = @'
using System;using System.Runtime.InteropServices;
public class DisplayInfoNative{
 [StructLayout(LayoutKind.Sequential,CharSet=CharSet.Unicode)]public struct DISPLAY_DEVICE{public int cb;
  [MarshalAs(UnmanagedType.ByValTStr,SizeConst=32)]public string DeviceName;[MarshalAs(UnmanagedType.ByValTStr,SizeConst=128)]public string DeviceString;
  public int StateFlags;[MarshalAs(UnmanagedType.ByValTStr,SizeConst=128)]public string DeviceID;[MarshalAs(UnmanagedType.ByValTStr,SizeConst=128)]public string DeviceKey;}
 [StructLayout(LayoutKind.Sequential,CharSet=CharSet.Unicode)]public struct DEVMODE{
  [MarshalAs(UnmanagedType.ByValTStr,SizeConst=32)]public string dmDeviceName;public short dmSpecVersion,dmDriverVersion,dmSize,dmDriverExtra;public int dmFields;
  public int dmPositionX,dmPositionY,dmDisplayOrientation,dmDisplayFixedOutput;public short dmColor,dmDuplex,dmYResolution,dmTTOption,dmCollate;
  [MarshalAs(UnmanagedType.ByValTStr,SizeConst=32)]public string dmFormName;public short dmLogPixels;
  public int dmBitsPerPel,dmPelsWidth,dmPelsHeight,dmDisplayFlags,dmDisplayFrequency,dmICMMethod,dmICMIntent,dmMediaType,dmDitherType,dmReserved1,dmReserved2,dmPanningWidth,dmPanningHeight;}
 [DllImport("user32.dll",CharSet=CharSet.Unicode)]public static extern bool EnumDisplayDevices(string dev,int i,ref DISPLAY_DEVICE dd,int flags);
 [DllImport("user32.dll",CharSet=CharSet.Unicode)]public static extern bool EnumDisplaySettings(string dev,int mode,ref DEVMODE dm);}
'@
Add-Type -TypeDefinition $c2 -ErrorAction SilentlyContinue

$MM_PER_INCH = 25.4
$DISPLAY_DEVICE_ATTACHED_TO_DESKTOP = 1
$DISPLAY_DEVICE_PRIMARY_DEVICE = 4
$EDD_GET_DEVICE_INTERFACE_NAME = 1
$ENUM_CURRENT_SETTINGS = -1
$EDID_DESCRIPTOR_OFFSETS = 54, 72, 90, 108
$EDID_TAG_MONITOR_NAME = 0xFC
$EDID_TAG_UNSPECIFIED_TEXT = 0xFE

function New-DisplayDevice { $d = New-Object DisplayInfoNative+DISPLAY_DEVICE; $d.cb = [Runtime.InteropServices.Marshal]::SizeOf($d); $d }

# adapter name (\\.\DISPLAY1) -> the EDID bytes of the monitor on it, as ints, or $null
function Get-MonitorEdid($adapterName) {
  $monitor = New-DisplayDevice
  if (-not [DisplayInfoNative]::EnumDisplayDevices($adapterName, 0, [ref]$monitor, $EDD_GET_DEVICE_INTERFACE_NAME)) { return $null }
  # \\?\DISPLAY#LEN9123#5&3ab00691&0&UID256#{guid} -> DISPLAY\LEN9123\5&3ab00691&0&UID256
  $parts = $monitor.DeviceID -split '#'
  if ($parts.Count -lt 3) { return $null }
  $key = "HKLM:\SYSTEM\CurrentControlSet\Enum\DISPLAY\$($parts[1])\$($parts[2])\Device Parameters"
  $edid = (Get-ItemProperty $key -ErrorAction SilentlyContinue).EDID
  if (-not $edid -or $edid.Length -lt 128) { return $null }
  return ,[int[]]$edid
}

# EDID -> @(width_mm, height_mm), or $null
function Get-EdidSizeMm($e) {
  # the first detailed timing descriptor holds the size in mm; a zero pixel clock
  # means it is not a timing, so fall back to the whole-cm size in the header
  if ($e[54] -or $e[55]) {
    $w = $e[66] + (($e[68] -shr 4) -shl 8)
    $hgt = $e[67] + (($e[68] -band 0xF) -shl 8)
    if ($w -and $hgt) { return @($w, $hgt) }
  }
  if ($e[21] -and $e[22]) { return @(($e[21] * 10), ($e[22] * 10)) }
  return $null
}

# EDID -> the model name from its monitor-name descriptor, else from its free-text
# one (where laptop panels keep theirs), or ""
function Get-EdidName($e) {
  foreach ($tag in $EDID_TAG_MONITOR_NAME, $EDID_TAG_UNSPECIFIED_TEXT) {
    foreach ($o in $EDID_DESCRIPTOR_OFFSETS) {
      if ($e[$o] -eq 0 -and $e[$o + 1] -eq 0 -and $e[$o + 3] -eq $tag) {
        return (-join ($e[($o + 5)..($o + 17)] | ForEach-Object { [char]$_ })).Split([char]10)[0].Trim()
      }
    }
  }
  return ""
}

function Format-Diagonal($sizeMm) {
  if (-not $sizeMm) { return "unknown (no EDID)" }
  $inch = [math]::Sqrt($sizeMm[0] * $sizeMm[0] + $sizeMm[1] * $sizeMm[1]) / $MM_PER_INCH
  return '{0:0.0}" (~{1} inch, {2}x{3} mm)' -f $inch, [math]::Round($inch), $sizeMm[0], $sizeMm[1]
}

# one row per monitor attached to the desktop, primary first
$monitors = New-Object System.Collections.Generic.List[object]
$adapter = New-DisplayDevice
# [NullString]::Value, since a plain $null reaches a string parameter as ""
for ($i = 0; [DisplayInfoNative]::EnumDisplayDevices([NullString]::Value, $i, [ref]$adapter, 0); $i++) {
  if ($adapter.StateFlags -band $DISPLAY_DEVICE_ATTACHED_TO_DESKTOP) {
    $mode = New-Object DisplayInfoNative+DEVMODE
    $mode.dmSize = [Runtime.InteropServices.Marshal]::SizeOf($mode)
    [void][DisplayInfoNative]::EnumDisplaySettings($adapter.DeviceName, $ENUM_CURRENT_SETTINGS, [ref]$mode)
    $edid = Get-MonitorEdid $adapter.DeviceName
    # built outside Add(), where the commas below would split the method arguments
    $row = [pscustomobject]@{
      Display  = $adapter.DeviceName -replace '^\\\\\.\\', ''
      Primary  = [bool]($adapter.StateFlags -band $DISPLAY_DEVICE_PRIMARY_DEVICE)
      Model    = if ($edid) { Get-EdidName $edid } else { "" }
      # real pixels and refresh rate of the current mode
      Screen   = "{0}x{1} @ {2} Hz" -f $mode.dmPelsWidth, $mode.dmPelsHeight, $mode.dmDisplayFrequency
      Position = "+{0}+{1}" -f $mode.dmPositionX, $mode.dmPositionY
      # estimated from the EDID physical size, so a 23.8" panel shows as ~24 inch
      Diagonal = Format-Diagonal $(if ($edid) { Get-EdidSizeMm $edid })
    }
    $monitors.Add($row)
  }
  $adapter = New-DisplayDevice
}
$monitors = @($monitors.ToArray() | Sort-Object { -not $_.Primary }, Display)
$primary = $monitors | Where-Object Primary | Select-Object -First 1

[pscustomobject]@{
  # real pixels of the primary display
  Screen                  = "{0}x{1}" -f [D]::GetSystemMetrics(0), [D]::GetSystemMetrics(1)
  Diagonal                = if ($primary) { $primary.Diagonal } else { Format-Diagonal $null }
  DPI                     = $dpi
  Scaling                 = "{0}%" -f ([math]::Round($dpi / 96 * 100))
  # the size Windows gives a custom HCURSOR of its own
  SysCursor               = "{0}x{1}" -f [D]::GetSystemMetrics(13), [D]::GetSystemMetrics(14)
  # the desktop size the client actually sees, and the ceiling on render_width
  VirtualizedForLegacyApp = "{0}x{1}" -f [math]::Round([D]::GetSystemMetrics(0) * 96 / $dpi), [math]::Round([D]::GetSystemMetrics(1) * 96 / [D]::GetDeviceCaps($h, 90))
} | Format-List

"All monitors ($($monitors.Count)):"
$monitors | Format-Table -AutoSize
