--[[ Keybinds. `SUPER + K` opens a cheat sheet that is generated from THIS file (shell/services/Hotkeys.qml):
     · a comment line holding only a short title ("-- Apps") starts a new section
     · the `-- comment` at the end of an hl.bind(...) line is the description shown next to the keys;
       consecutive binds with the same description share one row ("Super + ← → ↑ ↓", "Super + C or Alt + F4")
     · `for i = a, b do … end` loops are listed once, with the key shown as "a–b"
     Comment lines that look like code or prose (a commented-out bind, "-----", anything over 40 characters) and
     block comments like this one are ignored. A bind whose key uses a variable the sheet cannot resolve is left out. ]]

-- Shell panels
hl.bind(mainMod .. " + K",         hl.dsp.exec_cmd(qs_ipc .. " panels toggle hotkeys"))        -- This cheat sheet
hl.bind(mainMod .. " + SPACE",     hl.dsp.exec_cmd(qs_ipc .. " panels toggle launcher"))       -- App launcher
hl.bind(mainMod .. " + R",         hl.dsp.exec_cmd(qs_ipc .. " panels toggle launcher"))       -- App launcher
hl.bind(mainMod .. " + D",         hl.dsp.exec_cmd(qs_ipc .. " panels toggle dashboard"))      -- Dashboard
hl.bind(mainMod .. " + N",         hl.dsp.exec_cmd(qs_ipc .. " panels toggle notifications"))  -- Notification centre
hl.bind(mainMod .. " + W",         hl.dsp.exec_cmd(qs_ipc .. " panels toggle wallpapers"))     -- Wallpaper picker
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd(shell .. " wallpaper random"))              -- Random wallpaper
hl.bind(mainMod .. " + B",         hl.dsp.exec_cmd(qs_ipc .. " panels toggle bluetooth"))      -- Bluetooth panel
hl.bind(mainMod .. " + X",         hl.dsp.exec_cmd(qs_ipc .. " panels toggle power"))          -- Power menu
hl.bind(mainMod .. " + V",         hl.dsp.exec_cmd(qs_ipc .. " panels toggle clipboard"))      -- Clipboard history
hl.bind(mainMod .. " + SHIFT + D", hl.dsp.exec_cmd(qs_ipc .. " widgets toggle"))               -- Hide / show desktop widgets

-- Screenshots
hl.bind("PRINT",         hl.dsp.exec_cmd("mkdir -p ~/Pictures/Screenshots && grim ~/Pictures/Screenshots/$(date +%Y-%m-%d_%H-%M-%S).png && notify-send -a Screenshot 'Saved to ~/Pictures/Screenshots'"))  -- Screen → ~/Pictures/Screenshots
hl.bind("SHIFT + PRINT", hl.dsp.exec_cmd("grim -g \"$(slurp)\" - | wl-copy && notify-send -a Screenshot 'Region copied to clipboard'"))  -- Region → clipboard

-- Apps
hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(terminal))        -- Terminal (kitty)
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))     -- File manager (Dolphin)
hl.bind(mainMod .. " + F", hl.dsp.exec_cmd(browser))         -- Browser (Zen)
hl.bind(mainMod .. " + C", hl.dsp.window.close())            -- Close window
hl.bind("ALT + F4",        hl.dsp.window.close())            -- Close window

-- Session
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("hyprlock"))      -- Lock screen
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("uwsm stop"))     -- Log out

-- Windows
hl.bind(mainMod .. " + left",   hl.dsp.focus({ direction = "left" }))     -- Move focus
hl.bind(mainMod .. " + right",  hl.dsp.focus({ direction = "right" }))    -- Move focus
hl.bind(mainMod .. " + up",     hl.dsp.focus({ direction = "up" }))       -- Move focus
hl.bind(mainMod .. " + down",   hl.dsp.focus({ direction = "down" }))     -- Move focus
hl.bind("ALT + TAB",            hl.dsp.window.cycle_next())               -- Next window
hl.bind(mainMod .. " + T",      hl.dsp.window.float({ action = "toggle" }))  -- Toggle floating
hl.bind(mainMod .. " + RETURN", hl.dsp.window.fullscreen({ mode = 1 }))   -- Fullscreen (keeps the bar)
hl.bind(mainMod .. " + P",      hl.dsp.window.pseudo())                   -- Pseudo-tile (window keeps its size)
hl.bind(mainMod .. " + J",      hl.dsp.layout("togglesplit"))             -- Toggle split direction
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })  -- Drag window
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })  -- Resize window

-- Workspaces
for i = 1, 8 do
    hl.bind(mainMod .. " + " .. i,          hl.dsp.focus({ workspace = i }))          -- Go to workspace
    hl.bind(mainMod .. " + SHIFT + " .. i,  hl.dsp.window.move({ workspace = i }))    -- Move window to workspace
end
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))            -- Next / previous workspace
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))            -- Next / previous workspace
hl.bind(mainMod .. " + S",          hl.dsp.workspace.toggle_special("magic"))       -- Show / hide the scratchpad
hl.bind(mainMod .. " + SHIFT + S",  hl.dsp.window.move({ workspace = "special:magic" }))  -- Send window to scratchpad

-- Media & hardware keys
--[[ these go through the shell so the on-screen display shows; `locked = true` = they also work on the lock screen ]]
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd(qs_ipc .. " osd volume up"),       { locked = true, repeating = true })  -- Volume
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd(qs_ipc .. " osd volume down"),     { locked = true, repeating = true })  -- Volume
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd(qs_ipc .. " osd volume mute"),     { locked = true })                    -- Mute
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd(qs_ipc .. " osd mic"),             { locked = true })                    -- Mute microphone
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd(qs_ipc .. " osd brightness up"),   { locked = true, repeating = true })  -- Screen brightness
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(qs_ipc .. " osd brightness down"), { locked = true, repeating = true })  -- Screen brightness
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })  -- Play / pause
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })  -- Play / pause
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })  -- Next track
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })  -- Previous track
