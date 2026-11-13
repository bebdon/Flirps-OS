for _, ns in ipairs({ "qs-bar", "launcher", "qs-dock", "qs-launcher", "qs-power", "qs-clipboard", "qs-wallpapers" }) do
  hl.layer_rule({ match = { namespace = "^" .. ns .. "$" }, blur = true, ignore_alpha = 0.3 })
end

-- Quickshell settings app (qs -n -c settings)
hl.window_rule({
  name  = "quickshell-settings",
  match = { class = "^org\\.quickshell$", title = "^Settings$" },
  float = true,
  size  = "1100 720",
  center = true,
})

-- Quickshell overlays animate themselves; skip Hyprland's layer animation so they don't animate twice.
for _, ns in ipairs({ "qs-launcher", "qs-power", "qs-clipboard", "qs-wallpapers", "qs-quicksettings", "qs-dashboard", "qs-media", "qs-tool", "qs-desktop", "qs-osd", "qs-notifs", "qs-notifcenter" }) do
  hl.layer_rule({ match = { namespace = "^" .. ns .. "$" }, no_anim = true })
end
-- blur behind the drop-down popups and floating tools too
for _, ns in ipairs({ "qs-quicksettings", "qs-dashboard", "qs-media", "qs-tool", "qs-osd", "qs-notifs", "qs-notifcenter" }) do
  hl.layer_rule({ match = { namespace = "^" .. ns .. "$" }, blur = true, ignore_alpha = 0.3 })
end
