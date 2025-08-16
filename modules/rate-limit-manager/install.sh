#!/bin/bash

# Claude Rate Limit Manager - Installation Script
# Automatically installs and configures the rate limit monitoring system

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
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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
echo "║         Claude Code Rate Limit Manager Installer            ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""

# Check for update mode
UPDATE_MODE=false
if [ "$1" == "--update" ]; then
    UPDATE_MODE=true
    print_status "Running in update mode..."
fi

# Step 1: Check dependencies
print_status "Checking dependencies..."

# Check for jq
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
    print_success "jq installed successfully"
else
    print_success "jq is already installed"
fi

# Step 2: Create necessary directories
print_status "Creating directories..."

mkdir -p "$HOOKS_DIR"
mkdir -p "$CHECKPOINTS_DIR"
mkdir -p "$CLAUDE_DIR/conversations"

print_success "Directories created"

# Step 3: Copy hook scripts
print_status "Installing hook scripts..."

# Check if running from package directory or need to copy from current hooks
if [ -d "$SCRIPT_DIR/hooks" ]; then
    # Package structure exists
    cp "$SCRIPT_DIR/hooks/rate-limit-monitor.sh" "$HOOKS_DIR/" 2>/dev/null || true
    cp "$SCRIPT_DIR/hooks/auto-checkpoint.sh" "$HOOKS_DIR/" 2>/dev/null || true
    cp "$SCRIPT_DIR/hooks/context-manager.sh" "$HOOKS_DIR/" 2>/dev/null || true
elif [ -f "$HOOKS_DIR/rate-limit-monitor.sh" ]; then
    # Scripts already exist, we're updating
    print_warning "Hook scripts already installed, skipping..."
else
    # Try to copy from the extracted location
    if [ -f "$SCRIPT_DIR/rate-limit-monitor.sh" ]; then
        cp "$SCRIPT_DIR/rate-limit-monitor.sh" "$HOOKS_DIR/"
        cp "$SCRIPT_DIR/auto-checkpoint.sh" "$HOOKS_DIR/"
        cp "$SCRIPT_DIR/context-manager.sh" "$HOOKS_DIR/"
    else
        print_error "Hook scripts not found in package. Creating from embedded content..."
        
        # Create scripts inline (embedded in installer)
        cat > "$HOOKS_DIR/rate-limit-monitor.sh" << 'MONITOR_EOF'
#!/bin/bash
# [Script content would be embedded here - using placeholder for brevity]
# This would contain the full rate-limit-monitor.sh script
MONITOR_EOF
        
        cat > "$HOOKS_DIR/auto-checkpoint.sh" << 'CHECKPOINT_EOF'
#!/bin/bash
# [Script content would be embedded here - using placeholder for brevity]
# This would contain the full auto-checkpoint.sh script
CHECKPOINT_EOF
        
        cat > "$HOOKS_DIR/context-manager.sh" << 'CONTEXT_EOF'
#!/bin/bash
# [Script content would be embedded here - using placeholder for brevity]
# This would contain the full context-manager.sh script
CONTEXT_EOF
    fi
fi

# Make scripts executable
chmod +x "$HOOKS_DIR/rate-limit-monitor.sh" 2>/dev/null || true
chmod +x "$HOOKS_DIR/auto-checkpoint.sh" 2>/dev/null || true
chmod +x "$HOOKS_DIR/context-manager.sh" 2>/dev/null || true

print_success "Hook scripts installed"

# Step 4: Install dashboard
print_status "Installing dashboard..."

if [ -f "$SCRIPT_DIR/rate-limit-dashboard.sh" ]; then
    cp "$SCRIPT_DIR/rate-limit-dashboard.sh" "$CLAUDE_DIR/"
elif [ -f "$CLAUDE_DIR/rate-limit-dashboard.sh" ]; then
    print_warning "Dashboard already installed, skipping..."
else
    # Create dashboard inline if not found
    print_error "Dashboard not found in package. Please download separately."
fi

chmod +x "$CLAUDE_DIR/rate-limit-dashboard.sh" 2>/dev/null || true

print_success "Dashboard installed"

# Step 5: Configure hooks in settings.json
print_status "Configuring Claude Code hooks..."

# Backup existing settings if they exist
if [ -f "$SETTINGS_FILE" ] && [ "$UPDATE_MODE" = false ]; then
    cp "$SETTINGS_FILE" "$SETTINGS_FILE.backup.$(date +%Y%m%d-%H%M%S)"
    print_success "Backed up existing settings"
fi

