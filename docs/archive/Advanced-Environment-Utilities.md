# =============================================================================
# ADVANCED ENVIRONMENT UTILITIES
# Save as: ai-dev-utils.ps1
# =============================================================================

# Model Performance Monitor
function Monitor-ModelPerformance {
    param(
        [int]$DurationMinutes = 5
    )
    
    Write-Host "Monitoring AI model performance for $DurationMinutes minutes..." -ForegroundColor Yellow
    $endTime = (Get-Date).AddMinutes($DurationMinutes)
    
    while ((Get-Date) -lt $endTime) {
        $memory = Get-Process -Name "ollama*" -ErrorAction SilentlyContinue | Measure-Object WorkingSet -Sum
        if ($memory.Sum) {
            $memoryMB = [math]::Round($memory.Sum / 1MB, 2)
            Write-Host "$(Get-Date -Format 'HH:mm:ss') - Ollama Memory Usage: $memoryMB MB" -ForegroundColor Cyan
        }
        Start-Sleep 30
    }
}

# Quick Model Switcher
function Switch-Model {
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet("llama3.2:3b", "codellama:7b", "qwen2.5-coder:7b")]
        [string]$ModelName
    )
    
    Write-Host "Switching to model: $ModelName" -ForegroundColor Yellow
    
    # Stop current model
    ollama stop
    Start-Sleep 2
    
    # Start new model
    Start-Process -FilePath "ollama" -ArgumentList "run", $ModelName, "--keepalive", "15m" -WindowStyle Hidden
    
    Write-Host "Model switched to $ModelName" -ForegroundColor Green
}

# Environment Health Check
function Test-EnvironmentHealth {
    Write-Host "🔍 Running Environment Health Check..." -ForegroundColor Yellow
    $issues = @()
    
    # Check Ollama
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:11434/api/tags" -TimeoutSec 5
        Write-Host "✓ Ollama API responding" -ForegroundColor Green
    }
    catch {
        $issues += "Ollama API not responding"
        Write-Host "✗ Ollama API not responding" -ForegroundColor Red
    }
    
    # Check available models
    try {
        $models = ollama list 2>$null
        $requiredModels = @("llama3.2:3b", "codellama:7b", "qwen2.5-coder:7b")
        foreach ($model in $requiredModels) {
            if ($models -match $model) {
                Write-Host "✓ Model $model available" -ForegroundColor Green
            }
            else {
                $issues += "Missing model: $model"
                Write-Host "✗ Missing model: $model" -ForegroundColor Red
            }
        }
    }
    catch {
        $issues += "Cannot check available models"
    }
    
    # Check memory
    $freeMemory = (Get-WmiObject -Class Win32_OperatingSystem).FreePhysicalMemory / 1MB
    if ($freeMemory -lt 2000) {
        $issues += "Low memory: $([math]::Round($freeMemory, 2)) MB free"
        Write-Host "⚠ Low memory: $([math]::Round($freeMemory, 2)) MB free" -ForegroundColor Yellow
    }
    else {
        Write-Host "✓ Memory OK: $([math]::Round($freeMemory, 2)) MB free" -ForegroundColor Green
    }
    
    # Check VS Code extensions
    try {
        $extensions = code --list-extensions 2>$null
        $requiredExtensions = @("continue.continue", "github.copilot")
        foreach ($ext in $requiredExtensions) {
            if ($extensions -match $ext) {
                Write-Host "✓ Extension $ext installed" -ForegroundColor Green
            }
            else {
                $issues += "Missing VS Code extension: $ext"
                Write-Host "✗ Missing VS Code extension: $ext" -ForegroundColor Red
            }
        }
    }
    catch {
        Write-Host "⚠ Cannot check VS Code extensions" -ForegroundColor Yellow
    }
    
    # Summary
    if ($issues.Count -eq 0) {
        Write-Host "`n🎉 Environment is healthy!" -ForegroundColor Green
    }
    else {
        Write-Host "`n⚠ Issues found:" -ForegroundColor Red
        foreach ($issue in $issues) {
            Write-Host "  - $issue" -ForegroundColor Red
        }
    }
    
    return $issues.Count -eq 0
}

