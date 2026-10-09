param(
  [Parameter(Mandatory=$true)][string]$Receipt,
  [Parameter(Mandatory=$true)][string]$PreparationRoot
)
$ErrorActionPreference='Stop'
$reportRoot=Split-Path -Parent $Receipt
$summary=Get-Content -LiteralPath $Receipt -Raw | ConvertFrom-Json
if(-not $summary.complete -or $summary.cases.Count -ne 24){throw 'Require all 24 completed measurements before finalizing'}
if(@($summary.cases | Group-Object biome,preset,repeat | Where-Object Count -ne 1).Count){throw 'Duplicate measurement keys'}
$summary.hardware | Add-Member -NotePropertyName operating_system -NotePropertyValue (Get-CimInstance Win32_OperatingSystem | Select-Object Caption,Version,BuildNumber,OSArchitecture) -Force
$summary | Add-Member -NotePropertyName current_main_at_quiet_start -NotePropertyValue '7dd4a777fbc11ce62c6747248b96d53e4a27a099' -Force
$summary | Add-Member -NotePropertyName gameplay_config_changes -NotePropertyValue @() -Force
$lines=[System.Collections.Generic.List[string]]::new()
$lines.Add('| Biome | Preset | Run | Mean fps | P95 ms | P99 ms | CPU render+setup ms | GPU ms | CPU process ms | Physics ms |')
$lines.Add('|---|---|---:|---:|---:|---:|---:|---:|---:|---:|')
foreach($case in $summary.cases){
  if(-not $case.complete){throw 'Incomplete case'}
  $raw=Get-Content -LiteralPath $case.raw_receipt -Raw | ConvertFrom-Json
  if($raw.failures.Count -gt 0){throw "Route failures: $($case.raw_receipt)"}
  $actualHash=(Get-FileHash -LiteralPath $case.raw_receipt).Hash.ToLowerInvariant()
  if($actualHash -ne $case.raw_sha256){throw 'Raw receipt hash changed'}
  $caseName="$($case.biome)-$($case.preset.ToLower())-r$($case.repeat)"
  $caseEvidence=Join-Path $reportRoot $caseName
  New-Item -ItemType Directory -Path $caseEvidence -Force | Out-Null
  Copy-Item -LiteralPath $case.raw_receipt -Destination (Join-Path $caseEvidence 'route.json')
  $case | Add-Member -NotePropertyName committed_raw_receipt -NotePropertyValue "ralph/reports/F26/quiet-baseline/$caseName/route.json" -Force
  $logEvidence=@()
  foreach($key in @('engine_log','stdout','stderr')){
    $sourcePath=$case.$key
    $targetName="$key.txt"
    Copy-Item -LiteralPath $sourcePath -Destination (Join-Path $caseEvidence $targetName)
    $contents=Get-Content -LiteralPath $sourcePath
    $errors=@($contents | Where-Object {$_ -match '^ERROR:'})
    $warnings=@($contents | Where-Object {$_ -match '^WARNING:'})
    $logEvidence+=@{path="ralph/reports/F26/quiet-baseline/$caseName/$targetName";sha256=(Get-FileHash -LiteralPath $sourcePath).Hash.ToLowerInvariant();error_count=$errors.Count;warning_count=$warnings.Count;error_examples=@($errors|Select-Object -First 5)}
  }
  $case | Add-Member -NotePropertyName committed_logs -NotePropertyValue $logEvidence -Force
  $cpuRenderer=if($null -ne $case.cpu_render -and $null -ne $case.cpu_render_setup){'{0:F2}' -f ($case.cpu_render.mean_ms+$case.cpu_render_setup.mean_ms)}else{'unavailable'}
  $gpu=if($null -ne $case.gpu_render){'{0:F2}' -f $case.gpu_render.mean_ms}else{'unavailable'}
  $biome=if($case.biome -eq 'water'){'Tidewake'}else{(Get-Culture).TextInfo.ToTitleCase($case.biome)}
  $lines.Add(('| {0} | {1} | {2} | {3:F2} | {4:F2} | {5:F2} | {6} | {7} | {8:F2} | {9:F2} |' -f $biome,$case.preset,$case.repeat,$case.mean_fps,$case.frame_ms.p95_ms,$case.frame_ms.p99_ms,$cpuRenderer,$gpu,$case.cpu_process.mean_ms,$case.cpu_physics.mean_ms))
}
foreach($name in @('measurement-source.patch','route-check.log','export.log','export-failure.json','export-rescoped.log')){
  $source=Join-Path $PreparationRoot $name
  if(Test-Path -LiteralPath $source){
    $targetName=if($name.EndsWith('.log')){$name.Replace('.log','-log.txt')}else{$name}
    Copy-Item -LiteralPath $source -Destination (Join-Path $reportRoot $targetName)
  }
}
$summary | Add-Member -NotePropertyName methodology -NotePropertyValue @{
  shipping_source='Published latest release source 7c7d25873cec69c1720b1964af9fd4b94151bee5; shipping executable verified, instrumented PCK exported in release mode. This is the permitted release-mode capture-tool fallback, not a byte-identical shipping PCK.'
  routes='Existing seed-2042 F26 routes, real physics traversal, fresh isolated user home per run. Fifteen seconds elapsed warmup; at least sixty seconds timed. Short routes hold their final pose for the remaining interval; Cloudreach and Stormwood time the longer full route.'
  resolution='1920x1080 fullscreen, VSync disabled, unlimited fps. Low uses Compatibility; Medium/High use Forward+ as the F26 harness specifies.'
  cpu_interpretation='CPU render+setup measures renderer CPU work only. Process and physics monitors are reported separately; they overlap and must not be added into a purported total CPU frame time. GPU root viewport timing excludes unrelated desktop GPU work.'
  repetitions='Two independent measurements per biome/preset. Table reports each run rather than averaging percentiles or hiding variation.'
  image_capture='Existing start/end route screenshots occur outside the timed interval; no screenshots are written during the measured traversal.'
  duration='Preparation encountered insufficient disk space twice (download/export); retained failure metadata and rescaled export resource scope. Fresh process/world/shader initialization precedes each timed interval and lengthens total wall time.'
} -Force
$summary | Add-Member -NotePropertyName finalized_utc -NotePropertyValue ([DateTime]::UtcNow.ToString('o')) -Force
$summary | ConvertTo-Json -Depth 40 | Set-Content -LiteralPath $Receipt -Encoding utf8
$table=$lines -join "`n"
$table | Set-Content -LiteralPath (Join-Path $reportRoot 'table.md') -Encoding utf8
$readme=@"
Quiet baseline, 2026-10-09

