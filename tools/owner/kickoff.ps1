# Tetherbound evidence run. Launched by KICKOFF.cmd; see docs/acceptance/KICKOFF_RUN.md.
#
# The only human action in the whole evidence process is starting this file.
# Everything it does either succeeds and is recorded, or fails and is recorded;
# it never stops to ask. A phase that fails does not stop the phases after it.
#
# Phases (each skippable with -Only, each resumable with -Resume <stamp>):
#   prepare  repo + pinned Godot + ffmpeg + import + machine record
#   frames   the fixed stands, the Band 1 composition stands, the route strip
#            (day and night) on a real GPU, sheeted for the blind judge
#   perf     draw calls/primitives and a REAL frame rate at eye-level sites
#   export   download the shipped Windows zip, run it, verify-export checks
#   chain    Gate F S01 -> S10e with video, then the capture lanes
#   package  RUN_SUMMARY.md, zip, commit to owner-run/<stamp>, push
#
# -Quick runs everything except the chain (about half an hour on a desktop
# GPU). The chain is an overnight run: leave the machine alone until the
# window says it is finished.
#
# Windows PowerShell 5.1 is enough; nothing here needs PowerShell 7.

param(
  [string]$Branch = "",
  [string]$Only = "",
  [switch]$Quick,
  [string]$Resume = "",
  [int]$SegmentTimeoutMinutes = 360,
  [switch]$FullPayload,
  [string]$Res = "1280x800",
  [int]$RouteStepMetres = 40
)

$ErrorActionPreference = "Continue"
$ProgressPreference = "SilentlyContinue"
# An unattended run must never stop at a credential prompt. Without these a git
# call on a machine that has never authenticated blocks on the Credential
# Manager dialog forever, and an overnight chain dies holding a modal nobody is
# there to answer. Failing fast is what lets Test-PushAccess report a verdict.
$env:GIT_TERMINAL_PROMPT = "0"
$env:GCM_INTERACTIVE = "never"
try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}

$GodotVersion = "4.7-stable"
$RepoUrl = "https://github.com/MJohnsonWellabe/Tetherbound"
$FfmpegUrl = "https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip"
$State = Join-Path $env:LOCALAPPDATA "Tetherbound"
$ToolsDir = Join-Path $State "tools"
if ($Resume) { $Stamp = $Resume } else { $Stamp = (Get-Date).ToUniversalTime().ToString("yyyyMMddTHHmmssZ") }
$RunLocal = Join-Path $State "runs\$Stamp"
New-Item -ItemType Directory -Force -Path $ToolsDir, $RunLocal | Out-Null
$LogPath = Join-Path $RunLocal "kickoff.log"
$PhasesPath = Join-Path $RunLocal "PHASES.json"

$Journey = @("S01","S02","S03","S04","S05","S06","S07","S08","S09","S10a","S10b","S10c","S10d","S10e")
$CaptureLanes = @("S01C","S02C","S03C","S04C","S05C","S06C","S07C","S08C","S09C","S10aC","S10bC","S10cC")

$script:Godot = $null
$script:Ffmpeg = $null
$script:Repo = $null
$script:Evidence = $null
$script:GateRun = $null
$script:Sha = "unknown"
$script:CanPush = $false
# Every segment the chain ran, and how it ended. Phase-Chain reads this to
# decide its own status: without it a chain whose segments ALL failed still
# reported "ok", because Run-Phase only fails on a thrown exception. The
# 2026-09-07 run shipped a RUN_SUMMARY.md saying `chain | ok` over a CHAIN_LOG
# in which 12 of 14 journey segments exited 1.
$script:SegmentResults = @()
$script:PushProbe = "not checked"
$script:Phases = @{}
if (Test-Path $PhasesPath) {
  try { $loaded = Get-Content $PhasesPath -Raw | ConvertFrom-Json; foreach ($p in $loaded.PSObject.Properties) { $script:Phases[$p.Name] = $p.Value } } catch {}
}

function Log([string]$msg) {
  $line = "[{0}] {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $msg
  Write-Host $line
  Add-Content -Path $LogPath -Value $line
}

function Save-Phases {
  $obj = New-Object PSObject
  foreach ($k in $script:Phases.Keys) { $obj | Add-Member -NotePropertyName $k -NotePropertyValue $script:Phases[$k] }
  $obj | ConvertTo-Json -Depth 5 | Out-File -FilePath $PhasesPath -Encoding utf8
}

function Run-Phase([string]$Name, [scriptblock]$Body, [bool]$Slow = $false) {
  if ($Only -and (($Only -split ",") -notcontains $Name)) { Log "phase ${Name}: skipped (-Only $Only)"; return }
  if ($Quick -and $Slow) { Log "phase ${Name}: skipped (-Quick)"; return }
  # `prepare` is NEVER skipped, even on -Resume. It is the phase that sets
  # $script:Repo, $script:Godot, $script:Evidence and $script:GateRun; skipping
  # it left them null and the run died two lines into the main body with
  # "prepare did not produce a repo and a Godot", which made -Resume -- the
  # documented way to continue an interrupted run -- fail on every use. It is
  # idempotent (a fetch, two tool checks, an import) and costs a minute.
  if ($script:Phases.ContainsKey($Name) -and $script:Phases[$Name].status -eq "ok" -and $Resume -and $Name -ne "prepare") { Log "phase ${Name}: already ok in $Resume, skipped"; return }
  Log "=== phase $Name ==="
  $t0 = Get-Date
  $status = "ok"; $err = ""
  try { & $Body } catch { $status = "failed"; $err = "$($_.Exception.Message)"; Log "phase $Name FAILED: $err" }
  $script:Phases[$Name] = @{ status = $status; error = $err; started = $t0.ToString("o"); seconds = [int]((Get-Date) - $t0).TotalSeconds }
  Save-Phases
  Log "=== phase ${Name}: $status ($([int]((Get-Date) - $t0).TotalSeconds) s) ==="
}

