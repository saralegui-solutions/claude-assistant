REM =============================================================================
REM QUICK ENVIRONMENT LAUNCHERS
REM Create these as separate .bat files for one-click access
REM =============================================================================

REM File: web-dev.bat
@echo off
echo Starting Web Development Environment...
powershell -ExecutionPolicy Bypass -File "%~dp0environment-manager.ps1" -Environment web
pause

REM =============================================================================

REM File: python-dev.bat
@echo off
echo Starting Python Development Environment...
powershell -ExecutionPolicy Bypass -File "%~dp0environment-manager.ps1" -Environment python
pause

REM =============================================================================

REM File: data-science.bat
@echo off
echo Starting Data Science Environment...
powershell -ExecutionPolicy Bypass -File "%~dp0environment-manager.ps1" -Environment data
pause

REM =============================================================================

REM File: mobile-dev.bat
@echo off
echo Starting Mobile Development Environment...
powershell -ExecutionPolicy Bypass -File "%~dp0environment-manager.ps1" -Environment mobile
pause

REM =============================================================================

REM File: light-dev.bat
@echo off
echo Starting Light Development Environment...
powershell -ExecutionPolicy Bypass -File "%~dp0environment-manager.ps1" -Environment light
pause

REM =============================================================================

REM File: stop-all.bat
@echo off
echo Stopping All AI Services...
powershell -ExecutionPolicy Bypass -File "%~dp0environment-manager.ps1" -Environment stop
pause

REM =============================================================================

REM File: status.bat
@echo off
echo Checking AI Environment Status...
powershell -ExecutionPolicy Bypass -File "%~dp0environment-manager.ps1" -Environment status
pause

REM =============================================================================

REM File: setup-shortcuts.bat - Run this once to create desktop shortcuts
@echo off
echo Creating desktop shortcuts...

set "desktopPath=%USERPROFILE%\Desktop"
set "scriptPath=%~dp0"

REM Create shortcuts
echo Creating shortcuts on desktop...
powershell "$ws = New-Object -ComObject WScript.Shell; $s = $ws.CreateShortcut('%desktopPath%\Web Dev AI.lnk'); $s.TargetPath = '%scriptPath%web-dev.bat'; $s.Save()"
powershell "$ws = New-Object -ComObject WScript.Shell; $s = $ws.CreateShortcut('%desktopPath%\Python Dev AI.lnk'); $s.TargetPath = '%scriptPath%python-dev.bat'; $s.Save()"
powershell "$ws = New-Object -ComObject WScript.Shell; $s = $ws.CreateShortcut('%desktopPath%\Data Science AI.lnk'); $s.TargetPath = '%scriptPath%data-science.bat'; $s.Save()"
powershell "$ws = New-Object -ComObject WScript.Shell; $s = $ws.CreateShortcut('%desktopPath%\Light Dev AI.lnk'); $s.TargetPath = '%scriptPath%light-dev.bat'; $s.Save()"
powershell "$ws = New-Object -ComObject WScript.Shell; $s = $ws.CreateShortcut('%desktopPath%\Stop AI Services.lnk'); $s.TargetPath = '%scriptPath%stop-all.bat'; $s.Save()"

echo Desktop shortcuts created!
pause
