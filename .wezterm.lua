-- Pull in the wezterm API
local os              = require 'os'
local wezterm         = require 'wezterm'
local act             = wezterm.action
local mux             = wezterm.mux
local session_manager = require 'wezterm-session-manager/session-manager'

local config = {}

-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
if wezterm.config_builder then
  config = wezterm.config_builder()
end

config.adjust_window_size_when_changing_font_size = false
config.automatically_reload_config = true
config.color_scheme = 'Gruvbox Dark (Gogh)'
config.enable_scroll_bar = true
config.enable_wayland = true
-- config.font = wezterm.font('Hack')
--config.font = wezterm.font('Monaspace Neon')

local user_domain = os.getenv("USERDOMAIN") or ""
if string.lower(user_domain):find("lenovo2") then
  config.font_size = 10.0
else
  config.font_size = 11.0
end

config.hide_tab_bar_if_only_one_tab = true
config.show_close_tab_button_in_tabs = false
config.mouse_bindings = {
    -- Open URLs with Ctrl+Click
    {
        event = { Up = { streak = 1, button = 'Left' } },
        mods = 'CTRL',
        action = act.OpenLinkAtMouseCursor,
    }
}
config.pane_focus_follows_mouse = false
config.scrollback_lines = 5000 -- Default is 3500
config.use_dead_keys = false
config.warn_about_missing_glyphs = false
--config.window_decorations = 'TITLE | RESIZE'
--config.window_decorations = 'NONE'
config.window_decorations = 'RESIZE'
if wezterm.target_triple == 'x86_64-pc-windows-msvc' or wezterm.target_triple == 'x86_64-pc-windows-gnu' then
    -- The leader is similar to how tmux defines a set of keys to hit in order to
    -- invoke tmux bindings. Binding to ctrl-a here to mimic tmux
    config.leader = { key = 'a', mods = 'CTRL', timeout_milliseconds = 1000 }

    config.window_padding = {
        left = 15,
        right = 5,
        top = 20,
        bottom = 10,
    }
else
    config.leader = { key = 'b', mods = 'CTRL', timeout_milliseconds = 1000 }

    config.window_padding = {
        left = 10,
        right = -3,
        top = 10,
        bottom = 0,
    }
end

-- Tab bar
-- config.use_fancy_tab_bar = true
config.tab_bar_at_bottom = true
config.switch_to_last_active_tab_when_closing_tab = true
config.tab_max_width = 15
config.colors = {
    tab_bar = {
        active_tab = {
            fg_color = '#3c3836',
            --bg_color = '#8ec07c',
            bg_color = '#458588',
        }
    }
}

-- Setup muxing by default
config.unix_domains = {
  {
    name = 'unix',
  },
}

-- config.disable_default_key_bindings = true,

-- Session manager
wezterm.on("save_session", function(window) session_manager.save_state(window) end)
wezterm.on("load_session", function(window) session_manager.load_state(window) end)
wezterm.on("restore_session", function(window) session_manager.restore_state(window) end)

-- wezterm-move
--local function is_vim(pane)
--  local process_info = pane:get_foreground_process_info()
--  local process_name = process_info and process_info.name
--  -- return process_name == "nvim" or process_name == "vim"
--
--  if process_name then
--    process_name = process_name:lower()
--    return string.find(process_name, "vim") ~= nil
--  end
--
--  return false
--end

-- local function is_vim(pane)
--   -- local process_info = pane:get_foreground_process_info()
--   -- local process_name = process_info and process_info.name
--   local process_name = pane:get_foreground_process_name()
-- 
--   if process_name then
--     -- Convert to lowercase and check for the presence of "vim"
--     process_name = process_name:lower()
--     
--     -- Open a file in append mode
--     local file = io.open("C:/Users/se-jonornf-01/test_process_name.txt", "a")
--     if file then
--       file:write(process_name .. "\n")
--       file:close()
--     else
--       print("Failed to open file test_process_name.txt for writing.")
--     end
-- 
--     return string.find(process_name, "vim") ~= nil
--   end
-- 
--   return false
-- end

-- Define directional keys for navigation and resizing
-- local direction_keys = {
--   Left = "h",
--   Down = "j",
--   Up = "k",
--   Right = "l",
--   h = "Left",
--   j = "Down",
--   k = "Up",
--   l = "Right",
-- }

