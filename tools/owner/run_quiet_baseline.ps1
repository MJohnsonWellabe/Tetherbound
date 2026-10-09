param(
  [Parameter(Mandatory=$true)][string]$PackageRoot,
  [Parameter(Mandatory=$true)][string]$Output,
  [Parameter(Mandatory=$true)][string]$Receipt,
  [string]$SourceCommit='7c7d25873cec69c1720b1964af9fd4b94151bee5'
)
$ErrorActionPreference='Stop'
function Save-Receipt { $script:summary | ConvertTo-Json -Depth 40 | Set-Content -LiteralPath $Receipt -Encoding utf8 }
function Percentile([double[]]$Values,[double]$Fraction) {
  $ordered=@($Values | Sort-Object); $index=($ordered.Count-1)*$Fraction
  $lower=[int][Math]::Floor($index); $upper=[int][Math]::Ceiling($index)
  return $ordered[$lower]+($ordered[$upper]-$ordered[$lower])*($index-$lower)
}
function Stats($Rows,[string]$Key) {
  [double[]]$values=@($Rows | ForEach-Object { [double]$_.$Key })
  if($values.Count -eq 0){return $null}
  return @{mean_ms=($values|Measure-Object -Average).Average;p95_ms=(Percentile $values .95);p99_ms=(Percentile $values .99);sample_count=$values.Count}
}
if(Test-Path -LiteralPath $Output){throw 'Choose a fresh measurement output directory'}
New-Item -ItemType Directory -Path $Output -Force | Out-Null
New-Item -ItemType Directory -Path (Split-Path $Receipt) -Force | Out-Null
$system=Get-CimInstance Win32_ComputerSystem
$summary=[ordered]@{
  schema_version=1;complete=$false;started_utc=[DateTime]::UtcNow.ToString('o');source_commit=$SourceCommit
  build_mode='release export of existing F26 route tool plus explicit quiet timing/monitor instrumentation'
  scoped_source_changes=@('tools/capture_lookdev_route.gd: --quiet-baseline adds elapsed-time limits and render monitors','export_presets.cfg: measurement export omits local ralph/ and shots/ proof resources; production presets unchanged')
  published_release_zip_sha256='55091796270befbea3a19dd55b015351db54b038c3d53c4d2961268603a47262'
  published_executable_sha256='a3e6b1cbd46ad153e7dfb24a5c0ee2b9187e0fb21fa7c0610fa8754ba5939d9c'
  published_pck_sha256='09334cb4de0cc7b673b50c41c2e89088a029b3d8fd71d6ce5c799aa7dafb1e36'
  measured_package=@(Get-FileHash -LiteralPath (Join-Path $PackageRoot 'Tetherbound.exe'),(Join-Path $PackageRoot 'Tetherbound.pck') | Select-Object Path,Hash)
  hardware=@{cpu=@(Get-CimInstance Win32_Processor|Select-Object Name,NumberOfCores,NumberOfLogicalProcessors);ram_bytes=$system.TotalPhysicalMemory;gpu=@(Get-CimInstance Win32_VideoController|Select-Object Name,DriverVersion,CurrentHorizontalResolution,CurrentVerticalResolution,CurrentRefreshRate);power_plan=(& powercfg /getactivescheme|Out-String).Trim()}
  process_snapshot=@(Get-CimInstance Win32_Process|Select-Object ProcessId,ParentProcessId,Name,ExecutablePath)
  quiet_note='Codex and its idle Node tool transports remain; no Node/Python/image/build workload is launched. Actual system CPU and GPU utilization are checked for one minute.'
  idle_samples=@();cases=@();failures=@();requirements=@{resolution=@(1920,1080);warmup_seconds=15;minimum_timed_seconds=60;repetitions=2;vsync='disabled';fps_cap=0}
  timing_definitions=@{fps='1000 / arithmetic mean wall-frame ms';percentiles='P95/P99 wall-frame ms, linearly interpolated';cpu='CPU process, physics, viewport render and render setup are separate monitors, not a non-overlapping total';gpu='Root viewport GPU render time; all-zero output means unavailable, never a measured zero cost'}
}
Save-Receipt
if(Get-Process -Name 'Godot*','Tetherbound' -ErrorAction SilentlyContinue){throw 'Quiet baseline refuses another active engine'}
$idleStart=[DateTime]::UtcNow
$quietWindowStart=$null
do {
  $cpu=[double](Get-CimInstance Win32_PerfFormattedData_PerfOS_Processor|Where-Object Name -eq '_Total').PercentProcessorTime
  $gpu=[double](Get-CimInstance Win32_PerfFormattedData_GPUPerformanceCounters_GPUEngine|Measure-Object UtilizationPercentage -Maximum).Maximum
  $summary.idle_samples+=@{utc=[DateTime]::UtcNow.ToString('o');cpu_percent=$cpu;maximum_gpu_engine_percent=$gpu}
  Save-Receipt
  if($cpu -ge 10 -or $gpu -ge 10){$quietWindowStart=$null}
  elseif($null -eq $quietWindowStart){$quietWindowStart=[DateTime]::UtcNow}
  if($null -ne $quietWindowStart -and ([DateTime]::UtcNow-$quietWindowStart).TotalSeconds -ge 60){break}
  if(([DateTime]::UtcNow-$idleStart).TotalSeconds -ge 180){throw 'CPU/GPU could not stay below 10% for one minute; no native measurements started'}
  Start-Sleep -Seconds 5
}while($true)
$summary.idle_elapsed_seconds=([DateTime]::UtcNow-$idleStart).TotalSeconds
$summary.continuous_quiet_seconds=([DateTime]::UtcNow-$quietWindowStart).TotalSeconds
Save-Receipt
$savedAppData=$env:APPDATA
try {
  foreach($biome in @('meadows','water','cloudreach','stormwood')){
    foreach($preset in @('Low','Medium','High')){
      foreach($repeat in @(1,2)){
        $name="$biome-$($preset.ToLower())-r$repeat"
        $caseRoot=Join-Path $Output $name
        $homeRoot=Join-Path $Output "$name-home"
        New-Item -ItemType Directory -Path $homeRoot -Force|Out-Null
        $env:APPDATA=$homeRoot
        $renderer=if($preset -eq 'Low'){'gl_compatibility'}else{'forward_plus'}
        $engineLog=Join-Path $Output "$name.engine.log"
        $stdout=Join-Path $Output "$name.stdout.log"; $stderr=Join-Path $Output "$name.stderr.log"
        $arguments="--rendering-method $renderer --fullscreen --resolution 1920x1080 --disable-vsync --max-fps 0 --log-file `"$engineLog`" -- --f26-route --quiet-baseline --biome=$biome --preset=$preset --source-commit=$SourceCommit --output=$($caseRoot.Replace('\','/'))"
        $process=Start-Process -FilePath (Join-Path $PackageRoot 'Tetherbound.exe') -ArgumentList $arguments -WorkingDirectory $PackageRoot -WindowStyle Normal -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr
        $case=[ordered]@{biome=$biome;preset=$preset;repeat=$repeat;complete=$false;pid=$process.Id;arguments=$arguments;started_utc=[DateTime]::UtcNow.ToString('o');raw_receipt=(Join-Path $caseRoot 'route.json');engine_log=$engineLog;stdout=$stdout;stderr=$stderr}
        $summary.cases+=$case;Save-Receipt
        Write-Output "START $name pid=$($process.Id)"
        $deadline=[DateTime]::UtcNow.AddMinutes(20)
        while(-not $process.HasExited -and [DateTime]::UtcNow -lt $deadline){Start-Sleep -Seconds 2;$process.Refresh()}
        if(-not $process.HasExited){& taskkill /PID $process.Id /T /F|Out-Null;$process.WaitForExit();$case.watchdog_timeout=$true}
        $case.exit_code=$process.ExitCode;$case.finished_utc=[DateTime]::UtcNow.ToString('o')
        $nativeErrors=@(Select-String -LiteralPath $engineLog -Pattern '^ERROR:' | ForEach-Object Line)
        $case.native_error_count=$nativeErrors.Count
        $case.native_error_examples=@($nativeErrors | Select-Object -First 5)
        if($nativeErrors.Count -gt 0){
          $case.measurement_quality='qualified: engine errors require release-content audit before complete-biome certification'
          Write-Output "QUALIFIED $name native_errors=$($nativeErrors.Count)"
        }
        if(Test-Path -LiteralPath $case.raw_receipt){
          $raw=Get-Content -LiteralPath $case.raw_receipt -Raw|ConvertFrom-Json
          $case.frame_ms=Stats $raw.samples 'wall_ms';$case.cpu_process=Stats $raw.samples 'process_ms';$case.cpu_physics=Stats $raw.samples 'physics_ms';$case.cpu_render=Stats $raw.samples 'render_cpu_ms';$case.cpu_render_setup=Stats $raw.samples 'render_setup_cpu_ms';$case.gpu_render=Stats $raw.samples 'render_gpu_ms'
          if($case.gpu_render -and $case.gpu_render.mean_ms -le 0){$case.gpu_render=$null;$case.gpu_monitor_status='unavailable/all zero'}
          if($case.cpu_render -and $case.cpu_render.mean_ms -le 0){$case.cpu_render=$null;$case.cpu_render_monitor_status='unavailable/all zero'}
          if($case.cpu_render_setup -and $case.cpu_render_setup.mean_ms -le 0){$case.cpu_render_setup=$null}
          if($case.frame_ms){$case.mean_fps=1000/$case.frame_ms.mean_ms}
          $case.elapsed_ms=$raw.elapsed_ms;$case.warmup_elapsed_ms=$raw.warmup_elapsed_ms;$case.route_failures=$raw.failures;$case.waypoints_reached=$raw.waypoints_reached
          $case.complete=($process.ExitCode -eq 0 -and $raw.complete -eq $true -and $raw.quiet_baseline -eq $true -and $raw.is_debug_build -eq $false -and $raw.elapsed_ms -ge 60000 -and $raw.warmup_elapsed_ms -ge 15000 -and $raw.vsync_mode -eq 0 -and $raw.max_fps -eq 0 -and $raw.source_commit -eq $SourceCommit -and $raw.resolution[0] -eq 1920 -and $raw.resolution[1] -eq 1080)
          $case.raw_sha256=(Get-FileHash -LiteralPath $case.raw_receipt).Hash.ToLowerInvariant()
        }
        Save-Receipt
        Write-Output "END $name complete=$($case.complete) fps=$($case.mean_fps)"
        if(-not $case.complete){
          $summary.failures+="$name incomplete; preserve evidence and fix/re-scope before repeating"
          Save-Receipt
          if($summary.failures.Count -ge 2){throw 'Two unsuccessful native measurements: fix/re-scope or BLOCKED before further runs'}
          break
        }
      }
    }
  }
  $summary.complete=($summary.cases.Count -eq 24 -and @($summary.cases|Where-Object {-not $_.complete}).Count -eq 0)
}finally{
  $env:APPDATA=$savedAppData
  $summary.finished_utc=[DateTime]::UtcNow.ToString('o');Save-Receipt
}
