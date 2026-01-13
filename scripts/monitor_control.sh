#!/bin/bash

# =============================================================================
#  MONITOR COMMANDER
#  Target: MSI MP223 E2 | Bus ID: 2
# =============================================================================

BUS_ID=2

# Colors for UI
GREEN='\033[0;32m'
CYAN='\033[0;36m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# -----------------------------------------------------------------------------
#  Helper Functions
# -----------------------------------------------------------------------------

get_status() {
    echo -e "${CYAN}--- Current Status ---${NC}"
    # Fetch values (filtering output for cleanliness)
    local bright=$(ddcutil --bus $BUS_ID getvcp 10 | grep -oP 'current value = \s*\K\d+')
    local contrast=$(ddcutil --bus $BUS_ID getvcp 12 | grep -oP 'current value = \s*\K\d+')
    local input=$(ddcutil --bus $BUS_ID getvcp 60 | grep -oP 'sl=\s*\K0x[0-9a-fA-F]+')
    
    echo -e "Brightness: ${YELLOW}$bright%${NC}"
    echo -e "Contrast:   ${YELLOW}$contrast%${NC}"
    
    if [ "$input" == "0x11" ]; then
        echo -e "Input:      ${GREEN}HDMI-1${NC}"
    elif [ "$input" == "0x0f" ]; then
        echo -e "Input:      ${GREEN}DisplayPort${NC}"
    else
        echo -e "Input:      ${RED}Unknown ($input)${NC}"
    fi
    echo ""
    read -p "Press Enter to continue..."
}

set_monitor() {
    local b=$1 # Brightness
    local c=$2 # Contrast
    local p=$3 # Preset (Color)
    
    echo -e "${GREEN}Applying settings...${NC}"
    ddcutil --bus $BUS_ID setvcp 10 $b --noverify &
    ddcutil --bus $BUS_ID setvcp 12 $c --noverify &
    
    # Only set color if provided
    if [ ! -z "$p" ]; then
        ddcutil --bus $BUS_ID setvcp 14 $p --noverify &
    fi
    wait
    echo -e "${GREEN}Done!${NC}"
    sleep 1
}

set_rgb() {
    local r=$1
    local g=$2
    local b=$3
    echo -e "${RED}Adjusting RGB channels...${NC}"
    ddcutil --bus $BUS_ID setvcp 16 $r --noverify &
    ddcutil --bus $BUS_ID setvcp 18 $g --noverify &
    ddcutil --bus $BUS_ID setvcp 1A $b --noverify &
    wait
    echo -e "${GREEN}RGB Set!${NC}"
    sleep 1
}

# -----------------------------------------------------------------------------
#  Main Loop
# -----------------------------------------------------------------------------

while true; do
    clear
    echo -e "${CYAN}===========================================${NC}"
    echo -e "   MONITOR COMMANDER     "
    echo -e "${CYAN}===========================================${NC}"
    echo -e "${YELLOW}PRESETS:${NC}"
    echo "1) Coding / Work      (Bright: 30 | Contrast: 70 | Neutral)"
    echo "2) Movie Mode         (Bright: 90 | Contrast: 80 | Vibrant)"
    echo "3) Literal Dark Mode  (Bright: 0  | Contrast: 40 | Dim)"
    echo "4) Red Alert          (Blue Light Filter / Eye Saver)"
    echo ""
    echo -e "${YELLOW}CONTROLS:${NC}"
    echo "5) Custom Brightness"
    echo "6) Audio Controls"
    echo "7) Switch Input (HDMI <-> DP)"
    echo "8) Check Status"
    echo ""
    echo -e "${YELLOW}DISPLAY LAYOUT:${NC}"
    echo "9) Mirror Screen (Projector Mode)"
    echo "10) Extend Screen (Default)"
    echo ""
    echo "q) Quit"
    echo -e "${CYAN}===========================================${NC}"
    read -p "Select an option: " choice

    case $choice in
        1) set_monitor 30 70 0x05 ;;
        2) set_monitor 90 80 0x05 ;;
        3) set_monitor 0 40 0x05 ;;
        4) 
            # Low brightness, Standard Contrast, User Color Mode
            ddcutil --bus $BUS_ID setvcp 10 20 --noverify
            ddcutil --bus $BUS_ID setvcp 12 50 --noverify
            ddcutil --bus $BUS_ID setvcp 14 0x0B --noverify # User Mode
            # Kill Blue, Reduce Green, Boost Red
            set_rgb 100 50 0
            ;;
        5)
            echo "Fetching current brightness..."
            current_bright=$(ddcutil --bus $BUS_ID getvcp 10 | grep -oP 'current value = \s*\K\d+')
            echo -e "${CYAN}Current Brightness: ${YELLOW}$current_bright%${NC}"
            read -p "Enter new brightness (0-100): " val
            if [[ "$val" =~ ^[0-9]+$ ]] && [ "$val" -le 100 ]; then
                ddcutil --bus $BUS_ID setvcp 10 $val --noverify
            fi
            ;;
        6)
            echo ""
            echo "a) Mute"
            echo "b) Unmute"
            echo "c) Set Volume (0-100)"
            read -p "Audio choice: " aud
            case $aud in
                a) ddcutil --bus $BUS_ID setvcp 8D 0x01 --noverify ;;
                b) ddcutil --bus $BUS_ID setvcp 8D 0x02 --noverify ;;
                c) 
                   read -p "Volume: " vol
                   ddcutil --bus $BUS_ID setvcp 62 $vol --noverify 
                   ;;
            esac
            ;;
        7)
            echo "Switching Input..."
            current=$(ddcutil --bus $BUS_ID getvcp 60 | grep -oP 'sl=\s*\K0x[0-9a-fA-F]+')
            if [ "$current" == "0x11" ]; then
                ddcutil --bus $BUS_ID setvcp 60 0x0f --noverify # Switch to DP
            else
                ddcutil --bus $BUS_ID setvcp 60 0x11 --noverify # Switch to HDMI
            fi
            ;;
        8) get_status ;;
        9)
            echo -e "${YELLOW}Mirroring eDP-1 to HDMI-A-1...${NC}"
            xrandr --output HDMI-A-1 --auto --same-as eDP-1
            echo -e "${GREEN}Done!${NC}"
            sleep 1
            ;;
        10)
            echo -e "${YELLOW}Extending HDMI-A-1 to the right of eDP-1...${NC}"
            xrandr --output HDMI-A-1 --auto --right-of eDP-1
            echo -e "${GREEN}Done!${NC}"
            sleep 1
            ;;
        q|Q) echo "Exiting."; exit 0 ;;
        *) echo "Invalid option." ;;
    esac
done