-- Function to create navigation keybindings tailored for vim usage or default terminal navigation/resizing
-- local function split_nav(resize_or_move, key)
--   return {
--     key = key,
--     mods = resize_or_move == "resize" and "META" or "CTRL", -- Here you specify METAs for resizing, CTRL for movement between panes
--     action = wezterm.action_callback(function(win, pane)
--       if is_vim(pane) then
--         -- Send key to vim/nvim directly
--         win:perform_action({
--           SendKey = { key = key, mods = resize_or_move == "resize" and "META" or "CTRL" },
--         }, pane)
--       else
--         if resize_or_move == "resize" then
--           win:perform_action({ AdjustPaneSize = { direction_keys[key], 3 } }, pane)
--         else
--           win:perform_action({ ActivatePaneDirection = direction_keys[key] }, pane)
--         end
--       end
--     end),
--   }
-- end

-- local function split_nav(resize_or_move, key)
--   return {
--     key = key,
--     mods = resize_or_move == "resize" and "LEADER" or "ALT", -- Change "resize" to use "LEADER" and "move" to use "ALT"
--     action = wezterm.action_callback(function(win, pane)
--       if is_vim(pane) then
--         --win:perform_action({
--         --  SendKey = { key = key, mods = resize_or_move == "resize" and "LEADER" or "ALT" },
--         --}, pane)
--         --win:perform_action({
--         --  SendKey = { key = key, mods = "ALT" },
--         --}, pane)
--         win:perform_action({
--           SendKey = { key = "w", mods = "CTRL" },
--         }, pane)
--         win:perform_action({
--           SendKey = { key = key },
--         }, pane)
--       else
--         if resize_or_move == "resize" then
--           win:perform_action({ AdjustPaneSize = { direction_keys[key], 3 } }, pane)
--         else
--           win:perform_action({ ActivatePaneDirection = direction_keys[key] }, pane)
--         end
--       end
--     end),
--   }
-- end

-- Generate the desired key mappings for nav keys and resizing
-- local nav_keys = {
--   -- movement keys between panes
--   split_nav("move", "h"),
--   split_nav("move", "j"),
--   split_nav("move", "k"),
--   split_nav("move", "l"),
--   -- resizing keys
--   split_nav("resize", "h"),
--   split_nav("resize", "j"),
--   split_nav("resize", "k"),
--   split_nav("resize", "l"),
-- }

local direction_keys = {
  h = "Left",
  j = "Down",
  k = "Up",
  l = "Right",
}
-- Next and Prev is also available as dir keys

local function split_nav(key)
  return {
    key = key,
    mods = "ALT",
    action = wezterm.action_callback(function(win, pane)
      -- Check if there are multiple panes to navigate
      local dir = direction_keys[key]
      local tab = pane:tab()
      if tab:get_pane_direction(dir) then
        win:perform_action({ ActivatePaneDirection = dir }, pane)
      else
        -- Send the key sequence to process, e.g., vim
        -- win:perform_action({
          -- SendKey = { key = key, mods = "ALT" }
        -- }, pane)
        win:perform_action({
          SendKey = { key = "w", mods = "CTRL" },
        }, pane)
        win:perform_action({
          SendKey = { key = key },
        }, pane)
      end
    end),
  }
end

