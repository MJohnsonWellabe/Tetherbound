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
#   studies  optional -FullProtocol: X01-X08 and their actual capture twins
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
  [switch]$FullProtocol,
  [string]$StudiesFromRun = "",
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

$Journey = @("S01","S02","S03p1","S03p2","S03p3","S04","S05","S06","S07","S08","S09","S10a","S10b","S10c","S10d","S10e")
$CaptureLanes = @("S01C","S02C","S03Cp1","S03Cp2","S03Cp3","S04C","S05C","S06C","S07C","S08C","S09C","S10aC","S10bC","S10cC")

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
  # Revalidate chain inventories even if an older runner marked the phase ok
  # from process exits alone. Clean no-op resumes may reuse their package.
  if ($script:Phases.ContainsKey($Name) -and $script:Phases[$Name].status -eq "ok" -and $Resume -and $Name -notin @("prepare", "chain", "studies")) { Log "phase ${Name}: already ok in $Resume, skipped"; return }
  Log "=== phase $Name ==="
  $t0 = Get-Date
  $status = "ok"; $err = ""
  try { & $Body } catch { $status = "failed"; $err = "$($_.Exception.Message)"; Log "phase $Name FAILED: $err" }
  $script:Phases[$Name] = @{ status = $status; error = $err; started = $t0.ToString("o"); seconds = [int]((Get-Date) - $t0).TotalSeconds }
  if ($Name -in @("chain", "studies") -and ($status -ne "ok" -or @($script:SegmentResults | Where-Object { -not $_.skipped }).Count -gt 0)) {
    # A new attempt or changed verdict invalidates the previously written summary.
    $script:Phases.Remove("package")
  }
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

# Process exit only measures whether the instrument ran. A completed instrument
# may report failed expectations, refused steps or a derailed journey and exit 0.
function Get-SegmentVerdict([string]$Directory, [Nullable[int]]$ProcessExit = $null) {
  $reasons = @()
  if ($null -ne $ProcessExit -and $ProcessExit -ne 0) { $reasons += "process exited $ProcessExit" }
  foreach ($marker in @("INCOMPLETE.md", "BLOCKER.md")) {
    if (Test-Path (Join-Path $Directory $marker)) { $reasons += $marker }
  }
  $inventoryPath = Join-Path $Directory "INVENTORY.json"
  try {
    $inventory = Get-Content -LiteralPath $inventoryPath -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
    if ($inventory.complete -isnot [bool] -or -not $inventory.complete) { $reasons += "inventory.complete is not true" }
    if ($null -eq $inventory.steps) { $reasons += "inventory.steps is missing" }
    else {
      foreach ($field in @("total", "ran", "fail", "refused", "skipped")) {
        $value = $inventory.steps.$field
        if ($null -eq $value -or "$value" -notmatch '^\d+$') { $reasons += "invalid steps.$field" }
      }
      if ($inventory.steps.ran -ne $inventory.steps.total) { $reasons += "steps.ran != steps.total" }
      foreach ($field in @("fail", "refused", "skipped")) {
        if ($inventory.steps.$field -gt 0) { $reasons += "steps.$field=$($inventory.steps.$field)" }
      }
      # Authored skip_if no-ops are PASS, not SKIP, in the harness inventory.
      # SKIP here means unexecuted/context-missing work and cannot close a lane.
    }
    foreach ($field in @("blocked", "derailed")) {
      if (-not [string]::IsNullOrEmpty([string]$inventory.$field)) { $reasons += "${field}: $($inventory.$field)" }
    }
    foreach ($field in @("derails", "harness_errors", "uncommittable")) {
      if (@($inventory.$field | Where-Object { $null -ne $_ }).Count -gt 0) { $reasons += "inventory.$field is not empty" }
    }
  } catch { $reasons += "inventory unreadable: $($_.Exception.Message)" }
  $effective = 0
  if ($reasons.Count -gt 0) { $effective = 1 }
  if ($null -ne $ProcessExit -and $ProcessExit -ne 0) { $effective = [int]$ProcessExit }
  return @{ process_exit = $ProcessExit; effective_exit = $effective; reasons = $reasons }
}

