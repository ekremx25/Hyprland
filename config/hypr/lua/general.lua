-- General Hyprland settings converted from custom/general.conf.

hl.config({
  general = {
    gaps_in = 6,
    gaps_out = 3,
    border_size = 2,
    col = {
      active_border = { colors = { "rgba(89b4faff)", "rgba(89b4faff)" }, angle = 45 },
      inactive_border = "rgba(595959aa)",
    },
    resize_on_border = true,
    allow_tearing = false,
    layout = "dwindle",
    hover_icon_on_border = true,
    extend_border_grab_area = 15,
  },

  xwayland = {
    force_zero_scaling = true,
  },

  render = {
    cm_enabled = true,
    cm_auto_hdr = 1,
    cm_sdr_eotf = "default",
    send_content_type = true,
    use_fp16 = 2,
    keep_unmodified_copy = 2,
    non_shader_cm = 2,
    non_shader_cm_interop = 2,
  },

  decoration = {
    rounding = 10,
    active_opacity = 1.0,
    inactive_opacity = 1.0,
    shadow = {
      enabled = false,
      range = 12,
      render_power = 1000,
      color = "rgba(00000055)",
      color_inactive = "rgba(00000000)",
    },
    blur = {
      enabled = false,
      size = 9,
      passes = 5,
      vibrancy = 1.1696,
    },
  },

  animations = {
    enabled = true,
  },

  input = {
    kb_layout = "tr",
    follow_mouse = 1,
  },

  misc = {
    force_default_wallpaper = -1,
    disable_hyprland_logo = false,
  },
})

hl.curve("overshot", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.05 } } })
hl.curve("smoothOut", { type = "bezier", points = { { 0.5, 0 }, { 0.99, 0.99 } } })
hl.curve("smoothIn", { type = "bezier", points = { { 0.5, -0.5 }, { 0.68, 1.5 } } })

hl.animation({ leaf = "windows", enabled = true, speed = 5, bezier = "overshot", style = "slide" })
hl.animation({ leaf = "fade", enabled = true, speed = 5, bezier = "smoothIn" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 6, bezier = "default" })
