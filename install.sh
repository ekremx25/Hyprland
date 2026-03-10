#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$SCRIPT_DIR"
CONFIG_DIR="$HOME/.config"
LOCAL_SHARE_DIR="$HOME/.local/share"
ICON_DIR="$LOCAL_SHARE_DIR/icons"
WALLPAPER_DIR="$HOME/Pictures/wallpapers"
BUILD_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles-setup"
DOTFILES_REPO_URL="https://github.com/ekremx25/Hyprland.git"
QUICKSHELL_REPO_URL="https://github.com/ekremx25/quickshell.git"
OH_MY_ZSH_INSTALL_URL="https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"
GRUB_KERNEL_PARAMS=(amdgpu.ppfeaturemask=0xffffffff amd_pstate=passive)
ZAPRET_CONFIG_SOURCE_REL="assets/zapret/config"

PACMAN_PACKAGES=(
  archlinux-xdg-menu
  ark
  base-devel
  cpupower
  discord
  dolphin
  dnsmasq
  feh
  git
  gwenview
  gvfs-gphoto2
  hyprland
  hypridle
  hyprlock
  hyprpolkitagent
  hyprshot
  keepassxc
  kitty
  kvantum
  linux-headers
  kwrite
  libpulse
  libvirt
  libguestfs
  network-manager-applet
  nftables
  obs-studio
  mpv
  openbsd-netcat
  pavucontrol
  playerctl
  pipewire-pulse
  pipewire-jack
  quickshell
  qt5-wayland
  qt5ct
  qemu-full
  qt6-multimedia-ffmpeg
  rclone
  rofi
  sddm
  swww
  telegram-desktop
  ttf-roboto
  unarchiver
  unzip
  vde2
  virt-manager
  virt-viewer
  wl-clipboard
  wireplumber
  xdg-desktop-portal-hyprland
)

YAY_PACKAGES=(
  antigravity
  brave-bin
  cargo
  catppuccin-cursors-mocha
  catppuccin-gtk-theme-latte
  codex-desktop-bin
  libxcrypt-compat
  matugen-bin
  noto-fonts
  nwg-look
  qt6ct-kde
  ttf-hack
  ttf-jetbrains-mono-nerd
  waypaper
  zsh
  zsh-autosuggestions
  zsh-syntax-highlighting
)

OPENCL_AMD_REPO_URL="https://aur.archlinux.org/opencl-amd.git"
OPENCL_AMD_COMMIT="42c9eb7"

CONFIG_TARGETS=(
  fastfetch
  gtk-3.0
  gtk-4.0
  hypr
  rofi
  kitty
  nwg-look
  qt6ct
  Kvantum
  waypaper
  xsettingsd
)

CONFIG_FILES=(
  brave-flags.conf
  dolphinrc
  kdeglobals
  user-dirs.dirs
  user-dirs.locale
)

HOME_FILES=(
  .zshrc
)

log() {
  printf '[dotfiles] %s\n' "$1"
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1
}

ensure_repo_files() {
  if [[ -d "$REPO_DIR/assets" && -d "$REPO_DIR/config" && -d "$REPO_DIR/home" ]]; then
    return
  fi

  log "Fetching dotfiles repository contents"
  mkdir -p "$BUILD_DIR"
  rm -rf "$BUILD_DIR/repo"
  git clone --depth 1 "$DOTFILES_REPO_URL" "$BUILD_DIR/repo"
  REPO_DIR="$BUILD_DIR/repo"
}

install_packages() {
  if ! need_cmd pacman; then
    log "This installer currently supports Arch Linux only."
    exit 1
  fi

  log "Installing required packages with pacman"
  sudo pacman -Syu --needed --noconfirm "${PACMAN_PACKAGES[@]}"
}

install_yay() {
  if need_cmd yay; then
    log "yay is already installed"
    return
  fi

  log "Installing yay"
  mkdir -p "$BUILD_DIR"
  rm -rf "$BUILD_DIR/yay"
  git clone https://aur.archlinux.org/yay.git "$BUILD_DIR/yay"
  (
    cd "$BUILD_DIR/yay"
    makepkg -si --noconfirm
  )
}

install_yay_packages() {
  log "Installing required packages with yay"
  yay -S --needed --noconfirm "${YAY_PACKAGES[@]}"
}

install_iriunwebcam() {
  log "Installing iriunwebcam-bin with yay"
  yay -S --needed --noconfirm iriunwebcam-bin
}

