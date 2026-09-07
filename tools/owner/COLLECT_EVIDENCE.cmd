@echo off
rem Collect a kickoff run's TEXT evidence into one small zip on the Desktop.
rem
rem Use this when a run finished but could not push: the big Desktop zip is
rem ~170 MB of frames and video, and the verdict is a few hundred KB of text.
rem Double-click this, then attach the kickoff-text-*.zip it names.
setlocal
set "HERE=%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%HERE%collect_evidence.ps1" %*
echo.
pause
endlocal