function Run-Segment([string]$Seg, [bool]$Capture, [bool]$Movie, [bool]$RequireCurrentRevision = $false) {
  $out = Join-Path $script:GateRun $Seg
  # Reuse only a genuinely clean inventory, including old runs that exited 0
  # despite failed expectations. Preserve a recorded nonzero process exit too.
  $previousExit = $null
  $resultPath = Join-Path $out "SEGMENT_RESULT.json"
  if (Test-Path $resultPath) {
    try {
      $previous = Get-Content $resultPath -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
      if ($null -eq $previous.process_exit -or "$($previous.process_exit)" -notmatch '^-?\d+$') { throw "Invalid recorded process exit" }
      $previousExit = [int]$previous.process_exit
    } catch { $previousExit = 1 }
  }
  $prior = Get-SegmentVerdict $out $previousExit
  if ($RequireCurrentRevision -and $prior.effective_exit -eq 0) {
    $oldInventory = Get-Content -LiteralPath (Join-Path $out "INVENTORY.json") -Raw | ConvertFrom-Json
    $wantedLane = $(if ($Capture) { "capture" } else { "logic" })
    if ($oldInventory.sha -cne $script:Sha -or $oldInventory.evidence_lane -cne $wantedLane) {
      $prior.effective_exit = 1
      Log "${Seg}: clean prior study belongs to another revision/lane; preserve and rerun"
    }
  }
  if ($prior.effective_exit -eq 0) {
    Log "${Seg}: inventory complete with no failed, refused or skipped steps; reused"
    $script:SegmentResults += @{ seg = $Seg; exit = $previousExit; effective_exit = 0; reasons = @(); wall = 0; capture = $Capture; skipped = $true }
    return
  }
  if (Test-Path $out) {
    $n = 1; while (Test-Path "$out-superseded-$n") { $n += 1 }
    $rootPath = [IO.Path]::GetFullPath($script:GateRun).TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar
    $destination = [IO.Path]::GetFullPath("$out-superseded-$n")
    if (-not [IO.Path]::GetFullPath($out).StartsWith($rootPath, [StringComparison]::OrdinalIgnoreCase) -or
        -not $destination.StartsWith($rootPath, [StringComparison]::OrdinalIgnoreCase)) { throw "Segment archive escaped run directory" }
    Move-Item -LiteralPath $out -Destination $destination -ErrorAction Stop
    Log "${Seg}: previous attempt renamed to -superseded-$n"
  }
  New-Item -ItemType Directory -Force -Path $out | Out-Null
  if ($Capture) {
    # The harness deliberately requires a smoke frame in EACH capture lane's
    # own output directory. The phase-level smoke only proves the machine can
    # render; it does not prove this invocation came through the capture path.
    $smokeCode = Invoke-GodotRender @("--script", "tools/capture_diag_minimal.gd", "--", "--gatef-out=$out") (Join-Path $out "capture-smoke.log") 600
    if ($smokeCode -ne 0) { Log "${Seg}: capture smoke failed (exit $smokeCode); the harness will record the lane blocker" }
  }
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
  $verdict = Get-SegmentVerdict $out $code
  $result = @{ seg = $Seg; process_exit = $code; effective_exit = $verdict.effective_exit; reasons = $verdict.reasons; wall = $wall; capture = $Capture }
  $result | ConvertTo-Json -Depth 5 | Out-File -FilePath $resultPath -Encoding utf8
  Log "${Seg}: process exit $code, effective exit $($verdict.effective_exit) after $wall s; $($verdict.reasons -join '; ')"
  $script:SegmentResults += @{ seg = $Seg; exit = $code; effective_exit = $verdict.effective_exit; reasons = $verdict.reasons; wall = $wall; capture = $Capture; skipped = $false }
}

function Publish-SegmentPhases([ValidateSet("S03", "S03C")][string]$Parent = "S03") {
  $capture = $Parent -eq "S03C"
  # Always reverify the current phase receipts, even on resume. A formerly
  # clean canonical handoff cannot certify rerun phases or changed definitions.
  $out = Join-Path $script:GateRun $Parent
  if (Test-Path -LiteralPath $out) {
    $n = 1; while (Test-Path -LiteralPath "$out-superseded-$n") { $n += 1 }
    $runRoot = [IO.Path]::GetFullPath($script:GateRun).TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar
    $destination = [IO.Path]::GetFullPath("$out-superseded-$n")
    if (-not [IO.Path]::GetFullPath($out).StartsWith($runRoot, [StringComparison]::OrdinalIgnoreCase) -or
        -not $destination.StartsWith($runRoot, [StringComparison]::OrdinalIgnoreCase)) { throw "$Parent archive escaped the run directory" }
    Move-Item -LiteralPath $out -Destination $destination -ErrorAction Stop
  }
  $t0 = Get-Date
  $code = 1
  $why = ""
  try {
    foreach ($phase in @("${Parent}p1", "${Parent}p2", "${Parent}p3")) {
      $attempts = @($script:SegmentResults | Where-Object { $_.seg -eq $phase })
      if ($attempts.Count -eq 0 -or $attempts[-1].effective_exit -ne 0) {
        throw "$phase has no clean runner verdict; canonical $Parent publication is blocked"
      }
    }
    # Logic phase three writes the canonical parent filename. Capture phase
    # three ends in the authored fight; the strict verifier validates its
    # terminal_capture receipt without inventing a final save.
    if (-not $capture -and -not (Test-Path -LiteralPath (Join-Path $script:GateRun "${Parent}p3/saves/$Parent-exit.json"))) {
      throw "${Parent}p3 wrote no canonical $Parent-exit.json"
    }
    $python = $null; $prefix = @()
    if ($env:PYTHON) { $python = Get-Command $env:PYTHON -ErrorAction Stop }
    else {
      foreach ($candidate in @("python", "python3", "py")) {
        $python = Get-Command $candidate -ErrorAction SilentlyContinue
        if ($python) { if ($candidate -eq "py") { $prefix = @("-3") }; break }
      }
    }
    if (-not $python) { throw "Python 3 is required for strict $Parent phase aggregation; set PYTHON to its executable" }
    $arguments = $prefix + @((Join-Path $script:Repo "tools/gate_f/aggregate_segment_phases.py"), $script:GateRun, "--parent", $Parent)
    $code = Invoke-Proc $python.Source $arguments (Join-Path $script:GateRun "$Parent-aggregate.log") 120 $script:Repo
  } catch { $why = $_.Exception.Message }
  $wall = [int]((Get-Date) - $t0).TotalSeconds
  $verdict = Get-SegmentVerdict $out $code
  if ($why) { $verdict.reasons += $why; $verdict.effective_exit = 1 }
  if (-not $capture -and -not (Test-Path -LiteralPath (Join-Path $out "saves/$Parent-exit.json"))) {
    $verdict.reasons += "verified canonical $Parent exit save is missing"
    if ($verdict.effective_exit -eq 0) { $verdict.effective_exit = 1 }
  }
  New-Item -ItemType Directory -Force -Path $out | Out-Null
  @{ seg = $Parent; process_exit = $code; effective_exit = $verdict.effective_exit; reasons = $verdict.reasons; wall = $wall; capture = $capture } |
    ConvertTo-Json -Depth 5 | Out-File -FilePath (Join-Path $out "SEGMENT_RESULT.json") -Encoding utf8
  Add-Content -Path (Join-Path $script:GateRun "CHAIN_LOG.tsv") -Value ("$Parent`t{0}`t{1}`t{2}" -f $t0.ToUniversalTime().ToString("o"), $wall, $code)
  $script:SegmentResults += @{ seg = $Parent; exit = $code; effective_exit = $verdict.effective_exit; reasons = $verdict.reasons; wall = $wall; capture = $capture; skipped = $false }
  Log "$Parent phase aggregation: process exit $code, effective exit $($verdict.effective_exit); $($verdict.reasons -join '; ')"
  return ($verdict.effective_exit -eq 0)
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

  # Journey files declare evidence_lane=logic and deliberately delegate their
  # pictures to the capture lanes below. Recording a fixed-FPS movie here turns
  # every simulated wait into encoded frames, making long segments take 4-6
  # hours and trip the harness's honest pre-flight ceiling before step one.
  # Run the mechanics on the real renderer without Movie Maker; capture lanes
  # remain the production-frame evidence and the logic lanes retain events and
  # their 2 Hz route trace.
  foreach ($seg in $Journey) {
    Run-Segment $seg $false $false
    if ($seg -eq "S03p3" -and -not (Publish-SegmentPhases "S03")) {
      Log "S03 phase aggregation failed; S04 and later journey segments are blocked"
      break
    }
  }
  foreach ($seg in $CaptureLanes) {
    if (Test-Path (Join-Path $script:Repo "tools\gate_f\segments\$seg.json")) { Run-Segment $seg $true $false }
    if ($seg -eq "S03Cp3" -and -not (Publish-SegmentPhases "S03C")) {
      Log "S03C phase aggregation failed; remaining independent capture lanes will still run"
    }
  }

  # THE PHASE IS ONLY OK IF THE PLAY ACTUALLY HAPPENED. Throwing here is how a
  # unsuccessful segment verdict reaches the phase table: Run-Phase records the
  # message in the `error` column, and package still runs, so the evidence is
  # still delivered -- it is just delivered honestly.
  $journey = @($script:SegmentResults | Where-Object { -not $_.capture })
  $lanes = @($script:SegmentResults | Where-Object { $_.capture })
  $jbad = @($journey | Where-Object { $_.effective_exit -ne 0 })
  $lbad = @($lanes | Where-Object { $_.effective_exit -ne 0 })
  if ($jbad.Count -gt 0 -or $lbad.Count -gt 0) {
    $names = (($jbad + $lbad) | ForEach-Object { $_.seg }) -join ", "
    throw ("$($jbad.Count) of $($journey.Count) journey segments and $($lbad.Count) of $($lanes.Count) capture lanes FAILED: $names -- see each segment's SEGMENT_RESULT.json and INVENTORY.json; CHAIN_LOG.tsv preserves raw process exits")
  }
}