function Quote-Arg([string]$a) { if ($a -match '[\s"]') { return '"' + ($a -replace '"', '\"') + '"' } else { return $a } }

# Run a process with a wall-clock timeout, capturing all output to a file.
# Returns the exit code; 124 means it was killed on the timeout.
function Invoke-Proc([string]$Exe, [string[]]$Arguments, [string]$LogFile, [int]$TimeoutSec, [string]$WorkDir) {
  $psi = New-Object System.Diagnostics.ProcessStartInfo
  $psi.FileName = $Exe
  $psi.WorkingDirectory = $WorkDir
  $psi.Arguments = (($Arguments | ForEach-Object { Quote-Arg $_ }) -join " ")
  $psi.UseShellExecute = $false
  $psi.RedirectStandardOutput = $true
  $psi.RedirectStandardError = $true
  $psi.CreateNoWindow = $false
  Log "run: $Exe $($psi.Arguments)"
  $p = [System.Diagnostics.Process]::Start($psi)
  $outTask = $p.StandardOutput.ReadToEndAsync()
  $errTask = $p.StandardError.ReadToEndAsync()
  $code = 0
  if (-not $p.WaitForExit($TimeoutSec * 1000)) {
    try { $p.Kill() } catch {}
    $p.WaitForExit()
    Log "TIMEOUT after $TimeoutSec s"
    $code = 124
  } else {
    $p.WaitForExit()
    $code = $p.ExitCode
  }
  $text = $outTask.Result + "`r`n--- stderr ---`r`n" + $errTask.Result
  $text | Out-File -FilePath $LogFile -Encoding utf8
  Log "exit $code -> $LogFile"
  return $code
}

# Godot with a window and a real driver. NEVER add --headless here: --headless
# together with --rendering-driver hangs forever (docs/AGENT_WORKFLOW.md).
function Invoke-GodotRender([string[]]$ScriptAndArgs, [string]$LogFile, [int]$TimeoutSec, [string[]]$EngineFlags = @()) {
  $cmd = @("--path", $script:Repo, "--rendering-driver", "opengl3", "--resolution", $Res) + $EngineFlags + $ScriptAndArgs
  return Invoke-Proc $script:Godot $cmd $LogFile $TimeoutSec $script:Repo
}

function Invoke-GodotHeadless([string[]]$ScriptAndArgs, [string]$LogFile, [int]$TimeoutSec) {
  $cmd = @("--headless", "--path", $script:Repo) + $ScriptAndArgs
  return Invoke-Proc $script:Godot $cmd $LogFile $TimeoutSec $script:Repo
}

function Download([string]$Url, [string]$Dest) {
  Log "download $Url"
  $resp = Invoke-WebRequest -Uri $Url -OutFile $Dest -UseBasicParsing -PassThru
  return $resp
}

function Find-Repo {
  $dir = Split-Path -Parent $PSCommandPath
  for ($i = 0; $i -lt 6; $i++) {
    if (Test-Path (Join-Path $dir "project.godot")) { return $dir }
    $parent = Split-Path -Parent $dir
    if (-not $parent -or $parent -eq $dir) { break }
    $dir = $parent
  }
  return $null
}

function Resolve-Branch {
  if ($Branch) { return $Branch }
  if ($env:TETHERBOUND_BRANCH) { return $env:TETHERBOUND_BRANCH }
  $f = Join-Path (Split-Path -Parent $PSCommandPath) "kickoff.branch"
  if (Test-Path $f) { $b = (Get-Content $f -Raw).Trim(); if ($b) { return $b } }
  return "main"
}

function Ensure-Godot {
  $found = Get-ChildItem -Path $ToolsDir -Recurse -Filter "Godot_v*_win64_console.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
  if (-not $found) {
    $zip = Join-Path $ToolsDir "godot.zip"
    Download "https://github.com/godotengine/godot/releases/download/$GodotVersion/Godot_v${GodotVersion}_win64.exe.zip" $zip | Out-Null
    Expand-Archive -Path $zip -DestinationPath (Join-Path $ToolsDir "godot") -Force
    $found = Get-ChildItem -Path $ToolsDir -Recurse -Filter "Godot_v*_win64_console.exe" | Select-Object -First 1
  }
  if (-not $found) { throw "Godot $GodotVersion console binary not found after download" }
  $script:Godot = $found.FullName
  $ver = (& $script:Godot --version 2>&1 | Select-Object -Last 1)
  Log "godot: $script:Godot ($ver)"
  if ("$ver" -notmatch "^4\.7\.") { Log "WARNING: Godot version is not 4.7.x; results are not comparable to CI" }
}

function Ensure-Ffmpeg {
  $found = Get-ChildItem -Path $ToolsDir -Recurse -Filter "ffmpeg.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
  if (-not $found) {
    try {
      $zip = Join-Path $ToolsDir "ffmpeg.zip"
      Download $FfmpegUrl $zip | Out-Null
      Expand-Archive -Path $zip -DestinationPath (Join-Path $ToolsDir "ffmpeg") -Force
      $found = Get-ChildItem -Path $ToolsDir -Recurse -Filter "ffmpeg.exe" | Select-Object -First 1
    } catch { Log "ffmpeg download failed: $($_.Exception.Message) -- video stays as MJPEG .avi and no video sheets are made" }
  }
  if ($found) { $script:Ffmpeg = $found.FullName; Log "ffmpeg: $script:Ffmpeg" }
}

