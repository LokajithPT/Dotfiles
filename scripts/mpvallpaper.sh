#!/usr/bin/env sh

lockFile="/tmp/hyde$(id -u)$(basename ${0}).lock"
[ -e "${lockFile}" ] && echo "An instance of the script is already running..." && exit 1
touch "${lockFile}"
trap 'rm -f ${lockFile}' EXIT

Wall_Cache()
{
    ln -fs "${wallList[setIndex]}" "${wallSet}"
    ln -fs "${wallList[setIndex]}" "${wallCur}"
    ln -fs "${thmbDir}/${wallHash[setIndex]}.sqre" "${wallSqr}"
    ln -fs "${thmbDir}/${wallHash[setIndex]}.thmb" "${wallTmb}"
    ln -fs "${thmbDir}/${wallHash[setIndex]}.blur" "${wallBlr}"
    ln -fs "${thmbDir}/${wallHash[setIndex]}.quad" "${wallQad}"
    ln -fs "${dcolDir}/${wallHash[setIndex]}.dcol}" "${wallDcl}"
}

Wall_Change()
{
    curWall="$(set_hash "${wallSet}")"
    for i in "${!wallHash[@]}" ; do
        if [ "${curWall}" == "${wallHash[i]}" ] ; then
            if [ "${1}" == "n" ] ; then
                setIndex=$(( (i + 1) % ${#wallList[@]} ))
            elif [ "${1}" == "p" ] ; then
                setIndex=$(( i - 1 ))
            fi
            break
        fi
    done
    Wall_Cache
}

scrDir="$(dirname "$(realpath "$0")")"
source "${scrDir}/globalcontrol.sh"
wallSet="${hydeThemeDir}/wall.set"
wallCur="${cacheDir}/wall.set"
wallSqr="${cacheDir}/wall.sqre"
wallTmb="${cacheDir}/wall.thmb"
wallBlr="${cacheDir}/wall.blur"
wallQad="${cacheDir}/wall.quad"
wallDcl="${cacheDir}/wall.dcol"

setIndex=0
[ ! -d "${hydeThemeDir}" ] && echo "ERROR: \"${hydeThemeDir}\" does not exist" && exit 0
wallPathArray=("${hydeThemeDir}")
wallPathArray+=("${wallAddCustomPath[@]}")
get_hashmap "${wallPathArray[@]}"
[ ! -e "$(readlink -f "${wallSet}")" ] && echo "fixig link :: ${wallSet}" && ln -fs "${wallList[setIndex]}" "${wallSet}"

while getopts "nps:" option ; do
    case $option in
    n )
        Wall_Change n
        ;;
    p )
        Wall_Change p
        ;;
    s )
        if [ ! -z "${OPTARG}" ] && [ -f "${OPTARG}" ] ; then
            get_hashmap "${OPTARG}"
        fi
        Wall_Cache
        ;;
    * )
        echo "... invalid option ..."
        echo "$(basename "${0}") -[option]"
        echo "n : set next wall"
        echo "p : set previous wall"
        echo "s : set input wallpaper"
        exit 1 ;;
    esac
done

wallpaper_path="$(readlink -f "${wallSet}")"

get_monitors() {
    hyprctl -j monitors | jq -r '.[] | .name'
}

apply_mpvpaper() {
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

echo ":: applying wall :: \"${wallpaper_path}\""

for monitor in $(get_monitors); do
    apply_mpvpaper "${monitor}" "${wallpaper_path}"
done