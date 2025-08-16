# Claude Assistant Suite

A comprehensive collection of tools and enhancements for Claude Code, designed to improve productivity, prevent errors, and add powerful features to your AI-assisted development workflow.

## 🚀 Features

### 📊 Rate Limit Manager
Prevents 500 errors and ensures smooth operation by:
- Real-time monitoring of API rate limits
- Automatic checkpointing when approaching limits
- Context management and optimization
- Interactive dashboard with live metrics
- Smart blocking to prevent limit exceeded errors

### 🔔 Notifications
Stay informed about Claude Code events:
- Pushover integration for mobile alerts
- Customizable notification triggers
- Event hooks for various Claude operations
- Support for multiple notification channels

### 🎤 Voice Assistant
Hands-free interaction with Claude:
- Voice input for commands and queries
- Text-to-speech responses
- Multiple voice engine support
- WSL and Windows integration

## 📦 Quick Installation

### Install Everything
```bash
./install.sh --all
```

### Interactive Installation
```bash
./install.sh
# Follow prompts to select modules
```

### Install Specific Module
```bash
./install.sh --module rate-limit-manager
./install.sh --module notifications
./install.sh --module voice-assistant
```

## 🎯 Quick Start

### Set Your API Key
```bash
export ANTHROPIC_API_KEY="sk-ant-api03-..."
```

### Launch Dashboard (Rate Limit Manager)
```bash
~/.claude/rate-limit-dashboard.sh
```

### Configure Notifications
```bash
# Create ~/.pushover_config
cat > ~/.pushover_config << EOF
PUSHOVER_USER_KEY=your_user_key
PUSHOVER_APP_TOKEN=your_app_token
EOF
```

### Start Voice Assistant
```bash
~/.claude/claude-voice
```

## 🛠️ Module Details

### Rate Limit Manager

Monitor and manage API usage to prevent interruptions:

```bash
# Check current limits
~/.claude/hooks/rate-limit-monitor.sh

# Create manual checkpoint
~/.claude/hooks/auto-checkpoint.sh manual

# List checkpoints
~/.claude/hooks/auto-checkpoint.sh list

# Check context status
~/.claude/hooks/context-manager.sh status
```

**Configuration:** `~/.claude/rate-limit-config.json`
```json
{
  "warning_threshold": 80,
  "critical_threshold": 95,
  "auto_compact_threshold": 75
}
```

### Notifications

Get alerts for Claude Code events:

**Supported Events:**
- Command completion
- Error occurrences
- Rate limit warnings
- Session end

**Configuration:** `~/.pushover_config`
```bash
PUSHOVER_USER_KEY=your_key
PUSHOVER_APP_TOKEN=your_token
```

### Voice Assistant

Interact with Claude using voice:

```bash
# Start voice assistant
~/.claude/claude-voice

# Interactive mode
~/.claude/claude-voice-interactive

# Direct voice input
~/.claude/voice_claude_direct.py
```

## 📁 Project Structure

```
claude-assistant/
├── modules/
│   ├── rate-limit-manager/    # Rate limiting and checkpoints
│   ├── notifications/          # Alert systems
│   └── voice-assistant/        # Voice interaction
├── config/                     # Shared configurations
├── docs/                       # Documentation
├── utils/                      # Shared utilities
├── install.sh                  # Master installer
└── README.md                   # This file
```

## ⚙️ Configuration

### Global Settings
Located in `~/.claude/settings.json`, automatically configured by installer.

### Module Configurations
- Rate Limits: `~/.claude/rate-limit-config.json`
- Notifications: `~/.pushover_config`
- Voice: Module-specific settings

## 🔄 Updating

Update all modules:
```bash
./install.sh --update --all
```

Update specific module:
```bash
./install.sh --update --module rate-limit-manager
```

## 🗑️ Uninstallation

Each module includes its own uninstaller:
```bash
# Uninstall rate limit manager
./modules/rate-limit-manager/uninstall.sh

# Or use module uninstallers
cd modules/[module-name]
./uninstall.sh
```

## 🤝 Contributing

Contributions are welcome! To add a new module:

1. Create a new directory in `modules/`
2. Include:
   - Module-specific scripts
   - `install.sh` for module installation
   - `uninstall.sh` for cleanup
   - `README.md` for documentation
3. Update the master installer to recognize the module
4. Submit a pull request

## 📊 System Requirements

- **OS:** Linux, macOS, WSL
- **Shell:** Bash 4.0+
- **Dependencies:**
  - `jq` for JSON processing
  - `curl` for API calls
  - Python 3.x (for voice assistant)
  - Node.js (optional, for some features)

## 🐛 Troubleshooting

### API Key Issues
```bash
# Check if key is set
echo $ANTHROPIC_API_KEY

# Set permanently in ~/.bashrc or ~/.zshrc
export ANTHROPIC_API_KEY="your-key"
```

### Permission Errors
```bash
# Fix script permissions
chmod +x ~/.claude/hooks/*.sh
chmod +x ~/.claude/*.sh
```

### Hook Not Triggering
```bash
# Verify hooks configuration
cat ~/.claude/settings.json | jq '.hooks'

# Check logs
tail -f /tmp/claude-*.log
```

### Dashboard Not Working
```bash
# Install jq if missing
sudo apt-get install jq  # Debian/Ubuntu
brew install jq          # macOS
```

## 📝 Logs and Metrics

- Rate limit cache: `/tmp/claude-rate-limits.json`
- Context metrics: `/tmp/claude-context-metrics.json`
- Monitor logs: `/tmp/claude-rate-monitor.log`
- Checkpoint logs: `/tmp/claude-checkpoint.log`

## 🔐 Security

- API keys are never logged or transmitted
- Local storage only for configurations
- Checkpoints stored in user home directory
- No telemetry or external data collection

## 📄 License

MIT License - See LICENSE file for details

## 🙏 Acknowledgments

Built by the community, for the community. Special thanks to all contributors and the Claude Code team at Anthropic.

## 📮 Support

- Report issues: [GitHub Issues](https://github.com/yourusername/claude-assistant/issues)
- Documentation: See module-specific README files
- Community: Join discussions in the repository

---

**Note:** Always keep your API key secure and never commit it to version control.