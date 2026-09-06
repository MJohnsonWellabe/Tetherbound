@echo off
rem Tetherbound multiplayer session. Double-click to play with yourself first,
rem then with other people.
rem
rem By default it launches ONE HOST plus THREE CLIENTS as four windows on this
rem one machine, all joined to the same world. That is the fastest way to see
rem whether four players actually work; it is not a substitute for a real LAN,
rem because four windows on one PC share a CPU and never touch the network.
rem
rem   MULTIPLAYER_KICKOFF.cmd                 host + 3 clients on this PC
rem   MULTIPLAYER_KICKOFF.cmd -Clients 1      host + 1 client (kinder on a laptop)
rem   MULTIPLAYER_KICKOFF.cmd -HostOnly       host only, and print the address
rem                                           other machines should join
rem   MULTIPLAYER_KICKOFF.cmd -Join 192.168.1.42
rem                                           join a host on another machine
rem
rem On the ROG Ally, run it with -HostOnly and join from a PC: that is the
rem configuration whose frame time actually matters, and the only one whose
rem fps.json is worth recording in docs/acceptance/MULTIPLAYER_ACCEPTANCE.md.
rem
rem Details: docs/acceptance/MULTIPLAYER_ACCEPTANCE.md
setlocal
set "HERE=%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%HERE%multiplayer_kickoff.ps1" %*
set "RC=%ERRORLEVEL%"
echo.
if "%RC%"=="0" (
  echo Session finished. Any fps.json and logs are named above.
) else (
  echo Exit code %RC%. The log names what did not start.
)
echo You can close this window.
pause
endlocal
