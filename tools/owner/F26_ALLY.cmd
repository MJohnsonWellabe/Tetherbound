@echo off
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0f26_ally.ps1"
set "F26_RESULT=%ERRORLEVEL%"
echo.
pause
exit /b %F26_RESULT%
