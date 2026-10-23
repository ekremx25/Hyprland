-- Main Hyprland Lua config.

local hypr_dir = os.getenv("HOME") .. "/.config/hypr"

package.path = hypr_dir .. "/?.lua;" .. hypr_dir .. "/?/init.lua;" .. package.path

require("lua.env")
require("lua.general")
require("lua.rules")
require("lua.keybinds")
require("lua.execs")

-- Optional machine-specific overrides (monitors, rules for custom Hyprland
-- builds) live in lua/local.lua, which is not part of the shared config.
-- A missing or failing local.lua never breaks the main config.
pcall(require, "lua.local")
