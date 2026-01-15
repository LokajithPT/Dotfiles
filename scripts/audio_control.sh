#!/bin/bash

# =============================================================================
#  AUDIO COMMANDER
#  Smart Audio Switching for Arch Linux (PipeWire/PulseAudio)
# =============================================================================

# --- Configuration ---
CARD_NAME="alsa_card.pci-0000_00_1f.3-platform-skl_hda_dsp_generic"

# Profile Names (Exact match from 'pactl list cards')
PROF_HP="HiFi (HDMI1, HDMI2, HDMI3, Headphones, Mic1, Mic2)"
PROF_SPK="HiFi (HDMI1, HDMI2, HDMI3, Mic1, Mic2, Speaker)"

# Sink Names (These appear/disappear based on the active profile)
SINK_HP="alsa_output.pci-0000_00_1f.3-platform-skl_hda_dsp_generic.HiFi__Headphones__sink"
SINK_INT_SPK="alsa_output.pci-0000_00_1f.3-platform-skl_hda_dsp_generic.HiFi__Speaker__sink"

# Colors
GREEN='\033[0;32m'
CYAN='\033[0;36m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# --- Functions ---

# Switch to Internal Headphones
use_hp() {
    echo -e "${YELLOW}Switching to Headphones...${NC}"
    # 1. Set the card profile to enable headphones
    pactl set-card-profile "$CARD_NAME" "$PROF_HP" 2>/dev/null
    
    # 2. Wait a split second for the sink to appear
    sleep 0.2
    
    # 3. Set the sink as default
    pactl set-default-sink "$SINK_HP"
    
    # 4. Unmute just in case
    pactl set-sink-mute "$SINK_HP" 0
    
    echo -e "${GREEN}🎧 Audio Output: Headphones${NC}"
}

# Switch to Internal Laptop Speakers
use_laptop() {
    echo -e "${YELLOW}Switching to Laptop Speakers...${NC}"
    # 1. Set the card profile to enable speakers
    pactl set-card-profile "$CARD_NAME" "$PROF_SPK" 2>/dev/null
    
    # 2. Wait a split second
    sleep 0.2
    
    # 3. Set the sink as default
    pactl set-default-sink "$SINK_INT_SPK"
    
    # 4. Unmute
    pactl set-sink-mute "$SINK_INT_SPK" 0
    
    echo -e "${GREEN}💻 Audio Output: Laptop Speakers${NC}"
}

# Switch to USB Speakers (Smart Detect)
use_usb() {
    echo -e "${YELLOW}Searching for USB Speakers...${NC}"
    
    # Find any sink with "usb" in the name
    local usb_sink=$(pactl list short sinks | grep "usb" | awk '{print $2}' | head -n 1)
    
    if [ -z "$usb_sink" ]; then
        echo -e "${RED}❌ No USB Speakers found!${NC}"
        return 1
    fi
    
    # Set it as default
    pactl set-default-sink "$usb_sink"
    pactl set-sink-mute "$usb_sink" 0
    echo -e "${GREEN}🔊 Audio Output: USB Speakers ($usb_sink)${NC}"
    return 0
}

# Toggle Logic
toggle() {
    # Get current default sink name
    local current=$(pactl get-default-sink)
    
    if [[ "$current" == *"$SINK_HP"* ]]; then
        # If currently HP, try USB, then Laptop
        use_usb || use_laptop
    elif [[ "$current" == *"usb"* ]]; then
        # If currently USB, go to Laptop
        use_laptop
    else
        # If currently Laptop (or unknown), go to HP
        use_hp
    fi
}

# --- Main Execution ---

case "$1" in
    hp)
        use_hp
        ;;
    laptop)
        use_laptop
        ;;
    spk)
        use_usb
        # If USB fails, fallback to laptop speakers per user request
        if [ $? -ne 0 ]; then
             echo -e "${CYAN}Falling back to Laptop Speakers...${NC}"
             use_laptop
        fi
        ;;
    *)
        # Default behavior: Toggle
        echo -e "${CYAN}Toggling Audio Output...${NC}"
        toggle
        ;;
esac
