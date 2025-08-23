# Whisper Transcription Module

## Overview
High-quality speech-to-text transcription using OpenAI's Whisper model with multiple backend support and automatic fallback.

## Quick Start
```bash
# Install module
./install-interactive.sh
# Select: [5] Whisper Transcription

# Basic usage
claude-whisper audio.mp3
claude-whisper --mic --duration 10
```

## Key Features
- 🎯 **5 Backend Options** - OpenAI Whisper, Faster-whisper, Whisper.cpp, OpenAI API, WhisperX
- 🌍 **99+ Languages** - Automatic language detection
- 🎤 **Microphone Support** - Direct recording and transcription
- 📁 **Batch Processing** - Convert multiple files
- 💾 **Offline Operation** - Works without internet (after model download)
- ⚡ **GPU Acceleration** - CUDA support for faster processing

## Installation Methods

### Interactive Installer
```bash
./install-interactive.sh
# Choose [5] or [A] for all modules
```

### Direct Module Install
```bash
./modules/whisper-transcription/install.sh
```

### Manual Python Install
```bash
# Official Whisper
pip install openai-whisper

# Faster alternative
pip install faster-whisper
```

## Usage Examples

### File Transcription
```bash
# Basic transcription
claude-whisper audio.mp3

# With specific model
claude-whisper audio.mp3 --model large

# Force language
claude-whisper audio.mp3 --language en

# Output formats
claude-whisper audio.mp3 --format json
claude-whisper audio.mp3 --format srt
```

### Microphone Recording
```bash
# Default 5 seconds
claude-whisper --mic

# Custom duration
claude-whisper --mic --duration 30

# Save to file
claude-whisper --mic --output transcript.txt
```

### Batch Processing
```bash
# Process directory
claude-whisper ./audio/ --batch

# With pattern
claude-whisper ./audio/ --batch --pattern "*.mp3"

# Specify output
claude-whisper ./audio/ --batch --output ./transcripts/
```

## Available Models

| Model | Size | Speed | Quality | Best For |
|-------|------|-------|---------|----------|
| tiny | 39M | Fastest | Basic | Quick drafts, real-time |
| base | 74M | Fast | Good | **Default - balanced** |
| small | 244M | Medium | Better | General use |
| medium | 769M | Slow | High | Professional |
| large | 1.5G | Slowest | Best | Maximum accuracy |

## Configuration

### Settings Location
`~/.claude/whisper/config.json`

### Key Options
```json
{
  "model": "base",           // Model size
  "language": "auto",        // Language detection
  "device": "auto",          // CPU/GPU selection
  "output_format": "text",   // Output format
  "backends": {
    "prefer_local": true,    // Use local model first
    "allow_api": true        // Allow cloud fallback
  }
}
```

## Integration with Claude

### Workflow Example
```bash
# Record voice note
claude-whisper --mic --duration 60 --output note.txt

# Send to Claude
cat note.txt | claude-assistant

# Or combine with voice assistant
claude-voice --input note.txt
```

### Conversation Transcription
```bash
# Record meeting
claude-whisper meeting.mp3 --output meeting.txt

# Create summary with Claude
echo "Summarize this meeting:" > prompt.txt
cat meeting.txt >> prompt.txt
claude-assistant < prompt.txt
```

## Troubleshooting

### No Backends Available
```bash
# Install at least one backend
pip install openai-whisper

# Check installation
claude-whisper --check
```

### Audio Format Issues
```bash
# Install ffmpeg
sudo apt install ffmpeg  # Linux
brew install ffmpeg      # macOS
```

### Model Download
```bash
# Download specific model
python3 -c "import whisper; whisper.load_model('base')"
```

### Performance Issues
- Use smaller models for faster processing
- Enable GPU acceleration if available
- Try faster-whisper backend
- Process during off-hours for batch jobs

## Dependencies
- Python 3.8+
- ffmpeg (audio processing)
- One of: openai-whisper, faster-whisper, whisper.cpp
- Optional: CUDA for GPU acceleration

## Files Installed
- `~/.claude/bin/claude-whisper` - Main command
- `~/.claude/whisper/whisper_transcribe.py` - Core module
- `~/.claude/whisper/config.json` - Configuration
- `~/.cache/whisper/` - Model storage

## See Also
- [Full Module Documentation](../../modules/whisper-transcription/README.md)
- [Voice Assistant Integration](voice-assistant.md)
- [Project Structure](../../PROJECT_STRUCTURE.md)