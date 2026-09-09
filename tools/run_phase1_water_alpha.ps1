param([string]$RunId = 'phase1-game73-water-0909-v1')
$ErrorActionPreference = 'Stop'
$workspace = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$artifact = [IO.Path]::GetFullPath((Join-Path $workspace ('.artifacts/' + $RunId)))
if (-not $artifact.StartsWith($workspace + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw 'Invalid artifact path' }
if (Test-Path -LiteralPath $artifact) { throw 'Preserve existing attempt' }
New-Item -ItemType Directory -Path $artifact | Out-Null
$godot = 'C:/Users/mattj/AppData/Local/Temp/godot47-ci-diagnose/Godot_v4.7-stable_win64_console.exe'
$marker = '(?:\s|")TB_NET_RUN_ID=' + [Regex]::Escape($RunId) + '(?:\s|"|$)'
$watch = [Diagnostics.Stopwatch]::StartNew()
$owned = @{}
$samples = @()
$finding = ''
$rootProcess = $null
$savedEnvironment = @{}
foreach ($key in @('APPDATA','XDG_DATA_HOME','TB_NET_RUN_ID','TB_NET_OUT_DIR')) { $savedEnvironment[$key] = [Environment]::GetEnvironmentVariable($key) }
$paths = @('autoload/game_state.gd','scripts/net/session.gd','scripts/net/realm_transition.gd',
 'scripts/net/realm_replication_scope.gd','scripts/net/realm_receiver_history.gd','scripts/net/realm_spawn_origins.gd',
 'scripts/net/trainer_spawn.gd','scripts/net/remote_trainer.gd','scripts/net/realm_shells.gd',
 'scripts/combat/encounter_director.gd','scripts/net/trainer_reward_delivery.gd',
 'tests/smoke_net_water_alpha.gd','tests/fixtures/water_alpha_peer.gd','tests/helpers/net_harness.gd','tools/net/peer_runner.gd')
$hashes = foreach ($path in $paths) { [PSCustomObject]@{path=$path; hash=(Get-FileHash -LiteralPath (Join-Path $workspace $path) -Algorithm SHA256).Hash} }
$hashes | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $artifact 'source-hashes-before.json')
function Sample-OwnedProcesses {
 $all = @(Get-CimInstance Win32_Process)
 $memory = Get-CimInstance Win32_PerfFormattedData_PerfOS_Memory
 foreach ($process in $all) {
  if ($process.Name -like 'Godot*' -and ($process.CommandLine -match $marker -or ($rootProcess -and $process.ProcessId -eq $rootProcess.Id))) {
   $processId = [int]$process.ProcessId
   if (-not $owned.ContainsKey($processId)) {
    $handle = Get-Process -Id $processId -ErrorAction SilentlyContinue
    if ($handle) { $owned[$processId] = [PSCustomObject]@{handle=$handle; parent=[int]$process.ParentProcessId; command=$process.CommandLine; peak_mb=0.0} }
   }
  }
 }
 foreach ($row in $owned.Values) {
  $row.handle.Refresh()
  if (-not $row.handle.HasExited) { $row.peak_mb = [Math]::Max($row.peak_mb, $row.handle.PeakWorkingSet64 / 1MB) }
 }
 [PSCustomObject]@{seconds=$watch.Elapsed.TotalSeconds; commit_percent=[double]$memory.PercentCommittedBytesInUse;
  committed_bytes=[double]$memory.CommittedBytes; commit_limit=[double]$memory.CommitLimit; process_count=$all.Count;
  allowed=([double]$memory.PercentCommittedBytesInUse -lt 90 -and $all.Count -lt 400)}
}
try {
 $initial = Sample-OwnedProcesses
 $samples += $initial
 if (-not $initial.allowed) { throw 'Resource guard before launch' }
 if (@(Get-CimInstance Win32_Process -Filter "Name LIKE '%Godot%'").Count -ne 0) { throw 'Exclusive world lease requires zero existing Godot processes' }
 $profile = Join-Path $artifact 'coordinator-profile'
 New-Item -ItemType Directory -Path $profile | Out-Null
 $env:APPDATA = $profile
 $env:XDG_DATA_HOME = $profile
 $env:TB_NET_RUN_ID = $RunId
 $env:TB_NET_OUT_DIR = Join-Path $artifact 'harness'
 $rootProcess = Start-Process -FilePath $godot -ArgumentList @('--headless','--path',$workspace,
  '--script','tests/smoke_net_water_alpha.gd','--',('TB_NET_RUN_ID=' + $RunId)) -WindowStyle Hidden `
  -RedirectStandardOutput (Join-Path $artifact 'coordinator.stdout.log') -RedirectStandardError (Join-Path $artifact 'coordinator.stderr.log') -PassThru
 foreach ($key in $savedEnvironment.Keys) { [Environment]::SetEnvironmentVariable($key,$savedEnvironment[$key]) }
 while ($watch.Elapsed.TotalSeconds -lt 600) {
  $sample = Sample-OwnedProcesses
  $samples += $sample
  if (-not $sample.allowed) { $finding = 'Resource guard: system commit >=90% or process count >=400'; break }
  $logs = @(Get-ChildItem -LiteralPath $artifact -Filter '*.log' -Recurse -File)
  foreach ($log in $logs) {
   $bad = Select-String -LiteralPath $log.FullName -Pattern '(^|\s)(ERROR:|SCRIPT ERROR:)|^FAIL:' | Select-Object -First 1
   if ($bad) { $finding = $log.FullName + ':' + $bad.LineNumber + ': ' + $bad.Line; break }
  }
  if ($finding) { break }
  $rootProcess.Refresh()
  if ($rootProcess.HasExited) { if ($rootProcess.ExitCode -ne 0) { $finding = 'Coordinator exit ' + $rootProcess.ExitCode }; break }
  Start-Sleep -Milliseconds 200
 }
 if (-not $finding -and $watch.Elapsed.TotalSeconds -ge 600) { $finding = 'External 600-second world ceiling' }
} catch { $finding = $_.Exception.Message }
finally {
 foreach ($key in $savedEnvironment.Keys) { [Environment]::SetEnvironmentVariable($key,$savedEnvironment[$key]) }
 if ($rootProcess) { $rootProcess.Refresh(); if (-not $rootProcess.HasExited) { $rootProcess.Kill($true) }; $rootProcess.WaitForExit() }
 foreach ($row in $owned.Values) { $row.handle.Refresh(); if (-not $row.handle.HasExited) { $row.handle.Kill($true) }; $row.handle.WaitForExit() }
}
$remaining = @(Get-CimInstance Win32_Process | Where-Object { $_.Name -like 'Godot*' -and $_.CommandLine -match $marker })
$results = foreach ($processId in $owned.Keys) { $row = $owned[$processId]; [PSCustomObject]@{pid=$processId; parent=$row.parent; command=$row.command; peak_mb=$row.peak_mb; exited=$row.handle.HasExited; exit_code=$row.handle.ExitCode} }
$after = foreach ($path in $paths) { [PSCustomObject]@{path=$path; hash=(Get-FileHash -LiteralPath (Join-Path $workspace $path) -Algorithm SHA256).Hash} }
$after | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $artifact 'source-hashes-after.json')
$receipt = [PSCustomObject]@{run_id=$RunId; elapsed_seconds=$watch.Elapsed.TotalSeconds; finding=$finding;
 coordinator_exit= $(if ($rootProcess) {$rootProcess.ExitCode} else {$null}); remaining_owned=$remaining.Count; processes=@($results); samples=$samples}
$receipt | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $artifact 'receipt.json')
[PSCustomObject]@{run_id=$RunId; elapsed_seconds=$receipt.elapsed_seconds; finding=$finding; coordinator_exit=$receipt.coordinator_exit; remaining_owned=$remaining.Count; artifact=$artifact} | ConvertTo-Json
if ($finding -or $remaining.Count) { exit 1 }
