-- md_sync.lua
-- Copies markdown files into the flask md viewer project and keeps them
-- synced on save. Cross-platform: relies on $code_root_dir and the `git` binary.
--
-- Commands:
--   :MdCopy        Copy current .md file to the viewer project (captures git info if any)
--   :MdCopyAs      Like MdCopy but choose dest filename (avoids collisions)
--   :MdUnlink      Remove the current file from the viewer project + metadata
--   :MdOpen        Open the viewer in browser at this file's page

require('dbg_log').log_file(debug.getinfo(1, 'S').source)

local myconfig = require("myconfig")
local code_root_dir = myconfig.code_root_dir

local M = {}

local uv = vim.uv or vim.loop

-- ---------- paths ----------

local function code_root()
  local v = os.getenv("code_root_dir")
  if not v or v == "" then return nil end
  return (v:gsub("\\", "/"))
end

local function project_dir()
  local r = code_root()
  if not r then return nil end
  return r .. "/Code2/General/utils/md/py"
end

local function md_dir()
  local p = project_dir()
  return p and (p .. "/md_files") or nil
end

local function meta_file()
  local p = project_dir()
  return p and (p .. "/metadata.json") or nil
end

local function norm(p)
  if not p then return nil end
  return (p:gsub("\\", "/"))
end

-- ---------- io helpers ----------

local function read_file(path)
  local f = io.open(path, "rb")
  if not f then return nil end
  local s = f:read("*a")
  f:close()
  return s
end

local function write_file(path, data)
  local f = io.open(path, "wb")
  if not f then return false end
  f:write(data)
  f:close()
  return true
end

local function read_json(path)
  local s = read_file(path)
  if not s or s == "" then return {} end
  local ok, t = pcall(vim.json.decode, s)
  if not ok or type(t) ~= "table" then return {} end
  return t
end

local function write_json(path, tbl)
  -- Pretty-printed JSON (vim.json.encode is compact); good enough for a small map.
  local s = vim.json.encode(tbl)
  return write_file(path, s)
end

local function ensure_dir(path)
  vim.fn.mkdir(path, "p")
end

-- ---------- git ----------

local function git(args, cwd)
  local cmd = { "git", "-C", cwd }
  for _, a in ipairs(args) do table.insert(cmd, a) end
  local out = vim.fn.system(cmd)
  if vim.v.shell_error ~= 0 then return nil end
  return vim.fn.trim(out)
end

local function get_git_info(file_path)
  local dir = vim.fn.fnamemodify(file_path, ":h")
  local root = git({ "rev-parse", "--show-toplevel" }, dir)
  if not root or root == "" then return nil end
  local remote = git({ "config", "--get", "remote.origin.url" }, dir) or ""
  local branch = git({ "rev-parse", "--abbrev-ref", "HEAD" }, dir) or "main"

  local nfile = norm(file_path)
  local nroot = norm(root)
  local rel = nfile
  if nfile:sub(1, #nroot + 1) == nroot .. "/" then
    rel = nfile:sub(#nroot + 2)
  end

  return {
    git_root = root,
    remote_url = remote,
    branch = branch,
    relative_path = rel,
    source_path = nfile,
  }
end

-- ---------- core copy ----------

local function is_md(file)
  return vim.fn.fnamemodify(file, ":e"):lower() == "md"
end

local function notify(msg, level, silent)
  if silent then return end
  vim.notify("[md] " .. msg, level or vim.log.levels.INFO)
end

--- Copy file to project. Async copy via libuv; metadata is small + sync.
---@param opts { silent: boolean?, file: string?, dest_name: string? }
function M.copy(opts)
  opts = opts or {}
  local silent = opts.silent or false
  local file = opts.file or vim.fn.expand("%:p")

  if not file or file == "" then
    notify("no file", vim.log.levels.ERROR, silent)
    return
  end
  if not is_md(file) then
    notify("not a markdown file: " .. file, vim.log.levels.ERROR, silent)
    return
  end

  local mdd = md_dir()
  local mf = meta_file()
  if not mdd or not mf then
    notify("code_root_dir not set", vim.log.levels.ERROR, silent)
    return
  end
  ensure_dir(mdd)

  local name = opts.dest_name or vim.fn.fnamemodify(file, ":t")
  local dst = mdd .. "/" .. name
  local nfile = norm(file)

  uv.fs_copyfile(file, dst, function(err)
    vim.schedule(function()
      if err then
        notify("copy failed: " .. tostring(err), vim.log.levels.ERROR, silent)
        return
      end

      -- Update metadata.
      local meta = read_json(mf)
      local existing = meta[name] or {}
      local gi = get_git_info(file)

      if gi then
        -- Fresh git info wins, but keep any prior manual_linked flag dropped.
        meta[name] = gi
      else
        -- No git context: preserve any manual link, just update source_path.
        existing.source_path = nfile
        meta[name] = existing
      end
      write_json(mf, meta)
      notify("copied: " .. name, vim.log.levels.INFO, silent)
    end)
  end)
end

--- Background sync: only runs if the file is already tracked AND it's the
--- same source path we tracked. Doesn't re-query git (already in metadata).
local function background_sync()
  local file = norm(vim.fn.expand("%:p"))
  if not file or file == "" or not is_md(file) then return end

  local mf = meta_file()
  local mdd = md_dir()
  if not mf or not mdd then return end

  local meta = read_json(mf)
  -- Find the entry whose source_path matches this buffer.
  local match_name = nil
  for name, entry in pairs(meta) do
    if entry.source_path and norm(entry.source_path) == file then
      match_name = name
      break
    end
  end
  if not match_name then return end

  local dst = mdd .. "/" .. match_name
  uv.fs_copyfile(file, dst, function(_) end) -- silently swallow errors
end

function M.unlink(opts)
  opts = opts or {}
  local silent = opts.silent or false
  local file = vim.fn.expand("%:p")
  local name = vim.fn.fnamemodify(file, ":t")
  local mdd = md_dir()
  local mf = meta_file()
  if not mdd or not mf then
    notify("code_root_dir not set", vim.log.levels.ERROR, silent)
    return
  end
  local dst = mdd .. "/" .. name
  uv.fs_unlink(dst, function(_)
    vim.schedule(function()
      local meta = read_json(mf)
      if meta[name] then
        meta[name] = nil
        write_json(mf, meta)
      end
      notify("unlinked: " .. name, vim.log.levels.INFO, silent)
    end)
  end)
end

function M.open_in_browser()
  local file = vim.fn.expand("%:p")
  local name = vim.fn.fnamemodify(file, ":t")
  if not is_md(file) then
    notify("not a markdown file", vim.log.levels.ERROR)
    return
  end
  local url = string.format("http://127.0.0.1:5000/view/%s", name)
  local opener
  if vim.fn.has("mac") == 1 then
    opener = { "open", url }
  elseif vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
    opener = { "cmd", "/c", "start", "", url }
  else
    opener = { "xdg-open", url }
  end
  vim.fn.jobstart(opener, { detach = true })
end

function M.setup(user_opts)
  user_opts = user_opts or {}

  vim.api.nvim_create_user_command("MdCopy", function()
    M.copy({ silent = false })
  end, { desc = "Copy current md file to flask viewer project" })

  vim.api.nvim_create_user_command("MdCopyAs", function(args)
    local name = args.args
    if name == "" then
      vim.notify("[md] usage: :MdCopyAs <filename.md>", vim.log.levels.ERROR)
      return
    end
    if not name:lower():match("%.md$") then name = name .. ".md" end
    M.copy({ silent = false, dest_name = name })
  end, { desc = "Copy current md file with a chosen destination name", nargs = 1 })

  vim.api.nvim_create_user_command("MdUnlink", function()
    M.unlink({ silent = false })
  end, { desc = "Remove current md file from viewer project" })

  vim.api.nvim_create_user_command("MdOpen", function()
    M.open_in_browser()
  end, { desc = "Open current md file in the flask viewer" })

  if user_opts.auto_sync ~= false then
    local grp = vim.api.nvim_create_augroup("MdSync", { clear = true })
    vim.api.nvim_create_autocmd("BufWritePost", {
      group = grp,
      pattern = "*.md",
      callback = function()
        -- Defer slightly so write completes; sync runs async via libuv.
        vim.defer_fn(background_sync, 50)
      end,
    })
  end
end

return M
