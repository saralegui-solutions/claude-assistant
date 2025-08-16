#!/usr/bin/env python3
import speech_recognition as sr
import subprocess
import sys
import time
import threading
import os

class VoiceToClaudeCode:
    def __init__(self):
        self.recognizer = sr.Recognizer()
        self.microphone = sr.Microphone()
        self.listening = False
        
        # Adjust for ambient noise
        with self.microphone as source:
            print("🎤 Calibrating for ambient noise... Please wait.")
            self.recognizer.adjust_for_ambient_noise(source, duration=2)
            print("✅ Calibration complete!")
            
    def listen_and_transcribe(self):
        """Listen to microphone input and convert to text"""
        with self.microphone as source:
            print("\n🎙️  Listening... (speak now)")
            print("   Say 'stop listening' to pause or Ctrl+C to exit")
            
            try:
                # Listen with timeout
                audio = self.recognizer.listen(source, timeout=1, phrase_time_limit=10)
                print("🔄 Processing speech...")
                
                # Try Google's free speech recognition first
                try:
                    text = self.recognizer.recognize_google(audio)
                    return text
                except sr.UnknownValueError:
                    print("❌ Could not understand audio. Please speak clearly.")
                    return None
                except sr.RequestError as e:
                    print(f"❌ Error with speech recognition service: {e}")
                    return None
                    
            except sr.WaitTimeoutError:
                return None
                
    def send_to_claude(self, text):
        """Send the transcribed text to Claude Code"""
        if not text:
            return
            
        print(f"\n📝 Transcribed: '{text}'")
        
        # Check for stop command
        if "stop listening" in text.lower():
            print("⏸️  Paused. Press Enter to resume or Ctrl+C to exit.")
            input()
            return
        
        # Send to Claude Code (assuming it's running in interactive mode)
        try:
            # Write to a temporary file that Claude Code can read
            with open('/tmp/claude_voice_input.txt', 'w') as f:
                f.write(text)
            
            # You can also try to send directly to Claude Code if it's running
            # This assumes Claude Code is running in interactive mode
            print(f"✅ Ready to send to Claude: {text}")
            print("   Copy the text above and paste it into Claude Code")
            print("   OR press Enter to continue listening...")
            
        except Exception as e:
            print(f"❌ Error sending to Claude: {e}")
            
    def run(self):
        """Main loop for voice recognition"""
        print("\n🚀 Voice-to-Claude Started!")
        print("=" * 50)
        print("Instructions:")
        print("1. Speak clearly into your microphone")
        print("2. Wait for processing")
        print("3. Your speech will be transcribed")
        print("4. Copy the text to Claude Code")
        print("\nCommands:")
        print("- Say 'stop listening' to pause")
        print("- Press Ctrl+C to exit")
        print("=" * 50)
        
        try:
            while True:
                text = self.listen_and_transcribe()
                if text:
                    self.send_to_claude(text)
                    
        except KeyboardInterrupt:
            print("\n\n👋 Voice-to-Claude stopped. Goodbye!")
            sys.exit(0)

def main():
    try:
        voice_assistant = VoiceToClaudeCode()
        voice_assistant.run()
    except Exception as e:
        print(f"❌ Error: {e}")
        print("\nTroubleshooting:")
        print("1. Make sure your microphone is connected")
        print("2. Check microphone permissions")
        print("3. Try: 'sudo apt-get install python3-pyaudio'")
        sys.exit(1)

if __name__ == "__main__":
    main()