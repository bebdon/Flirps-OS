local mainMod = _G.mainMod or "SUPER"
local terminal = _G.terminal or "kitty"

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

hl.bind(mainMod .. " + SHIFT + Left", hl.dsp.window.resize({ x = -50, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + Right", hl.dsp.window.resize({ x = 50, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + Up", hl.dsp.window.resize({ x = 0, y = -50, relative = true }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + Down", hl.dsp.window.resize({ x = 0, y = 50, relative = true }), { repeating = true })

hl.bind(mainMod .. " + CTRL + Left", hl.dsp.window.move({ direction = "l" }))
hl.bind(mainMod .. " + CTRL + Right", hl.dsp.window.move({ direction = "r" }))
hl.bind(mainMod .. " + CTRL + Up", hl.dsp.window.move({ direction = "u" }))
hl.bind(mainMod .. " + CTRL + Down", hl.dsp.window.move({ direction = "d" }))

hl.bind(mainMod .. " + Left", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + Right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + Up", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + Down", hl.dsp.focus({ direction = "down" }))

hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + ALT + F", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.float({ action = "toggle" }))

hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -q -n 1% s 5%- && qs -c panels ipc call osd brightness"), { locked = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -q s 5%+ && qs -c panels ipc call osd brightness"), { locked = true })

hl.bind("Print", hl.dsp.exec_cmd("~/.local/bin/screenshot"), { locked = true })
hl.bind("SHIFT + Print", hl.dsp.exec_cmd("~/.local/bin/screenshot --edit"), { locked = true })
hl.bind("SUPER + Print", hl.dsp.exec_cmd("~/.local/bin/screenshot --full"), { locked = true })
hl.bind("SUPER + SHIFT + Print", hl.dsp.exec_cmd("~/.local/bin/screenshot --full --edit"), { locked = true })

hl.bind("XF86PowerOff", hl.dsp.exec_cmd("loginctl lock-session"), { locked = true })
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("loginctl lock-session"), { repeating = true, locked = true })

hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { repeating = true, locked = true })
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+"), { repeating = true, locked = true })

hl.bind(mainMod .. " + F", hl.dsp.exec_cmd("waterfox"))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd("thunar"))
hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(terminal))

hl.bind(mainMod .. " + R", hl.dsp.exec_cmd("pkill -SIGUSR2 -x waybar; swaync-client -R; swaync-client -rs"))
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd("~/.local/bin/qs-panel clipboard"))
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd("~/.local/bin/qs-panel launcher"))
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("swaync-client -t -sw"))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("swaync-client -t -sw"))
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("~/.local/bin/qs-panel wallpapers"))
hl.bind(mainMod .. " + S", hl.dsp.exec_cmd("swaync-client -t -sw"))
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("~/.local/bin/qs-panel quicksettings wifi"))
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd("~/.local/bin/qs-panel quicksettings audio"))
hl.bind(mainMod .. " + H", hl.dsp.exec_cmd("~/.local/bin/settings"))
hl.bind(mainMod .. " + A", hl.dsp.exec_cmd("pkill -SIGUSR1 -x waybar"))

for i = 1, 10 do
  local key = tostring(i % 10)
  hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
  hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

hl.bind(mainMod .. " + SHIFT + T", hl.dsp.exec_cmd("~/.local/bin/screenshot --ocr"))
hl.bind(mainMod .. " + I", hl.dsp.exec_cmd("~/.local/bin/settings"))

-- Quickshell floating tools
hl.bind(mainMod .. " + equal", hl.dsp.exec_cmd("qs -c panels ipc call calculator toggle"))
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd("qs -c panels ipc call timer toggle"))
hl.bind(mainMod .. " + ALT + N", hl.dsp.exec_cmd("qs -c panels ipc call notes toggle"))

-- Lock-key popups (Quickshell OSD). non_consuming = the key still works normally.
hl.bind("Caps_Lock", hl.dsp.exec_cmd("qs -c panels ipc call osd locks caps"), { non_consuming = true, release = true, ignore_mods = true, locked = true })
hl.bind("Num_Lock", hl.dsp.exec_cmd("qs -c panels ipc call osd locks num"), { non_consuming = true, release = true, ignore_mods = true, locked = true })
