#!/usr/bin/env bash

current=$(hyprctl getprop activewindow opacity)

if (( $(echo "$current < 0.99" | bc -l) )); then
  hyprctl dispatch setprop activewindow opacity 1.0 override
  hyprctl dispatch setprop activewindow opacity_inactive 1.0 override
  hyprctl dispatch setprop activewindow opacity_fullscreen 1.0 override
else
  hyprctl dispatch setprop activewindow opacity 0.9 override
  hyprctl dispatch setprop activewindow opacity_inactive 0.9 override
  hyprctl dispatch setprop activewindow opacity_fullscreen 1.0 override
fi
