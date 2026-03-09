# Hyprland Dotfiles Installer

Arch Linux icin tek komutla paketleri, `yay`, AUR temalarini, fontlari, icon temasini ve config dosyalarini kurar. `quickshell` ayari repo icinden degil, dogrudan GitHub'daki `ekremx25/quickshell` reposundan cekilir.

## Kurulum

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/ekremx25/Hyprland/main/install.sh)
```

Alternatif:

```bash
git clone https://github.com/ekremx25/Hyprland.git
cd Hyprland
./install.sh
```

## Ne Yapar

- Gerekli Arch paketlerini `pacman` ile kurar.
- `archlinux-xdg-menu` paketini de kurar.
- `git` ve `base-devel` kurar.
- `discord`, `telegram-desktop`, `kwrite`, `obs-studio`, `keepassxc`, `dolphin`, `ark`, `unzip`, `unarchiver`, `feh`, `gwenview`, `mpv`, `sddm`, `qemu-full`, `virt-manager`, `virt-viewer`, `libvirt`, `dnsmasq`, `vde2`, `openbsd-netcat`, `ebtables`, `nftables`, `libguestfs` ve `gvfs-gphoto2` gibi repo paketlerini kurar.
- `yay` kurulu degilse AUR'dan derleyip kurar.
- `catppuccin-gtk-theme-latte`, `catppuccin-cursors-mocha`, `nwg-look`, `qt6ct-kde`, `codex-desktop-bin`, `antigravity`, `libxcrypt-compat`, `brave-bin`, `iriunwebcam-bin`, `cargo` ve `matugen-bin` paketlerini `yay` ile kurar.
- `zsh`, `zsh-autosuggestions` ve `zsh-syntax-highlighting` paketlerini `yay` ile kurar.
- `opencl-amd` paketini AUR reposundan cekip `42c9eb7` commit'ine sabitleyerek derler ve kurar.
- `oh-my-zsh` kurar.
- `zsh-autosuggestions`, `zsh-syntax-highlighting`, `fast-syntax-highlighting` ve `zsh-autocomplete` pluginlerini `git clone` ile kurar veya gunceller.
- `cargo install matugen` calistirir.
- Gerekli aktif fontlari `yay` ile kurar: `ttf-jetbrains-mono-nerd`, `ttf-hack`, `noto-fonts`.
- Repo icindeki bundled sistem fontlarini `/usr/share/fonts` altina kopyalar ve `sudo fc-cache` calistirir.
- `assets/icons/Ars-Light-Icons` temasini `~/.local/share/icons` altina kurar ve rofi/Qt tarafinda bunu kullanir.
- `config/` altindaki senin masaustu ayarlarini `~/.config` altina kopyalar.
- `~/.config/quickshell` klasorunu `https://github.com/ekremx25/quickshell` reposundan clone eder.
- `home/.zshrc` dosyasini dogrudan `~/.zshrc` olarak kurar.
- `Pictures/wallpapers` klasorunu dogrudan `~/Pictures/wallpapers` olarak kurar.
- `sudo update-desktop-database` calistirir ve varsa `/etc/xdg/menus/arch-applications.menu` dosyasini `applications.menu` olarak yeniden adlandirir.
- `/etc/libvirt/libvirtd.conf` icinde `unix_sock_group` ve `unix_sock_rw_perms` ayarlarini yapar, kullaniciyi `libvirt` grubuna ekler ve `libvirtd` servisini aktif eder.
- `sddm.service` bir sonraki acilista giris ekraninin gelmesi icin aktif edilir.
- Eski config varsa zaman damgali `.bak.YYYYMMDD-HHMMSS` yedegi olusturur.

## Dahil Olanlar

- `hypr`
- `rofi`
- `kitty`
- `quickshell`
- `qt6ct`
- `Kvantum`
- `waypaper`
- `gtk-3.0`
- `gtk-4.0`
- `xsettingsd`
- `nwg-look`
- `fastfetch`
- `dolphinrc`
- `brave-flags.conf`
- `kdeglobals`
- `user-dirs.*`
- `Pictures/wallpapers`
- `kernel/config-7.0.0-rc3-Eko`

## Notlar

- Script su an `Arch Linux` icin yazildi.
- `install.sh` `sudo` ister; `pacman` ve `yay` kurulumu sirasinda parola sorar.
- Aktif configte gereken fontlar paket yoneticisi ile kurulur; bundled font kopyalama yoktur.
- Kurulumdan sonra oturumu kapatip yeniden Hyprland oturumu acman gerekir.
