#!/bin/bash

# PDF Generator Module Installer
# Part of Claude Assistant Suite

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Paths
CLAUDE_DIR="$HOME/.claude"
MODULE_DIR="$(dirname "$0")"
INSTALL_DIR="$CLAUDE_DIR/pdf-generator"

# Functions
print_header() {
    echo -e "${BOLD}${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║              PDF Generator Module Installation              ║"
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

check_command() {
    command -v "$1" >/dev/null 2>&1
}

check_python_module() {
    python3 -c "import $1" 2>/dev/null
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
    local os_type=$(detect_os)
    
    print_status "Detecting system dependencies..."
    
    local missing_deps=()
    
    # Check for pandoc
    if ! check_command pandoc; then
        missing_deps+=("pandoc")
    else
        print_success "pandoc found"
    fi
    
    # Check for wkhtmltopdf
    if ! check_command wkhtmltopdf; then
        missing_deps+=("wkhtmltopdf")
    else
        print_success "wkhtmltopdf found"
    fi
    
    # Check for LaTeX (optional)
    if ! check_command pdflatex; then
        print_warning "LaTeX not found (optional for pandoc)"
    else
        print_success "LaTeX found"
    fi
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo -e "\n${BOLD}Missing system dependencies:${NC} ${missing_deps[*]}"
        echo -e "\n${BOLD}Installation commands:${NC}"
        
        case "$os_type" in
            macos)
                echo "  brew install ${missing_deps[*]}"
                if [[ " ${missing_deps[@]} " =~ " wkhtmltopdf " ]]; then
                    echo "  brew install --cask wkhtmltopdf"
                fi
                ;;
            linux|wsl)
                echo "  sudo apt update"
                echo "  sudo apt install ${missing_deps[*]}"
                ;;
            *)
                echo "  Please install: ${missing_deps[*]}"
                ;;
        esac
        
        echo -e "\n${YELLOW}Continue without these dependencies? Some features may be limited.${NC}"
        read -p "Continue? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