function Get-StudySchedule {
  # X05 loads the awkward saves authored by X06: its producer studies MUST run
  # first. X06 variants cover the original script once, not three extra passes.
  $names = @("X01", "X02", "X03", "X04", "X06a", "X06b", "X06c", "X05", "X07", "X08",
    "X01C", "X02C", "X03C", "X04C", "X05C", "X07C")
  foreach ($name in $names) {
    $path = Join-Path $script:Repo "tools/gate_f/segments/$name.json"
    $definition = Get-Content -LiteralPath $path -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
    if ($definition.id -cne $name -or $definition.evidence_lane -notin @("logic", "capture")) { throw "Invalid study definition $name" }
    $seeds = @($definition.steps | Where-Object { $_.action -eq "seed_save" } | ForEach-Object {
      $from = [string]$_.args.from
      if ($from -notmatch '^run://([^/\\:]+\.json)$') { throw "$name has an unsupported non-run checkpoint: $from" }
      $Matches[1]
    } | Select-Object -Unique)
    [pscustomobject]@{ segment = $name; capture = ($definition.evidence_lane -eq "capture");
      prerequisites = $seeds; definition_sha256 = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant() }
  }
}

function Test-StudySplitCoverage {
  $base = Join-Path $script:Repo "tools/gate_f/segments"
  $source = Get-Content -LiteralPath (Join-Path $base "X06.json") -Raw -ErrorAction Stop | ConvertFrom-Json
  $union = @(); $prefix = @(); $hashes = @{}
  foreach ($name in @("X06a", "X06b", "X06c")) {
    $path = Join-Path $base "$name.json"
    $part = Get-Content -LiteralPath $path -Raw -ErrorAction Stop | ConvertFrom-Json
    $hashes[$name] = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()
    foreach ($step in $part.steps) {
      if ($step.id -cmatch '^X06c-pre-(\d+)$') {
        $originalId = "X06-$($Matches[1])"
        $copy = $step | ConvertTo-Json -Depth 100 -Compress | ConvertFrom-Json
        $copy.id = $originalId
        $original = @($source.steps | Where-Object { $_.id -ceq $originalId })
        if ($name -cne "X06c" -or $original.Count -ne 1 -or
            ($copy | ConvertTo-Json -Depth 100 -Compress) -cne ($original[0] | ConvertTo-Json -Depth 100 -Compress)) {
          throw "X06 split load preamble differs from its canonical source: $($step.id)"
        }
        $prefix += $originalId
      } else { $union += $step }
    }
  }
  $expectedPrefix = @(181..190 | ForEach-Object { "X06-$_" })
  if (($prefix -join ',') -cne ($expectedPrefix -join ',') -or $union.Count -ne $source.steps.Count) { throw "X06 split omits or duplicates canonical work" }
  for ($i = 0; $i -lt $union.Count; $i++) {
    if (($union[$i] | ConvertTo-Json -Depth 100 -Compress) -cne ($source.steps[$i] | ConvertTo-Json -Depth 100 -Compress)) {
      throw "X06 split source mismatch at canonical step $($source.steps[$i].id)"
    }
  }
  return @{ original_steps = $source.steps.Count; repeated_load_steps = $prefix.Count; variants = $hashes;
    source_sha256 = (Get-FileHash -LiteralPath (Join-Path $base "X06.json") -Algorithm SHA256).Hash.ToLowerInvariant() }
}

