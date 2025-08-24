#!/bin/bash

# Claude Assistant Suite - One-Command Quick Setup
# Complete installation with all dependencies and configurations

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
BASHRC="$HOME/.bashrc"
ZSHRC="$HOME/.zshrc"

# Progress tracking
TOTAL_STEPS=10
CURRENT_STEP=0

# Functions
print_header() {
    clear
    echo -e "${BOLD}${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║        Claude Assistant Suite - One-Click Setup             ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}\n"
}

print_progress() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    local percentage=$((CURRENT_STEP * 100 / TOTAL_STEPS))
    local filled=$((CURRENT_STEP * 30 / TOTAL_STEPS))
    local empty=$((30 - filled))
    
    echo -ne "\r${BLUE}Progress: ["
    printf "%${filled}s" | tr ' ' '█'
    printf "%${empty}s" | tr ' ' '░'
    echo -ne "] ${percentage}% ${NC}"
    
    if [ "$1" ]; then
        echo -e "\n${GREEN}✓${NC} $1"
    fi
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
        echo "unknown"
    fi
}

# Step 1: Install system dependencies
install_system_deps() {
    local os_type=$(detect_os)
    
    echo -e "\n${BOLD}Installing System Dependencies...${NC}"
    
    case "$os_type" in
        macos)
            # Check for Homebrew
            if ! command -v brew &> /dev/null; then
                echo "Installing Homebrew..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            fi
            
            # Install dependencies
            brew install jq curl git python3 2>/dev/null || true
            
            # PDF tools (optional but recommended)
            echo "Installing PDF tools (optional)..."
            brew install pandoc 2>/dev/null || true
            brew install --cask wkhtmltopdf 2>/dev/null || true
            ;;
            
        linux|wsl)
            # Update package list
            sudo apt-get update -qq
            
            # Install dependencies
            sudo apt-get install -y -qq \
                jq curl git python3 python3-pip \
                build-essential 2>/dev/null || true
            
            # PDF tools (optional)
            echo "Installing PDF tools (optional)..."
            sudo apt-get install -y -qq pandoc wkhtmltopdf 2>/dev/null || true
            ;;
            
        *)
            echo -e "${YELLOW}Unknown OS. Please install manually: jq, curl, git, python3${NC}"
            ;;
    esac
    
    print_progress "System dependencies installed"
}

# Step 2: Install Python dependencies
install_python_deps() {
    echo -e "\n${BOLD}Installing Python Dependencies...${NC}"
    
    # Ensure pip is installed
    if ! command -v pip3 &> /dev/null; then
        curl https://bootstrap.pypa.io/get-pip.py -o /tmp/get-pip.py
        python3 /tmp/get-pip.py --user
        rm /tmp/get-pip.py
    fi
    
    # Install Python packages
    pip3 install --quiet --user \
        markdown2 pdfkit md2pdf pypandoc \
        SpeechRecognition pyttsx3 pyaudio 2>/dev/null || \
        echo -e "${YELLOW}Some Python packages may need manual installation${NC}"
    
    print_progress "Python dependencies installed"
}

