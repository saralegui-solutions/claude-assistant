#!/usr/bin/env python3
"""
Voice to File - Writes voice input to a file that can be read by Claude Code
"""

import speech_recognition as sr
import sys
import os
import time
from datetime import datetime

class VoiceToFile:
    def __init__(self):
        self.recognizer = sr.Recognizer()
        self.microphone = sr.Microphone()
        self.output_file = "/tmp/claude_voice_input.txt"
        
        # Calibrate for ambient noise
        with self.microphone as source:
            print("🎤 Calibrating microphone...")
            self.recognizer.adjust_for_ambient_noise(source, duration=1)
            self.recognizer.energy_threshold = 300
            print("✅ Ready!")
            
    def listen_and_write(self):
        """Listen and write to file"""
        print("\n🎙️  Listening... Speak your command:")
        print("   (Will timeout after 10 seconds of silence)")
        
        with self.microphone as source:
            try:
                audio = self.recognizer.listen(source, timeout=2, phrase_time_limit=30)
                print("🔄 Processing...")
                
                text = self.recognizer.recognize_google(audio)
                print(f"✅ Transcribed: {text}")
                
                # Write to file
                with open(self.output_file, 'w') as f:
                    f.write(text)
                
                print(f"📝 Saved to: {self.output_file}")
                print("\nNow you can:")
                print(f"  1. Run: claude < {self.output_file}")
                print(f"  2. Or copy: cat {self.output_file} | pbcopy")
                
                return text
                
            except sr.WaitTimeoutError:
                print("⏱️  Timeout - no speech detected")
                return None
            except sr.UnknownValueError:
                print("❌ Couldn't understand. Please speak clearly.")
                return None
            except sr.RequestError as e:
                print(f"❌ Speech service error: {e}")
                return None

def main():
    try:
        voice = VoiceToFile()
        result = voice.listen_and_write()
        
        if result:
            # Also print to stdout for scripting
            print(f"\n--- Voice Input ---")
            print(result)
            
    except KeyboardInterrupt:
        print("\n👋 Stopped")
    except Exception as e:
        print(f"❌ Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()