function Get-StudyCheckpoint([string]$Filename) {
  # Named providers only. An incidental or failed study's same-named file is
  # never a substitute for the checkpoint prescribed by the protocol.
  $providers = @{
    "S02-exit.json" = "S02"; "S03-exit.json" = "S03"; "S04-exit.json" = "S04";
    "S05-exit.json" = "S05"; "S06-exit.json" = "S06"; "S07-exit.json" = "S07";
    "S08-exit.json" = "S08"; "S09-exit.json" = "S09"; "S10-exit.json" = "S10e";
    "X06-awkward-on-the-bridge.json" = "X06a";
    "X06-awkward-mid-Warrens.json" = "X06b";
    "X06-awkward-with-satchel-full.json" = "X06b";
    "X06-awkward-at-night-while-a-creature-is-bedded.json" = "X06b";
    "X06-awkward-during-aim-cancel-frame.json" = "X06c"
  }
  if (-not $providers.ContainsKey($Filename)) { throw "No approved checkpoint provider for $Filename" }
  $provider = $providers[$Filename]
  $definition = Get-Content -LiteralPath (Join-Path $script:Repo "tools/gate_f/segments/$provider.json") -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
  if (@($definition.steps | Where-Object { $_.action -eq 'save_out' -and $_.args.name -ceq $Filename }).Count -ne 1) {
    throw "$provider does not declare exactly one save_out for $Filename"
  }
  $directory = Join-Path $script:GateRun $provider
  $priorExit = $null
  $resultPath = Join-Path $directory "SEGMENT_RESULT.json"
  if (Test-Path -LiteralPath $resultPath) {
    $result = Get-Content -LiteralPath $resultPath -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
    if ($result.effective_exit -ne 0 -or $null -eq $result.process_exit -or "$($result.process_exit)" -notmatch '^0$') {
      throw "$Filename provider $provider has a failed or unknown process verdict"
    }
    $priorExit = 0
  }
  $verdict = Get-SegmentVerdict $directory $priorExit
  if ($verdict.effective_exit -ne 0) { throw "$Filename requires successful $provider ($($verdict.reasons -join '; '))" }
  $path = Join-Path $directory "saves/$Filename"
  if (-not (Test-Path -LiteralPath $path -PathType Leaf) -or (Get-Item -LiteralPath $path).Length -le 0) { throw "$provider did not export $Filename" }
  $inventory = Get-Content -LiteralPath (Join-Path $directory "INVENTORY.json") -Raw | ConvertFrom-Json
  $hash = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()
  if ($provider -eq "S03" -and $inventory.execution -eq "save_linked_phases" -and $inventory.aggregate.exit_save_sha256 -cne $hash) {
    throw "Canonical S03 checkpoint changed after phase aggregation"
  }
  # Mirror _step_seed_save's priority tiers. Directory enumeration order is not
  # portable, so every reachable fallback must contain the prescribed bytes.
  $candidates = @()
  $rootSave = Join-Path $script:GateRun "saves/$Filename"
  $owner = [IO.Path]::GetFileNameWithoutExtension($Filename) -creplace '-exit$', ''
  $ownedSave = Join-Path $script:GateRun "$owner/saves/$Filename"
  if (Test-Path -LiteralPath $rootSave -PathType Leaf) {
    $candidates = @($rootSave)
  } elseif (Test-Path -LiteralPath $ownedSave -PathType Leaf) {
    $candidates = @($ownedSave)
  } else {
    $candidates = @(Get-ChildItem -LiteralPath $script:GateRun -Directory -Force | Where-Object {
      -not $_.Name.StartsWith('.') -and -not $_.Name.Contains('-superseded-')
    } | ForEach-Object {
      $candidate = Join-Path $_.FullName "saves/$Filename"
      if (Test-Path -LiteralPath $candidate -PathType Leaf) { $candidate }
    })
  }
  if ($candidates.Count -eq 0) { throw "No harness-resolvable seed for $Filename" }
  foreach ($candidate in $candidates) {
    if ((Get-FileHash -LiteralPath $candidate -Algorithm SHA256).Hash.ToLowerInvariant() -cne $hash) {
      throw "Seed resolution conflict for ${Filename}: $candidate differs from verified provider $provider"
    }
  }
  return @{ filename = $Filename; provider = $provider; path = $path; sha256 = $hash; source_revision = $inventory.sha;
    resolution_candidates = $candidates; resolution_sha256 = $hash }
}

