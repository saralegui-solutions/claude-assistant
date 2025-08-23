# Claude Assistant - Quick Start Guide

## 🚀 One-Command Installation

### From anywhere on your system:
```bash
curl -sSL https://raw.githubusercontent.com/saralegui-solutions/claude-assistant/main/install-claude.sh | bash
```

### Or clone and run locally:
```bash
git clone https://github.com/saralegui-solutions/claude-assistant.git
cd claude-assistant
./quick-setup.sh
```

## ⚡ Quick Access Commands (After Installation)

### The Easiest Way - Quick Menu
```bash
cl              # Opens interactive menu (recommended!)
```

### Direct Commands
```bash
dash            # Rate limit dashboard
ca              # Main Claude assistant
ca-pdf          # PDF generator
ca-voice        # Voice input
ca-status       # System status check
ca-help         # Show all commands
```

## 📝 Essential Aliases Added to Your Shell

| Alias | Description | Example |
|-------|-------------|---------|
| `cl` | **Quick launcher menu** (easiest!) | `cl` |
| `dash` | Rate limit dashboard | `dash` |
| `ca` | Main command | `ca help` |
| `ca-dash` | Dashboard shortcut | `ca-dash` |
| `ca-pdf` | PDF generator | `ca-pdf input.md output.pdf` |
| `ca-voice` | Voice assistant | `ca-voice` |
| `ca-check` | Create checkpoint | `ca-check` |
| `ca-ctx` | Context check | `ca-ctx` |
| `ca-limits` | Quick limits | `ca-limits` |
| `ca-docs` | Convert all .md to PDF | `ca-docs` |
| `ca-export` | Export conversation | `ca-export` |
| `ca-status` | System check | `ca-status` |

## 🎯 Common Tasks

### Monitor API Usage
```bash
dash            # or
ca-dash         # or
cl → 1          # from menu
```

### Convert Markdown to PDF
```bash
ca-pdf README.md readme.pdf        # Single file
ca-docs                            # All .md files in directory
```

### Voice Input
```bash
ca-voice        # or
cl → 2          # from menu
```

### Save Conversation
```bash
ca-check        # or
cl → 4          # from menu
```

### Check System Status
```bash
ca-status       # or
cl → 6          # from menu
```

## 🔧 Configuration

### Set API Key (if not already set)
```bash
export ANTHROPIC_API_KEY="sk-ant-api03-..."
echo 'export ANTHROPIC_API_KEY="sk-ant-api03-..."' >> ~/.bashrc
```

### Edit Settings
```bash
ca config       # Edit rate limit config
nano ~/.claude/settings.json       # Edit Claude hooks
```

### Update Installation
```bash
claude-update   # Pull latest and reinstall
```

## 📁 Important Locations

- **Installation**: `~/claude-assistant/`
- **Claude Home**: `~/.claude/`
- **Settings**: `~/.claude/settings.json`
- **Rate Config**: `~/.claude/rate-limit-config.json`
- **Checkpoints**: `~/.claude/checkpoints/`
- **Conversations**: `~/.claude/conversations/`

## 🆘 Troubleshooting

### Commands Not Found
```bash
# Reload shell configuration
source ~/.bashrc        # or
source ~/.zshrc         # for zsh users

# Or restart terminal
```

### Check Installation
```bash
ca-status               # System check
ca-help                 # Show available commands
ls -la ~/.claude/       # Check files
```

### PDF Generator Issues
```bash
ca-pdf --check          # Check PDF dependencies
pip install markdown2 pdfkit md2pdf    # Install Python deps
```

### Voice Not Working
```bash
pip install SpeechRecognition pyttsx3 pyaudio
```

## 💡 Pro Tips

1. **Use `cl` for everything** - It's the quickest way to access all features
2. **Keep dashboard open** - Run `dash` in a separate terminal during long sessions
3. **Regular checkpoints** - Use `ca-check` before major changes
4. **Batch PDF conversion** - Use `ca-docs` to convert entire documentation
5. **Voice for quick queries** - Use `ca-voice` for hands-free operation

## 📖 Full Documentation

- [User Guide](USER_GUIDE.md)
- [Complete Setup Guide](COMPLETE_SETUP_GUIDE.md)
- [Module Documentation](modules/*/README.md)

---

**Quick Start:** After installation, just type `cl` and press Enter!