-- Custom key bindings
config.keys = {
    -- Leader is defined as Ctrl-A but this allows it to be sent to programs like vim when pressed twice
    { key = 'a', mods = 'LEADER|CTRL', action = wezterm.action.SendKey { key = 'a', mods = 'CTRL' }, },

    -- Copy/vim mode
    { key = 'v', mods = 'LEADER', action = act.ActivateCopyMode, },
    { key = 'f', mods = 'LEADER', action = wezterm.action.Search {CaseInSensitiveString = 'test' } },
    { key = 'f', mods = 'LEADER|CTRL', action = wezterm.action.Search {CaseSensitiveString = 'test' } },
    { key = 'g', mods = 'LEADER', action = wezterm.action.Search {Regex = 'test'} },

    -- ----------------------------------------------------------------
    -- TABS
    --
    -- Where possible, I'm using the same combinations as I would in tmux
    -- ----------------------------------------------------------------

    -- Show tab navigator; similar to listing panes in tmux
    {
        key = 'w',
        mods = 'LEADER',
        action = act.ShowTabNavigator,
    },
    -- Rename current tab; analagous to command in tmux
    {
        key = ',',
        mods = 'LEADER|ALT',
        action = act.PromptInputLine {
            description = 'Enter new name for tab',
            action = wezterm.action_callback(
                function(window, pane, line)
                    if line then
                        window:active_tab():set_title(line)
                    end
                end
            ),
        },
    },
    -- Move to next/previous TAB
    --{
    --    key = 'n',
    --    mods = 'LEADER',
    --    action = act.ActivateTabRelative(1),
    --},
    --{
    --    key = 'p',
    --    mods = 'LEADER',
    --    action = act.ActivateTabRelative(-1),
    --},
    -- Close tab
    {
        key = 'q',
        mods = 'LEADER|SHIFT',
        action = act.CloseCurrentTab{ confirm = true },
    },

    -- ----------------------------------------------------------------
    -- PANES
    --
    -- These are great and get me most of the way to replacing tmux
    -- entirely, particularly as you can use "wezterm ssh" to ssh to another
    -- server, and still retain Wezterm as your terminal there.
    -- ----------------------------------------------------------------

    -- Vertical split
    {
        key = 'Enter',
        mods = 'LEADER',
        action = act.SplitPane {
            direction = 'Right',
            size = { Percent = 50 },
        },
    },
    -- Horizontal split
    {
        key = '<',
        mods = 'LEADER',
        action = act.SplitPane {
            direction = 'Down',
            size = { Percent = 50 },
        },
    },
    { key = "h", mods = "LEADER", action = act.ActivatePaneDirection("Left") },
    { key = "j", mods = "LEADER", action = act.ActivatePaneDirection("Down") },
    { key = "k", mods = "LEADER", action = act.ActivatePaneDirection("Up") },
    { key = "l", mods = "LEADER", action = act.ActivatePaneDirection("Right") },
    { key = 'y', mods = 'LEADER', action = act.AdjustPaneSize { 'Left', 5 }, },
    { key = 'u', mods = 'LEADER', action = act.AdjustPaneSize { 'Down', 5 }, },
    { key = 'i', mods = 'LEADER', action = act.AdjustPaneSize { 'Up', 5 } },
    { key = 'o', mods = 'LEADER', action = act.AdjustPaneSize { 'Right', 5 }, },
    { key = "q", mods = "LEADER", action = act.CloseCurrentPane { confirm = false } },
    { key = "q", mods = "LEADER|CTRL", action = act.CloseCurrentPane { confirm = false } },

    -- Swap active pane with another one
    {
        key = 'T',
        mods = 'LEADER|SHIFT',
        action = act.PaneSelect { mode = "SwapWithActiveKeepFocus" },
    },
    -- Zoom current pane (toggle)
    {
        key = 'z',
        mods = 'LEADER',
        action = act.TogglePaneZoomState,
    },
    {
        key = 'f',
        mods = 'LEADER|SHIFT',
        action = act.TogglePaneZoomState,
    },
    -- Move to next/previous pane
    --{
    --    key = ';',
    --    mods = 'LEADER',
    --    action = act.ActivatePaneDirection('Prev'),
    --},
    --{
    --    key = 'o',
    --    mods = 'LEADER',
    --    action = act.ActivatePaneDirection('Next'),
    --},

    ---- Attach to muxer
    {
        key = 'a',
        mods = 'LEADER',
        action = act.AttachDomain 'unix',
    },

    -- Detach from muxer
    {
        key = 'd',
        mods = 'LEADER',
        action = act.DetachDomain { DomainName = 'unix' },
    },

    -- Show list of workspaces
    {
        key = 's',
        mods = 'LEADER',
        action = act.ShowLauncherArgs { flags = 'WORKSPACES' },
    },
    -- Rename current session; analagous to command in tmux
    {
        key = '-',
        mods = 'LEADER|ALT',
        action = act.PromptInputLine {
            description = 'Enter new name for session',
            action = wezterm.action_callback(
                function(window, pane, line)
                    if line then
                        mux.rename_workspace(
                            window:mux_window():get_workspace(),
                            line
                        )
                    end
                end
            ),
        },
    },

    -- Scroll
    { key = 'J', mods = 'ALT|SHIFT', action = wezterm.action.ScrollByLine(1), },
    { key = 'K', mods = 'ALT|SHIFT', action = wezterm.action.ScrollByLine(-1), },

    -- Copying
    --if wezterm.target_triple ~= "x86_64-pc-windows-msvc" and wezterm.target_triple ~= "x86_64-pc-windows-gnu" then
    { key = 'C', mods = 'ALT|SHIFT', action = wezterm.action.CopyTo 'ClipboardAndPrimarySelection', },
    { key = 'V', mods = 'ALT|SHIFT', action = wezterm.action.PasteFrom 'Clipboard', },

    -- Session manager
    {key = "m", mods = "LEADER", action = wezterm.action{EmitEvent = "save_session"}},
    {key = ".", mods = "LEADER", action = wezterm.action{EmitEvent = "restore_session"}},
    --{key = "p", mods = "LEADER", action = wezterm.action{EmitEvent = "load_session"}},

    -- Disable default
    { key = 'Enter', mods = 'ALT', action = wezterm.action.DisableDefaultAssignment, },
    { key = 'l', mods = 'ALT', action = wezterm.action.DisableDefaultAssignment, },
    { key = 'h', mods = 'ALT', action = wezterm.action.DisableDefaultAssignment, },
    { key = 'j', mods = 'ALT', action = wezterm.action.DisableDefaultAssignment, },
    { key = 'k', mods = 'ALT', action = wezterm.action.DisableDefaultAssignment, },

    -- Tabs
    { key = "1", mods = "LEADER", action = wezterm.action{ActivateTab=0}, },
    { key = "2", mods = "LEADER", action = wezterm.action{ActivateTab=1}, },
    { key = "3", mods = "LEADER", action = wezterm.action{ActivateTab=2}, },
    { key = "4", mods = "LEADER", action = wezterm.action{ActivateTab=3}, },
    { key = "5", mods = "LEADER", action = wezterm.action{ActivateTab=4}, },
    { key = "6", mods = "LEADER", action = wezterm.action{ActivateTab=5}, },
    { key = "7", mods = "LEADER", action = wezterm.action{ActivateTab=6}, },
    { key = "8", mods = "LEADER", action = wezterm.action{ActivateTab=7}, },
    { key = "9", mods = "LEADER", action = wezterm.action{ActivateTab=8}, },
    { key = "0", mods = "LEADER", action = wezterm.action{ActivateTab=9}, },
    { key = 't', mods = "LEADER", action = wezterm.action{SpawnTab="DefaultDomain"}, },
    { key = 'q', mods = 'LEADER|SHIFT', action = wezterm.action.QuitApplication },
    -- Seamless integration
    split_nav("h"),
    split_nav("j"),
    split_nav("k"),
    split_nav("l"),
}

