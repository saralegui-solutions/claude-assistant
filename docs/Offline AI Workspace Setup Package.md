# Offline AI Workspace Setup

A complete offline AI setup for planning, coding, prompt preparation, and task management.

## Project Structure

```
offline-ai-workspace/
├── setup.sh                 # Main setup script
├── setup.py                 # Python setup orchestrator
├── docker-compose.yml       # Docker services configuration
├── models/
│   ├── download_models.sh   # Model download script
│   └── model_config.json    # Model configurations
├── interfaces/
│   ├── chat_interface.py    # Custom Python chat interface
│   ├── export_manager.py    # Conversation export utilities
│   └── dnd_orchestrator.py  # D&D specific interface
├── prompts/
│   ├── planning_templates.md
│   ├── coding_templates.md
│   └── voice_to_text_prep.md
├── config/
│   └── ollama_config.json
├── requirements.txt
├── README.md
└── .gitignore
```

## Core Files

### `setup.sh`
```bash
#!/bin/bash

# Offline AI Workspace Setup Script
set -e

echo "🚀 Starting Offline AI Workspace Setup..."

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
echo "📋 Checking prerequisites..."

if ! command_exists docker; then
    echo -e "${RED}Docker is not installed. Please install Docker first.${NC}"
    exit 1
fi

if ! command_exists python3; then
    echo -e "${RED}Python 3 is not installed. Please install Python 3.8+.${NC}"
    exit 1
fi

# Install Ollama if not present
if ! command_exists ollama; then
    echo "📦 Installing Ollama..."
    curl -fsSL https://ollama.ai/install.sh | sh
else
    echo -e "${GREEN}✓ Ollama already installed${NC}"
fi

# Start Ollama service
echo "🔧 Starting Ollama service..."
ollama serve &
OLLAMA_PID=$!
sleep 5

# Run Python setup script
echo "🐍 Running Python setup..."
python3 setup.py

# Download models
echo "📥 Downloading AI models..."
bash models/download_models.sh

# Start Docker services
echo "🐳 Starting Docker services..."
docker-compose up -d

# Install Python dependencies
echo "📚 Installing Python dependencies..."
pip3 install -r requirements.txt

echo -e "${GREEN}✅ Setup complete!${NC}"
echo ""
echo "📖 Quick Start Guide:"
echo "  1. Open WebUI: http://localhost:3000"
echo "  2. Run custom chat: python3 interfaces/chat_interface.py"
echo "  3. D&D mode: python3 interfaces/dnd_orchestrator.py"
echo ""
echo "💾 To save Ollama PID for cleanup: echo $OLLAMA_PID > .ollama.pid"
```

