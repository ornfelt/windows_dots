local myconfig = require("myconfig")

-- Unified picker using fzf, fzf-lua, telescope or vim.ui.select
local function choose(prompt, options, callback)
  local picker    = myconfig.get_file_picker()
  local use_fzf   = picker == myconfig.FilePicker.FZF
  local use_fzf_lua = picker == myconfig.FilePicker.FZF_LUA
  --local use_file_picker = picker ~= myconfig.FilePicker.NONE
  local use_file_picker = true
  --local use_file_picker = false

  if use_file_picker then
    if use_fzf then
      vim.fn["fzf#run"]({
        source  = options,
        sink    = callback,
        options = "--prompt '" .. prompt .. "> ' --reverse",
      })

    elseif use_fzf_lua then
      require('fzf-lua').fzf_exec(options, {
        prompt  = prompt .. "> ",
        actions = {
          ["default"] = function(selected)
            callback(selected[1])
          end,
        },
      })

    else
      local pickers      = require('telescope.pickers')
      local finders      = require('telescope.finders')
      local actions      = require('telescope.actions')
      local action_state = require('telescope.actions.state')
      local conf         = require('telescope.config').values

      pickers.new({}, {
        prompt_title = prompt,
        finder = finders.new_table({ results = options }),
        sorter = conf.generic_sorter({}),
        attach_mappings = function(prompt_bufnr, map)
          local function on_select()
            local sel = action_state.get_selected_entry()
            actions.close(prompt_bufnr)
            -- sel.value for telescope, sel[1] for fzf-lua
            callback(sel.value or sel[1])
          end
          map('i', '<CR>', on_select)
          map('n', '<CR>', on_select)
          return true
        end,
      }):find()
    end

  else
    vim.ui.select(options, { prompt = prompt .. ':' }, function(choice)
      if choice then callback(choice) end
    end)
  end
end

-- Keymap: hierarchical pick from headers and subsequent lines -> copy to clipboard on select
vim.keymap.set('n', '<leader>?', function()
  local file_path = myconfig.my_notes_path .. "/scripts/files/nvim_keys.txt"
  local lines     = myconfig.read_lines_from_file(file_path)

  -- Parse categories and their items
  local categories = {}
  local items      = {}
  local current
  for _, line in ipairs(lines) do
    local header = line:match("^#%s*(.+)")
    if header then
      current = header
      table.insert(categories, header)
      items[header] = {}
    elseif current then
      if not (line:match("^%s*$")
              or line:match("^%-%-")
              or line:match("^[-]+$")) then
        table.insert(items[current], line)
      end
    end
  end

  -- Pick a category
  choose('Category', categories, function(cat)
    -- Pick a line in that category
    choose(cat, items[cat] or {}, function(line)
      -- Copy to clipboard and notify
      vim.fn.setreg('+', line)
      print('Copied to clipboard: ' .. line)
    end)
  end)
end, { noremap = true, silent = true })

