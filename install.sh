#!/usr/bin/env bash
# rrk-shell installer — installs packages from the official Arch repos and links this repo's configs into ~/.config.
# Safe to re-run. Nothing is downloaded from anywhere except Arch's own package mirrors.
set -euo pipefail
REPO="$(cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" && pwd)"
CFG="$HOME/.config"
STAMP="$(date +%Y%m%d-%H%M%S)"

say() { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }

say "Installing packages (official repos) — sudo will ask for your password"
sudo pacman -S --needed --noconfirm \
    hyprland quickshell matugen awww kitty \
    ttf-jetbrains-mono-nerd ttf-material-symbols-variable \
    hyprlock hypridle brightnessctl wl-clipboard cliphist jq \
    bluez bluez-utils networkmanager power-profiles-daemon upower \
    easyeffects lsp-plugins-lv2 \
    pipewire wireplumber pipewire-pulse playerctl pavucontrol \
    grim slurp libnotify imagemagick xdg-user-dirs qt6-imageformats qt6-5compat qt6ct wofi cava

say "Enabling services (bluetooth, power profiles)"
sudo systemctl enable --now bluetooth.service power-profiles-daemon.service >/dev/null 2>&1 || true

# link_dir <repo-subdir> <~/.config/name>  — backs up whatever was there, then symlinks the repo dir
link_dir() {
    local src="$REPO/$1" dst="$CFG/$2"
    if [ -L "$dst" ] && [ "$(readlink -f "$dst")" = "$src" ]; then return; fi
    if [ -e "$dst" ]; then mv "$dst" "$dst.bak-$STAMP"; echo "  backed up $dst -> $dst.bak-$STAMP"; fi
    ln -s "$src" "$dst"; echo "  linked $dst -> $src"
}

say "Linking configs into ~/.config"
mkdir -p "$CFG/quickshell" "$CFG/rrk-shell" "$HOME/.local/bin" "$HOME/.local/state/rrk-shell" "$HOME/.local/share/color-schemes"
link_dir shell  quickshell/rrk-shell
link_dir hypr   hypr
link_dir kitty  kitty
link_dir gtk/gtk-3.0 gtk-3.0
link_dir gtk/gtk-4.0 gtk-4.0
link_dir qt6ct  qt6ct
ln -sf "$REPO/bin/rrkshell" "$HOME/.local/bin/rrkshell"
# kitty's colors.conf and hypr's config/colors.lua are generated inside the repo dirs by matugen (gitignored)

say "Dark mode for every toolkit (GTK via the desktop portal, Qt via qt6ct, Flatpak apps read the GTK config)"
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'
gsettings set org.gnome.desktop.interface icon-theme 'Adwaita'
gsettings set org.gnome.desktop.interface cursor-theme 'Adwaita'
if command -v flatpak >/dev/null; then
    flatpak override --user --filesystem=xdg-config/gtk-3.0:ro --filesystem=xdg-config/gtk-4.0:ro
fi

say "Settings"
if [ ! -f "$CFG/rrk-shell/settings.json" ]; then
    cat > "$CFG/rrk-shell/settings.json" <<JSON
{
  "wallpaperDir": "~/Pictures/Wallpapers",
  "weather": {},
  "launcher": { "hide": [], "show": [] }
}
JSON
    echo "  wrote $CFG/rrk-shell/settings.json (edit to set a fixed weather location: {\"lat\":..,\"lon\":..,\"city\":\"..\"})"
fi

say "Wallpapers"
xdg-user-dirs-update >/dev/null 2>&1 || true
WALLS="$HOME/Pictures/Wallpapers"; mkdir -p "$WALLS"
if [ -z "$(ls -A "$WALLS" 2>/dev/null)" ]; then
    cp "$REPO/assets/wallpapers/"*.{jpg,png} "$WALLS/" 2>/dev/null || true
fi
if [ -z "$(ls -A "$WALLS" 2>/dev/null)" ]; then
    echo "  (no wallpapers yet — drop images into $WALLS, then SUPER+W)"
fi

say "First colour scheme"
first="$(find "$WALLS" -maxdepth 2 -type f \( -iname '*.jpg' -o -iname '*.png' -o -iname '*.webp' \) | head -n1 || true)"
STATEWP="$HOME/.local/state/rrk-shell/wallpaper"
if [ -f "$STATEWP" ] && [ -f "$(cat "$STATEWP")" ]; then first="$(cat "$STATEWP")"; fi   # keep the user's current pick
if [ -n "$first" ]; then
    printf '%s' "$first" > "$STATEWP"
    matugen image "$first" -c "$REPO/matugen/config.toml" -m dark --prefer saturation >/dev/null && echo "  palette generated from $(basename "$first")"
fi
"$REPO/shell/scripts/lock-avatar.sh" && echo "  lock-screen avatar -> $CFG/rrk-shell/avatar.png (put a photo at ~/.face and run 'rrkshell avatar' to use your own)" || true

say "Done"
cat <<TXT
  Log out (SUPER+M) and back in — the shell starts with Hyprland.
  Or, to try it in the current session right now:   rrkshell start
  Keys: SUPER+Space launcher · SUPER+D dashboard · SUPER+N notifications · SUPER+W wallpapers · SUPER+X power
  Roll back: bash ~/claude/backups/2026-09-13-before-rrk-shell/RESTORE.sh
TXT
