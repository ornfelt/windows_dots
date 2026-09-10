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

[pscustomobject]@{
  # real pixels of the primary display
  Screen                  = "{0}x{1}" -f [D]::GetSystemMetrics(0), [D]::GetSystemMetrics(1)
  DPI                     = $dpi
  Scaling                 = "{0}%" -f ([math]::Round($dpi / 96 * 100))
  # the size Windows gives a custom HCURSOR of its own
  SysCursor               = "{0}x{1}" -f [D]::GetSystemMetrics(13), [D]::GetSystemMetrics(14)
  # the desktop size the client actually sees, and the ceiling on render_width
  VirtualizedForLegacyApp = "{0}x{1}" -f [math]::Round([D]::GetSystemMetrics(0) * 96 / $dpi), [math]::Round([D]::GetSystemMetrics(1) * 96 / [D]::GetDeviceCaps($h, 90))
} | Format-List
