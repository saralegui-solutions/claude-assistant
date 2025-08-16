# Windows Voice Recognition Bridge for WSL
# This PowerShell script runs on Windows and captures voice input

Add-Type -AssemblyName System.Speech
$recognizer = New-Object System.Speech.Recognition.SpeechRecognitionEngine
$recognizer.SetInputToDefaultAudioDevice()

# Load a grammar (dictation)
$grammar = New-Object System.Speech.Recognition.DictationGrammar
$recognizer.LoadGrammar($grammar)

Write-Host "🎤 Windows Voice Recognition Ready" -ForegroundColor Green
Write-Host "Speak your command (will stop after 5 seconds of silence)..." -ForegroundColor Yellow

try {
    # Start recognition
    $recognizer.BabbleTimeout = [TimeSpan]::FromSeconds(2)
    $recognizer.InitialSilenceTimeout = [TimeSpan]::FromSeconds(5)
    $recognizer.EndSilenceTimeout = [TimeSpan]::FromSeconds(2)
    
    $result = $recognizer.Recognize()
    
    if ($result -ne $null) {
        $text = $result.Text
        Write-Host "✅ Transcribed: $text" -ForegroundColor Green
        
        # Write to WSL accessible location
        $wslPath = "\\wsl$\Ubuntu\tmp\claude_voice_input.txt"
        $text | Out-File -FilePath $wslPath -Encoding UTF8
        
        # Also output to console
        Write-Output $text
    } else {
        Write-Host "❌ No speech detected" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Error: $_" -ForegroundColor Red
} finally {
    $recognizer.Dispose()
}