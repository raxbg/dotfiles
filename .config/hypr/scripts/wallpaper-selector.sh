#!/usr/bin/env bash

set -euo pipefail

wallpaper_dir="$HOME/Pictures/Wallpapers"
state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/hypr"
state_file="$state_dir/wallpaper"

apply_wallpaper() {
    local wallpaper="$1"

    [[ -f "$wallpaper" ]] || return 1

    printf '%s\n' "$wallpaper" > "$state_file"
    awww img "$wallpaper" --transition-type wipe --transition-fps 75 --transition-step 255 >/dev/null 2>&1
    notify-send "Wallpaper changed" "$(basename "$wallpaper")" -t 3000
}

if [[ "${1:-}" == "--restore" ]]; then
    [[ -r "$state_file" ]] && apply_wallpaper "$(<"$state_file")"
    exit 0
fi

if [[ ! -d "$wallpaper_dir" ]]; then
    notify-send "Wallpaper selector" "Directory not found: $wallpaper_dir" -u critical
    exit 1
fi

if [[ "${1:-}" == "--rofi" ]]; then
    if [[ -n "${2:-}" ]]; then
        apply_wallpaper "$wallpaper_dir/$2"
        exit 0
    fi

    find "$wallpaper_dir" -maxdepth 1 -type f \
        \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.gif' -o -iname '*.webp' \) \
        -printf '%f\0icon\037%p\n'
    exit 0
fi

selected=$(find "$wallpaper_dir" -maxdepth 1 -type f \
    \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.gif' -o -iname '*.webp' \) \
    -printf '%f\0icon\037%p\n' | \
    rofi -dmenu -show-icons -p "Wallpaper" -config "$HOME/.config/rofi/wallpaper-selector.rasi")

[[ -n "$selected" ]] && apply_wallpaper "$wallpaper_dir/$selected"
