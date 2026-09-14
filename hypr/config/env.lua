hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("QT_QPA_PLATFORM", "wayland")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("GDK_BACKEND", "wayland,x11")
hl.env("MOZ_ENABLE_WAYLAND", "1")
-- WebKitGTK apps (Modrinth App, other Tauri apps) crashed on open: Mesa's Vulkan layer and GTK both drew to the same
-- window and Hyprland killed the client with "wp_linux_drm_syncobj_surface_v1: Missing acquire timeline" (2026-09-14).
-- Turning off WebKit's DMA-BUF renderer avoids that path; the app still renders on the GPU. Same fix the Hyprland wiki
-- recommends for NVIDIA. Remove once WebKitGTK / Hyprland sort out explicit sync.
hl.env("WEBKIT_DISABLE_DMABUF_RENDERER", "1")
-- NVIDIA driver (nvidia-open, 2026-09-14): VA-API through NVDEC and NVIDIA's GLX for Xwayland apps. The same two lines
-- live in ~/.config/uwsm/env for the whole session (systemd user services, D-Bus-started apps); these reach what Hyprland starts.
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
