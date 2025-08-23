# OpenAI Whisper Transcription Module

## Overview
High-quality speech-to-text transcription using OpenAI's Whisper model with multiple backend support and automatic fallback.

## Features
- 🎯 Multiple backend support (5 implementations)
- 🔄 Automatic fallback between methods
- 🎤 Microphone recording and transcription
- 📁 Batch processing for multiple files
- 🌍 Multi-language support (99+ languages)
- 💾 Offline operation after model download
- ⚡ GPU acceleration support

## Installation

### Via Interactive Installer
```bash
./install-interactive.sh
# Select: [5] Whisper Transcription
```

### Manual Installation
```bash
./modules/whisper-transcription/install.sh
```

### Quick Install (One Backend)
```bash
# Official Whisper
pip install openai-whisper

# OR Faster implementation  
pip install faster-whisper

# OR with API support
export OPENAI_API_KEY="sk-..."
pip install openai
```

## Usage

### Basic Commands
```bash
# Transcribe audio file
claude-whisper audio.mp3
whisper-transcribe recording.wav

# From microphone (10 seconds)
claude-whisper --mic --duration 10

# Batch transcribe directory
claude-whisper ./audio/ --batch --output ./transcripts/

# Check system capabilities
claude-whisper --check
```

### Advanced Options
```bash
# Use specific model
claude-whisper audio.mp3 --model large

# Specify language
claude-whisper audio.mp3 --language en

# Force specific backend
claude-whisper audio.mp3 --backend faster-whisper

# Output formats
claude-whisper audio.mp3 --format json
claude-whisper audio.mp3 --format srt
```

## Available Backends

### 1. OpenAI Whisper (Python)
**Official implementation**
```bash
pip install openai-whisper
```
- Best compatibility
- All model sizes
- Good accuracy

### 2. Faster-whisper
**Optimized C++ implementation**
```bash
pip install faster-whisper
```
- 4x faster than official
- Lower memory usage
- GPU optimized

### 3. Whisper.cpp
**Pure C++ implementation**
```bash
# Install from source
git clone https://github.com/ggerganov/whisper.cpp
cd whisper.cpp && make
```
- No Python required
- CPU optimized
- Minimal dependencies

### 4. OpenAI API
**Cloud-based transcription**
```bash
export OPENAI_API_KEY="sk-..."
pip install openai
```
- No local processing
- Always latest model
- Requires internet

### 5. WhisperX
**Enhanced with alignment**
```bash
pip install whisperx
```
- Word-level timestamps
- Speaker diarization
- Phoneme alignment

## Model Selection

| Model | Size | Speed | Accuracy | Use Case |
|-------|------|-------|----------|----------|
| tiny | 39M | ⚡⚡⚡⚡⚡ | ⭐⭐ | Real-time, draft |
| base | 74M | ⚡⚡⚡⚡ | ⭐⭐⭐ | **Balanced (default)** |
| small | 244M | ⚡⚡⚡ | ⭐⭐⭐⭐ | Good accuracy |
| medium | 769M | ⚡⚡ | ⭐⭐⭐⭐ | High accuracy |
| large | 1.5G | ⚡ | ⭐⭐⭐⭐⭐ | Best quality |

## Configuration

### File Location
`~/.claude/whisper/config.json`

### Configuration Options
```json
{
  "model": "base",              // Model size
  "language": "auto",          // or "en", "es", "fr", etc.
  "device": "auto",            // auto, cpu, cuda
  "output_format": "text",     // text, json, srt, vtt
  "temperature": 0,            // 0-1, higher = more variation
  "options": {
    "fp16": true,              // Use FP16 (faster on GPU)
    "threads": 4,              // CPU threads
    "verbose": false,
    "condition_on_previous_text": true,
    "compression_ratio_threshold": 2.4,
    "logprob_threshold": -1.0,
    "no_speech_threshold": 0.6
  },
  "backends": {
    "prefer_local": true,      // Use local model first
    "allow_api": true,         // Allow API fallback
    "cache_models": true       // Cache downloaded models
  }
}
```

## Language Support

Whisper supports 99 languages. Most common:
- English (en)
- Spanish (es) 
- French (fr)
- German (de)
- Italian (it)
- Portuguese (pt)
- Russian (ru)
- Chinese (zh)
- Japanese (ja)
- Korean (ko)

