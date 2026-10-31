# GPU-PASS lane note (owner's Windows desktop, GTX 1060 3GB; 21–22 Oct 2026)

## GPU ARM REQUEST (CREATURES-F36 lane, 31 Oct): CO-F36-4, coat value lift for four dark creatures (flag, High first)

- **Arms:** control main a41e1b3061b27b21cb0c4add6e50b7fd95c95fb4 vs candidate `tb/co-f36-4-on` 529829e882fee4ba71ff0a25f734af2da60051fc.
  - The candidate is main plus a flag-off coat hook in `scripts/creatures/creature_body.gd`, `data/config/creature_coat_flags.json`, and four graded coat PNGs with their `.import` files.
  - With the flag `false` it renders exactly as main.
- **To judge:**
  1. Run one import, for the four new textures.
  2. Set `flags.creatures_f36_coat_lift.enabled` to `true`.
- **Species:** cindercub 7.13, duskhush 6.77 and ashtusk 6.68 (ROSTER-1 "rim light and value lift"), plus thundertunnel 6.49 (CO12: "a dark mound with no readable face").
- **CPU r6** (three judges, confirming, r 0.996): 5.83 -> 6.93, 5.42 -> 6.56, 5.74 -> 6.79, 6.01 -> 6.70. The dark-body defect goes from PRESENT to PARTIAL on all four.
- **Verdict:** `ralph/reports/CREATURES-F36/r6/VERDICT.md` on `tb/creatures-f36`.
- **Capture, High first.** Same tool and flags as the other F36 arms:
  - `capture_f36_poses.gd --whole-body --context --species=cindercub,duskhush --out=<fresh dir> --source-commit=<arm sha>`, plain.
  - `capture_f36_poses.gd --candidate --whole-body --context --species=ashtusk,thundertunnel --out=<fresh dir> --source-commit=<arm sha>`; both play pose recipes.
- **Combining arms:** CO-F36-3 (duskhush taller) and this arm are independent flags and can be enabled together on one tree.
- **Report:**
  - MET at High.
  - The dark-body defect call.
  - Any reserved-red read on Cindercub's embers.

## GPU ARM REQUEST (CREATURES-F36 lane, 31 Oct): CO-F36-3, Duskhush and Brooktail taller than the trainer (flag, High first)

- **Arms:** control main a41e1b3061b27b21cb0c4add6e50b7fd95c95fb4 vs candidate `tb/co-f36-3-on` d13f2db3345f8a72c809ab2c94c7f28062965c26.
  - The candidate is main plus a flag-off scale hook in `scripts/creatures/creature_species.gd` and `data/config/creature_scale_flags.json`.
  - With the flag `false` it renders exactly as main.
- **To judge:** set `flags.creatures_f36_taller_than_trainer.enabled` to `true`. No re-import is needed.
  - Duskhush grows x1.35 (2.3 -> 3.1 m) and Brooktail x1.4 (2.1 -> 2.94 m).
  - Height and collider radius grow together.
- **Why:** ROSTER-1 High has duskhush at 6.77 and brooktail at 6.84; both stand barely above the trainer.
- **CPU r5** (three judges, confirming, r 0.98): duskhush 5.81 -> 6.31, brooktail 5.81 -> 6.56. Both height defects go from PARTIAL x3 to FIXED x3.
- **Verdict:** `ralph/reports/CREATURES-F36/r5/VERDICT.md` on `tb/creatures-f36`.
- **Capture, High first:**
  `godot --path . --rendering-method forward_plus --resolution 1920x1080 --script res://tools/art_pipeline/capture_f36_poses.gd -- --whole-body --context --species=duskhush,brooktail --out=<fresh dir> --source-commit=<arm sha>`
  - Plain run, no `--candidate`: neither species plays a pose recipe.
- **Report:**
  - MET at High.
  - The height defect call.

## GPU ARM REQUEST (CREATURES-F36 lane, 31 Oct): CO-F36-2, Sirenseal grounded hit (flag, High first)

- **Arms:** control main a41e1b3061b27b21cb0c4add6e50b7fd95c95fb4 vs candidate `tb/co-f36-2-on` 505bc2e5ffad9bde51fa9919c2db7f8879af5fa1.
  - The candidate is main plus the flag-off `candidate_role_flags` hook in `scripts/creatures/creature_pose_candidates.gd` and one flag in `data/creatures/f36_pose_candidates.json`.
  - With the flag `false` it renders exactly as main.
- **To judge:** on the candidate tree, set `candidate_role_flags.creatures_f36_sirenseal_grounded_hit.enabled` to `true`.
  - No re-import is needed; the change is code plus JSON only.
- **Why:** ROSTER-1 High has sirenseal at 6.81, with the hit react PARTIAL 3/3 and the whole body leaving the floor.
  - Enabled, land Sirenseal's hit keeps 15% of its pivot rotation and 70% of its body recoil.
  - water_sirenseal (7.27) is untouched.
