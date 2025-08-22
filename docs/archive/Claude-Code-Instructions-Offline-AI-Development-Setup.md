# Claude Code Instructions: Offline AI Development Setup for Surface Pro 9

## Phase 1: Install Core Components

**Task 1: Install Ollama**
```
Please install Ollama on this Windows system:
1. Download and install Ollama from https://ollama.ai/download
2. Verify installation by running `ollama --version`
3. Start the Ollama service
4. Test that it's running with `ollama list`
```

**Task 2: Download Recommended Models**
```
Download and install these AI models for offline use:
1. `ollama pull llama3.2:3b` (lightweight general model)
2. `ollama pull codellama:7b` (code-specialized model)
3. `ollama pull qwen2.5-coder:7b` (advanced coding model)
4. Verify models are installed with `ollama list`
5. Test each model briefly to ensure they work
```

## Phase 2: VS Code Setup

**Task 3: Install VS Code Extensions**
```
Install and configure VS Code with these extensions for offline AI development:
1. Install the Continue.dev extension
2. Install GitHub Copilot extension
3. Install Python extension pack
4. Install any other relevant language extensions for my typical projects
5. Configure Continue.dev to connect to local Ollama instance
```

**Task 4: Configure Continue.dev**
```
Configure Continue.dev for local Ollama integration:
1. Open Continue.dev settings
2. Set up Ollama as the provider
3. Configure it to use the installed models (llama3.2:3b, codellama:7b, qwen2.5-coder:7b)
4. Test the connection and ensure code completion works
5. Set up keyboard shortcuts for easy model switching
```

## Phase 3: Environment Optimization

**Task 5: System Optimization**
```
Optimize the system for AI model performance:
1. Check current RAM usage and available memory
2. Configure Windows power settings for high performance when plugged in
3. Set up environment variables for Ollama if needed
4. Create a simple script to start all services quickly
5. Test memory usage while running different models
```

**Task 6: Create Offline Development Scripts**
```
Create utility scripts for offline development:
1. A script to check which AI services are running
2. A script to switch between different AI models
3. A script to start the full offline development environment
4. A script to check system resources and model performance
5. Save these in an easily accessible location
```

## Phase 4: Testing and Validation

**Task 7: Comprehensive Testing**
```
Test the complete offline setup:
1. Disconnect from internet
2. Launch VS Code and test Continue.dev functionality
3. Test code completion and AI assistance with each model
4. Verify performance across different programming languages
5. Document any issues or performance bottlenecks
6. Create a quick reference guide for model selection
```

**Task 8: Backup Configuration**
```
Create backup of the working configuration:
1. Export VS Code settings and extensions list
2. Document the working Ollama configuration
3. Create a setup script that could recreate this environment
4. Save model download commands for future reference
```

## Additional Instructions

**Performance Notes:**
- Monitor RAM usage during model operations
- If performance is sluggish, try smaller models or reduce context windows
- Consider closing other applications when using larger models

**Model Selection Guide:**
- Use `llama3.2:3b` for general tasks and when conserving resources
- Use `codellama:7b` for most coding tasks
- Use `qwen2.5-coder:7b` for complex coding problems

**Troubleshooting:**
- If models fail to load, check available RAM
- If Ollama won't start, verify Windows services
- If Continue.dev doesn't connect, check Ollama API endpoint (usually localhost:11434)

## Success Criteria
The setup is complete when:
- [ ] All models download and run successfully
- [ ] VS Code with Continue.dev provides AI assistance offline
- [ ] System performs well with chosen models
- [ ] Quick startup scripts work reliably
- [ ] Full offline functionality confirmed

Please execute these tasks in order and let me know if you encounter any issues or need modifications for your specific workflow.
