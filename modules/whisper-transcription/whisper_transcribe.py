#!/usr/bin/env python3
"""
OpenAI Whisper Transcription Module for Claude Assistant
High-quality speech-to-text using OpenAI's Whisper model
"""

import os
import sys
import json
import argparse
import logging
import tempfile
import subprocess
from pathlib import Path
from typing import Optional, Dict, List, Tuple
import warnings

# Suppress warnings
warnings.filterwarnings("ignore")

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class WhisperTranscriber:
    """OpenAI Whisper transcription with multiple backend support"""
    
    def __init__(self, config_file: Optional[str] = None):
        self.config = self.load_config(config_file)
        self.available_backends = self.detect_backends()
        self.model_name = self.config.get('model', 'base')
        
    def load_config(self, config_file: Optional[str]) -> Dict:
        """Load configuration from JSON file or use defaults"""
        default_config = {
            "model": "base",  # tiny, base, small, medium, large
            "language": "auto",  # auto-detect or specify (en, es, fr, etc.)
            "device": "auto",  # auto, cpu, cuda
            "output_format": "text",  # text, json, srt, vtt
            "temperature": 0,  # 0 for deterministic, higher for variation
            "options": {
                "fp16": True,  # Use FP16 (faster on GPU)
                "threads": 4,  # CPU threads
                "verbose": False,
                "condition_on_previous_text": True,
                "compression_ratio_threshold": 2.4,
                "logprob_threshold": -1.0,
                "no_speech_threshold": 0.6
            },
            "backends": {
                "prefer_local": True,  # Use local model if available
                "allow_api": True,  # Allow OpenAI API fallback
                "cache_models": True  # Cache downloaded models
            }
        }
        
        if config_file and Path(config_file).exists():
            try:
                with open(config_file, 'r') as f:
                    user_config = json.load(f)
                # Merge configurations
                for key in user_config:
                    if isinstance(default_config.get(key), dict):
                        default_config[key].update(user_config[key])
                    else:
                        default_config[key] = user_config[key]
            except Exception as e:
                logger.warning(f"Could not load config file: {e}")
        
        return default_config
    
    def detect_backends(self) -> List[str]:
        """Detect available transcription backends"""
        backends = []
        
        # Check for whisper Python package
        try:
            import whisper
            backends.append('whisper-python')
            logger.info("✓ OpenAI Whisper (Python) detected")
        except ImportError:
            pass
        
        # Check for whisper.cpp
        if self.check_command('whisper'):
            backends.append('whisper-cpp')
            logger.info("✓ Whisper.cpp detected")
        
        # Check for faster-whisper
        try:
            import faster_whisper
            backends.append('faster-whisper')
            logger.info("✓ Faster-whisper detected")
        except ImportError:
            pass
        
        # Check for OpenAI API
        if os.environ.get('OPENAI_API_KEY'):
            backends.append('openai-api')
            logger.info("✓ OpenAI API available")
        
        # Check for whisperX (enhanced version)
        try:
            import whisperx
            backends.append('whisperx')
            logger.info("✓ WhisperX detected")
        except ImportError:
            pass
        
        if not backends:
            logger.warning("⚠ No Whisper backends available!")
            logger.info("Install with: pip install openai-whisper")
        
        return backends
    
    def check_command(self, command: str) -> bool:
        """Check if a command is available"""
        try:
            subprocess.run(['which', command], capture_output=True, check=True)
            return True
        except (subprocess.CalledProcessError, FileNotFoundError):
            return False
    
    def transcribe(self, audio_file: str, backend: Optional[str] = None) -> Dict:
        """Transcribe audio file using specified or best available backend"""
        
        audio_path = Path(audio_file)
        if not audio_path.exists():
            logger.error(f"Audio file not found: {audio_file}")
            return {"error": "File not found"}
        
        # Select backend
        if backend and backend in self.available_backends:
            backends_to_try = [backend]
        else:
            backends_to_try = self.available_backends
        
        if not backends_to_try:
            return {"error": "No transcription backends available"}
        
        # Try each backend
        for current_backend in backends_to_try:
            logger.info(f"Attempting transcription with: {current_backend}")
            
            try:
                if current_backend == 'whisper-python':
                    return self.transcribe_with_whisper_python(audio_file)
                elif current_backend == 'whisper-cpp':
                    return self.transcribe_with_whisper_cpp(audio_file)
                elif current_backend == 'faster-whisper':
                    return self.transcribe_with_faster_whisper(audio_file)
                elif current_backend == 'openai-api':
                    return self.transcribe_with_openai_api(audio_file)
                elif current_backend == 'whisperx':
                    return self.transcribe_with_whisperx(audio_file)
            except Exception as e:
                logger.warning(f"Backend {current_backend} failed: {e}")
                continue
        
        return {"error": "All transcription backends failed"}
    
    def transcribe_with_whisper_python(self, audio_file: str) -> Dict:
        """Transcribe using OpenAI Whisper Python package"""
        import whisper
        
        # Load model
        model = whisper.load_model(self.model_name)
        
        # Transcribe
        result = model.transcribe(
            audio_file,
            language=None if self.config['language'] == 'auto' else self.config['language'],
            temperature=self.config['temperature'],
            compression_ratio_threshold=self.config['options']['compression_ratio_threshold'],
            logprob_threshold=self.config['options']['logprob_threshold'],
            no_speech_threshold=self.config['options']['no_speech_threshold'],
            condition_on_previous_text=self.config['options']['condition_on_previous_text'],
            fp16=self.config['options']['fp16']
        )
        
        return {
            "text": result["text"],
            "language": result.get("language", "unknown"),
            "segments": result.get("segments", []),
            "backend": "whisper-python"
        }
    
    def transcribe_with_faster_whisper(self, audio_file: str) -> Dict:
        """Transcribe using Faster-whisper (optimized version)"""
        from faster_whisper import WhisperModel
        
        # Load model
        model = WhisperModel(
            self.model_name,
            device="auto" if self.config['device'] == 'auto' else self.config['device'],
            compute_type="float16" if self.config['options']['fp16'] else "float32"
        )
        
        # Transcribe
        segments, info = model.transcribe(
            audio_file,
            language=None if self.config['language'] == 'auto' else self.config['language'],
            temperature=self.config['temperature'],
            compression_ratio_threshold=self.config['options']['compression_ratio_threshold'],
            log_prob_threshold=self.config['options']['logprob_threshold'],
            no_speech_threshold=self.config['options']['no_speech_threshold'],
            condition_on_previous_text=self.config['options']['condition_on_previous_text']
        )
        
        # Collect text
        full_text = " ".join([segment.text for segment in segments])
        
        return {
            "text": full_text,
            "language": info.language,
            "duration": info.duration,
            "backend": "faster-whisper"
        }
    
    def transcribe_with_whisper_cpp(self, audio_file: str) -> Dict:
        """Transcribe using whisper.cpp (C++ implementation)"""
        
        # Convert audio to WAV if needed
        wav_file = self.ensure_wav_format(audio_file)
        
        cmd = [
            'whisper',
            '--model', self.model_name,
            '--file', wav_file,
            '--output-txt',
            '--threads', str(self.config['options']['threads'])
        ]
        
        if self.config['language'] != 'auto':
            cmd.extend(['--language', self.config['language']])
        
        try:
            result = subprocess.run(cmd, capture_output=True, text=True, check=True)
            
            # Read output file
            output_file = wav_file.replace('.wav', '.txt')
            with open(output_file, 'r') as f:
                text = f.read().strip()
            
            # Clean up
            if wav_file != audio_file:
                os.remove(wav_file)
            os.remove(output_file)
            
            return {
                "text": text,
                "backend": "whisper-cpp"
            }
            
        except subprocess.CalledProcessError as e:
            logger.error(f"Whisper.cpp failed: {e.stderr}")
            raise
    
    def transcribe_with_openai_api(self, audio_file: str) -> Dict:
        """Transcribe using OpenAI API"""
        try:
            import openai
            
            # Set API key
            openai.api_key = os.environ.get('OPENAI_API_KEY')
            
            # Open audio file
            with open(audio_file, 'rb') as f:
                # Call API
                response = openai.Audio.transcribe(
                    model="whisper-1",
                    file=f,
                    language=None if self.config['language'] == 'auto' else self.config['language'],
                    temperature=self.config['temperature']
                )
            
            return {
                "text": response["text"],
                "backend": "openai-api"
            }
            
        except Exception as e:
            logger.error(f"OpenAI API failed: {e}")
            raise
    
    def transcribe_with_whisperx(self, audio_file: str) -> Dict:
        """Transcribe using WhisperX (with alignment and diarization)"""
        import whisperx
        
        # Load model
        model = whisperx.load_model(
            self.model_name,
            device="auto" if self.config['device'] == 'auto' else self.config['device']
        )
        
        # Load audio
        audio = whisperx.load_audio(audio_file)
        
        # Transcribe
        result = model.transcribe(audio)
        
        # Align (if model available)
        if self.config['language'] != 'auto':
            model_a, metadata = whisperx.load_align_model(
                language_code=self.config['language'],
                device="auto" if self.config['device'] == 'auto' else self.config['device']
            )
            result = whisperx.align(
                result["segments"],
                model_a,
                metadata,
                audio,
                "auto" if self.config['device'] == 'auto' else self.config['device']
            )
        
        return {
            "text": " ".join([seg["text"] for seg in result["segments"]]),
            "segments": result["segments"],
            "backend": "whisperx"
        }
    
    def ensure_wav_format(self, audio_file: str) -> str:
        """Convert audio to WAV format if needed"""
        if audio_file.endswith('.wav'):
            return audio_file
        
        wav_file = audio_file.rsplit('.', 1)[0] + '.wav'
        
        # Use ffmpeg to convert
        cmd = ['ffmpeg', '-i', audio_file, '-ar', '16000', '-ac', '1', wav_file, '-y']
        subprocess.run(cmd, capture_output=True, check=True)
        
        return wav_file
    
    def transcribe_microphone(self, duration: int = 5) -> Dict:
        """Record from microphone and transcribe"""
        try:
            import sounddevice as sd
            import soundfile as sf
            import numpy as np
            
            # Recording parameters
            sample_rate = 16000
            channels = 1
            
            logger.info(f"Recording for {duration} seconds...")
            
            # Record audio
            audio_data = sd.rec(
                int(duration * sample_rate),
                samplerate=sample_rate,
                channels=channels,
                dtype='float32'
            )
            sd.wait()
            
            # Save to temporary file
            with tempfile.NamedTemporaryFile(suffix='.wav', delete=False) as tmp_file:
                sf.write(tmp_file.name, audio_data, sample_rate)
                temp_path = tmp_file.name
            
            # Transcribe
            result = self.transcribe(temp_path)
            
            # Clean up
            os.remove(temp_path)
            
            return result
            
        except ImportError:
            return {"error": "sounddevice not installed. Install with: pip install sounddevice soundfile"}
        except Exception as e:
            return {"error": f"Microphone recording failed: {e}"}
    
    def batch_transcribe(self, audio_dir: str, output_dir: str, 
                        pattern: str = "*.wav") -> Tuple[int, int]:
        """Batch transcribe audio files"""
        audio_path = Path(audio_dir)
        output_path = Path(output_dir)
        
        if not audio_path.exists():
            logger.error(f"Audio directory not found: {audio_dir}")
            return 0, 0
        
        output_path.mkdir(parents=True, exist_ok=True)
        
        audio_files = list(audio_path.glob(pattern))
        success_count = 0
        
        for audio_file in audio_files:
            logger.info(f"Transcribing: {audio_file.name}")
            
            result = self.transcribe(str(audio_file))
            
            if "error" not in result:
                # Save transcription
                output_file = output_path / f"{audio_file.stem}.txt"
                with open(output_file, 'w') as f:
                    f.write(result["text"])
                
                # Save metadata
                meta_file = output_path / f"{audio_file.stem}_meta.json"
                with open(meta_file, 'w') as f:
                    json.dump(result, f, indent=2)
                
                success_count += 1
                logger.info(f"✓ Saved: {output_file}")
            else:
                logger.error(f"✗ Failed: {audio_file.name}")
        
        return success_count, len(audio_files)
    
    def check_system(self) -> Dict:
        """Check system capabilities"""
        status = {
            'available_backends': self.available_backends,
            'models': {},
            'system': {}
        }
        
        # Check available models
        models = ['tiny', 'base', 'small', 'medium', 'large']
        for model in models:
            model_path = Path.home() / '.cache' / 'whisper' / f'{model}.pt'
            status['models'][model] = model_path.exists()
        
        # Check system tools
        status['system']['ffmpeg'] = self.check_command('ffmpeg')
        status['system']['sox'] = self.check_command('sox')
        
        # Check GPU
        try:
            import torch
            status['system']['cuda'] = torch.cuda.is_available()
            if status['system']['cuda']:
                status['system']['gpu_name'] = torch.cuda.get_device_name(0)
        except ImportError:
            status['system']['cuda'] = False
        
        return status