function Phase-Studies {
  New-Item -ItemType Directory -Force -Path $script:GateRun | Out-Null
  if (-not (Test-Path (Join-Path $script:GateRun "CHAIN_LOG.tsv"))) {
    "segment`tstarted_utc`twall_s`texit" | Out-File -FilePath (Join-Path $script:GateRun "CHAIN_LOG.tsv") -Encoding utf8
  }
  $plan = @(Get-StudySchedule)
  $coverage = Test-StudySplitCoverage
  $receipt = @{ scope = "full_protocol_studies"; source_revision = $script:Sha;
    note = "Study execution only; no journey, acceptance-gate, or synthetic X06 parent PASS is inferred.";
    x06_split = $coverage; complete = $false; planned = @($plan | ForEach-Object { $_.segment }); results = @() }
  $receiptPath = Join-Path $script:GateRun ("STUDY_SCHEDULE-{0}-{1}.json" -f (Get-Date).ToUniversalTime().ToString("yyyyMMddTHHmmssZ"), [guid]::NewGuid().ToString('N').Substring(0,8))
  foreach ($study in $plan) {
    $row = @{ segment = $study.segment; capture = $study.capture; definition_sha256 = $study.definition_sha256;
      prerequisites = @(); status = "blocked"; reasons = @(); effective_exit = 1 }
    try {
      $definitionPath = Join-Path $script:Repo "tools/gate_f/segments/$($study.segment).json"
      if ((Get-FileHash -LiteralPath $definitionPath -Algorithm SHA256).Hash.ToLowerInvariant() -cne $study.definition_sha256) {
        throw "$($study.segment) definition changed after scheduling; freeze the source before retrying"
      }
      foreach ($filename in $study.prerequisites) { $row.prerequisites += Get-StudyCheckpoint $filename }
      $before = $script:SegmentResults.Count
      Run-Segment $study.segment $study.capture $false $true
      if ($script:SegmentResults.Count -ne ($before + 1) -or $script:SegmentResults[-1].seg -cne $study.segment) {
        throw "$($study.segment) produced no unique runner verdict"
      }
      $result = $script:SegmentResults[-1]
      $row.effective_exit = $result.effective_exit
      $row.reasons = @($result.reasons)
      $row.status = $(if ($result.effective_exit -eq 0) { "passed" } else { "failed" })
      $row.reused = [bool]$result.skipped
    } catch {
      $row.reasons = @($_.Exception.Message)
      Log "study $($study.segment) blocked: $($_.Exception.Message)"
    }
    $receipt.results += $row
    $receipt | ConvertTo-Json -Depth 15 | Out-File -FilePath $receiptPath -Encoding utf8
  }
  $bad = @($receipt.results | Where-Object { $_.status -ne "passed" })
  $receipt.complete = $bad.Count -eq 0 -and $receipt.results.Count -eq $plan.Count
  $receipt | ConvertTo-Json -Depth 15 | Out-File -FilePath $receiptPath -Encoding utf8
  if (-not $receipt.complete) { throw "Full-protocol studies incomplete: $(($bad | ForEach-Object { $_.segment }) -join ', '); see $receiptPath" }
  Log "Study schedule completed with individual clean verdicts; acceptance review remains separate: $receiptPath"
}

function Start-FrozenStudies([string]$RunDirectory, [string]$Repository) {
  # No prepare/import/fetch/checkout/package/push. This entrypoint operates on
  # an already imported frozen checkout and an explicit existing evidence run.
  $script:Repo = (Resolve-Path -LiteralPath $Repository -ErrorAction Stop).Path
  $script:GateRun = (Resolve-Path -LiteralPath $RunDirectory -ErrorAction Stop).Path
  if (-not (Test-Path -LiteralPath $script:GateRun -PathType Container)) { throw "-StudiesFromRun requires an existing evidence directory" }
  if (-not (Test-Path (Join-Path $script:Repo "project.godot")) -or
      -not (Test-Path (Join-Path $script:Repo ".godot/imported") -PathType Container)) { throw "Frozen studies require an already imported project checkout" }
  if (-not $env:GODOT -or -not (Test-Path -LiteralPath $env:GODOT -PathType Leaf)) { throw "Set GODOT to the existing pinned Godot executable for -StudiesFromRun" }
  $script:Godot = (Resolve-Path -LiteralPath $env:GODOT).Path
  $script:Sha = (& git -C $script:Repo rev-parse HEAD 2>$null)
  if ($LASTEXITCODE -ne 0 -or -not $script:Sha) { throw "Cannot identify the frozen checkout revision" }
  Phase-Studies
}

