#!/bin/bash

echo "🗑️  Claude Pushover Notifications Uninstaller"
echo "============================================"
echo ""

# Remove hook script
if [ -f "$HOME/.claude/hooks/pushover-notify.sh" ]; then
    echo "Removing Pushover hook script..."
    rm "$HOME/.claude/hooks/pushover-notify.sh"
fi

# Optionally remove Pushover credentials
read -p "Remove Pushover credentials file? (y/N): " remove_creds
if [[ "$remove_creds" =~ ^[Yy]$ ]]; then
    if [ -f "$HOME/.claude/pushover.env" ]; then
        echo "Removing Pushover credentials..."
        rm "$HOME/.claude/pushover.env"
    fi
else
    echo "Keeping Pushover credentials at ~/.claude/pushover.env"
fi

# Clean up settings.json
if [ -f "$HOME/.claude/settings.json" ]; then
    echo "Cleaning up settings..."
    
    # Create a Python script to remove hooks from settings
    cat > /tmp/remove_pushover_hooks.py << 'EOF'
import json
import os

settings_path = os.path.expanduser("~/.claude/settings.json")

try:
    with open(settings_path, 'r') as f:
        settings = json.load(f)
    
    # Remove Pushover-related hooks
    if 'hooks' in settings:
        hooks_to_check = ['Notification', 'Stop', 'UserPromptSubmit', 'PreToolUse', 'PostToolUse']
        for hook in hooks_to_check:
            if hook in settings['hooks']:
                # Check if it's using pushover-notify.sh
                if any('pushover-notify.sh' in str(h) for h in settings['hooks'][hook]):
                    del settings['hooks'][hook]
        
        # If hooks is empty, remove it
        if not settings['hooks']:
            del settings['hooks']
    
    # Write back if there's still content
    if settings:
        with open(settings_path, 'w') as f:
            json.dump(settings, f, indent=2)
        print("Pushover hooks removed from settings")
    else:
        # Remove empty settings file
        os.remove(settings_path)
        print("Empty settings file removed")
        
except Exception as e:
    print(f"Could not clean settings: {e}")
EOF
    
    python3 /tmp/remove_pushover_hooks.py
    rm /tmp/remove_pushover_hooks.py
fi

echo ""
echo "✅ Pushover notifications uninstalled!"
echo ""
echo "Note: Backup files (*.backup.*) were not removed."
echo "You can manually delete them from ~/.claude/ if desired."
echo ""