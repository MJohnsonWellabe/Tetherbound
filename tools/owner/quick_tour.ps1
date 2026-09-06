# Tetherbound QUICK TOUR. Launched by QUICK_TOUR.cmd; see docs/00_START_HERE.md.
#
# This is NOT tools/owner/KICKOFF.cmd. KICKOFF is the full Gate F evidence
# pipeline -- an overnight run that renders fixed stands, plays the whole
# chapter through the operator harness with video, ships perf numbers and
# pushes an owner-run/<stamp> evidence branch. This script never touches that
# one and produces no evidence branch of its own: it is a fast, local,
# breadth-first spot-check across BOTH shipped biomes (the Meadows and
# Cloudreach Cliffs) for quick visual/functional feedback on a ROG Ally,
# capped at roughly 20 minutes of wall-clock time PER BIOME. Stormwood and
# Water are not built yet and are not attempted here.
#
# Phases:
#   prepare  repo + pinned Godot + one import pass
#   shared   title screen, creature roster, character cast (biome-independent
#            -- see tools/_capture_quick_tour_title.gd's own header for why
#            these are not run twice)
#   meadows  tools/_capture_quick_tour_meadows.gd, budgeted -BudgetMinutes
#   cloudreach  tools/_capture_quick_tour_cloudreach.gd, budgeted -BudgetMinutes
#   package  contact sheets + a short RUN_SUMMARY.md, zipped to the Desktop
#
# Nothing here pushes to git. The payload is local: a Desktop zip and the
# run folder under %LOCALAPPDATA%\Tetherbound named in the summary at the
# end. -Only limits which phases run; -SkipShared skips the roster/cast/title
# pass for a faster two-biome-only run.
#
# Windows PowerShell 5.1 is enough; nothing here needs PowerShell 7.

param(
  [string]$Branch = "",
  [string]$Only = "",
  [switch]$SkipShared,
  [int]$BudgetMinutes = 20,
  [string]$Res = "1280x800"
)

$ErrorActionPreference = "Continue"
$ProgressPreference = "SilentlyContinue"
try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}

$GodotVersion = "4.7-stable"
$RepoUrl = "https://github.com/MJohnsonWellabe/Tetherbound"
$State = Join-Path $env:LOCALAPPDATA "Tetherbound"
$ToolsDir = Join-Path $State "tools"
$Stamp = (Get-Date).ToUniversalTime().ToString("yyyyMMddTHHmmssZ")
$RunLocal = Join-Path $State "quick-tour-runs\$Stamp"
New-Item -ItemType Directory -Force -Path $ToolsDir, $RunLocal | Out-Null
$LogPath = Join-Path $RunLocal "quick_tour.log"
$BudgetSeconds = [Math]::Max(60, $BudgetMinutes * 60)

$script:Godot = $null
$script:Repo = $null
$script:Sha = "unknown"

function Log([string]$msg) {
  $line = "[{0}] {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $msg
  Write-Host $line
  Add-Content -Path $LogPath -Value $line
}

function Quote-Arg([string]$a) { if ($a -match '[\s"]') { return '"' + ($a -replace '"', '\"') + '"' } else { return $a } }

# Run a process with a wall-clock timeout, capturing all output to a file.
# Returns the exit code; 124 means it was killed on the timeout. Copied from
# tools/owner/kickoff.ps1's own Invoke-Proc -- same proven pattern, not
# reinvented here.
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
# together with --rendering-driver hangs forever (docs/AGENT_WORKFLOW.md,
# CLAUDE.md). Every screenshot in this tool goes through this function.
function Invoke-GodotRender([string[]]$ScriptAndArgs, [string]$LogFile, [int]$TimeoutSec) {
  $cmd = @("--path", $script:Repo, "--rendering-driver", "opengl3", "--resolution", $Res) + $ScriptAndArgs
  return Invoke-Proc $script:Godot $cmd $LogFile $TimeoutSec $script:Repo
}

# contact_sheet.gd is pure image compositing and runs headless by its own
# design (tools/contact_sheet.gd's own header).
function Invoke-GodotHeadless([string[]]$ScriptAndArgs, [string]$LogFile, [int]$TimeoutSec) {
  $cmd = @("--headless", "--path", $script:Repo) + $ScriptAndArgs
  return Invoke-Proc $script:Godot $cmd $LogFile $TimeoutSec $script:Repo
}

