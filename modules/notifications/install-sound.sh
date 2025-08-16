#!/bin/bash

set -e

echo "🎵 Claude Notifications Installer"
echo "================================"
echo ""

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Detect OS
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]] && command -v wslpath &> /dev/null; then
        echo "wsl"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"
    else
        echo "unknown"
    fi
}

OS_TYPE=$(detect_os)
echo "Detected OS: $OS_TYPE"
echo ""

# Function to backup existing settings
backup_settings() {
    if [ -f "$HOME/.claude/settings.json" ]; then
        echo "Backing up existing settings..."
        cp "$HOME/.claude/settings.json" "$HOME/.claude/settings.json.backup.$(date +%Y%m%d_%H%M%S)"
    fi
}

# Function to install for WSL
install_wsl() {
    echo "Installing for WSL..."
    
    # Copy sounds to Windows temp directory
    echo "Copying sound files to Windows..."
    mkdir -p /mnt/c/temp/claude-notifications
    cp "$SCRIPT_DIR/sounds/"*.wav /mnt/c/temp/claude-notifications/
    
    # Test if PowerShell can access the files
    if powershell.exe -Command "Test-Path 'C:\\temp\\claude-notifications\\OOT_Get_Heart.wav'" | grep -q "True"; then
        echo "✓ Sound files copied successfully"
    else
        echo "⚠ Warning: Could not verify sound files in Windows. They may not play correctly."
    fi
}

# Function to install for macOS
install_macos() {
    echo "Installing for macOS..."
    
    # Check if afplay is available
    if ! command -v afplay &> /dev/null; then
        echo "⚠ Warning: afplay not found. Sounds may not play."
    else
        echo "✓ afplay found"
    fi
}

# Function to install for Linux
install_linux() {
    echo "Installing for Linux..."
    
    # Check for audio players
    if command -v paplay &> /dev/null; then
        echo "✓ Found paplay (PulseAudio)"
    elif command -v aplay &> /dev/null; then
        echo "✓ Found aplay (ALSA)"
    elif command -v play &> /dev/null; then
        echo "✓ Found play (SoX)"
    else
        echo "⚠ Warning: No compatible audio player found."
        echo "  Please install one of: pulseaudio-utils, alsa-utils, or sox"
    fi
}

# Create claude directory if it doesn't exist
mkdir -p "$HOME/.claude/hooks"

# Copy hook script
echo "Installing hook script..."
cp "$SCRIPT_DIR/hooks/notify.sh" "$HOME/.claude/hooks/notify.sh"
chmod +x "$HOME/.claude/hooks/notify.sh"

# OS-specific installation
case $OS_TYPE in
    wsl)
        install_wsl
        ;;
    macos)
        install_macos
        ;;
    linux)
        install_linux
        ;;
    *)
        echo "⚠ Unknown OS type. Installation may not work correctly."
        ;;
esac

# For non-WSL systems, copy sounds to home directory
if [ "$OS_TYPE" != "wsl" ]; then
    echo "Copying sound files..."
    mkdir -p "$HOME/.claude/sounds"
    cp "$SCRIPT_DIR/sounds/"*.wav "$HOME/.claude/sounds/"
fi

# Backup and update settings
backup_settings

# Create or update settings.json
echo ""
echo "Updating Claude settings..."

# Check if settings.json exists
if [ -f "$HOME/.claude/settings.json" ]; then
    # Settings file exists, we need to merge
    echo "Merging with existing settings..."
    
    # Create a temporary Python script to merge JSON
    cat > /tmp/merge_claude_settings.py << 'EOF'
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

# Add notification hooks
hook_config = [
    {
        "matcher": ".*",
        "hooks": [
            {
                "type": "command",
                "command": os.path.expanduser("~/.claude/hooks/notify.sh"),
                "timeout": 2000
            }
        ]
    }
]

settings['hooks']['Notification'] = hook_config
settings['hooks']['Stop'] = hook_config

# Write updated settings
with open(settings_path, 'w') as f:
    json.dump(settings, f, indent=2)

print("Settings updated successfully!")
EOF
    
    python3 /tmp/merge_claude_settings.py
    rm /tmp/merge_claude_settings.py
else
    # No existing settings, create new
    cat > "$HOME/.claude/settings.json" << EOF
{
  "hooks": {
    "Notification": [
      {
        "matcher": ".*",
        "hooks": [
          {
            "type": "command",
            "command": "$HOME/.claude/hooks/notify.sh",
            "timeout": 2000
          }
        ]
      }
    ],
    "Stop": [
      {
        "matcher": ".*",
        "hooks": [
          {
            "type": "command",
            "command": "$HOME/.claude/hooks/notify.sh",
            "timeout": 2000
          }
        ]
      }
    ]
  }
}
EOF
    echo "Created new settings file"
fi

# Test the installation
echo ""
echo "Testing notification sounds..."
echo ""

echo "Testing 'Notification' sound (item pickup)..."
echo '{"event":"Notification","message":"Test"}' | "$HOME/.claude/hooks/notify.sh" > /dev/null
sleep 1

echo "Testing 'Stop' sound (heart)..."
echo '{"event":"Stop","message":"Test"}' | "$HOME/.claude/hooks/notify.sh" > /dev/null

echo ""
echo "✅ Installation complete!"
echo ""
echo "The following sounds will play:"
echo "  • Small Item sound - When Claude needs your attention"
echo "  • Heart sound - When Claude completes tasks"
echo ""
echo "To uninstall, run: ./uninstall.sh"
echo ""