Auto-detection works well for clear audio.

## Microphone Recording

### Setup
```bash
# Install audio dependencies
pip install sounddevice soundfile

# Test microphone
claude-whisper --mic --duration 3
```

### Usage
```bash
# Record and transcribe (5 seconds default)
claude-whisper --mic

# Custom duration
claude-whisper --mic --duration 10

# Save to file
claude-whisper --mic --output transcript.txt
```

## Batch Processing

### Directory Structure
```
audio/
├── interview1.mp3
├── interview2.mp3
└── meeting.wav

# Run batch
claude-whisper ./audio/ --batch --output ./transcripts/

# Results
transcripts/
├── interview1.txt
├── interview1_meta.json
├── interview2.txt
├── interview2_meta.json
├── meeting.txt
└── meeting_meta.json
```

### Batch Options
```bash
# Specific file pattern
claude-whisper ./audio/ --batch --pattern "*.mp3"

# With specific model
claude-whisper ./audio/ --batch --model large

# Force language
claude-whisper ./audio/ --batch --language en
```

## GPU Acceleration

### CUDA Setup
```bash
# Check CUDA availability
claude-whisper --check

# Install CUDA-enabled PyTorch
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118

# Force GPU usage
claude-whisper audio.mp3 --device cuda
```

### Performance Tips
1. Use `faster-whisper` for best GPU performance
2. Enable FP16 for faster processing
3. Batch process during off-hours
4. Use smaller models for drafts

## Integration with Claude

### Transcribe Conversations
```bash
# Record conversation
claude-whisper --mic --duration 60 --output conversation.txt

# Send to Claude
cat conversation.txt | claude-assistant
```

### Voice Notes Workflow
```bash
#!/bin/bash
# voice-note.sh

# Record
claude-whisper --mic --duration 30 --output note.txt

# Add to Claude context
echo "Voice note transcription:" > context.txt
cat note.txt >> context.txt

# Process with Claude
claude-assistant < context.txt
```

## Troubleshooting

### No Backends Available
```bash
# Install at least one
pip install openai-whisper
# or
pip install faster-whisper
```

### Model Not Downloaded
```bash
# Download specific model
python3 -c "import whisper; whisper.load_model('base')"

# Check cache
ls ~/.cache/whisper/
```

### Audio Format Issues
```bash
# Install ffmpeg
sudo apt install ffmpeg  # Linux
brew install ffmpeg      # macOS

# Convert to WAV
ffmpeg -i input.mp4 -ar 16000 -ac 1 output.wav
```

### Microphone Not Working
```bash
# Check audio devices
python3 -c "import sounddevice; print(sounddevice.query_devices())"

# Test recording
python3 -c "import sounddevice; sounddevice.rec(16000, samplerate=16000)"
```

### GPU Not Detected
```bash
# Check CUDA
python3 -c "import torch; print(torch.cuda.is_available())"

# Force CPU
claude-whisper audio.mp3 --device cpu
```

## Performance Benchmarks

| Model | CPU Time | GPU Time | RAM Usage |
|-------|----------|----------|-----------|
| tiny | 1x | 0.2x | 1GB |
| base | 2x | 0.3x | 1GB |
| small | 5x | 0.5x | 2GB |
| medium | 10x | 1x | 5GB |
| large | 20x | 2x | 10GB |

*Times relative to audio duration

## API Usage (Python)

```python
from whisper_transcribe import WhisperTranscriber

# Initialize
transcriber = WhisperTranscriber()

# Transcribe file
result = transcriber.transcribe("audio.mp3")
print(result["text"])

# From microphone
result = transcriber.transcribe_microphone(duration=10)
print(result["text"])

# Batch process
success, total = transcriber.batch_transcribe(
    "./audio/",
    "./transcripts/"
)
```

## Files Installed
- `~/.claude/bin/claude-whisper` - Main command
- `~/.claude/whisper/whisper_transcribe.py` - Core module
- `~/.claude/whisper/config.json` - Configuration
- `~/.cache/whisper/*.pt` - Model files (after download)

## Version
Current: 1.0
Compatible with: Whisper v20230314+
Python: 3.8+