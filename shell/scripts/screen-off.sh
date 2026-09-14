#!/usr/bin/env bash
# screen-off.sh — darken the panel without suspending (lock-screen moon button, idle timeout).
# Uses the BACKLIGHT only, on purpose: a real DPMS-off lets nouveau runtime-suspend the RTX 3080 Ti, and its
# GSP firmware fails to come back (-110, 2026-09-13 + 2026-09-14) -> black screen until reboot. Backlight 0 keeps
# the GPU awake. Wake it with the brightness keys (bound with locked=true) or `brightnessctl -r`.
brightnessctl -q -s set 0