### `setup.py`
```python
#!/usr/bin/env python3
"""
Offline AI Workspace Setup Orchestrator
Handles model configuration and system preparation
"""

import json
import os
import subprocess
import sys
from pathlib import Path
import platform
import shutil

class OfflineAISetup:
    def __init__(self):
        self.base_dir = Path.cwd()
        self.models_dir = self.base_dir / "models"
        self.config_dir = self.base_dir / "config"
        self.interfaces_dir = self.base_dir / "interfaces"
        self.prompts_dir = self.base_dir / "prompts"
        
    def create_directories(self):
        """Create necessary directory structure"""
        dirs = [self.models_dir, self.config_dir, self.interfaces_dir, self.prompts_dir]
        for dir_path in dirs:
            dir_path.mkdir(exist_ok=True)
            print(f"✓ Created {dir_path}")
    
    def check_system_requirements(self):
        """Check system requirements and compatibility"""
        system = platform.system()
        print(f"System: {system}")
        
        # Check RAM
        if system == "Linux":
            mem_bytes = os.sysconf('SC_PAGE_SIZE') * os.sysconf('SC_PHYS_PAGES')
            mem_gb = mem_bytes / (1024.**3)
        elif system == "Darwin":  # macOS
            mem_bytes = int(subprocess.check_output(['sysctl', '-n', 'hw.memsize']).decode())
            mem_gb = mem_bytes / (1024.**3)
        else:  # Windows
            import psutil
            mem_gb = psutil.virtual_memory().total / (1024.**3)
        
        print(f"Available RAM: {mem_gb:.1f} GB")
        
        if mem_gb < 8:
            print("⚠️  Warning: Less than 8GB RAM detected. Smaller models recommended.")
            return "small"
        elif mem_gb < 16:
            print("ℹ️  16GB RAM detected. Medium models recommended.")
            return "medium"
        else:
            print("✓ 16GB+ RAM detected. Large models supported.")
            return "large"
    
    def generate_model_config(self, size_category):
        """Generate model configuration based on system capabilities"""
        model_config = {
            "size_category": size_category,
            "models": self.get_recommended_models(size_category),
            "settings": {
                "context_length": 4096 if size_category != "small" else 2048,
                "temperature": 0.7,
                "top_p": 0.95
            }
        }
        
        config_path = self.models_dir / "model_config.json"
        with open(config_path, 'w') as f:
            json.dump(model_config, f, indent=2)
        
        print(f"✓ Model configuration saved to {config_path}")
        return model_config
    
    def get_recommended_models(self, size_category):
        """Get recommended models based on system resources"""
        models = {
            "small": {
                "planning": ["llama3.2:3b", "phi3:mini"],
                "coding": ["deepseek-coder:1.3b", "codellama:7b-instruct"],
                "creative": ["llama3.2:3b", "gemma2:2b"],
                "general": ["llama3.2:3b", "mistral:7b-instruct"],
                "voice_prep": ["llama3.2:3b"]
            },
            "medium": {
                "planning": ["llama3.1:8b", "mistral:7b-instruct"],
                "coding": ["deepseek-coder:6.7b", "codellama:13b-instruct"],
                "creative": ["llama3.1:8b", "mixtral:8x7b"],
                "general": ["llama3.1:8b", "gemma2:9b"],
                "voice_prep": ["mistral:7b-instruct"]
            },
            "large": {
                "planning": ["llama3.1:70b", "mixtral:8x22b"],
                "coding": ["deepseek-coder:33b", "codellama:34b-instruct"],
                "creative": ["llama3.1:70b", "mixtral:8x22b"],
                "general": ["llama3.1:70b", "gemma2:27b"],
                "voice_prep": ["llama3.1:8b"]
            }
        }
        
        return models.get(size_category, models["small"])
    
    def create_docker_compose(self):
        """Create Docker Compose configuration"""
        compose_content = '''version: '3.8'

services:
  open-webui:
    image: ghcr.io/open-webui/open-webui:main
    container_name: open-webui
    ports:
      - "3000:8080"
    extra_hosts:
      - "host.docker.internal:host-gateway"
    volumes:
      - open-webui:/app/backend/data
      - ./exports:/app/exports
    environment:
      - OLLAMA_BASE_URL=http://host.docker.internal:11434
      - WEBUI_SECRET_KEY=offline-ai-workspace-secret
      - WEBUI_AUTH=false
    restart: unless-stopped

volumes:
  open-webui:
'''
        
        with open(self.base_dir / "docker-compose.yml", 'w') as f:
            f.write(compose_content)
        
        print("✓ Docker Compose configuration created")
    
    def run(self):
        """Run the complete setup process"""
        print("🚀 Initializing Offline AI Workspace Setup...")
        
        self.create_directories()
        size_category = self.check_system_requirements()
        model_config = self.generate_model_config(size_category)
        self.create_docker_compose()
        
        print("\n✅ Python setup complete!")
        print(f"📊 Recommended model tier: {size_category}")
        
        return model_config

if __name__ == "__main__":
    setup = OfflineAISetup()
    setup.run()
```

### `models/download_models.sh`
```bash
#!/bin/bash

# Model Download Script
# Downloads recommended models based on system configuration

echo "📥 Starting model downloads..."

# Read model configuration
if [ ! -f "models/model_config.json" ]; then
    echo "Error: model_config.json not found. Run setup.py first."
    exit 1
fi

# Parse JSON and get size category
SIZE_CATEGORY=$(python3 -c "import json; print(json.load(open('models/model_config.json'))['size_category'])")

echo "📊 Downloading models for $SIZE_CATEGORY configuration..."

# Function to download model with progress
download_model() {
    local model=$1
    local category=$2
    echo "  ⬇️  Downloading $model for $category..."
    ollama pull $model
    if [ $? -eq 0 ]; then
        echo "  ✓ $model downloaded successfully"
    else
        echo "  ⚠️  Failed to download $model"
    fi
}

# Download models based on configuration
case $SIZE_CATEGORY in
    "small")
        # Essential small models
        download_model "llama3.2:3b" "general/planning"
        download_model "deepseek-coder:1.3b" "coding"
        download_model "phi3:mini" "voice-prep"
        ;;
    "medium")
        # Medium-sized models
        download_model "llama3.1:8b" "general/planning"
        download_model "deepseek-coder:6.7b" "coding"
        download_model "mistral:7b-instruct" "voice-prep"
        download_model "gemma2:9b" "creative"
        ;;
    "large")
        # Large models (selective download due to size)
        download_model "llama3.1:8b" "general"  # Start with 8b version
        download_model "deepseek-coder:33b" "coding"
        download_model "mixtral:8x7b" "creative"
        echo "  ℹ️  For 70B models, run: ollama pull llama3.1:70b"
        ;;
esac

# Download embedding model for RAG
echo "  ⬇️  Downloading embedding model..."
ollama pull nomic-embed-text

echo "✅ Model downloads complete!"
echo ""
echo "📋 Installed models:"
ollama list
```

