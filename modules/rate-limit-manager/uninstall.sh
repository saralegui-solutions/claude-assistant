#!/bin/bash

# Claude Rate Limit Manager - Uninstallation Script
# Removes all components of the rate limit monitoring system

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Installation paths
CLAUDE_DIR="$HOME/.claude"
HOOKS_DIR="$CLAUDE_DIR/hooks"
CHECKPOINTS_DIR="$CLAUDE_DIR/checkpoints"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"
CONFIG_FILE="$CLAUDE_DIR/rate-limit-config.json"

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
echo -e "${BOLD}${RED}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║        Claude Code Rate Limit Manager Uninstaller           ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""

# Confirmation
echo -e "${YELLOW}This will remove all Rate Limit Manager components.${NC}"
echo -e "${YELLOW}Your checkpoints will be preserved unless you choose otherwise.${NC}"
echo ""
read -p "Are you sure you want to uninstall? (y/N): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_warning "Uninstallation cancelled"
    exit 0
fi

# Step 1: Remove hook scripts
print_status "Removing hook scripts..."

rm -f "$HOOKS_DIR/rate-limit-monitor.sh"
rm -f "$HOOKS_DIR/auto-checkpoint.sh"
rm -f "$HOOKS_DIR/context-manager.sh"

print_success "Hook scripts removed"

# Step 2: Remove dashboard
print_status "Removing dashboard..."

rm -f "$CLAUDE_DIR/rate-limit-dashboard.sh"

print_success "Dashboard removed"

# Step 3: Remove configuration
print_status "Removing configuration files..."

rm -f "$CONFIG_FILE"

print_success "Configuration removed"

# Step 4: Clean up settings.json
print_status "Cleaning up hook configurations..."

if [ -f "$SETTINGS_FILE" ]; then
    # Backup current settings
    cp "$SETTINGS_FILE" "$SETTINGS_FILE.backup.uninstall.$(date +%Y%m%d-%H%M%S)"
    print_success "Settings backed up"
    
    # Check if jq is available for clean removal
    if command -v jq &> /dev/null; then
        # Remove rate limit manager hooks while preserving other hooks
        jq 'if .hooks.PreToolUse then 
                .hooks.PreToolUse[0].hooks |= map(select(.command | contains("rate-limit-monitor.sh") | not))
            else . end |
            if .hooks.PostToolUse then
                .hooks.PostToolUse[0].hooks |= map(select(.command | contains("rate-limit-monitor.sh") | not)) |
                .hooks.PostToolUse[0].hooks |= map(select(.command | contains("context-manager.sh") | not))
            else . end |
            if .hooks.UserPromptSubmit then
                .hooks.UserPromptSubmit[0].hooks |= map(select(.command | contains("rate-limit-monitor.sh") | not))
            else . end |
            if .hooks.PreCompact then
                .hooks.PreCompact[0].hooks |= map(select(.command | contains("auto-checkpoint.sh") | not))
            else . end |
            if .hooks.Stop then
                .hooks.Stop[0].hooks |= map(select(.command | contains("auto-checkpoint.sh") | not))
            else . end' "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp" && mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
        
        print_success "Hook configurations removed from settings"
    else
        print_warning "jq not available. Please manually remove hook configurations from $SETTINGS_FILE"
        echo "Look for references to: rate-limit-monitor.sh, auto-checkpoint.sh, context-manager.sh"
    fi
else
    print_warning "Settings file not found"
fi

# Step 5: Handle checkpoints
echo ""
read -p "Do you want to remove saved checkpoints? (y/N): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_status "Removing checkpoints..."
    rm -rf "$CHECKPOINTS_DIR"
    print_success "Checkpoints removed"
else
    print_success "Checkpoints preserved at $CHECKPOINTS_DIR"
fi

# Step 6: Clean up temporary files
print_status "Cleaning up temporary files..."

rm -f /tmp/claude-rate-limits.json
rm -f /tmp/claude-context-metrics.json
rm -f /tmp/claude-suggest-compact
rm -f /tmp/claude-open-files.txt
rm -f /tmp/claude-session-metadata.json
rm -f /tmp/claude-rate-monitor.log
rm -f /tmp/claude-checkpoint.log
rm -f /tmp/claude-context-manager.log

print_success "Temporary files cleaned"

# Step 7: Remove aliases
if [ -f "$HOME/.claude_aliases" ]; then
    print_status "Removing convenience aliases..."
    rm -f "$HOME/.claude_aliases"
    print_success "Aliases removed"
    print_warning "Remember to remove 'source ~/.claude_aliases' from your shell profile"
fi

# Final summary
echo ""
echo -e "${BOLD}${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${GREEN}║            Uninstallation Complete!                         ║${NC}"
echo -e "${BOLD}${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BOLD}Removed:${NC}"
echo "  • Hook scripts from $HOOKS_DIR"
echo "  • Dashboard from $CLAUDE_DIR"
echo "  • Configuration files"
echo "  • Temporary files"
echo ""

if [ -d "$CHECKPOINTS_DIR" ]; then
    echo -e "${BOLD}Preserved:${NC}"
    echo "  • Checkpoints at $CHECKPOINTS_DIR"
    echo ""
fi

if [ -f "$SETTINGS_FILE.backup.uninstall."* ]; then
    echo -e "${BOLD}Backups:${NC}"
    echo "  • Settings backup: $SETTINGS_FILE.backup.uninstall.*"
    echo ""
fi

print_success "Claude Rate Limit Manager has been uninstalled"
echo ""
echo "To reinstall, run: ./install.sh"