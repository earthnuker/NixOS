local wez      = require 'wezterm'
local wss      = wez.plugin.require("https://github.com/MLFlexer/smart_workspace_switcher.wezterm")
local ssh_menu = wez.plugin.require("https://github.com/PaysanCorrezien/ssh_menu.wezterm")

-- local schema      = {
--   options = {
--     prompt = "Workspace: ",
--     callback = history.Wrapper(sessionizer.DefaultCallback)
--   },
--   sessionizer.DefaultWorkspace {},
--   {
--     sessionizer.AllActiveWorkspaces { filter_current = false, filter_default = false },
--     processing = sessionizer.for_each_entry(function(entry)
--       entry.label = wezterm.format {
--         { Text = "󱂬 : " .. entry.label },
--       }
--     end)
--   },
--   history.MostRecentWorkspace {},
--   -- wezterm.plugin.require "https://github.com/mikkasendke/sessionizer-zoxide.git".Zoxide {},
--   processing = sessionizer.for_each_entry(function(entry)
--     entry.label = entry.label:gsub(wezterm.home_dir, "~")
--   end)
-- }

local config   = {}

if wez.config_builder then
  config = wez.config_builder()
end

wss.apply_to_config(config)

config.inactive_pane_hsb = { saturation = 0.5, brightness = 0.5 }

config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = false
config.switch_to_last_active_tab_when_closing_tab = true
config.font = wez.font_with_fallback({ 'FiraCode Nerd Font', 'JetBrains Mono', ' Nerd Font Symbols',
  'Noto Color Emoji' })
config.show_tab_index_in_tab_bar = false
config.enable_scroll_bar = true
config.scrollback_lines = 20000
-- config.window_decorations = "RESIZE"
config.default_prog = { "zsh", "-l" }
config.default_workspace = "home"
config.tab_max_width = 32
config.use_dead_keys = false
config.adjust_window_size_when_changing_font_size = false
config.pane_focus_follows_mouse = true
config.swallow_mouse_click_on_window_focus = true
config.swallow_mouse_click_on_pane_focus = true
config.hide_mouse_cursor_when_typing = true
-- config.front_end = 'WebGpu'
-- config.webgpu_power_preference = 'HighPerformance'

config.leader = { key = 'y', mods = 'CTRL', timeout_milliseconds = 3000 }
config.keys = {
  {
    key = ',',
    mods = 'LEADER',
    action = wez.action.SpawnCommandInNewWindow {
      cwd = wez.home_dir,
      args = { 'hx', wez.config_file },
    },
  },
  { key = '.', mods = 'LEADER', action = wss.switch_workspace() },
  {
    key = 's',
    mods = 'LEADER',
    action = wez.action_callback(function(window, pane)
      ssh_menu.ssh_menu(window, pane)
    end),
  },
  {
    key = 'g',
    mods = 'LEADER',
    action = wez.action.PaneSelect
  },
  { key = "w", mods = "LEADER", action = wez.action.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" }) },
  {
    key = "W",
    mods = "LEADER",
    action = wez.action.PromptInputLine({
      description = wez.format({
        { Attribute = { Intensity = "Bold" } },
        { Foreground = { AnsiColor = "Fuchsia" } },
        { Text = "Enter name for new workspace" },
      }),
      action = wez.action_callback(function(window, pane, line)
        if line then
          window:perform_action(
            wez.action.SwitchToWorkspace({
              name = line,
            }),
            pane
          )
        end
      end),
    })
  },
  {
    key = "t",
    mods = "LEADER",
    action = wez.action_callback(function(window, pane, line)
      window:toast_notification("HI","HI")
    end),
  },
  {
    key = '|',
    mods = 'LEADER',
    action = wez.action.SplitHorizontal { domain = 'CurrentPaneDomain' },
  },
  {
    key = '-',
    mods = 'LEADER',
    action = wez.action.SplitVertical { domain = 'CurrentPaneDomain' },
  },
  {
    key = '+',
    mods = 'LEADER',
    action = wez.action_callback(function(window, pane)
      local dims = pane:get_dimensions()
      local w = dims.pixel_width
      local h = dims.pixel_height
      if w < h then
        window:perform_action(
          wez.action { SplitVertical = { domain = "CurrentPaneDomain" } },
          pane
        )
      else
        window:perform_action(
          wez.action { SplitHorizontal = { domain = "CurrentPaneDomain" } },
          pane
        )
      end
    end),
  },
  {
    key = 'y',
    -- When we're in leader mode _and_ CTRL + A is pressed...
    mods = 'LEADER|CTRL',
    -- Actually send CTRL + A key to the terminal
    action = wez.action.SendKey { key = 'y', mods = 'CTRL' },
  }
}

wez.on("gui-startup", function(cmd)
  local tab, pane, window = wez.mux.spawn_window(cmd or {})
  window:gui_window():maximize()
end)


wez.on('update-status', function(window)
  local status = ""
  if window:leader_is_active() then status = "LEADER" end
  if window:active_key_table() then status = window:active_key_table() end

  window:set_left_status(wez.format({
    { Text = status },
  }))
  window:set_right_status(wez.strftime('[%H:%M]'))
end)

wez.on(
  'format-tab-title',
  function(tab, tabs, panes, config, hover, max_width)
    local function tab_title(tab_info)
      local title = tab_info.tab_title
      -- if the tab title is explicitly set, take that
      if title and #title > 0 then
        return title
      end
      -- Otherwise, use the title from the active pane
      -- in that tab
      return tab_info.active_pane.title
    end

    local title = tab_title(tab)
    if tab.is_active then
      title = wez.truncate_left(title, max_width - 4)
      return ' [' .. title .. '] '
    end
    title = wez.truncate_left(title, max_width - 2)
    return '  ' .. title .. '  '
  end
)
return config