# Step 3: Clone or update repository
setup_repository() {
    echo -e "\n${BOLD}Setting up Claude Assistant repository...${NC}"
    
    if [ -d "$SCRIPT_DIR/.git" ]; then
        # Already in repo, pull latest
        cd "$SCRIPT_DIR"
        git pull origin main 2>/dev/null || true
    else
        # Clone fresh if needed
        if [ ! -f "$SCRIPT_DIR/install.sh" ]; then
            echo "Cloning Claude Assistant repository..."
            git clone https://github.com/saralegui-solutions/claude-assistant.git /tmp/claude-assistant
            cp -r /tmp/claude-assistant/* "$SCRIPT_DIR/"
            rm -rf /tmp/claude-assistant
        fi
    fi
    
    print_progress "Repository ready"
}

# Step 4: Run main installer with all modules
install_all_modules() {
    echo -e "\n${BOLD}Installing all Claude Assistant modules...${NC}"
    
    cd "$SCRIPT_DIR"
    chmod +x install.sh
    
    # Run installer non-interactively with all modules
    echo "A" | ./install.sh --non-interactive
    
    print_progress "All modules installed"
}

# Step 5: Configure shell aliases
setup_aliases() {
    echo -e "\n${BOLD}Setting up shell aliases...${NC}"
    
    local shell_config=""
    local current_shell=$(detect_shell)
    
    # Determine which config file to use
    if [ -f "$ZSHRC" ] && [ "$current_shell" = "zsh" ]; then
        shell_config="$ZSHRC"
    elif [ -f "$BASHRC" ]; then
        shell_config="$BASHRC"
    else
        shell_config="$HOME/.profile"
    fi
    
    # Create alias block
    local alias_block="
# ============================================
# Claude Assistant Suite - Quick Access
# ============================================
export PATH=\"\$PATH:$CLAUDE_DIR\"

# Main launcher
alias ca='claude-assistant'
alias cad='claude-assistant dashboard'

# Quick commands
alias ca-dash='claude-assistant dashboard'           # Rate limit dashboard
alias ca-check='claude-assistant checkpoint'        # Create checkpoint
alias ca-ctx='claude-assistant context'            # Check context
alias ca-voice='claude-assistant voice'            # Voice input
alias ca-pdf='claude-assistant pdf'                # PDF generator
alias ca-limits='claude-assistant limits'          # Quick limits check

# PDF shortcuts
alias pdf='claude-pdf'                             # PDF generator direct
alias pdf-check='claude-pdf --check'               # Check PDF setup
alias pdf-batch='claude-pdf . ./pdfs --batch'      # Batch convert current dir

# Dashboard shortcut (auto-refresh)
alias dash='$CLAUDE_DIR/rate-limit-dashboard.sh'

# Quick status check
alias ca-status='echo \"Claude Assistant Status:\"; claude-assistant limits 2>/dev/null && echo \"✓ Ready\" || echo \"✗ Not configured\"'

# One-command project documentation
ca-docs() {
    echo \"Generating project documentation...\"
    find . -name \"*.md\" -type f | while read -r file; do
        claude-pdf \"\$file\" \"\${file%.md}.pdf\" 2>/dev/null
    done
    echo \"PDFs generated for all markdown files\"
}

# Export conversation to PDF
ca-export() {
    local latest=\"\$HOME/.claude/conversations/latest.md\"
    if [ -f \"\$latest\" ]; then
        claude-pdf \"\$latest\" \"claude_export_\$(date +%Y%m%d_%H%M%S).pdf\"
        echo \"Exported to PDF\"
    else
        echo \"No conversation to export\"
    fi
}

# Quick help
ca-help() {
    echo \"Claude Assistant Quick Commands:\"
    echo \"  ca         - Main launcher\"
    echo \"  ca-dash    - Rate limit dashboard\"
    echo \"  ca-check   - Create checkpoint\"
    echo \"  ca-voice   - Voice input\"
    echo \"  ca-pdf     - PDF generator\"
    echo \"  ca-docs    - Convert all .md to PDF\"
    echo \"  ca-export  - Export conversation to PDF\"
    echo \"  ca-status  - Check system status\"
    echo \"  dash       - Quick dashboard\"
    echo \"  claude-code - Claude with permissions bypass\"
}

# Claude Code alias (if not already present)
if ! grep -q \"alias claude-code=\" ~/.bashrc 2>/dev/null && ! grep -q \"alias claude-code=\" ~/.zshrc 2>/dev/null; then
    alias claude-code=\"claude --dangerously-skip-permissions\"
fi
# ============================================"
    
    # Check if aliases already exist
    if ! grep -q "Claude Assistant Suite" "$shell_config" 2>/dev/null; then
        echo "$alias_block" >> "$shell_config"
        echo -e "${GREEN}Aliases added to $shell_config${NC}"
    else
        echo -e "${YELLOW}Aliases already configured${NC}"
    fi
    
    print_progress "Shell aliases configured"
}

# Step 6: Create desktop launcher (optional)
create_desktop_launcher() {
    echo -e "\n${BOLD}Creating desktop launcher...${NC}"
    
    local desktop_file="$HOME/.local/share/applications/claude-assistant.desktop"
    
    if [ ! -d "$HOME/.local/share/applications" ]; then
        mkdir -p "$HOME/.local/share/applications"
    fi
    
    cat > "$desktop_file" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Claude Assistant Dashboard
Comment=Monitor Claude Code API usage and limits
Exec=gnome-terminal -- bash -c '$CLAUDE_DIR/rate-limit-dashboard.sh; read -p "Press enter to close"'
Icon=utilities-terminal
Terminal=false
Categories=Development;Utility;
EOF
    
    chmod +x "$desktop_file" 2>/dev/null || true
    
    print_progress "Desktop launcher created"
}

# Step 7: Configure Pushover (optional)
setup_pushover() {
    echo -e "\n${BOLD}Pushover Configuration (Optional)${NC}"
    
    if [ ! -f "$HOME/.pushover_config" ]; then
        echo -e "${YELLOW}Pushover not configured. To enable notifications:${NC}"
        echo "1. Get API keys from https://pushover.net"
        echo "2. Create ~/.pushover_config with:"
        echo "   PUSHOVER_USER_KEY=your_user_key"
        echo "   PUSHOVER_APP_TOKEN=your_app_token"
    fi
    
    print_progress "Notification setup checked"
}

# Step 8: Test installation
test_installation() {
    echo -e "\n${BOLD}Testing Installation...${NC}"
    
    local tests_passed=0
    local tests_total=5
    
    # Test 1: Claude directory exists
    if [ -d "$CLAUDE_DIR" ]; then
        ((tests_passed++))
        echo -e "${GREEN}✓${NC} Claude directory exists"
    else
        echo -e "${RED}✗${NC} Claude directory missing"
    fi
    
    # Test 2: Dashboard script exists
    if [ -f "$CLAUDE_DIR/rate-limit-dashboard.sh" ]; then
        ((tests_passed++))
        echo -e "${GREEN}✓${NC} Dashboard installed"
    else
        echo -e "${RED}✗${NC} Dashboard not found"
    fi
    
    # Test 3: PDF generator exists
    if [ -f "$CLAUDE_DIR/pdf-generator/pdf_generator.py" ]; then
        ((tests_passed++))
        echo -e "${GREEN}✓${NC} PDF generator installed"
    else
        echo -e "${RED}✗${NC} PDF generator not found"
    fi
    
    # Test 4: Python works
    if python3 -c "import markdown2" 2>/dev/null; then
        ((tests_passed++))
        echo -e "${GREEN}✓${NC} Python dependencies OK"
    else
        echo -e "${YELLOW}⚠${NC} Some Python dependencies missing"
        ((tests_passed++))
    fi
    
    # Test 5: Commands accessible
    if [ -f "$CLAUDE_DIR/claude-assistant" ]; then
        ((tests_passed++))
        echo -e "${GREEN}✓${NC} Commands configured"
    else
        echo -e "${RED}✗${NC} Commands not configured"
    fi
    
    echo -e "\nTests passed: $tests_passed/$tests_total"
    
    print_progress "Installation tested"
}

# Step 9: Create quick launcher
create_launcher() {
    echo -e "\n${BOLD}Creating quick launcher...${NC}"
    
    cat > "$CLAUDE_DIR/launch" << 'EOF'
#!/bin/bash
# Claude Assistant Quick Launcher

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

clear
echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║            Claude Assistant Suite - Quick Launch            ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo "Select an option:"
echo -e "${GREEN}1${NC}) Dashboard - Monitor API usage"
echo -e "${GREEN}2${NC}) Voice - Start voice input"
echo -e "${GREEN}3${NC}) PDF - Convert documents"
echo -e "${GREEN}4${NC}) Checkpoint - Save conversation"
echo -e "${GREEN}5${NC}) Context - Check token usage"
echo -e "${GREEN}6${NC}) Status - System check"
echo -e "${GREEN}7${NC}) Help - Show all commands"
echo -e "${GREEN}Q${NC}) Quit"
echo ""

read -p "Enter choice [1-7 or Q]: " choice

case $choice in
    1) ~/.claude/rate-limit-dashboard.sh ;;
    2) ~/.claude/claude-voice ;;
    3) 
        read -p "Input file: " input
        read -p "Output file: " output
        ~/.claude/claude-pdf "$input" "$output"
        ;;
    4) ~/.claude/hooks/auto-checkpoint.sh create ;;
    5) ~/.claude/hooks/context-manager.sh ;;
    6) 
        echo "Checking system..."
        ~/.claude/claude-assistant limits
        ~/.claude/claude-pdf --check
        ;;
    7) 
        ~/.claude/claude-assistant help
        echo ""
        echo "Press any key to continue..."
        read -n 1
        ;;
    [Qq]) exit 0 ;;
    *) echo "Invalid option" ;;
esac
EOF
    
    chmod +x "$CLAUDE_DIR/launch"
    
    # Add super quick alias
    local shell_config=""
    if [ -f "$HOME/.bashrc" ]; then
        shell_config="$HOME/.bashrc"
    elif [ -f "$HOME/.zshrc" ]; then
        shell_config="$HOME/.zshrc"
    fi
    
    if [ "$shell_config" ] && ! grep -q "alias cl=" "$shell_config" 2>/dev/null; then
        echo "alias cl='$CLAUDE_DIR/launch'" >> "$shell_config"
    fi
    
    print_progress "Quick launcher created"
}

# Step 10: Final configuration
finalize_setup() {
    echo -e "\n${BOLD}Finalizing setup...${NC}"
    
    # Ensure all scripts are executable
    chmod +x "$CLAUDE_DIR"/*.sh 2>/dev/null || true
    chmod +x "$CLAUDE_DIR/hooks"/*.sh 2>/dev/null || true
    chmod +x "$CLAUDE_DIR/pdf-generator"/*.py 2>/dev/null || true
    chmod +x "$CLAUDE_DIR/claude-"* 2>/dev/null || true
    
    # Create initial checkpoint directory
    mkdir -p "$CLAUDE_DIR/checkpoints"
    mkdir -p "$CLAUDE_DIR/conversations"
    
    print_progress "Setup finalized"
}

# Display completion message
show_completion() {
    clear
    echo -e "${BOLD}${GREEN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║         🎉 Claude Assistant Setup Complete! 🎉              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}\n"
    
    echo -e "${BOLD}Quick Access Commands:${NC}"
    echo -e "  ${CYAN}cl${NC}        - Quick launcher menu (easiest!)"
    echo -e "  ${CYAN}ca${NC}        - Claude assistant main"
    echo -e "  ${CYAN}dash${NC}      - Rate limit dashboard"
    echo -e "  ${CYAN}ca-voice${NC}  - Voice input"
    echo -e "  ${CYAN}ca-pdf${NC}    - PDF generator"
    echo -e "  ${CYAN}ca-help${NC}   - Show all commands"
    echo ""
    
    echo -e "${BOLD}Next Steps:${NC}"
    echo "1. Restart your terminal or run: source ~/.bashrc"
    echo "2. Type 'cl' to launch the quick menu"
    echo "3. Type 'dash' to open the dashboard"
    echo ""
    
    local os_type=$(detect_os)
    if [ "$os_type" = "macos" ] || [ "$os_type" = "linux" ]; then
        echo -e "${BOLD}Optional Enhancements:${NC}"
        echo "• Install Pushover for notifications"
        echo "• Install pandoc for better PDF quality"
        echo ""
    fi
    
    echo -e "${GREEN}Installation location:${NC} $CLAUDE_DIR"
    echo -e "${GREEN}Documentation:${NC} $SCRIPT_DIR/USER_GUIDE.md"
    echo ""
    
    # Test a command
    if command -v claude-assistant &> /dev/null || [ -f "$CLAUDE_DIR/claude-assistant" ]; then
        echo -e "${GREEN}✓ System ready!${NC} Restart terminal and type 'cl' to begin."
    else
        echo -e "${YELLOW}⚠ Restart terminal to activate commands${NC}"
    fi
}

# Main installation flow
main() {
    print_header
    
    echo -e "${BOLD}Starting automated setup...${NC}"
    echo "This will install all Claude Assistant components."
    echo ""
    
    # Run all installation steps
    install_system_deps
    install_python_deps
    setup_repository
    install_all_modules
    setup_aliases
    create_desktop_launcher
    setup_pushover
    test_installation
    create_launcher
    finalize_setup
    
    # Show completion
    show_completion
    
    # Offer to source bashrc immediately
    echo ""
    read -p "Source bashrc now to activate commands? (y/n): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [ -f "$HOME/.bashrc" ]; then
            source "$HOME/.bashrc"
            echo -e "${GREEN}✓ Commands activated! Type 'cl' to start.${NC}"
        elif [ -f "$HOME/.zshrc" ]; then
            source "$HOME/.zshrc"
            echo -e "${GREEN}✓ Commands activated! Type 'cl' to start.${NC}"
        fi
    else
        echo "Remember to restart your terminal or run: source ~/.bashrc"
    fi
}

# Run if not sourced
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi