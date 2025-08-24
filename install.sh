#!/bin/bash

# Claude Assistant - Master Installer
# Comprehensive suite of tools for enhancing Claude Code experience

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Installation paths
CLAUDE_DIR="$HOME/.claude"
HOOKS_DIR="$CLAUDE_DIR/hooks"
CHECKPOINTS_DIR="$CLAUDE_DIR/checkpoints"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Available modules
declare -A MODULES=(
    ["rate-limit-manager"]="Rate Limit Manager - Prevent 500 errors with smart monitoring"
    ["notifications"]="Notifications - Get alerts for Claude Code events"
    ["voice-assistant"]="Voice Assistant - Voice input/output for Claude"
    ["pdf-generator"]="PDF Generator - Convert markdown and documents to professional PDFs"
    ["api-orchestrator"]="API Orchestrator - Automated Claude API + Code workflow coordination"
)

# Function to print colored output
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

print_info() {
    echo -e "${CYAN}[i]${NC} $1"
}

# Header
display_header() {
    echo -e "${BOLD}${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                   Claude Assistant Suite                    ║"
    echo "║         Comprehensive Tools for Claude Code Enhancement     ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
}

# Parse command line arguments
SELECTED_MODULES=()
INSTALL_ALL=false
UPDATE_MODE=false
INTERACTIVE=true