install_python_deps() {
    print_status "Checking Python dependencies..."
    
    local missing_modules=()
    local optional_modules=()
    
    # Required modules
    for module in markdown2; do
        if ! check_python_module "$module"; then
            missing_modules+=("$module")
        else
            print_success "$module installed"
        fi
    done
    
    # Optional modules
    for module in pdfkit md2pdf pypandoc weasyprint; do
        if ! check_python_module "$module"; then
            optional_modules+=("$module")
        else
            print_success "$module installed"
        fi
    done
    
    if [ ${#missing_modules[@]} -gt 0 ]; then
        print_warning "Installing required Python modules..."
        pip install ${missing_modules[*]}
    fi
    
    if [ ${#optional_modules[@]} -gt 0 ]; then
        echo -e "\n${BOLD}Optional Python modules not installed:${NC}"
        echo "  ${optional_modules[*]}"
        echo -e "\n${CYAN}Install for additional features:${NC}"
        echo "  pip install ${optional_modules[*]}"
    fi
}

install_module_files() {
    print_status "Installing PDF Generator module..."
    
    # Create installation directory
    mkdir -p "$INSTALL_DIR"
    
    # Copy module files
    cp "$MODULE_DIR/pdf_generator.py" "$INSTALL_DIR/"
    cp "$MODULE_DIR/config.json" "$INSTALL_DIR/"
    cp "$MODULE_DIR/custom.css" "$INSTALL_DIR/"
    cp "$MODULE_DIR/sample.md" "$INSTALL_DIR/"
    cp "$MODULE_DIR/README.md" "$INSTALL_DIR/"
    
    # Make script executable
    chmod +x "$INSTALL_DIR/pdf_generator.py"
    
    # Create convenience symlink
    ln -sf "$INSTALL_DIR/pdf_generator.py" "$CLAUDE_DIR/pdf-generator"
    
    print_success "Module files installed"
}

configure_claude_integration() {
    print_status "Configuring Claude Assistant integration..."
    
    # Add to PATH if not already there
    if ! grep -q "$CLAUDE_DIR" ~/.bashrc 2>/dev/null; then
        echo "export PATH=\"\$PATH:$CLAUDE_DIR\"" >> ~/.bashrc
        print_success "Added to PATH in ~/.bashrc"
    fi
    
    # Create convenience command
    cat > "$CLAUDE_DIR/claude-pdf" << 'EOF'
#!/bin/bash
# Claude PDF Generator wrapper

PDF_GEN="$HOME/.claude/pdf-generator/pdf_generator.py"

if [ ! -f "$PDF_GEN" ]; then
    echo "PDF Generator not installed. Run: claude-assistant install pdf-generator"
    exit 1
fi

python3 "$PDF_GEN" "$@"
EOF
    
    chmod +x "$CLAUDE_DIR/claude-pdf"
    print_success "Created claude-pdf command"
}

test_installation() {
    print_status "Testing installation..."
    
    # Test Python import
    if python3 -c "import sys; sys.path.insert(0, '$INSTALL_DIR'); import pdf_generator" 2>/dev/null; then
        print_success "Python module loads correctly"
    else
        print_error "Failed to load Python module"
        return 1
    fi
    
    # Test system check
    if python3 "$INSTALL_DIR/pdf_generator.py" --check >/dev/null 2>&1; then
        print_success "System check passed"
    else
        print_warning "System check reported issues"
    fi
    
    # Test sample conversion if possible
    if python3 "$INSTALL_DIR/pdf_generator.py" "$INSTALL_DIR/sample.md" "/tmp/test_output.pdf" 2>/dev/null; then
        print_success "Sample conversion successful"
        rm -f "/tmp/test_output.pdf"
    else
        print_warning "Sample conversion failed (may need additional dependencies)"
    fi
}

print_completion() {
    echo -e "\n${BOLD}${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${GREEN}║           PDF Generator Installation Complete!              ║${NC}"
    echo -e "${BOLD}${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    
    echo -e "\n${BOLD}Quick Start:${NC}"
    echo "  Check system:    claude-pdf --check"
    echo "  Convert file:    claude-pdf input.md output.pdf"
    echo "  Batch convert:   claude-pdf ./docs/ ./pdfs/ --batch"
    
    echo -e "\n${BOLD}Locations:${NC}"
    echo "  Module:     $INSTALL_DIR"
    echo "  Command:    $CLAUDE_DIR/claude-pdf"
    echo "  Config:     $INSTALL_DIR/config.json"
    
    echo -e "\n${BOLD}Next Steps:${NC}"
    
    # Check what's missing
    local recommendations=()
    
    if ! check_command pandoc; then
        recommendations+=("Install pandoc for best quality: brew install pandoc")
    fi
    
    if ! check_command wkhtmltopdf; then
        recommendations+=("Install wkhtmltopdf: brew install --cask wkhtmltopdf")
    fi
    
    if ! check_python_module pdfkit; then
        recommendations+=("Install Python modules: pip install pdfkit md2pdf")
    fi
    
    if [ ${#recommendations[@]} -gt 0 ]; then
        echo -e "${YELLOW}Recommended additions:${NC}"
        for rec in "${recommendations[@]}"; do
            echo "  • $rec"
        done
    else
        echo -e "${GREEN}  ✓ All recommended components installed${NC}"
    fi
    
    echo -e "\n${CYAN}Test with: claude-pdf --check${NC}"
}

# Main installation
main() {
    print_header
    
    # Check if already installed
    if [ -d "$INSTALL_DIR" ]; then
        print_warning "PDF Generator already installed at $INSTALL_DIR"
        read -p "Reinstall? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 0
        fi
        rm -rf "$INSTALL_DIR"
    fi
    
    # Create Claude directory if needed
    mkdir -p "$CLAUDE_DIR"
    
    # Installation steps
    install_system_deps
    install_python_deps
    install_module_files
    configure_claude_integration
    test_installation
    
    print_completion
}

# Run main function
main "$@"