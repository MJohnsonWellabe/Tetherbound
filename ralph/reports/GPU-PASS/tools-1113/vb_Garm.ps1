# 9 Nov (coordinator): one config-overlay entry from gpu_queue.json. -Arms are arm_run specs ("tag=<sha40>" or "tag=<sha40>|<file>|<key>|<json>|..."), -Frames the job.json ids.
# Captures on the imported tree, packs with the null and sky checks, pushes to tb/gpu-frames-1108 (owner yes in chat 8 Nov) as section G-<id>.
# -NoPush stops after packing (an entry that needs an eye check first); the frames then wait uncommitted in the frames worktree.
param([Parameter(Mandatory)] [string] $Id, [Parameter(Mandatory)] [string[]] $Arms, [Parameter(Mandatory)] [string[]] $Frames, [string] $Preset = "High", [string] $Note = "", [switch] $NoPush)
# A BEFORE_<Id>.ps1 file runs once ahead of this entry, so a close-out candidate can jump a sequence already running.
# 12 Nov: a SKIP_<Id> file skips this run once (it was already run out of order by a hook).
if (Test-Path "D:\tb-gpu-runs\SKIP_$Id") { Remove-Item "D:\tb-gpu-runs\SKIP_$Id"; "== G-$Id skipped by SKIP file (already run)"; exit 0 }
$hook = "D:\tb-gpu-runs\BEFORE_$Id.ps1"; if (Test-Path $hook) { $hookRan = "D:\tb-gpu-runs\ran-BEFORE_$Id.ps1"; Move-Item $hook $hookRan -Force; & $hookRan }
$arm = "D:\tb-gpu-runs\tools\arm_run.ps1"; $py ="C:\Users\mattj\AppData\Local\Programs\Python\Python312\python.exe"; $root = "D:\tb-gpu-runs\frames-1108"; $fr = "D:\tb-gpu-frames-1108"
$env:TB_NOHOLD = "1"; $env:TB_RUN_TIMEOUT_MIN = "30"; $env:TB_GRADE_VARIANT = ""; $env:TB_FORCE_MATTE = ""; $env:TB_NL_OUT = ""
$env:PACK_LABEL = ""; $env:PACK_ROOT = ""; $env:PACK_PRESET = $Preset; $env:PACK_NOTE = $Note
$sha = $Arms[0].Split("=", 2)[1].Split("|")[0]
$env:TB_ITEMS_ROOT = "D:\tb-gpu-runs\itemscores-G-$($sha.Substring(0,9))"
# A tree no vb_G run has used yet: build its job folder as vb_G.ps1 does.
if (-not (Test-Path "$env:TB_ITEMS_ROOT\job.json")) {
    New-Item -ItemType Directory -Force $env:TB_ITEMS_ROOT | Out-Null
    cmd /c "git -C D:\tb-gpu-pass show ${sha}:ralph/reports/VISUAL/item-scores/job.json > $env:TB_ITEMS_ROOT\job.json"
    & $py "D:\tb-gpu-runs\tools\build_cmds.py" "$env:TB_ITEMS_ROOT\job.json" $env:TB_ITEMS_ROOT
}
$doc = Get-Content "$env:TB_ITEMS_ROOT\job.json" -Raw | ConvertFrom-Json
$names = @(foreach ($b in $doc.biomes.PSObject.Properties) { foreach ($it in $b.Value.items) { if (@($it.frames | Where-Object { $Frames -contains $_.id }).Count) { $it.item } } }) | Select-Object -Unique
if (-not @($names).Count) { "== G-$Id : no job.json item has these frames; not capturing"; exit 1 }
$s = "G-$Id"; $j = "R1108-$s"
"== $s start $(Get-Date -Format 'dd MMM HH:mm'): $(@($Frames).Count) frames, items $($names -join ','), tree $($sha.Substring(0,9))"
& $arm -Job $j -Items @($names) -Frames $Frames -Arms $Arms -Presets $Preset
$pack = @()
foreach ($a in $Arms) {
    $tag = $a.Split("=", 2)[0]; $pack += "$tag=$sha"
    $dest = "$root\$s\$tag\$Preset"
    & $py "D:\tb-gpu-runs\tools\vb_export.py" arms "D:\tb-gpu-runs\arms\$j\$tag-$Preset" $dest
    $scan = @(& $py "D:\tb-gpu-runs\tools\blank_scan.py" $dest)
    $scan | Set-Content "$dest\_blank.txt" -Encoding utf8
    $scan | Where-Object { $_ -match '^(BLANK|blank frames)' } | ForEach-Object { "  $s $tag $_" }
    # A script error can still leave a valid-looking frame (b5a5aabb9, 9 Nov), so list where each one hit.
    Get-ChildItem "D:\tb-gpu-runs\arms\$j\$tag-$Preset" -Recurse -Filter "*.err.log" | Select-String -Pattern "SCRIPT ERROR" -Context 0,1 | ForEach-Object { $_.Context.PostContext } | Group-Object | ForEach-Object { "  $s $tag SCRIPT ERROR x$($_.Count) $($_.Name.Trim())" }
}
& $py "D:\tb-gpu-runs\tools\pack_1108.py" $s @pack
if ($NoPush) { "  HELD for eye check, not pushed: $s"; "== $s captured $(Get-Date -Format 'dd MMM HH:mm')"; return }
# Stage only this section's own files: a -NoPush section held for an eye check sits uncommitted in the same worktree (9 Nov).
git -C $fr add -f -- "gpu-frames-1108/$s" "gpu-frames-1108/manifest-$s.json" "gpu-frames-1108/blank-$s-*.txt" 2>$null | Out-Null
$n = @(git -C $fr diff --cached --name-only).Count
if ($n -eq 0) { "  nothing staged for $s (held or empty)"; exit 1 }
git -C $fr commit -q -m "frames 1108 re-score section ${s}: $n files ($Preset 1920 JPEG q85)" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
# 12 Nov: take this section's own commit now; HEAD after the push can be a later section committed by a parallel push.
$mine = (git -C $fr rev-parse HEAD).Trim()
for ($i = 1; $i -le 3; $i++) { git -C $fr push -q origin tb/gpu-frames-1108 2>&1 | Out-Null; if ($LASTEXITCODE -eq 0) { break }; Start-Sleep 30 }
"  PUSHED $s ($n files) -> $mine exit=$LASTEXITCODE"
"== $s done $(Get-Date -Format 'dd MMM HH:mm')"