function Download([string]$Url, [string]$Dest) {
  Log "download $Url"
  Invoke-WebRequest -Uri $Url -OutFile $Dest -UseBasicParsing | Out-Null
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

# Same pinned-version / console-binary logic as tools/owner/kickoff.ps1's
# Ensure-Godot, so a machine that has already run KICKOFF finds the same
# cached install and does not pay a second download.
function Ensure-Godot {
  $found = Get-ChildItem -Path $ToolsDir -Recurse -Filter "Godot_v*_win64_console.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
  if (-not $found) {
    $zip = Join-Path $ToolsDir "godot.zip"
    Download "https://github.com/godotengine/godot/releases/download/$GodotVersion/Godot_v${GodotVersion}_win64.exe.zip" $zip
    Expand-Archive -Path $zip -DestinationPath (Join-Path $ToolsDir "godot") -Force
    $found = Get-ChildItem -Path $ToolsDir -Recurse -Filter "Godot_v*_win64_console.exe" | Select-Object -First 1
  }
  if (-not $found) { throw "Godot $GodotVersion console binary not found after download" }
  $script:Godot = $found.FullName
  $ver = (& $script:Godot --version 2>&1 | Select-Object -Last 1)
  Log "godot: $script:Godot ($ver)"
  if ("$ver" -notmatch "^4\.7\.") { Log "WARNING: Godot version is not 4.7.x; results are not comparable to CI" }
}

function Ensure-Repo {
  $branch = Resolve-Branch
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
  } elseif ($git) {
    $script:Repo = Join-Path $State "repo"
    if (-not (Test-Path (Join-Path $script:Repo ".git"))) {
      Log "cloning $RepoUrl ($branch) into $script:Repo"
      & git clone -q --branch $branch $RepoUrl $script:Repo 2>&1 | ForEach-Object { Log "git: $_" }
    } else {
      & git -C $script:Repo fetch -q origin $branch 2>&1 | ForEach-Object { Log "git: $_" }
      & git -C $script:Repo checkout -q -B $branch "origin/$branch" 2>&1 | ForEach-Object { Log "git: $_" }
    }
  } else {
    Log "no git and no local checkout found: downloading $branch as a zip"
    $zip = Join-Path $State "repo.zip"
    Download "$RepoUrl/archive/refs/heads/$branch.zip" $zip
    $script:Repo = Join-Path $State "repo"
    if (Test-Path $script:Repo) { Remove-Item -Recurse -Force $script:Repo }
    Expand-Archive -Path $zip -DestinationPath (Join-Path $State "repo_unzip") -Force
    $inner = Get-ChildItem (Join-Path $State "repo_unzip") | Select-Object -First 1
    Move-Item $inner.FullName $script:Repo
  }
  if (-not (Test-Path (Join-Path $script:Repo "project.godot"))) { throw "no project.godot under $script:Repo" }
  if ($git -and (Test-Path (Join-Path $script:Repo ".git"))) {
    $script:Sha = (& git -C $script:Repo rev-parse HEAD 2>$null)
    if (-not $script:Sha) { $script:Sha = "unknown" }
  }
  Log "sha: $script:Sha"
}

function Import-Project {
  # The first import on a clean checkout exits non-zero while Terrain3D's
  # GDExtension registers its classes; the second pass is authoritative --
  # same two-pass shape as tools/owner/kickoff.ps1's Import-Project.
  Invoke-GodotHeadless @("--import") (Join-Path $RunLocal "import-1.log") 1800 | Out-Null
  $code = Invoke-GodotHeadless @("--import") (Join-Path $RunLocal "import-2.log") 1800
  if ($code -ne 0) { throw "import failed (exit $code)" }
}

function Sheet-Dir([string]$RelDir, [string]$OutRel, [string]$Label) {
  $src = Join-Path $script:Repo $RelDir
  if (-not (Test-Path $src)) { Log "${Label}: no frames at $RelDir, nothing to sheet"; return }
  $log = Join-Path $RunLocal ("sheet-" + $Label + ".log")
  Invoke-GodotHeadless @("--script", "tools/contact_sheet.gd", "--", "--dir=res://$RelDir", "--out=res://$OutRel") $log 600 | Out-Null
}

function Collect([string]$RelDir, [string]$DestName) {
  $src = Join-Path $script:Repo $RelDir
  if (-not (Test-Path $src)) { return }
  $dst = Join-Path $RunLocal $DestName
  New-Item -ItemType Directory -Force -Path $dst | Out-Null
  Copy-Item (Join-Path $src "*") $dst -Recurse -Force -ErrorAction SilentlyContinue
}

function Run-Only([string]$Name) {
  return (-not $Only) -or (($Only -split ",") -contains $Name)
}

# ------------------------------------------------------------------------------

Log "Tetherbound QUICK TOUR $Stamp (budget ${BudgetMinutes}m/biome, only='$Only', skip-shared=$SkipShared)"
Log "state: $State"

