# Item arm runner (coordinator GPU queue, 31 Oct). Re-shoots the job.json repro commands for a list of catalogue items on each arm
# (a 40-hex SHA) at each preset, on the GPU renderer for that preset (run_tool.ps1: Forward+/Vulkan for Medium/High, isolated APPDATA).
# Per command: drop the repro's opengl3/resolution engine args, add --fullscreen (phase-2 viewport check), --source-commit=<sha> on every
# capture, --preset=<pr> for tools that read it (lookdev_capture_bootstrap), plus -Extra args (e.g. --gamepad). Output goes to the tool's
# required res://ralph/reports/VISUAL/phase2/<biome>/gpu-arms/... folder, then moves to D:\tb-gpu-runs\arms\<Job>\<arm>-<pr>\<biome>-<key>.
# Usage: arm_run.ps1 -Job SW041 -Items P2-041 -Arms "ctl=<sha40>","cand=<sha40>" [-Presets Medium,High] [-Extra --gamepad]
param([Parameter(Mandatory)] [string] $Job, [Parameter(Mandatory)] [string[]] $Items, [Parameter(Mandatory)] [string[]] $Arms,
      # Owner 31 Oct ("judge High first"): High only by default; add -Presets Medium for an arm whose High maps >= 7.5.
      [string[]] $Presets = @("High"), [string[]] $Extra = @(), [string[]] $Frames = @(), [switch] $DryRun)
$run = "D:\tb-gpu-runs\tools\run_tool.ps1"; $out = "D:\tb-gpu-runs\out"; $crA = "D:\tb-gpu-wt-crA"
$godot = "C:\Users\mattj\.cache\tetherbound-tools\godot-4.7\Godot_v4.7-stable_win64_console.exe"
# Rolling batches (coordinator 1 Nov): a waiting tb/vis-batch-<N> may interrupt a long run between blocks. vb_roll.ps1 raises
# HOLD_MAIN; the next arm_run of the long run parks here (HELD_MAIN tells vb_roll the GPU is free) until the hold is lifted. The batch's
# own arm_run calls set TB_NOHOLD=1.
if (-not $DryRun -and $env:TB_NOHOLD -ne "1" -and (Test-Path "D:\tb-gpu-runs\HOLD_MAIN")) {
    "  held for a rolling batch $(Get-Date -Format HH:mm)"; Set-Content "D:\tb-gpu-runs\HELD_MAIN" "$Job" -Encoding ascii
    while (Test-Path "D:\tb-gpu-runs\HOLD_MAIN") { Start-Sleep 20 }
    Remove-Item "D:\tb-gpu-runs\HELD_MAIN" -ErrorAction SilentlyContinue; "  resumed $(Get-Date -Format HH:mm)"
}
$env:TB_RUN_TIMEOUT_MIN = "30"
. "D:\tb-gpu-runs\tools\co_lib.ps1"
$root = if ($env:TB_ITEMS_ROOT) { $env:TB_ITEMS_ROOT } else { "D:\tb-gpu-runs\itemscores" }; $jroot = "D:\tb-gpu-runs\arms\$Job"; New-Item -ItemType Directory -Force $jroot | Out-Null
# PowerShell names are case-insensitive: never call this $job, or it replaces the -Job parameter.
$jobDoc = Get-Content "$root\job.json" -Raw | ConvertFrom-Json
$fmap = Get-Content "$root\frame_to_cmd.json" -Raw | ConvertFrom-Json
# PS 5.1 ConvertFrom-Json emits a JSON array as ONE object; enumerate it into a biome|key lookup.
$cmdBy = @{}
foreach ($f in "cmds.json", "cmds_extra.json") { (Get-Content "$root\$f" -Raw | ConvertFrom-Json) | ForEach-Object { $_ } | ForEach-Object { $cmdBy["$($_.biome)|$($_.key)"] = $_ } }
$presetTools = @("phase2_capture_build_systems", "phase2_capture_catch", "phase2_capture_cloudreach_ride", "phase2_capture_creatures",
    "phase2_capture_locations", "phase2_capture_realm_flight", "phase2_capture_stormheart_decks", "phase2_capture_stormwood_fights",
    "phase2_capture_stormwood_people", "phase2_capture_ui", "phase2_capture_world_inventory")
