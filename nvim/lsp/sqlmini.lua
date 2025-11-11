---@type vim.lsp.Config
return (function()
  local base_dir = os.getenv("code_root_dir")
  if not base_dir then
    if vim.fn.has("win32") == 1 then
      base_dir = os.getenv("USERPROFILE")
    else
      base_dir = os.getenv("HOME")
    end
  end

  local exe
  if vim.fn.has("win32") == 1 then
    exe = base_dir .. [[\Code2\C#\my_csharp\SqlMiniLsp\bin\Debug\net8.0\SqlMiniLsp.exe]]
  else
    exe = base_dir .. "/Code2/my_csharp/SqlMiniLsp/bin/Debug/net8.0/sqlminilsp"
  end

  --print("using sqlminilsp exe: " .. exe)

  return {
    cmd = { exe, "--stdio" },
    filetypes = { "csql" },
    -- optional root inference (Neovim 0.11+)
    root_markers = { ".git", "sqlproj" },
    -- or, explicitly:
    -- root_dir = function(fname)
    --   local util = require("lspconfig.util")
    --   return util.root_pattern(".git")(fname) or vim.loop.cwd()
    -- end,
    -- settings = { }, -- none yet
  }
end)()
