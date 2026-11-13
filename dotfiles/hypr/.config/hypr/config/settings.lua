hl.config({
  general = {
    border_size = 0,
    gaps_in = 4,
    gaps_out = 6,
    float_gaps = 6,
    resize_on_border = true,
    extend_border_grab_area = 30,
  },

  decoration = {
    rounding = 12,
    active_opacity = 0.92,
    inactive_opacity = 0.85,
    blur = {
      enabled = true,
      size = 8,
      passes = 3,
      new_optimizations = true,
      vibrancy = 0.17,
    },
    shadow = {
      enabled = true,
      range = 20,
      render_power = 3,
      color = 0x66000000,
    },
  },

  input = {
    kb_layout = "us",
    kb_options = "grp:alt_shift_toggle",
    accel_profile = "flat",
    touchpad = {
      natural_scroll = true,
      disable_while_typing = false,
    },
  },

  misc = {
    focus_on_activate = false,
    font_family = "JetBrains Mono",
    disable_hyprland_logo = true,
    disable_splash_rendering = true,
  },
})

-- ---- Animations ------------------------------------------------------------
-- The settings app (Windows page) edits these two lines.
local ANIM_ON = true      -- false = no animations
local ANIM_SPEED = 1.0    -- multiplier: 0.6 fast, 1.0 normal, 1.4 relaxed (higher = slower)

local function anim(leaf, speed, opts)
  opts = opts or {}
  opts.leaf = leaf
  opts.enabled = ANIM_ON
  opts.speed = speed * ANIM_SPEED
  hl.animation(opts)
end

hl.curve("myBezier",  { type = "bezier", points = { {0.05, 0.9}, {0.1, 1.05} } })
hl.curve("overshoot", { type = "bezier", points = { {0.05, 0.9}, {0.1, 1.1} } })
hl.curve("smoothOut", { type = "bezier", points = { {0.23, 1}, {0.32, 1} } })
hl.curve("linear",    { type = "bezier", points = { {0, 0}, {1, 1} } })
-- springs are computed per frame on the CPU side, cheap on this laptop
hl.curve("bouncy",    { type = "spring", mass = 1, stiffness = 220, damping = 19 })
hl.curve("soft",      { type = "spring", mass = 1, stiffness = 180, damping = 24 })

anim("windows",       4.0, { spring = "soft" })
anim("windowsIn",     4.0, { spring = "bouncy", style = "popin 82%" })
anim("windowsOut",    1.6, { bezier = "linear", style = "popin 88%" })
anim("windowsMove",   3.5, { spring = "soft" })
anim("border",        5.0, { bezier = "smoothOut" })
anim("fade",          3.0, { bezier = "smoothOut" })
anim("fadeOut",       1.6, { bezier = "linear" })
anim("layers",        3.0, { bezier = "smoothOut" })
anim("layersIn",      3.0, { bezier = "overshoot", style = "slide" })
anim("layersOut",     1.6, { bezier = "linear", style = "fade" })
anim("workspaces",    3.5, { bezier = "smoothOut", style = "slidefade 18%" })
anim("specialWorkspace", 3.5, { bezier = "overshoot", style = "slidefadevert 20%" })
