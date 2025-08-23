# Claude Assistant Suite

> Modular enhancement toolkit for Claude Code with smart monitoring, PDF generation, voice control, and notifications.

## ⚡ Quick Install

```bash
# Interactive installation (recommended)
curl -sSL https://raw.githubusercontent.com/saralegui-solutions/claude-assistant/main/install-interactive.sh | bash

# Or clone and install
git clone https://github.com/saralegui-solutions/claude-assistant.git
cd claude-assistant
./install-interactive.sh
```

After installation, type `cl` to start!

## 🎯 What It Does

Claude Assistant enhances Claude Code with:
- **Prevents API errors** with smart rate limiting
- **Converts documents to PDF** with multiple backends
- **Enables voice control** for hands-free coding
- **Sends notifications** for important events
- **Auto-saves progress** with smart checkpointing

## 📦 Modular Architecture

Choose only what you need:

| Module | Description | Size | Dependencies |
|--------|-------------|------|--------------|
| **Core** | Base framework & launcher | ~500KB | jq, curl |
| **Rate Limit Manager** | API monitoring & protection | ~1MB | jq |
| **PDF Generator** | Document conversion | ~1MB | python3 |
| **Voice Assistant** | Voice input/output | ~2MB | python3, pyaudio |
| **Whisper Transcription** | Speech-to-text with OpenAI Whisper | ~2MB | python3, ffmpeg |
| **Notifications** | Alerts & notifications | ~500KB | curl |

## 🚀 Quick Start

### Essential Commands
```bash
cl              # Interactive launcher (easiest!)
dash            # Rate limit dashboard
pdf             # PDF converter
ca help         # Show all commands
```

### Common Tasks
```bash
# Monitor API usage
dash

# Convert markdown to PDF
pdf README.md readme.pdf

# Batch convert directory
pdf ./docs/ ./pdfs/ --batch

# Voice input
ca voice

# Create checkpoint
ca checkpoint
```

## 📁 Project Structure

```
claude-assistant/
├── install-interactive.sh      # Main installer
├── docs/
│   ├── guides/                # User guides
│   │   ├── QUICK_START.md
│   │   ├── USER_GUIDE.md
│   │   └── SETUP_GUIDE.md
│   └── modules/               # Module docs
│       ├── rate-limit-manager.md
│       ├── pdf-generator.md
│       ├── voice-assistant.md
│       └── notifications.md
├── modules/                   # Modular components
│   ├── rate-limit-manager/
│   ├── pdf-generator/
│   ├── voice-assistant/
│   └── notifications/
└── core/                      # Core system files
```

## 🔧 Installation Options

### Interactive Mode
The installer will ask you:
1. **Which modules to install** - Choose à la carte or all
2. **System dependencies** - Auto-install required packages
3. **Shell configuration** - Add convenient aliases
4. **Optional features** - Desktop shortcuts, enhanced PDF tools

### Quick Mode
```bash
# Install recommended modules without prompts
./install-interactive.sh --quick
```

### Manual Module Installation
```bash
# Install individual modules
./modules/rate-limit-manager/install.sh
./modules/pdf-generator/install.sh
./modules/voice-assistant/install.sh
./modules/notifications/install.sh
```

## 🎨 Configuration

### Main Config
`~/.claude/config/settings.json`

### Module Configs
- Rate Limits: `~/.claude/config/rate-limit-config.json`
- PDF Settings: `~/.claude/pdf-generator/config.json`
- Notifications: `~/.pushover_config`

## 📊 Module Details

### Rate Limit Manager
- Real-time dashboard with visual indicators
- Automatic checkpointing at thresholds
- Context size tracking
- Smart blocking to prevent errors

### PDF Generator
- 6 conversion methods with auto-fallback
- Batch processing capabilities
- Custom CSS styling
- Supports MD, HTML, TXT, RST

### Voice Assistant
- Speech-to-text input
- Text-to-speech responses
- Multiple language support
- WSL/Windows compatible

### Whisper Transcription
- High-quality speech-to-text
- Multiple backend support
- 99+ language support
- Microphone recording
- Batch processing

### Notifications
- Pushover mobile alerts
- Desktop notifications
- Sound alerts
- Custom triggers

## 🛠️ Requirements

### Minimum
- Bash 4.0+
- curl or wget
- Claude Code installed

### Recommended
- jq (JSON processing)
- Python 3.6+
- pandoc or wkhtmltopdf (for PDF)

## 📚 Documentation

### Getting Started
- [Quick Start Guide](docs/guides/QUICK_START.md)
- [User Guide](docs/guides/USER_GUIDE.md)
- [Setup Instructions](docs/guides/SETUP_INSTRUCTIONS.md)

### Module Documentation
- [Rate Limit Manager](docs/modules/rate-limit-manager.md)
- [PDF Generator](docs/modules/pdf-generator.md)
- [Voice Assistant](docs/modules/voice-assistant.md)
- [Whisper Transcription](docs/modules/whisper-transcription.md)
- [Notifications](docs/modules/notifications.md)

## 🆘 Troubleshooting

### Commands Not Found
```bash
source ~/.bashrc   # Reload shell config
# or restart terminal
```

### Check Installation
```bash
ca help            # Show available commands
pdf --check        # Check PDF dependencies
ls -la ~/.claude/  # Verify installation
```

### Update Installation
```bash
ca update          # Update Claude Assistant
# or
cd ~/claude-assistant && git pull && ./install-interactive.sh
```

## 🤝 Contributing

Contributions welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Submit a pull request

## 📄 License

MIT License - See [LICENSE](LICENSE) file

## 🙏 Acknowledgments

Built for the Claude Code community to enhance the AI-assisted development experience.

---

**Quick Start:** After installation, just type `cl` and press Enter!