def main():
    """Command-line interface"""
    parser = argparse.ArgumentParser(
        description='Transcribe audio using OpenAI Whisper'
    )
    parser.add_argument(
        'input',
        nargs='?',
        help='Input audio file or directory'
    )
    parser.add_argument(
        '--output', '-o',
        help='Output file or directory'
    )
    parser.add_argument(
        '--model', '-m',
        choices=['tiny', 'base', 'small', 'medium', 'large'],
        default='base',
        help='Whisper model size (default: base)'
    )
    parser.add_argument(
        '--language', '-l',
        default='auto',
        help='Language code (default: auto-detect)'
    )
    parser.add_argument(
        '--backend', '-b',
        choices=['whisper-python', 'whisper-cpp', 'faster-whisper', 'openai-api', 'whisperx'],
        help='Force specific backend'
    )
    parser.add_argument(
        '--format', '-f',
        choices=['text', 'json', 'srt', 'vtt'],
        default='text',
        help='Output format (default: text)'
    )
    parser.add_argument(
        '--microphone', '--mic',
        action='store_true',
        help='Record from microphone'
    )
    parser.add_argument(
        '--duration', '-d',
        type=int,
        default=5,
        help='Recording duration in seconds (default: 5)'
    )
    parser.add_argument(
        '--batch',
        action='store_true',
        help='Batch process directory'
    )
    parser.add_argument(
        '--pattern',
        default='*.wav',
        help='File pattern for batch mode (default: *.wav)'
    )
    parser.add_argument(
        '--check',
        action='store_true',
        help='Check system capabilities'
    )
    parser.add_argument(
        '--config',
        help='Configuration JSON file'
    )
    parser.add_argument(
        '--verbose', '-v',
        action='store_true',
        help='Enable verbose output'
    )
    
    args = parser.parse_args()
    
    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)
    
    # Initialize transcriber
    config = {}
    if args.model:
        config['model'] = args.model
    if args.language:
        config['language'] = args.language
    
    config_file = args.config if args.config else None
    
    # Create transcriber with config
    if config:
        # Save temporary config
        with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
            json.dump(config, f)
            config_file = f.name
    
    transcriber = WhisperTranscriber(config_file)
    
    # Clean up temp config
    if config and config_file and 'tmp' in config_file:
        os.remove(config_file)
    
    # Check system
    if args.check:
        status = transcriber.check_system()
        print("\n=== Whisper System Check ===\n")
        print(f"Available backends: {', '.join(status['available_backends']) or 'None'}")
        print(f"\nModels downloaded:")
        for model, downloaded in status['models'].items():
            print(f"  {model:8} {'✓ Downloaded' if downloaded else '✗ Not downloaded'}")
        print(f"\nSystem tools:")
        for tool, available in status['system'].items():
            if tool != 'cuda' and tool != 'gpu_name':
                print(f"  {tool:8} {'✓ Available' if available else '✗ Not found'}")
        if status['system'].get('cuda'):
            print(f"\nGPU: ✓ CUDA available ({status['system'].get('gpu_name', 'Unknown')})")
        else:
            print(f"\nGPU: ✗ CUDA not available")
        
        if not status['available_backends']:
            print("\n⚠ No backends available!")
            print("\nInstall at least one:")
            print("  pip install openai-whisper  # Official Whisper")
            print("  pip install faster-whisper  # Optimized version")
            
        return 0
    
    # Microphone recording
    if args.microphone:
        result = transcriber.transcribe_microphone(args.duration)
        
        if "error" in result:
            print(f"Error: {result['error']}")
            return 1
        
        print(result["text"])
        
        if args.output:
            with open(args.output, 'w') as f:
                if args.format == 'json':
                    json.dump(result, f, indent=2)
                else:
                    f.write(result["text"])
            print(f"\nSaved to: {args.output}")
        
        return 0
    
    # Require input for file transcription
    if not args.input:
        parser.print_help()
        return 1
    
    # Batch processing
    if args.batch:
        if not args.output:
            args.output = "transcriptions"
        
        success, total = transcriber.batch_transcribe(
            args.input,
            args.output,
            args.pattern
        )
        print(f"\nBatch transcription complete: {success}/{total} files")
        return 0 if success == total else 1
    
    # Single file transcription
    result = transcriber.transcribe(args.input, args.backend)
    
    if "error" in result:
        print(f"Error: {result['error']}")
        return 1
    
    # Output results
    if args.format == 'json':
        output = json.dumps(result, indent=2)
    elif args.format == 'srt' and 'segments' in result:
        # Simple SRT format
        output = ""
        for i, seg in enumerate(result.get('segments', []), 1):
            start = seg.get('start', 0)
            end = seg.get('end', 0)
            text = seg.get('text', '')
            output += f"{i}\n"
            output += f"{format_time(start)} --> {format_time(end)}\n"
            output += f"{text}\n\n"
    else:
        output = result["text"]
    
    if args.output:
        with open(args.output, 'w') as f:
            f.write(output)
        print(f"Transcription saved to: {args.output}")
    else:
        print(output)
    
    return 0

def format_time(seconds: float) -> str:
    """Format seconds to SRT timestamp"""
    hours = int(seconds // 3600)
    minutes = int((seconds % 3600) // 60)
    secs = seconds % 60
    return f"{hours:02d}:{minutes:02d}:{secs:06.3f}".replace('.', ',')

if __name__ == '__main__':
    sys.exit(main())