# Hyprland Dotfiles Installer

This repository provides an opinionated one-command installer for my Arch Linux Hyprland setup. It installs the packages I use, prepares the desktop environment, copies my dotfiles, wallpapers, fonts, and icons, and applies a few post-install system tweaks.

It is meant for Arch Linux and is designed around my personal workflow, software choices, and visual setup.

## What This Installer Does

The `install.sh` script will:

- install required official Arch packages with `pacman`
- install `yay` automatically if it is missing
- install selected AUR packages with `yay`
- install and configure `oh-my-zsh` and Zsh plugins
- install bundled icons, fonts, wallpapers, and configuration files from this repository
- configure GRUB kernel parameters for my AMD setup
- configure `libvirt` and enable the service
- enable `sddm`
- back up existing files before replacing them

## Included Configuration

The installer copies these configs into `~/.config`:

- `fastfetch`
- `gtk-3.0`
- `gtk-4.0`
- `hypr`
- `kitty`
- `Kvantum`
- `nwg-look`
- `quickshell`
- `qt6ct`
- `rofi`
- `waypaper`
- `xsettingsd`

## Quickshell Overview

This setup includes an active Quickshell configuration from [`config/quickshell`](./config/quickshell) and uses it as a core part of the desktop experience.

The current shell layout includes:

- a top bar
- a bottom dock
- desktop weather
- notification toasts
- volume OSD on supported screens
- startup helpers for monitor layout, mouse settings, and EQ bootstrap

### Current bar layout

The live bar layout from [`bar_config.json`](./config/quickshell/bar_config.json) is:

- left: `Launcher`, `Calendar`, `RamModule`, `SysInfoGroup`
- center: `Workspaces`, `Notifications`, `Notepad`
- right: `Clipboard`, `Equalizer`, `Volume`

Workspace behavior:

- Roman numeral workspace format
- underline style
- scroll switching enabled
- application icons shown and grouped

### Current dock setup

The dock is enabled and centered at the bottom with background and border enabled. The pinned apps from [`dock_config.json`](./config/quickshell/dock_config.json) are:

- Brave
- Dolphin
- antigravity
- Telegram
- Lutris
- Virt Manager
- Discord
- IriunWebcam
- VS Code / Codex
- OBS Studio

The dock also exposes extra modules for:

- Weather
- Power
- Media
- Tray

### Theme and behavior

From [`theme_config.json`](./config/quickshell/theme_config.json), the shell currently uses:

- Material You color generation enabled
- light mode
- `scheme-tokyo-night` matugen preset
- live wallpaper-based theme updates
- Kitty theme syncing enabled

From [`notification_config.json`](./config/quickshell/notification_config.json), notifications currently use:

- 7 second display duration
- top-center popup position
- compact mode disabled
- do not disturb disabled
- popup shadow enabled
- 5 minute history retention

### Quickshell internals in this repo

This Quickshell setup is more than a simple bar theme. It includes custom modules and services such as:

- dynamic bar loading and screen-aware placement
- notification history and toast handling
- clipboard integration
- audio controls and equalizer support
- system info widgets
- wallpaper-aware theming
- monitor bootstrap via `scripts/apply_monitors.sh`

It also installs:

- `~/.zshrc`
- `~/Pictures/wallpapers`
- `brave-flags.conf`
- `dolphinrc`
- `kdeglobals`
- `user-dirs.dirs`
- `user-dirs.locale`

## Packages Installed

### Official Arch packages

The script installs a full desktop and utility stack, including:

- Hyprland components: `hyprland`, `hypridle`, `hyprlock`, `hyprpolkitagent`, `hyprshot`, `xdg-desktop-portal-hyprland`
- shell and desktop tools: `kitty`, `rofi`, `quickshell`, `swww`, `wl-clipboard`, `fastfetch` config support, `qt5ct`, `qt5-wayland`
- file and media apps: `dolphin`, `ark`, `gwenview`, `mpv`, `ffmpegthumbs`, `kwrite`, `unzip`, `unarchiver`
- audio and desktop integration: `pipewire-pulse`, `pipewire-jack`, `wireplumber`, `playerctl`, `pavucontrol`, `network-manager-applet`
- virtualization tools: `qemu-full`, `virt-manager`, `virt-viewer`, `libvirt`, `libguestfs`, `dnsmasq`, `vde2`, `openbsd-netcat`, `nftables`
- extra desktop apps: `discord`, `telegram-desktop`, `obs-studio`, `keepassxc`, `rclone`
- fonts and theme support: `ttf-roboto`, `kvantum`
- build and kernel-related tools: `base-devel`, `bc`, `bison`, `cpio`, `flex`, `git`, `github-cli`, `kmod`, `libelf`, `linux-headers`, `pahole`, `perl`, `tar`, `xmlto`, `xz`, `zstd`

### AUR packages

The script also installs:

- `antigravity`
- `brave-bin`
- `cargo`
- `catppuccin-cursors-mocha`
- `catppuccin-gtk-theme-latte`
- `codex-desktop-bin`
- `fastfetch`
- `goverlay`
- `lact`
- `libxcrypt-compat`
- `mangohud`
- `matugen-bin`
- `noto-fonts`
- `nwg-look`
- `qt6ct-kde`
- `ttf-hack`
- `ttf-jetbrains-mono-nerd`
- `waypaper`
- `zsh`
- `zsh-autosuggestions`
- `zsh-syntax-highlighting`
- `iriunwebcam-bin`

### Additional setup steps

The installer also:

- installs `opencl-amd` from a pinned AUR commit
- runs `cargo install matugen`
- installs `oh-my-zsh`
- installs these Zsh plugins:
  - `zsh-autosuggestions`
  - `zsh-syntax-highlighting`
  - `fast-syntax-highlighting`
  - `zsh-autocomplete`
- optionally runs `gh auth login` if GitHub CLI is installed and the script is running in an interactive terminal

## Installation

Run the installer directly:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/ekremx25/Hyprland/main/install.sh)
```

Or clone the repository and run it locally:

```bash
git clone https://github.com/ekremx25/Hyprland.git
cd Hyprland
./install.sh
```

## Backups

If a target file or directory already exists, the installer renames it to:

```bash
name.bak.YYYYMMDD-HHMMSS
```

This makes it easier to restore your previous setup if needed.

## Important Notes

- This script is intended for `Arch Linux` only.
- It requires `sudo`.
- It makes system-level changes, including GRUB and `libvirt` configuration.
- It enables `sddm.service`.
- It is opinionated and may install more software than a minimal setup needs.
- After installation, log out and select the Hyprland session.

## Disclaimer

This is my personal setup shared publicly. Feel free to use it as a base, but you should review `install.sh` before running it on your own system.
