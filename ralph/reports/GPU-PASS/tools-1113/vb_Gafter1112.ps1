# 12 Nov ~20:15: runs after vb_Gtail.ps1 ("== tail finished"). 1) below6-fulgocobra r2 (tb/below6 ba924ea82; its two fulgocobra textures differ from
# 1095069bb, so the marker is left alone and vb_Gcheck imports). 2) every D:\tb-gpu-runs\AFTER_*.ps1, in name order, read when reached, so later work
# (cloudnight on tb/things + main@#941) can be dropped in while this waits or runs. Each AFTER file is moved to ran-AFTER_* before it runs.
$t = "D:\tb-gpu-runs\tools"; $mk = "D:\tb-gpu-runs\crA_imported_sha.txt"
while (-not (Select-String -Path "D:\tb-gpu-runs\tail.log" -Pattern "== tail finished" -Quiet -ErrorAction SilentlyContinue)) { Start-Sleep 30 }
while (Get-Process Godot* -ErrorAction SilentlyContinue) { Start-Sleep 10 }
$keepMark = (Get-Content $mk -Raw).Trim()
git -C D:\tb-gpu-wt-crA fetch -q origin tb/below6
$f2 = (git -C D:\tb-gpu-wt-crA rev-parse "ba924ea82^{commit}").Trim()
$env:TB_RUN_TIMEOUT_MIN = "30"
& "$t\vb_Gcheck.ps1" -Id "below6-fulgocobra-r2-pair" -Section "below6-fulgocobra-r2-pair" -Biome "stormwood" -EntryFile "D:\tb-gpu-runs\entry_fulgocobra_r2.json" -Arms @("base=$f2", "arm=$f2|%${f2}:ralph/reports/LANES/BELOW6-FULGOCOBRA/overlay.json")
& "$t\vb_Gcheck.ps1" -Id "below6-fulgocobra-r2-poses" -Section "below6-fulgocobra-r2-poses" -Biome "stormwood" -EntryFile "D:\tb-gpu-runs\entry_fulgocobra_r2.json" -Arms @("base=$f2", "arm=$f2|%${f2}:ralph/reports/LANES/BELOW6-FULGOCOBRA/overlay.json")
"== below6-fulgocobra-r2 finished $(Get-Date -Format 'dd MMM HH:mm')"
Set-Content -Path $mk -Value $keepMark -Encoding ascii
foreach ($af in @(Get-ChildItem "D:\tb-gpu-runs\AFTER_*.ps1" -ErrorAction SilentlyContinue | Sort-Object Name)) {
    $ran = "D:\tb-gpu-runs\ran-$($af.BaseName)-$(Get-Date -Format 'HHmmss').ps1"; Move-Item $af.FullName $ran -Force
    "== AFTER: $($af.Name) $(Get-Date -Format 'HH:mm')"; & $ran
}
"== after1112 finished $(Get-Date -Format 'dd MMM HH:mm')"