-- Append nav_keys to the default set of keybindings
-- for i = 1, #nav_keys do
--   table.insert(config.keys, nav_keys[i])
-- end

--config.default_gui_startup_args = { 'connect', 'unix' }
if wezterm.target_triple == 'x86_64-pc-windows-msvc' or wezterm.target_triple == 'x86_64-pc-windows-gnu' then
    --config.default_prog = { 'pwsh.exe', '-NoLogo' }
    config.default_prog = { 'powershell.exe' }

    wezterm.on('gui-startup', function(cmd)
        -- allow `wezterm start -- something` to affect what we spawn
        -- in our initial window
        local args = {}
        if cmd then
            args = cmd.args
        end

        ---- Set a workspace for coding on a current project
        ---- Top pane is for the editor, bottom pane is for the build tool
        --local project_dir = wezterm.home_dir .. '/wezterm'
        --local tab, build_pane, window = mux.spawn_window {
        --  workspace = 'coding',
        --  cwd = project_dir,
        --  args = args,
        --}
        --local editor_pane = build_pane:split {
        --  direction = 'Top',
        --  size = 0.6,
        --  cwd = project_dir,
        --}
        ---- may as well kick off a build in that pane
        --build_pane:send_text 'cargo build\n'

        ---- A workspace for interacting with a local machine that
        ---- runs some docker containners for home automation
        ----local tab, pane, window = mux.spawn_window {
        ----  workspace = 'automation',
        ----  args = { 'ssh', 'vault' },
        ----}

        ---- We want to startup in the coding workspace
        --mux.set_active_workspace 'coding'



        -- Try to attach...
        -- Check if the workspace 'coding' exists
        --local workspace_name = 'coding'
        --local existing_workspace = false
        --for _, workspace in ipairs(mux.get_workspaces()) do
        --  if workspace == workspace_name then
        --    existing_workspace = true
        --    break
        --  end
        --end

        --if existing_workspace then
        --    window = mux.attach_workspace(workspace_name)
        --else

        --local unix = mux.get_domain("unix")
        --mux.set_default_domain(unix)
        --unix:attach()
        --mux.set_active_workspace 'coding'

        --local code_root_dir = os.getenv("code_root_dir")
        --local full_path = code_root_dir .. "/Code2/C++"
        ----local tab1, pane, window = mux.spawn_window(cmd or {})
        local tab1, pane, window = mux.spawn_window{cwd = full_path, workspace = 'coding' }
        window:gui_window():maximize()
        --tab1:set_title("one - pwsh")

        --local code_root_dir = "~/"
        --local tab2, second_pane, _ = window:spawn_tab { cwd = code_root_dir, workspace = 'coding' }
        --tab2:set_title("two - pwsh")
        --local tab3, third_pane, _ = window:spawn_tab { cwd = "C:\\", workspace = 'coding' }
        --tab3:set_title("three - pwsh")
        ----third_pane:send_text ".cdc\n"
        --local tab4, fourth_pane, _ = window:spawn_tab { cwd = "~/", workspace = 'coding' }
        --tab4:set_title("four - pwsh")
        ----fourth_pane:send_text ".cdp\n"

        --tab1:activate()
        --end

        --session_manager.restore_state(window)

    end)
