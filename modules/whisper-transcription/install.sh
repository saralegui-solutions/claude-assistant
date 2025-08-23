#!/bin/bash

# OpenAI Whisper Module Installer
# Part of Claude Assistant Suite

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

# Paths
CLAUDE_DIR="$HOME/.claude"
MODULE_DIR="$(dirname "$0")"
INSTALL_DIR="$CLAUDE_DIR/whisper"

print_header() {
    echo -e "${BOLD}${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║           OpenAI Whisper Module Installation                ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_status() {
    echo -e "${BLUE}[*]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if grep -q Microsoft /proc/version 2>/dev/null; then
            echo "wsl"
        else
            echo "linux"
        fi
    else
        echo "unknown"
    fi
}

install_system_deps() {
    print_status "Installing system dependencies..."
    
    local os_type=$(detect_os)
    
    case "$os_type" in
        macos)
            # Install ffmpeg for audio processing
            if ! command -v ffmpeg &> /dev/null; then
                print_status "Installing ffmpeg..."
                brew install ffmpeg
            else
                print_success "ffmpeg already installed"
            fi
            ;;
            
        linux|wsl)
            # Install ffmpeg
            if ! command -v ffmpeg &> /dev/null; then
                print_status "Installing ffmpeg..."
                sudo apt-get update -qq
                sudo apt-get install -y -qq ffmpeg
            else
                print_success "ffmpeg already installed"
            fi
            ;;
    esac
}

install_python_deps() {
    print_status "Installing Python dependencies..."
    
    # Check Python version
    if ! python3 -c "import sys; exit(0 if sys.version_info >= (3, 8) else 1)" 2>/dev/null; then
        print_error "Python 3.8+ required"
        exit 1
    fi
    
    echo -e "\n${BOLD}Select Whisper backend to install:${NC}"
    echo "  [1] OpenAI Whisper (official, recommended)"
    echo "  [2] Faster-whisper (optimized, faster)"
    echo "  [3] WhisperX (with alignment features)"
    echo "  [4] All backends (complete installation)"
    echo "  [5] Skip Python installation"
    echo ""
    
    read -p "Enter choice [1-5]: " -r choice
    
    case "$choice" in
        1)
            print_status "Installing OpenAI Whisper..."
            pip3 install --user openai-whisper
            ;;
        2)
            print_status "Installing Faster-whisper..."
            pip3 install --user faster-whisper
            ;;
        3)
            print_status "Installing WhisperX..."
            pip3 install --user whisperx
            ;;
        4)
            print_status "Installing all backends..."
            pip3 install --user openai-whisper faster-whisper
            # WhisperX has complex deps, make optional
            pip3 install --user whisperx 2>/dev/null || \
                print_warning "WhisperX installation failed (optional)"
            ;;
        5)
            print_warning "Skipping Python installation"
            ;;
        *)
            print_warning "Invalid choice, skipping Python deps"
            ;;
    esac
    
    # Install common audio processing libs
    print_status "Installing audio processing libraries..."
    pip3 install --user sounddevice soundfile 2>/dev/null || \
        print_warning "Audio libs installation failed (optional for microphone)"
}

select_model() {
    print_status "Selecting Whisper model..."
    
    echo -e "\n${BOLD}Available models:${NC}"
    echo "  [1] tiny   (39M)  - Fastest, least accurate"
    echo "  [2] base   (74M)  - Good balance (recommended)"
    echo "  [3] small  (244M) - Better accuracy"
    echo "  [4] medium (769M) - High accuracy"
    echo "  [5] large  (1.5G) - Best accuracy, slowest"
    echo ""
    
    read -p "Select model [1-5, default=2]: " -r choice
    
    case "$choice" in
        1) MODEL="tiny" ;;
        2|"") MODEL="base" ;;
        3) MODEL="small" ;;
        4) MODEL="medium" ;;
        5) MODEL="large" ;;
        *) MODEL="base" ;;
    esac
    
    print_success "Selected model: $MODEL"
    
    # Update config with selected model
    if [ -f "$MODULE_DIR/config.json" ]; then
        sed -i.bak "s/\"model\": \"[^\"]*\"/\"model\": \"$MODEL\"/" "$MODULE_DIR/config.json"
        rm "$MODULE_DIR/config.json.bak" 2>/dev/null || true
    fi
}

