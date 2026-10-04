# Runs the packaged F26 routes, without installing tools or using a source checkout.
# Windows PowerShell 5.1. Raw receipts and native logs are retained on every failure.
param(
  [string]$PackageRoot = $PSScriptRoot,
  [string]$Output = "",
  [string]$HardwareVariant = "",
  [int]$PowerWatts = 0,
  [switch]$DesktopPreflight,
  [switch]$VerifyOnly
)
$ErrorActionPreference = "Stop"
Import-Module (Join-Path $PSHOME "Modules/Microsoft.PowerShell.Utility/Microsoft.PowerShell.Utility.psd1")

function Write-Json($Value, [string]$Path) {
  $Value | ConvertTo-Json -Depth 32 | Set-Content -LiteralPath $Path -Encoding UTF8
}

function Get-Percentile([double[]]$Values, [double]$Fraction) {
  $ordered = @($Values | Sort-Object)
  $index = ($ordered.Count - 1) * $Fraction
  $lower = [int][Math]::Floor($index)
  $upper = [Math]::Min($lower + 1, $ordered.Count - 1)
  return $ordered[$lower] + ($ordered[$upper] - $ordered[$lower]) * ($index - $lower)
}

function Read-RouteResult($Receipt, $Manifest, [string]$Biome) {
  if ($Receipt.complete -ne $true -or $Receipt.source_commit -cne $Manifest.source_commit -or
      $Receipt.route_config_sha256 -cne $Manifest.route_config_sha256 -or
      $Receipt.biome -cne $Biome -or $Receipt.preset -cne "Medium" -or
      $Receipt.renderer -cne "forward_plus" -or $Receipt.display -cne "Windows" -or
      [string]::IsNullOrWhiteSpace($Receipt.adapter) -or $Receipt.resolution.Count -ne 2 -or
      $Receipt.resolution[0] -ne 1920 -or $Receipt.resolution[1] -ne 1080 -or
      @($Receipt.failures).Count -ne 0 -or
      $Receipt.frame_limit.max_fps -ne 0 -or $Receipt.frame_limit.vsync_mode -ne 0 -or
      $Receipt.frame_limit.fixed_fps_requested -ne $false -or $Receipt.frame_limit.render_loop_enabled -ne $true -or
      $Receipt.frame_limit.physics_ticks_per_second -ne 60 -or $Receipt.frame_limit.time_scale -ne 1 -or
      $Manifest.vista_far_floors_m.$Biome -le 0 -or
      $Receipt.camera.far -lt $Manifest.vista_far_floors_m.$Biome -or
      $Receipt.waypoints_reached -ne $Manifest.routes.$Biome.waypoint_count -or
      @($Receipt.samples).Count -lt $Manifest.minimum_timed_frames) {
    throw "$Biome receipt is incomplete or differs from the packaged source, route or Medium profile."
  }
  [double[]]$samples = @($Receipt.samples | ForEach-Object { [double]$_.wall_ms })
  foreach ($sample in $samples) {
    if ([double]::IsNaN($sample) -or [double]::IsInfinity($sample) -or $sample -le 0) {
      throw "$Biome contains invalid frame timing."
    }
  }
  $mean = ($samples | Measure-Object -Average).Average
  $p95 = Get-Percentile $samples .95
  $slowestCount = [Math]::Max(1, [Math]::Ceiling($samples.Count * .01))
  $slowestMean = ($samples | Sort-Object -Descending | Select-Object -First $slowestCount | Measure-Object -Average).Average
  return [ordered]@{
    biome = $Biome; route_complete = $true; timed_frames = $samples.Count
    mean_ms = $mean; p50_ms = (Get-Percentile $samples .5); p95_ms = $p95
    p99_ms = (Get-Percentile $samples .99); maximum_ms = ($samples | Measure-Object -Maximum).Maximum
    average_fps = 1000 / $mean; minimum_fps = 1000 / ($samples | Measure-Object -Maximum).Maximum
    one_percent_low_fps = 1000 / $slowestMean
    hitches_over_100ms = @($samples | Where-Object { $_ -gt 100 }).Count
    camera_far_m = $Receipt.camera.far; required_vista_far_floor_m = $Manifest.vista_far_floors_m.$Biome
    meets_30fps_timing_target = ($mean -le (1000 / 30) -and $p95 -le (1000 / 30))
    meets_preferred_40fps_timing_target = ($mean -le 25 -and $p95 -le 25)
    adapter = $Receipt.adapter; renderer = $Receipt.renderer; receipt = "$Biome/route.json"
  }
}