while [[ $# -gt 0 ]]; do
    case $1 in
        --all)
            INSTALL_ALL=true
            shift
            ;;
        --module)
            SELECTED_MODULES+=("$2")
            INTERACTIVE=false
            shift 2
            ;;
        --update)
            UPDATE_MODE=true
            shift
            ;;
        --non-interactive)
            INTERACTIVE=false
            shift
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --all              Install all modules"
            echo "  --module NAME      Install specific module"
            echo "  --update           Update existing installation"
            echo "  --non-interactive  Run without prompts"
            echo "  --help             Show this help message"
            echo ""
            echo "Available modules:"
            for module in "${!MODULES[@]}"; do
                echo "  - $module: ${MODULES[$module]}"
            done
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Interactive module selection
select_modules() {
    if [ "$INSTALL_ALL" = true ]; then
        SELECTED_MODULES=("${!MODULES[@]}")
        return
    fi
    
    if [ ${#SELECTED_MODULES[@]} -gt 0 ]; then
        return
    fi
    
    if [ "$INTERACTIVE" = false ]; then
        SELECTED_MODULES=("${!MODULES[@]}")
        return
    fi
    
    echo -e "${BOLD}Select modules to install:${NC}"
    echo ""
    
    local i=1
    local module_array=()
    for module in "${!MODULES[@]}"; do
        module_array+=("$module")
        echo "  [$i] $module"
        echo "      ${MODULES[$module]}"
        echo ""
        ((i++))
    done
    
    echo "  [A] All modules"
    echo "  [Q] Quit"
    echo ""
    
    read -p "Enter your choice (numbers separated by space, or A/Q): " -r choice
    
    if [[ "$choice" =~ ^[Qq]$ ]]; then
        print_info "Installation cancelled"
        exit 0
    elif [[ "$choice" =~ ^[Aa]$ ]]; then
        SELECTED_MODULES=("${!MODULES[@]}")
    else
        for num in $choice; do
            if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le "${#module_array[@]}" ]; then
                SELECTED_MODULES+=("${module_array[$((num-1))]}")
            fi
        done
    fi
    
    if [ ${#SELECTED_MODULES[@]} -eq 0 ]; then
        print_warning "No modules selected"
        exit 0
    fi
}

# Check and install dependencies
install_dependencies() {
    print_status "Checking dependencies..."
    
    # Check for jq (needed for rate-limit-manager and others)
    if ! command -v jq &> /dev/null; then
        print_warning "jq not found. Installing..."
        if command -v apt-get &> /dev/null; then
            sudo apt-get update && sudo apt-get install -y jq
        elif command -v brew &> /dev/null; then
            brew install jq
        elif command -v yum &> /dev/null; then
            sudo yum install -y jq
        else
            print_error "Could not install jq. Please install it manually."
            exit 1
        fi
        print_success "jq installed"
    fi
    
    # Check for curl (needed for notifications)
    if ! command -v curl &> /dev/null; then
        print_warning "curl not found. Installing..."
        if command -v apt-get &> /dev/null; then
            sudo apt-get install -y curl
        elif command -v brew &> /dev/null; then
            brew install curl
        else
            print_error "Could not install curl. Please install it manually."
            exit 1
        fi
        print_success "curl installed"
    fi
    
    print_success "All dependencies satisfied"
}

# Create necessary directories
create_directories() {
    print_status "Creating directories..."
    
    mkdir -p "$HOOKS_DIR"
    mkdir -p "$CHECKPOINTS_DIR"
    mkdir -p "$CLAUDE_DIR/conversations"
    mkdir -p "$CLAUDE_DIR/config"
    
    print_success "Directories created"
}

# Backup existing configuration
backup_configuration() {
    if [ -f "$SETTINGS_FILE" ] && [ "$UPDATE_MODE" = false ]; then
        local backup_file="$SETTINGS_FILE.backup.$(date +%Y%m%d-%H%M%S)"
        cp "$SETTINGS_FILE" "$backup_file"
        print_success "Backed up settings to $backup_file"
    fi
}

# Install Rate Limit Manager module
install_rate_limit_manager() {
    print_status "Installing Rate Limit Manager..."
    
    local module_dir="$SCRIPT_DIR/modules/rate-limit-manager"
    
    # Copy hook scripts
    cp "$module_dir/hooks/"*.sh "$HOOKS_DIR/" 2>/dev/null || true
    chmod +x "$HOOKS_DIR/rate-limit-monitor.sh"
    chmod +x "$HOOKS_DIR/auto-checkpoint.sh"
    chmod +x "$HOOKS_DIR/context-manager.sh"
    
    # Copy dashboard
    cp "$module_dir/rate-limit-dashboard.sh" "$CLAUDE_DIR/"
    chmod +x "$CLAUDE_DIR/rate-limit-dashboard.sh"
    
    # Copy configuration
    if [ ! -f "$CLAUDE_DIR/rate-limit-config.json" ]; then
        cp "$module_dir/rate-limit-config.json" "$CLAUDE_DIR/"
    fi
    
    print_success "Rate Limit Manager installed"
}

# Install Notifications module
install_notifications() {
    print_status "Installing Notifications..."
    
    local module_dir="$SCRIPT_DIR/modules/notifications"
    
    # Copy notification scripts
    cp "$module_dir/"*.sh "$HOOKS_DIR/" 2>/dev/null || true
    chmod +x "$HOOKS_DIR/pushover-notify.sh" 2>/dev/null || true
    chmod +x "$HOOKS_DIR/notify.sh" 2>/dev/null || true
    
    # Check for notification configuration
    if [ ! -f "$HOME/.pushover_config" ]; then
        print_warning "Pushover configuration not found"
        echo "To enable Pushover notifications:"
        echo "  1. Create ~/.pushover_config with:"
        echo "     PUSHOVER_USER_KEY=your_user_key"
        echo "     PUSHOVER_APP_TOKEN=your_app_token"
    fi
    
    print_success "Notifications installed"
}

# Install Voice Assistant module
install_voice_assistant() {
    print_status "Installing Voice Assistant..."
    
    local module_dir="$SCRIPT_DIR/modules/voice-assistant"
    
    # Copy voice scripts
    cp "$module_dir/claude-voice"* "$HOME/.local/bin/" 2>/dev/null || \
        cp "$module_dir/claude-voice"* "$HOME/bin/" 2>/dev/null || \
        cp "$module_dir/claude-voice"* "$CLAUDE_DIR/" 2>/dev/null || true
    
    cp "$module_dir/voice"*.py "$CLAUDE_DIR/" 2>/dev/null || true
    cp "$module_dir/"*.sh "$CLAUDE_DIR/" 2>/dev/null || true
    
    # Make executable
    chmod +x "$CLAUDE_DIR/claude-voice"* 2>/dev/null || true
    chmod +x "$CLAUDE_DIR/voice"*.py 2>/dev/null || true
    
    # Check for Python dependencies
    if command -v python3 &> /dev/null; then
        print_info "Checking Python dependencies for voice assistant..."
        python3 -m pip install --quiet pyaudio speech_recognition pyttsx3 2>/dev/null || \
            print_warning "Some voice dependencies may need manual installation"
    fi
    
    print_success "Voice Assistant installed"
}

# Install PDF Generator module
install_pdf_generator() {
    print_status "Installing PDF Generator..."
    
    local module_dir="$SCRIPT_DIR/modules/pdf-generator"
    
    # Create PDF generator directory
    mkdir -p "$CLAUDE_DIR/pdf-generator"
    
    # Copy PDF generator files
    cp "$module_dir/pdf_generator.py" "$CLAUDE_DIR/pdf-generator/"
    cp "$module_dir/config.json" "$CLAUDE_DIR/pdf-generator/"
    cp "$module_dir/custom.css" "$CLAUDE_DIR/pdf-generator/"
    cp "$module_dir/sample.md" "$CLAUDE_DIR/pdf-generator/"
    cp "$module_dir/README.md" "$CLAUDE_DIR/pdf-generator/"
    
    # Make executable
    chmod +x "$CLAUDE_DIR/pdf-generator/pdf_generator.py"
    
    # Create convenience command
    cat > "$CLAUDE_DIR/claude-pdf" << 'EOPDF'
#!/bin/bash
# Claude PDF Generator wrapper

PDF_GEN="$HOME/.claude/pdf-generator/pdf_generator.py"

if [ ! -f "$PDF_GEN" ]; then
    echo "PDF Generator not installed. Run: claude-assistant install pdf-generator"
    exit 1
fi

python3 "$PDF_GEN" "$@"
EOPDF
    
    chmod +x "$CLAUDE_DIR/claude-pdf"
    
    # Check for Python dependencies
    if command -v python3 &> /dev/null; then
        print_info "Checking Python dependencies for PDF generator..."
        python3 -m pip list | grep -q markdown2 || \
            print_warning "Install Python packages for best results: pip install markdown2 pdfkit md2pdf pypandoc"
    fi
    
    # Check for system tools
    if ! command -v pandoc &> /dev/null && ! command -v wkhtmltopdf &> /dev/null; then
        print_warning "For best PDF quality, install: pandoc or wkhtmltopdf"
    fi
    
    print_success "PDF Generator installed"
}

# Install API Orchestrator module
install_api_orchestrator() {
    print_status "Installing API Orchestrator..."
    
    local module_dir="$SCRIPT_DIR/modules/api-orchestrator"
    
    # Create orchestrator directories
    mkdir -p "$CLAUDE_DIR/modules/api-orchestrator"
    mkdir -p "$CLAUDE_DIR/orchestrated-sessions"
    
    # Copy orchestrator script
    if [ -f "$module_dir/orchestrator.py" ]; then
        cp "$module_dir/orchestrator.py" "$CLAUDE_DIR/modules/api-orchestrator/"
        chmod +x "$CLAUDE_DIR/modules/api-orchestrator/orchestrator.py"
    fi
    
    # Create wrapper script
    cat > "$CLAUDE_DIR/claude-orchestrate" << 'EOORCH'
#!/bin/bash
# Claude Orchestrator wrapper

ORCHESTRATOR="$HOME/.claude/modules/api-orchestrator/orchestrator.py"

if [ ! -f "$ORCHESTRATOR" ]; then
    echo "Orchestrator not installed. Run: claude-assistant install api-orchestrator"
    exit 1
fi

if ! command -v python3 &> /dev/null; then
    echo "Python 3 is required but not installed!"
    exit 1
fi

python3 "$ORCHESTRATOR" "$@"
EOORCH
    
    chmod +x "$CLAUDE_DIR/claude-orchestrate"
    
    # Check for Python dependencies
    if command -v python3 &> /dev/null && command -v pip3 &> /dev/null; then
        print_info "Checking Python dependencies for orchestrator..."
        python3 -m pip list 2>/dev/null | grep -q anthropic || \
            print_warning "Install anthropic package: pip3 install anthropic"
    fi
    
    print_success "API Orchestrator installed"
}

# Configure hooks in settings.json
configure_hooks() {
    print_status "Configuring Claude Code hooks..."
    
    # Create base settings if doesn't exist
    if [ ! -f "$SETTINGS_FILE" ]; then
        echo '{"hooks": {}}' > "$SETTINGS_FILE"
    fi
    
    # Merge hook configurations based on installed modules
    local hooks_config='{"hooks": {}}'
    
    if [[ " ${SELECTED_MODULES[@]} " =~ " rate-limit-manager " ]]; then
        hooks_config=$(echo "$hooks_config" | jq '.hooks += {
            "PreToolUse": [{
                "matcher": ".*",
                "hooks": [{
                    "type": "command",
                    "command": "'"$HOOKS_DIR"'/rate-limit-monitor.sh",
                    "timeout": 3000
                }]
            }],
            "PostToolUse": [{
                "matcher": ".*",
                "hooks": [
                    {
                        "type": "command",
                        "command": "'"$HOOKS_DIR"'/rate-limit-monitor.sh",
                        "timeout": 3000
                    },
                    {
                        "type": "command",
                        "command": "'"$HOOKS_DIR"'/context-manager.sh analyze",
                        "timeout": 2000
                    }
                ]
            }],
            "PreCompact": [{
                "matcher": ".*",
                "hooks": [{
                    "type": "command",
                    "command": "'"$HOOKS_DIR"'/auto-checkpoint.sh pre-compact",
                    "timeout": 5000
                }]
            }]
        }')
    fi
    
    if [[ " ${SELECTED_MODULES[@]} " =~ " notifications " ]]; then
        hooks_config=$(echo "$hooks_config" | jq '.hooks += {
            "Notification": [{
                "matcher": ".*",
                "hooks": [{
                    "type": "command",
                    "command": "'"$HOOKS_DIR"'/pushover-notify.sh",
                    "timeout": 5000
                }]
            }],
            "Stop": [{
                "matcher": ".*",
                "hooks": [{
                    "type": "command",
                    "command": "'"$HOOKS_DIR"'/pushover-notify.sh",
                    "timeout": 5000
                }]
            }]
        }')
    fi
    
    # Merge with existing settings
    if [ "$UPDATE_MODE" = true ]; then
        jq -s '.[0] * .[1]' "$SETTINGS_FILE" <(echo "$hooks_config") > "$SETTINGS_FILE.tmp"
        mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
    else
        echo "$hooks_config" > "$SETTINGS_FILE"
    fi
    
    print_success "Hooks configured"
}

# Create convenience script
create_convenience_script() {
    print_status "Creating convenience commands..."
    
    cat > "$CLAUDE_DIR/claude-assistant" << 'EOF'
#!/bin/bash

# Claude Assistant - Command Line Interface

case "$1" in
    dashboard)
        ~/.claude/rate-limit-dashboard.sh
        ;;
    checkpoint)
        ~/.claude/hooks/auto-checkpoint.sh ${@:2}
        ;;
    context)
        ~/.claude/hooks/context-manager.sh ${@:2}
        ;;
    limits)
        ~/.claude/hooks/rate-limit-monitor.sh
        ;;
    voice)
        ~/.claude/claude-voice ${@:2}
        ;;
    pdf)
        ~/.claude/claude-pdf ${@:2}
        ;;
    config)
        ${EDITOR:-nano} ~/.claude/rate-limit-config.json
        ;;
    help)
        echo "Claude Assistant Commands:"
        echo "  dashboard  - Launch rate limit dashboard"
        echo "  checkpoint - Manage checkpoints"
        echo "  context    - Check context status"
        echo "  limits     - Check current rate limits"
        echo "  voice      - Start voice assistant"
        echo "  pdf        - Convert documents to PDF"
        echo "  config     - Edit configuration"
        echo "  help       - Show this help"
        ;;
    *)
        echo "Usage: claude-assistant [command]"
        echo "Run 'claude-assistant help' for available commands"
        ;;
