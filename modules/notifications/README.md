# Claude Notifications 🔔

Get notified when Claude Code needs your attention or completes tasks! Choose between Zelda-themed sound effects or Pushover mobile notifications.

## 🚀 Quick Setup (2 minutes)

### Option 1: With Pushover Credentials Ready
```bash
# Clone and setup
git clone https://github.com/saralegui-solutions/claude-notifications.git
cd claude-notifications

# Add your Pushover credentials to .env
cp .env.example .env
nano .env  # Add your PUSHOVER_USER_KEY and PUSHOVER_APP_TOKEN

# Run setup
./setup.sh
```

### Option 2: Interactive Setup
```bash
# Clone and setup
git clone https://github.com/saralegui-solutions/claude-notifications.git
cd claude-notifications
./setup.sh  # Will prompt for everything
```

That's it! You're done. 🎉

## Features

### Two Notification Methods:

**Option 1: Sound Notifications** 🎮
- Zelda OOT sound effects
- Item pickup sound when Claude needs input
- Heart sound when Claude completes tasks
- Works on WSL, macOS, and Linux

**Option 2: Pushover Mobile Notifications** 📱
- Get notifications on your phone/tablet/desktop
- High priority alerts when Claude needs input
- Normal priority when tasks complete
- Works anywhere with internet connection
- Perfect for remote work or multiple machines

## Quick Start

### For Sound Notifications:
```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/claude-notifications.git
cd claude-notifications

# Run the sound installer
./install.sh
```

### For Pushover Mobile Notifications:
```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/claude-notifications.git
cd claude-notifications

# Run the Pushover installer
./install-pushover.sh
# You'll be prompted for your Pushover credentials
```

## What Gets Installed

### Sound Notifications:
- **Hook Script**: `~/.claude/hooks/notify.sh`
- **Settings**: Updates `~/.claude/settings.json` with hook configuration
- **Sounds**: 
  - WSL: Copies to `C:\temp\claude-notifications\`
  - macOS/Linux: Copies to `~/.claude/sounds/`

### Pushover Notifications:
- **Hook Script**: `~/.claude/hooks/pushover-notify.sh`
- **Settings**: Updates `~/.claude/settings.json` with hook configuration
- **Config**: Creates `~/.claude/pushover.env` with your API credentials

## Requirements

### For Sound Notifications:

**WSL (Windows Subsystem for Linux)**
- PowerShell (included with Windows)
- No additional requirements

**macOS**
- `afplay` command (included with macOS)

**Linux**
- One of the following audio players:
  - `paplay` (PulseAudio) - Recommended
  - `aplay` (ALSA)
  - `play` (SoX)

### For Pushover Notifications:

**All Platforms**
- Pushover account (https://pushover.net/)
- Pushover mobile app ($4.99 one-time purchase)
- Internet connection
- `curl` (usually pre-installed)

Install on Ubuntu/Debian:
```bash
# For PulseAudio (recommended)
sudo apt-get install pulseaudio-utils

# For ALSA
sudo apt-get install alsa-utils

# For SoX
sudo apt-get install sox
```

## Testing

After installation, the installer automatically tests both sounds. You can manually test them:

```bash
# Test notification sound
echo '{"event":"Notification","message":"Test"}' | ~/.claude/hooks/notify.sh

# Test completion sound
echo '{"event":"Stop","message":"Test"}' | ~/.claude/hooks/notify.sh
```

## Customizing Sounds

To use your own sounds:

1. Replace the `.wav` files in the `sounds/` directory
2. Keep the same filenames or update `hooks/notify.sh`
3. Re-run `./install.sh`

## Uninstalling

```bash
./uninstall.sh
```

This will:
- Remove the hook script
- Clean up sound files
- Remove hook entries from settings.json
- Keep backup files for safety

## Troubleshooting

### No sound on WSL
- Check Windows volume settings
- Verify files exist: `ls /mnt/c/temp/claude-notifications/`
- Test PowerShell audio: `powershell.exe -Command "[System.Media.SystemSounds]::Beep.Play()"`

### No sound on Linux
- Install an audio player: `sudo apt-get install pulseaudio-utils`
- Check audio permissions: `groups | grep audio`
- Test audio: `speaker-test -t sine -f 1000 -l 1`

### No sound on macOS
- Check system volume
- Verify afplay works: `afplay /System/Library/Sounds/Ping.aiff`

## File Structure

```
claude-notifications/
├── README.md           # This file
├── install.sh          # Installation script
├── uninstall.sh        # Uninstallation script
├── hooks/
│   └── notify.sh       # Main notification hook script
└── sounds/
    ├── OOT_Get_Heart.wav      # Heart pickup sound
    └── OOT_Get_SmallItem1.wav # Item pickup sound
```

## How It Works

Claude Code supports hooks that trigger on specific events. This package:

1. Installs a hook script that listens for Claude events
2. Parses the event type from JSON input
3. Plays the appropriate sound based on the event
4. Passes through the input unchanged (required for hooks)

## License

The Zelda sound effects are property of Nintendo. This project is for personal use only.

## Contributing

Feel free to submit issues or pull requests if you have improvements or bug fixes!