install_zapret() {
  local zapret_config_source="$REPO_DIR/$ZAPRET_CONFIG_SOURCE_REL"

  log "Installing zapret with yay"
  yay -S --needed --noconfirm zapret

  if [[ ! -f "$zapret_config_source" ]]; then
    log "Missing zapret config source: $zapret_config_source"
    exit 1
  fi

  log "Installing zapret config to /opt/zapret/config"
  sudo install -d /opt/zapret
  sudo install -m 644 "$zapret_config_source" /opt/zapret/config

  log "Enabling zapret service"
  sudo systemctl enable zapret.service >/dev/null 2>&1 || true
  sudo systemctl start zapret.service >/dev/null 2>&1 || true
}

install_opencl_amd() {
  if pacman -Q opencl-amd >/dev/null 2>&1; then
    log "opencl-amd is already installed"
    return
  fi

  log "Installing opencl-amd from pinned commit ${OPENCL_AMD_COMMIT}"
  mkdir -p "$BUILD_DIR"
  rm -rf "$BUILD_DIR/opencl-amd"
  git clone "$OPENCL_AMD_REPO_URL" "$BUILD_DIR/opencl-amd"
  (
    cd "$BUILD_DIR/opencl-amd"
    git checkout "$OPENCL_AMD_COMMIT"
    makepkg -si --noconfirm
  )
}

install_oh_my_zsh() {
  if [[ -d "$HOME/.oh-my-zsh" ]]; then
    log "oh-my-zsh is already installed"
    return
  fi

  log "Installing oh-my-zsh"
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL "$OH_MY_ZSH_INSTALL_URL")"
}

clone_or_update_plugin() {
  local repo_url="$1"
  local target_dir="$2"

  if [[ -d "$target_dir/.git" ]]; then
    log "Updating $(basename "$target_dir")"
    git -C "$target_dir" pull --ff-only
    return
  fi

  rm -rf "$target_dir"
  git clone --depth 1 "$repo_url" "$target_dir"
}

install_zsh_plugins() {
  local zsh_custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
  local plugin_dir="$zsh_custom/plugins"

  log "Installing zsh plugins"
  mkdir -p "$plugin_dir"
  clone_or_update_plugin "https://github.com/zsh-users/zsh-autosuggestions.git" "$plugin_dir/zsh-autosuggestions"
  clone_or_update_plugin "https://github.com/zsh-users/zsh-syntax-highlighting.git" "$plugin_dir/zsh-syntax-highlighting"
  clone_or_update_plugin "https://github.com/zdharma-continuum/fast-syntax-highlighting.git" "$plugin_dir/fast-syntax-highlighting"
  clone_or_update_plugin "https://github.com/marlonrichert/zsh-autocomplete.git" "$plugin_dir/zsh-autocomplete"
}

configure_grub_kernel_params() {
  local grub_default="/etc/default/grub"
  local current_line current_params param

  if [[ ! -f "$grub_default" ]]; then
    return
  fi

  log "Configuring GRUB kernel parameters"
  current_line="$(sudo grep '^GRUB_CMDLINE_LINUX_DEFAULT=' "$grub_default" || true)"
  current_params="${current_line#GRUB_CMDLINE_LINUX_DEFAULT=\"}"
  current_params="${current_params%\"}"

  for param in "${GRUB_KERNEL_PARAMS[@]}"; do
    if [[ " $current_params " != *" $param "* ]]; then
      current_params="${current_params:+$current_params }$param"
    fi
  done

  sudo sed -i "s|^GRUB_CMDLINE_LINUX_DEFAULT=.*|GRUB_CMDLINE_LINUX_DEFAULT=\"${current_params}\"|" "$grub_default"
  sudo grub-mkconfig -o /boot/grub/grub.cfg >/dev/null 2>&1 || true
}

install_cargo_tools() {
  if ! need_cmd cargo; then
    log "cargo is not available after package installation"
    exit 1
  fi

  log "Installing matugen with cargo"
  cargo install matugen || cargo install --force matugen
}

backup_path() {
  local path="$1"
  if [[ -e "$path" || -L "$path" ]]; then
    local backup="${path}.bak.$(date +%Y%m%d-%H%M%S)"
    log "Backing up $path to $backup"
    mv "$path" "$backup"
  fi
}

