# Plan: nouveau → nvidia-open on RRK

*Written 2026-09-13 by Claude (2 independent drafts, 4 adversarial verifications, 33 issues resolved). Status: **PROPOSED — nothing applied yet.** Apply only after an explicit "go"; commands marked `sudo` are typed by the user (`! sudo …` in the Claude session or a kitty window).*

Machine facts this plan relies on: RTX 3080 Ti Laptop GPU (GA103) is the **only** display path (MUX in discrete mode); systemd-boot with a single UKI `/boot/EFI/Linux/arch-linux.efi`; kernel `linux` 7.2.4.arch1-2; Secure Boot off; uwsm session; 4 GB zram swap (no hibernation).

## Packages

- nvidia-open 615.71.09-1 ([extra]) - prebuilt open-source NVIDIA kernel modules for exactly the kernel package 'linux' 7.2.4.arch1-2 (pacman -Si: Depends On linux, nvidia-utils=615.71.09). Chosen over nvidia-open-dkms: no linux-headers/dkms/compiler, no 2-3 minute compile on every kernel update, Arch rebuilds it together with 'linux'; the Arch wiki lists it first for Ampere on the plain 'linux' kernel. The one downside (module tied to one exact kernel build) is covered by the post-update check in the risks list.
- nvidia-utils 615.71.09-1 ([extra]) - the userspace driver, GSP firmware, the nouveau blacklist file (/usr/lib/modprobe.d/nvidia-utils.conf), the Xorg driver the SDDM login screen uses, nvidia-smi and nvidia-powerd. pacman pulls libglvnd, egl-wayland, egl-wayland2, egl-gbm and egl-x11 automatically (egl-wayland is what the Hyprland wiki requires).
- libva-nvidia-driver 0.0.18-1 ([extra]) - VA-API to NVDEC bridge (/usr/lib/dri/nvidia_drv_video.so) so native apps (mpv, kitty image previews, a native browser) can decode video on the GPU.
- NOT installed: nvidia-open-dkms, linux-headers, dkms (only worth it with a second/custom kernel); lib32-nvidia-utils ([multilib] is commented out in /etc/pacman.conf and nothing 32-bit is used - add it together with multilib if Steam/Wine come later); nvidia-settings (X11 tool, useless on Wayland). nvidia-persistenced stays disabled (Arch wiki: not needed on a single-GPU desktop).
- Optional, after the switch, verification only: libva-utils (gives 'vainfo'), nvtop (shows the GPU DEC column while a video plays).
- Downloaded automatically by 'flatpak update' after the reboot (no command needed): org.freedesktop.Platform.GL.nvidia-615-71-09//1.4 (344 MB, GL/Vulkan libs for Zen and Discord) and org.freedesktop.Platform.VAAPI.nvidia//25.08 (52 kB, nvidia-vaapi-driver 0.0.18 inside the sandbox). Both exist on flathub (checked with flatpak remote-info); the 25.08 runtime declares 'download-if = active-gl-driver' / 'have-kernel-module-nvidia'.

## Steps (in order)

### 1. Full system update first (never a partial upgrade)  (**sudo**)

```
sudo pacman -Syu
```

Refreshes the package lists and upgrades everything, so that step 3 installs a driver built for the kernel that is actually installed. Answer Y. LOOK AT THE LIST: if it contains the package 'linux', run 'systemctl reboot' when it finishes, log back in and continue with step 2 (the old kernel's module folder is deleted by the upgrade, so working on the old running kernel for the rest of this list is asking for trouble). If 'linux' was not in the list, just continue.

### 2. Keep a safety copy of today's working nouveau boot image as a second boot-menu entry  (**sudo**)

```
sudo cp -n /boot/EFI/Linux/arch-linux.efi /boot/EFI/Linux/arch-linux-nouveau.efi
```

This machine boots one unified kernel image (UKI) /boot/EFI/Linux/arch-linux.efi and has no fallback image. Right now that file still contains nouveau + its firmware and no blacklist, i.e. it boots exactly what you have today. systemd-boot lists every .efi file in /boot/EFI/Linux automatically, so this copy appears in the boot menu as a second 'Arch Linux' entry - your way back to a working desktop if the NVIDIA boot shows nothing. Done AFTER step 1 so the copy matches the installed kernel, and BEFORE step 3 so it is still a pure-nouveau image. ~110 MB; /boot has 854 MB free. '-n' means 'do not overwrite if it already exists'.

### 3. Install the NVIDIA open driver, userspace and VA-API bridge (about 330 MB download)  (**sudo**)

```
sudo pacman -S nvidia-open nvidia-utils libva-nvidia-driver
```

One transaction installs the kernel modules into /usr/lib/modules/<kernel>/extramodules/, the nouveau blacklist into /usr/lib/modprobe.d/nvidia-utils.conf and the firmware. At the end pacman prints 'Updating linux initcpios...' - that is mkinitcpio's own hook rebuilding the boot image with the blacklist inside (it is re-done in step 8 anyway). Nothing changes in the running session until the reboot: nouveau keeps running, so do not start new graphics apps between now and the reboot. Answer Y.

### 4. Confirm the modules landed in the folder of the installed kernel  (user)

```
ls /usr/lib/modules/*/extramodules/
```

Expected: exactly four files - nvidia.ko.zst, nvidia-drm.ko.zst, nvidia-modeset.ko.zst, nvidia-uvm.ko.zst - and NO line ending in ':' (such a header line would mean there are two kernel folders, i.e. the driver was built for a different kernel than the one installed). This is the only check that can catch a kernel/driver mismatch, because 'pacman -Q' prints two unrelated version numbers. If it is wrong, stop here: nothing has changed for the next boot yet (nouveau is only blacklisted from the root filesystem; the boot image copy from step 2 still boots nouveau). Ask for help before rebooting.

### 5. Load the NVIDIA modules early, from inside the boot image (early KMS)  (**sudo**)

```
sudo sed -i '/^MODULES=()/s/()/(nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf
```

Turns the line 'MODULES=()' into 'MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)'. Without this, the driver would load 'late' from the root disk while the login screen is already starting; on this laptop the NVIDIA GPU is the ONLY display device and the login service (sddm) does not wait for it, so the login screen can come up black or restart in a loop (Arch wiki: 'nvidia kernel module being loaded after the display manager'; Hyprland wiki tells Arch users to do exactly this). mkinitcpio pulls the GSP firmware (~120 MB) into the image by itself. Safe to run twice (it only matches the empty '()' line). Hibernation would be a reason not to do this, but this machine cannot hibernate (4 GB zram swap, no resume= setting).

### 6. Remove the 'kms' hook so nouveau is not packed into the boot image at all  (**sudo**)

```
sudo sed -i '/^HOOKS=/s/ kms / /' /etc/mkinitcpio.conf
```

The 'kms' hook copies nouveau plus ~105 MB of nouveau firmware into the boot image; it can never add the NVIDIA modules (they live outside the folder it scans). The Arch wiki recommends removing it so nouveau cannot possibly be loaded during early boot. 'modconf' stays - it is what copies the nouveau blacklist into the image. Only the active HOOKS= line is touched; the commented example lines are left alone.

### 7. Check the two edited lines  (user)

```
grep -E '^(MODULES|HOOKS)=' /etc/mkinitcpio.conf
```

Must print exactly these two lines: MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm) and HOOKS=(base udev autodetect microcode modconf keyboard keymap consolefont block filesystems fsck). Anything else (duplicated names, kms still present, MODULES still empty): do not continue, show the output.

