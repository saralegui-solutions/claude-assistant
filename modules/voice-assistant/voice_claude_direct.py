#!/usr/bin/env python3
"""
Voice to Claude Code - Direct Integration
Listens to voice commands and pipes them directly to Claude Code
"""

import speech_recognition as sr
import subprocess
import sys
import os
import time
import signal

class VoiceToClaudeDirect:
    def __init__(self):
        self.recognizer = sr.Recognizer()
        self.microphone = sr.Microphone()
        self.continuous_mode = True
        
        # Calibrate for ambient noise
        with self.microphone as source:
            print("🎤 Calibrating microphone...")
            self.recognizer.adjust_for_ambient_noise(source, duration=1)
            self.recognizer.energy_threshold = 300  # Adjust sensitivity
            print("✅ Ready!")
            
    def listen_once(self, timeout=None):
        """Listen for a single phrase"""
        with self.microphone as source:
            try:
                if timeout:
                    audio = self.recognizer.listen(source, timeout=timeout, phrase_time_limit=15)
                else:
                    audio = self.recognizer.listen(source, phrase_time_limit=15)
                    
                # Use Google's free speech recognition
                text = self.recognizer.recognize_google(audio)
                return text
                
            except sr.WaitTimeoutError:
                return None
            except sr.UnknownValueError:
                print("❌ Couldn't understand. Please speak clearly.")
                return None
            except sr.RequestError as e:
                print(f"❌ Speech service error: {e}")
                return None
                
    def run_continuous(self):
        """Continuous listening mode"""
        print("\n🎙️  CONTINUOUS MODE - Listening...")
        print("Say 'stop recording' to end your message")
        print("Say 'exit voice mode' to quit")
        print("-" * 40)
        
        full_message = []
        
        while self.continuous_mode:
            text = self.listen_once(timeout=2)
            
            if text:
                print(f"📝 Heard: {text}")
                
                # Check for commands
                lower_text = text.lower()
                
                if "exit voice mode" in lower_text:
                    print("👋 Exiting voice mode")
                    break
                    
                elif "stop recording" in lower_text:
                    if full_message:
                        complete_text = " ".join(full_message)
                        print(f"\n✅ Complete message: {complete_text}")
                        print("-" * 40)
                        # Output to stdout for piping
                        print(complete_text, file=sys.stdout)
                        sys.stdout.flush()
                        full_message = []
                        print("\n🎙️  Ready for next message...")
                    continue
                    
                elif "clear message" in lower_text:
                    full_message = []
                    print("🗑️  Message cleared")
                    continue
                    
                # Add to message
                full_message.append(text)
                
        return " ".join(full_message) if full_message else None
        
    def run_single(self):
        """Single command mode"""
        print("\n🎙️  Listening for your command...")
        print("Speak now (max 15 seconds):")
        
        text = self.listen_once()
        
        if text:
            print(f"✅ Transcribed: {text}")
            return text
        else:
            return None

def main():
    # Parse arguments
    continuous = "--continuous" in sys.argv or "-c" in sys.argv
    
    # Setup signal handler for clean exit
    def signal_handler(sig, frame):
        print("\n👋 Voice input stopped")
        sys.exit(0)
    signal.signal(signal.SIGINT, signal_handler)
    
    try:
        voice = VoiceToClaudeDirect()
        
        if continuous:
            # Continuous mode for interactive use
            result = voice.run_continuous()
        else:
            # Single mode for one-shot commands
            result = voice.run_single()
            
        if result:
            # Output final result
            print(result, file=sys.stdout)
            
    except Exception as e:
        print(f"❌ Error: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()