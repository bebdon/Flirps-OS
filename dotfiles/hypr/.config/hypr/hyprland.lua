require("config/variables")
require("config/env")
require("config/autostart")
require("config/monitors")
require("config/settings")
require("config/keybinds")
require("config/rules")
-- per-machine extras written by install.sh (e.g. VM tweaks); optional, gitignored
pcall(require, "config/machine")