esac
EOF
    
    chmod +x "$CLAUDE_DIR/claude-assistant"
    
    # Add to PATH if not already there
    if ! echo "$PATH" | grep -q "$CLAUDE_DIR"; then
        print_info "Add this to your shell profile to use 'claude-assistant' command:"
        echo "  export PATH=\"\$PATH:$CLAUDE_DIR\""
    fi
    
    # Add claude-code alias to shell profile
    local shell_config=""
    if [ -f "$HOME/.zshrc" ]; then
        shell_config="$HOME/.zshrc"
    elif [ -f "$HOME/.bashrc" ]; then
        shell_config="$HOME/.bashrc"
    else
        shell_config="$HOME/.profile"
    fi
    
    if ! grep -q "alias claude-code=" "$shell_config" 2>/dev/null; then
        echo "" >> "$shell_config"
        echo "# Claude Code alias" >> "$shell_config"
        echo "alias claude-code='claude --dangerously-skip-permissions'" >> "$shell_config"
        print_success "Added claude-code alias to $shell_config"
    fi
    
    print_success "Convenience commands created"
}

# Display summary
display_summary() {
    echo ""
    echo -e "${BOLD}${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${GREEN}║            Claude Assistant Installation Complete!          ║${NC}"
    echo -e "${BOLD}${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${BOLD}Installed Modules:${NC}"
    for module in "${SELECTED_MODULES[@]}"; do
        echo "  ✓ $module"
    done
    echo ""
    
    echo -e "${BOLD}Quick Start:${NC}"
    
    if [[ " ${SELECTED_MODULES[@]} " =~ " rate-limit-manager " ]]; then
        echo "  Rate Limit Dashboard:"
        echo "    $CLAUDE_DIR/rate-limit-dashboard.sh"
        echo ""
    fi
    
    if [[ " ${SELECTED_MODULES[@]} " =~ " notifications " ]]; then
        echo "  Configure Notifications:"
        echo "    Create ~/.pushover_config with your API keys"
        echo ""
    fi
    
    if [[ " ${SELECTED_MODULES[@]} " =~ " voice-assistant " ]]; then
        echo "  Voice Assistant:"
        echo "    $CLAUDE_DIR/claude-voice"
        echo ""
    fi
    
    if [[ " ${SELECTED_MODULES[@]} " =~ " pdf-generator " ]]; then
        echo "  PDF Generator:"
        echo "    $CLAUDE_DIR/claude-pdf"
        echo "    Test: claude-pdf --check"
        echo ""
    fi
    
    if [[ " ${SELECTED_MODULES[@]} " =~ " api-orchestrator " ]]; then
        echo "  API Orchestrator:"
        echo "    $CLAUDE_DIR/claude-orchestrate"
        echo "    Voice: claude-orchestrate (no args)"
        echo "    Text: claude-orchestrate 'your request'"
        echo ""
    fi
    
    echo -e "${BOLD}Configuration Files:${NC}"
    echo "  • Settings: $SETTINGS_FILE"
    echo "  • Rate Limits: $CLAUDE_DIR/rate-limit-config.json"
    echo ""
    
    echo -e "${BOLD}Documentation:${NC}"
    echo "  • README: $SCRIPT_DIR/README.md"
    echo "  • Module docs: $SCRIPT_DIR/modules/*/README.md"
    echo ""
    
    if [ -z "${ANTHROPIC_API_KEY:-}" ]; then
        print_warning "Remember to set your API key:"
        echo "  export ANTHROPIC_API_KEY=\"sk-ant-api03-...\""
    fi
}

# Main installation flow
main() {
    display_header
    
    if [ "$UPDATE_MODE" = true ]; then
        print_info "Running in update mode"
    fi
    
    # Select modules to install
    select_modules
    
    print_info "Installing modules: ${SELECTED_MODULES[*]}"
    echo ""
    
    # Installation steps
    install_dependencies
    create_directories
    backup_configuration
    
    # Install selected modules
    for module in "${SELECTED_MODULES[@]}"; do
        case $module in
            rate-limit-manager)
                install_rate_limit_manager
                ;;
            notifications)
                install_notifications
                ;;
            voice-assistant)
                install_voice_assistant
                ;;
            pdf-generator)
                install_pdf_generator
                ;;
            api-orchestrator)
                install_api_orchestrator
                ;;
        esac
    done
    
    # Configure and finalize
    configure_hooks
    create_convenience_script
    
    # Show summary
    display_summary
}

# Run main installation
main