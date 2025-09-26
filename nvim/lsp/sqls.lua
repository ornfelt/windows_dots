--return {
--  cmd = { 'sqls' },
--  filetypes = { 'sql', 'mysql' },
--  root_markers = { '.git' },
--  settings = {
--    sqls = {
--      connections = {
--        {
--          driver = 'mysql',
--          dataSourceName = 'acore:acore@tcp(localhost:3306)/acore_world?parseTime=true',
--        },
--      },
--    },
--  },
--}

local function trim(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end

local function parse_kv_pairs(s)
  local t = {}
  for part in s:gmatch("([^;]+)") do
    local k, v = part:match("^%s*([^=]+)%s*=%s*(.-)%s*$")
    if k and v then
      k = k:lower()
      -- strip optional quotes
      v = v:gsub("^['\"](.*)['\"]$", "%1")
      t[k] = v
    end
  end
  return t
end

-- Convert ADO.NET-like to Go-MySQL DSN
local function to_mysql_dsn_from_kv(kv)
  local host = kv.server or kv.host or "localhost"
  local port = kv.port or "3306"
  local db   = kv.database or kv.db or ""
  local user = kv["user id"] or kv.userid or kv.user or kv.uid or kv.username or ""
  local pass = kv.password or kv.pwd or ""
  -- Basic DSN; add any query params you like here:
  local qs = "parseTime=true"
  return string.format("%s:%s@tcp(%s:%s)/%s?%s", user, pass, host, port, db, qs)
end

local function parse_line(line)
  line = trim(line)
  if line == "" then return nil end
  if line:match("^#") or line:match("^%-%-") or line:match("^;") then return nil end

  local driver, rest

  -- Only accept an explicit "mysql:" prefix; otherwise don't split.
  local prefixed = line:match("^%s*mysql%s*:%s*(.+)$")
  if prefixed then
    driver, rest = "mysql", prefixed
  else
    driver, rest = "mysql", line
  end

  -- ADO.NET-style ("Server=...;...") -> convert; otherwise assume raw Go-MySQL DSN.
  local is_kv = (rest:find(";", 1, true) ~= nil) and (rest:match("[%w_ ]+%s*=") ~= nil)

  local dsn
  if is_kv then
    local kv = parse_kv_pairs(rest)
    dsn = to_mysql_dsn_from_kv(kv)
  else
    -- assume raw Go-MySQL DSN (user:pass@tcp(host:port)/db?params)
    dsn = rest
  end

  return {
    driver = driver,
    dataSourceName = dsn,
  }
end

local function read_connections_from_file()
  local cfg_path = (vim.fn.has("win32") == 1)
    and [[C:/local/sqls_config.txt]]
    or ((vim.loop.os_homedir() or (vim.env.HOME or "")) .. "/Documents/local/sqls_config.txt")

  if cfg_path == "" or vim.fn.filereadable(cfg_path) ~= 1 then
    return {}, cfg_path
  end

  local conns = {}
  for _, line in ipairs(vim.fn.readfile(cfg_path)) do
    local entry = parse_line(line)
    if entry then table.insert(conns, entry) end
  end
  return conns, cfg_path
end

local connections, used_path = read_connections_from_file()

-- Debug log
--if used_path and used_path ~= "" then
--  if #connections > 0 then
--    vim.schedule(function()
--      vim.notify(string.format("sqls: loaded %d connection(s) from %s", #connections, used_path))
--    end)
--  else
--    vim.schedule(function()
--      vim.notify(string.format("sqls: config file empty or no valid lines: %s (skipping connections)", used_path), vim.log.levels.WARN)
--    end)
--  end
--end

return {
  cmd = { 'sqls' },
  filetypes = { 'sql', 'mysql' },
  root_markers = { '.git' },
  settings = (#connections > 0) and { sqls = { connections = connections } } or nil,
}