### 8. Rebuild the boot image with the new settings  (**sudo**)

```
sudo mkinitcpio -P
```

Regenerates /boot/EFI/Linux/arch-linux.efi (the UKI). The kernel command line embedded in it comes from /etc/kernel/cmdline and needs NO change: nvidia_drm.modeset=1 and nvidia_drm.fbdev=1 are already the driver's defaults in 615 (verified with modinfo on the package). The output must end with 'Unified kernel image generation successful' and must not contain a line starting with 'ERROR' ('module not found: nvidia' would mean step 4 was wrong). 'Possibly missing firmware' warnings for other modules are harmless. Takes ~30 s.

### 9. Look inside the new boot image  (**sudo**)

```
sudo lsinitcpio -a /boot/EFI/Linux/arch-linux.efi
```

Prints a summary of the image (sudo because /boot is root-only). In the 'Included modules' list you must see nvidia, nvidia-drm, nvidia-modeset and nvidia-uvm, and you must NOT see nouveau. The 'Command line' shown must still be 'root=PARTUUID=6edd4be3-... zswap.enabled=0 rw rootfstype=ext4'. If nouveau is listed, step 6 did not apply - repeat steps 6-8.

### 10. Confirm the safety entry from step 2 is visible to the boot loader  (**sudo**)

```
sudo bootctl list
```

Lists the boot-menu entries. You must see two 'Arch Linux' entries: one with 'id: arch-linux.efi' (the new NVIDIA image) and one with 'id: arch-linux-nouveau.efi' (the safety copy). If the copy is missing, repeat step 2 before rebooting.

### 11. Show the boot menu for 10 seconds on every boot (temporary)  (**sudo**)

```
sudo bootctl set-timeout 10
```

