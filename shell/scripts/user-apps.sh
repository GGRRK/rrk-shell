#!/usr/bin/env bash
# Prints (as a JSON array) the desktop-entry ids of the applications the user installed on purpose — the launcher's
# default "Apps" view. Everything else in the menu came along as a dependency of something (Avahi browsers, V4L test
# tools, …) and is only shown under "All".
#   · pacman packages installed explicitly (`pacman -Qe`), not as dependencies: every .desktop file they ship
#   · every Flatpak app (system + user installs)
#   · the user's own ~/.local/share/applications/*.desktop
# The id is the file name without ".desktop" (what Quickshell's DesktopEntries uses), e.g. "org.kde.dolphin".
set -u
{
    pacman -Qql $(pacman -Qqe) 2>/dev/null | grep -E '^/usr(/local)?/share/applications/[^/]+\.desktop$'
    ls /var/lib/flatpak/exports/share/applications/*.desktop \
       "${XDG_DATA_HOME:-$HOME/.local/share}"/flatpak/exports/share/applications/*.desktop \
       "${XDG_DATA_HOME:-$HOME/.local/share}"/applications/*.desktop 2>/dev/null
} | sed 's|.*/||; s|\.desktop$||' | sort -u | jq -R -s 'split("\n") | map(select(length > 0))'
