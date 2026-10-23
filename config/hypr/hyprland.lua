-- Main Hyprland Lua config.

local hypr_dir = os.getenv("HOME") .. "/.config/hypr"

package.path = hypr_dir .. "/?.lua;" .. hypr_dir .. "/?/init.lua;" .. package.path

require("lua.env")
require("lua.general")
-- This display is also connected over DP-3; keep the 165 Hz DP connection active.
hl.monitor({ output = "HDMI-A-1", disabled = true })
require("lua.rules")
require("lua.keybinds")
require("lua.execs")