Today the menu flashes by in about 3-4 s (measured from the boot loader's own timing variables), too short for a non-expert to pick the safety entry. This writes a small setting into the laptop's firmware memory (an EFI variable), no boot files are edited; it is undone after the switch is confirmed with: sudo bootctl set-timeout "" (see verifyAfterReboot). In the menu, pressing any arrow key stops the countdown.

### 12. Check that the boot menu allows editing the kernel line (recovery route C)  (**sudo**)

```
sudo cat /boot/loader/loader.conf
```

Prints the boot loader config (root-only file). It must NOT contain a line 'editor no'. If it does, recovery route C in the rollback (typing extra boot options with the 'e' key) will not work; route B (the safety entry) still works. Do not edit anything; just note the result. A missing file or no 'editor' line = editor enabled (the default).

### 13. Create the folder for session-wide environment variables (uwsm)  (user)

```
mkdir -p ~/.config/uwsm
```

This desktop is started by uwsm. The Hyprland wiki (UWSM page) says: put NVIDIA and toolkit variables in ~/.config/uwsm/env, not in the Hyprland config, because uwsm exports that file to the whole session (systemd user services, D-Bus-started apps, Flatpaks opened from links) - hl.env only reaches apps started by Hyprland itself (verified: the existing hl.env variables are absent from 'systemctl --user show-environment'). The folder does not exist yet.

### 14. Session variable: tell VA-API to use the NVIDIA decoder  (user)

```
echo 'export LIBVA_DRIVER_NAME=nvidia' >> ~/.config/uwsm/env
```

Required by libva-nvidia-driver with libva >= 2.20 (installed: 2.24). Appends one line to the (new) file; takes effect at the next login, i.e. after the reboot. Inside the Zen/Discord Flatpaks it is what makes the VAAPI.nvidia extension load.

### 15. Session variable: GLX (Xwayland apps) uses NVIDIA's GL library  (user)

```
echo 'export __GLX_VENDOR_LIBRARY_NAME=nvidia' >> ~/.config/uwsm/env
```

Hyprland wiki NVIDIA page: makes X11/Xwayland OpenGL apps pick NVIDIA's libGLX instead of Mesa's. NVD_BACKEND=direct is NOT added: 'direct' is already the default of libva-nvidia-driver 0.0.18. ELECTRON_OZONE_PLATFORM_HINT is NOT added: VS Code (electron42) and the Discord Flatpak (Electron 42.11) already run natively on Wayland and Electron >= 38 ignores that variable (checked with 'strings' on the electron binary).

### 16. Hyprland env.lua: same VA-API variable (belt and braces)  (user)

```
echo 'hl.env("LIBVA_DRIVER_NAME", "nvidia")' >> ~/.config/hypr/config/env.lua
```

Mirrors step 14 in the rrk-shell Hyprland config (~/.config/hypr is a symlink to ~/claude/rrk-shell/hypr, so this edits the repo file). Hyprland reloads its config the moment a file is saved, so from now on newly started apps in THIS nouveau session would get the NVIDIA setting - therefore do steps 16-18 back to back and open nothing else in between.

### 17. Hyprland env.lua: same GLX variable  (user)

```
echo 'hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")' >> ~/.config/hypr/config/env.lua
```

Mirrors step 15. Keeps the existing convention of env.lua (QT_/GDK_/MOZ_ lines) and matches the Hyprland wiki's hl.env examples. Harmless duplicate of the uwsm file. Do not open new apps now.

### 18. Reboot into the NVIDIA driver (save your work first)  (user)

```
systemctl reboot
```

The driver switch only happens at boot: the new boot image blacklists nouveau and loads nvidia early, the login screen (X11) auto-selects the nvidia driver through the package's OutputClass rule, then Hyprland starts on the NVIDIA EGL driver. Leave the boot menu alone the first time (the default entry is the NVIDIA image). Then work through verifyAfterReboot. If the screen stays black, go to rollback.

## Hyprland env lines added (steps 16–17)

- `hl.env("LIBVA_DRIVER_NAME", "nvidia")`
- `hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")`

## Other config changes / notes

- /etc/mkinitcpio.conf - exact edit. Before: MODULES=() and HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block filesystems fsck). After: MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm) and HOOKS=(base udev autodetect microcode modconf keyboard keymap consolefont block filesystems fsck). BINARIES/FILES unchanged. Done by the two sed lines (steps 5-6); both were tested on a copy - forward + rollback seds give a byte-identical file.
- systemd-boot entry: NOTHING to edit. This machine has no /boot/loader/entries/*.conf; it boots the UKI /boot/EFI/Linux/arch-linux.efi (preset /etc/mkinitcpio.d/linux.preset: default_uki, only the 'default' preset, no fallback). The kernel command line lives in /etc/kernel/cmdline = 'root=PARTUUID=6edd4be3-b6eb-4fa9-8340-4abee10d96c8 zswap.enabled=0 rw rootfstype=ext4' and stays as is: nvidia_drm.modeset=1 and nvidia_drm.fbdev=1 are compiled-in defaults of driver 615 (changelog: modeset default since 595.45.04, fbdev since 570.86.16). If a kernel option is ever needed later (e.g. acpi_backlight=native or mem_sleep_default=deep): 'sudoedit /etc/kernel/cmdline', then 'sudo mkinitcpio -P'. Two temporary boot-loader items are added and later removed: the safety UKI copy /boot/EFI/Linux/arch-linux-nouveau.efi (auto-listed Type #2 entry, delete when done) and the EFI variable set by 'bootctl set-timeout 10' (clear with: sudo bootctl set-timeout "").
- /etc/modprobe.d: nothing to add. nvidia-utils ships /usr/lib/modprobe.d/nvidia-utils.conf = 'blacklist nouveau', 'blacklist nova_core', 'blacklist nova_drm', 'softdep nvidia post: nvidia-uvm nvidia-drm', 'options nvidia NVreg_UseKernelSuspendNotifiers=1', 'options nvidia NVreg_TemporaryFilePath=/var/tmp'. The modconf hook copies it into the boot image. Any file you add under /etc/modprobe.d later (S0ix, color_pipeline, see below) also needs 'sudo mkinitcpio -P' because the modules now load from inside the image.
- No pacman hook to add. mkinitcpio 42's own /usr/share/libalpm/hooks/90-mkinitcpio-install.hook already triggers on usr/lib/modules/*/extramodules/, usr/lib/modprobe.d/ and usr/lib/firmware/* (Install/Upgrade/Remove) and rebuilds the UKI ('Updating linux initcpios...'). The old Arch-wiki nvidia.hook is obsolete.
- New file ~/.config/uwsm/env (created by steps 13-15), contents: 'export LIBVA_DRIVER_NAME=nvidia' and 'export __GLX_VENDOR_LIBRARY_NAME=nvidia'. uwsm's prepare-env sources it at session start and exports the difference to the systemd user manager and D-Bus activation environment. Long-term the existing QT_/GDK_/MOZ_ hl.env lines belong here too (not part of this change). Optional power saver for GPU video decode (driver >= 580.105.08, Arch wiki): 'export CUDA_DISABLE_PERF_BOOST=1' in the same file.
- ~/claude/rrk-shell/hypr/config/env.lua: the two hl.env lines from hyprlandEnv appended (steps 16-17). No GBM_BACKEND, WLR_NO_HARDWARE_CURSORS, __GL_GSYNC_ALLOWED, AQ_DRM_DEVICES, NVD_BACKEND or ELECTRON_OZONE_PLATFORM_HINT (single GPU, GBM auto-selected via /usr/lib/gbm/nvidia-drm_gbm.so; NVD_BACKEND=direct is the default; Electron 42 ignores the hint).
- ~/claude/rrk-shell/hypr/config/input.lua, AFTER the reboot (verifyAfterReboot): cursor.no_hardware_cursors = true -> 2 (2 = auto, Hyprland's default; cursor.use_cpu_buffer stays at its default 2 = 'auto, enabled on NVIDIA', which is the mechanism that makes hardware cursors work on NVIDIA in 0.56). Hyprland applies it live (autoreload). Also fix by hand the comment above the block that still talks about the nouveau workaround. Not done before the reboot on purpose: autoreload would re-enable the vanishing-cursor bug while still on nouveau. Ladder if the cursor misbehaves on NVIDIA: first add use_cpu_buffer = 1 to the cursor block; only then go back to no_hardware_cursors = true (software cursor, what runs today).
- Suspend/resume: nothing to enable. nvidia-utils ships nvidia-suspend/hibernate/resume/suspend-then-hibernate.service DISABLED and they must stay so - the 615 open modules preserve video memory with NVreg_UseKernelSuspendNotifiers=1 (set in nvidia-utils.conf); VRAM in use is written to /var/tmp on the ext4 root (877 GB free, the README wants free space >= VRAM in use, max ~17 GB). (The package's .INSTALL only has a post_upgrade that disables those services when coming from < 595.58.03 - on a fresh install nothing runs; do not expect a message.) hypridle's before_sleep/after_sleep lines stay. This laptop sleeps with s2idle ('[s2idle] deep' in /sys/power/mem_sleep). Two optional follow-ups after testing: (a) if 'cat /proc/driver/nvidia/gpus/0000:01:00.0/power' says 'Video Memory Self Refresh: Supported', a file /etc/modprobe.d/nvidia-s0ix.conf with 'options nvidia NVreg_EnableS0ixPowerManagement=1' + 'sudo mkinitcpio -P' lets the GPU sleep properly under s2idle; (b) if resume is unreliable, switch to real S3: test with 'echo deep | sudo tee /sys/power/mem_sleep' then 'systemctl suspend'; make permanent by appending ' mem_sleep_default=deep' to /etc/kernel/cmdline + 'sudo mkinitcpio -P' (a and b exclude each other: S0ix only applies to s2idle).
- GPU power management: do NOT set NVreg_DynamicPowerManagement - RTD3 (GPU fully off) only works when the GPU drives no display; here the MUX is in discrete mode and the 3080 Ti drives the panel. What you get instead is the driver's own clock management (idle at P8, low power draw), which nouveau never did on this Ampere chip. nvidia-powerd (Dynamic Boost, shifts power between the i9-12900H and the GPU) is optional: after the reboot read 'cat /proc/driver/nvidia/gpus/0000:01:00.0/power'; only if it reports Dynamic Boost as supported run 'sudo systemctl enable --now nvidia-powerd.service' and check 'journalctl -u nvidia-powerd -b' for SBIOS errors (if any: 'sudo systemctl disable --now nvidia-powerd.service'). Do not enable nvidia-persistenced.
- Flatpak (Zen, Discord): after the reboot run 'flatpak update' and accept - flatpak reads /sys/module/nvidia/version and auto-downloads org.freedesktop.Platform.GL.nvidia-615-71-09 (GL/Vulkan, 344 MB) and org.freedesktop.Platform.VAAPI.nvidia (nvidia-vaapi-driver inside the sandbox). Until then Flatpak apps render in software (slow). Repeat 'flatpak update' after every future nvidia-utils upgrade (flathub can lag a few days). Both apps have 'devices=all', so /dev/nvidia* is reachable, and session variables from uwsm/env pass into the sandbox.
- Zen video decode (Zen 1.22 = Firefox 155): about:config -> media.hardware-video-decoding.force-enabled = true (media.ffmpeg.vaapi.enabled is not needed on Firefox >= 137; leave media.av1.enabled true, GA103 decodes AV1). The nvidia-vaapi-driver README says Firefox also needs MOZ_DISABLE_RDD_SANDBOX=1 (it weakens the sandbox of the decoder process - decide whether you accept that); scope it to Zen only with 'flatpak override --user --env=MOZ_DISABLE_RDD_SANDBOX=1 app.zen_browser.zen' (undo: flatpak override --user --reset app.zen_browser.zen). Sandbox-free alternative (experimental, Firefox >= 153 on Turing+): about:config media.hardware-video-decoding-vulkan.enabled = true and skip the override. This matters for the temps: today Zen's 'RDD Process' (software video decode) sits at ~25 % CPU while a video plays. No native browser install (AUR zen-browser-bin) is needed.
- Electron apps (VS Code, Discord): no change. Both already run natively on Wayland (Electron 42 / Chrome 148, XDG_SESSION_TYPE=wayland). If one ever needs XWayland instead (e.g. Discord global keybinds), write '--ozone-platform=x11' into ~/.config/code-flags.conf (read by /usr/bin/code) or ~/.var/app/com.discordapp.Discord/config/discord-flags.conf (read by the Flathub launcher). The old --enable-features=WaylandLinuxDrmSyncobj flag no longer exists in Chrome 148.
- Separate from the driver, but it explains most of the 85-92 C idle CPU: power-profiles-daemon is on 'performance' (EPP=performance). After the driver checks, run 'powerprofilesctl set balanced' (no root, reversible) and re-measure with 'sensors'. Real battery/thermal gains from GPU power-off would need switching the BIOS MUX to hybrid/Optimus so the Intel iGPU drives the panel (i915 + PRIME) - a separate project.
- Clean-up once everything passes (verifyAfterReboot, last items): sudo rm /boot/EFI/Linux/arch-linux-nouveau.efi (stale copy that future kernel updates will not refresh) and sudo bootctl set-timeout "" (back to the previous menu timing). xf86-video-nouveau may be removed later ('sudo pacman -Rns xf86-video-nouveau') - keep it until the switch is final, the rollback login screen uses it.
- Per CLAUDE.md, afterwards: append the entry to ~/claude/setup-log.md (date, commands, results), update ~/claude/memory/machine-rrk-razer-blade-17.md (GPU now nvidia-open 615.71.09, early KMS, kms hook removed, uwsm env file, UKI boot, safety copy removed) and commit the rrk-shell repo change (hypr/config/env.lua, hypr/config/input.lua).

## Verify after the reboot (in order)

1. lsmod | grep -E '^(nvidia|nouveau)'   # expect nvidia, nvidia_modeset, nvidia_uvm, nvidia_drm; no nouveau line
2. cat /sys/module/nvidia_drm/parameters/modeset /sys/module/nvidia_drm/parameters/fbdev   # expect Y and Y
3. nvidia-smi --query-gpu=name,driver_version,pstate,power.draw,temperature.gpu --format=csv   # expect 'NVIDIA GeForce RTX 3080 Ti Laptop GPU', 615.71.09, and at an idle desktop pstate P8 with a low power draw (roughly 10-25 W). This is the 'GPU can idle' check nouveau could not pass; it cannot go lower because it drives the panel
4. grep -hE 'with driver|Vendor:|Renderer:|Explicit sync' /run/user/1000/hypr/*/hyprland.log   # expect 'with driver nvidia-drm', 'Vendor: NVIDIA Corporation', 'Renderer: NVIDIA GeForce RTX 3080 Ti Laptop GPU/PCIe/SSE2' and 'Explicit sync supported'. Today (nouveau) these lines read 'driver nouveau', 'Vendor: Mesa', 'Renderer: zink ... NVK', 'Explicit sync unsupported' and 'failed to set DRM_CLIENT_CAP_ATOMIC, falling back to legacy' - none of those may appear. If it still says Mesa/zink, check: ls /usr/share/glvnd/egl_vendor.d/ must list 10_nvidia.json
5. grep -E 'UseKernelSuspendNotifiers|TemporaryFilePath' /proc/driver/nvidia/params   # expect UseKernelSuspendNotifiers: 1 and TemporaryFilePath: "/var/tmp" (video-memory preservation on suspend is active without any service)
6. journalctl -b -p err --no-pager   # ideally nothing about nvidia/drm/sddm/Xorg. 'journalctl -b -k --no-pager | grep -i nvidia' should show the driver initialising early (before sddm) and 'nvidia-drm ... fb0' (fbdev took over the console)
7. Desktop sanity: rrk-shell bar + blur render, kitty/Dolphin/VS Code open, hyprlock (SUPER+L) and SUPER+M logout (uwsm stop) still work, the login screen looks normal
8. sed -i 's/no_hardware_cursors = true/no_hardware_cursors = 2/' ~/.config/hypr/config/input.lua   # switches to hardware cursors live (Hyprland autoreload). Then leave the mouse still for 10 s: it must stay visible; move over kitty/Zen/Dolphin: no trails/ghosting. If it flickers or vanishes: first add 'use_cpu_buffer = 1,' inside the cursor block; if still bad, put 'no_hardware_cursors = true,' back
9. Screen-off test (driver 615.71.09 has a fresh, open DPMS-wake bug report, NVIDIA bug 6760883, and hypridle turns the panel off after 15 min): in kitty run: hyprctl dispatch dpms off   - the screen goes black; wait 5 s, then type blind: hyprctl dispatch dpms on   and press Enter (kitty still has focus). The panel must come back. Real-life repeat: leave the laptop idle 15 min, then move the mouse. If the panel stays black: Ctrl+Alt+F3 then Ctrl+Alt+F1 usually re-lights it; then comment out the 900 s listener line in ~/.config/hypr/hypridle.conf (keep the dim and lock lines) until a fixed driver lands. If the machine FREEZES here and 'journalctl -b -k | grep -E "Xid|GSP"' shows Xid 119 / GSP timeout, see risks (GSP bug)
10. Brightness: press the brightness keys and confirm the panel VISIBLY dims (the device is nvidia_wmi_ec_backlight; a known failure is the value changing while the screen stays at maximum). If it does not dim: add ' acpi_backlight=native' (second try: video) to /etc/kernel/cmdline with sudoedit, 'sudo mkinitcpio -P', reboot; if two backlight devices then exist, pin the working one with '-d <name>' in hypridle.conf line 6 and rrk-shell/shell/services/Brightness.qml lines 13 and 27
11. systemctl suspend   # close the lid or run it; wait 20 s; wake -> hyprlock, desktop intact, kitty still renders. 'journalctl -b | grep -i suspend' should show no errors. If resume is black/unreliable: test S3 once ('echo deep | sudo tee /sys/power/mem_sleep', suspend again); if that works, make it permanent via mem_sleep_default=deep in /etc/kernel/cmdline + sudo mkinitcpio -P
12. cat /proc/driver/nvidia/gpus/0000:01:00.0/power   # read two things: 'Video Memory Self Refresh' (Supported -> optional S0ix tweak, see otherConfigChanges) and Dynamic Boost (supported -> optional 'sudo systemctl enable --now nvidia-powerd.service', then 'systemctl status nvidia-powerd.service --no-pager' must be active (running) with no SBIOS errors in 'journalctl -u nvidia-powerd -b'; otherwise leave it disabled)
13. flatpak update   # accept; must offer org.freedesktop.Platform.GL.nvidia-615-71-09 and org.freedesktop.Platform.VAAPI.nvidia. Then: flatpak list --runtime --columns=application,branch   # both listed. Then open Zen: about:support -> Graphics -> Compositing must say WebRender (not Software)
14. Zen video decode (optional, see otherConfigChanges for the sandbox trade-off): flatpak override --user --env=MOZ_DISABLE_RDD_SANDBOX=1 app.zen_browser.zen   then about:config media.hardware-video-decoding.force-enabled = true, restart Zen, play a YouTube video and run: nvidia-smi -q -d UTILIZATION   # Decoder must be > 0 %, and Zen's 'RDD Process' in top must be near 0 % CPU instead of ~25 %
15. Native VA-API (optional): sudo pacman -S libva-utils   then   vainfo   # expect 'vainfo: Driver version: VA-API NVDEC driver [direct backend]' with H264/HEVC/VP9/AV1 profiles. If it errors, only GPU video decode is lost (CPU decode still works)
16. Temps: sensors   and   ps -eo pid,pcpu,comm --sort=-pcpu | head   # compare with the 85-92 C package and the busy kworker/u81 threads from before. Then run: powerprofilesctl set balanced   and measure again after a few minutes (the CPU heat is largely the performance power profile, not the GPU driver)
17. Going forward, after EVERY 'sudo pacman -Syu' whose list contained 'linux': ls /usr/lib/modules/*/extramodules/   # must show the four nvidia files and no ':' header line, and the 'Updating linux initcpios...' output must not contain 'ERROR: module not found: nvidia'. If it does: do NOT reboot; run 'sudo pacman -Syu' again later (the matching nvidia-open is missing on the mirror) or ask for help (switch to nvidia-open-dkms + linux-headers)
18. When everything above passes: sudo rm /boot/EFI/Linux/arch-linux-nouveau.efi   then   sudo bootctl set-timeout ""   # remove the safety entry and restore the menu timing. Then log the change in setup-log.md / memory and commit rrk-shell

## Rollback

HOW TO REACH A TEXT CONSOLE ON THIS LAPTOP: press Ctrl+Alt+F3 (NOT F2). Here F1 is the Hyprland session, F2 is the SDDM login screen's own X server (a black F2 is normal when the greeter is broken), F3 to F6 are text consoles. Log in as alien with your normal password. Run the lines below ONE AT A TIME, exactly as written (nothing after the command).

ROUTE A - the desktop or login screen is broken, but Ctrl+Alt+F3 gives you a text login. Step A1 empties the MODULES line again (must be done BEFORE removing the packages, otherwise the automatic rebuild prints ERROR lines and still writes an image):

```
sudo sed -i 's/^MODULES=(.*)/MODULES=()/' /etc/mkinitcpio.conf
```
A2 puts the kms hook back exactly where it was (tested on a copy: file becomes byte-identical to today's):

```
sudo sed -i '/^HOOKS=/s/ modconf keyboard / modconf kms keyboard /' /etc/mkinitcpio.conf
```
A3 check: must print MODULES=() and HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block filesystems fsck):

```
grep -E '^(MODULES|HOOKS)=' /etc/mkinitcpio.conf
```
A4 removes the driver, its egl-* dependencies, the nouveau blacklist and the firmware (answer Y; works offline). pacman's mkinitcpio hook fires on removal too and rebuilds the boot image with nouveau ('Updating linux initcpios...'):

```
sudo pacman -Rns nvidia-open nvidia-utils libva-nvidia-driver
```
A5 rebuilds the boot image once more with the restored settings (safe to run even if A4 already did it; must end with 'Unified kernel image generation successful'):

```
sudo mkinitcpio -P
```
A6 removes the session variables file (it did not exist before; with nouveau, LIBVA_DRIVER_NAME/__GLX_VENDOR_LIBRARY_NAME=nvidia would break GL apps):

```
rm ~/.config/uwsm/env
```
A7 deletes the two NVIDIA hl.env lines from the Hyprland config (tested on a copy: the six original lines survive):

```
sed -i '/LIBVA_DRIVER_NAME\|GLX_VENDOR_LIBRARY/d' ~/.config/hypr/config/env.lua
```
A8 only if you already changed the cursor after the reboot - software cursor back on for nouveau:

```
sed -i 's/no_hardware_cursors = 2/no_hardware_cursors = true/' ~/.config/hypr/config/input.lua
```
A9 only if you did the Zen video override:

```
flatpak override --user --reset app.zen_browser.zen
```
A10 reboot; the normal entry boots on nouveau exactly as before:

```
systemctl reboot
```
A11 afterwards, from the desktop: delete the safety copy, restore the menu timing, and log the rollback in setup-log.md:

```
sudo rm /boot/EFI/Linux/arch-linux-nouveau.efi
```
```
sudo bootctl set-timeout ""
```
ROUTE B - nothing on screen at all, Ctrl+Alt+F3 shows nothing either: hold the power button 10 s, power on. The boot menu now stays for 10 s (step 11); press an arrow key to stop the countdown, select the second 'Arch Linux' entry - the one showing arch-linux-nouveau.efi - and press Enter. That boots the saved nouveau image: the desktop appears as before (Wi-Fi may be missing in this emergency boot if step 1 updated the kernel; not needed). Open kitty and run route A from A1. Nothing is typed blind.

ROUTE C - the safety entry is missing or does not work: at the boot menu highlight the normal 'Arch Linux' entry, press e (the editor shows the current line ending in 'rootfstype=ext4'; press End), type a space and then exactly: systemd.unit=multi-user.target module_blacklist=nvidia_drm,nvidia_modeset,nvidia_uvm,nvidia   then press Enter. The kernel boots without the NVIDIA modules and without the login screen, straight to a text login (works because Secure Boot is off and the editor is enabled - step 12). Log in and run route A. This edit is one-time and not saved. From a working console you can also force the menu with: systemctl reboot --boot-loader-menu=30

ROUTE D - the laptop hangs at shutdown/reboot after the switch and 'journalctl -b -k' from the previous boot shows GFW_BOOT / GSP errors: that is a known nvidia-open bug on Ampere laptops, not something you broke. Hold power 10 s, use route B, then route A. Plan B for later (separate session): AUR nvidia-580xx-dkms + linux-headers with NVreg_EnableGpuFirmware=0.

What was tested (read-only task, nothing changed on the live system): every sed above was run on copies of the real /etc/mkinitcpio.conf, env.lua and input.lua and diffed (forward + rollback = identical files); a UKI was built from the current config into the scratchpad as the normal user to confirm 'mkinitcpio -P'/'lsinitcpio -a' behaviour on a UKI; the pacman hook triggers, /usr/lib/uwsm/prepare-env.sh, sddm.service, the VT numbers (journal: sddm 'Using VT 2', Hyprland session VTNr=1) and the flatpak extension rules were read. The reboot itself is the untested part, by necessity.


## Risks and expectations

1. WHAT IMPROVES (expectations): (1) GPU power management - the NVIDIA driver clocks the GPU down to P8 at idle (roughly 10-25 W) and stops nouveau's GSP/DRM busy-work that shows up as kworker/u81 threads; the GPU cannot switch fully off (D3cold/RTD3) because in discrete MUX mode it drives the panel, and most of the 85-92 C CPU is the 'performance' power profile (fix separately with powerprofilesctl set balanced). (2) Blur/compositing - Hyprland moves from Mesa's zink-on-NVK translation layer without atomic KMS and without explicit sync to NVIDIA's native EGL driver with atomic modesetting and explicit sync: smoother rrk-shell blur, fewer tearing/flicker artefacts, far less CPU spent on rendering. (3) Hardware cursor - Hyprland's cursor:use_cpu_buffer path works on the NVIDIA driver, so the software-cursor workaround can go (cursor stays visible when idle). (4) Video decode - NVDEC via libva-nvidia-driver for native apps and, through the flathub VAAPI.nvidia extension, for Zen (today Zen's software decoder burns ~25 % CPU per video); Discord/VS Code get proper GL through the GL.nvidia extension instead of llvmpipe.
2. GSP firmware on an Ampere laptop (Arch wiki footnote): nvidia-open cannot run without GSP and 'GSP firmware is known to cause issues, including complete failure on some laptops containing Ampere GPUs'. Good sign: nouveau already runs this exact GPU on GSP firmware today (journal: 'gsp: RM version: 570.144') without crashing. Known shapes if it does hit: (a) freeze when the screen blanks or on resume with 'Xid 119 ... Timeout ... GSP' in journalctl -k - first disable the 900 s dpms listener in hypridle.conf; the wiki workaround is locking clocks (nvidia-persistenced + nvidia-smi -lgc), otherwise roll back; (b) hang at shutdown/reboot with GFW_BOOT errors (open-gpu-kernel-modules issue #1294, RTX 3070 Laptop, still open) - rollback route D. Plan B is the proprietary AUR nvidia-580xx-dkms + linux-headers with NVreg_EnableGpuFirmware=0 (needs a compile; may not build for kernel 7.2) - decide then, not now.
3. Black screen at the first boot is the main failure mode on a laptop whose ONLY display path is this GPU. Mitigations built in: early KMS (step 5) so the driver is up before the login screen; the arch-linux-nouveau.efi safety entry with a 10 s menu (steps 2, 10, 11); the boot-editor route C; the Ctrl+Alt+F3 console. Two look-alikes that are NOT driver failures: a login screen that is black but shows a mouse cursor while F3 works = sddm started before the GPU finished (should not happen with early KMS; if it does, a drop-in with ExecStartPre=/usr/bin/sleep 3 for sddm.service fixes it - ask for help); Hyprland starts but the panel stays blank while F3 works = possibly the new DRM colour-pipeline API (driver 610+, NVIDIA README: 'can cause a blank screen' with some compositors) - test once via route C's editor with ' nvidia_drm.color_pipeline=0' instead of the blacklist, and if that helps make it permanent with /etc/modprobe.d/nvidia-drm.conf containing 'options nvidia_drm color_pipeline=0' + sudo mkinitcpio -P.
4. Kernel/driver lockstep: nvidia-open is built for one exact kernel build and its dependency on 'linux' is unversioned, so a mirror that is behind could give you a new kernel without the matching driver. If that happens, mkinitcpio prints 'ERROR: module not found: nvidia' but STILL writes a boot image without the driver (verified with mkinitcpio 42 on a scratch config) and the next boot has nouveau blacklisted and no nvidia = text console only. Guard (verifyAfterReboot, last-but-one item): after every update that contained 'linux', run 'ls /usr/lib/modules/*/extramodules/' and read the pacman output; never 'pacman -S linux' alone. Alternative if this ever bites: nvidia-open-dkms + linux-headers (rebuilds automatically for any kernel, at the price of a compile per kernel update).
5. DPMS/screen-off regression in 615.71.09: a 2026-09-11 forum report (RTX 5090, KDE, same kernel 7.2.4) of a DisplayPort monitor not waking after being turned off; NVIDIA filed bug 6760883. hypridle here turns the panel off after 15 min and any external HDMI/DP monitor hangs off this same GPU, so test the dpms off/on path right after the reboot (verifyAfterReboot) and, if it fails, comment out the 900 s listener until a fixed driver arrives. There is no repo 610 fallback (nvidia-open is kernel-pinned).
6. Suspend: this laptop uses s2idle; the 615 README notes s2idle resume problems on some systems and offers 'deep' as the fallback (documented in otherConfigChanges). Video memory is copied to /var/tmp on every suspend (needs free space >= VRAM in use, ~17 GB worst case; root has 877 GB). Do not enable the nvidia-suspend/resume services on 595+ (unsupported combination with kernel suspend notifiers). Early loading would break resume-from-hibernation, which this machine cannot do anyway (zram only).
7. Hyprland auto-reloads its config on save (misc:disable_autoreload is false): the two hl.env lines (steps 16-17) take effect in the running nouveau session immediately, so any GLX/VA-API app started between step 16 and the reboot would try the NVIDIA libraries without the NVIDIA kernel module. Also, after step 3 the NVIDIA EGL vendor file is present while nouveau still runs, so app launches may be slower/odd until the reboot. Just do steps 16-18 back to back; nothing persists.
8. Hardware cursor on NVIDIA may still glitch with some Hyprland/driver combinations; ladder in otherConfigChanges (use_cpu_buffer = 1 first, then software cursor). That is why the cursor change is made only after the reboot, live and reversible.
9. Flatpak apps (Zen, Discord) render in software until 'flatpak update' has installed GL.nvidia-615-71-09 (344 MB); the same applies after every future nvidia-utils upgrade until flathub catches up (usually days). Native apps are unaffected.
10. Zen video decode: the recommended path needs MOZ_DISABLE_RDD_SANDBOX=1, which weakens Firefox's decoder-process sandbox (scoped to Zen only via flatpak override, reversible). The sandbox-free Vulkan Video path is experimental. libva-nvidia-driver's direct backend uses an unstable NVIDIA API and 'is likely to break with new driver versions' (README); 0.0.18 vs 615.71.09 is unproven on this box - if vainfo fails, only GPU video decode is lost.
11. 'sudo pacman -Syu' in step 1 upgrades everything (Hyprland, Quickshell, kernel...). Any unrelated upgrade regression lands in the same reboot - if something non-GPU breaks, check 'journalctl -b -p err' before blaming the driver.
12. Brightness on this laptop goes through nvidia_wmi_ec_backlight; with the NVIDIA driver a documented failure is the value changing while the panel stays at full brightness. Fallback (acpi_backlight=native/video) is in verifyAfterReboot.
13. The boot image grows by ~120 MB (GSP/ucode firmware embedded); /boot has 854 MB free, boot-time impact negligible. Only the 'default' preset exists (no fallback UKI), hence the manual safety copy - delete it at the end, it is never refreshed by kernel updates.
14. Secure Boot is disabled, which is what makes the unsigned modules load and the boot-menu editor (route C) work; if Secure Boot is ever enabled later, both change. seatd.service stays disabled (unchanged). Do not switch SDDM to a Wayland greeter in the same change - the X11 greeter with NVIDIA's Xorg driver is the tested path. xf86-video-nouveau stays installed until the switch is final.
15. Electron apps (VS Code, Discord) may still flicker on NVIDIA in rare cases even though they already run natively on Wayland; the current escape hatch is '--ozone-platform=x11' in their flags files (otherConfigChanges), not an environment variable.