### `interfaces/chat_interface.py`
```python
#!/usr/bin/env python3
"""
Enhanced Chat Interface for Offline AI
Supports multiple models, conversation export, and Claude prep
"""

import json
import requests
from datetime import datetime
from pathlib import Path
import sys
from typing import List, Dict, Optional
from rich.console import Console
from rich.markdown import Markdown
from rich.prompt import Prompt, Confirm
from rich.table import Table
from rich.panel import Panel
from rich.syntax import Syntax
import click

console = Console()

class OfflineChat:
    def __init__(self, model: str = "llama3.1:8b"):
        self.model = model
        self.conversation_history = []
        self.session_id = datetime.now().strftime("%Y%m%d_%H%M%S")
        self.exports_dir = Path("exports")
        self.exports_dir.mkdir(exist_ok=True)
        self.ollama_url = "http://localhost:11434"
        
    def list_models(self) -> List[str]:
        """List available Ollama models"""
        try:
            response = requests.get(f"{self.ollama_url}/api/tags")
            if response.status_code == 200:
                models = response.json().get("models", [])
                return [m["name"] for m in models]
        except:
            pass
        return []
    
    def chat(self, prompt: str, system_prompt: Optional[str] = None) -> str:
        """Send chat request to Ollama"""
        messages = []
        
        if system_prompt:
            messages.append({"role": "system", "content": system_prompt})
        
        # Add conversation history
        for item in self.conversation_history[-10:]:  # Last 10 exchanges for context
            messages.append({"role": "user", "content": item["user"]})
            messages.append({"role": "assistant", "content": item["assistant"]})
        
        messages.append({"role": "user", "content": prompt})
        
        try:
            response = requests.post(
                f"{self.ollama_url}/api/chat",
                json={
                    "model": self.model,
                    "messages": messages,
                    "stream": False
                }
            )
            
            if response.status_code == 200:
                return response.json()["message"]["content"]
            else:
                return f"Error: {response.status_code}"
        except Exception as e:
            return f"Error connecting to Ollama: {e}"
    
    def export_for_claude(self) -> Path:
        """Export conversation formatted for Claude input"""
        export_path = self.exports_dir / f"claude_prep_{self.session_id}.md"
        
        with open(export_path, 'w') as f:
            f.write("# Offline Planning Session\n\n")
            f.write(f"**Date**: {datetime.now().strftime('%Y-%m-%d %H:%M')}\n")
            f.write(f"**Model Used**: {self.model}\n\n")
            f.write("## Conversation Summary\n\n")
            
            for i, exchange in enumerate(self.conversation_history, 1):
                f.write(f"### Exchange {i}\n\n")
                f.write(f"**User**: {exchange['user']}\n\n")
                f.write(f"**Assistant**: {exchange['assistant']}\n\n")
                f.write("---\n\n")
            
            f.write("\n## Claude Action Items\n\n")
            f.write("Based on this planning session, please help with:\n\n")
            f.write("1. [Auto-generated from conversation]\n")
            f.write("2. [Add specific tasks here]\n")
        
        return export_path
    
    def export_json(self) -> Path:
        """Export conversation as JSON"""
        export_path = self.exports_dir / f"session_{self.session_id}.json"
        
        export_data = {
            "session_id": self.session_id,
            "model": self.model,
            "timestamp": datetime.now().isoformat(),
            "conversation": self.conversation_history
        }
        
        with open(export_path, 'w') as f:
            json.dump(export_data, f, indent=2)
        
        return export_path
    
    def interactive_session(self):
        """Run interactive chat session"""
        console.print(Panel.fit(
            f"[bold green]Offline AI Chat Interface[/bold green]\n"
            f"Model: {self.model}\n"
            f"Session: {self.session_id}",
            border_style="green"
        ))
        
        # Show available models
        models = self.list_models()
        if models:
            console.print("\n[bold]Available models:[/bold]")
            for model in models:
                console.print(f"  • {model}")
        
        console.print("\n[dim]Commands: /export, /claude, /switch, /clear, /exit[/dim]\n")
        
        while True:
            try:
                user_input = Prompt.ask("\n[bold cyan]You[/bold cyan]")
                
                # Handle commands
                if user_input.startswith("/"):
                    self.handle_command(user_input)
                    continue
                
                if user_input.lower() in ['exit', 'quit']:
                    if Confirm.ask("Export conversation before exiting?"):
                        self.export_for_claude()
                        self.export_json()
                    break
                
                # Get response
                console.print("\n[bold magenta]AI[/bold magenta]: ", end="")
                with console.status("[bold green]Thinking..."):
                    response = self.chat(user_input)
                
                console.print(Markdown(response))
                
                # Save to history
                self.conversation_history.append({
                    "user": user_input,
                    "assistant": response,
                    "timestamp": datetime.now().isoformat()
                })
                
            except KeyboardInterrupt:
                console.print("\n[yellow]Use 'exit' to quit properly[/yellow]")
            except Exception as e:
                console.print(f"[red]Error: {e}[/red]")
    
    def handle_command(self, command: str):
        """Handle special commands"""
        cmd = command.lower().strip()
        
        if cmd == "/export":
            path = self.export_json()
            console.print(f"[green]Exported to: {path}[/green]")
        
        elif cmd == "/claude":
            path = self.export_for_claude()
            console.print(f"[green]Claude prep exported to: {path}[/green]")
        
        elif cmd == "/clear":
            self.conversation_history = []
            console.print("[yellow]Conversation history cleared[/yellow]")
        
        elif cmd.startswith("/switch"):
            models = self.list_models()
            if models:
                console.print("\nAvailable models:")
                for i, model in enumerate(models, 1):
                    console.print(f"{i}. {model}")
                choice = Prompt.ask("Select model number")
                try:
                    self.model = models[int(choice) - 1]
                    console.print(f"[green]Switched to {self.model}[/green]")
                except:
                    console.print("[red]Invalid selection[/red]")
        
        else:
            console.print("[yellow]Unknown command[/yellow]")

@click.command()
@click.option('--model', '-m', default="llama3.1:8b", help='Model to use')
def main(model):
    """Launch offline AI chat interface"""
    chat = OfflineChat(model=model)
    chat.interactive_session()

if __name__ == "__main__":
    main()
```

