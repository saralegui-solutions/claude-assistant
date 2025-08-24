#!/bin/bash

# Claude API Orchestrator Module - Installation Script
# Installs the orchestrator that coordinates Claude API and Claude Code

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Installation paths
CLAUDE_DIR="$HOME/.claude"
MODULES_DIR="$CLAUDE_DIR/modules"
ORCHESTRATOR_DIR="$MODULES_DIR/api-orchestrator"
SESSIONS_DIR="$CLAUDE_DIR/orchestrated-sessions"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}Installing Claude API Orchestrator Module...${NC}"

# Create necessary directories
echo "Creating directories..."
mkdir -p "$ORCHESTRATOR_DIR"
mkdir -p "$SESSIONS_DIR"
mkdir -p "$CLAUDE_DIR/config"

# Copy orchestrator script
echo "Installing orchestrator script..."
cp "$SCRIPT_DIR/orchestrator.py" "$ORCHESTRATOR_DIR/"
chmod +x "$ORCHESTRATOR_DIR/orchestrator.py"

# Check Python installation
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}Python 3 is required but not installed!${NC}"
    echo "Please install Python 3 and try again."
    exit 1
fi

# Install Python dependencies
echo "Installing Python dependencies..."
if command -v pip3 &> /dev/null; then
    # Install anthropic
    pip3 install --quiet anthropic --user --break-system-packages 2>/dev/null || {
        echo -e "${YELLOW}Warning: Could not install anthropic package automatically${NC}"
        echo "Please run: pip3 install anthropic --user --break-system-packages"
    }
    
    # Install SpeechRecognition for voice input
    pip3 install --quiet SpeechRecognition --user --break-system-packages 2>/dev/null || {
        echo -e "${YELLOW}Note: SpeechRecognition not installed (needed for voice)${NC}"
    }
else
    echo -e "${YELLOW}pip3 not found. Please install the packages manually:${NC}"
    echo "  pip3 install anthropic SpeechRecognition --user --break-system-packages"
fi

# Check for voice dependencies
echo "Checking voice input dependencies..."
if ! python3 -c "import pyaudio" 2>/dev/null; then
    echo -e "${YELLOW}Note: PyAudio not installed - voice input will not work${NC}"
    echo "To enable voice input, run:"
    echo "  $SCRIPT_DIR/install-voice-deps.sh"
    echo "Or install manually:"
    echo "  sudo apt-get install python3-pyaudio portaudio19-dev"
else
    echo -e "${GREEN}✓ Voice dependencies found${NC}"
fi

# Create convenience wrapper script
echo "Creating wrapper script..."
cat > "$CLAUDE_DIR/claude-orchestrate" << 'EOF'
#!/bin/bash
# Claude Orchestrator wrapper

ORCHESTRATOR="$HOME/.claude/modules/api-orchestrator/orchestrator.py"

if [ ! -f "$ORCHESTRATOR" ]; then
    echo "Orchestrator not installed. Run: claude-assistant install api-orchestrator"
    exit 1
fi

# Check for Python
if ! command -v python3 &> /dev/null; then
    echo "Python 3 is required but not installed!"
    exit 1
fi

# Run orchestrator with all arguments
python3 "$ORCHESTRATOR" "$@"
EOF

chmod +x "$CLAUDE_DIR/claude-orchestrate"

# Create quick-access aliases script
cat > "$ORCHESTRATOR_DIR/aliases.sh" << 'EOF'
# Claude Orchestrator Aliases

# Main orchestrator command
alias orch='claude-orchestrate'

# Start with voice input
alias orch-voice='claude-orchestrate'

# Start with text input
orch-text() {
    claude-orchestrate "$*"
}

# Review last session
orch-review() {
    local sessions_dir="$HOME/.claude/orchestrated-sessions"
    if [ -d "$sessions_dir" ]; then
        echo "Recent orchestrated sessions:"
        ls -lat "$sessions_dir" | head -10
        echo ""
        echo "To view a session: cat $sessions_dir/session_YYYYMMDD_HHMMSS_summary.json"
    else
        echo "No sessions found"
    fi
}

# View session log
orch-log() {
    local sessions_dir="$HOME/.claude/orchestrated-sessions"
    local latest=$(ls -t "$sessions_dir"/*.log 2>/dev/null | head -1)
    if [ -f "$latest" ]; then
        less "$latest"
    else
        echo "No session logs found"
    fi
}

# Clean old sessions (keep last 10)
orch-clean() {
    local sessions_dir="$HOME/.claude/orchestrated-sessions"
    local count=$(ls -1 "$sessions_dir" 2>/dev/null | wc -l)
    if [ "$count" -gt 20 ]; then
        echo "Cleaning old sessions (keeping last 20 files)..."
        ls -t "$sessions_dir"/* | tail -n +21 | xargs rm -f
        echo "Cleaned!"
    else
        echo "No cleanup needed"
    fi
}
EOF

# Check for API key
if [ -z "${ANTHROPIC_API_KEY:-}" ]; then
    if [ ! -f "$CLAUDE_DIR/config/api_key.json" ]; then
        echo -e "${YELLOW}⚠️  No API key configured${NC}"
        echo ""
        echo "The orchestrator requires an Anthropic API key to function."
        echo "You can set it up in one of these ways:"
        echo ""
        echo "  1. Set environment variable (add to ~/.bashrc):"
        echo "     export ANTHROPIC_API_KEY='sk-ant-api03-...'"
        echo ""
        echo "  2. The orchestrator will prompt you on first run"
        echo ""
        echo "To get an API key:"
        echo "  1. Go to https://console.anthropic.com/"
        echo "  2. Sign up or log in"
        echo "  3. Navigate to API keys section"
        echo "  4. Create a new key"
    else
        echo -e "${GREEN}✓ API key configuration found${NC}"
    fi
else
    echo -e "${GREEN}✓ API key found in environment${NC}"
fi

# Success message
echo -e "${GREEN}✅ Claude API Orchestrator installed successfully!${NC}"
echo ""
echo "Usage:"
echo "  claude-orchestrate              - Start with voice input"
echo "  claude-orchestrate 'request'    - Start with text input"
echo "  claude-orchestrate --help       - Show help"
echo ""
echo "Quick commands (add aliases to your shell):"
echo "  source $ORCHESTRATOR_DIR/aliases.sh"
echo ""
echo "Examples:"
echo "  claude-orchestrate 'Create a web scraper for product prices'"
echo "  claude-orchestrate 'Debug my Python test suite'"
echo ""
echo "Session files are saved in: $SESSIONS_DIR"