# Claude Voice Input System

Voice-to-text integration for Claude Code that allows you to speak commands instead of typing.

## ✅ Installation Complete

All necessary components have been installed:
- Python speech recognition libraries
- Google Speech Recognition (free, no API key needed)
- Custom voice input scripts
- Shell aliases for easy access

## 🎤 Quick Start

1. **Activate the commands:**
   ```bash
   source ~/.bashrc
   ```

2. **Test voice input:**
   ```bash
   voice
   ```
   This opens an interactive menu where you can:
   - Press `s` to speak a command
   - Press `h` to see history
   - Press `q` to quit

## 📝 Available Commands

### Interactive Mode (Recommended)
- `voice` or `cvi` - Interactive voice menu
  - Speak commands and review them before sending to Claude
  - Maintains command history
  - Works around Claude's terminal limitations

### Direct Commands
- `vcf` - Voice to file (saves to `/tmp/claude_voice_input.txt`)
  - Speak once, saves to file
  - Then run: `claude < /tmp/claude_voice_input.txt`

### Advanced Commands
- `cv` - Single voice input mode
- `cvc` - Continuous voice mode
- `vc` - Attempts direct pipe to Claude (may have issues)

## 🎯 How to Use

### Method 1: Interactive Mode (Best)
```bash
voice
# Press 's' to speak
# Speak your command
# It will transcribe and show options
```

### Method 2: Voice to File
```bash
vcf
# Speak your command
# Then run: claude < /tmp/claude_voice_input.txt
```

### Method 3: Manual Process
```bash
# Record your voice
python3 ~/saralegui-solutions-llc/claude-assistant/voice_to_file.py

# Send to Claude
claude < /tmp/claude_voice_input.txt
```

## 🔧 Troubleshooting

### Microphone Not Working
1. Check microphone is connected
2. Test microphone: `arecord -d 5 test.wav && aplay test.wav`
3. Check permissions: `ls -l /dev/snd/`

### Speech Not Recognized
- Speak clearly and at normal pace
- Reduce background noise
- The system auto-calibrates for ambient noise

### Claude Integration Issues
- Claude Code doesn't accept piped input well due to terminal requirements
- Use the interactive mode (`voice`) or file method (`vcf`) instead

## 🎙️ Voice Commands (Continuous Mode)

When using `cvc` (continuous mode):
- Say "stop recording" to send message
- Say "clear message" to start over
- Say "exit voice mode" to quit

## 📁 File Locations

- Scripts: `/home/ben/saralegui-solutions-llc/claude-assistant/`
- Voice input file: `/tmp/claude_voice_input.txt`
- Command history: `/tmp/claude_voice_history.txt`

## 🔄 Updating

To get the latest aliases:
```bash
source ~/.bashrc
```

## 📋 Examples

**Ask Claude to explain code:**
```bash
voice
# Press 's'
# Say: "Explain the main function in this Python file"
```

**Ask Claude to write code:**
```bash
vcf
# Say: "Write a Python function that calculates fibonacci numbers"
# Then: claude < /tmp/claude_voice_input.txt
```

**Quick debugging:**
```bash
voice
# Press 's'
# Say: "Debug this TypeError on line 42"
```

## ⚙️ Technical Details

- Uses Google Speech Recognition API (free tier)
- No API keys required
- Works offline after initial setup
- Automatic noise calibration
- 30-second maximum recording time per command
- Supports multiple languages (defaults to English)