### `interfaces/dnd_orchestrator.py`
```python
#!/usr/bin/env python3
"""
D&D Campaign Orchestrator for Offline AI
Manages campaign state, NPCs, and game mechanics
"""

import json
import random
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Optional
import requests
from rich.console import Console
from rich.table import Table
from rich.panel import Panel
from rich.prompt import Prompt, IntPrompt
from dataclasses import dataclass, asdict
import pickle

console = Console()

@dataclass
class Character:
    name: str
    race: str
    class_type: str
    level: int
    hp: int
    max_hp: int
    stats: Dict[str, int]
    inventory: List[str]
    notes: str = ""

@dataclass
class Campaign:
    name: str
    setting: str
    current_location: str
    party: List[Character]
    npcs: List[Dict]
    quest_log: List[str]
    session_notes: List[Dict]
    world_state: Dict

class DnDOrchestrator:
    def __init__(self, model: str = "llama3.1:8b"):
        self.model = model
        self.ollama_url = "http://localhost:11434"
        self.campaigns_dir = Path("campaigns")
        self.campaigns_dir.mkdir(exist_ok=True)
        self.current_campaign: Optional[Campaign] = None
        
    def create_campaign(self) -> Campaign:
        """Create a new campaign"""
        console.print(Panel("[bold]Create New Campaign[/bold]"))
        
        name = Prompt.ask("Campaign name")
        setting = Prompt.ask("Setting/World")
        location = Prompt.ask("Starting location")
        
        campaign = Campaign(
            name=name,
            setting=setting,
            current_location=location,
            party=[],
            npcs=[],
            quest_log=[],
            session_notes=[],
            world_state={}
        )
        
        # Add party members
        if Prompt.ask("Add party members now?", choices=["y", "n"]) == "y":
            while True:
                character = self.create_character()
                campaign.party.append(character)
                if Prompt.ask("Add another?", choices=["y", "n"]) == "n":
                    break
        
        self.current_campaign = campaign
        self.save_campaign()
        return campaign
    
    def create_character(self) -> Character:
        """Create a new character"""
        name = Prompt.ask("Character name")
        race = Prompt.ask("Race")
        class_type = Prompt.ask("Class")
        level = IntPrompt.ask("Level", default=1)
        
        # Generate stats
        stats = {
            "STR": random.randint(8, 18),
            "DEX": random.randint(8, 18),
            "CON": random.randint(8, 18),
            "INT": random.randint(8, 18),
            "WIS": random.randint(8, 18),
            "CHA": random.randint(8, 18)
        }
        
        hp = random.randint(6, 12) * level + stats["CON"] // 2
        
        return Character(
            name=name,
            race=race,
            class_type=class_type,
            level=level,
            hp=hp,
            max_hp=hp,
            stats=stats,
            inventory=[]
        )
    
    def ai_request(self, prompt: str, context: Dict) -> str:
        """Make AI request with campaign context"""
        system_prompt = f"""You are a D&D Dungeon Master for the campaign '{self.current_campaign.name}'.
        Setting: {self.current_campaign.setting}
        Current Location: {self.current_campaign.current_location}
        
        Party Members:
        {json.dumps([asdict(c) for c in self.current_campaign.party], indent=2)}
        
        Recent Events:
        {json.dumps(self.current_campaign.session_notes[-5:] if self.current_campaign.session_notes else [], indent=2)}
        
        Quest Log:
        {json.dumps(self.current_campaign.quest_log, indent=2)}
        
        Respond in character as the DM. Be creative, engaging, and maintain consistency with the established world."""
        
        try:
            response = requests.post(
                f"{self.ollama_url}/api/chat",
                json={
                    "model": self.model,
                    "messages": [
                        {"role": "system", "content": system_prompt},
                        {"role": "user", "content": prompt}
                    ],
                    "stream": False
                }
            )
            
            if response.status_code == 200:
                return response.json()["message"]["content"]
            else:
                return "The mystical energies are disrupted... (AI error)"
        except Exception as e:
            return f"Connection to the astral plane failed: {e}"
    
    def run_encounter(self):
        """Run a combat or social encounter"""
        console.print(Panel("[bold]Encounter Manager[/bold]"))
        
        encounter_type = Prompt.ask("Encounter type", choices=["combat", "social", "puzzle"])
        description = Prompt.ask("Describe the situation")
        
        # Get AI to set the scene
        prompt = f"Set up a {encounter_type} encounter: {description}"
        response = self.ai_request(prompt, {"encounter_type": encounter_type})
        
        console.print(Panel(response, title="[bold red]Encounter[/bold red]"))
        
        # Log the encounter
        self.current_campaign.session_notes.append({
            "timestamp": datetime.now().isoformat(),
            "type": "encounter",
            "description": description,
            "dm_response": response
        })
        
        # Interactive encounter loop
        while True:
            action = Prompt.ask("\n[bold]Player action[/bold] (or 'end' to finish)")
            if action.lower() == 'end':
                break
            
            # Get AI response to action
            ai_response = self.ai_request(f"Player action: {action}", {"last_scene": response})
            console.print(f"\n[bold magenta]DM:[/bold magenta] {ai_response}")
            
            # Log the exchange
            self.current_campaign.session_notes.append({
                "timestamp": datetime.now().isoformat(),
                "type": "action",
                "player_action": action,
                "dm_response": ai_response
            })
    
    def generate_npc(self):
        """Generate an NPC using AI"""
        console.print(Panel("[bold]NPC Generator[/bold]"))
        
        npc_type = Prompt.ask("NPC type/role")
        personality = Prompt.ask("Personality traits (optional)", default="")
        
        prompt = f"Create a detailed NPC for a D&D campaign. Type: {npc_type}. "
        if personality:
            prompt += f"Personality: {personality}. "
        prompt += "Include name, appearance, motivation, secrets, and how they might interact with the party."
        
        npc_details = self.ai_request(prompt, {"npc_type": npc_type})
        
        console.print(Panel(npc_details, title="[bold]Generated NPC[/bold]"))
        
        if Prompt.ask("Save this NPC?", choices=["y", "n"]) == "y":
            self.current_campaign.npcs.append({
                "type": npc_type,
                "details": npc_details,
                "created": datetime.now().isoformat()
            })
            self.save_campaign()
    
    def export_for_claude(self) -> Path:
        """Export campaign data for Claude processing"""
        export_path = self.campaigns_dir / f"{self.current_campaign.name}_claude_export.md"
        
        with open(export_path, 'w') as f:
            f.write(f"# D&D Campaign: {self.current_campaign.name}\n\n")
            f.write(f"## Campaign Overview\n")
            f.write(f"- **Setting**: {self.current_campaign.setting}\n")
            f.write(f"- **Current Location**: {self.current_campaign.current_location}\n\n")
            
            f.write("## Party Members\n")
            for char in self.current_campaign.party:
                f.write(f"\n### {char.name}\n")
                f.write(f"- **Race/Class**: {char.race} {char.class_type}\n")
                f.write(f"- **Level**: {char.level}\n")
                f.write(f"- **HP**: {char.hp}/{char.max_hp}\n")
                f.write(f"- **Stats**: {char.stats}\n")
            
            f.write("\n## Quest Log\n")
            for quest in self.current_campaign.quest_log:
                f.write(f"- {quest}\n")
            
            f.write("\n## Session Notes\n")
            for note in self.current_campaign.session_notes[-20:]:  # Last 20 entries
                f.write(f"\n**{note.get('timestamp', 'Unknown time')}**\n")
                f.write(f"{note.get('dm_response', note)}\n")
            
            f.write("\n## Claude Tasks\n")
            f.write("1. Expand on the world lore\n")
            f.write("2. Generate detailed maps and locations\n")
            f.write("3. Create plot hooks for next session\n")
            f.write("4. Develop NPC backstories\n")
        
        return export_path
    
    def save_campaign(self):
        """Save current campaign to disk"""
        if not self.current_campaign:
            return
        
        save_path = self.campaigns_dir / f"{self.current_campaign.name}.pkl"
        with open(save_path, 'wb') as f:
            pickle.dump(self.current_campaign, f)
        
        # Also save as JSON for readability
        json_path = self.campaigns_dir / f"{self.current_campaign.name}.json"
        campaign_dict = {
            "name": self.current_campaign.name,
            "setting": self.current_campaign.setting,
            "current_location": self.current_campaign.current_location,
            "party": [asdict(c) for c in self.current_campaign.party],
            "npcs": self.current_campaign.npcs,
            "quest_log": self.current_campaign.quest_log,
            "session_notes": self.current_campaign.session_notes,
            "world_state": self.current_campaign.world_state
        }
        with open(json_path, 'w') as f:
            json.dump(campaign_dict, f, indent=2)
    
    def load_campaign(self, name: str) -> Optional[Campaign]:
        """Load a campaign from disk"""
        load_path = self.campaigns_dir / f"{name}.pkl"
        if load_path.exists():
            with open(load_path, 'rb') as f:
                self.current_campaign = pickle.load(f)
                return self.current_campaign
        return None
    
    def interactive_session(self):
        """Run interactive D&D session"""
        console.print(Panel.fit(
            "[bold red]D&D Campaign Orchestrator[/bold red]\n"
            "Offline AI-Powered Dungeon Master",
            border_style="red"
        ))
        
        # Load or create campaign
        campaigns = list(self.campaigns_dir.glob("*.pkl"))
        if campaigns:
            console.print("\n[bold]Available Campaigns:[/bold]")
            for i, camp in enumerate(campaigns, 1):
                console.print(f"{i}. {camp.stem}")
            console.print(f"{len(campaigns) + 1}. Create New Campaign")
            
            choice = IntPrompt.ask("Select campaign")
            if choice <= len(campaigns):
                self.load_campaign(campaigns[choice - 1].stem)
                console.print(f"[green]Loaded campaign: {self.current_campaign.name}[/green]")
            else:
                self.create_campaign()
        else:
            self.create_campaign()
        
        # Main menu loop
        while True:
            console.print("\n[bold]Actions:[/bold]")
            console.print("1. Run Encounter")
            console.print("2. Generate NPC")
            console.print("3. Add Quest")
            console.print("4. World Building")
            console.print("5. Party Management")
            console.print("6. Export for Claude")
            console.print("7. Save & Exit")
            
            choice = IntPrompt.ask("Select action")
            
            if choice == 1:
                self.run_encounter()
            elif choice == 2:
                self.generate_npc()
            elif choice == 3:
                quest = Prompt.ask("Enter quest description")
                self.current_campaign.quest_log.append(quest)
                console.print("[green]Quest added![/green]")
            elif choice == 4:
                topic = Prompt.ask("What aspect of the world to develop?")
                response = self.ai_request(f"Develop world lore about: {topic}", {})
                console.print(Panel(response, title="[bold]World Building[/bold]"))
                self.current_campaign.world_state[topic] = response
            elif choice == 5:
                # Party management submenu
                self.manage_party()
            elif choice == 6:
                path = self.export_for_claude()
                console.print(f"[green]Exported to: {path}[/green]")
            elif choice == 7:
                self.save_campaign()
                console.print("[green]Campaign saved![/green]")
                break
            
            self.save_campaign()  # Auto-save after each action
    
    def manage_party(self):
        """Manage party members"""
        console.print(Panel("[bold]Party Management[/bold]"))
        
        # Show current party
        table = Table(title="Current Party")
        table.add_column("Name")
        table.add_column("Race/Class")
        table.add_column("Level")
        table.add_column("HP")
        
        for char in self.current_campaign.party:
            table.add_row(
                char.name,
                f"{char.race} {char.class_type}",
                str(char.level),
                f"{char.hp}/{char.max_hp}"
            )
        
        console.print(table)
        
        action = Prompt.ask("Action", choices=["add", "edit", "remove", "back"])
        
        if action == "add":
            char = self.create_character()
            self.current_campaign.party.append(char)
            console.print(f"[green]{char.name} added to party![/green]")
        elif action == "edit":
            # Simple HP/inventory edit for now
            name = Prompt.ask("Character name to edit")
            for char in self.current_campaign.party:
                if char.name.lower() == name.lower():
                    char.hp = IntPrompt.ask("New HP", default=char.hp)
                    if Prompt.ask("Edit inventory?", choices=["y", "n"]) == "y":
                        item = Prompt.ask("Add item")
                        char.inventory.append(item)
                    break

def main():
    """Launch D&D Orchestrator"""
    orchestrator = DnDOrchestrator()
    orchestrator.interactive_session()

if __name__ == "__main__":
    main()
```

