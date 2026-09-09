#!/usr/bin/env bash

current=$(hyprctl getprop activewindow opacity) || exit 1

if [[ $current == 0 || $current == 0.* ]]; then
  opacity="1.0 override 1.0 override 1.0 override"
else
  opacity="0.9 override 0.9 override 1.0 override"
fi

hyprctl eval "hl.dispatch(hl.dsp.window.set_prop({ prop = 'opacity', value = '$opacity' }))"