download_model() {
    print_status "Downloading Whisper model..."
    
    echo -e "${CYAN}Download $MODEL model now?${NC}"
    echo "This will download the model for offline use."
    read -p "(y/N): " -r response
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        python3 -c "import whisper; whisper.load_model('$MODEL')" 2>/dev/null || \
            print_warning "Model download failed - will download on first use"
    else
        print_warning "Model will be downloaded on first use"
    fi
}

install_module_files() {
    print_status "Installing Whisper module files..."
    
    # Create installation directory
    mkdir -p "$INSTALL_DIR"
    
    # Copy module files
    cp "$MODULE_DIR/whisper_transcribe.py" "$INSTALL_DIR/"
    cp "$MODULE_DIR/config.json" "$INSTALL_DIR/"
    cp "$MODULE_DIR/README.md" "$INSTALL_DIR/" 2>/dev/null || true
    
    # Make executable
    chmod +x "$INSTALL_DIR/whisper_transcribe.py"
    
    # Create wrapper command
    cat > "$CLAUDE_DIR/bin/claude-whisper" << 'EOF'
#!/bin/bash
# Claude Whisper wrapper

WHISPER_DIR="$HOME/.claude/whisper"
python3 "$WHISPER_DIR/whisper_transcribe.py" "$@"
EOF
    
    chmod +x "$CLAUDE_DIR/bin/claude-whisper"
    
    # Create convenience symlink
    ln -sf "$CLAUDE_DIR/bin/claude-whisper" "$CLAUDE_DIR/bin/whisper-transcribe" 2>/dev/null || true
    
    print_success "Module files installed"
}

configure_integration() {
    print_status "Configuring Claude Assistant integration..."
    
    # Add to voice assistant if installed
    if [ -d "$CLAUDE_DIR/voice-assistant" ]; then
        print_status "Integrating with voice assistant..."
        # Add whisper as transcription backend
        echo "TRANSCRIPTION_BACKEND=whisper" >> "$CLAUDE_DIR/voice-assistant/config" 2>/dev/null || true
        print_success "Voice assistant integration configured"
    fi
    
    print_success "Integration complete"
}

test_installation() {
    print_status "Testing installation..."
    
    if python3 "$INSTALL_DIR/whisper_transcribe.py" --check 2>/dev/null; then
        print_success "Installation test passed"
    else
        print_warning "Installation test failed - check dependencies"
    fi
}

print_completion() {
    echo -e "\n${BOLD}${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${GREEN}║         OpenAI Whisper Installation Complete!               ║${NC}"
    echo -e "${BOLD}${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    
    echo -e "\n${BOLD}Quick Start:${NC}"
    echo "  Check system:      claude-whisper --check"
    echo "  Transcribe file:   claude-whisper audio.mp3"
    echo "  From microphone:   claude-whisper --mic --duration 10"
    echo "  Batch process:     claude-whisper ./audio/ --batch"
    
    echo -e "\n${BOLD}Installed:${NC}"
    echo "  Module:     $INSTALL_DIR"
    echo "  Command:    $CLAUDE_DIR/bin/claude-whisper"
    echo "  Config:     $INSTALL_DIR/config.json"
    echo "  Model:      $MODEL"
    
    echo -e "\n${BOLD}Next Steps:${NC}"
    
    # Check what's available
    if python3 -c "import whisper" 2>/dev/null; then
        echo -e "${GREEN}  ✓ Whisper is ready to use${NC}"
    else
        echo -e "${YELLOW}  Install Python package: pip install openai-whisper${NC}"
    fi
    
    if [ ! -f "$HOME/.cache/whisper/${MODEL}.pt" ]; then
        echo "  Download model: claude-whisper --check"
    fi
    
    echo -e "\n${CYAN}Test with: claude-whisper --mic --duration 5${NC}"
}

# Main installation
main() {
    print_header
    
    # Check if already installed
    if [ -d "$INSTALL_DIR" ]; then
        print_warning "Whisper module already installed at $INSTALL_DIR"
        read -p "Reinstall? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 0
        fi
        rm -rf "$INSTALL_DIR"
    fi
    
    # Create directories
    mkdir -p "$CLAUDE_DIR/bin"
    
    # Installation steps
    install_system_deps
    install_python_deps
    select_model
    download_model
    install_module_files
    configure_integration
    test_installation
    
    print_completion
}

# Run installation
main "$@"