#!/usr/bin/env sh

scrDir="$(dirname "$(realpath "$0")")"
source "${scrDir}/globalcontrol.sh"

wallpaper_path="${hydeThemeDir}/wall.set"

get_monitors() {
    hyprctl -j monitors | jq -r '.[] | .name'
}

start_mpvpaper() {
    local monitor="$1"
    local wallpaper="$2"
    
    pkill -f "mpvpaper ${monitor}" 2>/dev/null
    
    if [ -f "${wallpaper}" ]; then
        case "${wallpaper}" in
            *.gif|*.mp4|*.webm|*.avi)
                mpvpaper -v -o "loop" "${monitor}" "${wallpaper}" &
                ;;
            *.jpg|*.jpeg|*.png)
                mpvpaper -v -o "loop no-audio" "${monitor}" "${wallpaper}" &
                ;;
        esac
    fi
}

for monitor in $(get_monitors); do
    start_mpvpaper "${monitor}" "$(readlink -f "${wallpaper_path}")"
done