### `requirements.txt`
```
requests>=2.31.0
rich>=13.7.0
click>=8.1.7
psutil>=5.9.0
python-dotenv>=1.0.0
```

### `README.md`
```markdown
# Offline AI Workspace

A comprehensive offline AI setup for planning, coding, and creative work without internet connectivity.

## Features

- 🤖 **Multiple AI Models** - Optimized models for different tasks
- 💬 **Interactive Chat Interface** - Rich terminal UI with conversation export
- 🎲 **D&D Campaign Orchestrator** - Complete campaign management system
- 🌐 **Web UI** - Open WebUI for browser-based interaction
- 📤 **Claude Integration** - Export conversations formatted for Claude
- 🎯 **Task-Specific Models** - Specialized models for planning, coding, and creativity

## Quick Start

1. Clone the repository:
```bash
git clone https://github.com/yourusername/offline-ai-workspace.git
cd offline-ai-workspace
```

2. Run the setup:
```bash
chmod +x setup.sh
./setup.sh
```

3. Access the tools:
- Web UI: http://localhost:3000
- Chat Interface: `python3 interfaces/chat_interface.py`
- D&D Orchestrator: `python3 interfaces/dnd_orchestrator.py`

## Model Recommendations

### Small Systems (8GB RAM)
- **General/Planning**: llama3.2:3b
- **Coding**: deepseek-coder:1.3b
- **Creative**: gemma2:2b

### Medium Systems (16GB RAM)
- **General/Planning**: llama3.1:8b
- **Coding**: deepseek-coder:6.7b
- **Creative**: mixtral:8x7b

### Large Systems (32GB+ RAM)
- **General/Planning**: llama3.1:70b
- **Coding**: deepseek-coder:33b
- **Creative**: mixtral:8x22b

## Usage Examples

### Planning Session
```bash
python3 interfaces/chat_interface.py --model llama3.1:8b
# Use /claude command to export for Claude
```

### Code Development
```bash
python3 interfaces/chat_interface.py --model deepseek-coder:6.7b
# Focus on algorithm design and architecture
```

### D&D Campaign
```bash
python3 interfaces/dnd_orchestrator.py
# Manage campaigns, run encounters, generate NPCs
```

## Exporting for Claude

All interfaces support exporting conversations in a format optimized for Claude:

1. **Chat Interface**: Use `/claude` command
2. **D&D Orchestrator**: Select "Export for Claude" from menu
3. **Web UI**: Export conversations as markdown

## System Requirements

- Python 3.8+
- Docker & Docker Compose
- 8GB+ RAM (16GB recommended)
- 20GB+ free disk space for models

## Troubleshooting

### Ollama Connection Issues
```bash
# Check if Ollama is running
curl http://localhost:11434/api/tags

