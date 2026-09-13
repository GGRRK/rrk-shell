-- apps
hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + F", hl.dsp.exec_cmd(browser))
hl.bind(mainMod .. " + C", hl.dsp.window.close())
hl.bind("ALT + F4",        hl.dsp.window.close())
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("uwsm stop"))      -- log out (session is managed by uwsm)
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("hyprlock"))

-- shell panels
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd(qs_ipc .. " panels toggle launcher"))
hl.bind(mainMod .. " + R",     hl.dsp.exec_cmd(qs_ipc .. " panels toggle launcher"))
hl.bind(mainMod .. " + D",     hl.dsp.exec_cmd(qs_ipc .. " panels toggle dashboard"))
hl.bind(mainMod .. " + N",     hl.dsp.exec_cmd(qs_ipc .. " panels toggle notifications"))
hl.bind(mainMod .. " + W",     hl.dsp.exec_cmd(qs_ipc .. " panels toggle wallpapers"))
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd(shell .. " wallpaper random"))
hl.bind(mainMod .. " + B",     hl.dsp.exec_cmd(qs_ipc .. " panels toggle bluetooth"))
hl.bind(mainMod .. " + X",     hl.dsp.exec_cmd(qs_ipc .. " panels toggle power"))
hl.bind(mainMod .. " + V",     hl.dsp.exec_cmd("cliphist list | wofi --dmenu | cliphist decode | wl-copy"))

-- screenshots (grim + slurp): region to clipboard, full screen to ~/Pictures/Screenshots
hl.bind("SHIFT + PRINT", hl.dsp.exec_cmd("grim -g \"$(slurp)\" - | wl-copy && notify-send -a Screenshot 'Region copied to clipboard'"))
hl.bind("PRINT",         hl.dsp.exec_cmd("mkdir -p ~/Pictures/Screenshots && grim ~/Pictures/Screenshots/$(date +%Y-%m-%d_%H-%M-%S).png && notify-send -a Screenshot 'Saved to ~/Pictures/Screenshots'"))

-- desktop widgets (clock, visualizer, system monitor, weather on the wallpaper)
hl.bind(mainMod .. " + SHIFT + D", hl.dsp.exec_cmd(qs_ipc .. " widgets toggle"))   -- hide / show them

-- windows
hl.bind(mainMod .. " + T", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + RETURN", hl.dsp.window.fullscreen({ mode = 1 }))
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))
hl.bind("ALT + TAB",           hl.dsp.window.cycle_next())

-- workspaces
for i = 1, 8 do
    hl.bind(mainMod .. " + " .. i,          hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. i,  hl.dsp.window.move({ workspace = i }))
end
hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- media / hardware keys go through the shell so the on-screen display shows
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd(qs_ipc .. " osd volume up"),       { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd(qs_ipc .. " osd volume down"),     { locked = true, repeating = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd(qs_ipc .. " osd volume mute"),     { locked = true })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd(qs_ipc .. " osd mic"),             { locked = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd(qs_ipc .. " osd brightness up"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(qs_ipc .. " osd brightness down"), { locked = true, repeating = true })
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })
