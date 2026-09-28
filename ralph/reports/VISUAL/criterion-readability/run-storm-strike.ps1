param([string]$Tag='baseline1080',[string]$Subjects='', [switch]$Timed)
$ErrorActionPreference='Stop'
$lockPath='D:/tetherbound/RENDER_LOCK.json'
$old=Get-Content -LiteralPath $lockPath -Raw | ConvertFrom-Json
if ($old.held_by) { throw "Render lock held by $($old.held_by)" }
$env:APPDATA='D:/tetherbound/visual-acceptance-local/profile'
$logBase="D:/tetherbound/visual-acceptance-local/storm-strike-$Tag"
$record=@{held_by='combat';since_utc=[DateTime]::UtcNow.ToString('o');pid=0;shell_pid=$PID}
$record | ConvertTo-Json | Set-Content -LiteralPath $lockPath
try {
  $argsList=@('--path','D:/tetherbound/visual-acceptance','--rendering-method','gl_compatibility','--borderless','--position','0,0','--resolution','1920x1080','--fixed-fps','60','--script','tools/capture_stormwood_strike_visual.gd','--',"--out=res://shots/storm-strike-$Tag")
  if ($Timed) { $argsList += '--timed' }; if ($Subjects) { $argsList += "--only=$Subjects" }
  $proc=Start-Process 'D:/Tetherbound-tools/godot/Godot_v4.7-stable_win64.exe' -ArgumentList $argsList -WindowStyle Hidden -RedirectStandardOutput "$logBase.log" -RedirectStandardError "$logBase.err" -PassThru
  $record.pid=$proc.Id
  $record | ConvertTo-Json | Set-Content -LiteralPath $lockPath
  if (-not $proc.WaitForExit(600000)) { $proc.Kill(); throw 'Stage exceeded ten-minute deadline' }
  $proc.Refresh()
  Write-Output "$Tag exit: $($proc.ExitCode)"
  if ($proc.ExitCode -ne 0) { throw 'Stage failed; inspect logs' }
} finally {
  $current=Get-Content -LiteralPath $lockPath -Raw | ConvertFrom-Json
  if ($current.shell_pid -eq $PID) { '{}' | Set-Content -LiteralPath $lockPath }
}




