#!/usr/bin/env sh

scrDir="$(dirname "$(realpath "$0")")"
source "${scrDir}/globalcontrol.sh"

wallpaper_path="${hydeThemeDir}/wall.set"

get_monitors() {
    hyprctl -j monitors | jq -r '.[] | .name'
}

is_animated() {
    case "${1}" in
        *.gif|*.mp4|*.webm|*.avi) return 0 ;;
        *) return 1 ;;
    esac
}

start_wallpaper() {
    local monitor="$1"
    local wallpaper="$2"
    
    if [ -f "${wallpaper}" ]; then
        if is_animated "${wallpaper}"; then
            mpvpaper -v -o "loop" "${monitor}" "${wallpaper}" &
        else
            swww img "${wallpaper}" --outputs "${monitor}" 2>/dev/null || swww img "${wallpaper}"
        fi
    fi
}

pkill -f "mpvpaper" 2>/dev/null
swww query 2>/dev/null || swww-daemon &
sleep 0.3

for monitor in $(get_monitors); do
    start_wallpaper "${monitor}" "$(readlink -f "${wallpaper_path}")"
done