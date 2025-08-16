#!/bin/bash

# Notifications Module - Master Installer
# Installs both sound and Pushover notifications for Claude Code

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
BOLD='\033[1m'

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

# Header
echo -e "${BOLD}${BLUE}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║           Claude Notifications Module Installer             ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""

# Check for installation type
echo "Select notification type to install:"
echo "  [1] Sound notifications (Zelda sounds)"
echo "  [2] Pushover mobile notifications"
echo "  [3] Both"
echo "  [Q] Quit"
echo ""

read -p "Enter your choice: " -n 1 -r choice
echo ""

case "$choice" in
    1)
        print_status "Installing sound notifications..."
        ./install-sound.sh
        ;;
    2)
        print_status "Installing Pushover notifications..."
        ./install-pushover.sh
        ;;
    3)
        print_status "Installing both notification types..."
        ./install-sound.sh
        ./install-pushover.sh
        ;;
    [Qq])
        print_info "Installation cancelled"
        exit 0
        ;;
    *)
        print_error "Invalid choice"
        exit 1
        ;;
esac

print_success "Notification module installation complete!"