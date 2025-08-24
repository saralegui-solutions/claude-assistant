#!/bin/bash

# WSL Audio Setup Script
# Configures PulseAudio for real voice input in WSL

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Setting up WSL Audio Support...${NC}"
echo ""

# Check if running in WSL
if ! grep -q microsoft /proc/version 2>/dev/null; then
    echo -e "${YELLOW}Not running in WSL. This script is for WSL only.${NC}"
    exit 0
fi

# Function to get Windows host IP
get_windows_ip() {
    cat /etc/resolv.conf | grep nameserver | awk '{print $2}'
}

# Install PulseAudio if not present
install_pulseaudio() {
    echo "Checking PulseAudio installation..."
    
    if ! command -v pulseaudio &> /dev/null; then
        echo "Installing PulseAudio..."
        sudo apt-get update
        sudo apt-get install -y pulseaudio pulseaudio-utils
    else
        echo -e "${GREEN}✓ PulseAudio already installed${NC}"
    fi
    
    # Install additional audio tools
    echo "Installing audio tools..."
    sudo apt-get install -y \
        alsa-utils \
        libasound2-plugins \
        pavucontrol 2>/dev/null || true
}

# Configure PulseAudio for WSL
configure_pulseaudio() {
    echo "Configuring PulseAudio for WSL..."
    
    # Create PulseAudio config directory
    mkdir -p ~/.config/pulse
    
    # Get Windows host IP
    WINDOWS_HOST=$(get_windows_ip)
    echo "Windows host IP: $WINDOWS_HOST"
    
    # Create client.conf
    cat > ~/.config/pulse/client.conf << EOF
# PulseAudio client configuration for WSL
default-server = tcp:$WINDOWS_HOST
autospawn = no
daemon-binary = /bin/true
enable-shm = false
EOF
    
    echo -e "${GREEN}✓ PulseAudio configured${NC}"
}

# Setup environment variables
setup_environment() {
    echo "Setting up environment variables..."
    
    # Create script to set PulseAudio variables
    cat > ~/.claude/wsl-audio-env.sh << 'EOF'
#!/bin/bash
# WSL Audio Environment Setup

# Get Windows host IP dynamically
export PULSE_SERVER=tcp:$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}')

# Disable ALSA warnings
export ALSA_CARD=null
export ALSA_PCM_CARD=null

# Test connection
if pactl info &>/dev/null; then
    echo "✓ PulseAudio connected to Windows"
else
    echo "⚠ PulseAudio not connected. Make sure PulseAudio is running on Windows."
fi
EOF
    
    chmod +x ~/.claude/wsl-audio-env.sh
    
    # Add to bashrc if not already there
    if ! grep -q "wsl-audio-env.sh" ~/.bashrc 2>/dev/null; then
        echo "" >> ~/.bashrc
        echo "# WSL Audio Support for Claude Assistant" >> ~/.bashrc
        echo "[ -f ~/.claude/wsl-audio-env.sh ] && source ~/.claude/wsl-audio-env.sh" >> ~/.bashrc
    fi
    
    echo -e "${GREEN}✓ Environment configured${NC}"
}

# Create Windows PulseAudio installer
create_windows_installer() {
    echo "Creating Windows PulseAudio installer..."
    
    cat > ~/pulseaudio-windows-setup.txt << 'EOF'
=============================================================
Windows PulseAudio Setup Instructions
=============================================================

To enable audio from WSL to Windows, you need to install and run PulseAudio on Windows:

Option 1: Using Chocolatey (Recommended)
-----------------------------------------
1. Install Chocolatey (if not installed):
   Open PowerShell as Administrator and run:
   Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

2. Install PulseAudio:
   choco install pulseaudio

3. Configure PulseAudio:
   Edit C:\ProgramData\chocolatey\lib\pulseaudio\tools\etc\pulse\default.pa
   Add this line at the end:
   load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1;172.16.0.0/12

4. Run PulseAudio:
   C:\ProgramData\chocolatey\lib\pulseaudio\tools\pulseaudio.exe

Option 2: Manual Installation
-----------------------------
1. Download PulseAudio for Windows:
   https://www.freedesktop.org/wiki/Software/PulseAudio/Ports/Windows/Support/

2. Extract to C:\pulseaudio

3. Edit C:\pulseaudio\etc\pulse\default.pa
   Add: load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1;172.16.0.0/12

4. Run C:\pulseaudio\bin\pulseaudio.exe

Creating Windows Startup Script
--------------------------------
Create pulseaudio-start.bat:

@echo off
echo Starting PulseAudio Server...
cd C:\ProgramData\chocolatey\lib\pulseaudio\tools
start "" pulseaudio.exe --exit-idle-time=-1
echo PulseAudio started. Keep this window open.
pause

Testing Connection
------------------
From WSL, run:
pactl info

You should see server information if connected successfully.

Troubleshooting
---------------
1. Windows Firewall: Allow PulseAudio through firewall
2. Check Windows IP: ipconfig (look for WSL adapter)
3. Restart WSL: wsl --shutdown then reopen
=============================================================
EOF
    
    echo -e "${GREEN}✓ Windows setup instructions saved to ~/pulseaudio-windows-setup.txt${NC}"
}

# Test audio connection
test_audio() {
    echo ""
    echo "Testing audio connection..."
    
    # Source environment
    source ~/.claude/wsl-audio-env.sh
    
    # Test PulseAudio connection
    if pactl info &>/dev/null; then
        echo -e "${GREEN}✓ Connected to PulseAudio server${NC}"
        
        # List audio devices
        echo ""
        echo "Audio sources (microphones):"
        pactl list short sources 2>/dev/null | grep -v monitor || echo "  No microphones detected"
        
        echo ""
        echo "Audio sinks (speakers):"
        pactl list short sinks 2>/dev/null || echo "  No speakers detected"
    else
        echo -e "${YELLOW}⚠ Cannot connect to PulseAudio server${NC}"
        echo ""
        echo "Please ensure PulseAudio is running on Windows."
        echo "See ~/pulseaudio-windows-setup.txt for instructions."
    fi
}

# Main installation
main() {
    echo "This script will set up real audio support for WSL."
    echo ""
    
    install_pulseaudio
    configure_pulseaudio
    setup_environment
    create_windows_installer
    test_audio
    
    echo ""
    echo -e "${GREEN}WSL Audio Setup Complete!${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Install PulseAudio on Windows (see ~/pulseaudio-windows-setup.txt)"
    echo "2. Run PulseAudio on Windows"
    echo "3. Restart your WSL terminal"
    echo "4. Test with: pactl info"
    echo ""
    echo "Audio will be automatically configured when you run claude-assistant."
}

# Run main
main