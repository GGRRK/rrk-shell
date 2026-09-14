#!/usr/bin/env bash
# screen-off.sh — turn the panel off without suspending (lock-screen moon button, "Screen off" buttons, idle timeout).
# Real DPMS off. Safe since nouveau.runpm=0 (2026-09-14, verified: the GPU no longer powers down, so the panel comes back).
# The backlight route (brightnessctl 0) is NOT an option on this laptop: under nouveau the EC accepts the value but the
# panel never changes (only the NVIDIA driver applies it) — see memory/fix-backlight-dead-nouveau.md.
# Any key press or mouse move turns the screen back on (misc.key_press_enables_dpms / mouse_move_enables_dpms in look.lua);
# the short sleep keeps the click that triggered this from waking it straight away.
sleep 0.4
exec hyprctl dispatch 'hl.dsp.dpms({action = "off"})'