function Publish-Evidence {
  $git = Get-Command git -ErrorAction SilentlyContinue
  if (-not $git -or -not (Test-Path (Join-Path $script:Repo ".git"))) { Log "no git checkout: evidence is in the zip only"; return }
  $branch = "owner-run/$Stamp"
  # Never include another task's staged work in the evidence commit.
  & git -C $script:Repo diff --cached --quiet
  if ($LASTEXITCODE -ne 0) { throw "Evidence packaging requires an empty index; existing staged work was preserved" }
  $before = (& git -C $script:Repo rev-parse HEAD)
  if ($LASTEXITCODE -ne 0) { throw "Cannot resolve evidence base commit" }
  $prev = (& git -C $script:Repo rev-parse --abbrev-ref HEAD 2>$null)
  & git -C $script:Repo checkout -q -b $branch 2>&1 | ForEach-Object { Log "git: $_" }
  if ($LASTEXITCODE -ne 0) { throw "Cannot create evidence branch $branch" }
  try {
    # --sparse permits these exact report paths outside the worktree cone.
    # -f only overrides ignores; it does not override sparse-checkout.
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
    & git -C $script:Repo add --sparse -- "ralph/reports/OWNER-KICKOFF-$Stamp" 2>&1 | ForEach-Object { Log "git: $_" }
    if ($LASTEXITCODE -ne 0) { throw "Failed to stage intended evidence files" }
    # The run's own diagnostic record, forced past two REPO-WIDE ignores that are
    # not about evidence at all: `*.log` (.gitignore:38) and `logs/`
    # (.gitignore:37). kickoff.log is what says WHY a phase failed and it is a few
    # hundred KB of text -- dropping it would leave a failed phase with a status
    # and no cause. Checked with `git check-ignore -v` rather than assumed.
    & git -C $script:Repo add --sparse -f -- "ralph/reports/OWNER-KICKOFF-$Stamp/kickoff.log" 2>&1 | ForEach-Object { Log "git: $_" }
    if ($LASTEXITCODE -ne 0) { throw "Failed to stage intended evidence files" }
    if (Test-Path (Join-Path $script:Evidence "logs")) {
      & git -C $script:Repo add --sparse -f -- "ralph/reports/OWNER-KICKOFF-$Stamp/logs" 2>&1 | ForEach-Object { Log "git: $_" }
      if ($LASTEXITCODE -ne 0) { throw "Failed to stage intended evidence files" }
    }
    if (Test-Path $script:GateRun) {
      if ($FullPayload) {
        Log "add: -FullPayload, forcing the whole gate-f run into the commit"
        & git -C $script:Repo add --sparse -f -- "ralph/reports/gate-f-run-$Stamp-owner" 2>&1 | ForEach-Object { Log "git: $_" }
        if ($LASTEXITCODE -ne 0) { throw "Failed to stage intended evidence files" }
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
            & git -C $script:Repo add --sparse -f -- $batch 2>&1 | ForEach-Object { Log "git: $_" }
            if ($LASTEXITCODE -ne 0) { throw "Failed to stage intended evidence files" }
          }
        }
      }
    }
    & git -C $script:Repo diff --cached --quiet
    if ($LASTEXITCODE -eq 0) { throw "No evidence changes staged; refusing to publish the code-only commit" }
    if ($LASTEXITCODE -ne 1) { throw "Cannot verify staged evidence" }
    $msg = "evidence(owner): kickoff run $Stamp on $env:COMPUTERNAME"
    & git -C $script:Repo -c user.name="Tetherbound Kickoff" -c user.email="kickoff@tetherbound.local" commit -q -m $msg 2>&1 | ForEach-Object { Log "git: $_" }
    if ($LASTEXITCODE -ne 0) { throw "Evidence commit failed; nothing was published" }
    $committed = (& git -C $script:Repo rev-parse HEAD)
    if ($LASTEXITCODE -ne 0 -or $committed -eq $before) { throw "Evidence commit did not advance HEAD; nothing was published" }
    $pushed = $false
    for ($i = 1; $i -le 4; $i++) {
      $outp = (& git -C $script:Repo push -u origin $branch 2>&1)
      $outp | ForEach-Object { Log "git: $_" }
      if ($LASTEXITCODE -eq 0) { $pushed = $true; break }
      Start-Sleep -Seconds ([Math]::Pow(2, $i))
    }
    if ($pushed) {
      $remote = (& git -C $script:Repo ls-remote origin "refs/heads/$branch" 2>&1)
      if ($LASTEXITCODE -ne 0 -or "$remote" -notmatch "^$committed\s") { throw "Push returned success but remote evidence commit could not be verified" }
      Log "PUSHED: $branch ($committed)"
    } else {
      Log "*** PUSH FAILED. The evidence is complete and is in two places on"
      Log "*** THIS machine: local branch $branch, and $zip"
      Log "*** Nothing needs re-running. Authenticate (gh auth login) and then:"
      Log "***   git -C `"$script:Repo`" push -u origin $branch"
    }
    if (-not $pushed) { throw "Evidence commit $committed remains local; push failed" }
  } finally {
    if ($prev -and $prev -ne "HEAD") {
      & git -C $script:Repo checkout -q $prev 2>&1 | ForEach-Object { Log "git: $_" }
      if ($LASTEXITCODE -ne 0) { throw "Could not restore original branch $prev after packaging" }
    }
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
  $jbad = @($journey | Where-Object { $_.effective_exit -ne 0 })
  if ($badPhases.Count -eq 0 -and $notRun.Count -eq 0 -and $jbad.Count -eq 0) {
    $lines += "**Everything ran.** All phases ok; segment inventories are complete with no failed, refused or skipped steps."
  } else {
    $lines += "**This run is NOT clean.**"
    $lines += ""
    if ($badPhases.Count) { $lines += "- phases that FAILED: $($badPhases -join ', ')" }
    if ($notRun.Count) { $lines += "- phases that did NOT RUN: $($notRun -join ', ')" }
    if ($journey.Count -and $jbad.Count) {
      $lines += "- **$($jbad.Count) of $($journey.Count) journey segments failed**: $((($jbad | ForEach-Object { $_.seg }) -join ', '))"
      $lines += "  Read each one's ``SEGMENT_RESULT.json`` and ``INVENTORY.json`` before trusting anything about the chapter play."
    }
    if ($journey.Count -and $jbad.Count -eq 0) { $lines += "- every journey segment has a clean, complete inventory" }
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
    $lines += "## Chain"; $lines += ""; $lines += "Exit is the raw process code, not a gameplay verdict. Read each segment's SEGMENT_RESULT.json and INVENTORY.json for completeness and failures."; $lines += ""; $lines += '```'
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

  Publish-Evidence
}