end

wezterm.on("format-tab-title", function(tab)
    local new_title = tostring(tab.active_pane.current_working_dir):gsub("^file:///", "")
    local max_title_len = 20
    if #new_title > max_title_len then
        new_title = "..." .. new_title:sub(-(max_title_len-3))
    end
    return {
        { Text = new_title }
    }
end)

-- Return config to wezterm
return config

-- Kept for reference (resize with yuio and using wezterm-move)
-- local function is_vim(pane)
--   local process_info = pane:get_foreground_process_info()
--   local process_name = process_info and process_info.name
-- 
--   return process_name == "nvim" or process_name == "vim"
-- end
-- 
-- -- Define mappings for leader key resizing
-- local resize_keys = {
--   y = "h",
--   u = "j",
--   i = "k",
--   o = "l",
-- }
-- 
-- local direction_keys = {
--   Left = "h",
--   Down = "j",
--   Up = "k",
--   Right = "l",
-- }
-- 
-- local function create_resize_keybinding(leader_key, direction_key)
--   return {
--     key = leader_key,
--     mods = "LEADER",
--     action = wezterm.action_callback(function(win, pane)
--       if is_vim(pane) then
--         -- If the pane is running vim, send ALT-h/j/k/l keys
--         win:perform_action({
--           SendKey = { key = direction_key, mods = "ALT" }
--         }, pane)
--       else
--         -- Otherwise, adjust the pane size
--         win:perform_action({ AdjustPaneSize = { direction_keys[direction_key], 3 } }, pane)
--       end
--     end)
--   }
-- end
-- 
-- -- Define custom leader key resize bindings
-- local nav_keys = {
--   create_resize_keybinding("y", "h"),
--   create_resize_keybinding("u", "j"),
--   create_resize_keybinding("i", "k"),
--   create_resize_keybinding("o", "l"),
-- }
-- 
-- -- Define your complete configuration
-- local config = {}
-- 
-- -- Integrate navigation and other existing key bindings
-- config.keys = {
--   -- Original leader and sign key configurations
--   { key = 'a', mods = 'LEADER|CTRL', action = wezterm.action.SendKey { key = 'a', mods = 'CTRL' }, },
--   { key = 'v', mods = 'LEADER', action = wezterm.action.ActivateCopyMode, },
--   { key = 'f', mods = 'LEADER', action = wezterm.action.Search { CaseInSensitiveString = 'test' } },
--   
--   -- Insert the custom nav_keys configurations for resizing
-- }
-- 
-- -- Append nav_keys to the default set of keybindings
-- for i = 1, #nav_keys do
--   table.insert(config.keys, nav_keys[i])
-- end