All 24 cases completed. This report uses the release-mode F26 capture-tool fallback on published latest source ``7c7d25873``. The executable matches the published Windows release; the PCK adds elapsed-time and viewport-timing instrumentation. The exact source/export delta is retained in measurement-source.patch. No gameplay/config default changed.

i5-8400, GTX 1060 3GB, 16 GiB RAM, Balanced power plan, 1920x1080 fullscreen at 60 Hz, VSync disabled, no fps cap. System CPU/GPU remained below 10% for a continuous minute before measurements. Process snapshot and utilization samples are in receipt.json.

Seed 2042, existing F26 routes, fresh isolated user home for every run, 15 seconds elapsed warmup, at least 60 seconds timed. Short Meadows/Tidewake routes hold their final pose to complete the timed interval; Cloudreach/Stormwood cover their longer full route. Low uses Compatibility and Medium/High use Forward+. Startup/world/shader time is outside the timed interval. Preparation and fresh startup made the overall quiet window longer than the 45-minute target.

FPS is 1000 divided by mean wall-frame milliseconds. P95/P99 are wall-frame percentiles. CPU render+setup is renderer work only; process and physics are separate overlapping monitors and cannot be summed into a total CPU frame time. GPU is the root viewport renderer time. Each repeat is shown separately.

$table

Raw samples and logs are committed per case, with hashes in receipt.json. Native shutdown/resource warnings and errors, if present, are retained and counted in the receipt; successful route completion does not assert clean engine teardown. Measurement timings alone do not establish a gameplay root cause. No visual verdict or whole-criterion READY is claimed by this baseline.
"@
$readme | Set-Content -LiteralPath (Join-Path $reportRoot 'README.md') -Encoding utf8
Write-Output $table
