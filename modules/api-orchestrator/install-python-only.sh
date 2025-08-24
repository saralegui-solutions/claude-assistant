#!/bin/bash

# Python-Only Installation (No sudo required)
# Installs what's possible without system packages

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Installing Python packages for API Orchestrator...${NC}"
echo ""

# Install core requirements
echo "Installing core dependencies..."
pip3 install anthropic --user --break-system-packages 2>/dev/null || {
    echo -e "${YELLOW}Could not install anthropic. Try:${NC}"
    echo "  pip3 install anthropic --user --break-system-packages"
}

# Install voice dependencies (will work if system packages exist)
echo "Installing voice dependencies..."
pip3 install SpeechRecognition --user --break-system-packages 2>/dev/null || {
    echo -e "${YELLOW}Could not install SpeechRecognition${NC}"
}

# Try PyAudio (will fail without system packages but worth trying)
echo "Attempting PyAudio installation..."
pip3 install pyaudio --user --break-system-packages 2>/dev/null || {
    echo -e "${YELLOW}PyAudio requires system packages. Voice input will use text fallback.${NC}"
    echo ""
    echo "To enable voice input, you need to install system packages:"
    echo "  Ubuntu/Debian: sudo apt-get install python3-pyaudio portaudio19-dev"
    echo "  macOS: brew install portaudio"
    echo ""
    echo "Or run: ./install-voice-deps.sh (requires sudo)"
}

# Verify what's installed
echo ""
echo -e "${BLUE}Checking installed packages...${NC}"

python3 -c "
import sys
print('Python version:', sys.version.split()[0])
print()

try:
    import anthropic
    print('✓ anthropic:', anthropic.__version__)
except ImportError:
    print('✗ anthropic: NOT INSTALLED (required)')

try:
    import speech_recognition as sr
    print('✓ SpeechRecognition:', sr.__version__)
except ImportError:
    print('✗ SpeechRecognition: NOT INSTALLED (optional)')

try:
    import pyaudio
    print('✓ PyAudio:', pyaudio.__version__)
except ImportError:
    print('△ PyAudio: NOT INSTALLED (optional, text input will work)')
"

echo ""
echo -e "${GREEN}Installation complete!${NC}"
echo ""
echo "The orchestrator will work with text input."
echo "Voice input requires PyAudio (needs system packages)."