install_icons() {
  log "Installing bundled icon theme"
  mkdir -p "$ICON_DIR"
  backup_path "$ICON_DIR/Ars-Light-Icons"
  cp -a "$REPO_DIR/assets/icons/Ars-Light-Icons" "$ICON_DIR/"
  if need_cmd gtk-update-icon-cache; then
    gtk-update-icon-cache -f -t "$ICON_DIR/Ars-Light-Icons" >/dev/null 2>&1 || true
  fi
}

install_fonts() {
  if [[ ! -d "$REPO_DIR/assets/system-fonts" ]]; then
    return
  fi

  log "Installing bundled fonts"
  sudo mkdir -p /usr/share/fonts
  sudo cp -a "$REPO_DIR/assets/system-fonts/." /usr/share/fonts/
  need_cmd fc-cache && sudo fc-cache -f /usr/share/fonts >/dev/null 2>&1 || true
}

install_configs() {
  log "Installing config directories and files"
  mkdir -p "$CONFIG_DIR"
  for target in "${CONFIG_TARGETS[@]}"; do
    backup_path "$CONFIG_DIR/$target"
    cp -a "$REPO_DIR/config/$target" "$CONFIG_DIR/"
  done
  for target in "${CONFIG_FILES[@]}"; do
    backup_path "$CONFIG_DIR/$target"
    cp -a "$REPO_DIR/config/$target" "$CONFIG_DIR/"
  done
}

install_home_files() {
  log "Installing home dotfiles"
  for target in "${HOME_FILES[@]}"; do
    backup_path "$HOME/$target"
    cp -a "$REPO_DIR/home/$target" "$HOME/$target"
  done
}

install_wallpapers() {
  log "Installing wallpapers"
  mkdir -p "$HOME/Pictures"
  backup_path "$WALLPAPER_DIR"
  cp -a "$REPO_DIR/Pictures/wallpapers" "$HOME/Pictures/wallpapers"
}

install_quickshell_config() {
  log "Installing quickshell config from GitHub"
  mkdir -p "$BUILD_DIR"
  rm -rf "$BUILD_DIR/quickshell"
  git clone --depth 1 "$QUICKSHELL_REPO_URL" "$BUILD_DIR/quickshell"
  backup_path "$CONFIG_DIR/quickshell"
  cp -a "$BUILD_DIR/quickshell" "$CONFIG_DIR/quickshell"
  rm -rf "$CONFIG_DIR/quickshell/.git"
}

fix_xdg_menu() {
  if [[ ! -d /etc/xdg/menus ]]; then
    return
  fi

  log "Refreshing system desktop database"
  sudo update-desktop-database || true

  if [[ -e /etc/xdg/menus/arch-applications.menu ]]; then
    log "Renaming arch-applications.menu to applications.menu"
    sudo mv /etc/xdg/menus/arch-applications.menu /etc/xdg/menus/applications.menu
  fi
}

configure_libvirt() {
  if ! need_cmd virsh; then
    return
  fi

  log "Configuring libvirt"
  sudo install -d /etc/libvirt
  sudo touch /etc/libvirt/libvirtd.conf
  sudo sed -i 's|^#\\?unix_sock_group = .*|unix_sock_group = \"libvirt\"|' /etc/libvirt/libvirtd.conf
  sudo sed -i 's|^#\\?unix_sock_rw_perms = .*|unix_sock_rw_perms = \"0770\"|' /etc/libvirt/libvirtd.conf
  sudo usermod -a -G libvirt "$(id -un)"
  sudo systemctl enable --now libvirtd >/dev/null 2>&1 || true
}

post_install() {
  fix_xdg_menu
  configure_libvirt
  configure_grub_kernel_params
  log "Enabling display manager"
  sudo systemctl enable sddm.service >/dev/null 2>&1 || true
  log "Refreshing desktop caches"
  need_cmd update-desktop-database && update-desktop-database "$HOME/.local/share/applications" >/dev/null 2>&1 || true
  need_cmd xdg-user-dirs-update && xdg-user-dirs-update || true

  log "Install complete"
  printf '\n'
  printf 'Next step: log out and select the Hyprland session.\n'
}

main() {
  ensure_repo_files
  install_packages
  install_yay
  install_iriunwebcam
  install_zapret
  install_yay_packages
  install_opencl_amd
  install_cargo_tools
  install_oh_my_zsh
  install_zsh_plugins
  install_fonts
  install_icons
  install_configs
  install_home_files
  install_quickshell_config
  install_wallpapers
  post_install
}

main "$@"
