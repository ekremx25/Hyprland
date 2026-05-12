-- Environment variables converted from custom/env.conf and hyprland.conf.

local runtime_dir = os.getenv("XDG_RUNTIME_DIR") or ""

local env = {
  XDG_CURRENT_DESKTOP = "Hyprland",
  XDG_SESSION_DESKTOP = "Hyprland",
  XDG_SESSION_TYPE = "wayland",
  QT_QPA_PLATFORM = "wayland",
  QT_CURSOR_SIZE = "24",
  QT_QPA_PLATFORMTHEME = "qt6ct",
  SSH_AUTH_SOCK = runtime_dir .. "/ssh-agent.socket",
  MOZ_ENABLE_WAYLAND = "1",
  ECORE_EVAS_ENGINE = "wayland_egl",
  ELM_DISPLAY = "wayland",
  GDK_BACKEND = "wayland",
  CLUTTER_BACKEND = "wayland",
  ELECTRON_OZONE_PLATFORM_HINT = "wayland",
  GDK_SCALE = "1",

  GTK_IM_MODULE = "fcitx",
  QT_IM_MODULE = "fcitx",
  XMODIFIERS = "@im=fcitx",
  SDL_IM_MODULE = "fcitx",
  GLFW_IM_MODULE = "ibus",
}

for key, value in pairs(env) do
  hl.env(key, value)
end
