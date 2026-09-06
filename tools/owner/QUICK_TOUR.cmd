@echo off
rem Tetherbound QUICK TOUR. Double-click this file and walk away.
rem
rem A fast, breadth-first spot-check across BOTH shipped biomes (the Meadows
rem and Cloudreach Cliffs), capped at ~20 minutes per biome. Stills at a
rem handful of important locations (day and, for one, night), a combat
rem moment, the HUD, the menu, a creature, the player character, and a short
rem real play check (walk to a resource node and gather once) -- for each
rem biome, plus a shared title/creature-roster/character-cast pass.
rem
rem This is NOT tools/owner/KICKOFF.cmd. KICKOFF is the full overnight Gate F
rem evidence pipeline that ships chapter-acceptance evidence and pushes an
rem owner-run/<stamp> branch. QUICK_TOUR produces no evidence branch -- its
rem output is a local zip on your Desktop and a run folder under
rem %LOCALAPPDATA%\Tetherbound, meant for a quick look, not for gating a
rem decision. Details: docs/00_START_HERE.md.
rem
rem Optional switches (edit a shortcut or run from a prompt):
rem   QUICK_TOUR.cmd -BudgetMinutes 15     tighter per-biome cap
rem   QUICK_TOUR.cmd -Only meadows         one biome only
rem   QUICK_TOUR.cmd -SkipShared           skip title/roster/cast, biomes only
setlocal
set "HERE=%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%HERE%quick_tour.ps1" %*
set "RC=%ERRORLEVEL%"
echo.
if "%RC%"=="0" (
  echo Quick tour finished. The zip on your Desktop and the log above name what was captured.
) else (
  echo Quick tour finished with exit code %RC%. The log names what did not run.
)
echo You can close this window.
pause
endlocal
