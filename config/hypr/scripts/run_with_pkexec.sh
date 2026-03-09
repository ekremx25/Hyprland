#!/bin/bash
# Hyprland oturumundan ortam değişkenlerini al
export XDG_SESSION_TYPE=wayland
export XDG_CURRENT_DESKTOP=Hyprland
export QT_QPA_PLATFORM=wayland
export WAYLAND_DISPLAY=$(echo $WAYLAND_DISPLAY)
export DISPLAY=:0

# Qt Wayland entegrasyonunu desteklemek için ek değişkenler
export QT_WAYLAND_FORCE_DPI=96
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1

# pkexec ile komutu çalıştır
pkexec --preserve-env=QT_QPA_PLATFORM "$@"
