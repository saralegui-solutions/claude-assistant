#!/usr/bin/env python3
"""
Claude API Orchestrator
Coordinates between voice input, Claude API planning, and Claude Code execution
"""

import json
import subprocess
from pathlib import Path
import sys
from datetime import datetime
import time
import os

# Check for anthropic module
try:
    import anthropic
except ImportError:
    print("❌ Error: anthropic module not found!")
    print("\nTo install it, run:")
    print("  pip3 install anthropic --user --break-system-packages")
    print("\nOr if you have pipx:")
    print("  pipx install anthropic")
    print("\nFor more information, see the README.md")
    sys.exit(1)

class ClaudeOrchestrator:
    def __init__(self, model=None):
        self.client = anthropic.Anthropic(
            api_key=self.load_api_key()
        )
        self.session_dir = Path.home() / '.claude' / 'orchestrated-sessions'
        self.session_dir.mkdir(parents=True, exist_ok=True)
        self.conversation_history = []
        self.current_session_id = datetime.now().strftime("%Y%m%d_%H%M%S")
        self.session_log_file = self.session_dir / f"session_{self.current_session_id}.log"
        
        # Model selection with Claude Opus 4.1 as default
        self.available_models = {
            "opus-4.1": "claude-opus-4-1-20250805",
            "opus": "claude-3-opus-20240229",
            "sonnet": "claude-3-5-sonnet-20241022",
            "sonnet-new": "claude-3-5-sonnet-20241022",
            "haiku": "claude-3-haiku-20240307"
        }
        
        # Set default model to Opus 4.1
        self.current_model = model if model else self.available_models["opus-4.1"]
        
        # If model is a shorthand, convert it
        if model and model.lower() in self.available_models:
            self.current_model = self.available_models[model.lower()]
        
    def load_api_key(self):
        """Load API key from environment or Claude Assistant config"""
        # First check environment variable
        if 'ANTHROPIC_API_KEY' in os.environ:
            return os.environ['ANTHROPIC_API_KEY']
            
        # Then check Claude Assistant config
        config_path = Path.home() / '.claude' / 'config' / 'api_key.json'
        if config_path.exists():
            with open(config_path) as f:
                data = json.load(f)
                return data.get('anthropic_api_key', data.get('api_key'))
        
        # Finally prompt for API key
        print("⚠️  No API key found!")
        print("Please set your Anthropic API key:")
        print("  1. Set environment variable: export ANTHROPIC_API_KEY='your-key'")
        print("  2. Or enter it now (will be saved):")
        
        key = input("API Key: ").strip()
        if key:
            config_path.parent.mkdir(parents=True, exist_ok=True)
            with open(config_path, 'w') as f:
                json.dump({'anthropic_api_key': key}, f)
            print("✅ API key saved to config")
            return key
        else:
            sys.exit("No API key provided")
    
    def log(self, message, level="INFO"):
        """Log messages to both console and file"""
        timestamp = datetime.now().strftime("%H:%M:%S")
        log_entry = f"[{timestamp}] {level}: {message}"
        
        # Console output with colors
        if level == "ERROR":
            print(f"❌ {message}")
        elif level == "WARNING":
            print(f"⚠️  {message}")
        elif level == "SUCCESS":
            print(f"✅ {message}")
        else:
            print(f"ℹ️  {message}")
        
        # File output
        with open(self.session_log_file, 'a') as f:
            f.write(log_entry + "\n")
    
    def select_model(self):
        """Interactive model selection"""
        print("\n🤖 Available Models:")
        print("  1. Claude Opus 4.1 (Latest, Recommended)")
        print("  2. Claude 3 Opus (Previous generation)")
        print("  3. Claude 3.5 Sonnet (Fast, capable)")
        print("  4. Claude 3 Haiku (Fastest, lightweight)")
        print(f"\nCurrent model: {self.get_model_name()}")
        print("\nSelect model [1-4, or press Enter to keep current]: ", end="")
        
        choice = input().strip()
        if choice == "1":
            self.current_model = self.available_models["opus-4.1"]
            print("✅ Switched to Claude Opus 4.1")
        elif choice == "2":
            self.current_model = self.available_models["opus"]
            print("✅ Switched to Claude 3 Opus")
        elif choice == "3":
            self.current_model = self.available_models["sonnet"]
            print("✅ Switched to Claude 3.5 Sonnet")
        elif choice == "4":
            self.current_model = self.available_models["haiku"]
            print("✅ Switched to Claude 3 Haiku")
        elif choice == "":
            print(f"Keeping current model: {self.get_model_name()}")
        else:
            print("Invalid choice, keeping current model")
    
    def get_model_name(self):
        """Get friendly name for current model"""
        for name, id in self.available_models.items():
            if id == self.current_model:
                return f"{name.upper()} ({id})"
        return self.current_model
    
    def capture_voice_input(self):
        """Use existing voice module to get input"""
        self.log("Listening for voice input...", "INFO")
        print("🎤 Speak your requirements (press Ctrl+C to stop)...")
        
        # Check for voice module
        voice_script = Path.home() / '.claude' / 'modules' / 'voice-assistant' / 'voice_claude_direct.py'
        if not voice_script.exists():
            # Fallback to text input
            self.log("Voice module not found, using text input", "WARNING")
            return input("📝 Enter your requirements: ")
        
        try:
            result = subprocess.run(
                ['python3', str(voice_script)],
                capture_output=True,
                text=True,
                timeout=60  # 60 second timeout for voice input
            )
            
            if result.returncode == 0 and result.stdout.strip():
                voice_text = result.stdout.strip()
                self.log(f"Captured: {voice_text[:100]}...", "SUCCESS")
                return voice_text
            else:
                # Fallback to text input
                self.log("Voice capture failed, using text input", "WARNING")
                return input("📝 Enter your requirements: ")
                
        except subprocess.TimeoutExpired:
            self.log("Voice input timeout", "WARNING")
            return input("📝 Enter your requirements: ")
        except Exception as e:
            self.log(f"Voice capture error: {e}", "ERROR")
            return input("📝 Enter your requirements: ")
    
    def send_to_claude_api(self, message, include_history=True):
        """Send message to Claude API with conversation context"""
        self.log("Sending to Claude API...", "INFO")
        
        # Build messages array with full context
        messages = self.conversation_history.copy() if include_history else []
        messages.append({
            "role": "user",
            "content": message
        })
        
        try:
            # Make API call with structured output request
            response = self.client.messages.create(
                model=self.current_model,
                max_tokens=4000,
                messages=messages,
                system="""You are helping orchestrate a Claude Code session. 
                
                When given planning requirements, respond with a JSON structure:
                {
                    "phase": "planning|execution|verification|complete",
                    "tasks": [
                        {
                            "type": "claude_code_prompt|file_creation|command",
                            "content": "the actual prompt or file content",
                            "filename": "optional filename if creating a file",
                            "description": "what this task does"
                        }
                    ],
                    "checkpoint": true/false,
                    "summary": "brief summary of what's being done",
                    "next_action": "what should happen next",
                    "success_criteria": "how to know if this succeeded"
                }
                
                Guidelines:
                - Break complex tasks into smaller, executable steps
                - Use claude_code_prompt for tasks requiring Claude Code
                - Use file_creation for creating config/data files
                - Use command for shell commands like testing or running scripts
                - Set checkpoint:true at major milestones for user review
                - In verification phase, check outputs and provide fixes if needed
                - Set phase:complete only when all requirements are fully met
                
                IMPORTANT: Your entire response must be valid JSON only. No markdown, no explanations outside JSON."""
            )
            
            # Parse response
            response_text = response.content[0].text
            
            # Update conversation history
            self.conversation_history.append(messages[-1])
            self.conversation_history.append({
                "role": "assistant",
                "content": response_text
            })
            
            # Try to parse as JSON
            try:
                parsed = json.loads(response_text)
                self.log("Claude API response parsed successfully", "SUCCESS")
                return parsed
            except json.JSONDecodeError as e:
                self.log(f"JSON parse error: {e}", "ERROR")
                # Try to extract JSON from response
                import re
                json_match = re.search(r'\{.*\}', response_text, re.DOTALL)
                if json_match:
                    try:
                        return json.loads(json_match.group())
                    except:
                        pass
                
                # Fallback response
                return {
                    "phase": "planning",
                    "tasks": [],
                    "summary": response_text[:200],
                    "checkpoint": True,
                    "next_action": "Review and provide clearer instructions"
                }
                
        except Exception as e:
            self.log(f"API call failed: {e}", "ERROR")
            return {
                "phase": "error",
                "tasks": [],
                "summary": f"API error: {str(e)}",
                "checkpoint": True
            }
    
    def execute_claude_code_task(self, task):
        """Execute a single Claude Code task"""
        self.log(f"Executing: {task.get('description', 'task')}", "INFO")
        
        task_type = task.get('type', 'unknown')
        
        if task_type == 'claude_code_prompt':
            # Save prompt to file for reference
            prompt_file = self.session_dir / f"prompt_{datetime.now().timestamp():.0f}.txt"
            prompt_file.write_text(task['content'])
            
            # Execute with Claude Code using pipe
            try:
                # Use echo to pipe the prompt to claude-code
                result = subprocess.run(
                    f'echo "{task["content"]}" | claude-code',
                    shell=True,
                    capture_output=True,
                    text=True,
                    cwd=str(Path.cwd()),
                    timeout=120  # 2 minute timeout
                )
                
                return {
                    "success": result.returncode == 0,
                    "output": result.stdout[:1000],  # Limit output size
                    "error": result.stderr[:500] if result.stderr else None
                }
            except subprocess.TimeoutExpired:
                return {
                    "success": False,
                    "output": "",
                    "error": "Command timed out after 2 minutes"
                }
            except Exception as e:
                return {
                    "success": False,
                    "output": "",
                    "error": str(e)
                }
            
        elif task_type == 'file_creation':
            # Create file directly
            try:
                filename = task.get('filename', f'file_{datetime.now().timestamp():.0f}.txt')
                # Create in current directory, not session directory
                file_path = Path.cwd() / filename
                file_path.parent.mkdir(parents=True, exist_ok=True)
                file_path.write_text(task['content'])
                
                return {
                    "success": True,
                    "output": f"Created {filename}",
                    "error": None
                }
            except Exception as e:
                return {
                    "success": False,
                    "output": "",
                    "error": str(e)
                }
            
        elif task_type == 'command':
            # Execute shell command
            try:
                result = subprocess.run(
                    task['content'],
                    shell=True,
                    capture_output=True,
                    text=True,
                    cwd=str(Path.cwd()),
                    timeout=60  # 1 minute timeout
                )
                return {
                    "success": result.returncode == 0,
                    "output": result.stdout[:1000],
                    "error": result.stderr[:500] if result.stderr else None
                }
            except subprocess.TimeoutExpired:
                return {
                    "success": False,
                    "output": "",
                    "error": "Command timed out"
                }
            except Exception as e:
                return {
                    "success": False,
                    "output": "",
                    "error": str(e)
                }
        
        else:
            return {
                "success": False,
                "output": "",
                "error": f"Unknown task type: {task_type}"
            }
    
    def run_orchestrated_session(self, initial_input=None):
        """Main orchestration loop"""
        print("\n" + "="*60)
        print("🚀 Claude Orchestrated Session")
        print(f"🤖 Model: {self.get_model_name()}")
        print("="*60 + "\n")
        
        self.log(f"Starting session {self.current_session_id}", "INFO")
        self.log(f"Using model: {self.get_model_name()}", "INFO")
        
        # Step 1: Get initial input (voice or text)
        if initial_input is None:
            initial_input = self.capture_voice_input()
        
        if not initial_input:
            self.log("No input provided", "ERROR")
            return
        
        # Step 2: Send to Claude API for planning
        print("\n🧠 Planning with Claude API...")
        response = self.send_to_claude_api(
            f"""I need help with the following project:
            
{initial_input}

Please analyze this request and provide a structured plan with specific tasks.
First, set phase to 'planning' and outline what needs to be done.
Then provide executable tasks for Claude Code."""
        )
        
        iteration = 0
        max_iterations = 15  # Safety limit
        
        while iteration < max_iterations:
            iteration += 1
            print(f"\n{'='*60}")
            print(f"📍 Iteration {iteration} - Phase: {response.get('phase', 'unknown').upper()}")
            print(f"{'='*60}")
            
            if 'summary' in response:
                print(f"📋 {response['summary']}")
            
            # Check if we're done
            if response.get('phase') == 'complete':
                self.log("Session completed successfully!", "SUCCESS")
                print("\n🎉 Project completed successfully!")
                if 'summary' in response:
                    print(f"Final summary: {response['summary']}")
                break
            
            # Check for error phase
            if response.get('phase') == 'error':
                self.log(f"Error phase: {response.get('summary')}", "ERROR")
                break
            
            # Execute tasks
            task_results = []
            if response.get('tasks'):
                print(f"\n📝 Executing {len(response['tasks'])} tasks:")
                for i, task in enumerate(response['tasks'], 1):
                    print(f"  [{i}/{len(response['tasks'])}] {task.get('description', 'Task')}")
                    result = self.execute_claude_code_task(task)
                    task_results.append({
                        "task": task.get('description', 'Unknown task'),
                        "type": task.get('type'),
                        "success": result['success'],
                        "output": result.get('output', '')[:200],  # Truncate for logging
                        "error": result.get('error')
                    })
                    
                    # Show progress
                    if result['success']:
                        self.log(f"Task completed: {task.get('description', '')}", "SUCCESS")
                    else:
                        self.log(f"Task failed: {result.get('error', 'Unknown error')}", "ERROR")
            
            # Check for checkpoint
            if response.get('checkpoint'):
                print("\n" + "="*60)
                print("🛑 CHECKPOINT - Review and decide next action")
                print("="*60)
                print("\nOptions:")
                print("  [c]ontinue    - Proceed with execution")
                print("  [r]eview      - Show detailed results")
                print("  [m]odify      - Provide new instructions")
                print("  [v]oice       - Add voice instructions")
                print("  [o]model      - Change AI model")
                print("  [s]top        - End session")
                
                choice = input("\n👉 Your choice [c/r/m/v/o/s]: ").lower().strip()
                
                if choice == 's':
                    self.log("Session stopped by user", "INFO")
                    break
                elif choice == 'm':
                    new_input = input("📝 New instructions: ")
                    response = self.send_to_claude_api(
                        f"""User provided new instructions: {new_input}
                        
Previous task results:
{json.dumps(task_results, indent=2)}

Please adjust the plan accordingly and provide next tasks."""
                    )
                    continue
                elif choice == 'v':
                    new_input = self.capture_voice_input()
                    response = self.send_to_claude_api(
                        f"""User provided new voice instructions: {new_input}
                        
Previous task results:
{json.dumps(task_results, indent=2)}

Please adjust the plan accordingly and provide next tasks."""
                    )
                    continue
                elif choice == 'r':
                    print("\n📊 Detailed Results:")
                    print(json.dumps(task_results, indent=2))
                    input("\nPress Enter to continue...")
                elif choice == 'o':
                    self.select_model()
                    # Continue with same context
            
            # Send results back to Claude for verification/next steps
            print("\n🔄 Getting next steps from Claude API...")
            
            # Prepare concise feedback
            feedback_message = f"""Task execution results for phase '{response.get('phase')}':

Success rate: {sum(1 for t in task_results if t['success'])}/{len(task_results)} tasks succeeded

Results:
{json.dumps(task_results, indent=2)}

Based on these results:
1. If tasks failed, provide fixes in the next iteration
2. If this phase succeeded, move to the next phase
3. If all requirements are met, set phase to 'complete'
4. Always provide clear next steps"""
            
            response = self.send_to_claude_api(feedback_message)
            
            # Rate limit protection
            time.sleep(1)  # Basic rate limiting
        
        if iteration >= max_iterations:
            self.log(f"Max iterations ({max_iterations}) reached", "WARNING")
            print(f"\n⚠️  Session ended: Maximum iterations reached")
        
        # Save session summary
        self.save_session_summary()
        
    def save_session_summary(self):
        """Save the complete session for reference"""
        summary_file = self.session_dir / f"session_{self.current_session_id}_summary.json"
        
        summary = {
            "session_id": self.current_session_id,
            "timestamp": datetime.now().isoformat(),
            "conversation_length": len(self.conversation_history),
            "conversation": self.conversation_history,
            "log_file": str(self.session_log_file),
            "files_created": [str(f) for f in self.session_dir.glob(f"*{self.current_session_id}*")]
        }
        
        with open(summary_file, 'w') as f:
            json.dump(summary, f, indent=2)
        
        self.log(f"Session saved to: {summary_file}", "SUCCESS")
        print(f"\n📁 Session files saved in: {self.session_dir}")
        print(f"   - Summary: {summary_file.name}")
        print(f"   - Log: {self.session_log_file.name}")