# Git is what carries the evidence back. Install it when missing: winget
# first, the official installer second. The FIRST push from a machine opens
# GitHub's sign-in in a browser once (Git Credential Manager); after that it
# is cached and every later run pushes on its own.
function Ensure-Git {
  if (Get-Command git -ErrorAction SilentlyContinue) { return }
  Log "git not found; installing Git for Windows"
  try {
    $winget = Get-Command winget -ErrorAction SilentlyContinue
    if ($winget) {
      & winget install --id Git.Git -e --silent --accept-package-agreements --accept-source-agreements 2>&1 | ForEach-Object { Log "winget: $_" }
    }
  } catch { Log "winget failed: $($_.Exception.Message)" }
  if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    try {
      $rel = Invoke-RestMethod -Uri "https://api.github.com/repos/git-for-windows/git/releases/latest" -UseBasicParsing
      $asset = $rel.assets | Where-Object { $_.name -match "^Git-.*-64-bit\.exe$" } | Select-Object -First 1
      if ($asset) {
        $inst = Join-Path $ToolsDir $asset.name
        Download $asset.browser_download_url $inst | Out-Null
        & $inst /VERYSILENT /NORESTART /NOCANCEL /SP- /COMPONENTS="gitlfs" | Out-Null
      }
    } catch { Log "git installer failed: $($_.Exception.Message)" }
  }
  foreach ($c in @("$env:ProgramFiles\Git\cmd", "$env:LOCALAPPDATA\Programs\Git\cmd")) {
    if (Test-Path (Join-Path $c "git.exe")) { $env:Path = "$c;$env:Path" }
  }
  if (Get-Command git -ErrorAction SilentlyContinue) { Log "git: $((& git --version) 2>&1)" }
  else { Log "git still missing: the run will work, the evidence will only be zipped" }
}

function Ensure-Repo {
  $branch = Resolve-Branch
  Ensure-Git
  $git = Get-Command git -ErrorAction SilentlyContinue
  $repo = Find-Repo
  if ($repo) {
    $script:Repo = $repo
    Log "repo: $repo (this checkout)"
    if ($git -and (Test-Path (Join-Path $repo ".git"))) {
      # Untracked files (Godot writes .uid sidecars on import) do not count as dirty.
      $dirty = (& git -C $repo status --porcelain --untracked-files=no 2>$null)
      if ($dirty) {
        Log "working tree has local changes; running on it AS IS, no fetch"
      } else {
        & git -C $repo fetch -q origin $branch 2>&1 | ForEach-Object { Log "git: $_" }
        & git -C $repo checkout -q -B $branch "origin/$branch" 2>&1 | ForEach-Object { Log "git: $_" }
      }
    }
  } else {
    $script:Repo = Join-Path $State "repo"
    if ($git) {
      if (-not (Test-Path (Join-Path $script:Repo ".git"))) {
        Log "cloning $RepoUrl ($branch) into $script:Repo"
        & git clone -q --branch $branch $RepoUrl $script:Repo 2>&1 | ForEach-Object { Log "git: $_" }
      } else {
        & git -C $script:Repo fetch -q origin $branch 2>&1 | ForEach-Object { Log "git: $_" }
        & git -C $script:Repo checkout -q -B $branch "origin/$branch" 2>&1 | ForEach-Object { Log "git: $_" }
      }
    } else {
      Log "no git on this machine: downloading $branch as a zip (evidence cannot be pushed, it will be zipped)"
      $zip = Join-Path $State "repo.zip"
      Download "$RepoUrl/archive/refs/heads/$branch.zip" $zip | Out-Null
      if (Test-Path $script:Repo) { Remove-Item -Recurse -Force $script:Repo }
      Expand-Archive -Path $zip -DestinationPath (Join-Path $State "repo_unzip") -Force
      $inner = Get-ChildItem (Join-Path $State "repo_unzip") | Select-Object -First 1
      Move-Item $inner.FullName $script:Repo
    }
  }
  if (-not (Test-Path (Join-Path $script:Repo "project.godot"))) { throw "no project.godot under $script:Repo" }
  if ($git -and (Test-Path (Join-Path $script:Repo ".git"))) {
    $script:Sha = (& git -C $script:Repo rev-parse HEAD 2>$null)
    if (-not $script:Sha) { $script:Sha = "unknown" }
  }
  $script:Evidence = Join-Path $script:Repo "ralph\reports\OWNER-KICKOFF-$Stamp"
  $script:GateRun = Join-Path $script:Repo "ralph\reports\gate-f-run-$Stamp-owner"
  New-Item -ItemType Directory -Force -Path $script:Evidence, (Join-Path $script:Evidence "frames"), (Join-Path $script:Evidence "logs") | Out-Null
  Log "sha: $script:Sha  evidence: $script:Evidence"
  Test-PushAccess
}

# Can this machine actually deliver the evidence?
#
# WHY THIS RUNS IN `prepare` AND NOT AT THE PUSH: the push is the last thing an
# eight-hour run does. A machine that was never logged into GitHub burns the
# whole chain and then fails at the final step, which is exactly what happened
# on the 2026-09-07 run -- the evidence was complete and stranded on a local
# branch. Ten seconds here turns that into a warning the operator sees before
# walking away.
#
# `push --dry-run` rather than `ls-remote`: this repository allows anonymous
# READ, so ls-remote succeeds on a machine that cannot push. --dry-run does the
# real connection and the real authorisation check, and updates nothing -- the
# probe ref is never created.
function Test-PushAccess {
  $git = Get-Command git -ErrorAction SilentlyContinue
  if (-not $git -or -not (Test-Path (Join-Path $script:Repo ".git"))) {
    $script:PushProbe = "no git checkout: evidence will be zipped only"
    Log "PUSH ACCESS: none -- $script:PushProbe"
    return
  }
  $probe = "refs/heads/kickoff-auth-probe-$Stamp"
  $out = (& git -C $script:Repo push --dry-run origin "HEAD:$probe" 2>&1)
  if ($LASTEXITCODE -eq 0) {
    $script:CanPush = $true
    $script:PushProbe = "ok"
    Log "PUSH ACCESS: ok (evidence will be pushed to owner-run/$Stamp)"
    return
  }
  $script:PushProbe = ($out | Select-Object -First 1) -join " "
  Log "*** PUSH ACCESS: NONE ***"
  Log "*** git said: $script:PushProbe"
  Log "*** The run will continue and everything will be recorded, but the"
  Log "*** evidence can only be delivered as the Desktop zip and a LOCAL"
  Log "*** branch. To fix it now, in another window: gh auth login"
  Log "*** (or: winget install GitHub.cli, then gh auth login), then re-run"
  Log "*** KICKOFF. Nothing is lost -- -Resume $Stamp skips finished phases."
}

