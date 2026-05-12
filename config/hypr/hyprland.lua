-- Main Hyprland Lua config.

local hypr_dir = os.getenv("HOME") .. "/.config/hypr"

package.path = hypr_dir .. "/?.lua;" .. hypr_dir .. "/?/init.lua;" .. package.path

require("lua.env")
require("lua.general")
require("lua.rules")
require("lua.keybinds")
require("lua.execs")
