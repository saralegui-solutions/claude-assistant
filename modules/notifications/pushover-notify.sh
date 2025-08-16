#!/bin/bash

# Read the JSON input from stdin
input=$(cat)

# Extract the event type from JSON
event_type=$(echo "$input" | grep -o '"event":"[^"]*"' | cut -d'"' -f4)

# Load configuration from .env file or environment variables
CONFIG_FILE="$HOME/.claude/pushover.env"
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

# Check if credentials are set
if [ -z "$PUSHOVER_USER_KEY" ] || [ -z "$PUSHOVER_APP_TOKEN" ]; then
    echo "Error: Pushover credentials not configured" >&2
    echo "Please set PUSHOVER_USER_KEY and PUSHOVER_APP_TOKEN in $CONFIG_FILE" >&2
    echo "$input"
    exit 0
fi

# Set default priorities if not configured
NOTIFICATION_PRIORITY=${NOTIFICATION_PRIORITY:-1}
STOP_PRIORITY=${STOP_PRIORITY:-0}

# Function to send Pushover notification
send_pushover() {
    local title="$1"
    local message="$2"
    local priority="$3"
    local sound="$4"
    
    curl -s \
        --form-string "token=$PUSHOVER_APP_TOKEN" \
        --form-string "user=$PUSHOVER_USER_KEY" \
        --form-string "title=$title" \
        --form-string "message=$message" \
        --form-string "priority=$priority" \
        --form-string "sound=$sound" \
        https://api.pushover.net/1/messages.json > /dev/null 2>&1 &
}

# Get current directory name for context
CURRENT_DIR=$(basename "$PWD")

# Send different notifications based on event type
# Using custom Zelda sounds:
# - "OOT-Get-Small-Item-1" for item pickup (when Claude needs attention)
# - "OOT-Get-Heart" for achievement/heart (when Claude completes)
case "$event_type" in
    "Notification")
        # Claude needs attention - like picking up an item
        send_pushover \
            "🔔 Claude needs your input" \
            "Claude is waiting for your response in: $CURRENT_DIR" \
            "$NOTIFICATION_PRIORITY" \
            "OOT-Get-Small-Item-1"
        ;;
    "Stop")
        # Claude finished task - like getting a heart/achievement  
        send_pushover \
            "✅ Claude completed task" \
            "Task finished in: $CURRENT_DIR" \
            "$STOP_PRIORITY" \
            "OOT-Get-Heart"
        ;;
    "UserPromptSubmit")
        # User submitted a prompt (optional tracking)
        # Uncomment if you want to track when prompts are submitted
        # send_pushover \
        #     "📝 Prompt submitted" \
        #     "New task started in: $CURRENT_DIR" \
        #     "-1" \
        #     "OOT-Get-Small-Item-1"
        ;;
    *)
        # Other events - you can customize as needed
        send_pushover \
            "Claude Event: $event_type" \
            "Event occurred in: $CURRENT_DIR" \
            "0" \
            "OOT-Get-Small-Item-1"
        ;;
esac

# Pass through the input unchanged
echo "$input"