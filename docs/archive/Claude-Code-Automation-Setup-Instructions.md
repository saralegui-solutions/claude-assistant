# Claude Code: Automation Setup Instructions

## Task 1: Create the Automation Scripts Directory
```
Create a new directory called "ai-dev-automation" in the user's home directory or a convenient location. Then create all the script files from the artifacts I provided:

1. Create `environment-manager.ps1` (main automation script)
2. Create individual .bat files for each environment:
   - `web-dev.bat`
   - `python-dev.bat` 
   - `data-science.bat`
   - `mobile-dev.bat`
   - `light-dev.bat`
   - `stop-all.bat`
   - `status.bat`
   - `setup-shortcuts.bat`
3. Create `ai-dev-utils.ps1` (advanced utilities)

Ensure all scripts are in the same directory.
```

## Task 2: Set Execution Policy
```
Run PowerShell as administrator and execute:
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

This allows the PowerShell scripts to run properly.
```

## Task 3: Test the Environment Manager
```
Test the main script by running:
powershell -File "environment-manager.ps1" -Environment status

This should show the current status of AI services.
```

## Task 4: Create Desktop Shortcuts
```
Run the setup-shortcuts.bat file to automatically create desktop shortcuts for each environment. This gives one-click access to each development environment.
```

## Task 5: Add to System PATH (Optional)
```
Add the ai-dev-automation directory to the system PATH so the scripts can be run from anywhere. Then create aliases:

Set-Alias -Name "ai-web" -Value "path\to\web-dev.bat"
Set-Alias -Name "ai-python" -Value "path\to\python-dev.bat"
Set-Alias -Name "ai-data" -Value "path\to\data-science.bat"
Set-Alias -Name "ai-mobile" -Value "path\to\mobile-dev.bat"
Set-Alias -Name "ai-light" -Value "path\to\light-dev.bat"
Set-Alias -Name "ai-stop" -Value "path\to\stop-all.bat"
Set-Alias -Name "ai-status" -Value "path\to\status.bat"
```

## Usage Examples After Setup

**Command Line Usage:**
- `ai-web` - Start web development environment
- `ai-python` - Start Python development environment  
- `ai-data` - Start data science environment
- `ai-light` - Start lightweight environment
- `ai-stop` - Stop all AI services
- `ai-status` - Check current status

**Advanced Features:**
- `powershell -c "Test-EnvironmentHealth"` - Run health check
- `powershell -c "Get-ResourceUsage"` - Check resource usage
- `powershell -c "Monitor-ModelPerformance -DurationMinutes 10"` - Monitor performance

## Environment Configurations

Each environment automatically:
1. Stops any running AI models
2. Starts the optimal model for that project type
3. Launches VS Code
4. Configures Continue.dev for the active model

**Model Assignments:**
- **Web Dev**: CodeLlama 7B (HTML, CSS, JS, frameworks)
- **Python**: Qwen2.5-Coder 7B (Python, data science)
- **Data Science**: Qwen2.5-Coder 7B (analytics, ML)
- **Mobile**: CodeLlama 7B (React Native, Flutter, native)
- **General**: Qwen2.5-Coder 7B (versatile coding)
- **Light**: Llama3.2 3B (minimal resource usage)

## Troubleshooting Commands

If something goes wrong:
1. `ai-status` - Check what's running
2. `ai-stop` - Stop everything and start fresh
3. `powershell -c "Test-EnvironmentHealth"` - Diagnose issues
4. Check the log file at `%USERPROFILE%\ai-dev-log.txt`

## Success Criteria

The automation is working when:
- [ ] One-click environment switching works
- [ ] Each environment loads the correct AI model
- [ ] VS Code launches automatically with AI assistance
- [ ] Resource usage is monitored and optimized
- [ ] Desktop shortcuts provide instant access
- [ ] Command-line aliases work from any directory
