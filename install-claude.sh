#!/bin/bash

# Claude Assistant - Universal One-Line Installer
# Run from anywhere: curl -sSL https://raw.githubusercontent.com/saralegui-solutions/claude-assistant/main/install-claude.sh | bash

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'
BOLD='\033[1m'

# Installation directory
INSTALL_DIR="$HOME/claude-assistant"
CLAUDE_DIR="$HOME/.claude"

echo -e "${BOLD}${CYAN}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║         Claude Assistant Suite - Universal Installer        ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}\n"

# Step 1: Check for git
if ! command -v git &> /dev/null; then
    echo -e "${YELLOW}Git not found. Installing...${NC}"
    if command -v apt-get &> /dev/null; then
        sudo apt-get update && sudo apt-get install -y git
    elif command -v brew &> /dev/null; then
        brew install git
    else
        echo -e "${RED}Please install git manually and run again${NC}"
        exit 1
    fi
fi

# Step 2: Clone repository
echo -e "${BLUE}[1/4]${NC} Downloading Claude Assistant..."
if [ -d "$INSTALL_DIR" ]; then
    echo "Updating existing installation..."
    cd "$INSTALL_DIR"
    git pull origin main
else
    git clone https://github.com/saralegui-solutions/claude-assistant.git "$INSTALL_DIR"
fi

# Step 3: Run quick setup
echo -e "${BLUE}[2/4]${NC} Running automated setup..."
cd "$INSTALL_DIR"
chmod +x quick-setup.sh
./quick-setup.sh

# Step 4: Add to PATH permanently
echo -e "${BLUE}[3/4]${NC} Configuring environment..."

# Detect shell
SHELL_CONFIG=""
if [ -n "$ZSH_VERSION" ]; then
    SHELL_CONFIG="$HOME/.zshrc"
elif [ -n "$BASH_VERSION" ]; then
    SHELL_CONFIG="$HOME/.bashrc"
else
    SHELL_CONFIG="$HOME/.profile"
fi

# Add one-line launcher to shell config
if ! grep -q "claude-quick" "$SHELL_CONFIG" 2>/dev/null; then
    cat >> "$SHELL_CONFIG" << 'EOF'

# Claude Assistant - Quick Launch (added by installer)
alias claude-quick='cd ~/claude-assistant && ./quick-setup.sh'
alias claude-update='cd ~/claude-assistant && git pull && ./quick-setup.sh'
EOF
fi

# Step 5: Create global launcher
echo -e "${BLUE}[4/4]${NC} Creating global launcher..."
sudo tee /usr/local/bin/claude-assistant > /dev/null << 'EOF'
#!/bin/bash
exec $HOME/.claude/claude-assistant "$@"
EOF
sudo chmod +x /usr/local/bin/claude-assistant 2>/dev/null || true

# Success message
echo ""
echo -e "${BOLD}${GREEN}✨ Installation Complete! ✨${NC}"
echo ""
echo -e "${BOLD}Quick Start:${NC}"
echo -e "  1. Restart terminal or run: ${CYAN}source ~/.bashrc${NC}"
echo -e "  2. Type: ${CYAN}cl${NC} for quick menu"
echo -e "  3. Type: ${CYAN}dash${NC} for dashboard"
echo ""
echo -e "${BOLD}Useful Commands:${NC}"
echo -e "  ${CYAN}cl${NC}             - Quick launcher (easiest!)"
echo -e "  ${CYAN}ca${NC}             - Claude assistant"
echo -e "  ${CYAN}dash${NC}           - Rate limit dashboard"
echo -e "  ${CYAN}ca-pdf${NC}         - PDF generator"
echo -e "  ${CYAN}ca-voice${NC}       - Voice input"
echo -e "  ${CYAN}claude-update${NC}  - Update installation"
echo ""
echo -e "${GREEN}Installation directory:${NC} $INSTALL_DIR"
echo -e "${GREEN}Claude home:${NC} $CLAUDE_DIR"