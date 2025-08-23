#!/bin/bash

# Claude Assistant - Interactive Modular Installer
# One-step installation with à la carte module selection

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'
BOLD='\033[1m'

# Paths
CLAUDE_DIR="$HOME/.claude"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Module definitions with descriptions and dependencies
declare -A MODULES
declare -A MODULE_DESC
declare -A MODULE_DEPS
declare -A MODULE_SIZE

# Core module (always installed)
MODULES["core"]="Core System"
MODULE_DESC["core"]="Essential Claude Assistant framework and base commands"
MODULE_DEPS["core"]="jq curl"
MODULE_SIZE["core"]="~500KB"

# Optional modules
MODULES["rate-limit-manager"]="Rate Limit Manager"
MODULE_DESC["rate-limit-manager"]="Prevents API errors with smart monitoring and checkpointing"
MODULE_DEPS["rate-limit-manager"]="jq"
MODULE_SIZE["rate-limit-manager"]="~1MB"

MODULES["notifications"]="Notifications System"
MODULE_DESC["notifications"]="Desktop and mobile alerts for Claude events"
MODULE_DEPS["notifications"]="curl"
MODULE_SIZE["notifications"]="~500KB"

MODULES["voice-assistant"]="Voice Assistant"
MODULE_DESC["voice-assistant"]="Voice input/output for hands-free interaction"
MODULE_DEPS["voice-assistant"]="python3 pyaudio"
MODULE_SIZE["voice-assistant"]="~2MB"

MODULES["pdf-generator"]="PDF Generator"
MODULE_DESC["pdf-generator"]="Convert markdown and documents to professional PDFs"
MODULE_DEPS["pdf-generator"]="python3"
MODULE_SIZE["pdf-generator"]="~1MB"

MODULES["whisper-transcription"]="Whisper Transcription"
MODULE_DESC["whisper-transcription"]="High-quality speech-to-text using OpenAI Whisper"
MODULE_DEPS["whisper-transcription"]="python3 ffmpeg"
MODULE_SIZE["whisper-transcription"]="~2MB"

# Selected modules array
declare -a SELECTED_MODULES=("core")

# Installation options
INSTALL_DEPS=true
CONFIGURE_SHELL=true
CREATE_SHORTCUTS=true
INSTALL_OPTIONAL_DEPS=false

# Functions
print_header() {
    clear
    echo -e "${BOLD}${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║         Claude Assistant - Interactive Installer            ║"
    echo "║                   Modular Installation                      ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}\n"
}

print_module_info() {
    local module=$1
    echo -e "${BOLD}${GREEN}$module${NC}"
    echo -e "  ${MODULE_DESC[$module]}"
    echo -e "  ${CYAN}Dependencies:${NC} ${MODULE_DEPS[$module]}"
    echo -e "  ${CYAN}Size:${NC} ${MODULE_SIZE[$module]}"
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

detect_shell() {
    if [ -n "$ZSH_VERSION" ]; then
        echo "zsh"
    elif [ -n "$BASH_VERSION" ]; then
        echo "bash"
    else
        echo "$(basename "$SHELL")"
    fi
}

# Step 1: System detection and compatibility check
check_system() {
    print_header
    echo -e "${BOLD}Step 1: System Detection${NC}\n"
    
    local os_type=$(detect_os)
    local shell_type=$(detect_shell)
    
    echo -e "  ${GREEN}✓${NC} Operating System: $os_type"
    echo -e "  ${GREEN}✓${NC} Shell: $shell_type"
    echo -e "  ${GREEN}✓${NC} Home Directory: $HOME"
    echo -e "  ${GREEN}✓${NC} Installation Directory: $CLAUDE_DIR"
    
    # Check for existing installation
    if [ -d "$CLAUDE_DIR" ]; then
        echo -e "\n  ${YELLOW}⚠${NC} Existing installation detected at $CLAUDE_DIR"
        echo -e "     Files will be updated/merged"
    fi
    
    echo -e "\n${CYAN}Press Enter to continue...${NC}"
    read -r
}

# Step 2: Module selection
select_modules() {
    print_header
    echo -e "${BOLD}Step 2: Select Modules${NC}\n"
    echo -e "Choose which modules to install (space-separated numbers):\n"
    
    # Core is always installed
    echo -e "${GREEN}[✓] Core System${NC} (automatically included)"
    echo -e "    ${MODULE_DESC["core"]}\n"
    
    # List optional modules
    local i=1
    local module_array=()
    for module in rate-limit-manager notifications voice-assistant pdf-generator whisper-transcription; do
        module_array+=("$module")
        echo -e "${BOLD}[$i]${NC} ${MODULES[$module]}"
        echo -e "    ${MODULE_DESC[$module]}"
        echo -e "    ${CYAN}Deps:${NC} ${MODULE_DEPS[$module]} | ${CYAN}Size:${NC} ${MODULE_SIZE[$module]}\n"
        ((i++))
    done
    
    echo -e "${BOLD}[A]${NC} All modules (recommended)"
    echo -e "${BOLD}[M]${NC} Minimal (core only)"
    echo -e "${BOLD}[R]${NC} Recommended (core + rate-limit + pdf)"
    echo ""
    
    read -p "Enter your choice: " -r choice
    
    case "$choice" in
        [Aa]*)
            SELECTED_MODULES+=(rate-limit-manager notifications voice-assistant pdf-generator whisper-transcription)
            echo -e "\n${GREEN}Installing all modules${NC}"
            ;;
        [Mm]*)
            echo -e "\n${GREEN}Installing core only${NC}"
            ;;
        [Rr]*)
            SELECTED_MODULES+=(rate-limit-manager pdf-generator)
            echo -e "\n${GREEN}Installing recommended modules${NC}"
            ;;
        *)
            # Parse numbers
            for num in $choice; do
                if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le 4 ]; then
                    SELECTED_MODULES+=("${module_array[$((num-1))]}")
                fi
            done
            echo -e "\n${GREEN}Custom selection${NC}"
            ;;
    esac
    
    # Display selection
    echo -e "\n${BOLD}Selected modules:${NC}"
    for module in "${SELECTED_MODULES[@]}"; do
        echo -e "  ${GREEN}✓${NC} ${MODULES[$module]}"
    done
    
    echo -e "\n${CYAN}Press Enter to continue...${NC}"
    read -r
}

# Step 3: Installation options
configure_options() {
    print_header
    echo -e "${BOLD}Step 3: Installation Options${NC}\n"
    
    # Dependency installation
    echo -e "${BOLD}Install system dependencies?${NC}"
    echo -e "This will install required packages like jq, curl, python3"
    read -p "(Y/n): " -r response
    [[ "$response" =~ ^[Nn]$ ]] && INSTALL_DEPS=false
    
    # Shell configuration
    echo -e "\n${BOLD}Configure shell aliases?${NC}"
    echo -e "This will add convenient shortcuts like 'cl' and 'dash'"
    read -p "(Y/n): " -r response
    [[ "$response" =~ ^[Nn]$ ]] && CONFIGURE_SHELL=false
    
    # Desktop shortcuts
    echo -e "\n${BOLD}Create desktop shortcuts?${NC}"
    echo -e "This will create application launchers (Linux/WSL only)"
    read -p "(Y/n): " -r response
    [[ "$response" =~ ^[Nn]$ ]] && CREATE_SHORTCUTS=false
    
    # Optional dependencies
    echo -e "\n${BOLD}Install optional dependencies?${NC}"
    echo -e "This includes pandoc, wkhtmltopdf for better PDF quality"
    read -p "(y/N): " -r response
    [[ "$response" =~ ^[Yy]$ ]] && INSTALL_OPTIONAL_DEPS=true
    
    # Summary
    echo -e "\n${BOLD}Configuration Summary:${NC}"
    echo -e "  System dependencies: $([ "$INSTALL_DEPS" = true ] && echo "Yes" || echo "No")"
    echo -e "  Shell aliases: $([ "$CONFIGURE_SHELL" = true ] && echo "Yes" || echo "No")"
    echo -e "  Desktop shortcuts: $([ "$CREATE_SHORTCUTS" = true ] && echo "Yes" || echo "No")"
    echo -e "  Optional deps: $([ "$INSTALL_OPTIONAL_DEPS" = true ] && echo "Yes" || echo "No")"
    
    echo -e "\n${CYAN}Press Enter to start installation...${NC}"
    read -r
}

# Step 4: Install dependencies
install_dependencies() {
    if [ "$INSTALL_DEPS" = false ]; then
        return
    fi
    
    echo -e "\n${BOLD}Installing System Dependencies...${NC}"
    
    local os_type=$(detect_os)
    
    # Collect all required dependencies
    local deps=""
    for module in "${SELECTED_MODULES[@]}"; do
        deps="$deps ${MODULE_DEPS[$module]}"
    done
    
    # Remove duplicates
    deps=$(echo "$deps" | tr ' ' '\n' | sort -u | tr '\n' ' ')
    
    case "$os_type" in
        macos)
            if ! command -v brew &> /dev/null; then
                echo "Installing Homebrew..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            fi
            
            for dep in $deps; do
                if ! command -v "$dep" &> /dev/null; then
                    echo "Installing $dep..."
                    brew install "$dep" 2>/dev/null || true
                fi
            done
            
            if [ "$INSTALL_OPTIONAL_DEPS" = true ]; then
                echo "Installing optional dependencies..."
                brew install pandoc 2>/dev/null || true
                brew install --cask wkhtmltopdf 2>/dev/null || true
            fi
            ;;
            
        linux|wsl)
            sudo apt-get update -qq
            
            for dep in $deps; do
                if ! command -v "$dep" &> /dev/null; then
                    echo "Installing $dep..."
                    sudo apt-get install -y -qq "$dep" 2>/dev/null || true
                fi
            done
            
            if [ "$INSTALL_OPTIONAL_DEPS" = true ]; then
                echo "Installing optional dependencies..."
                sudo apt-get install -y -qq pandoc wkhtmltopdf 2>/dev/null || true
            fi
            ;;
    esac
    
    # Python dependencies for selected modules
    if [[ " ${SELECTED_MODULES[@]} " =~ " pdf-generator " ]]; then
        echo "Installing Python packages for PDF generator..."
        pip3 install --quiet --user markdown2 pdfkit 2>/dev/null || true
    fi
    
    if [[ " ${SELECTED_MODULES[@]} " =~ " voice-assistant " ]]; then
        echo "Installing Python packages for voice assistant..."
        pip3 install --quiet --user SpeechRecognition pyttsx3 pyaudio 2>/dev/null || true
    fi
    
    echo -e "${GREEN}✓${NC} Dependencies installed"
}

# Step 5: Install modules
install_modules() {
    echo -e "\n${BOLD}Installing Modules...${NC}"
    
    # Create directory structure
    mkdir -p "$CLAUDE_DIR"
    mkdir -p "$CLAUDE_DIR/bin"
    mkdir -p "$CLAUDE_DIR/config"
    mkdir -p "$CLAUDE_DIR/data"
    
    local total=${#SELECTED_MODULES[@]}
    local current=0
    
    for module in "${SELECTED_MODULES[@]}"; do
        ((current++))
        echo -e "\n${BLUE}[$current/$total]${NC} Installing ${MODULES[$module]}..."
        
        case "$module" in
            core)
                install_core_module
                ;;
            rate-limit-manager)
                install_rate_limit_module
                ;;
            notifications)
                install_notifications_module
                ;;
            voice-assistant)
                install_voice_module
                ;;
            pdf-generator)
                install_pdf_module
                ;;
            whisper-transcription)
                install_whisper_module
                ;;
        esac
        
        echo -e "${GREEN}✓${NC} ${MODULES[$module]} installed"
    done
}

# Core module installation
install_core_module() {
    # Copy core files
    cp -r "$SCRIPT_DIR/hooks" "$CLAUDE_DIR/" 2>/dev/null || true
    
    # Create main launcher
    cat > "$CLAUDE_DIR/bin/claude-assistant" << 'EOF'
#!/bin/bash
# Claude Assistant Main Launcher

CLAUDE_HOME="$HOME/.claude"

case "$1" in
    help|--help|-h)
        echo "Claude Assistant - Available Commands:"
        echo ""
        [ -f "$CLAUDE_HOME/bin/claude-dashboard" ] && echo "  dashboard  - Rate limit monitoring"
        [ -f "$CLAUDE_HOME/bin/claude-pdf" ] && echo "  pdf        - PDF generator"
        [ -f "$CLAUDE_HOME/bin/claude-voice" ] && echo "  voice      - Voice assistant"
        [ -f "$CLAUDE_HOME/bin/claude-notify" ] && echo "  notify     - Test notifications"
        echo "  config     - Edit configuration"
        echo "  update     - Update Claude Assistant"
        echo "  help       - Show this help"
        ;;
    dashboard)
        "$CLAUDE_HOME/bin/claude-dashboard" "${@:2}"
        ;;
    pdf)
        "$CLAUDE_HOME/bin/claude-pdf" "${@:2}"
        ;;
    voice)
        "$CLAUDE_HOME/bin/claude-voice" "${@:2}"
        ;;
    config)
        ${EDITOR:-nano} "$CLAUDE_HOME/config/settings.json"
        ;;
    update)
        cd "$(dirname "$(readlink -f "$0")")" && git pull && ./install-interactive.sh
        ;;
    *)
        "$CLAUDE_HOME/bin/claude-launcher"
        ;;
esac
EOF
    chmod +x "$CLAUDE_DIR/bin/claude-assistant"
    
    # Create interactive launcher
    cat > "$CLAUDE_DIR/bin/claude-launcher" << 'EOF'
#!/bin/bash
# Claude Assistant Interactive Launcher

GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

clear
echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║              Claude Assistant - Quick Launch                ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo "Available Options:"
modules=0

if [ -f "$HOME/.claude/bin/claude-dashboard" ]; then
    ((modules++))
    echo -e "${GREEN}$modules${NC}) Dashboard - Monitor API usage"
    option_$modules="dashboard"
fi

if [ -f "$HOME/.claude/bin/claude-voice" ]; then
    ((modules++))
    echo -e "${GREEN}$modules${NC}) Voice - Start voice input"
    option_$modules="voice"
fi

if [ -f "$HOME/.claude/bin/claude-pdf" ]; then
    ((modules++))
    echo -e "${GREEN}$modules${NC}) PDF - Convert documents"
    option_$modules="pdf"
fi

echo -e "${GREEN}H${NC}) Help - Show all commands"
echo -e "${GREEN}Q${NC}) Quit"
echo ""

read -p "Enter choice: " choice

case $choice in
    [1-9])
        var="option_$choice"
        if [ -n "${!var}" ]; then
            "$HOME/.claude/bin/claude-${!var}"
        fi
        ;;
    [Hh]) claude-assistant help ;;
    [Qq]) exit 0 ;;
    *) echo "Invalid option" ;;
esac
EOF
    chmod +x "$CLAUDE_DIR/bin/claude-launcher"
}

# Rate limit module installation
install_rate_limit_module() {
    local module_dir="$SCRIPT_DIR/modules/rate-limit-manager"
    
    cp "$module_dir/rate-limit-dashboard.sh" "$CLAUDE_DIR/bin/claude-dashboard"
    chmod +x "$CLAUDE_DIR/bin/claude-dashboard"
    
    cp "$module_dir/rate-limit-config.json" "$CLAUDE_DIR/config/"
    cp "$module_dir/hooks/"*.sh "$CLAUDE_DIR/hooks/" 2>/dev/null || true
    
    # Create checkpoints directory
    mkdir -p "$CLAUDE_DIR/data/checkpoints"
}

# Notifications module installation
install_notifications_module() {
    local module_dir="$SCRIPT_DIR/modules/notifications"
    
    cp "$module_dir/"*.sh "$CLAUDE_DIR/hooks/" 2>/dev/null || true
    
    # Create notification wrapper
    cat > "$CLAUDE_DIR/bin/claude-notify" << 'EOF'
#!/bin/bash
~/.claude/hooks/notify.sh "$@"
EOF
    chmod +x "$CLAUDE_DIR/bin/claude-notify"
}

# Voice module installation
install_voice_module() {
    local module_dir="$SCRIPT_DIR/modules/voice-assistant"
    
    cp "$module_dir/voice"*.py "$CLAUDE_DIR/bin/" 2>/dev/null || true
    cp "$module_dir/claude-voice" "$CLAUDE_DIR/bin/" 2>/dev/null || true
    chmod +x "$CLAUDE_DIR/bin/claude-voice"
    chmod +x "$CLAUDE_DIR/bin/voice"*.py 2>/dev/null || true
}

# PDF module installation
install_pdf_module() {
    local module_dir="$SCRIPT_DIR/modules/pdf-generator"
    
    mkdir -p "$CLAUDE_DIR/pdf-generator"
    cp "$module_dir/"*.py "$CLAUDE_DIR/pdf-generator/" 2>/dev/null || true
    cp "$module_dir/"*.json "$CLAUDE_DIR/pdf-generator/" 2>/dev/null || true
    cp "$module_dir/"*.css "$CLAUDE_DIR/pdf-generator/" 2>/dev/null || true
    
    # Create PDF wrapper
    cat > "$CLAUDE_DIR/bin/claude-pdf" << 'EOF'
#!/bin/bash
python3 "$HOME/.claude/pdf-generator/pdf_generator.py" "$@"
EOF
    chmod +x "$CLAUDE_DIR/bin/claude-pdf"
}

# Whisper module installation
install_whisper_module() {
    local module_dir="$SCRIPT_DIR/modules/whisper-transcription"
    
    mkdir -p "$CLAUDE_DIR/whisper"
    cp "$module_dir/"*.py "$CLAUDE_DIR/whisper/" 2>/dev/null || true
    cp "$module_dir/"*.json "$CLAUDE_DIR/whisper/" 2>/dev/null || true
    
    # Create Whisper wrapper
    cat > "$CLAUDE_DIR/bin/claude-whisper" << 'EOF'
#!/bin/bash
python3 "$HOME/.claude/whisper/whisper_transcribe.py" "$@"
EOF
    chmod +x "$CLAUDE_DIR/bin/claude-whisper"
    
    # Create alias
    ln -sf "$CLAUDE_DIR/bin/claude-whisper" "$CLAUDE_DIR/bin/whisper-transcribe" 2>/dev/null || true
}

# Step 6: Configure shell
configure_shell() {
    if [ "$CONFIGURE_SHELL" = false ]; then
        return
    fi
    
    echo -e "\n${BOLD}Configuring Shell...${NC}"
    
    local shell_config=""
    local shell_type=$(detect_shell)
    
    case "$shell_type" in
        zsh)
            shell_config="$HOME/.zshrc"
            ;;
        bash)
            shell_config="$HOME/.bashrc"
            ;;
        *)
            shell_config="$HOME/.profile"
            ;;
    esac
    
    # Remove old configurations
    sed -i '/# Claude Assistant - Start/,/# Claude Assistant - End/d' "$shell_config" 2>/dev/null || true
    
    # Add new configuration
    cat >> "$shell_config" << 'EOF'

# Claude Assistant - Start
export PATH="$PATH:$HOME/.claude/bin"

# Quick aliases
alias cl='claude-assistant'
alias ca='claude-assistant'

EOF
    
    # Add module-specific aliases
    if [[ " ${SELECTED_MODULES[@]} " =~ " rate-limit-manager " ]]; then
        cat >> "$shell_config" << 'EOF'
alias dash='claude-dashboard'
alias ca-check='claude-assistant checkpoint'
EOF
    fi
    
    if [[ " ${SELECTED_MODULES[@]} " =~ " pdf-generator " ]]; then
        cat >> "$shell_config" << 'EOF'
alias pdf='claude-pdf'
alias ca-pdf='claude-pdf'
EOF
    fi
    
    if [[ " ${SELECTED_MODULES[@]} " =~ " voice-assistant " ]]; then
        cat >> "$shell_config" << 'EOF'
alias ca-voice='claude-voice'
EOF
    fi
    
    cat >> "$shell_config" << 'EOF'

# Claude Assistant - End
EOF
    
    echo -e "${GREEN}✓${NC} Shell configured"
}