$mutex = $null
$held = $false
$savedEnvironment = @{}
$summary = $null
$process = $null
try {
  $PackageRoot = (Resolve-Path -LiteralPath $PackageRoot).Path
  $manifest = Get-Content -LiteralPath (Join-Path $PackageRoot "F26_PACKAGE.json") -Raw | ConvertFrom-Json
  if ($manifest.source_commit -cnotmatch '^[0-9a-f]{40}$' -or
      $manifest.route_config_sha256 -cnotmatch '^[0-9a-f]{64}$' -or
      $manifest.minimum_timed_frames -lt 120 -or @($manifest.files).Count -lt 4) {
    throw "Invalid F26 package manifest."
  }
  foreach ($file in $manifest.files) {
    $path = [IO.Path]::GetFullPath((Join-Path $PackageRoot $file.path))
    $packagePrefix = $PackageRoot.TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
    if (-not $path.StartsWith($packagePrefix, [StringComparison]::OrdinalIgnoreCase) -or
        -not (Test-Path -LiteralPath $path -PathType Leaf) -or
        (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant() -cne $file.sha256) {
      throw "Package integrity failed: $($file.path). Re-extract the complete zip."
    }
  }
  foreach ($required in @("Tetherbound.exe", "Tetherbound.pck", "F26_ALLY.cmd", "f26_ally.ps1")) {
    if (@($manifest.files | Where-Object { $_.path -ceq $required }).Count -ne 1) {
      throw "Package manifest must identify $required exactly once."
    }
  }
  if ($VerifyOnly) { Write-Host "Package hashes verified: $($manifest.source_commit)"; exit 0 }
  if ($DesktopPreflight) {
    if ($PowerWatts -ne 0 -or $HardwareVariant) { throw "Desktop preflight cannot declare Ally hardware or power." }
  } else {
    if (-not $HardwareVariant) { $HardwareVariant = Read-Host "Exact ROG Ally variant (Z1, Z1 Extreme, Ally X, etc.)" }
    if (-not $PowerWatts) { $PowerWatts = [int](Read-Host "Set Armoury Crate to 15 W, then enter the selected watts") }
    if ([string]::IsNullOrWhiteSpace($HardwareVariant) -or $PowerWatts -ne 15) {
      throw "The owner F26 run requires an identified Ally variant at 15 W."
    }
  }
  if (Get-Process -Name valheim,Tetherbound -ErrorAction SilentlyContinue) {
    throw "Close Valheim and any other Tetherbound window before measuring."
  }
  $mutex = New-Object Threading.Mutex($false, "Local\TetherboundF26Capture")
  try { $held = $mutex.WaitOne(0) } catch [Threading.AbandonedMutexException] { $held = $true }
  if (-not $held) { throw "Another packaged F26 run is already active." }
  if (-not $Output) {
    $Output = Join-Path $env:LOCALAPPDATA ("Tetherbound\f26-runs\" + (Get-Date).ToUniversalTime().ToString("yyyyMMddTHHmmssZ"))
  }
  $Output = [IO.Path]::GetFullPath($Output)
  if (Test-Path -LiteralPath $Output) { throw "Evidence directory already exists; choose a fresh Output." }
  New-Item -ItemType Directory -Path $Output -Force | Out-Null
  $homePath = Join-Path $Output "device-home"
  New-Item -ItemType Directory -Path $homePath | Out-Null
  foreach ($key in @("APPDATA", "XDG_DATA_HOME", "XDG_CONFIG_HOME")) {
    $savedEnvironment[$key] = [Environment]::GetEnvironmentVariable($key, "Process")
    [Environment]::SetEnvironmentVariable($key, $homePath, "Process")
  }
  $system = Get-CimInstance Win32_ComputerSystem
  $os = Get-CimInstance Win32_OperatingSystem
  $summary = [ordered]@{
    result = "INCOMPLETE"; source_commit = $manifest.source_commit
    package_manifest_sha256 = (Get-FileHash -LiteralPath (Join-Path $PackageRoot "F26_PACKAGE.json")).Hash.ToLowerInvariant()
    started_utc = (Get-Date).ToUniversalTime().ToString("o"); cases = @()
    evidence_kind = if ($DesktopPreflight) { "DESKTOP_PREFLIGHT" } else { "OWNER_ALLY_MEASUREMENT" }
    device = @{ owner_declared_variant = if ($DesktopPreflight) { $null } else { $HardwareVariant }
      owner_declared_power_watts = if ($DesktopPreflight) { $null } else { $PowerWatts }
      manufacturer = $system.Manufacturer; model = $system.Model; os = $os.Caption; os_version = $os.Version
      graphics = @(Get-CimInstance Win32_VideoController | Select-Object Name,DriverVersion) }
    scope = "Four exported Medium native 1080p scripted render routes. Manual device/power verification required; no release endurance, earned campaign, combat or invitation co-op claim."
    fps_definition = "Minimum=1000/max wall_ms; average=1000/mean wall_ms; 1% low=1000/mean slowest ceiling(1% of frames) wall_ms."
  }
  if ($DesktopPreflight) { $summary.scope += " Desktop hardware only; no Ally hardware, 15 W or owner acceptance claim." }
  Write-Json $summary (Join-Path $Output "ALLY_RESULT.json")
  foreach ($biome in @("meadows", "water", "cloudreach", "stormwood")) {
    Write-Host "Running $biome / Medium. Keep the game window visible; do not run another game."
    $casePath = Join-Path $Output $biome
    $stdout = Join-Path $Output ($biome + ".stdout.log")
    $stderr = Join-Path $Output ($biome + ".stderr.log")
    $engineLog = Join-Path $Output ($biome + ".engine.log")
    # Start-Process needs an explicitly quoted argument string on Windows, even
    # when ArgumentList is an array. These paths are parameters, never shell code.
    if ($casePath.Contains('"')) { throw "Output cannot contain a quote." }
    $argumentText = '--rendering-method forward_plus --resolution 1920x1080 --log-file "' + $engineLog + '" -- --f26-route --biome=' +
      $biome + ' --preset=Medium --source-commit=' + $manifest.source_commit + ' "--output=' + $casePath.Replace([char]92,[char]47) + '"'
    # The release preset exports the GUI executable without a console wrapper.
    # The owner watches this interactive measurement window; engine logs are
    # explicit and do not depend on the Windows console subsystem.
    $process = Start-Process -FilePath (Join-Path $PackageRoot "Tetherbound.exe") -ArgumentList $argumentText -WorkingDirectory $PackageRoot -WindowStyle Normal -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr
    if (-not $process.WaitForExit(1800000)) {
      # End only this owned wrapper's process tree. Preserve the partial evidence.
      & taskkill.exe /PID $process.Id /T /F | Out-Null
      throw "$biome exceeded its 30-minute startup/route deadline."
    }
    $process.Refresh()
    $nativeLog = (Get-Content -LiteralPath $stdout -Raw) + (Get-Content -LiteralPath $stderr -Raw) + (Get-Content -LiteralPath $engineLog -Raw)
    if ($process.ExitCode -ne 0 -or $nativeLog -match 'SCRIPT ERROR:|ERROR:') {
      throw "$biome native process failed; inspect its retained logs."
    }
    $receipt = Get-Content -LiteralPath (Join-Path $casePath "route.json") -Raw | ConvertFrom-Json
    $result = Read-RouteResult $receipt $manifest $biome
    $result.raw_files = @()
    foreach ($rawPath in @($stdout, $stderr, $engineLog, (Join-Path $casePath "route.json"), (Join-Path $casePath "start.png"), (Join-Path $casePath "end.png"))) {
      if (-not (Test-Path -LiteralPath $rawPath -PathType Leaf)) { throw "Missing raw evidence: $rawPath" }
      $result.raw_files += @{ path = $rawPath.Substring($Output.Length + 1).Replace([char]92,[char]47); sha256 = (Get-FileHash -LiteralPath $rawPath -Algorithm SHA256).Hash.ToLowerInvariant() }
    }
    $summary.cases += $result
    Write-Json $summary (Join-Path $Output "ALLY_RESULT.json")
  }
  $belowTarget = @($summary.cases | Where-Object { -not $_.meets_30fps_timing_target }).Count -gt 0
  $summary.result = if ($DesktopPreflight) { "DESKTOP_PREFLIGHT_COMPLETE" } elseif ($belowTarget) { "BELOW_TARGET" } else { "OWNER_REVIEW_REQUIRED" }
  $summary.below_30fps_timing_target = $belowTarget
  $summary.finished_utc = (Get-Date).ToUniversalTime().ToString("o")
  Write-Json $summary (Join-Path $Output "ALLY_RESULT.json")
  Write-Host "Finished: $($summary.result). Evidence: $Output"
  Write-Host "Send the complete result folder to the coordinator. Confirm device/power and report visible faults."
  if ($belowTarget -and -not $DesktopPreflight) { exit 1 }
} catch {
  if ($null -ne $summary) {
    $summary.result = "INCOMPLETE"
    $summary.failure = $_.Exception.Message
    Write-Json $summary (Join-Path $Output "ALLY_RESULT.json")
  }
  Write-Host ("F26 stopped: " + $_.Exception.Message) -ForegroundColor Red
  exit 1
} finally {
  if ($null -ne $process -and -not $process.HasExited) { & taskkill.exe /PID $process.Id /T /F | Out-Null }
  foreach ($key in $savedEnvironment.Keys) { [Environment]::SetEnvironmentVariable($key, $savedEnvironment[$key], "Process") }
  if ($held) { $mutex.ReleaseMutex() }
  if ($null -ne $mutex) { $mutex.Dispose() }
}