# Project-Specific Environment Launcher
function Start-ProjectEnvironment {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ProjectPath,
        [string]$ProjectType = "auto"
    )
    
    if (-not (Test-Path $ProjectPath)) {
        Write-Host "Project path not found: $ProjectPath" -ForegroundColor Red
        return
    }
    
    # Auto-detect project type
    if ($ProjectType -eq "auto") {
        $files = Get-ChildItem -Path $ProjectPath -File
        
        if ($files | Where-Object { $_.Name -match "\.(py|ipynb)$" }) {
            $ProjectType = "python"
        }
        elseif ($files | Where-Object { $_.Name -match "\.(js|ts|jsx|tsx|html|css)$" }) {
            $ProjectType = "web"
        }
        elseif ($files | Where-Object { $_.Name -match "\.(java|kt|swift)$" }) {
            $ProjectType = "mobile"
        }
        else {
            $ProjectType = "general"
        }
        
        Write-Host "Auto-detected project type: $ProjectType" -ForegroundColor Cyan
    }
    
    # Start appropriate environment
    Write-Host "Starting $ProjectType environment for: $ProjectPath" -ForegroundColor Yellow
    & "$PSScriptRoot\environment-manager.ps1" -Environment $ProjectType
    
    # Open project in VS Code
    Start-Sleep 3
    code $ProjectPath
}

# Resource Usage Reporter
function Get-ResourceUsage {
    $cpu = (Get-WmiObject -Class Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average
    $memory = Get-WmiObject -Class Win32_OperatingSystem
    $totalMemory = [math]::Round($memory.TotalVisibleMemorySize / 1MB, 2)
    $freeMemory = [math]::Round($memory.FreePhysicalMemory / 1MB, 2)
    $usedMemory = $totalMemory - $freeMemory
    $memoryPercent = [math]::Round(($usedMemory / $totalMemory) * 100, 1)
    
    Write-Host "=== Resource Usage ===" -ForegroundColor Yellow
    Write-Host "CPU: $cpu%" -ForegroundColor Cyan
    Write-Host "Memory: $usedMemory MB / $totalMemory MB ($memoryPercent%)" -ForegroundColor Cyan
    
    # AI-specific processes
    $ollamaProcess = Get-Process -Name "ollama*" -ErrorAction SilentlyContinue
    if ($ollamaProcess) {
        $ollamaMemory = [math]::Round(($ollamaProcess | Measure-Object WorkingSet -Sum).Sum / 1MB, 2)
        Write-Host "Ollama Memory: $ollamaMemory MB" -ForegroundColor Green
    }
    
    $vscodeProcess = Get-Process -Name "Code" -ErrorAction SilentlyContinue
    if ($vscodeProcess) {
        $vscodeMemory = [math]::Round(($vscodeProcess | Measure-Object WorkingSet -Sum).Sum / 1MB, 2)
        Write-Host "VS Code Memory: $vscodeMemory MB" -ForegroundColor Green
    }
}

# Installation Helper
function Install-MissingComponents {
    Write-Host "Checking for missing components..." -ForegroundColor Yellow
    
    # Check Ollama
    try {
        ollama --version | Out-Null
        Write-Host "✓ Ollama installed" -ForegroundColor Green
    }
    catch {
        Write-Host "Installing Ollama..." -ForegroundColor Yellow
        # Add Ollama installation logic here
        Write-Host "Please install Ollama manually from https://ollama.ai/download" -ForegroundColor Red
    }
    
    # Check VS Code
    try {
        code --version | Out-Null
        Write-Host "✓ VS Code installed" -ForegroundColor Green
    }
    catch {
        Write-Host "Please install VS Code manually" -ForegroundColor Red
    }
    
    # Install required models
    $requiredModels = @("llama3.2:3b", "codellama:7b", "qwen2.5-coder:7b")
    foreach ($model in $requiredModels) {
        Write-Host "Pulling model: $model" -ForegroundColor Yellow
        ollama pull $model
    }
}

# Export functions for use
Export-ModuleMember -Function Monitor-ModelPerformance, Switch-Model, Test-EnvironmentHealth, Start-ProjectEnvironment, Get-ResourceUsage, Install-MissingComponents
