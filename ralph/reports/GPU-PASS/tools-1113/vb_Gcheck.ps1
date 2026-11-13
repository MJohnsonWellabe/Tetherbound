# 9 Nov (coordinator): one tool run from gpu_queue.json (a kind "check" repro, or an arm's lifecycle capture with -Arms) at each of its presets. Capture only; push with pack_check.py after a look.
# Engine args as in arm_run.ps1: run_tool picks Forward+/Vulkan per preset, the entry's CPU opengl3/resolution args are dropped, --fullscreen for the viewport check.
# -Arms are "tag=<sha40>[|@<sha>:<path>|%<sha>:<overlay>]" and land in <tag>-<preset>; with no -Arms, the entry's head lands in <preset>. -Section publishes under another G-<name>.
# -EntryFile reads the entry from a local json (a tool run an entry only describes in prose) instead of the queue.
param([Parameter(Mandatory)] [string] $Id, [string] $Biome = "tidewake", [string] $Section = "", [string[]] $Arms = @(), [string] $EntryFile = "", [switch] $DryRun)
# A SKIP_<Id> file defers this run once (a running sequence can't be edited; vb_Gstorm3.ps1 shoots it later).
if (Test-Path "D:\tb-gpu-runs\SKIP_$Id") { Remove-Item "D:\tb-gpu-runs\SKIP_$Id"; "== $Id deferred by SKIP file"; exit 0 }
# 12 Nov: a BEFORE_NEXT.ps1 file runs once ahead of the next run (a close-out can jump a running sequence between sides). Moved aside before it runs, so it never repeats.
# Every BEFORE_NEXT*.ps1 runs, in name order; a gated hook sees this call's $Id/$Section and copies itself back to its own name to wait for a later call.
if (-not $DryRun) { foreach ($hf in @(Get-ChildItem "D:\tb-gpu-runs\BEFORE_NEXT*.ps1" -ErrorAction SilentlyContinue | Sort-Object Name)) { $bn = "D:\tb-gpu-runs\ran-$($hf.BaseName)-$(Get-Date -Format 'HHmmss').ps1"; Move-Item $hf.FullName $bn -Force; & $bn } }
$run = "D:\tb-gpu-runs\tools\run_tool.ps1"; $out = "D:\tb-gpu-runs\out"; $crA = "D:\tb-gpu-wt-crA"; $importMark = "D:\tb-gpu-runs\crA_imported_sha.txt"
$godot = "C:\Users\mattj\.cache\tetherbound-tools\godot-4.7\Godot_v4.7-stable_win64_console.exe"; $py = "C:\Users\mattj\AppData\Local\Programs\Python\Python312\python.exe"
if (-not $env:TB_RUN_TIMEOUT_MIN) { $env:TB_RUN_TIMEOUT_MIN = "30" }  # 10 Nov: a caller (vb_Gbase.ps1) may set a longer timeout for big matrices
. "D:\tb-gpu-runs\tools\co_lib.ps1"
$doc = if ($EntryFile) { Get-Content $EntryFile -Raw | ConvertFrom-Json } else { (git -C D:\tb-gpu-pass show origin/ccr-99b76ce0-imf8zn:ralph/reports/COORDINATOR/gpu_queue.json) -join "`n" | ConvertFrom-Json }
$entry = @($doc.entries | Where-Object { $_.id -eq $Id })[0]
if (-not $entry -or ($entry.kind -ne "check" -and $Arms.Count -eq 0)) { "== no runnable entry $Id; not capturing"; exit 1 }
$label = if ($Section) { $Section } else { $Id }
$tool = $entry.tool; $want = @($entry.expected_frames.lifecycle); $presetList = if ($entry.presets) { @($entry.presets) } else { @("High") }
$armList = if ($Arms.Count) { $Arms } else { @("=$($entry.head)") }
$jroot = "D:\tb-gpu-runs\arms\R1108-G-$label"
"== G-$label start $(Get-Date -Format 'dd MMM HH:mm'): $tool, arms $($armList -join ' '), presets $($presetList -join ',')"
foreach ($spec in $armList) {
    $tag, $rest = $spec.Split("=", 2); $sha, $flips = $rest.Split("|", 2)
    if ($sha -notmatch '^[0-9a-f]{40}$') { "== arm '$tag' needs a 40-hex sha, got $sha"; exit 1 }
    if (-not $DryRun) {
        Gate "G-$label $tag"
        CheckoutCrA $sha
        $marked = if (Test-Path $importMark) { (Get-Content $importMark -Raw).Trim() } else { "" }
        if ($marked -eq $sha) { "  crA already imported at $($sha.Substring(0,9))" }
        else { $ir = Import $crA "crA-G-$label"; $ir; if ("$ir" -match "exit=0$") { Set-Content -Path $importMark -Value $sha -Encoding ascii } else { "IMPORT FAILED at $($sha.Substring(0,9))"; exit 1 } }
    }
    foreach ($pr in $presetList) {
        $name = if ($tag) { "$tag-$pr" } else { $pr }
        $dest = "$jroot\$name"; $rel = "ralph/reports/VISUAL/phase2/$Biome/gpu-arms/G-$label-$name"; $abs = Join-Path $crA ($rel -replace '/', '\')
        # A "+<arg>" flip token is a tool arg for that arm only (an entry's arm_extra_args, 9 Nov); {PRESET} and {SHA} fill like {OUT}.
        $plus = @(if ($flips) { $flips.Split("|") | Where-Object { $_.StartsWith("+") } | ForEach-Object { $_.Substring(1) } })
        $ua = @(@($entry.args) | ForEach-Object { $_.Replace("{OUT}", "res://$rel").Replace("{PRESET}", $pr).Replace("{SHA}", $sha) }) + $plus + @("--source-commit=$sha")
        if ($DryRun) { "  [$name] flips: $flips"; "  [$name] $tool -- $($ua -join ' ')"; continue }
        if (Test-Path "$dest\_done") { "[$name] already captured"; continue }
        Gate "G-$label $name"
        CleanCrA $sha
        if ($env:TB_PAD_GLYPHS -ne "0") { $pg = & $py "D:\tb-gpu-runs\tools\pad_glyphs.py" $crA; "  $pg"; if ($LASTEXITCODE -ne 0) { "  PAD GLYPHS NOT APPLIED for $name" } }
        if ($flips) {
            foreach ($t in $flips.Split("|")) {
                if ($t.StartsWith("+")) { continue }
                $src, $rp = $t.Substring(1).Split(":", 2)
                $mode = if ($t.StartsWith("@")) { "--from" } elseif ($t.StartsWith("%")) { "--overlay" } else { "== bad flip token $t"; exit 1 }
                $o = & $py "D:\tb-gpu-runs\tools\json_flip.py" $mode $src $rp $crA; "  $o"
                if ($LASTEXITCODE -ne 0) { "FLIP FAILED for $name; stopping"; exit 1 }
            }
            "  dirty after flip: $(@(git -C $crA status --porcelain --untracked-files=no 2>$null) -join '; ')"
        }
        for ($try = 1; $try -le 2; $try++) {
            if (Test-Path $abs) { cmd /c "rmdir /s /q `"$abs`"" }
            if (Test-Path $dest) { Move-Item $dest "$dest.try$($try - 1)" -Force -ErrorAction SilentlyContinue }
            # An entry's godot_args (engine args such as --fixed-fps 20 for motion strips, 10 Nov) ride after --fullscreen.
            $ga = @("--fullscreen") + @(@($entry.godot_args) | Where-Object { $_ })
            $r = & $run -Preset $pr -Script $tool -OutDir $dest -Resolution "1920x1080" -ProjectPath $crA -GodotArgs $ga -UserArgs $ua
            if (Test-Path $abs) { New-Item -ItemType Directory -Force "$dest\frames" | Out-Null; Move-Item "$abs\*" "$dest\frames\" -Force; cmd /c "rmdir /s /q `"$abs`"" }
            $got = @(foreach ($w in $want) { Get-ChildItem "$dest\frames" -Recurse -File -Filter $w -ErrorAction SilentlyContinue })
            $imgs = @(Get-ChildItem "$dest\frames" -Recurse -File -Include *.png, *.jpg -ErrorAction SilentlyContinue).Count
            "[$name] try=$try $r lifecycle=$($got.Count)/$($want.Count) images=$imgs"
            Get-ChildItem $dest -Recurse -Filter "*.err.log" | Select-String -Pattern "SCRIPT ERROR" -Context 0,1 | ForEach-Object { $_.Context.PostContext } | Group-Object | ForEach-Object { "  [$name] SCRIPT ERROR x$($_.Count) $($_.Name.Trim())" }
            if ($got.Count -eq $want.Count -and $imgs -gt 0) { New-Item -ItemType File -Force "$dest\_done" | Out-Null; break }
        }
    }
}
"== G-$label capture finished $(Get-Date -Format 'dd MMM HH:mm')"
