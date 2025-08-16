#!/bin/bash

set -e

echo "📱 Claude Pushover Notifications Installer"
echo "========================================="
echo ""

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Create claude directory if it doesn't exist
mkdir -p "$HOME/.claude/hooks"

# Function to backup existing settings
backup_settings() {
    if [ -f "$HOME/.claude/settings.json" ]; then
        echo "Backing up existing settings..."
        cp "$HOME/.claude/settings.json" "$HOME/.claude/settings.json.backup.$(date +%Y%m%d_%H%M%S)"
    fi
}

# Check for existing Pushover configuration
check_pushover_config() {
    if [ -f "$HOME/.claude/pushover.env" ]; then
        echo "Found existing Pushover configuration"
        source "$HOME/.claude/pushover.env"
        if [ -n "$PUSHOVER_USER_KEY" ] && [ -n "$PUSHOVER_APP_TOKEN" ]; then
            echo "✓ Pushover credentials are configured"
            return 0
        fi
    fi
    return 1
}

# Setup Pushover credentials
setup_pushover_credentials() {
    echo ""
    echo "Setting up Pushover credentials..."
    echo "You'll need:"
    echo "1. A Pushover account (https://pushover.net/)"
    echo "2. Your User Key (from https://pushover.net/dashboard)"
    echo "3. An Application Token (create at https://pushover.net/apps/build)"
    echo ""
    
    read -p "Enter your Pushover User Key: " user_key
    read -p "Enter your Pushover Application Token: " app_token
    
    # Optional priority settings
    echo ""
    echo "Optional: Set notification priorities"
    echo "(-2=lowest, -1=low, 0=normal, 1=high, 2=emergency)"
    read -p "Priority for 'needs attention' notifications [1]: " notif_priority
    notif_priority=${notif_priority:-1}
    read -p "Priority for 'task complete' notifications [0]: " stop_priority
    stop_priority=${stop_priority:-0}
    
    # Save configuration
    cat > "$HOME/.claude/pushover.env" << EOF
# Pushover API Configuration
PUSHOVER_USER_KEY="$user_key"
PUSHOVER_APP_TOKEN="$app_token"

# Notification priorities
NOTIFICATION_PRIORITY=$notif_priority
STOP_PRIORITY=$stop_priority
EOF
    
    chmod 600 "$HOME/.claude/pushover.env"
    echo "✓ Pushover credentials saved to ~/.claude/pushover.env"
}

# Copy hook script
echo "Installing Pushover hook script..."
cp "$SCRIPT_DIR/hooks/pushover-notify.sh" "$HOME/.claude/hooks/pushover-notify.sh"
chmod +x "$HOME/.claude/hooks/pushover-notify.sh"

# Check or setup Pushover credentials
if ! check_pushover_config; then
    setup_pushover_credentials
fi

# Backup and update settings
backup_settings

# Create or update settings.json
echo ""
echo "Updating Claude settings..."

# Create temporary Python script to update settings
cat > /tmp/update_claude_pushover.py << 'EOF'
import json
import sys
import os

settings_path = os.path.expanduser("~/.claude/settings.json")

# Read existing settings
try:
    with open(settings_path, 'r') as f:
        settings = json.load(f)
except:
    settings = {}

# Ensure hooks section exists
if 'hooks' not in settings:
    settings['hooks'] = {}

# Add Pushover notification hooks
hook_config = [
    {
        "matcher": ".*",
        "hooks": [
            {
                "type": "command",
                "command": os.path.expanduser("~/.claude/hooks/pushover-notify.sh"),
                "timeout": 5000
            }
        ]
    }
]

# Configure for multiple event types
settings['hooks']['Notification'] = hook_config
settings['hooks']['Stop'] = hook_config
# Optional: Enable for all events
# settings['hooks']['UserPromptSubmit'] = hook_config
# settings['hooks']['PreToolUse'] = hook_config
# settings['hooks']['PostToolUse'] = hook_config

# Write updated settings
with open(settings_path, 'w') as f:
    json.dump(settings, f, indent=2)

print("Settings updated successfully!")
EOF

python3 /tmp/update_claude_pushover.py
rm /tmp/update_claude_pushover.py

# Test the notifications
echo ""
echo "Testing Pushover notifications..."
echo ""

# Load the configuration for testing
source "$HOME/.claude/pushover.env"

echo "Sending test notification..."
response=$(curl -s \
    --form-string "token=$PUSHOVER_APP_TOKEN" \
    --form-string "user=$PUSHOVER_USER_KEY" \
    --form-string "title=🎉 Claude Pushover Setup Complete" \
    --form-string "message=You'll now receive notifications when Claude needs your attention or completes tasks!" \
    --form-string "priority=0" \
    --form-string "sound=magic" \
    https://api.pushover.net/1/messages.json)

if echo "$response" | grep -q '"status":1'; then
    echo "✅ Test notification sent successfully!"
    echo "Check your Pushover app!"
else
    echo "⚠️ Failed to send test notification"
    echo "Response: $response"
    echo "Please check your credentials in ~/.claude/pushover.env"
fi

echo ""
echo "✅ Installation complete!"
echo ""
echo "You'll receive Pushover notifications when:"
echo "  📱 Claude needs your input (high priority)"
echo "  ✅ Claude completes tasks (normal priority)"
echo ""
echo "To modify settings, edit: ~/.claude/pushover.env"
echo "To uninstall, run: ./uninstall-pushover.sh"
echo ""