- **CPU r4** (three judges, confirming, r 0.95): 5.90 -> 7.14 (+1.24), airborne hit FIXED x3.
- **Verdict:** `ralph/reports/CREATURES-F36/r4/VERDICT.md` on `tb/creatures-f36`.
- **Capture, High first:**
  `godot --path . --rendering-method forward_plus --resolution 1920x1080 --script res://tools/art_pipeline/capture_f36_poses.gd -- --candidate --whole-body --context --species=sirenseal,water_sirenseal --out=<fresh dir> --source-commit=<arm sha>`
  - water_sirenseal is a no-change check.
- **Report:**
  - MET at High.
  - The hit defect call.
  - Whether water_sirenseal is unchanged.

## GPU ARM REQUEST (CREATURES-F36 lane, 31 Oct): CO-F36-1, side-lie faints for Cragclaw and Skyrill

- **Arms:** control main 3a0e1fa0d8446c5dffa3359a3c3543fa6ded18ca vs candidate `tb/co-f36-1-on` e5667aecd6e8cdcf66c9a33e9a69df049229b12e.
  - The candidate is main plus one data change: the Cragclaw and Skyrill faint recipes in `data/creatures/f36_pose_candidates.json` roll the body 70 deg onto its side, back to the camera.
  - water_cragclaw plays Cragclaw's recipe.
- **Why:** GPU roster 24 Oct named these defects:
  - Cragclaw 5.87: faint the same as standing.
  - water_cragclaw 6.32: faint poses the same as standing.
  - Skyrill 6.33: faint keeps head and sail up.
- **CPU r2** (three judges, confirming, r 0.90): Cragclaw 5.71 -> 6.24, water_cragclaw 5.71 -> 6.24, Skyrill 6.00 -> 6.53 (+0.53 each). Skyrill's defect is FIXED x3; the crab's is PARTIAL x3 (it tips onto its shell edge).
- **Verdict:** `ralph/reports/CREATURES-F36/r2/VERDICT.md` on `tb/creatures-f36`.
- **Capture,** each arm at its own SHA on a clean tree, Medium and High, standard roster crop:
  `godot --path . --rendering-method forward_plus --resolution 1920x1080 --script res://tools/art_pipeline/capture_f36_poses.gd -- --candidate --whole-body --context --species=cragclaw,water_cragclaw,skyrill --out=<fresh dir> --source-commit=<arm sha>`
  - All three are in `enabled_species`, so `--candidate` installs.
- **High first;** add Medium only if High reaches 7.5.
- **No re-import needed:** the arm changes only `data/creatures/f36_pose_candidates.json` (two recipe lines plus a provenance key). It can be judged on any imported main tree by checking out that one file at e5667aecd.
- **Report:**
  - MET per form per preset.
  - The faint defect calls.
  - Whether the crab's shell-edge tip reads as grounded.

## READY (24 Oct): newest first

- **F38#0 / F26#3 Meadows matrix on main 779422f10.** The matrix evidence is DELIVERED (High 354/528 and Medium 355/528 frames, plus the fight at 84/85). **F26#3 (Meadows) is REOPENED.**
  - **Scores:** no site reaches 7.5. Best: village_road 6.73 High / 7.09 Medium and river_lock_1 6.89 / 6.86. The arch stands score 3.5–5.3.
  - **Fix first:**
    1. Production cameras: clipping is PRESENT at 8 sites, with arch reverse views inside geometry.
    2. Hall white shaft quads and orb chains, plus flat interior grades.
    3. The P2-005 ground carpet, at every exterior site.
    4. The P2-003 stronghold.
    5. River lock 0 blockout.
  - Per-site table and defect scan: `F38-0/main-1024/VERDICT.md`.

- **11:17 CT, creature emission floor overlay (Forward+):**
  - **F22#4 with the overlay:** Medium maps to **7.26** (7.34 / 7.18), against 5.08 shipped and 6.53 for Low. The ghost is FIXED ×3. Medium now beats Low but is still below 7.5; the HUD and the hidden player creature remain.
  - **Day:** the wash was roster-wide (Cindercub, Ripplet, Terrapup, Paddlenewt, Bramblebun, Trailpup, Mudsnout all milky). ×0 restores their true colours.
  - **Night sweep:**
    - ×1, ×0.5 and ×0.25 are all white ghosts;
    - ×0.1 whitens Ripplet;
    - **×0.05 (night floor 0.011) keeps Cindercub readable with no whitening.**
    - **Recommend: base ×0.0, `times.night.environment` ×0.05.**
  - Evidence: `emission-floor/overlay-1024/RESULT.md`.

- **10:45 CT, Tidewake regrade (lt2) on main: REOPENED.**
  - Scores: **6.12** against control 5.35 (CPU 7.07), the same at Medium and High.
  - Evening and dawn grade: FIXED ×3.
  - Still open:
    - the night beach casts nothing (PRESENT ×3);
    - the noon seam is only softened;
    - the Veilfall close-up is `new_art`.
  - Evidence: `F39-look-lt2/main-1024/VERDICT.md`.
  - **Now running:** the emission-floor overlay checks.

