#!/bin/bash

# Voice Dependencies Installation Script
# Handles PyAudio and related audio dependencies

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Installing Voice Input Dependencies...${NC}"
echo ""

# Detect OS
OS_TYPE=""
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS_TYPE="macos"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if grep -q Microsoft /proc/version 2>/dev/null; then
        OS_TYPE="wsl"
    else
        OS_TYPE="linux"
    fi
else
    OS_TYPE="unknown"
fi

echo "Detected OS: $OS_TYPE"
echo ""

# Function to check if running with sudo
check_sudo() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${YELLOW}This script needs sudo privileges to install system packages.${NC}"
        echo "Please run: sudo $0"
        echo ""
        echo "Or install manually:"
        case "$OS_TYPE" in
            linux|wsl)
                echo "  sudo apt-get update"
                echo "  sudo apt-get install -y python3-pyaudio portaudio19-dev python3-dev"
                ;;
            macos)
                echo "  brew install portaudio"
                echo "  pip3 install pyaudio --user"
                ;;
        esac
        exit 1
    fi
}

# Install based on OS
case "$OS_TYPE" in
    linux|wsl)
        echo -e "${BLUE}Installing Linux/WSL audio dependencies...${NC}"
        
        # Check for sudo
        if command -v apt-get &> /dev/null; then
            if [ "$EUID" -ne 0 ]; then
                echo -e "${YELLOW}Requesting sudo access to install system packages...${NC}"
                sudo apt-get update
                sudo apt-get install -y \
                    portaudio19-dev \
                    python3-pyaudio \
                    python3-dev \
                    libasound2-dev \
                    libportaudio2 \
                    libportaudiocpp0
            else
                apt-get update
                apt-get install -y \
                    portaudio19-dev \
                    python3-pyaudio \
                    python3-dev \
                    libasound2-dev \
                    libportaudio2 \
                    libportaudiocpp0
            fi
            echo -e "${GREEN}✓ System packages installed${NC}"
        else
            echo -e "${RED}apt-get not found. Please install packages manually.${NC}"
            exit 1
        fi
        ;;
        
    macos)
        echo -e "${BLUE}Installing macOS audio dependencies...${NC}"
        
        # Check for Homebrew
        if command -v brew &> /dev/null; then
            brew install portaudio
            echo -e "${GREEN}✓ PortAudio installed via Homebrew${NC}"
        else
            echo -e "${RED}Homebrew not found. Please install Homebrew first:${NC}"
            echo '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
            exit 1
        fi
        ;;
        
    *)
        echo -e "${RED}Unknown OS. Please install manually:${NC}"
        echo "  1. Install PortAudio development libraries"
        echo "  2. Install Python development headers"
        echo "  3. pip3 install pyaudio"
        exit 1
        ;;
esac

# Install Python packages
echo ""
echo -e "${BLUE}Installing Python packages...${NC}"

# Install PyAudio via pip (fallback if system package didn't work)
if ! python3 -c "import pyaudio" 2>/dev/null; then
    echo "Installing PyAudio via pip..."
    pip3 install pyaudio --user --break-system-packages 2>/dev/null || {
        echo -e "${YELLOW}Note: PyAudio pip installation failed, but system package may work${NC}"
    }
fi

# Install SpeechRecognition
if ! python3 -c "import speech_recognition" 2>/dev/null; then
    echo "Installing SpeechRecognition..."
    pip3 install SpeechRecognition --user --break-system-packages
fi

# Install pyttsx3 for text-to-speech (optional)
if ! python3 -c "import pyttsx3" 2>/dev/null; then
    echo "Installing pyttsx3 for text-to-speech..."
    pip3 install pyttsx3 --user --break-system-packages 2>/dev/null || {
        echo -e "${YELLOW}Note: pyttsx3 is optional for text-to-speech${NC}"
    }
fi

# Verify installation
echo ""
echo -e "${BLUE}Verifying installation...${NC}"

# Check PyAudio
if python3 -c "import pyaudio; print('✓ PyAudio working')" 2>/dev/null; then
    echo -e "${GREEN}✓ PyAudio installed successfully${NC}"
else
    echo -e "${YELLOW}⚠ PyAudio not working. Voice input may not function.${NC}"
    echo "  Try: sudo apt-get install python3-pyaudio"
fi

# Check SpeechRecognition
if python3 -c "import speech_recognition; print('✓ SpeechRecognition working')" 2>/dev/null; then
    echo -e "${GREEN}✓ SpeechRecognition installed successfully${NC}"
else
    echo -e "${RED}✗ SpeechRecognition not installed${NC}"
fi

# Test microphone access
echo ""
echo -e "${BLUE}Testing microphone access...${NC}"

python3 -c "
import sys
try:
    import pyaudio
    p = pyaudio.PyAudio()
    if p.get_device_count() > 0:
        print('✓ Found', p.get_device_count(), 'audio device(s)')
        for i in range(p.get_device_count()):
            info = p.get_device_info_by_index(i)
            if info['maxInputChannels'] > 0:
                print(f'  - Input device {i}: {info[\"name\"]}')
    else:
        print('⚠ No audio devices found')
    p.terminate()
except Exception as e:
    print(f'✗ Could not access audio devices: {e}')
    sys.exit(1)
" 2>/dev/null || {
    echo -e "${YELLOW}Note: Audio device test failed. This is normal in some environments.${NC}"
    echo "Voice input may still work when an actual microphone is available."
}

echo ""
echo -e "${GREEN}Voice dependencies installation complete!${NC}"
echo ""
echo "To test voice input:"
echo "  claude-assistant orch-voice"
echo ""
echo "Note: In WSL, you may need additional setup for audio passthrough."
echo "See: https://github.com/microsoft/WSL/issues/4205"