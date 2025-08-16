#!/bin/bash

# Setup script for Claude Voice aliases

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "Setting up Claude Voice aliases..."

# Add to bashrc
ALIAS_LINES="
# Claude Voice Commands
alias cv='$SCRIPT_DIR/claude-voice'
alias claude-voice='$SCRIPT_DIR/claude-voice'
alias cvc='$SCRIPT_DIR/claude-voice -c'
alias cvi='$SCRIPT_DIR/claude-voice-interactive'
alias voice='$SCRIPT_DIR/claude-voice-interactive'

# Quick voice command to Claude
vc() {
    echo '🎤 Listening for your command...'
    VOICE_INPUT=\$($SCRIPT_DIR/claude-voice-interactive -d)
    if [ -n \"\$VOICE_INPUT\" ]; then
        echo \"\$VOICE_INPUT\" | claude \"\$@\"
    fi
}

# Voice command saved to file
vcf() {
    python3 $SCRIPT_DIR/voice_to_file.py
    if [ -f /tmp/claude_voice_input.txt ]; then
        echo \"Voice input saved. Run: claude < /tmp/claude_voice_input.txt\"
    fi
}
"

# Check if aliases already exist
if ! grep -q "Claude Voice Commands" ~/.bashrc 2>/dev/null; then
    echo "$ALIAS_LINES" >> ~/.bashrc
    echo "✅ Aliases added to ~/.bashrc"
else
    echo "⚠️  Aliases already exist in ~/.bashrc"
fi

# Also add to .zshrc if it exists
if [ -f ~/.zshrc ]; then
    if ! grep -q "Claude Voice Commands" ~/.zshrc 2>/dev/null; then
        echo "$ALIAS_LINES" >> ~/.zshrc
        echo "✅ Aliases added to ~/.zshrc"
    fi
fi

echo ""
echo "✅ Setup complete!"
echo ""
echo "Available commands:"
echo "  cv              - Run voice input (single command)"
echo "  cvc             - Run voice input (continuous mode)"
echo "  voice-claude    - Voice input piped directly to Claude"
echo "  vc [args]       - Quick voice command to Claude with args"
echo ""
echo "To activate now, run:"
echo "  source ~/.bashrc"
echo ""
echo "Examples:"
echo "  vc              # Speak a command for Claude"
echo "  cvc             # Continuous voice mode"
echo "  voice-claude    # Direct pipe to Claude"