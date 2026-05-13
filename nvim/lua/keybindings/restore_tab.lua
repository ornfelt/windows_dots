require('dbg_log').log_file(debug.getinfo(1, 'S').source)

local last_closed_tab = nil

local function buf_is_modified(buf)
  return vim.api.nvim_buf_is_valid(buf)
    and vim.api.nvim_get_option_value("modified", { buf = buf })
end

local function current_tab_has_modified_buffers()
  local tabpage = vim.api.nvim_get_current_tabpage()
  local windows = vim.api.nvim_tabpage_list_wins(tabpage)

  for _, win in ipairs(windows) do
    local buf = vim.api.nvim_win_get_buf(win)
    if buf_is_modified(buf) then
      return true
    end
  end

  return false
end

local function save_and_close_tab()
  local tab_count = vim.fn.tabpagenr('$')

  if current_tab_has_modified_buffers() then
    vim.notify("Tab has unsaved changes. Save first or use :q! manually.", vim.log.levels.WARN)
    return
  end

  if tab_count <= 1 then
    --print("Cannot save tab state: only one tab open.")
    vim.cmd("q")
    return
  end

  local tabpage = vim.api.nvim_get_current_tabpage()
  local windows = vim.api.nvim_tabpage_list_wins(tabpage)
  local buffers = {}

  if #windows > 1 then
    vim.cmd("q")
    return
  end

  for _, win in ipairs(windows) do
    local buf = vim.api.nvim_win_get_buf(win)
    table.insert(buffers, {
      name = vim.api.nvim_buf_get_name(buf),
      position = vim.api.nvim_win_get_cursor(win),
    })
  end

  last_closed_tab = buffers
  vim.cmd("tabclose")
end

local function restore_tab()
  if not last_closed_tab or #last_closed_tab == 0 then
    print("No closed tab to restore.")
    return
  end

  vim.cmd("tabnew")

  local current_tab_index = vim.fn.tabpagenr()
  local total_tabs = vim.fn.tabpagenr("$")

  if current_tab_index < total_tabs then
    vim.cmd("tabmove -1")
  end

  for _, buf_data in ipairs(last_closed_tab) do
    if buf_data.name ~= "" then
      vim.cmd.edit(vim.fn.fnameescape(buf_data.name))
      vim.api.nvim_win_set_cursor(0, buf_data.position)
    end
  end

  last_closed_tab = nil
end

-- bind m-q: save_and_close_tab (n)
vim.keymap.set("n", "<M-q>", save_and_close_tab, { noremap = true, silent = true })
-- bind m-s-t: restore_tab (n)
vim.keymap.set("n", "<M-S-T>", restore_tab, { noremap = true, silent = true })
