# GPU-PASS lane note (owner's Windows desktop, GTX 1060 3GB; 21–22 Oct 2026)

## READY (24 Oct): newest first

- **08:55 CT, F25#4 confirmed on main (Medium):** the launch frame is 16.6–27.4 ms (volley 1) and 10.3–18.0 ms (volley 2), with 0 frames over 33.3 ms in 24 volleys. The budget caps at 384 under over-cap load. This backs F21#5.
  - Low with prewarm read 245–254 ms on a cold cache after the reimport; a warm-cache re-run is queued. Low is not the line.
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

**State at stop (22 Oct, evening):** every result above is pushed to tb/gpu-pass; tb/vfx-launch is pushed; no GPU process is running.

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