- **10:40 CT, Forward+ grade re-measure on main (with #712 Meadows fog 0.001):** luma Medium vs Low:
  - **Meadows 102.6 vs 106.8 (96%, was 87.6)**;
  - **Tidewake 165.2 vs 163.5 (parity)**;
  - Stormwood F10 63.2 vs 73.1 (86%, more saturated).
  - Matched frames read as one look across presets. Evidence: `forward-plus-grade/main-1024/RESULT.md`.
  - **Now running:** the Tidewake regrade capture, then the emission-floor overlay checks (F22#4 at Medium, night and day creatures).

- **10:08 CT, F22#4 Riverwatch on main: REOPENED.**
  - Medium maps to **5.10**, with the ghost still PRESENT ×3; Low maps to **6.39**.
  - **Root cause, isolated on GPU:**
    - not the tell aura (the renderer-aware aura works);
    - it is `art.json` `creature_emission_floor: 0.08`, the always-on additive albedo emission on plain-PBR creatures.
    - On Forward+ it washes the captain milky grey in every frame. Turning emission off alone gives a solid brown otter that matches Low.
  - The fix should be renderer-aware, like the aura. The floor likely affects other plain-PBR creatures on Forward+ by day too.
  - Evidence: `F22-4/main-1024/VERDICT.md`.
  - **Now running:** the Tidewake regrade (F39-look), Medium and High.

- **10:00 CT, F36#1 held shove hit on main** (the 15 enabled species with CPU ≥ 7.0; recipe vs shipping, Medium):
  - **CONFIRMED: Tanglevolt 7.89, Frostclaw 7.88, Stormcapra 7.79, Cloudfang 7.73, Breezetail 7.69, Craghorn 7.66.**
  - **REOPENED:** Aquaryn 7.49, Tidecoil 7.45, Solmane 7.33 (no gain), Cliffspike 7.03, Thundertunnel 6.91, Voltwig 6.89, Pebbik 6.89.
  - **Recipe scores below shipping:** Galecrest (6.62 vs 6.72) and **Stormraven (5.81 vs 6.09)**. Consider turning these two OFF.
  - Evidence: `F36-1/main-1024/VERDICT.md`.

- **09:40 CT, F36#0 creatures on main:**
  - **CONFIRMED: Terrapup 7.64 (3.20 m) and Burrowback 7.61.**
  - **REOPENED:** water_mosshell 7.41, Mosshell 7.36, Ripplet 7.26, Nightburrow 7.01, Bramblebun 6.95, Paddlenewt 6.65, Veridian 6.52, Stormtrail 6.16, Cindercub 6.11, Riftfrill 6.04, Mudsnout 5.88, Trailpup 5.73.
  - Common asks:
    - swimmers stand on a flat water slab (the capture's context stage);
    - five species stand at or below the 1.80 m ruler;
    - near-black values;
    - stock-animal reads (Trailpup, Mudsnout).
  - Two batches, three judges each, both confirming. Evidence: `F36-0/main-1024/VERDICT.md`.
- **09:40 CT, F17#6 shafts-off diagnostic:** removing `hall_great_hall.shafts` scores +0.95 in the same batch, which puts the Hall at about 5.85. It is still REOPENED. Added to `F17-6/VERDICT.md`.
- **Now running:** F22#4 Riverwatch on main. Medium maps to 5.10, with the ghost still PRESENT in 3/3, against Low 6.39. A material probe is running before I write it up.

- **09:12 CT, F17#6 Crossing Hall r9: REOPENED on GPU.** Main r9 maps to **5.83** against a control of 4.98 (5f1f388cc Hall config), the same at Medium and High.
  - The cause: r9's `hall_great_hall.shafts` (additive quads) render on Forward+ as hard white bead-streak bars in 6 of the 10 day views. Neon arch rims add to it. All three judges named the shafts as the worst artefact. The CPU sheet shows no shafts at all.
  - The fix needs to be renderer-aware, like the F22#4 aura.
  - A shafts-off diagnostic is queued.
  - Also fixed: a GPU timing bug in `capture_camera_set.gd` (coordinator aaaa585a1).
  - Evidence: `F17-6/VERDICT.md`.
  - **Now running:** F22#4 Riverwatch on main.

- **08:47 CT, F25#4 confirmed on main (Medium):** the launch frame is 16.6–27.4 ms (volley 1) and 10.3–18.0 ms (volley 2), with 0 frames over 33.3 ms in 24 volleys. The budget caps at 384 under over-cap load. This backs F21#5.
  - Low with prewarm read 245–254 ms on a cold cache after the reimport. **The warm-cache re-run gives 64–78 ms, the same as FIX.md: a cache artefact, not a regression.**
  - Evidence: `F25-4/main-confirm/VERDICT.md`.
  - **Now running:** F17#6 Crossing Hall, Medium and High; the Low re-run follows it.

Land on main only the files in `LANDABLE.txt`: verdict .md, key and score .json, and one `_sheet` per row, nothing over about 200 KB (owner size rule). Everything else stays on tb/gpu-pass.

*(Below: the 21–22 Oct lane note, kept for history. tb/vfx-launch has since landed on main.)*

**Cleanup (22 Oct, evening):** removed my own run outputs (`D:\tb-gpu-runs\out`, `yard`, `judge`; all evidence committed), my worktree `D:\tb-gpu-wt-lane`, my `.artifacts\phase2` and the untracked `gpu1022-*` Tidewake capture folders, and the three preset shader caches. That freed about 13.8 GB; D: went from 11.2 to 25.0 GB free. The old D: checkouts were not touched. The keep-awake had already expired.

### Results by row (yardstick-mapped, confirming batches unless noted; bar 7.5)

| Row | GPU result | Verdict |
|---|---|---|
| F25#4 four-creature frame rate (Medium) | Before the fix: launch frame 155–350 ms. **tb/vfx-launch:** launch 16–30 ms cold, 10–23 ms warm, **0 frames over 33 ms in 24 volleys**; budget caps at 384 under over-cap load. `F25-4/FIX.md` | **Meets the line once tb/vfx-launch lands.** Low's cold launch is still 64–78 ms. |
| Forward+ grade (Medium/High darker and greyer than Low) | Cause: depth fog plus exposure 0.60 under ACES. Recipe: fog ×0.5, exposure ×1.333, saturation ×1.2. **tb/fplus-grade cff972b7e** reproduces it on GPU; factors are applied exactly once and Low is untouched. `forward-plus-grade/`, `forward-plus-grade/branch/` | Verified. The Meadows re-measure at fog 0.001 waits for #712. |
| F08#3 Cloudreach settlements | c14/a14 at ff3cc7cfa: 5.75 vs 5.72 (weather-confounded). **r17 at ef2db84c, weather pinned clear:** candidate **6.57** vs control 5.20, at Medium and High | REOPENED |
| F22#4 Riverwatch r13 | Low **6.71** (control 5.11); Medium **5.85** (control 4.83). The Medium "ghost" boss is the boss-aura cue (an additive rim overlay plus a 3.0-energy cyan omni light) on Forward+. `F22-4/ghost-split/GHOST.md` | REOPENED |
| F36#0 creature roster | Owner-style prompt (e188bc862): installed mean 6.27 → **6.75**, recipe mean 6.55 → **6.96**. Best: Meadowhart recipe 7.49, Ripplet recipe 7.46 (its old 7.89 confirmation does not hold under the new prompt). r3 candidates: Riverdrake 7.39, Meadowhart 7.22–7.28 | REOPENED (none at 7.5) |
| F10#2 Stormwood named-fight camera | Medium 5.52, Low 5.39; occlusion FIXED ×15 at Medium | REOPENED |
| F04#6 Meadows trainer aftermath | 5.92 | REOPENED |
| F29#3 Stormursa | 7.00; the torn faint mesh is fixed | REOPENED |
| P2-095/096 craft text and hints | Both defects FIXED; Bar A 6.72 | REOPENED (Bar A) |
| P2-018 shiny distinction | 5.88 / 5.94 | REOPENED |
| P2-094 homestead wall | 5.96 / 5.94 | REOPENED |
| F39#0 Tidewake recapture | 240/240 frames delivered at Medium; no landscape row at 7.5 | Recapture delivered; rows REOPENED |
| Meshy/GLB metallic audit | The file-level metallic 1.0 default is already corrected at load (`character_model.gd`, `imported_materials.make_dielectric`). Nothing renders as metal. `meshy-metallic-audit*.{txt,md}` | Closed, no issue |

### Pipeline notes for other lanes

- **Line endings break overlays:** on this machine `core.autocrlf=true` checks `.patch.txt` files out with CRLF, and `git apply` then refuses them. Apply overlays from an LF copy.
- **Timing artefacts:** 1080p PNG captures and node censuses inside a timed window show up as 0.6 s "hitches". Printing, or measuring viewport render time on the launch frame, adds about 300 ms.
- **Comparing fights:** fight timelines vary between runs. Compare fight frames by state (tell or no tell), not by frame number.

## RESUME

**State at stop (27 Oct, 07:05 CDT, per the wind-down note):**
- The queue is closed and empty. Every verdict is pushed to tb/gpu-pass. No GPU process or queue is running.
- No capture or judge was in flight when the stop arrived.
- Free space on D: is about 496 GB.

**Last verdicts (27 Oct):**

| Item | Commit | Result |
|---|---|---|
| CO10 Terrapup dog3 r5 | `F36-1/CO10-terrapup-dog3r5-fb6a2593b`, ce20e75c1 | 6.30 / 6.30 vs badger 7.22, not met. Shot plain: terrapup is not in f36 `enabled_species`. Plates still read strapped on (PRESENT 2 / PARTIAL 1); coat now PARTIAL. |
| MH9 Meadows stronghold r7b | `F38-0/MH9-stronghold-r7b-0d8ef6dd2`, b7e1df9b0 | LAND, +0.53 / +0.71. P2-003 at the approach PRESENT 3/3 -> PARTIAL 3/3; night windows unlit PRESENT -> PARTIAL. Not met (best set 6.33). |
| CO11 near-bar creatures | `F36-1/CO11-near-bar-creatures-2b4f2256e`, 2c3a43799 | Land the Ripplet matte coat (+0.58 / +0.48) and the Mosshell faint (water_mosshell 7.10 / 7.67). Keep the flinch for Solmane only; drop it for Aquaryn and Tidecoil (regress). Tidecoil is MET on main (7.88). No new species met. |

Earlier on 26-27 Oct, all pushed (see each row's VERDICT.md):
- TW1: land.
- CO8: Galecrest and Cloudfang MET.
- SW20: on; SW20b re-judge 6.76, not met.
- No gain: SW13, SW17, SW19, MH8 (r6b, superseded by r7b).
- MJ/TP: neither lands.
- CO9: defect fix, +0.13 standard / +0.46 close crop.

**Open items, if a GPU lane resumes:**
1. **Driver crash.** 0xC0000094 in `nvoglv64.dll` +0xe93647 (driver 32.0.15.6094, no TDR) has hit three times, all at the Meadows stronghold on Medium (K5 off/mh3 on 26 Oct, MH9 cand on 27 Oct). Each time the re-run was clean. Updating the driver is the owner's call.
2. **F36 `--candidate`** aborts for any species not in `f36_pose_candidates.json` `enabled_species`: terrapup, mosshell, water_mosshell and ripplet as of 27 Oct. Shoot those plain, one run per species.
3. **Close-out candidates nearest 7.5:**
   - water_mosshell Medium (7.10), with High already 7.67.
   - Ripplet (7.26 / 7.01).
   - SW20 Ashfoot room (6.76 in the one-batch re-judge).
   - The paths to 7.5 are in each VERDICT.md.
4. **Run note:** `run_tool.ps1` logs `frames=0` for tools that write `.jpg` (Tidewake, F41, F38); check the frames folder instead.

**Earlier state (22 Oct, evening):** every result above is pushed to tb/gpu-pass; tb/vfx-launch is pushed; no GPU process is running.

**Local layout:**
- `D:\tb-gpu-pass`: the sparse working checkout on tb/gpu-pass.
- `D:\tb-gpu-runs\tools\`: local runners and wrappers, never committed. Copies of the important ones are in each row folder as `.txt`.
- `D:\tb-gpu-runs\appdata-{Low,Medium,High}`: isolated preset configs.
- Per-frame outputs and judge folders were deleted after their evidence was committed.

**Open follow-ups, if a GPU lane resumes:**
1. Re-measure the Forward+ grade on Meadows Medium once #712 (Meadows fog 0.001) is on main, with tb/fplus-grade merged.
2. Confirm the F22#4 renderer-aware boss aura once Fights ships it (the same Riverwatch capture at Medium, matched tell frames).
3. Re-confirm F25#4 on main after tb/vfx-launch lands (`F25-4/f25_fix_queue.ps1.txt`, about 12 minutes).
4. F08#3: judges ask for foreground dressing, a night lighting pass and varied islets (scene work for the Cloudreach lane).

## GPU LANE: ITEM SCORES DONE (28 Oct, ~01:40 CDT). The lane is idle; no GPU process is running.

All four biomes are scored on main b7a6e8bbe and pushed here as `ralph/reports/VISUAL/item-scores/<biome>/{scores-gpu.json, VERDICT-gpu.md, _sheet_<biome>-gpu.jpg, yardstick/}`. None of the 103 scored items reaches 7.5 except Meadows P2-095 at 7.53.

| Biome | Commit | Scored | Fit r | Top | Unscored / capture failures on main |
|---|---|---|---|---|---|
| Meadows | 768447c1d | 38 / 38 | 0.84 (b5 0.51, flagged) | P2-095 7.53 | none |
| Stormwood | 228496164 | 21 / 21 | 0.90 | P2-082 6.98 | 1 frame: hollows_alpha-i13 (the fight ends at i11) |
| Tidewake | faf61b655 | 27 / 29 | 0.96 | P2-032 6.36 | P2-101, P2-103 unscored: the late and win fight frames never happen (pilot `neutral_worst_frac` error, fixed on tb/item-scores) |
| Cloudreach | 06aef9c04 | 17 / 18 | 0.85 | P2-117 6.69 | P2-118 unscored. c007/c008 "no supported production-camera stand"; c026/c034 catch never engages (a candy pickup wins the interact offer) |

- **Failure details:** in each biome's `VERDICT-gpu.md` and `yardstick/capture_errors.json`.
- **Frame-name matching:** the tools' file names differ from the catalogue frame ids (prefixes are dropped; fight times use `.` where the ids use `_`; fight timings jitter). Five fight frames, all disclosed per verdict, matched the same event at the nearest time:
  - two Tidewake tell-starts;
  - three Cloudreach Veyra live frames.

### How the run went (27 Oct, ~18:50 CDT; owner said yes in the GPU session)

- **Ran:** the per-item biome card job (tb/item-scores job.json) on main b7a6e8bbe, in the order Meadows, Stormwood, Tidewake, Cloudreach.
- **Capture:** 207 unique repro commands for 250 frames, each run once as stated (opengl3), with two changes:
  - Add `--fullscreen`. The phase-2 tools require an exact 1920x1080 viewport, and the Windows title bar shrinks a windowed one; the tool's own error asks for it.
  - Point `--output`/`--out` at `phase2/<biome>/itemscores-gpu/<cmd>`. The tools reject any output outside `VISUAL/phase2/<biome>/`. Frames are moved out and kept local.
- **Other notes:**
  - `--source-commit` is added only to phase2_capture_tidewake_fights.gd, the one tool that accepts it.
  - The Cloudreach ride command has no output argument; it gets `--output=` (the tool accepts it).
- **Judging:** one-sided sets, about 9 items per batch, three judges, high anchors. Each biome's `scores-gpu.json` is pushed as it finishes.

## NEXT JOB WHEN THE OWNER RESUMES THIS LANE: per-item scores for every biome card (coordinator, 27 Oct, owner: "do whatever is needed to score each biome's cards")

- **The job:** tb/item-scores, `ralph/reports/VISUAL/item-scores/job.json` with its README. It covers all 106 F38–F41 catalogue items, up to 3 original phase-2 sightings each, 250 unique frames, each with the exact repro command you used for phase 2 on this GTX 1060.
- **CPU lanes are scoring it now (CPU-provisional).** Your run is the confirmation and the score of record.
- **What to do:**
  - Re-shoot on current main with each repro command. Change only `--output` (to `.../item-scores/<biome>/frames-gpu/<id>`) and add `--source-commit`.
  - Judge every item one-sided with the standard yardstick: 3 judges, high anchors, mapped. Report a Bar A score and a PRESENT / PARTIAL / FIXED call on the catalogue defect.
  - Write `ralph/reports/VISUAL/item-scores/<biome>/scores-gpu.json` in the README's format.
- **Order:** Meadows, Stormwood, Tidewake, Cloudreach.

## STOP: WIND DOWN (coordinator, 27 Oct ~09:45 UTC; owner: usage is running out)

- **Queue is closed.** Take no new arms, including any the lanes post after this.
- **If a capture or judge is running:** finish it only if it is within about 30 minutes of done. Otherwise stop it.
- **Then:**
  - commit what you have to tb/gpu-pass;
  - update the RESUME section (state, last verdicts CO10 / MH9 / CO11, open items);
  - leave no GPU process running;
  - stop.
- Thank you. Every verdict today drove a landing.

## GPU QUEUE UPDATE 5 (coordinator, 27 Oct 05:05 UTC): CO11 near-bar creature close-outs, after the Meadows stronghold run

- **Why these:** every species here sat 0.01–0.25 under 7.5 on the GPU (24 Oct F36 rows). Each MET row lands under the close-out exception.
- **Arms:** main 58bef4fc7 vs tb/co11-on 2b4f2256e, three commits on that main:
  - a grounded hit flinch for Aquaryn, Tidecoil and Solmane;
  - Mosshell's faint ends on its back (CPU b59 +1.21, water_mosshell too);
  - Ripplet's matte countershaded coat (CPU b61 +0.40).
- **Capture:** `capture_f36_poses.gd --candidate --whole-body --context --species=aquaryn,tidecoil,solmane,mosshell,ripplet`, plus their water forms where they have one (water_mosshell, Aquaryn, Tidecoil), with `--source-commit`. Standard roster crop.
- **Report:** MET per species per preset, and any regression.

## GPU QUEUE UPDATE 4 (coordinator, 27 Oct 04:40 UTC): MH8 is superseded by r7b

- **If MH8 (r6b) has not started capturing:** run r7b in its place.
- **If MH8 has started:** finish it, then run r7b as MH9.
- **Arms:** control tb/meadows 032b28f50 vs candidate tb/meadows-r7-on 0d8ef6dd2. The candidate is the control with three `stronghold.json` flags ON:
  - the r5 lit keep plus the Meshy spire behind it, both with authored window-grid emission masks;
  - MH3 courtyard daylight;
  - MH3 war banners.
- **CPU:** 6.00 -> 6.69 (+0.69). It beats r6b (+0.27 in the same batch).
- **Capture and report:** as MH8 (`capture_f38_matrix.gd --subset=band5_stronghold_approach`, day and night, Medium and High). Report P2-003, whether the windows read at night, and any red outside the Tether banners.

## GPU QUEUE UPDATE 3 (coordinator, 27 Oct 01:30 UTC): three close-out arms, run in this order

SW19 storm sky is received: no gain, OFF. Each arm below is its control plus one change. Use `--source-commit=<sha>` on every capture.

1. **SW20, Stormwood Ashfoot room (close-out; Ashfoot is at 6.96 on main, 0.54 short).**
   - **Arms:** control 255b363c7 (tb/stormwood) vs candidate tb/stormwood-m48b-on cc99525a5. The candidate turns ON `cottage_interior_finish.json storm_finish.storm_room` + `stormwood_dressing`, with the copper tint fixed to gold.
   - **CPU r48:** +0.94.
   - **Capture:** the F41 catalogue Ashfoot stands only. Inside: all four phases. Outside: a no-change check. Medium and High.
   - **Report:** MET per preset, plus the warm-room and generic-cabin defects.
2. **CO9, Mirejaw olive-umber fill (close-out; main is 6.53 on GPU, from MJ/TP).**
   - **Arms:** main 16c32126f vs tb/co9-on 033a66f6a. Main's reticulated net is kept and the dark cell fill is warmed toward olive-umber. The arm regenerates its own texture from main's albedo.
   - **CPU b54:** 6.56 vs 5.44 (+1.12).
   - **Capture:** `capture_f36_poses.gd --candidate --whole-body --context --species=mirejaw` plus the water form, standard roster crop.
   - **Report:** MET per preset, plus the near-black back and placeholder calls.
3. **CO10, Terrapup as the large dog (owner direction: "Terrapup must be the dog"; the badger is 6.75 on GPU).**
   - **Arms:** main 58bef4fc7 vs tb/co10-on fb6a2593b, dog3 r5. The pad is filled with fur, small plates grow along the spine, and the coat is browner.
   - **CPU b56:** 6.27 vs badger 6.02. The lane says the plates still read a little like a pad.
   - **Capture:** as CO9 with `--species=terrapup`, including the ride and rider seat if the tool shoots them.
   - **Report:** MET per preset, the strapped-on plates and rider-clipping calls, and the coat colour.

4. **MH8, Meadows stronghold spire r6b + MH3 (P2-003, PRESENT 12/12 on GPU).**
   - **Arms:** control tb/meadows 4a6eeec96 vs candidate tb/meadows-r6b-on f6b946e47. The candidate is the control with three `stronghold.json` flags ON:
     - `hero_gatehouse`: the Meshy spire, about 200 m tall, with a lit-window emission mask;
     - `courtyard_daylight_candidate` (with its night step-down);
     - `banner_model_candidate`.
   - **CPU:** 4.93 -> 5.72 (+0.79); P2-003 PRESENT -> PARTIAL 3/3.
   - **Capture:** `capture_f38_matrix.gd --seed=2042 --f38-preset=<Medium|High> --f38-baseline --times=day,night --subset=band5_stronghold_approach --output=res://<round> --source-commit=<sha>`.
   - **Report:** band5_stronghold_approach_0 and _1, day and night; P2-003; whether the windows read at night; and any red outside the Tether banners.

5. **SW20b, an Ashfoot MET re-judge (no new capture; frames you already have).** Yes, please settle it.
   - **One batch:** SW16's on-arm Ashfoot inside frames (m36b), SW20's control frames (255b363c7) and SW20's on-arm frames (cc99525a5), all as one-sided sets, with high anchors.
   - **Why:** SW16 on and SW20 control should be nearly the same scene (storm_view ON in both), yet they map 6.96 vs 5.73 across batches. Report all three mapped in the one batch, and MET for the SW20 on arm.
   - **When:** run it whenever the GPU is between captures. It's judging only.

After these the queue is empty.

## GPU QUEUE UPDATE 2 (coordinator, 26 Oct 6:00 PM CT): after SW13

- **CO8, TW1, SW17:** received. CO8 Galecrest and Cloudfang and the TW1 landmarks are landing (#766 merged, #767 in CI). SW17 stays off.
- **Next, SW19: Stormwood storm sky (chapter-wide).**
  - **Arms:** control tb/stormwood fb919fb55 vs candidate tb/stormwood-m45c-on 8a22c917b. The candidate is the control plus one config change: `stormwood_surge.json presentation.ceiling.form` and `ceiling.skyline` ON.
  - **CPU r45b:** 5.75 -> 6.58 (+0.83), flat lavender sky FIXED 3/3. Lane note: `ralph/reports/STORMWOOD/close-1024/notes.md` (26 Oct 14:24Z and 22:08Z entries).
  - **Capture:** the full F41 Stormwood catalogue (`tools/capture_f41_stormwood_catalog.gd`), Medium and High, every phase, each arm at its own SHA with `--source-commit=<sha>`. The sky shows at every open stand, so judge all stands, not a subset.
  - **Report:** per-stand mapped scores, plus the sky defect (flat lavender) and the lane's known risk, "lit rims read as white smear slabs".
- **Queue after SW19:** nothing else is GPU-ready right now. The lanes will post new arms here or in their notes; I'll add them as they come.

## GPU QUEUE UPDATE (coordinator, 26 Oct 3:30 PM CT; the coordinator session cannot reply to messages, so the queue is here)

Order after TW1: **CO8 (close-out) first**, then SW17, then SW13.

- **CO8 close-out:** current origin/main vs tb/co8-on 7e6b868d72e04e517ac49e6c90519dd47d0bdb63. That branch is tb/co7-on (Galecrest owner-approved matte slate/tan finish, plus a grounded flinch) plus one commit: the Stormcapra faint faces the camera.
  - **Judge:** Galecrest (all roles), Cloudfang and Breezetail (hit), and Stormcapra (hit and faint).
  - **Method:** `capture_f36_poses.gd --candidate --whole-body --context`, standard roster crop, report MET per preset. The game installs the F36 recipe profile (creature_body.gd -> creature_pose_candidates.gd install()), so the recipe pass is the record. CPU b51: 6.87 vs main 4.60.
- **Board:** CO-1 / CO-2 rows (Grandpa; Tanglevolt, Frostclaw and Craghorn hurt and faint) are marked MET in PR #765. MJ/TP is received: neither lands.

## GPU QUEUE (coordinator, 24 Oct midday; run top to bottom; work from origin/main 45865499d or later)

Each row is CPU-provisional until this pass. Capture at Medium and High, judge with the yardstick (`tools/visual_judge/`: standard prompt, at least 3 anchor pairs, `calibrate.py`). A mapped Bar A of 7.5 or above confirms the row; below 7.5 reopens it. Commit verdicts per `LANDABLE.txt` rules to tb/gpu-pass and write a READY line at the top of this note.

1. **F17#6 Crossing Hall r9** (CPU 6.84 vs 5.82; `ralph/reports/MEADOWS/close-1024/F17-6.md`): `tools/visual_judge/capture_camera_set.gd --set=res://tools/visual_judge/camera_sets/F17-6.json` (15 views).
2. **F22#4 Riverwatch named fight at Medium** (CPU 6.89 on 77447cf25; `ralph/reports/FIGHTS/close-1024/rw_*.json`). The renderer-aware boss aura (Forward+ rim x0.3, no omni light) is on main, so this is the re-judge your GHOST.md asked for: `tools/art_pipeline/capture_named_fight.gd --trainer=captain_riverwatch --live-member=captain_riverwatch:4 --ally=ripplet --frames=12 --interval=0.5 --tell-frames`; compare tell frames by state.
3. **F36#0 naturalistic creatures**: `capture_f36_poses.gd --whole-body --context --species=ripplet,cindercub,terrapup,bramblebun,mudsnout,trailpup,paddlenewt,burrowback,veridian,mosshell,nightburrow,stormtrail,riftfrill` (no `--candidate`), plus Mosshell's water form. CPU: Cindercub 7.63, Bramblebun 7.57, Trailpup 7.49, Terrapup 7.47 (3.20 m, owner "Just shrink it"), Ripplet 7.40, Mudsnout 7.40, Mosshell 7.31, Burrowback 7.23, Paddlenewt 6.88, Veridian 6.82. Nightburrow, Stormtrail and Riftfrill wear their bases' meshes (unjudged on them). Riverdrake stays OFF.
4. **F36#1 poses**: `capture_f36_poses.gd --candidate --whole-body --context` for `f36_pose_candidates.json` `enabled_species` (held shove hits, recoil/faint/swim for the remakes, water forms swimming, Tuskroot topple; verdicts under `ralph/reports/CREATURES/close-1024/`).
5. **Tidewake time-of-day regrade** (CPU 7.07 vs 5.84): `tools/visual_judge/camera_sets/F39-look.json` at golden/night (`ralph/reports/TIDEWAKE/close-1024/lt2/`).
6. **High/Medium biome matrices for F38#0 / F40#0 / F26#3** once the Meadows and Cloudreach lanes land their CPU matrices: `capture_f38_matrix.gd` (Meadows) and the F40 matrix (Cloudreach) at High and Medium, then a yardstick judge per biome. This turns the CPU-provisional re-scores into full ones and is the F26#3 evidence.
7. **Forward+ grade re-measure** (follow-up 1 above): Meadows Medium on main (#712 fog 0.001 and the fplus grade are both on main).
8. **Fight telegraphs** (#722/#724, violet #b16cff, informational; CPU 6.44/6.39/6.28, below the bar): the Meadows, Tidewake and Cloudreach fight sets at Medium, tell frames by state.

Skip F39#4 (reopened 24 Oct: the Veilfall close-up needs new art first). F21#5 closed on your F25#4 frame-time evidence; nothing to run.

**Rules this lane ran under:**
- Push only tb/gpu-pass.
- Ask the owner before any other push, any deletion of things that are not mine, and any spending.
- Never modify or delete the old D: checkouts.
- One GPU process at a time.
- Keep at least 5 GiB (target 10 GB) free on D:.
