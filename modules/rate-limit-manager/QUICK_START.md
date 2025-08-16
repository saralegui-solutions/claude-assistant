# Quick Start Guide - Claude Rate Limit Manager

## 🚀 30-Second Installation

### Option 1: From Package Archive
```bash
# Download and extract the package
tar xzf claude-rate-limit-manager-1.0.0.tar.gz
cd claude-rate-limit-manager-*

# Run the installer
./quick-install.sh
```

### Option 2: Direct Installation
```bash
# Clone from existing installation
cd ~/claude-rate-limit-manager
./install.sh
```

## ⚡ Immediate Usage

### 1. Set Your API Key
```bash
export ANTHROPIC_API_KEY="sk-ant-api03-..."
```

### 2. Launch Dashboard
```bash
~/.claude/rate-limit-dashboard.sh
```

### 3. Test the System
```bash
# Check current rate limits
~/.claude/hooks/rate-limit-monitor.sh

# Create a test checkpoint
~/.claude/hooks/auto-checkpoint.sh manual

# View context status
~/.claude/hooks/context-manager.sh status
```

## 🎯 Key Commands

| Command | Description |
|---------|-------------|
| `~/.claude/rate-limit-dashboard.sh` | Interactive dashboard |
| `~/.claude/hooks/auto-checkpoint.sh manual` | Create checkpoint |
| `~/.claude/hooks/auto-checkpoint.sh list` | List checkpoints |
| `~/.claude/hooks/context-manager.sh status` | Check context usage |

## 🔧 Quick Configuration

Edit `~/.claude/rate-limit-config.json`:
- `warning_threshold`: Alert at this % (default: 80)
- `critical_threshold`: Block at this % (default: 95)
- `auto_compact_threshold`: Suggest compact at this % (default: 75)

## ⚠️ Troubleshooting

### API Key Not Working
```bash
echo $ANTHROPIC_API_KEY  # Check if set
export ANTHROPIC_API_KEY="your-key"  # Set it
```

### Dashboard Not Opening
```bash
chmod +x ~/.claude/rate-limit-dashboard.sh
which jq  # Check if jq installed
```

### Hooks Not Triggering
```bash
cat ~/.claude/settings.json | jq '.hooks'  # Check configuration
```

## 📝 Files Installed

- `~/.claude/hooks/` - Monitoring scripts
- `~/.claude/rate-limit-dashboard.sh` - Dashboard
- `~/.claude/rate-limit-config.json` - Configuration
- `~/.claude/settings.json` - Hook settings
- `~/.claude/checkpoints/` - Saved checkpoints

## 🗑️ Uninstall

```bash
cd ~/claude-rate-limit-manager
./uninstall.sh
```

---
For full documentation, see README.md