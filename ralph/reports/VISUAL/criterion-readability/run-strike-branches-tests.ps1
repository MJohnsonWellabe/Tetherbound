$ErrorActionPreference='Stop'
$lockPath='D:/tetherbound/RENDER_LOCK.json'
$old=Get-Content -LiteralPath $lockPath -Raw | ConvertFrom-Json
if ($old.held_by) { throw "Render lock held by $($old.held_by)" }
$env:APPDATA='D:/tetherbound/visual-acceptance-local/profile'
$record=@{held_by='combat';since_utc=[DateTime]::UtcNow.ToString('o');pid=0;shell_pid=$PID}
$record | ConvertTo-Json | Set-Content -LiteralPath $lockPath
try {
  foreach ($spec in @(
    @{id='unit';script='tests/run_tests.gd';extra=@('--','--only=test_stormwood_surge.gd,test_stormwood_surge_presentation.gd,test_stormwood_lightning_spare.gd,test_stormwood_b_surge_phase_bolt_hold.gd')},
    @{id='cleanup';script='tests/smoke_stormwood_lightning_cleanup.gd';extra=@()},
    @{id='mechanics';script='tests/smoke_stormwood_lightning.gd';extra=@()}
  )) {
    $logBase="D:/tetherbound/visual-acceptance-local/storm-strike-branches-$($spec.id)"
    $argsList=@('--headless','--path','D:/tetherbound/visual-acceptance','--script',$spec.script)+$spec.extra
    $proc=Start-Process 'D:/Tetherbound-tools/godot/Godot_v4.7-stable_win64_console.exe' -ArgumentList $argsList -WindowStyle Hidden -RedirectStandardOutput "$logBase.log" -RedirectStandardError "$logBase.err" -PassThru
    $record.pid=$proc.Id
    $record | ConvertTo-Json | Set-Content -LiteralPath $lockPath
    if (-not $proc.WaitForExit(180000)) { $proc.Kill(); throw "$($spec.id) exceeded three-minute deadline" }
    $proc.Refresh()
    Write-Output "$($spec.id) exit: $($proc.ExitCode)"
    if ($proc.ExitCode -ne 0) { throw "$($spec.id) failed; inspect logs" }
  }
} finally {
  $current=Get-Content -LiteralPath $lockPath -Raw | ConvertFrom-Json
  if ($current.shell_pid -eq $PID) { '{}' | Set-Content -LiteralPath $lockPath }
}

