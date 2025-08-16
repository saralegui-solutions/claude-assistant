#!/bin/bash

# WSL Voice Input - Uses Windows speech recognition
# This script calls PowerShell from WSL to use Windows' microphone

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PS_SCRIPT="$SCRIPT_DIR/windows_voice_bridge.ps1"
VOICE_FILE="/tmp/claude_voice_input.txt"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Convert WSL path to Windows path
WIN_SCRIPT=$(wslpath -w "$PS_SCRIPT")

echo -e "${BLUE}🎤 WSL Voice Input${NC}"
echo "==================="
echo ""

# Method 1: Try using PowerShell directly
use_powershell() {
    echo -e "${YELLOW}Using Windows PowerShell for voice input...${NC}"
    
    # Run PowerShell script from WSL
    powershell.exe -ExecutionPolicy Bypass -File "$WIN_SCRIPT" 2>/dev/null
    
    if [ -f "$VOICE_FILE" ]; then
        echo -e "${GREEN}✅ Voice input captured!${NC}"
        echo "Content: $(cat $VOICE_FILE)"
        return 0
    else
        return 1
    fi
}

# Method 2: Use Windows Speech Recognition API via Python
use_windows_python() {
    echo -e "${YELLOW}Trying Windows Python speech recognition...${NC}"
    
    # Create a Windows Python script
    cat > /tmp/win_voice.py << 'EOF'
import speech_recognition as sr
import sys

r = sr.Recognizer()
with sr.Microphone() as source:
    print("Listening...")
    audio = r.listen(source, timeout=5, phrase_time_limit=30)
    try:
        text = r.recognize_google(audio)
        print(f"Transcribed: {text}")
        with open(r"\\wsl$\Ubuntu\tmp\claude_voice_input.txt", "w") as f:
            f.write(text)
    except:
        print("Could not understand audio")
        sys.exit(1)
EOF
    
    # Convert to Windows path and run
    WIN_PY=$(wslpath -w /tmp/win_voice.py)
    python.exe "$WIN_PY" 2>/dev/null || py.exe "$WIN_PY" 2>/dev/null
    
    if [ -f "$VOICE_FILE" ]; then
        return 0
    else
        return 1
    fi
}

# Method 3: Use simple input fallback
use_text_input() {
    echo -e "${YELLOW}Audio not available. Please type your command:${NC}"
    read -r text_input
    echo "$text_input" > "$VOICE_FILE"
    echo -e "${GREEN}✅ Input saved${NC}"
    return 0
}

# Main execution
main() {
    # Try PowerShell first
    if use_powershell; then
        echo -e "${GREEN}Success using PowerShell${NC}"
    # Try Windows Python
    elif use_windows_python; then
        echo -e "${GREEN}Success using Windows Python${NC}"
    # Fallback to text input
    else
        echo -e "${RED}⚠️  Microphone access not available in WSL${NC}"
        echo -e "${YELLOW}Using text input instead...${NC}"
        use_text_input
    fi
    
    # Display the result
    if [ -f "$VOICE_FILE" ]; then
        echo ""
        echo -e "${BLUE}Your input:${NC}"
        cat "$VOICE_FILE"
        echo ""
        echo -e "${GREEN}Now you can run:${NC}"
        echo "  claude < $VOICE_FILE"
    fi
}

# Check if running in WSL
if grep -q Microsoft /proc/version; then
    main
else
    echo -e "${RED}This script is designed for WSL. Use the regular voice scripts on native Linux.${NC}"
    exit 1
fi