# ------------------------------------------------------------------------------

Log "Tetherbound kickoff $Stamp  (quick=$Quick only='$Only' resume='$Resume')"
Log "state: $State"

if ($StudiesFromRun) {
  try { Start-FrozenStudies $StudiesFromRun (Join-Path $PSScriptRoot "../.."); exit 0 }
  catch { Log "frozen studies FAILED: $($_.Exception.Message)"; exit 2 }
}

Run-Phase "prepare" { Ensure-Repo; Ensure-Godot; Ensure-Ffmpeg; Write-MachineRecord; Import-Project }
if (-not $script:Godot -or -not $script:Repo) {
  Log "prepare did not produce a repo and a Godot; nothing else can run"
  exit 1
}
Run-Phase "frames" { Phase-Frames }
Run-Phase "perf" { Phase-Perf }
Run-Phase "export" { Phase-Export }
Run-Phase "chain" { Phase-Chain } $true
if ($FullProtocol -or (($Only -split ',') -contains 'studies')) { Run-Phase "studies" { Phase-Studies } $true }
Run-Phase "package" { Phase-Package }

$failed = @($script:Phases.Keys | Where-Object { $script:Phases[$_].status -ne "ok" })
Log "done. failed phases: $(if ($failed.Count) { $failed -join ', ' } else { 'none' })"
Log "evidence: $script:Evidence"
Log "payload:  $RunLocal"
if ($failed.Count) { exit 2 } else { exit 0 }
