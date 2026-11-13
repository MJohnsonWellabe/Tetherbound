# 9 Nov: publish one section held by vb_Garm -NoPush after its eye check. Stages only that section's files.
param([Parameter(Mandatory)] [string] $Id, [string] $Preset = "High")
$fr = "D:\tb-gpu-frames-1108"; $s = "G-$Id"
git -C $fr add -f -- "gpu-frames-1108/$s" "gpu-frames-1108/manifest-$s.json" "gpu-frames-1108/blank-$s-*.txt" 2>$null | Out-Null
$n = @(git -C $fr diff --cached --name-only).Count
if ($n -eq 0) { "  nothing staged for $s"; exit 1 }
git -C $fr commit -q -m "frames 1108 re-score section ${s}: $n files ($Preset 1920 JPEG q85)" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
# 12 Nov: take this section's own commit now; HEAD after the push can be a later section committed by a parallel runner.
$mine = (git -C $fr rev-parse HEAD).Trim()
for ($i = 1; $i -le 3; $i++) { git -C $fr push -q origin tb/gpu-frames-1108 2>&1 | Out-Null; if ($LASTEXITCODE -eq 0) { break }; Start-Sleep 30 }
"  PUSHED $s ($n files) -> $mine exit=$LASTEXITCODE"
