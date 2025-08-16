#!/bin/bash

echo "🗑️  Claude Notifications Uninstaller"
echo "==================================="
echo ""

# Remove hook script
if [ -f "$HOME/.claude/hooks/notify.sh" ]; then
    echo "Removing hook script..."
    rm "$HOME/.claude/hooks/notify.sh"
fi

# Remove sounds from home directory (non-WSL)
if [ -d "$HOME/.claude/sounds" ]; then
    echo "Removing sound files..."
    rm -rf "$HOME/.claude/sounds"
fi

# Remove sounds from Windows temp (WSL)
if command -v wslpath &> /dev/null && [ -d "/mnt/c/temp/claude-notifications" ]; then
    echo "Removing Windows sound files..."
    rm -rf /mnt/c/temp/claude-notifications
fi

# Clean up settings.json
if [ -f "$HOME/.claude/settings.json" ]; then
    echo "Cleaning up settings..."
    
    # Create a Python script to remove hooks from settings
    cat > /tmp/remove_claude_hooks.py << 'EOF'
import json
import os

settings_path = os.path.expanduser("~/.claude/settings.json")

try:
    with open(settings_path, 'r') as f:
        settings = json.load(f)
    
    # Remove notification hooks
    if 'hooks' in settings:
        if 'Notification' in settings['hooks']:
            del settings['hooks']['Notification']
        if 'Stop' in settings['hooks']:
            del settings['hooks']['Stop']
        
        # If hooks is empty, remove it
        if not settings['hooks']:
            del settings['hooks']
    
    # Write back if there's still content
    if settings:
        with open(settings_path, 'w') as f:
            json.dump(settings, f, indent=2)
        print("Hooks removed from settings")
    else:
        # Remove empty settings file
        os.remove(settings_path)
        print("Empty settings file removed")
        
except Exception as e:
    print(f"Could not clean settings: {e}")
EOF
    
    python3 /tmp/remove_claude_hooks.py
    rm /tmp/remove_claude_hooks.py
fi

echo ""
echo "✅ Uninstallation complete!"
echo ""
echo "Note: Backup files (*.backup.*) were not removed."
echo "You can manually delete them from ~/.claude/ if desired."
echo ""