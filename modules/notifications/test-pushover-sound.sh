#!/bin/bash

# Test script to send Pushover notification with custom sound attachment

# Load configuration
CONFIG_FILE="$HOME/.claude/pushover.env"
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

# Check if credentials are set
if [ -z "$PUSHOVER_USER_KEY" ] || [ -z "$PUSHOVER_APP_TOKEN" ]; then
    echo "Error: Pushover credentials not configured"
    echo "Please set PUSHOVER_USER_KEY and PUSHOVER_APP_TOKEN in $CONFIG_FILE"
    exit 1
fi

# Send test notification with custom sound attachment
# Note: Pushover supports attaching audio files up to 2.5MB
SOUND_FILE="/home/ben/claude-notifications/sounds/OOT_Get_Heart.mp3"

if [ -f "$SOUND_FILE" ]; then
    echo "Sending test notification with custom sound..."
    
    # Send notification with attachment
    response=$(curl -s \
        --form-string "token=$PUSHOVER_APP_TOKEN" \
        --form-string "user=$PUSHOVER_USER_KEY" \
        --form-string "title=Claude Code Test" \
        --form-string "message=Testing custom notification sound from Claude Code" \
        --form-string "priority=0" \
        --form "attachment=@$SOUND_FILE" \
        https://api.pushover.net/1/messages.json)
    
    echo "Response: $response"
    
    # Check if successful
    if echo "$response" | grep -q '"status":1'; then
        echo "✅ Test notification sent successfully!"
    else
        echo "❌ Failed to send notification"
    fi
else
    echo "Sound file not found: $SOUND_FILE"
    exit 1
fi