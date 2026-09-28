param([string]$Region='cloudreach',[string]$Section='region',[string]$Tag='baseline',[switch]$DumpStock)
$ErrorActionPreference='Stop'
$lockPath='D:/tetherbound/RENDER_LOCK.json'
$old=Get-Content -LiteralPath $lockPath -Raw | ConvertFrom-Json
if ($old.held_by) { throw "Render lock held by $($old.held_by)" }
$env:APPDATA='D:/tetherbound/visual-acceptance-local/profile'
$runTag=$Tag
$tag=if ($Section -eq 'region') {$Region} else {$Section}
$logBase="D:/tetherbound/visual-acceptance-local/flower-patches-$runTag-$tag"
$record=@{held_by='combat';since_utc=[DateTime]::UtcNow.ToString('o');pid=0;shell_pid=$PID}
$record | ConvertTo-Json | Set-Content -LiteralPath $lockPath
try {
  $argsList=@('--path','D:/tetherbound/visual-acceptance','--rendering-method','gl_compatibility','--borderless','--position','0,0','--resolution','1920x1080','--fixed-fps','60','--script','D:/tetherbound/visual-acceptance-local/capture_flower_preserved.gd','--',"--section=$Section","--out=res://shots/flower-patches-$runTag")
  if ($DumpStock) { $argsList += "--dump-stock" }
  if ($Section -eq 'region') { $argsList += "--region=$Region" }
  $proc=Start-Process 'D:/Tetherbound-tools/godot/Godot_v4.7-stable_win64.exe' -ArgumentList $argsList -WindowStyle Hidden -RedirectStandardOutput "$logBase.log" -RedirectStandardError "$logBase.err" -PassThru
  $record.pid=$proc.Id
  $record | ConvertTo-Json | Set-Content -LiteralPath $lockPath
  if (-not $proc.WaitForExit(1200000)) { $proc.Kill(); throw 'Audit exceeded twenty-minute deadline' }
  $proc.Refresh()
  Write-Output "$tag exit: $($proc.ExitCode)"
  if (Select-String -LiteralPath "$logBase.err" -Pattern 'SCRIPT ERROR:|^ERROR:' -Quiet) { throw 'Audit emitted error diagnostics' }
  if ($proc.ExitCode -ne 0) { throw 'Audit failed; inspect logs' }
} finally {
  $current=Get-Content -LiteralPath $lockPath -Raw | ConvertFrom-Json
  if ($current.shell_pid -eq $PID) { '{}' | Set-Content -LiteralPath $lockPath }
}