# Tools that extend phase2_capture_locations.gd and accept a repeatable --subset (checked 31 Oct on the queue trees).
$multiSubsetTools = @("phase2_capture_locations", "phase2_capture_world_inventory", "phase2_capture_characters", "phase2_capture_dialogue",
    "phase2_capture_routes", "phase2_capture_stormwood_glass_sink", "phase2_capture_creatures")
# Args a grouped launch merges instead of keying on (1 Nov batch driver): --subset repeats; --times/--views/--only take the comma union
# (the locations family splits both on ",", phase2_capture_creatures splits --only on ","). A union shoots a few extra frames; harmless.
$mergeArgs = @{ phase2_capture_locations = @("--subset=", "--spot=", "--times=", "--views="); phase2_capture_stormwood_glass_sink = @("--subset=", "--times=", "--views=");
    phase2_capture_creatures = @("--only=") }
function MergeKeys($tool) { if ($mergeArgs.ContainsKey($tool)) { $mergeArgs[$tool] } else { @("--subset=") } }
function IsMerged($arg, $tool) { foreach ($p in (MergeKeys $tool)) { if ($arg.StartsWith($p)) { return $true } }; return $arg.StartsWith("--output=") -or $arg.StartsWith("--out=") }
function MergedArgs($users, $tool) {
    $outA = @()
    foreach ($p in (MergeKeys $tool)) {
        $vals = @($users | ForEach-Object { $_ } | Where-Object { $_.StartsWith($p) } | ForEach-Object { $_.Substring($p.Length) })
        if ($p -eq "--subset=" -or $p -eq "--spot=") { $outA += @($vals | Select-Object -Unique | ForEach-Object { "$p$_" }) }
        elseif ($vals.Count) { $outA += "$p" + (@($vals | ForEach-Object { $_.Split(",") } | Where-Object { $_ } | Select-Object -Unique) -join ",") }
    }
    return , $outA
}

# The commands these items need (deduplicated by biome + key), and the item -> frame map for the builder.
$need = [ordered]@{}; $index = @()
foreach ($b in $jobDoc.biomes.PSObject.Properties) {
    foreach ($it in $b.Value.items) {
        if ($Items -notcontains $it.item) { continue }
        foreach ($f in $it.frames) {
            if ($Frames.Count -gt 0 -and $Frames -notcontains $f.id) { continue }
            $k = $fmap.($b.Name).($f.id); $need["$($b.Name)|$k"] = $true
            $index += [ordered]@{ item = $it.item; biome = $b.Name; frame = $f.id; cmd = $k; subject = $it.subject; defect = $it.defect; board_row = $it.board_row }
        }
    }
}
# Rolling-batch manifests name stands directly: a requested frame that is not one of the items' job.json sightings but has a repro
# command in frame_to_cmd.json is captured too (item "manifest").
foreach ($f in $Frames) {
    if (@($index | Where-Object { $_.frame -eq $f }).Count) { continue }
    foreach ($b in $fmap.PSObject.Properties) {
        $k = $b.Value.$f
        if ($k) { $need["$($b.Name)|$k"] = $true; $index += [ordered]@{ item = "manifest"; biome = $b.Name; frame = $f; cmd = $k; subject = ""; defect = ""; board_row = "" }; break }
    }
}
[IO.File]::WriteAllText("$jroot\items.json", (ConvertTo-Json -InputObject @($index) -Depth 4))
"== $Job : $($Items.Count) item(s), $($index.Count) frame(s), $($need.Count) command(s), arms $($Arms -join ' '), presets $($Presets -join ',')"
if ($index.Count -eq 0) { "NO FRAMES for $Job; not capturing"; exit 1 }
if ($DryRun) {
    foreach ($nk in $need.Keys) {
        $c = $cmdBy[$nk]; "  $nk : $($c.args -join ' ')"
    }
    $pg = @{}
    foreach ($nk in $need.Keys) {
        $gc = $cmdBy[$nk]; $gsi = [array]::IndexOf($gc.args, "--script"); $gtool = [IO.Path]::GetFileNameWithoutExtension($gc.args[$gsi + 1])
        if ($multiSubsetTools -notcontains $gtool) { continue }
        $gui = [array]::IndexOf($gc.args, "--"); $guser = @($gc.args[($gui + 1)..($gc.args.Count - 1)])
        $gk = "$($nk.Split('|')[0])|$gtool|" + (@($guser | Where-Object { -not (IsMerged $_ $gtool) }) -join ' ')
        if (-not $pg.ContainsKey($gk)) { $pg[$gk] = @() }; $pg[$gk] += $nk
    }
    foreach ($gk in $pg.Keys) { if (@($pg[$gk]).Count -ge 2) { "  GROUP x$(@($pg[$gk]).Count): $(($gk -split '\|')[0..1] -join ' ') <- $(($pg[$gk] | ForEach-Object { $_.Split('|')[1] }) -join ',')" } }
    exit 0
}

