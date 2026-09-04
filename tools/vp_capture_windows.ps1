# Visual-parity evidence capture on a real GPU (owner's Windows machine).
#
# The cloud containers that run the VP program have no GPU: every frame is
# software-rasterised through llvmpipe, so a 15-frame location set takes ~40
# minutes there. The same set on a desktop GPU takes about a minute. This runs
# the SAME capture tools with the SAME arguments, so frames are comparable.
#
# Usage (PowerShell, from the repo root, Godot 4.7 editor on PATH or set $env:GODOT):
#   tools\vp_capture_windows.ps1 -Evidence ralph\reports\visual-parity\OWNER-<date> -Only "01-village,02-mill-pond"
#   tools\vp_capture_windows.ps1 -Evidence ralph\reports\visual-parity\OWNER-<date>            # all locations
# Then: git add the evidence dir, commit `visual(owner): GPU frames <date>`, push to a
# branch named claude/vp-owner-frames and tell the coordinator.
#
# Do NOT pass --headless to a render tool: with a rendering driver it hangs forever
# (ralph/conventions.md). The window will open and close by itself.
param(
  [Parameter(Mandatory=$true)][string]$Evidence,
  [string]$Only = "",
  [string]$Res = "1920x1080",
  [switch]$Full   # also run the combat and buildings captures
)
$ErrorActionPreference = "Continue"
$godot = if ($env:GODOT) { $env:GODOT } else { "godot" }
$repo = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $repo
New-Item -ItemType Directory -Force -Path $Evidence | Out-Null
$log = Join-Path $Evidence "capture.log"
$failedStages = [System.Collections.Generic.List[string]]::new()

function Render($name, $script, $extra) {
  "=== $name $(Get-Date -Format u)" | Tee-Object -FilePath $log -Append
  $args = @("--path", ".", "--rendering-driver", "opengl3", "--resolution", $Res, "--script", $script)
  if ($extra) { $args += "--"; $args += $extra }
  & $godot @args 2>&1 | Select-String -NotMatch "ALSA|libpulse" | Select-Object -Last 30 | Out-File -FilePath $log -Append
  $stageExit = $LASTEXITCODE
  "--- $name exit=$stageExit" | Tee-Object -FilePath $log -Append
  if ($stageExit -ne 0) { $script:failedStages.Add("$name ($stageExit)") }
}

Remove-Item -Recurse -Force shots\locations, shots\ground, shots\combat, shots\buildings -ErrorAction SilentlyContinue
Remove-Item -Force shots\*.png -ErrorAction SilentlyContinue

if ($Only) { Render "locations" "tools/_capture_locations.gd" @("--only=$Only") } else { Render "locations" "tools/_capture_locations.gd" $null }
Render "survey" "tools/survey.gd" $null
Render "ground_and_sky" "tools/_capture_ground_and_sky.gd" $null
if ($Full) {
  Render "combat" "tools/survey_combat.gd" $null
  Render "buildings" "tools/capture_buildings.gd" $null
}
foreach ($d in @("locations", "ground", "combat", "buildings")) {
  if (Test-Path "shots\$d") {
    & $godot --headless --path . --script tools/contact_sheet.gd -- "--dir=res://shots/$d" "--out=res://shots/_sheet_$d.png" 2>&1 | Out-Null
  }
}
& $godot --headless --path . --script tools/contact_sheet.gd 2>&1 | Out-Null

foreach ($d in @("locations", "ground", "combat", "buildings")) {
  if (Test-Path "shots\$d") { New-Item -ItemType Directory -Force -Path (Join-Path $Evidence $d) | Out-Null; Copy-Item "shots\$d\*.png" (Join-Path $Evidence $d) }
}
New-Item -ItemType Directory -Force -Path (Join-Path $Evidence "survey") | Out-Null
Copy-Item shots\*.png (Join-Path $Evidence "survey") -ErrorAction SilentlyContinue

# Structural perf counters are hardware-independent; frame time here IS a real
# GPU number, unlike the containers' -- record both.
"=== perf $(Get-Date -Format u)" | Tee-Object -FilePath $log -Append
& $godot --path . --rendering-driver opengl3 --resolution 1280x720 --script tools/perf_render_stats.gd -- "--label=owner-gpu" "--views=band1_open,village_high,hall_approach" 2>&1 |
  Select-String -NotMatch "ALSA|libpulse" | Out-File -FilePath (Join-Path $Evidence "perf_render_stats.txt")
$perfExit = $LASTEXITCODE
if ($perfExit -ne 0) { $failedStages.Add("perf ($perfExit)") }
$pngCount = (Get-ChildItem -Recurse -Filter *.png $Evidence).Count
if ($failedStages.Count -gt 0) {
  "=== FAILED $(Get-Date -Format u)  pngs=$pngCount  stages=$($failedStages -join ', ')" | Tee-Object -FilePath $log -Append
  exit 1
}
"=== DONE $(Get-Date -Format u)  pngs=$pngCount" | Tee-Object -FilePath $log -Append
exit 0
