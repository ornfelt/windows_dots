if vim.fn.has('win32') == 1 then
  local user_profile = vim.loop.os_getenv("USERPROFILE") or ""
  local bundle_path = user_profile .. '/Downloads/PowerShellEditorServices'
  if vim.fn.isdirectory(bundle_path) == 1 and vim.fn.executable('powershell.exe') == 1 then
    return {
      cmd = { 'powershell.exe', '-NoLogo', '-NoProfile', '-Command',
        bundle_path .. [[\PowerShellEditorServices\Start-EditorServices.ps1]],
        '-HostName', 'Neovim',
        '-HostProfileId', 'Neovim',
        '-HostVersion', '1.0.0',
        '-LogLevel', 'Normal',
        '-BundlePath', bundle_path,
        '-Stdio'
      },
      filetypes = { 'ps1', 'psm1', 'psd1' },
      root_markers = { '.git' },
    }
  else
    return {} -- no-op when not available
  end
else
  return {}
end