# An arm is "tag=<sha40>" or, for a flag-flip arm on the same tree, "tag=<sha40>|<repo-relative json>|<dotted.key>|<json value>"
# (coordinator 31 Oct: JSON is read at runtime, so a flip needs no re-import). CleanCrA's forced checkout restores the file.
$py = "C:\Users\mattj\AppData\Local\Programs\Python\Python312\python.exe"
$importMark = "D:\tb-gpu-runs\crA_imported_sha.txt"
foreach ($armSpec in $Arms) {
    $tag, $rest = $armSpec.Split("=", 2)
    $sha, $flips = $rest.Split("|", 2)
    if ($sha -notmatch '^[0-9a-f]{40}$') { "ARM $tag needs a 40-hex SHA, got '$sha'; stopping"; exit 1 }
    Gate "$Job $tag"
    CheckoutCrA $sha
    # tb/capture-speed in the tree: Cloudreach launches reuse a ground-cover cache (coordinator 1 Nov; same instances, ~6 min less a boot)
    $hasCS = HasCS $sha
    $marked = if (Test-Path $importMark) { (Get-Content $importMark -Raw).Trim() } else { "" }
    if ($marked -eq $sha) { "  crA already imported at $($sha.Substring(0,9)); no re-import" }
    else { $ir = Import $crA "crA-$Job-$tag"; $ir; if ("$ir" -match "exit=0$") { Set-Content -Path $importMark -Value $sha -Encoding ascii } else { "IMPORT FAILED for $tag at $($sha.Substring(0,9)); skipping this arm"; continue } }
    foreach ($pr in $Presets) {
        Gate "$Job $tag $pr"
        CleanCrA $sha
        # Controller prompts on every side (coordinator 9 Nov, after keyboard glyphs in G-pilot-mark arm r1). TB_PAD_GLYPHS=0 turns it off.
        if ($env:TB_PAD_GLYPHS -ne "0") { $pg = & $py "D:\tb-gpu-runs\tools\pad_glyphs.py" $crA; "  $pg"; if ($LASTEXITCODE -ne 0) { "  PAD GLYPHS NOT APPLIED for $tag $pr" } }
        if ($flips) {
            # Tokens: "@<sha>:<repo path>" copies that file's exact bytes from the candidate branch; otherwise a file|key|value triple.
            $fs = @($flips.Split("|")); $i = 0
            while ($i -lt $fs.Count) {
                if ($fs[$i].StartsWith("@")) {
                    $src, $rp = $fs[$i].Substring(1).Split(":", 2)
                    $o = & $py "D:\tb-gpu-runs\tools\json_flip.py" --from $src $rp $crA; $desc = "$rp <- $src"; $i += 1
                } elseif ($fs[$i].StartsWith("%")) {
                    # "%<sha>:<repo path>" deep-merges an overlay json from that commit ({file: {nested keys}}); new keys are allowed, unlike a triple.
                    $src, $rp = $fs[$i].Substring(1).Split(":", 2)
                    $o = & $py "D:\tb-gpu-runs\tools\json_flip.py" --overlay $src $rp $crA; $desc = "overlay $rp <- $src"; $i += 1
                } elseif ($i + 2 -lt $fs.Count) {
                    $o = & $py "D:\tb-gpu-runs\tools\json_flip.py" (Join-Path $crA ($fs[$i] -replace '/', '\')) $fs[$i + 1] $fs[$i + 2]
                    $desc = "$($fs[$i]) $($fs[$i + 1]) = $($fs[$i + 2])"; $i += 3
                } else { "FLIP SPEC for $tag is malformed at '$($fs[$i])'; stopping"; exit 1 }
                "  $o"; if ($LASTEXITCODE -ne 0) { "FLIP FAILED for $tag; stopping"; exit 1 }
                ([ordered]@{ job = $Job; arm = $tag; preset = $pr; flip = $desc; receipt = "$o" } | ConvertTo-Json -Compress) | Add-Content "$jroot\flips.jsonl"
            }
            $dirty = @(git -C $crA status --porcelain --untracked-files=no 2>$null)
            "  dirty after flip: $($dirty.Count) $($dirty -join '; ')"
        }
        # One boot, many frames (coordinator throughput note, 31 Oct): commands for the same locations-family tool and biome that differ
        # only in --subset run as ONE launch with every subset; each member's folder then gets the group's frames (the resolver matches by
        # frame id). If the group run yields no images, the members fall through to the one-by-one loop below.
        $groups = @{}
        foreach ($nk in $need.Keys) {
            $gc = $cmdBy[$nk]; if (-not $gc) { continue }
            if (Test-Path "$jroot\$tag-$pr\$($nk.Replace('|','-'))\_done") { continue }
            $gsi = [array]::IndexOf($gc.args, "--script"); $gtool = [IO.Path]::GetFileNameWithoutExtension($gc.args[$gsi + 1])
            if ($multiSubsetTools -notcontains $gtool) { continue }
            $gui = [array]::IndexOf($gc.args, "--"); $guser = @($gc.args[($gui + 1)..($gc.args.Count - 1)])
            $rest = @($guser | Where-Object { -not (IsMerged $_ $gtool) }) -join ' '
            $gk = "$($nk.Split('|')[0])|$gtool|$rest"
            if (-not $groups.ContainsKey($gk)) { $groups[$gk] = @() }
            $groups[$gk] += $nk
        }
        foreach ($gk in $groups.Keys) {
            $members = @($groups[$gk]); if ($members.Count -lt 2) { continue }
            $gbiome = $gk.Split("|")[0]; $first = $cmdBy[$members[0]]
            $gsi = [array]::IndexOf($first.args, "--script"); $gscript = $first.args[$gsi + 1]; $gtool = [IO.Path]::GetFileNameWithoutExtension($gscript)
            $gui = [array]::IndexOf($first.args, "--"); $guser = @($first.args[($gui + 1)..($first.args.Count - 1)])
            $allUser = @($members | ForEach-Object { $m = $cmdBy[$_]; $mu = [array]::IndexOf($m.args, "--"); @($m.args[($mu + 1)..($m.args.Count - 1)]) })
            $subs = MergedArgs $allUser $gtool
            $gname = "_grp-$gbiome-$($members[0].Split('|')[1])"; $gdest = "$jroot\$tag-$pr\$gname"
            $grel = "ralph/reports/VISUAL/phase2/$gbiome/gpu-arms/$Job-$tag-$pr-grp-$($members[0].Split('|')[1])"
            $gua = @($guser | Where-Object { -not (IsMerged $_ $gtool) -or $_.StartsWith("--output=") -or $_.StartsWith("--out=") } | ForEach-Object { $_.Replace("{OUT}", "res://$grel") }) + $subs + @("--source-commit=$sha")
            if ($presetTools -contains $gtool) { $gua += "--preset=$pr" }
            $gua += $Extra
            if ($gbiome -eq "cloudreach" -and $hasCS) { $gua += "--ground-cover-cache" }
            for ($try = 1; $try -le 2; $try++) {
                $gabs = Join-Path $crA ($grel -replace '/', '\'); if (Test-Path $gabs) { cmd /c "rmdir /s /q `"$gabs`"" }
                if (Test-Path $gdest) { if ($try -gt 1) { Move-Item $gdest "$gdest.try$($try - 1)" -Force -ErrorAction SilentlyContinue } else { Remove-Item $gdest -Recurse -Force } }
                $t = Get-Date
                $r = & $run -Preset $pr -Script "res://$gscript" -OutDir $gdest -Resolution "1920x1080" -ProjectPath $crA -GodotArgs @("--fullscreen") -UserArgs $gua
                if (Test-Path $gabs) { New-Item -ItemType Directory -Force "$gdest\frames" | Out-Null; Move-Item "$gabs\*" "$gdest\frames\" -Force; cmd /c "rmdir /s /q `"$gabs`"" }
                $gimgs = @(Get-ChildItem "$gdest\frames" -Recurse -File -Include *.png, *.jpg -ErrorAction SilentlyContinue).Count
                $sec = [int]((Get-Date) - $t).TotalSeconds
                "[$tag $pr] GROUP $gbiome $gtool x$($members.Count) ($($subs.Count) subsets) try=$try $r images=$gimgs sec=$sec"
                ([ordered]@{ job = $Job; arm = $tag; preset = $pr; biome = $gbiome; key = $gname; members = $members; try = $try; images = $gimgs; sec = $sec } | ConvertTo-Json -Compress) | Add-Content "$jroot\runlog.jsonl"
                if ($gimgs -gt 0) {
                    foreach ($m in $members) {
                        $md = "$jroot\$tag-$pr\$($m.Replace('|','-'))"; if (Test-Path $md) { Remove-Item $md -Recurse -Force }
                        New-Item -ItemType Directory -Force $md | Out-Null; Copy-Item "$gdest\frames" "$md\frames" -Recurse -Force
                        Set-Content "$md\_grouped.txt" "frames from one grouped launch: $gname" -Encoding ascii; New-Item -ItemType File -Force "$md\_done" | Out-Null
                    }
                    break
                }
            }
        }
        foreach ($nk in $need.Keys) {
            $biome, $key = $nk.Split("|")
            $dest = "$jroot\$tag-$pr\$biome-$key"
            if (Test-Path "$dest\_done") { continue }
            $c = $cmdBy[$nk]; if (-not $c) { "NO COMMAND for $nk; skipping"; continue }
            # Several catalogue frames share one identical command (e.g. every catch frame); shoot it once, copy its frames.
            $twin = $need.Keys | Where-Object { $_ -ne $nk -and $_.Split("|")[0] -eq $biome -and (($cmdBy[$_].args -join ' ') -eq ($c.args -join ' ')) -and (Test-Path "$jroot\$tag-$pr\$($_.Replace('|','-'))\_done") } | Select-Object -First 1
            if ($twin) {
                Copy-Item "$jroot\$tag-$pr\$($twin.Replace('|','-'))" $dest -Recurse -Force
                "[$tag $pr] $biome $key = same command as $twin, frames copied"; continue
            }
            # ...and an identical command that already failed both tries in this run is not shot again (1 Nov: Cloudreach catch twins).
            $failedTwin = $need.Keys | Where-Object { $_ -ne $nk -and $_.Split("|")[0] -eq $biome -and (($cmdBy[$_].args -join ' ') -eq ($c.args -join ' ')) -and (Test-Path "$jroot\$tag-$pr\$($_.Replace('|','-')).try1") -and -not (Test-Path "$jroot\$tag-$pr\$($_.Replace('|','-'))\_done") -and (Test-Path "$jroot\$tag-$pr\$($_.Replace('|','-'))") } | Select-Object -First 1
            if ($failedTwin) {
                "[$tag $pr] $biome $key = same command as $failedTwin, which failed twice; skipped"; continue
            }
            $si = [array]::IndexOf($c.args, "--script"); $script = $c.args[$si + 1]; $tool = [IO.Path]::GetFileNameWithoutExtension($script)
            $ui = [array]::IndexOf($c.args, "--"); $user = @($c.args[($ui + 1)..($c.args.Count - 1)])
            $rel = "ralph/reports/VISUAL/phase2/$biome/gpu-arms/$Job-$tag-$pr-$key"
            $ua = @($user | ForEach-Object { $_.Replace("{OUT}", "res://$rel") }) + @("--source-commit=$sha")
            if ($presetTools -contains $tool) { $ua += "--preset=$pr" }
            $ua += $Extra
            if ($biome -eq "cloudreach" -and $hasCS) { $ua += "--ground-cover-cache" }
            for ($try = 1; $try -le 2; $try++) {
                $abs = Join-Path $crA ($rel -replace '/', '\'); if (Test-Path $abs) { cmd /c "rmdir /s /q `"$abs`"" }
                # Keep a failed attempt's logs for diagnosis (31 Oct: a hung try was lost when the retry deleted it).
                if (Test-Path $dest) {
                    if ($try -gt 1) {
                        # A just-killed Godot can hold the folder for a few seconds: retry, then fall back to copying the logs.
                        $kept = "$dest.try$($try - 1)"
                        for ($m = 0; $m -lt 5 -and (Test-Path $dest); $m++) { try { Move-Item $dest $kept -Force -ErrorAction Stop } catch { Start-Sleep 5 } }
                        if (Test-Path $dest) { New-Item -ItemType Directory -Force $kept | Out-Null; Copy-Item "$dest\*" $kept -Recurse -Force -ErrorAction SilentlyContinue; Remove-Item $dest -Recurse -Force -ErrorAction SilentlyContinue }
                    } else { Remove-Item $dest -Recurse -Force }
                }
                $t = Get-Date
                # Capture-speed's cheap build frames skip the 3D pass until the world shell is built; phase2_capture_catch does not wait for
                # the Meadows shell, so its frames came out as HUD over a flat fill (1 Nov, batch-3). For that one command, render the build
                # frames as before (performance.json forward_build_cheap_frames=false) and restore the file after the launch.
                $cheapOff = $hasCS -and $biome -eq "meadows" -and $tool -eq "phase2_capture_catch"
                if ($cheapOff) { & $py "D:\tb-gpu-runs\tools\json_flip.py" (Join-Path $crA "data\config\performance.json") "forward_build_cheap_frames" "false" | Out-Null; "  cheap build frames off for $biome $key" }
                $r = & $run -Preset $pr -Script "res://$script" -OutDir $dest -Resolution "1920x1080" -ProjectPath $crA -GodotArgs @("--fullscreen") -UserArgs $ua
                if ($cheapOff) { git -C $crA checkout -q -- data/config/performance.json }
                $code = if ("$r" -match 'exit=(-?\d+)') { [int]$Matches[1] } else { -999 }
                if (Test-Path $abs) { New-Item -ItemType Directory -Force "$dest\frames" | Out-Null; Move-Item "$abs\*" "$dest\frames\" -Force; cmd /c "rmdir /s /q `"$abs`"" }
                $imgs = @(Get-ChildItem "$dest\frames" -Recurse -File -Include *.png, *.jpg -ErrorAction SilentlyContinue).Count
                $sec = [int]((Get-Date) - $t).TotalSeconds
                "[$tag $pr] $biome $key try=$try exit=$code images=$imgs sec=$sec"
                ([ordered]@{ job = $Job; arm = $tag; preset = $pr; biome = $biome; key = $key; try = $try; exit = $code; images = $imgs; sec = $sec } | ConvertTo-Json -Compress) | Add-Content "$jroot\runlog.jsonl"
                if ($imgs -gt 0) { New-Item -ItemType File -Force "$dest\_done" | Out-Null; break }
            }
        }
    }
}
New-Item -ItemType File -Force "$jroot\_done" | Out-Null
"$Job capture done $(Get-Date -Format HH:mm)"