## Sources

- https://wiki.archlinux.org/title/NVIDIA - Installation table (nvidia-open for 'linux' on Turing/Ampere/Ada; Ampere-laptop GSP footnote), 'nvidia-utils blacklists nouveau ... optionally remove kms from HOOKS', DRM kernel mode setting (modeset+fbdev enabled by default with nvidia-utils), Early loading ('startup issues such as the nvidia kernel module being loaded after the display manager'), Wayland section
- https://wiki.archlinux.org/title/NVIDIA/Tips_and_tricks - Preserve video memory after suspend (595+: NVreg_UseKernelSuspendNotifiers=1, services disabled by default, /var/tmp, 5 % free-space rule), Dynamic Boost, nvidia-persistenced not needed
- https://wiki.archlinux.org/title/NVIDIA/Troubleshooting - Black screen at X startup (add nvidia to mkinitcpio MODULES); System freeze when the display powers off or on resume (Xid 119 GSP, clock locking workaround)
- https://wiki.archlinux.org/title/CPU_frequency_scaling#nvidia-powerd - prerequisites and /proc/driver/nvidia/gpus/*/power check
- https://wiki.archlinux.org/title/Kernel_mode_setting - Early KMS start with MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)
- https://wiki.archlinux.org/title/Mkinitcpio and mkinitcpio.conf(5) - kms/modconf hooks, MODULES pulls firmware, UKI generation, -P
- https://wiki.archlinux.org/title/Unified_kernel_image - /etc/kernel/cmdline embedding, preset, pacman hook; editor override only without Secure Boot
- https://wiki.archlinux.org/title/Systemd-boot and systemd-boot(7)/loader.conf(5) local man pages - UKIs in ESP/EFI/Linux listed automatically (Type #2), 'e' editor, 'editor' option default yes, bootctl set-timeout / list, 'systemctl reboot --boot-loader-menu='
- https://wiki.archlinux.org/title/Hardware_video_acceleration - libva-nvidia-driver, LIBVA_DRIVER_NAME=nvidia, vainfo, nvtop DEC, CUDA_DISABLE_PERF_BOOST power note
- https://wiki.archlinux.org/title/Firefox (Vulkan subsection: Vulkan Video on NVIDIA does not need the RDD sandbox disabled) and https://wiki.archlinux.org/title/Wayland#Electron ('Since Electron 38.2, Wayland is used by default')
- https://wiki.hypr.land/Nvidia/ (updated 2026-08-26) - nvidia-open for Turing+, early KMS MODULES on Arch, modeset/fbdev already done on Arch, hl.env LIBVA_DRIVER_NAME / __GLX_VENDOR_LIBRARY_NAME, suspend handled on Arch, Electron flicker section
- https://wiki.hypr.land/useful-utilities/uwsm/ (updated 2026-09-12) - 'Avoid placing environment variables in the hyprland.lua file. Instead, use ~/.config/uwsm/env for theming, XCursor, NVIDIA and toolkit variables'; https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/
- https://wiki.hypr.land/Configuring/Basics/Variables/ - cursor:no_hardware_cursors (int, default 2 = auto), cursor:use_cpu_buffer (default 2 = auto, 'Required on Nvidia to have HW cursors'), misc:disable_autoreload default false, render:non_shader_cm default 3
- https://github.com/elFarto/nvidia-vaapi-driver README - NVD_BACKEND direct is the default, needs nvidia_drm modeset, Firefox keys (media.hardware-video-decoding.force-enabled; media.ffmpeg.vaapi.enabled only until Firefox 137), MOZ_DISABLE_RDD_SANDBOX, direct backend stability note
- https://forums.developer.nvidia.com/t/615-release-feedback-discussion/382815 - 2026-09-11 DPMS wake regression report, NVIDIA bug 6760883; https://github.com/NVIDIA/open-gpu-kernel-modules/issues/1294 - GFW_BOOT/GSP hang on an Ampere laptop with open modules; https://bbs.archlinux.org/viewtopic.php?id=311264 - black greeter from an sddm/GPU race
- https://download.nvidia.com/XFree86/Linux-x86_64/615.71.09/README/ - dynamicpowermanagement.html (GPU stays active while driving a display), powermanagement.html (kernel suspend notifiers, S0ix option, s2idle known issue -> deep, TemporaryFilePath), wayland-issues.html / NVIDIA_Changelog (color_pipeline since 610.43.02)
- https://raw.githubusercontent.com/electron/electron/main/docs/breaking-changes.md (38.0: ELECTRON_OZONE_PLATFORM_HINT removed, --ozone-platform=x11 to force XWayland) and https://www.electronjs.org/blog/tech-talk-wayland
- https://github.com/flathub/org.freedesktop.Platform.GL.nvidia and https://gitlab.com/freedesktop-sdk/freedesktop-sdk/-/tree/master/elements/extensions/platform-vaapi-nvidia (VAAPI.nvidia = nvidia-vaapi-driver v0.0.18); https://github.com/flatpak/flatpak/blob/main/common/flatpak-utils.c (active-gl-driver / have-kernel-module- conditions)
- Packages inspected from the mirror in the earlier drafts (nvidia-open / nvidia-utils 615.71.09-1): modinfo of nvidia-drm.ko.zst (vermagic 7.2.4-arch1-2; modeset, fbdev and color_pipeline default 1), nvidia.ko firmware list, usr/lib/modprobe.d/nvidia-utils.conf, .INSTALL (post_upgrade only), 10-nvidia-drm-outputclass.conf, 60-nvidia.rules, usr/share/doc/nvidia/html/*
- Verified on RRK 2026-09-13 for this final plan: /etc/mkinitcpio.conf, /etc/mkinitcpio.d/linux.preset (default_uki, single preset), /etc/kernel/cmdline, /usr/lib/modules (single dir 7.2.4-arch1-2), pacman -Q (linux 7.2.4.arch1-2, mkinitcpio 42-1, hyprland 0.56.2-3, uwsm 0.26.7-1, sddm 0.21.0-7, flatpak 1.18.2, code 1.137.0 -> electron42 42.9.3, libva 2.24.1, xf86-video-nouveau 1.0.18), pacman -Si nvidia-open/nvidia-utils (deps), /etc/pacman.conf (multilib commented), /usr/share/libalpm/hooks/90-mkinitcpio-install.hook, /usr/lib/systemd/system/sddm.service (After= only, Restart=always, StartLimitBurst=2), journalctl (sddm 'Using VT 2', nouveau gsp RM 570.144, simpledrm), loginctl (Hyprland session VTNr=1), EFI variables LoaderTimeMenuUSec/LoaderTimeExecUSec (menu shown ~3.8 s), bootctl status (systemd-boot 261.3, Secure Boot disabled, menu-timeout control supported), /run/user/1000/hypr/*/hyprland.log (driver nouveau, Vendor Mesa, zink/NVK, explicit sync unsupported, legacy fallback), hyprctl getoption misc:disable_autoreload (false), ~/.config/hypr symlink -> ~/claude/rrk-shell/hypr, hypr/config/env.lua and input.lua, hypridle.conf (900 s dpms off), rrk-shell/shell/services/Brightness.qml, /sys/class/backlight (nvidia_wmi_ec_backlight), /sys/power/mem_sleep ([s2idle] deep), /usr/lib/uwsm/prepare-env.sh + /usr/share/doc/uwsm/README.md (uwsm/env sourced and exported to systemd/D-Bus), systemctl --user show-environment (hl.env vars absent), strings of /usr/lib/electron42/electron (Chrome 148.0.7778.280 / Electron 42.9.3: '--ozone-platform' present, no ELECTRON_OZONE_PLATFORM_HINT, no WaylandLinuxDrmSyncobj), /usr/bin/code (reads ~/.config/code-flags.conf), flatpak info -m org.freedesktop.Platform//25.08 (GL: download-if active-gl-driver; VAAPI.nvidia: download-if have-kernel-module-nvidia), flatpak remote-info flathub org.freedesktop.Platform.VAAPI.nvidia//25.08 (exists), flatpak permissions of app.zen_browser.zen (devices=all), Zen platform.ini Milestone=155.0.1, powerprofilesctl get (performance), sensors (package 89 C), df /boot (854 M free) and / (877 G free)
- Scratchpad tests for this plan (no system changes): every sed in steps and rollback run on copies of the real files and diffed (idempotent MODULES sed, forward+rollback identical); a UKI built with 'mkinitcpio -c <conf without kms> -k 7.2.4-arch1-2 -U' as the normal user (Early CPIO 800 KiB without nouveau) and inspected with 'lsinitcpio -a' to confirm the 'Included modules' listing used in step 9; all command lines measured (< 100 chars, no '&&', no pipes in required steps)
