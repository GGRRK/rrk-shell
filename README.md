# rrk-shell

A desktop shell for [Hyprland](https://hypr.land) on **RRK** (Razer Blade 17, Arch Linux), built with
[Quickshell](https://quickshell.org). The look is inspired by ilyamiro's "Linux superiority" desktop —
but every line here was written from scratch for this machine; no third-party shell code runs.

Everything the desktop does lives in this one repo and is plain, readable text:

| Folder | What it is |
|---|---|
| `shell/` | Quickshell QML — top bar, dashboard, notification center, launcher, wallpaper picker, media / Bluetooth / Wi-Fi / power panels, on-screen display |
| `hypr/` | Hyprland config in Lua (look, blur, animations, keybinds, window rules, idle + lock) |
| `matugen/` | colour-scheme generation from the wallpaper (templates for the shell, Hyprland, kitty, hyprlock) |
| `kitty/` | terminal config + generated theme |
| `bin/rrkshell` | control script: start / stop / restart / toggle panels / change wallpaper |
| `assets/wallpapers/` | 8 NASA public-domain wallpapers to start with |
| `install.sh` | installs packages (official Arch repos only) and links the configs into `~/.config` |

## Install

```
git clone https://github.com/GGRRK/rrk-shell ~/claude/rrk-shell
bash ~/claude/rrk-shell/install.sh
```

Then log out (`SUPER+M`) and back in — the shell starts with Hyprland. The installer backs up whatever
was in `~/.config/hypr` and `~/.config/kitty` to `*.bak-<date>` and replaces them with symlinks into this repo,
so editing a file here changes the live desktop (Quickshell hot-reloads QML on save).

## Keyboard shortcuts

`SUPER` is the Windows key. **`SUPER + K` shows this list on screen** (with a search box) — it is generated live
from `hypr/config/keybinds.lua`, so the sheet is always right even if this README lags behind.

### Shell panels
| Key | Action |
|---|---|
| `SUPER + K` | Keyboard cheat sheet — every shortcut below, type to search |
| `SUPER + Space` (or `SUPER + R`) | App launcher — type to filter, `Enter` launches, `↑ ↓` move. Opens on **Apps** (programs you installed: explicit `pacman` packages, Flatpaks, your own `.desktop` files); the **All** button or `Tab` shows every menu entry, dependencies' helper tools included. Start with `>` to run a shell command (`>kitty -e htop`) |
| `SUPER + D` | Dashboard — clock, calendar, weather, quick tiles (Wi-Fi, Bluetooth, DND, wallpapers, power mode, lock, shortcuts, clipboard, media) |
| `SUPER + N` | Notification centre (do-not-disturb, clear all, quick actions) |
| `SUPER + W` | Wallpaper picker (carousel, colour filter, shuffle, auto-rotate) |
| `SUPER + Shift + W` | Random wallpaper right now (colours re-theme everywhere) |
| `SUPER + B` | Bluetooth panel — radial view: the connected device in the centre with Scan / Battery / Audio profile / Disconnect / MAC chips around it; the Scan chip shows nearby devices to pair or connect; top-right button switches to a plain list |
| `SUPER + X` | Power menu (lock, log out, screen off, reboot, shut down). "Screen off" locks and darkens the backlight — a brightness key brings it back. There is deliberately no sleep/suspend: on this laptop's nouveau driver the GPU does not wake up from it |
| `SUPER + V` | Clipboard history — type to filter, `Enter` copies the highlighted entry, `↑ ↓` move, `✕` on a row deletes it, `Shift + Delete` deletes the highlighted one, bin button clears all (asks first) |
| `SUPER + Shift + D` | Hide / show the desktop widgets (clock, visualizer, system monitor, weather) |
| `Esc` / click outside | Close any open panel |

### Screenshots
| Key | Action |
|---|---|
| `Print` | Whole screen → `~/Pictures/Screenshots/<date>.png` |
| `Shift + Print` | Select a region → clipboard |

### Apps
| Key | Action |
|---|---|
| `SUPER + Q` | Terminal (kitty) |
| `SUPER + E` | File manager (Dolphin) |
| `SUPER + F` | Browser (Zen) |
| `SUPER + C` or `Alt + F4` | Close window |

### Session
| Key | Action |
|---|---|
| `SUPER + L` | Lock screen (hyprlock) |
| `SUPER + M` | Log out (`uwsm stop`) |

### Windows
| Key | Action |
|---|---|
| `SUPER + ← → ↑ ↓` | Move focus between windows |
| `Alt + Tab` | Next window |
| `SUPER + T` | Toggle floating |
| `SUPER + Enter` | Fullscreen (keeps the bar) |
| `SUPER + P` | Pseudo-tile |
| `SUPER + J` | Toggle split direction |
| `SUPER + left-drag` | Drag a window |
| `SUPER + right-drag` | Resize a window |

### Workspaces
| Key | Action |
|---|---|
| `SUPER + 1 … 8` | Go to workspace 1–8 |
| `SUPER + Shift + 1 … 8` | Move the focused window to that workspace |
| `SUPER + scroll` | Next / previous workspace |
| `SUPER + S` | Toggle the scratchpad ("magic" special workspace) |
| `SUPER + Shift + S` | Send the focused window to the scratchpad |
| 3-finger swipe | Switch workspace (touchpad) |

### Media & hardware keys
Volume, mute, mic-mute and brightness keys show the on-screen display; the `Fn` media keys (play/pause, next,
previous) control whatever is playing (MPRIS via playerctl). All of them also work on the lock screen.

### Editing the shortcuts
Everything above lives in `hypr/config/keybinds.lua` (Hyprland's Lua config). Hyprland reloads it on save, and the
`SUPER + K` sheet is parsed from the same file: a comment line holding a short title (`-- Apps`) starts a section,
the `-- comment` at the end of a bind line is the text shown next to the keys, binds with the same text share a row,
and `for i = 1, 8 do … end` loops are listed once as `1–8`. Commented-out binds and long prose comments are ignored.

## The bar

Left to right:

| Module | Click | Other |
|---|---|---|
| 🔍 search button | app launcher | |
| workspaces `1 … 8` | jump to that workspace | scroll to switch |
| now-playing (appears when something plays) | media panel | play/pause + skip buttons inline |
| clock + date | dashboard | |
| weather | dashboard | temperature + condition from open-meteo (no API key) |
| system tray | app-specific | middle-click = secondary action, right-click = menu |
| keyboard layout (`EN`) | switch layout | |
| Wi-Fi | network panel (scan, connect, toggle) | |
| Bluetooth | Bluetooth panel (radial device view) | |
| volume | media panel (volume + mic sliders, output device, seek) | right-click mute · scroll changes volume |
| notifications bell | notification center | badge shows unread count |
| battery | | percentage, charging icon |
| ⏻ | power menu | |

## `rrkshell` command

`install.sh` links `bin/rrkshell` into `~/.local/bin`, so you can type these in any terminal:

```
rrkshell start              start the wallpaper daemon + shell (Hyprland does this at login)
rrkshell stop               stop the shell
rrkshell restart            restart it (use after big QML edits; small edits hot-reload)
rrkshell toggle <panel>     dashboard | notifications | launcher | wallpapers | media | bluetooth | network | power | clipboard | hotkeys
rrkshell wallpaper <image>  set a wallpaper and regenerate the colour scheme everywhere
rrkshell wallpaper random   pick a random one from your wallpaper folder
rrkshell log                follow the shell log (~/.local/state/rrk-shell/shell.log)
rrkshell widgets            hide / show the desktop widgets
rrkshell avatar [photo]     rebuild the lock-screen avatar (with a photo: it is copied to ~/.face first)
```

The panels can also be driven directly over Quickshell IPC (this is what the keybinds do):

```
qs -c rrk-shell ipc call panels toggle dashboard
qs -c rrk-shell ipc call osd volume up|down|mute
qs -c rrk-shell ipc call osd brightness up|down
```

## Settings

`~/.config/rrk-shell/settings.json` (created by the installer):

```json
{
  "wallpaperDir": "~/Pictures/Wallpapers",
  "weather": { "lat": 52.52, "lon": 13.40, "city": "Berlin" },
  "widgets": { "clock": true, "cava": true, "sysmon": true, "weather": true },
  "launcher": { "hide": ["qt6ct", "uuctl"], "show": [] },
  "brightness": { "mode": "backlight" }
}
```

- `wallpaperDir` — where the wallpaper picker looks (subfolders one level deep are included).
- `weather` — leave `{}` to locate automatically by IP, or set a fixed place.
- `widgets` — switch single desktop widgets off (all on by default; the key may be left out entirely). `SUPER + Shift + D` hides / shows them all.
- `brightness` — `"backlight"` (default, `brightnessctl`) or `"overlay"`: software dimming with a translucent black layer over the screen, for machines where the backlight cannot be driven (this laptop: nouveau + dGPU-only mode — the panel ignores the EC backlight and there is no gamma either). Darkens the picture only (the mouse cursor stays bright), no power saving; the level is remembered in `~/.local/state/rrk-shell/brightness`.
- `launcher` — corrections for the launcher's **Apps** view: `hide` = desktop-entry ids (file name without `.desktop`) to keep out of it even though you installed the package yourself, `show` = ids to force in. `shell/scripts/user-apps.sh` prints the ids the view is built from. Picked up live.

The media panel's equalizer keeps its own state in `~/.config/rrk-shell/eq.json` (10 band gains in dB, preset, the Saved slot, on/off, expanded). The EQ runs on easyeffects (started at login as `easyeffects --hide-window --service-mode`; needs `lsp-plugins-lv2` for the actual filter); the shell talks to it over its local socket and loads the generated preset `~/.local/share/easyeffects/output/rrk-eq.json` to put a 10-band equalizer into the output pipeline.

## Theming

Pick a wallpaper (`SUPER+W`) and `matugen` derives a Material-You palette from it. The templates in
`matugen/templates/` are rendered to:

| Template | Written to | Used by |
|---|---|---|
| `colors.json` | `~/.config/rrk-shell/colors.json` | every shell colour (`shell/services/Theme.qml` watches the file) |
| `colors.lua` | `hypr/config/colors.lua` | Hyprland window borders |
| `kitty-colors.conf` | `kitty/colors.conf` | terminal colours (running kitty windows update live) |
| `hyprlock.conf` | `hypr/hyprlock.conf` | lock screen |
| `gtk.css` | `~/.config/gtk-3.0/gtk.css`, `gtk-4.0/gtk.css` | GTK / libadwaita apps (accent + surfaces) |
| `qt6ct-colors.conf` | `qt6ct/colors/rrk-dark.conf` | plain Qt apps (via qt6ct) |
| `kdeglobals` | `~/.config/kdeglobals`, `~/.local/share/color-schemes/RRKDark.colors` | KDE apps (Dolphin) |

The generated files are git-ignored; the palette is always rebuilt from the current wallpaper.
Dark mode for everything else: `install.sh` sets `color-scheme = prefer-dark` in gsettings (served to apps — including
Flatpaks like Zen — by `xdg-desktop-portal-gtk`), links `gtk/` and `qt6ct/` into `~/.config`, and gives Flatpak apps
read access to the GTK config. Running apps pick the change up live (GTK/Firefox) or on next launch (Qt/KDE).
Fonts: JetBrainsMono Nerd Font for text, Material Symbols Rounded for icons.

Lock screen (`SUPER+L`, or after 10 min idle): blurred wallpaper, clock, your avatar (`~/.face` if it exists — any size, it is
centre-cropped — otherwise a monogram in the palette colours), the password pill, and keyboard-layout / battery / weather
pills; the moon button bottom-right turns the backlight off (brightness keys bring it back; suspend/DPMS-off on nouveau hang the GPU). Template `matugen/templates/hyprlock.conf`, helpers `shell/scripts/lock-status.sh`
and `lock-avatar.sh`; re-rendered on every wallpaper change. Deliberate differences from the reference: the clock stays visible
above the avatar row (hyprlock cannot swap views), the prompt says ENTER PASSWORD, and the button turns the screen off instead of
powering off (change `bedtime` + `screen-off.sh` to `power_settings_new` + `systemctl poweroff` in the template if you want that).

## Hyprland config layout

`hypr/hyprland.lua` just requires the files in `hypr/config/`:

| File | Contents |
|---|---|
| `variables.lua` | `mainMod`, terminal, file manager, browser, paths |
| `env.lua` | environment (Wayland for Qt/GTK/Firefox, cursor size) |
| `monitors.lua` | eDP-1 at 2× scale, any external monitor auto |
| `look.lua` | gaps, rounding, blur, shadows, animation curves, layer-blur for the shell |
| `input.lua` | keyboard layout, touchpad, gestures |
| `rules.lua` | window rules (float pavucontrol and file dialogs, …) |
| `autostart.lua` | shell, clipboard watcher, hypridle |
| `keybinds.lua` | everything in the tables above |
| `hypridle.conf` | dim after 5 min, lock after 10, screen off after 15, lock before sleep |

Check a change without restarting: `Hyprland --verify-config -c ~/claude/rrk-shell/hypr/hyprland.lua`, then `hyprctl reload`.

## Roll back

A snapshot of the previous `~/.config` and package list was taken before the first install:

```
bash ~/claude/backups/2026-09-13-before-rrk-shell/RESTORE.sh
```

## Notes / gotchas (Hyprland 0.56, Lua config)

- IPC dispatches use Lua syntax: `hyprctl dispatch 'hl.dsp.focus({ workspace = 2 })'`.
- Keyboard layout switching is `hyprctl switchxkblayout all next`, not a dispatcher.
- `misc.vfr` and `dwindle.pseudotile` no longer exist.
- `seatd.service` must stay **disabled** on this machine (it fights `logind` and leaves a black screen on logout).
- Logging out is `uwsm stop`, not the raw `exit` dispatcher.

## Desktop widgets

A column of glass cards on the right of the wallpaper (beneath windows, click-through, never focused): analog + digital clock,
a [cava](https://github.com/karlstav/cava) audio visualizer (cava only runs while something is playing and the desktop is
actually visible), a system monitor (CPU, RAM, CPU temperature, disk, network) and the current weather. `SUPER + Shift + D`
or `rrkshell widgets` hides / shows them (remembered across restarts in `~/.local/state/rrk-shell/widgets-hidden`); single
widgets are switched off in `settings.json` (`"widgets": {"cava": false}`, picked up live). Code: `shell/desktop/`, services
`Widgets`, `SysMon`, `Cava`, helper scripts `shell/scripts/sysmon.sh` and `shell/scripts/cava.conf`.