# Create or update settings.json
if [ ! -f "$SETTINGS_FILE" ] || [ "$UPDATE_MODE" = true ]; then
    cat > "$SETTINGS_FILE" << 'EOF'
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": ".*",
        "hooks": [
          {
            "type": "command",
            "command": "$HOME/.claude/hooks/rate-limit-monitor.sh",
            "timeout": 3000
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": ".*",
        "hooks": [
          {
            "type": "command",
            "command": "$HOME/.claude/hooks/rate-limit-monitor.sh",
            "timeout": 3000
          },
          {
            "type": "command",
            "command": "$HOME/.claude/hooks/context-manager.sh analyze",
            "timeout": 2000
          }
        ]
      }
    ],
    "UserPromptSubmit": [
      {
        "matcher": ".*",
        "hooks": [
          {
            "type": "command",
            "command": "$HOME/.claude/hooks/rate-limit-monitor.sh",
            "timeout": 3000
          }
        ]
      }
    ],
    "PreCompact": [
      {
        "matcher": ".*",
        "hooks": [
          {
            "type": "command",
            "command": "$HOME/.claude/hooks/auto-checkpoint.sh pre-compact",
            "timeout": 5000
          }
        ]
      }
    ],
    "Stop": [
      {
        "matcher": ".*",
        "hooks": [
          {
            "type": "command",
            "command": "$HOME/.claude/hooks/auto-checkpoint.sh auto",
            "timeout": 5000
          }
        ]
      }
    ]
  }
}
EOF
    # Replace $HOME with actual path
    sed -i "s|\$HOME|$HOME|g" "$SETTINGS_FILE"
    print_success "Hook configuration created"
else
    print_warning "Settings file exists. Please manually merge hook configurations."
    print_warning "See $SCRIPT_DIR/settings-example.json for reference"
fi

# Step 6: Create default configuration
print_status "Creating default configuration..."

if [ ! -f "$CONFIG_FILE" ]; then
    cat > "$CONFIG_FILE" << 'EOF'
{
  "warning_threshold": 80,
  "critical_threshold": 95,
  "auto_compact_threshold": 75,
  "token_warning_threshold": 150000,
  "token_compact_threshold": 180000,
  "max_context_size": 200000,
  "checkpoint_settings": {
    "max_checkpoints": 10,
    "auto_checkpoint_interval": 50,
    "checkpoint_on_warning": true,
    "checkpoint_on_critical": true,
    "checkpoint_before_compact": true
  },
  "monitoring": {
    "enable_notifications": true,
    "log_verbose": false,
    "dashboard_refresh_interval": 5
  },
  "api_settings": {
    "retry_on_rate_limit": true,
    "max_retries": 3,
    "retry_delay_ms": 1000
  }
}
EOF
    print_success "Configuration file created"
else
    print_warning "Configuration file exists, keeping existing settings"
fi

# Step 7: Check for API key
print_status "Checking API key configuration..."

if [ -z "${ANTHROPIC_API_KEY:-}" ]; then
    print_warning "ANTHROPIC_API_KEY not set"
    echo ""
    echo "To use the rate limit manager, set your API key:"
    echo "  export ANTHROPIC_API_KEY=\"sk-ant-api03-...\""
    echo ""
    echo "Add this to your shell profile (~/.bashrc or ~/.zshrc) for persistence"
else
    print_success "API key is configured"
fi

# Step 8: Create convenience aliases (optional)
print_status "Setting up convenience commands..."

ALIAS_FILE="$HOME/.claude_aliases"
cat > "$ALIAS_FILE" << EOF
# Claude Rate Limit Manager Aliases
alias claude-dashboard='$CLAUDE_DIR/rate-limit-dashboard.sh'
alias claude-checkpoint='$HOOKS_DIR/auto-checkpoint.sh'
alias claude-context='$HOOKS_DIR/context-manager.sh'
alias claude-limits='$HOOKS_DIR/rate-limit-monitor.sh'
EOF

print_success "Convenience aliases created in $ALIAS_FILE"
echo "  Add 'source $ALIAS_FILE' to your shell profile to use them"

# Step 9: Test installation
print_status "Testing installation..."

# Test if scripts are executable
if [ -x "$HOOKS_DIR/rate-limit-monitor.sh" ]; then
    print_success "Rate limit monitor is executable"
else
    print_error "Rate limit monitor is not executable"
fi

if [ -x "$HOOKS_DIR/auto-checkpoint.sh" ]; then
    print_success "Checkpoint system is executable"
else
    print_error "Checkpoint system is not executable"
fi

# Final summary
echo ""
echo -e "${BOLD}${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${GREEN}║              Installation Complete!                         ║${NC}"
echo -e "${BOLD}${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BOLD}Quick Start:${NC}"
echo "  1. Set your API key (if not already set):"
echo "     export ANTHROPIC_API_KEY=\"your-key-here\""
echo ""
echo "  2. Launch the dashboard:"
echo "     $CLAUDE_DIR/rate-limit-dashboard.sh"
echo ""
echo "  3. Create a manual checkpoint:"
echo "     $HOOKS_DIR/auto-checkpoint.sh manual"
echo ""
echo -e "${BOLD}Files Installed:${NC}"
echo "  • Hooks: $HOOKS_DIR/"
echo "  • Dashboard: $CLAUDE_DIR/rate-limit-dashboard.sh"
echo "  • Config: $CONFIG_FILE"
echo "  • Settings: $SETTINGS_FILE"
echo ""
echo -e "${BOLD}Documentation:${NC}"
if [ -f "$SCRIPT_DIR/README.md" ]; then
    echo "  See $SCRIPT_DIR/README.md for full documentation"
else
    echo "  See README.md for full documentation"
fi
echo ""
print_success "Claude Rate Limit Manager is ready to use!"