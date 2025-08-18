local wezterm = require 'wezterm'
local config  = {}

if wezterm.config_builder then
  config = wezterm.config_builder()
end

config.inactive_pane_hsb = { saturation = 0.75, brightness = 1.0 }

config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = false
config.switch_to_last_active_tab_when_closing_tab = true
config.font = wezterm.font_with_fallback({'FiraCode Nerd Font', 'JetBrains Mono'})
-- config.color_scheme = "Tokyo Night Storm"
config.show_tab_index_in_tab_bar = false
config.enable_scroll_bar = true
config.scrollback_lines = 20000
config.window_decorations = "NONE"
config.default_prog = { "zsh","-l" }
config.default_workspace = "~"
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
    action = wezterm.action.SpawnCommandInNewTab {
      cwd = wezterm.home_dir,
      args = { 'hx', wezterm.config_file },
    },
  },

  {
    key = 'g',
    mods = 'LEADER',
    action = wezterm.action.PaneSelect
  },
  {
    key = '|',
    mods = 'LEADER',
    action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' },
  },
  {
    key = '-',
    mods = 'LEADER',
    action = wezterm.action.SplitVertical { domain = 'CurrentPaneDomain' },
  },
  {
    key = '+',
    mods = 'LEADER',
    action = wezterm.action_callback(function(window, pane)
      local dims = pane:get_dimensions()
      local w = dims.pixel_width
      local h = dims.pixel_height
      if w < h then
        window:perform_action(
          wezterm.action { SplitVertical = { domain = "CurrentPaneDomain" } },
          pane
        )
      else
        window:perform_action(
          wezterm.action { SplitHorizontal = { domain = "CurrentPaneDomain" } },
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
    action = wezterm.action.SendKey { key = 'y', mods = 'CTRL' },
  }
}

wezterm.on('update-status', function(window)
  local status = ""
  if window:leader_is_active() then status = "LEADER" end
  if window:active_key_table() then status = window:active_key_table() end

  window:set_left_status(wezterm.format({
    { Text = status },
  }))
  window:set_right_status(wezterm.strftime('[%H:%M]'))
end)

wezterm.on(
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
      title = wezterm.truncate_left(title, max_width - 4)
      return ' [' .. title .. '] '
    end
    title = wezterm.truncate_left(title, max_width - 2)
    return '  ' .. title .. '  '
  end
)
return config

