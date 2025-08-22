# =============================================================================
# MAIN ENVIRONMENT MANAGER SCRIPT
# Save as: environment-manager.ps1
# =============================================================================

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("web", "python", "data", "mobile", "general", "light", "stop", "status")]
    [string]$Environment
)

# Configuration
$OllamaPath = "ollama"
$VSCodePath = "code"
$LogFile = "$env:USERPROFILE\ai-dev-log.txt"

function Write-Log {
    param($Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $Message" | Tee-Object -FilePath $LogFile -Append
}

function Stop-AllServices {
    Write-Log "Stopping all AI services..."
    try {
        & $OllamaPath stop 2>$null
        Get-Process -Name "ollama*" -ErrorAction SilentlyContinue | Stop-Process -Force
        Write-Log "All services stopped"
    }
    catch {
        Write-Log "Error stopping services: $_"
    }
}

function Start-OllamaModel {
    param($ModelName)
    Write-Log "Starting Ollama model: $ModelName"
    
    # Check if Ollama is running
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:11434/api/tags" -TimeoutSec 5 -ErrorAction Stop
    }
    catch {
        Write-Log "Starting Ollama service..."
        Start-Process -FilePath $OllamaPath -ArgumentList "serve" -WindowStyle Hidden
        Start-Sleep 5
    }
    
    # Load the model
    Write-Log "Loading model $ModelName..."
    & $OllamaPath run $ModelName --keepalive 10m
}

function Start-VSCode {
    param($ProjectPath = ".")
    Write-Log "Starting VS Code..."
    & $VSCodePath $ProjectPath
}

function Show-Status {
    Write-Log "=== AI Development Environment Status ==="
    
    # Check Ollama
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:11434/api/tags" -TimeoutSec 3
        $models = ($response.Content | ConvertFrom-Json).models
        Write-Host "✓ Ollama is running" -ForegroundColor Green
        Write-Host "Loaded models:" -ForegroundColor Yellow
        foreach ($model in $models) {
            Write-Host "  - $($model.name)" -ForegroundColor Cyan
        }
    }
    catch {
        Write-Host "✗ Ollama is not running" -ForegroundColor Red
    }
    
    # Check VS Code
    $vscode = Get-Process -Name "Code" -ErrorAction SilentlyContinue
    if ($vscode) {
        Write-Host "✓ VS Code is running ($($vscode.Count) instances)" -ForegroundColor Green
    }
    else {
        Write-Host "✗ VS Code is not running" -ForegroundColor Red
    }
    
    # System resources
    $memory = Get-WmiObject -Class Win32_ComputerSystem
    $freeMemory = (Get-WmiObject -Class Win32_OperatingSystem).FreePhysicalMemory / 1MB
    Write-Host "Memory: $([math]::Round($freeMemory, 2)) GB free" -ForegroundColor Yellow
}

# =============================================================================
# ENVIRONMENT CONFIGURATIONS
# =============================================================================

switch ($Environment) {
    "web" {
        Write-Log "Starting WEB DEVELOPMENT environment"
        Stop-AllServices
        Start-Sleep 2
        Start-OllamaModel "codellama:7b"
        Start-VSCode
        Write-Host "🌐 Web Development Environment Ready!" -ForegroundColor Green
        Write-Host "Model: CodeLlama 7B (optimized for web development)" -ForegroundColor Cyan
    }
    
    "python" {
        Write-Log "Starting PYTHON DEVELOPMENT environment"
        Stop-AllServices
        Start-Sleep 2
        Start-OllamaModel "qwen2.5-coder:7b"
        Start-VSCode
        Write-Host "🐍 Python Development Environment Ready!" -ForegroundColor Green
        Write-Host "Model: Qwen2.5-Coder 7B (excellent for Python)" -ForegroundColor Cyan
    }
    
    "data" {
        Write-Log "Starting DATA SCIENCE environment"
        Stop-AllServices
        Start-Sleep 2
        Start-OllamaModel "qwen2.5-coder:7b"
        Start-VSCode
        Write-Host "📊 Data Science Environment Ready!" -ForegroundColor Green
        Write-Host "Model: Qwen2.5-Coder 7B (great for data analysis)" -ForegroundColor Cyan
    }
    
    "mobile" {
        Write-Log "Starting MOBILE DEVELOPMENT environment"
        Stop-AllServices
        Start-Sleep 2
        Start-OllamaModel "codellama:7b"
        Start-VSCode
        Write-Host "📱 Mobile Development Environment Ready!" -ForegroundColor Green
        Write-Host "Model: CodeLlama 7B (good for mobile frameworks)" -ForegroundColor Cyan
    }
    
    "general" {
        Write-Log "Starting GENERAL DEVELOPMENT environment"
        Stop-AllServices
        Start-Sleep 2
        Start-OllamaModel "qwen2.5-coder:7b"
        Start-VSCode
        Write-Host "⚡ General Development Environment Ready!" -ForegroundColor Green
        Write-Host "Model: Qwen2.5-Coder 7B (versatile for all tasks)" -ForegroundColor Cyan
    }
    
    "light" {
        Write-Log "Starting LIGHT environment (low resource usage)"
        Stop-AllServices
        Start-Sleep 2
        Start-OllamaModel "llama3.2:3b"
        Start-VSCode
        Write-Host "🪶 Light Development Environment Ready!" -ForegroundColor Green
        Write-Host "Model: Llama3.2 3B (minimal resource usage)" -ForegroundColor Cyan
    }
    
    "stop" {
        Write-Log "Stopping all AI development services"
        Stop-AllServices
        Write-Host "🛑 All AI services stopped" -ForegroundColor Yellow
    }
    
    "status" {
        Show-Status
    }
}

# =============================================================================
# ADDITIONAL UTILITY SCRIPTS
# =============================================================================
