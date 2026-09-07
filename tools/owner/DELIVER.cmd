@echo off
rem Deliver a finished kickoff run: pack the text evidence, then push the
rem owner-run branch, logging into GitHub only if the push actually needs it.
rem Double-click this. It asks nothing except the GitHub browser approval.
setlocal
set "HERE=%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%HERE%deliver.ps1" %*
endlocal
