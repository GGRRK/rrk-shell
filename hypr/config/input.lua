hl.config({
    input = {
        kb_layout = "us", kb_variant = "", kb_model = "", kb_options = "", kb_rules = "",
        follow_mouse = 1, sensitivity = 0,
        touchpad = { natural_scroll = true, tap_to_click = true, clickfinger_behavior = true },
    },
})
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

-- cursor: draw it in software. nouveau's hardware cursor plane (legacy DRM) stops showing the cursor
-- when it sits still; software rendering keeps it always visible. Never auto-hide it.
hl.config({
    cursor = {
        no_hardware_cursors = true,
        inactive_timeout = 0,
        hide_on_key_press = false,
        hide_on_touch = false,
    },
})
