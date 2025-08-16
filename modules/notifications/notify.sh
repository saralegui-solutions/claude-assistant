#!/bin/bash

# Read the JSON input from stdin
input=$(cat)

# Extract the event type from JSON (using jq if available, or simple grep)
event_type=$(echo "$input" | grep -o '"event":"[^"]*"' | cut -d'"' -f4)

# Define sound file paths (using Windows-accessible location)
HEART_SOUND="C:\\temp\\claude-notifications\\OOT_Get_Heart.wav"
ITEM_SOUND="C:\\temp\\claude-notifications\\OOT_Get_SmallItem1.wav"

# Function to play sound in background without blocking
play_sound() {
    local sound_file="$1"
    # Use Start-Process to launch sound in separate process that won't be killed
    powershell.exe -WindowStyle Hidden -Command "
        Start-Process powershell -ArgumentList '-WindowStyle Hidden -Command \"(New-Object System.Media.SoundPlayer ''$sound_file'').PlaySync()\"' -NoNewWindow
    " 2>/dev/null &
}

# Play different sounds based on event type
case "$event_type" in
    "Notification")
        # Play item sound when Claude needs attention
        play_sound "$ITEM_SOUND"
        ;;
    "Stop")
        # Play heart sound when Claude finishes
        play_sound "$HEART_SOUND"
        ;;
    *)
        # Default to item sound
        play_sound "$ITEM_SOUND"
        ;;
esac

# Pass through the input unchanged immediately
echo "$input"