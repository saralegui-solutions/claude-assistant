#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}                       Claude Notifications Quick Setup                           ${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Function to check if we have Pushover credentials
check_env_file() {
    if [ -f ".env" ]; then
        source .env
        if [ -n "$PUSHOVER_USER_KEY" ] && [ -n "$PUSHOVER_APP_TOKEN" ] && 
           [ "$PUSHOVER_USER_KEY" != "your_user_key_here" ] && 
           [ "$PUSHOVER_APP_TOKEN" != "your_app_token_here" ]; then
            return 0
        fi
    fi
    return 1
}

# Function to check existing installation
check_existing_installation() {
    if [ -f "$HOME/.claude/hooks/pushover-notify.sh" ] || [ -f "$HOME/.claude/hooks/notify.sh" ]; then
        echo -e "${YELLOW}⚠️  Existing Claude notification hooks detected${NC}"
        read -p "Replace existing configuration? (y/N): " replace
        if [[ ! "$replace" =~ ^[Yy]$ ]]; then
            echo "Installation cancelled."
            exit 0
        fi
        # Backup existing settings
        if [ -f "$HOME/.claude/settings.json" ]; then
            cp "$HOME/.claude/settings.json" "$HOME/.claude/settings.json.backup.$(date +%Y%m%d_%H%M%S)"
            echo -e "${GREEN}✓ Backed up existing settings${NC}"
        fi
    fi
}

# Check for existing installation
check_existing_installation

# Create necessary directories
mkdir -p "$HOME/.claude/hooks"

echo -e "${BLUE}Choose notification method:${NC}"
echo "1) Pushover (mobile notifications) - Recommended"
echo "2) Sound notifications (local only)"
echo ""
read -p "Enter choice [1]: " choice
choice=${choice:-1}

if [ "$choice" = "2" ]; then
    # Sound notifications setup
    echo -e "${YELLOW}Setting up sound notifications...${NC}"
    ./install.sh
    exit 0
fi

# Pushover setup
echo ""
echo -e "${BLUE}Setting up Pushover mobile notifications...${NC}"
echo ""

# Check for .env file in repo
if check_env_file; then
    echo -e "${GREEN}✓ Found Pushover credentials in .env file${NC}"
else
    # Check for credentials in current environment
    if [ -n "$PUSHOVER_USER_KEY" ] && [ -n "$PUSHOVER_APP_TOKEN" ] && 
       [ "$PUSHOVER_USER_KEY" != "your_user_key_here" ]; then
        echo -e "${GREEN}✓ Using Pushover credentials from environment${NC}"
    else
        # Need to get credentials
        echo -e "${YELLOW}Pushover credentials needed!${NC}"
        echo ""
        echo "To get your credentials:"
        echo "1. Sign up at: https://pushover.net/ (if you don't have an account)"
        echo "2. Get your User Key from: https://pushover.net/dashboard"
        echo "3. Create an App Token at: https://pushover.net/apps/build"
        echo "   - Name it: 'Claude Notifications'"
        echo "   - Type: Application"
        echo ""
        
        # Offer options
        echo "How would you like to provide credentials?"
        echo "1) Enter them now"
        echo "2) I'll add them to .env file manually"
        echo ""
        read -p "Choice [1]: " cred_choice
        cred_choice=${cred_choice:-1}
        
        if [ "$cred_choice" = "1" ]; then
            read -p "Enter your Pushover User Key: " user_key
            read -p "Enter your Pushover App Token: " app_token
            
            # Save to .env file
            cat > "$SCRIPT_DIR/.env" << EOF
# Pushover API Configuration
PUSHOVER_USER_KEY=$user_key
PUSHOVER_APP_TOKEN=$app_token

# Optional: Different priority levels for different events
# -2 = lowest, -1 = low, 0 = normal, 1 = high, 2 = emergency
NOTIFICATION_PRIORITY=1
STOP_PRIORITY=0
EOF
            echo -e "${GREEN}✓ Credentials saved to .env${NC}"
            source "$SCRIPT_DIR/.env"
        else
            # Create template .env file
            cp "$SCRIPT_DIR/.env.example" "$SCRIPT_DIR/.env" 2>/dev/null || \
            cat > "$SCRIPT_DIR/.env" << 'EOF'
# Pushover API Configuration
PUSHOVER_USER_KEY=your_user_key_here
PUSHOVER_APP_TOKEN=your_app_token_here

# Optional: Different priority levels for different events
# -2 = lowest, -1 = low, 0 = normal, 1 = high, 2 = emergency
NOTIFICATION_PRIORITY=1
STOP_PRIORITY=0
EOF
            echo ""
            echo -e "${YELLOW}Please edit .env file with your credentials:${NC}"
            echo "  $SCRIPT_DIR/.env"
            echo ""
            echo "Then run this script again: ./setup.sh"
            exit 0
        fi
    fi
fi

# Copy credentials to Claude config directory
echo -e "${BLUE}Installing Pushover configuration...${NC}"
cat > "$HOME/.claude/pushover.env" << EOF
# Pushover API Configuration
PUSHOVER_USER_KEY="$PUSHOVER_USER_KEY"
PUSHOVER_APP_TOKEN="$PUSHOVER_APP_TOKEN"

# Notification priorities
NOTIFICATION_PRIORITY=${NOTIFICATION_PRIORITY:-1}
STOP_PRIORITY=${STOP_PRIORITY:-0}
EOF
chmod 600 "$HOME/.claude/pushover.env"
echo -e "${GREEN}✓ Credentials configured${NC}"

# Install hook script
cp "$SCRIPT_DIR/hooks/pushover-notify.sh" "$HOME/.claude/hooks/pushover-notify.sh"
chmod +x "$HOME/.claude/hooks/pushover-notify.sh"
echo -e "${GREEN}✓ Hook script installed${NC}"

# Update Claude settings
echo -e "${BLUE}Updating Claude settings...${NC}"
python3 << 'EOF'
import json
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

settings['hooks']['Notification'] = hook_config
settings['hooks']['Stop'] = hook_config

# Write updated settings
with open(settings_path, 'w') as f:
    json.dump(settings, f, indent=2)

print("✓ Claude settings updated")
EOF

# Test the setup
echo ""
echo -e "${BLUE}Testing Pushover notifications...${NC}"
response=$(curl -s \
    --form-string "token=$PUSHOVER_APP_TOKEN" \
    --form-string "user=$PUSHOVER_USER_KEY" \
    --form-string "title=🎉 Claude Notifications Active" \
    --form-string "message=You'll now receive notifications when Claude needs your attention or completes tasks!" \
    --form-string "priority=0" \
    --form-string "sound=magic" \
    https://api.pushover.net/1/messages.json)

if echo "$response" | grep -q '"status":1'; then
    echo -e "${GREEN}✅ Test notification sent successfully!${NC}"
    echo -e "${GREEN}   Check your Pushover app!${NC}"
else
    echo -e "${RED}⚠️  Failed to send test notification${NC}"
    echo "Response: $response"
    echo ""
    echo "Please check:"
    echo "1. Your credentials are correct"
    echo "2. You have the Pushover app installed"
    echo "3. Your internet connection is working"
fi

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}                         Setup Complete! 🎉                                      ${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "You'll receive Pushover notifications when:"
echo "  📱 Claude needs your input (high priority)"
echo "  ✅ Claude completes tasks (normal priority)"
echo ""
echo "To uninstall: ./uninstall-pushover.sh"
echo ""