# Restart Ollama
ollama serve
```

### Model Download Failures
```bash
# Manual model download
ollama pull modelname

# List installed models
ollama list
```

## Contributing

Feel free to submit issues and enhancement requests!

## License

MIT License - See LICENSE file for details
```

### `.gitignore`
```
# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
env/
venv/
.venv
.env

# Ollama models (large files)
models/*.bin
models/*.gguf

# Exports and user data
exports/
campaigns/
*.pkl

# Docker
docker-compose.override.yml

# System
.DS_Store
Thumbs.db
.ollama.pid

# IDE
.vscode/
.idea/
*.swp
*.swo

# Logs
*.log
logs/

# Config overrides
config/local_*
```

### `prompts/planning_templates.md`
```markdown
# Planning Templates for Claude Preparation

## Project Planning Template
```
PROJECT: [Name]
OFFLINE WORK COMPLETED:
- Architecture decisions
- Component structure
- API design
- Database schema

CLAUDE TASKS:
1. Review architecture and suggest improvements
2. Generate implementation code for [specific components]
3. Create comprehensive tests
4. Document edge cases

SPECIFIC QUESTIONS:
- [Question 1 with context]
- [Question 2 with context]
```

## Code Review Preparation
```
CODE CONTEXT:
- Language: [Language]
- Framework: [Framework]
- Purpose: [Description]

