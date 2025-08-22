#!/bin/bash

# Install Claude Code hooks for automatic model updates

SCRIPT_DIR="$(dirname "$(realpath "$0")")"
CLAUDE_SETTINGS_DIR="$HOME/.config/claude"
HOOKS_DIR="$CLAUDE_SETTINGS_DIR/hooks"

echo "Installing Claude Code hooks..."

# Create Claude settings directory if it doesn't exist
mkdir -p "$HOOKS_DIR"

# Create or update the pre-submit hook
cat > "$HOOKS_DIR/pre-submit.sh" << 'EOF'
#!/bin/bash

# Claude Code Pre-Submit Hook - Check for model updates
CLAUDE_ASSISTANT_DIR="/home/ben/saralegui-solutions-llc/claude-assistant"

if [ -f "$CLAUDE_ASSISTANT_DIR/check-updates.js" ]; then
  # Check for updates silently in background
  (
    cd "$CLAUDE_ASSISTANT_DIR"
    node check-updates.js --silent 2>/dev/null
  ) &
fi

# Always allow submission to continue
exit 0
EOF

chmod +x "$HOOKS_DIR/pre-submit.sh"

# Create Claude settings.json if it doesn't exist
SETTINGS_FILE="$CLAUDE_SETTINGS_DIR/settings.json"

if [ ! -f "$SETTINGS_FILE" ]; then
  cat > "$SETTINGS_FILE" << 'EOF'
{
  "hooks": {
    "pre-submit": "~/.config/claude/hooks/pre-submit.sh"
  }
}
EOF
  echo "✓ Created Claude settings with hooks"
else
  # Update existing settings to add hooks
  if command -v jq &> /dev/null; then
    # Use jq if available
    jq '.hooks = {"pre-submit": "~/.config/claude/hooks/pre-submit.sh"}' "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp" && mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
    echo "✓ Updated Claude settings with hooks"
  else
    echo "⚠️  Please manually add the following to $SETTINGS_FILE:"
    echo '  "hooks": {'
    echo '    "pre-submit": "~/.config/claude/hooks/pre-submit.sh"'
    echo '  }'
  fi
fi

echo "✓ Claude Code hooks installed successfully"
echo ""
echo "The model update check will now run automatically:"
echo "  • When Claude Code starts a new session"
echo "  • Before submitting prompts to Claude"
echo ""
echo "To test the hook, run: claude (or your Claude Code command)"