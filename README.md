# rrk-shell

A desktop shell for Hyprland on RRK (Razer Blade 17), built with [Quickshell](https://quickshell.org).
Look inspired by ilyamiro's "Linux superiority" desktop — written from scratch, no third-party shell code.

Everything the shell does is in this repo and readable:

- `shell/`     Quickshell QML — bar, dashboard, notification center, launcher, wallpaper picker, panels
- `matugen/`   colour-scheme generation from the wallpaper (templates for the shell, Hyprland, kitty)
- `hypr/`      Hyprland config (Lua) — look, animations, keybinds
- `kitty/`     terminal theme
- `bin/rrkshell`  control script: `rrkshell start|stop|restart|toggle <panel>|wallpaper <file>`
- `install.sh` installs packages (official Arch repos only) and links configs into `~/.config`

## Install
```
bash ~/claude/rrk-shell/install.sh
```
Then log out and back in (SUPER+M). The shell autostarts with Hyprland.

## Keys
| Key | Action |
|---|---|
| SUPER+Space | app launcher |
| SUPER+W | wallpaper picker |
| SUPER+D | dashboard (clock, calendar, weather) |
| SUPER+N | notification center |
| SUPER+Q | terminal |
| SUPER+E | file manager |
| SUPER+L | lock |
| SUPER+M | log out |