PSEUDOCODE/ARCHITECTURE:
[Detailed pseudocode or architecture notes]

CLAUDE IMPLEMENTATION REQUEST:
- Convert pseudocode to production code
- Add error handling
- Implement [specific features]
- Optimize for [specific metrics]
```

## Research Summary Template
```
TOPIC: [Research Topic]

KEY FINDINGS:
1. [Finding with source]
2. [Finding with source]

GAPS IDENTIFIED:
- [Gap 1]
- [Gap 2]

CLAUDE RESEARCH REQUESTS:
- Deep dive into [specific aspect]
- Find recent developments in [area]
- Validate assumptions about [topic]
```
```

### `prompts/voice_to_text_prep.md`
```markdown
# Voice-to-Text Preparation Templates

## Structured Voice Note Format
```
VOICE NOTE TOPIC: [Topic]
DATE: [Date]
CONTEXT: [Brief context]

KEY POINTS:
- [Point 1]
- [Point 2]
- [Point 3]

ACTION ITEMS:
- [ ] [Action 1]
- [ ] [Action 2]

CLAUDE PROCESSING:
- Expand on [specific point]
- Research [related topic]
- Generate [specific output]
```

## Meeting Notes Template
```
MEETING: [Title]
PARTICIPANTS: [Names]
DATE: [Date]

DISCUSSION POINTS:
1. [Topic]: [Key decisions/notes]
2. [Topic]: [Key decisions/notes]

DECISIONS MADE:
- [Decision 1]
- [Decision 2]

FOLLOW-UP FOR CLAUDE:
- Create detailed project plan for [decision]
- Research best practices for [topic]
- Generate implementation timeline
```

## Brainstorming Session
```
BRAINSTORM TOPIC: [Topic]
DURATION: [Time]

RAW IDEAS:
- [Idea 1]
- [Idea 2]
- [Idea 3]

PROMISING DIRECTIONS:
1. [Direction with brief notes]
2. [Direction with brief notes]

CLAUDE EXPANSION:
- Develop [idea] into full proposal
- Identify potential challenges with [approach]
- Suggest alternatives to [solution]
```
```
