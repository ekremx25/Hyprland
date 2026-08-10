-- Startup commands converted from exec/exec-once lines.

hl.on("hyprland.start", function()
  hl.exec_cmd("systemctl --user start hyprpolkitagent")
  hl.exec_cmd("systemctl --user start hypridle.service")
  hl.exec_cmd("nm-applet --indicator")
  hl.exec_cmd("quickshell")
  hl.exec_cmd("awww-daemon")
  hl.exec_cmd("dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")

  hl.exec_cmd("fcitx5 -d")
  hl.exec_cmd("sleep 2 && fcitx5-remote -o")
end)