def main():
    """Main entry point"""
    model = None
    initial_input = None
    
    # Parse command line arguments
    i = 1
    while i < len(sys.argv):
        arg = sys.argv[i]
        
        if arg == '--help':
            print("Claude Orchestrator - Automated Claude Code Session Manager")
            print("\nUsage:")
            print("  orchestrator.py                    - Start with voice input")
            print("  orchestrator.py 'request'          - Start with text input")
            print("  orchestrator.py --model MODEL      - Select model (opus-4.1, opus, sonnet, haiku)")
            print("  orchestrator.py --select-model     - Interactive model selection")
            print("  orchestrator.py --help             - Show this help")
            print("\nModels:")
            print("  opus-4.1  - Claude Opus 4.1 (Latest, Default)")
            print("  opus      - Claude 3 Opus")
            print("  sonnet    - Claude 3.5 Sonnet")
            print("  haiku     - Claude 3 Haiku")
            print("\nExamples:")
            print("  orchestrator.py 'Create a Python web scraper'")
            print("  orchestrator.py --model opus-4.1 'Debug my test suite'")
            print("  orchestrator.py --select-model")
            sys.exit(0)
        elif arg == '--model' and i + 1 < len(sys.argv):
            model = sys.argv[i + 1]
            i += 2
        elif arg == '--select-model':
            # Will trigger interactive selection
            model = 'SELECT'
            i += 1
        else:
            # Rest is the input request
            initial_input = " ".join(sys.argv[i:])
            break
    
    try:
        orchestrator = ClaudeOrchestrator(model if model != 'SELECT' else None)
        
        # Interactive model selection if requested
        if model == 'SELECT':
            orchestrator.select_model()
        
        orchestrator.run_orchestrated_session(initial_input)
    except KeyboardInterrupt:
        print("\n\n⚠️  Session interrupted by user")
        sys.exit(0)
    except Exception as e:
        print(f"\n❌ Fatal error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()