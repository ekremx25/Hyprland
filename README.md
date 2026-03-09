# Hyprland Dotfiles Installer

Arch Linux icin tek komutla paketleri, `yay`, AUR temalarini, fontlari, icon temasini ve config dosyalarini kurar. `quickshell` ayari repo icinden degil, dogrudan GitHub'daki `ekremx25/quickshell` reposundan cekilir.

## Kurulum

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/<kullanici>/<repo>/main/install.sh)
```

Alternatif:

```bash
git clone https://github.com/<kullanici>/<repo>.git
cd <repo>
./install.sh
```

## Ne Yapar

- Gerekli Arch paketlerini `pacman` ile kurar.
- `git` ve `base-devel` kurar.
- `discord`, `telegram-desktop`, `kwrite`, `obs-studio` ve `keepassxc` gibi repo paketlerini kurar.
- `yay` kurulu degilse AUR'dan derleyip kurar.
- `catppuccin-gtk-theme-latte`, `catppuccin-cursors-mocha`, `nwg-look`, `qt6ct-kde`, `codex-desktop-bin`, `antigravity`, `libxcrypt-compat`, `brave-bin` ve `iriunwebcam-bin` paketlerini `yay` ile kurar.
- `zsh`, `zsh-autosuggestions` ve `zsh-syntax-highlighting` paketlerini `yay` ile kurar.
- `opencl-amd` paketini AUR reposundan cekip `42c9eb7` commit'ine sabitleyerek derler ve kurar.
- `oh-my-zsh` kurar.
- `zsh-autosuggestions`, `zsh-syntax-highlighting`, `fast-syntax-highlighting` ve `zsh-autocomplete` pluginlerini `git clone` ile kurar veya gunceller.
- Gerekli aktif fontlari `yay` ile kurar: `ttf-jetbrains-mono-nerd`, `ttf-hack`, `noto-fonts`.
- `assets/icons/Ars-Light-Icons` temasini `~/.local/share/icons` altina kurar ve rofi/Qt tarafinda bunu kullanir.
- `config/` altindaki senin masaustu ayarlarini `~/.config` altina kopyalar.
- `~/.config/quickshell` klasorunu `https://github.com/ekremx25/quickshell` reposundan clone eder.
- `home/.zshrc` dosyasini dogrudan `~/.zshrc` olarak kurar.
- Eski config varsa zaman damgali `.bak.YYYYMMDD-HHMMSS` yedegi olusturur.
- `~/Pictures/wallpapers/rain-house-tree.jpg` yoksa kilit ekrani gorselinden olusturur.

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

## Notlar

- Script su an `Arch Linux` icin yazildi.
- `install.sh` `sudo` ister; `pacman` ve `yay` kurulumu sirasinda parola sorar.
- Aktif configte gereken fontlar paket yoneticisi ile kurulur; bundled font kopyalama yoktur.
- Kurulumdan sonra oturumu kapatip yeniden Hyprland oturumu acman gerekir.
