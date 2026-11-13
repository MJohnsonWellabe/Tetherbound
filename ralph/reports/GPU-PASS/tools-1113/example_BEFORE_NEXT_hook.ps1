# 13 Nov ~06:00 (coordinator): two F38 close-out arms at the FRONT (next free slot): things-hallmoss (F38#28) then things-telldust2 (F38#3 Medium,
# F38#28 High). Both 0.03 short. Gated on overlook-join-perches, the next vb_Gcheck listing; re-arms at any other caller.
# Camera pairing with ONE arm retry per preset when a scored frame misses (coordinator 13 Nov). Hallmoss no-loss (Solene dialogue, F38#20 approach)
# waits for the by-eye check on Warden 03 and is queued separately.
if ($Id -ne "below6-overlook-join-perches") {
    "== BEFORE_NEXT_1 closeouts: caller $Id is not overlook-join-perches; re-armed"
    Copy-Item $MyInvocation.MyCommand.Path "D:\tb-gpu-runs\BEFORE_NEXT_1_closeouts.ps1" -Force
    return
}
$keepTo = $env:TB_RUN_TIMEOUT_MIN
$py = "C:\Users\mattj\AppData\Local\Programs\Python\Python312\python.exe"
$A = "D:\tb-gpu-runs\arms"
$env:TB_RUN_TIMEOUT_MIN = "30"
git -C D:\tb-gpu-wt-crA fetch -q origin tb/things
function Retry-Once($entryFile, $idBase, $section, $armSpec, $frames) {
    foreach ($pr in "Medium", "High") {
        $lp = $pr.ToLower()
        & $py "D:\tb-gpu-runs\tools\pair_frames.py" --base "$A\R1108-G-$section\base-$pr\frames" --arm "$A\R1108-G-$section\arm-$pr\frames" --frames $frames
        if ($LASTEXITCODE -eq 0) { "== $section $pr pairs matched"; continue }
        "== $section $pr arm retry (one, capped)"
        & "D:\tb-gpu-runs\tools\vb_Gcheck.ps1" -Id "$idBase-$lp" -Section "$section-armtry1-$lp" -Biome "meadows" -EntryFile $entryFile -Arms @($armSpec)
        & $py "D:\tb-gpu-runs\tools\pair_frames.py" --base "$A\R1108-G-$section\base-$pr\frames" --arm "$A\R1108-G-$section\arm-$pr\frames,$A\R1108-G-$section-armtry1-$lp\arm-$pr\frames" --frames $frames --json "D:\tb-gpu-runs\eye\$section-pairs-$pr.json"
    }
}
# 1) things-hallmoss on tb/things 2f1475db9.
"== BEFORE_NEXT_1: things-hallmoss $(Get-Date -Format 'HH:mm') (caller $Id)"
$hm = (git -C D:\tb-gpu-wt-crA rev-parse "2f1475db9^{commit}").Trim()
if ($hm.Length -eq 40) {
    $td1 = "%${hm}:ralph/reports/LANES/THINGS-TELLDUST/overlay_tell_dust.json"
    $hArm = "arm=$hm|$td1|%${hm}:ralph/reports/LANES/THINGS-HALLMOSS/overlay_hall_moss.json"
    & "D:\tb-gpu-runs\tools\vb_Gcheck.ps1" -Id "hallmoss-warden" -Section "things-hallmoss" -Biome "meadows" -EntryFile "D:\tb-gpu-runs\entry_hallmoss.json" -Arms @("base=$hm|$td1", $hArm)
    Retry-Once "D:\tb-gpu-runs\entry_hallmoss.json" "hallmoss-warden" "things-hallmoss" $hArm "warden_aldis-03.png,warden_aldis-05.png,warden_aldis-r16.png,warden_aldis-a03.png"
} else { "== hallmoss: 2f1475db9 not reachable; skipped (report it)" }
"== things-hallmoss finished $(Get-Date -Format 'dd MMM HH:mm')"
# 2) things-telldust2 on tb/things 303115335.
"== BEFORE_NEXT_1: things-telldust2 $(Get-Date -Format 'HH:mm')"
$t2 = (git -C D:\tb-gpu-wt-crA rev-parse "303115335^{commit}").Trim()
if ($t2.Length -eq 40) {
    $r1 = "%${t2}:ralph/reports/LANES/THINGS-TELLDUST/overlay_tell_dust.json"
    $tArm = "arm=$t2|$r1|%${t2}:ralph/reports/LANES/THINGS-TELLDUST2/overlay_tell_dust_low.json"
    & "D:\tb-gpu-runs\tools\vb_Gcheck.ps1" -Id "telldust2-meadows" -Section "things-telldust2" -Biome "meadows" -EntryFile "D:\tb-gpu-runs\entry_telldust2.json" -Arms @("base=$t2|$r1", $tArm)
    Retry-Once "D:\tb-gpu-runs\entry_telldust2.json" "telldust2-meadows" "things-telldust2" $tArm "south_bridge_grunt-01.png,south_bridge_grunt-02.png,south_bridge_grunt-03.png,warden_aldis-03.png,warden_aldis-05.png,warden_aldis-r16.png,warden_aldis-a03.png"
} else { "== telldust2: 303115335 not reachable; skipped (report it)" }
"== things-telldust2 finished $(Get-Date -Format 'dd MMM HH:mm')"
$env:TB_RUN_TIMEOUT_MIN = $keepTo
