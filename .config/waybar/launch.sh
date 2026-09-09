#!/usr/bin/env bash

set -euo pipefail

config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/waybar"
runtime_dir="${XDG_RUNTIME_DIR:-/tmp}/waybar"

# Treat the monitor placed at the layout origin as the main display.
WAYBAR_OUTPUT=$(hyprctl monitors -j | jq -er '([.[] | select(.x == 0 and .y == 0)][0] // .[0]).name')
export WAYBAR_OUTPUT

install -d -m 700 "$runtime_dir"
envsubst '${WAYBAR_OUTPUT}' < "$config_dir/config" > "$runtime_dir/config"

exec waybar --config "$runtime_dir/config" --style "$config_dir/style.css"