# Step 7: Create desktop shortcuts
create_shortcuts() {
    if [ "$CREATE_SHORTCUTS" = false ]; then
        return
    fi
    
    local os_type=$(detect_os)
    if [ "$os_type" != "linux" ] && [ "$os_type" != "wsl" ]; then
        return
    fi
    
    echo -e "\n${BOLD}Creating Desktop Shortcuts...${NC}"
    
    local desktop_dir="$HOME/.local/share/applications"
    mkdir -p "$desktop_dir"
    
    # Main launcher
    cat > "$desktop_dir/claude-assistant.desktop" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Claude Assistant
Comment=AI Development Assistant
Exec=$CLAUDE_DIR/bin/claude-assistant
Icon=utilities-terminal
Terminal=true
Categories=Development;Utility;
EOF
    
    # Module-specific shortcuts
    if [[ " ${SELECTED_MODULES[@]} " =~ " rate-limit-manager " ]]; then
        cat > "$desktop_dir/claude-dashboard.desktop" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Claude Dashboard
Comment=API Rate Limit Monitor
Exec=$CLAUDE_DIR/bin/claude-dashboard
Icon=utilities-system-monitor
Terminal=true
Categories=Development;Monitor;
EOF
    fi
    
    echo -e "${GREEN}✓${NC} Desktop shortcuts created"
}

# Step 8: Final setup
finalize_installation() {
    echo -e "\n${BOLD}Finalizing Installation...${NC}"
    
    # Create default configuration
    if [ ! -f "$CLAUDE_DIR/config/settings.json" ]; then
        echo '{"version": "2.0", "modules": {}}' > "$CLAUDE_DIR/config/settings.json"
    fi
    
    # Set permissions
    chmod -R 755 "$CLAUDE_DIR/bin" 2>/dev/null || true
    
    # Create version file
    echo "2.0" > "$CLAUDE_DIR/VERSION"
    date > "$CLAUDE_DIR/INSTALLED"
    
    echo -e "${GREEN}✓${NC} Installation finalized"
}

# Display completion summary
show_summary() {
    clear
    echo -e "${BOLD}${GREEN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║           🎉 Installation Complete! 🎉                      ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}\n"
    
    echo -e "${BOLD}Installed Modules:${NC}"
    for module in "${SELECTED_MODULES[@]}"; do
        echo -e "  ${GREEN}✓${NC} ${MODULES[$module]}"
    done
    
    echo -e "\n${BOLD}Quick Commands:${NC}"
    echo -e "  ${CYAN}cl${NC} or ${CYAN}ca${NC}    - Launch Claude Assistant"
    
    if [[ " ${SELECTED_MODULES[@]} " =~ " rate-limit-manager " ]]; then
        echo -e "  ${CYAN}dash${NC}         - Open dashboard"
    fi
    
    if [[ " ${SELECTED_MODULES[@]} " =~ " pdf-generator " ]]; then
        echo -e "  ${CYAN}pdf${NC}          - Convert to PDF"
    fi
    
    if [[ " ${SELECTED_MODULES[@]} " =~ " voice-assistant " ]]; then
        echo -e "  ${CYAN}ca-voice${NC}     - Voice input"
    fi
    
    echo -e "\n${BOLD}Installation Location:${NC}"
    echo -e "  $CLAUDE_DIR"
    
    echo -e "\n${BOLD}Next Steps:${NC}"
    echo -e "  1. Restart your terminal or run: ${CYAN}source ~/.bashrc${NC}"
    echo -e "  2. Type ${CYAN}cl${NC} to start"
    
    if [ ! -f "$HOME/.pushover_config" ] && [[ " ${SELECTED_MODULES[@]} " =~ " notifications " ]]; then
        echo -e "  3. Configure notifications: Create ~/.pushover_config"
    fi
    
    echo -e "\n${BOLD}Documentation:${NC}"
    echo -e "  ${CYAN}cl help${NC}     - Show available commands"
    echo -e "  README at: $SCRIPT_DIR/README.md"
    
    echo ""
}

# Main installation flow
main() {
    # Check if running with --quick flag for non-interactive
    if [ "$1" = "--quick" ]; then
        SELECTED_MODULES=(core rate-limit-manager pdf-generator)
        print_header
        echo "Quick installation with recommended modules..."
        install_dependencies
        install_modules
        configure_shell
        finalize_installation
        show_summary
        exit 0
    fi
    
    # Interactive installation
    check_system
    select_modules
    configure_options
    
    print_header
    echo -e "${BOLD}Starting Installation...${NC}"
    
    install_dependencies
    install_modules
    configure_shell
    create_shortcuts
    finalize_installation
    
    show_summary
}

# Run installer
main "$@"