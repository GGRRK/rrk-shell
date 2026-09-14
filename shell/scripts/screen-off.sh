#!/usr/bin/env bash
# screen-off.sh — turn the panel off without suspending (lock-screen moon button).
# Suspend on nouveau left the screen black on 2026-09-13; DPMS off is the safe alternative.
# Any key press / mouse move turns it back on (misc.key_press_enables_dpms / mouse_move_enables_dpms in look.lua).
exec hyprctl dispatch 'hl.dsp.dpms("off")'
