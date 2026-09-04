@echo off
rem Tetherbound evidence run. Double-click this file and walk away.
rem
rem It installs the pinned Godot and ffmpeg into %LOCALAPPDATA%\Tetherbound,
rem fetches the branch, renders the route, measures the frame rate on THIS
rem machine, runs the shipped Windows build, plays the whole chapter through the
rem Gate F harness with video, and pushes the evidence to a branch. Nothing in
rem it asks a question. Details: docs\acceptance\KICKOFF_RUN.md.
rem
rem Optional switches (drag-and-drop is not needed; edit a shortcut or run from
rem a prompt):  KICKOFF.cmd -Quick      frames, perf and the shipped build only
rem             KICKOFF.cmd -Only chain  just the chapter playthrough
setlocal
set "HERE=%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%HERE%kickoff.ps1" %*
set "RC=%ERRORLEVEL%"
echo.
if "%RC%"=="0" (
  echo Kickoff finished. The evidence branch and the zip are named above.
) else (
  echo Kickoff finished with exit code %RC%. The log names what did not run.
)
echo You can close this window.
pause
endlocal