function Write-MachineRecord {
  $gpu = @()
  try { $gpu = Get-CimInstance Win32_VideoController | ForEach-Object { "$($_.Name) ($($_.DriverVersion))" } } catch {}
  $cpu = ""; $ram = 0; $os = ""
  try { $cpu = (Get-CimInstance Win32_Processor | Select-Object -First 1).Name } catch {}
  try { $ram = [int]((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB) } catch {}
  try { $os = (Get-CimInstance Win32_OperatingSystem).Caption } catch {}
  $rec = @{
    stamp = $Stamp; sha = $script:Sha; branch = (Resolve-Branch); godot = $script:Godot; ffmpeg = "$script:Ffmpeg"
    resolution = $Res; gpu = $gpu; cpu = $cpu; ram_gb = $ram; os = $os; machine = $env:COMPUTERNAME
    quick = [bool]$Quick; only = $Only; started_utc = (Get-Date).ToUniversalTime().ToString("o")
    grass_field = (Get-Content (Join-Path $script:Repo "data\config\grass_field.json") -Raw | ConvertFrom-Json).enabled
  }
  $rec | ConvertTo-Json -Depth 4 | Out-File -FilePath (Join-Path $script:Evidence "RUN_METADATA.json") -Encoding utf8
  Log "machine: $cpu / $($gpu -join '; ') / $ram GB / $os"
}

function Import-Project {
  # The first import on a clean checkout exits non-zero while Terrain3D's
  # GDExtension registers its classes; the second pass is authoritative.
  Invoke-GodotHeadless @("--import") (Join-Path $script:Evidence "logs\import-1.log") 1800 | Out-Null
  $code = Invoke-GodotHeadless @("--import") (Join-Path $script:Evidence "logs\import-2.log") 1800
  if ($code -ne 0) { throw "import failed (exit $code)" }
}

function Sheet-Dir([string]$RelDir, [string]$OutRel) {
  $log = Join-Path $script:Evidence ("logs\sheet-" + ($OutRel -replace '[\\/:]', '_') + ".log")
  Invoke-GodotHeadless @("--script", "tools/contact_sheet.gd", "--", "--dir=res://$RelDir", "--out=res://$OutRel") $log 600 | Out-Null
}

function Collect-Frames([string]$RelDir, [string]$SetName) {
  $src = Join-Path $script:Repo $RelDir
  if (-not (Test-Path $src)) { Log "no frames at $RelDir"; return }
  $dst = Join-Path $RunLocal "frames\$SetName"
  New-Item -ItemType Directory -Force -Path $dst | Out-Null
  Copy-Item (Join-Path $src "*") $dst -Recurse -Force -ErrorAction SilentlyContinue
  Get-ChildItem $src -Filter "_sheet*.png" -ErrorAction SilentlyContinue | ForEach-Object {
    Copy-Item $_.FullName (Join-Path $script:Evidence "frames\_sheet_${SetName}_$($_.Name.TrimStart('_'))") -Force
  }
}

# The route strip is ~190 frames per pass; contact_sheet.gd is three columns,
# so chunk it into sheets of twelve in route order.
function Sheet-Route([string]$RelDir, [string]$SetName) {
  $src = Join-Path $script:Repo $RelDir
  if (-not (Test-Path $src)) { return }
  $frames = Get-ChildItem $src -Filter "band*.png" | Sort-Object Name
  $n = 0
  for ($i = 0; $i -lt $frames.Count; $i += 12) {
    $n += 1
    $chunk = "{0}/sheet_{1:d3}" -f $RelDir, $n
    New-Item -ItemType Directory -Force -Path (Join-Path $script:Repo $chunk) | Out-Null
    $frames[$i..([Math]::Min($i + 11, $frames.Count - 1))] | ForEach-Object { Move-Item $_.FullName (Join-Path $script:Repo $chunk) }
    Sheet-Dir $chunk ("{0}/_sheet_{1}_{2:d3}.png" -f $RelDir, $SetName, $n)
  }
}

function Phase-Frames {
  foreach ($d in @("shots", "shots_composition", "shots_places", "shots_route", "shots_route_night")) {
    $p = Join-Path $script:Repo $d; if (Test-Path $p) { Remove-Item -Recurse -Force $p }
  }
  $L = Join-Path $script:Evidence "logs"
  Invoke-GodotRender @("--script", "tools/survey.gd") "$L\survey.log" 1800 | Out-Null
  Invoke-GodotRender @("--script", "tools/_capture_band1_composition.gd") "$L\composition.log" 1800 | Out-Null
  Invoke-GodotRender @("--script", "tools/_capture_band1_places.gd") "$L\places.log" 1800 | Out-Null
  Invoke-GodotRender @("--script", "tools/_capture_locations.gd") "$L\locations.log" 3600 | Out-Null
  Invoke-GodotRender @("--script", "tools/_capture_route_strip.gd", "--", "--step=$RouteStepMetres", "--time=day") "$L\route-day.log" 7200 | Out-Null
  Invoke-GodotRender @("--script", "tools/_capture_route_strip.gd", "--", "--step=$($RouteStepMetres * 2)", "--time=night", "--out=res://shots_route_night") "$L\route-night.log" 7200 | Out-Null

  Sheet-Dir "shots" "shots/_sheet_survey.png"
  Sheet-Dir "shots_composition" "shots_composition/_sheet_composition.png"
  Sheet-Dir "shots_places" "shots_places/_sheet_places.png"
  Sheet-Dir "shots/locations" "shots/locations/_sheet_locations.png"
  Sheet-Route "shots_route" "route_day"
  Sheet-Route "shots_route_night" "route_night"

  Collect-Frames "shots" "survey"
  Collect-Frames "shots_composition" "composition"
  Collect-Frames "shots_places" "places"
  Collect-Frames "shots\locations" "locations"
  Collect-Frames "shots_route" "route_day"
  Collect-Frames "shots_route_night" "route_night"
  foreach ($m in @("shots_route\manifest.json", "shots_route_night\manifest.json")) {
    $src = Join-Path $script:Repo $m
    if (Test-Path $src) { Copy-Item $src (Join-Path $script:Evidence ("frames\" + ($m -replace '\\', '_'))) -Force }
  }
  $count = (Get-ChildItem (Join-Path $script:Evidence "frames") -Filter "_sheet*.png").Count
  Log "frames: $count contact sheets in evidence"
  if ($count -eq 0) { throw "no contact sheet was produced" }
}

function Phase-Perf {
  $L = Join-Path $script:Evidence "logs"
  Invoke-GodotRender @("--script", "tools/perf_render_stats.gd", "--", "--label=owner-gpu-$Stamp") "$L\perf_render_stats.log" 3600 | Out-Null
  Copy-Item "$L\perf_render_stats.log" (Join-Path $script:Evidence "perf_render_stats.txt") -Force
  $out = Join-Path $script:Evidence "fps.json"
  $code = Invoke-GodotRender @("--script", "tools/_owner_fps_probe.gd", "--", "--seconds=20", "--out=$out") "$L\fps_probe.log" 3600
  if (-not (Test-Path $out)) { throw "fps probe wrote nothing (exit $code)" }
}

function Phase-Export {
  $dir = Join-Path $RunLocal "release"
  if (Test-Path $dir) { Remove-Item -Recurse -Force $dir }
  New-Item -ItemType Directory -Force -Path $dir | Out-Null
  $zip = Join-Path $dir "Tetherbound-windows.zip"
  $resp = Download "$RepoUrl/releases/download/latest/Tetherbound-windows.zip" $zip
  $lastMod = ""
  try { $lastMod = "$($resp.Headers['Last-Modified'])" } catch {}
  Expand-Archive -Path $zip -DestinationPath $dir -Force
  $exe = Get-ChildItem $dir -Recurse -Filter "Tetherbound.console.exe" | Select-Object -First 1
  $console = $true
  if (-not $exe) { $exe = Get-ChildItem $dir -Recurse -Filter "Tetherbound.exe" | Select-Object -First 1; $console = $false }
  if (-not $exe) { throw "no Tetherbound.exe in the release zip" }
  $log = Join-Path $script:Evidence "logs\export-run.log"
  $code = Invoke-Proc $exe.FullName @("--rendering-driver", "opengl3", "--resolution", $Res, "--verify-export") $log 900 $exe.DirectoryName
  $text = Get-Content $log -Raw
  $fails = @()
  if ($text -match "No baked terrain at") { $fails += "the exported build cannot see its own terrain data" }
  if ($text -match "Terrain3D addon is not installed") { $fails += "Terrain3D did not load in the exported build" }
  if ($text -match "GDExtension dynamic library not found") { $fails += "a GDExtension library is missing from the export" }
  if ($text -match "scatter bake .* is missing|scatter bake manifest names region") { $fails += "the exported build could not open its scatter bake" }
  if ($text -match "no ground under") { $fails += "creatures could not find the ground" }
  if ($text -match "terrain=NO|ground_at_spawn=NaN") { $fails += "no terrain under the player" }
  if ($console -and ($text -notmatch "EXPORT-CHECK")) { $fails += "the exported build never reported EXPORT-CHECK" }
  if ($code -ne 0) { $fails += "the exported build did not exit cleanly (code $code)" }
  $verdict = @()
  $verdict += "# Shipped Windows build, run on $env:COMPUTERNAME"
  $verdict += ""
  $verdict += "- zip: $RepoUrl/releases/download/latest/Tetherbound-windows.zip"
  $verdict += "- release Last-Modified: $lastMod"
  $verdict += "- repo sha this run used for everything else: $script:Sha"
  $verdict += "- binary: $($exe.Name) (console wrapper: $console)"
  $verdict += "- exit code: $code"
  $verdict += ""
  if ($fails.Count -eq 0) { $verdict += "**PASS** - extension loaded, data present, ground found, clean exit." }
  else { $verdict += "**FAIL**"; foreach ($f in $fails) { $verdict += "- $f" } }
  $m = [regex]::Match($text, "EXPORT-CHECK.*"); if ($m.Success) { $verdict += ""; $verdict += '```'; $verdict += $m.Value; $verdict += '```' }
  $verdict -join "`r`n" | Out-File -FilePath (Join-Path $script:Evidence "EXPORT_VERDICT.md") -Encoding utf8
  Log "export: $(if ($fails.Count -eq 0) { 'PASS' } else { 'FAIL: ' + ($fails -join '; ') })"
  if ($fails.Count -gt 0) { throw "shipped build failed verification" }
}

function Process-Video([string]$Avi, [string]$Seg, [string]$SegDir) {
  if (-not (Test-Path $Avi)) { Log "${Seg}: the movie writer produced no file at $Avi"; return }
  $size = [int]((Get-Item $Avi).Length / 1MB)
  Log "${Seg}: video $size MB"
  if (-not $script:Ffmpeg) { return }
  $mp4 = [IO.Path]::ChangeExtension($Avi, ".mp4")
  $code = Invoke-Proc $script:Ffmpeg @("-y", "-loglevel", "error", "-i", $Avi, "-c:v", "libx264", "-preset", "veryfast", "-crf", "26", "-pix_fmt", "yuv420p", "-c:a", "aac", "-b:a", "96k", $mp4) (Join-Path $script:Evidence "logs\ffmpeg-$Seg.log") 14400 $RunLocal
  if ($code -eq 0 -and (Test-Path $mp4)) {
    Remove-Item $Avi -Force
    # One tile per minute of play, sixteen to a sheet: what the judge reads.
    Invoke-Proc $script:Ffmpeg @("-y", "-loglevel", "error", "-i", $mp4, "-vf", "fps=1/60,scale=640:-1,tile=4x4", (Join-Path $SegDir "_sheet_video_%03d.png")) (Join-Path $script:Evidence "logs\ffmpeg-sheet-$Seg.log") 3600 $RunLocal | Out-Null
    # One frame per ten seconds, kept locally, for anyone walking a defect back to its moment.
    $strip = Join-Path $RunLocal "strips\$Seg"; New-Item -ItemType Directory -Force -Path $strip | Out-Null
    Invoke-Proc $script:Ffmpeg @("-y", "-loglevel", "error", "-i", $mp4, "-vf", "fps=1/10,scale=640:-1", (Join-Path $strip "%05d.png")) (Join-Path $script:Evidence "logs\ffmpeg-strip-$Seg.log") 3600 $RunLocal | Out-Null
  } else { Log "${Seg}: transcode failed (exit $code); keeping the .avi" }
}

function Run-Segment([string]$Seg, [bool]$Capture, [bool]$Movie) {
  $out = Join-Path $script:GateRun $Seg
  # A finished segment is skipped on -Resume. A BLOCKED one is not: the harness
  # writes INVENTORY.json even when it refuses at step 1, so the old
  # INVENTORY-only test skipped precisely the segments a resume exists to
  # retry. INCOMPLETE.md / BLOCKER.md are what the harness writes when it did
  # not finish, so they are the honest test.
  $done = (Test-Path (Join-Path $out "INVENTORY.json")) `
      -and -not (Test-Path (Join-Path $out "INCOMPLETE.md")) `
      -and -not (Test-Path (Join-Path $out "BLOCKER.md"))
  if ($done) {
    Log "${Seg}: already finished, skipped"
    $script:SegmentResults += @{ seg = $Seg; exit = 0; wall = 0; capture = $Capture; skipped = $true }
    return
  }
  if (Test-Path $out) {
    $n = 1; while (Test-Path "$out-superseded-$n") { $n += 1 }
    Move-Item $out "$out-superseded-$n"; Log "${Seg}: previous attempt renamed to -superseded-$n"
  }
  New-Item -ItemType Directory -Force -Path $out | Out-Null
  $cmd = @("--script", "tools/gate_f/operator_harness.gd", "--",
    "--gatef-out=$out", "--gatef-run-id=gate-f-run-$Stamp-owner", "--gatef-sha=$script:Sha",
    "--gatef-segment=tools/gate_f/segments/$Seg.json")
  if ($Capture) { $cmd += "--gatef-capture" }
  $engine = @()
  $avi = ""
  if ($Movie) {
    New-Item -ItemType Directory -Force -Path (Join-Path $RunLocal "video") | Out-Null
    $avi = Join-Path $RunLocal "video\$Seg.avi"
    $engine = @("--write-movie", $avi, "--fixed-fps", "30")
  }
  $t0 = Get-Date
  $code = Invoke-GodotRender $cmd (Join-Path $out "console.log") ($SegmentTimeoutMinutes * 60) $engine
  $wall = [int]((Get-Date) - $t0).TotalSeconds
  Add-Content -Path (Join-Path $script:GateRun "CHAIN_LOG.tsv") -Value ("{0}`t{1}`t{2}`t{3}" -f $Seg, $t0.ToUniversalTime().ToString("o"), $wall, $code)
  if ($Movie) { Process-Video $avi $Seg $out }
  Log "${Seg}: exit $code after $wall s"
  $script:SegmentResults += @{ seg = $Seg; exit = $code; wall = $wall; capture = $Capture; skipped = $false }
}

function Phase-Chain {
  New-Item -ItemType Directory -Force -Path $script:GateRun | Out-Null
  if (-not (Test-Path (Join-Path $script:GateRun "CHAIN_LOG.tsv"))) {
    "segment`tstarted_utc`twall_s`texit" | Out-File -FilePath (Join-Path $script:GateRun "CHAIN_LOG.tsv") -Encoding utf8
  }
  # The capture smoke run_segment.sh gates on: can this box write a PNG at all?
  $smoke = Join-Path $script:GateRun "_smoke"
  New-Item -ItemType Directory -Force -Path $smoke | Out-Null
  $code = Invoke-GodotRender @("--script", "tools/capture_diag_minimal.gd", "--", "--gatef-out=$smoke") (Join-Path $smoke "console.log") 600
  if ($code -ne 0 -or -not (Test-Path (Join-Path $smoke "capture_smoke.png"))) { throw "capture smoke failed (exit $code); the chain would produce no frames" }
  @{ requested = @(1280, 800); used = ($Res -split "x" | ForEach-Object { [int]$_ }); substituted = $false; why = "kickoff resolution"; smoke = "_smoke/capture_smoke.png" } |
    ConvertTo-Json | Out-File -FilePath (Join-Path $script:GateRun "CAPTURE_RESOLUTION.json") -Encoding utf8

  foreach ($seg in $Journey) { Run-Segment $seg $false $true }
  foreach ($seg in $CaptureLanes) {
    if (Test-Path (Join-Path $script:Repo "tools\gate_f\segments\$seg.json")) { Run-Segment $seg $true $false }
  }

  # THE PHASE IS ONLY OK IF THE PLAY ACTUALLY HAPPENED. Throwing here is how a
  # non-zero segment reaches the phase table: Run-Phase catches it, records the
  # message in the `error` column, and package still runs, so the evidence is
  # still delivered -- it is just delivered honestly.
  $journey = @($script:SegmentResults | Where-Object { -not $_.capture })
  $lanes = @($script:SegmentResults | Where-Object { $_.capture })
  $jbad = @($journey | Where-Object { $_.exit -ne 0 })
  $lbad = @($lanes | Where-Object { $_.exit -ne 0 })
  if ($jbad.Count -gt 0 -or $lbad.Count -gt 0) {
    $names = (($jbad + $lbad) | ForEach-Object { $_.seg }) -join ", "
    throw ("$($jbad.Count) of $($journey.Count) journey segments and $($lbad.Count) of $($lanes.Count) capture lanes FAILED: $names -- see CHAIN_LOG.tsv and each segment's BLOCKER.md/INCOMPLETE.md")
  }
}

function Phase-Package {
  Copy-Item $LogPath (Join-Path $script:Evidence "kickoff.log") -Force -ErrorAction SilentlyContinue
  Copy-Item $PhasesPath (Join-Path $script:Evidence "PHASES.json") -Force -ErrorAction SilentlyContinue
  $lines = @()
  $lines += "# Kickoff run $Stamp"
  $lines += ""
  $lines += "Machine: $env:COMPUTERNAME. Repo sha: $script:Sha. Resolution: $Res."
  $lines += "Payload (video, every frame, strips) stays on this machine at: ``$RunLocal``."
  $lines += "Push access, probed at the start of the run: $script:PushProbe."
  $lines += ""

  # THE VERDICT GOES FIRST. A reader who stops after four lines must not come
  # away with the wrong answer: the 2026-09-07 summary opened with a phase
  # table of six `ok`s above a chain log in which twelve of fourteen segments
  # had exited 1, and that is the reading it invited.
  $lines += "## Verdict"
  $lines += ""
  $badPhases = @(@("prepare", "frames", "perf", "export", "chain") | Where-Object {
    $script:Phases.ContainsKey($_) -and $script:Phases[$_].status -ne "ok"
  })
  $notRun = @(@("prepare", "frames", "perf", "export", "chain") | Where-Object { -not $script:Phases.ContainsKey($_) })
  $journey = @($script:SegmentResults | Where-Object { -not $_.capture })
  $jbad = @($journey | Where-Object { $_.exit -ne 0 })
  if ($badPhases.Count -eq 0 -and $notRun.Count -eq 0 -and $jbad.Count -eq 0) {
    $lines += "**Everything ran.** All phases ok; every journey segment exited 0."
  } else {
    $lines += "**This run is NOT clean.**"
    $lines += ""
    if ($badPhases.Count) { $lines += "- phases that FAILED: $($badPhases -join ', ')" }
    if ($notRun.Count) { $lines += "- phases that did NOT RUN: $($notRun -join ', ')" }
    if ($journey.Count -and $jbad.Count) {
      $lines += "- **$($jbad.Count) of $($journey.Count) journey segments failed**: $((($jbad | ForEach-Object { $_.seg }) -join ', '))"
      $lines += "  Read each one's ``BLOCKER.md`` / ``INCOMPLETE.md`` before trusting anything about the chapter play."
    }
    if ($journey.Count -and $jbad.Count -eq 0) { $lines += "- every journey segment that ran exited 0" }
  }
  $lines += ""
  $lines += "| phase | status | seconds | error |"
  $lines += "|---|---|---|---|"
  foreach ($k in @("prepare", "frames", "perf", "export", "chain", "package")) {
    if ($script:Phases.ContainsKey($k)) { $p = $script:Phases[$k]; $lines += "| $k | $($p.status) | $($p.seconds) | $($p.error) |" }
    else { $lines += "| $k | not run | | |" }
  }
  $lines += ""
  if (Test-Path (Join-Path $script:GateRun "CHAIN_LOG.tsv")) {
    $lines += "## Chain"; $lines += ""; $lines += '```'
    $lines += (Get-Content (Join-Path $script:GateRun "CHAIN_LOG.tsv"))
    $lines += '```'
  }
  if (Test-Path (Join-Path $script:Evidence "EXPORT_VERDICT.md")) { $lines += ""; $lines += (Get-Content (Join-Path $script:Evidence "EXPORT_VERDICT.md")) }
  $lines += ""
  $lines += "Sheets: ``frames/_sheet_*.png`` (fixed stands, composition, places, locations, route day/night) and ``../gate-f-run-$Stamp-owner/<segment>/_sheet_video_*.png`` (one tile per minute of play)."
  $lines -join "`r`n" | Out-File -FilePath (Join-Path $script:Evidence "RUN_SUMMARY.md") -Encoding utf8

  $desktop = [Environment]::GetFolderPath("Desktop")
  $zip = Join-Path $desktop "Tetherbound-evidence-$Stamp.zip"
  $toZip = @($script:Evidence); if (Test-Path $script:GateRun) { $toZip += $script:GateRun }
  try { Compress-Archive -Path $toZip -DestinationPath $zip -Force; Log "zip: $zip" } catch { Log "zip failed: $($_.Exception.Message)" }

  $git = Get-Command git -ErrorAction SilentlyContinue
  if (-not $git -or -not (Test-Path (Join-Path $script:Repo ".git"))) { Log "no git checkout: evidence is in the zip only"; return }
  $branch = "owner-run/$Stamp"
  $prev = (& git -C $script:Repo rev-parse --abbrev-ref HEAD 2>$null)
  & git -C $script:Repo checkout -q -b $branch 2>&1 | ForEach-Object { Log "git: $_" }
  # WHAT GOES IN THE TREE, and why this is not a plain `add -f` any more.
  #
  # The line this replaces added both directories with -f, which forced past
  # every payload ignore in .gitignore -- the ones whose own comment says
  # capture rounds "grew to 2.8 GB in three days" and that only written
  # verdicts (*.md) and one contact sheet (_sheet*.png) per round belong in
  # the tree. The 2026-09-07 run committed 170 MB that way. Its neighbours in
  # ralph/reports/ are 3.2 MB: json, md and tsv, no per-frame captures.
  #
  # The comment on the old line already said "minus per-frame strips (sheets
  # carry them)". The code never did that. This makes it true.
  #
  # Two directories, two different reasons:
  #
  #   OWNER-KICKOFF-<stamp>   `ralph/reports/OWNER-*/**/[!_]*.png` already
  #                           ignores its per-frame captures and keeps the
  #                           _sheet*.png contact sheets, so a PLAIN add is
  #                           exactly right. -f was only ever defeating it.
  #
  #   gate-f-run-<stamp>-owner  .gitignore deliberately does not name gate-f
  #                           dirs (CD-2 requires the prescribed captures, and
  #                           the harness's own _uncommittable() reads
  #                           `git check-ignore` exit 0 as "git will not carry
  #                           this"), so nothing there is filtered for us and a
  #                           plain add would commit every frame of a whole
  #                           chapter. It is filtered HERE instead, by name, so
  #                           no ignore rule and no test that reads one moves.
  #                           The two blanket rules that DO reach it --
  #                           `ralph/reports/**/*.jsonl` and `**/*.csv` -- are
  #                           what the -f below is for: events.jsonl and
  #                           route.csv are the Gate F telemetry the protocol
  #                           wants committed.
  #
  # -FullPayload restores the old force-everything behaviour for a run that
  # genuinely needs every frame in the tree.
  & git -C $script:Repo add -- "ralph/reports/OWNER-KICKOFF-$Stamp" 2>&1 | ForEach-Object { Log "git: $_" }
  # The run's own diagnostic record, forced past two REPO-WIDE ignores that are
  # not about evidence at all: `*.log` (.gitignore:38) and `logs/`
  # (.gitignore:37). kickoff.log is what says WHY a phase failed and it is a few
  # hundred KB of text -- dropping it would leave a failed phase with a status
  # and no cause. Checked with `git check-ignore -v` rather than assumed.
  & git -C $script:Repo add -f -- "ralph/reports/OWNER-KICKOFF-$Stamp/kickoff.log" 2>&1 | ForEach-Object { Log "git: $_" }
  if (Test-Path (Join-Path $script:Evidence "logs")) {
    & git -C $script:Repo add -f -- "ralph/reports/OWNER-KICKOFF-$Stamp/logs" 2>&1 | ForEach-Object { Log "git: $_" }
  }
  if (Test-Path $script:GateRun) {
    if ($FullPayload) {
      Log "add: -FullPayload, forcing the whole gate-f run into the commit"
      & git -C $script:Repo add -f -- "ralph/reports/gate-f-run-$Stamp-owner" 2>&1 | ForEach-Object { Log "git: $_" }
    } else {
      # THE EXTENSION LIST IS MEASURED, NOT GUESSED. Every gate-f run already
      # committed to this repo carries, in total: 1043 .json, 494 .md, 228
      # .jsonl, 228 .csv, 8 .tsv, 7 .txt, 1 .sha256 -- and 17 .png, every one
      # of them from a selfcheck rig or a preflight smoke, none a chapter run's
      # per-frame capture. So this keeps the text record whole and takes only
      # the _sheet*.png contact sheets, which is what the tree has always held.
      $keep = @(Get-ChildItem -Path $script:GateRun -Recurse -File -ErrorAction SilentlyContinue | Where-Object {
        $_.Extension -in @(".md", ".json", ".tsv", ".jsonl", ".csv", ".txt", ".sha256") -or $_.Name -like "_sheet*.png"
      })
      $skipped = 0
      try { $skipped = @(Get-ChildItem -Path $script:GateRun -Recurse -File -ErrorAction SilentlyContinue).Count - $keep.Count } catch {}
      Log "add: $($keep.Count) evidence files from the gate-f run, $skipped per-frame captures left on this machine"
      # Batched: a whole chapter's verdicts overflow the command line as one call.
      for ($i = 0; $i -lt $keep.Count; $i += 100) {
        $batch = $keep[$i..([Math]::Min($i + 99, $keep.Count - 1))] | ForEach-Object { $_.FullName }
        if ($batch.Count -gt 0) {
          & git -C $script:Repo add -f -- $batch 2>&1 | ForEach-Object { Log "git: $_" }
        }
      }
    }
  }
  $msg = "evidence(owner): kickoff run $Stamp on $env:COMPUTERNAME"
  & git -C $script:Repo -c user.name="Tetherbound Kickoff" -c user.email="kickoff@tetherbound.local" commit -q -m $msg 2>&1 | ForEach-Object { Log "git: $_" }
  $pushed = $false
  for ($i = 1; $i -le 4; $i++) {
    $outp = (& git -C $script:Repo push -u origin $branch 2>&1)
    $outp | ForEach-Object { Log "git: $_" }
    if ($LASTEXITCODE -eq 0) { $pushed = $true; break }
    Start-Sleep -Seconds ([Math]::Pow(2, $i))
  }
  if ($pushed) {
    Log "PUSHED: $branch"
  } else {
    Log "*** PUSH FAILED. The evidence is complete and is in two places on"
    Log "*** THIS machine: local branch $branch, and $zip"
    Log "*** Nothing needs re-running. Authenticate (gh auth login) and then:"
    Log "***   git -C `"$script:Repo`" push -u origin $branch"
  }
  if ($prev -and $prev -ne "HEAD") { & git -C $script:Repo checkout -q $prev 2>&1 | ForEach-Object { Log "git: $_" } }
}

# ------------------------------------------------------------------------------

Log "Tetherbound kickoff $Stamp  (quick=$Quick only='$Only' resume='$Resume')"
Log "state: $State"

Run-Phase "prepare" { Ensure-Repo; Ensure-Godot; Ensure-Ffmpeg; Write-MachineRecord; Import-Project }
if (-not $script:Godot -or -not $script:Repo) {
  Log "prepare did not produce a repo and a Godot; nothing else can run"
  exit 1
}
Run-Phase "frames" { Phase-Frames }
Run-Phase "perf" { Phase-Perf }
Run-Phase "export" { Phase-Export }
Run-Phase "chain" { Phase-Chain } $true
Run-Phase "package" { Phase-Package }

$failed = @($script:Phases.Keys | Where-Object { $script:Phases[$_].status -ne "ok" })
Log "done. failed phases: $(if ($failed.Count) { $failed -join ', ' } else { 'none' })"
Log "evidence: $script:Evidence"
Log "payload:  $RunLocal"
if ($failed.Count) { exit 2 } else { exit 0 }
