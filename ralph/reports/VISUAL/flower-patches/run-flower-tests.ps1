$ErrorActionPreference='Stop'
$lockPath='D:/tetherbound/RENDER_LOCK.json'
$old=Get-Content -LiteralPath $lockPath -Raw | ConvertFrom-Json
if ($old.held_by) { throw "Render lock held by $($old.held_by)" }
$env:APPDATA='D:/tetherbound/visual-acceptance-local/profile'
$logBase='D:/tetherbound/visual-acceptance-local/flower-patches-tests'
$record=@{held_by='combat';since_utc=[DateTime]::UtcNow.ToString('o');pid=0;shell_pid=$PID}
$record | ConvertTo-Json | Set-Content -LiteralPath $lockPath
try {
  $proc=Start-Process 'D:/Tetherbound-tools/godot/Godot_v4.7-stable_win64.exe' -ArgumentList @('--headless','--path','D:/tetherbound/visual-acceptance','--script','res://tests/run_tests.gd','--','--only=grass_field') -WindowStyle Hidden -RedirectStandardOutput "$logBase.log" -RedirectStandardError "$logBase.err" -PassThru
  $record.pid=$proc.Id
  $record | ConvertTo-Json | Set-Content -LiteralPath $lockPath
  if (-not $proc.WaitForExit(120000)) { $proc.Kill(); throw 'Tests exceeded two minutes' }
  $proc.Refresh()
  Write-Output "tests exit: $($proc.ExitCode)"
  if ($proc.ExitCode -ne 0) { throw 'Tests failed' }
} finally {
  $current=Get-Content -LiteralPath $lockPath -Raw | ConvertFrom-Json
  if ($current.shell_pid -eq $PID) { '{}' | Set-Content -LiteralPath $lockPath }
}