$t0 = Get-Date
Ensure-Repo
Ensure-Godot
Import-Project
try {
  $gpu = (Get-CimInstance Win32_VideoController | Select-Object -First 1).Name
  Log "gpu: $gpu"
} catch {}
Log "prepare done after $([int]((Get-Date) - $t0).TotalSeconds)s"

foreach ($d in @("shots_quick_tour", "shots")) {
  $p = Join-Path $script:Repo $d
  if (Test-Path $p) { Remove-Item -Recurse -Force $p }
}

if (-not $SkipShared -and (Run-Only "shared")) {
  Log "=== shared: title / creature roster / character cast ==="
  $t1 = Get-Date
  Invoke-GodotRender @("--script", "tools/_capture_quick_tour_title.gd") (Join-Path $RunLocal "title.log") 300 | Out-Null
  Invoke-GodotRender @("--script", "tools/_capture_creature_roster.gd") (Join-Path $RunLocal "roster.log") 900 | Out-Null
  Invoke-GodotRender @("--script", "tools/_capture_character_cast.gd") (Join-Path $RunLocal "cast.log") 900 | Out-Null
  Sheet-Dir "shots/creatures" "shots/creatures/_sheet.png" "creatures"
  Sheet-Dir "shots/characters" "shots/characters/_sheet.png" "characters"
  Collect "shots/creatures" "shared_creatures"
  Collect "shots/characters" "shared_characters"
  Collect "shots_quick_tour" "shared_title"
  Log "shared done after $([int]((Get-Date) - $t1).TotalSeconds)s"
} else {
  Log "=== shared: skipped ==="
}

if (Run-Only "meadows") {
  Log "=== biome: meadows (budget ${BudgetMinutes}m) ==="
  $t2 = Get-Date
  $code = Invoke-GodotRender @("--script", "tools/_capture_quick_tour_meadows.gd", "--",
    "--budget-seconds=$BudgetSeconds", "--out=res://shots_quick_tour/meadows") `
    (Join-Path $RunLocal "meadows.log") ($BudgetSeconds + 300)
  Sheet-Dir "shots_quick_tour/meadows" "shots_quick_tour/meadows/_sheet.png" "meadows"
  Collect "shots_quick_tour/meadows" "meadows"
  Log "meadows done (exit $code) after $([int]((Get-Date) - $t2).TotalSeconds)s"
} else {
  Log "=== biome: meadows skipped ==="
}

if (Run-Only "cloudreach") {
  Log "=== biome: cloudreach (budget ${BudgetMinutes}m) ==="
  $t3 = Get-Date
  $code = Invoke-GodotRender @("--script", "tools/_capture_quick_tour_cloudreach.gd", "--",
    "--budget-seconds=$BudgetSeconds", "--out=res://shots_quick_tour/cloudreach") `
    (Join-Path $RunLocal "cloudreach.log") ($BudgetSeconds + 300)
  Sheet-Dir "shots_quick_tour/cloudreach" "shots_quick_tour/cloudreach/_sheet.png" "cloudreach"
  Collect "shots_quick_tour/cloudreach" "cloudreach"
  Log "cloudreach done (exit $code) after $([int]((Get-Date) - $t3).TotalSeconds)s"
} else {
  Log "=== biome: cloudreach skipped ==="
}

# --- package ------------------------------------------------------------------

$lines = @()
$lines += "# Quick Tour run $Stamp"
$lines += ""
$lines += "Repo sha: $script:Sha. Resolution: $Res. Budget: ${BudgetMinutes} minutes per biome."
$lines += "This is a fast spot-check, not chapter-acceptance evidence -- see tools/owner/KICKOFF.cmd for that."
$lines += ""
$lines += "Payload (every frame): ``$RunLocal``"
$lines += ""
$lines += "Contact sheets to look at first:"
foreach ($sheet in Get-ChildItem -Path $RunLocal -Recurse -Filter "_sheet.png" -ErrorAction SilentlyContinue) {
  $lines += "- $($sheet.FullName)"
}
$lines += ""
$lines += "Console logs are named after each phase (title/roster/cast/meadows/cloudreach) in the payload folder above."
$lines -join "`r`n" | Out-File -FilePath (Join-Path $RunLocal "RUN_SUMMARY.md") -Encoding utf8

$desktop = [Environment]::GetFolderPath("Desktop")
$zip = Join-Path $desktop "Tetherbound-quick-tour-$Stamp.zip"
try { Compress-Archive -Path $RunLocal -DestinationPath $zip -Force; Log "zip: $zip" } catch { Log "zip failed: $($_.Exception.Message)" }

Log "done. summary: $(Join-Path $RunLocal 'RUN_SUMMARY.md')"
Log "payload: $RunLocal"
exit 0
