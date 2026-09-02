# Visual Parity Program — progress checkpoint

**This file is the single resume point for the Meadows visual-parity program**
(`docs/VISUAL_PARITY_STAGED_GOAL_PROMPT_V2.md`, `docs/TETHERBOUND_VISUAL_BIBLE_V2.md`).
A fresh session with only this file plus the repo must be able to continue.
Passes are `VP0…VP11` (visual passes) — never conflate with gameplay Gate A/B/….

## Branch and SHAs

| item | value |
|---|---|
| program branch | `claude/coordination-subagents-3fhz1x` (the owner prompt names `codex/meadows-visual-parity`; this session's harness pins the branch name, so this branch *is* the visual-parity branch — do not create a second one) |
| starting `main` SHA | `252ccc81` (2026-09-01, `origin/main` at program start) |
| current branch SHA | (updated at each pass, see per-pass table) |
| last successful push SHA | (see per-pass table) |

## Pass status

| pass | status | commit SHA | pushed SHA | evidence |
|---|---|---|---|---|
| VP-PRE | complete (5/5 checks) | f4afc9d9 | f4afc9d9 | §VP-PRE below |
| VP0 baseline | **complete** (evidence set reduced to village/pond/survey by owner call; other sites' befores are renderable from ca0575b8) | 401d7217 | 401d7217 | `ralph/reports/visual-parity/VP0-baseline/` (locations-1080p/, locations/, JUDGE-village-pond.md), `VP-PRE/` |
| VP1 sky/light | candidate merged (WORLD r1–r3: cumulus sky, dawn/golden/night presets, sun_glow_falloff, moon); judge r3: day/golden "yes" for environment, dawn/night overlook red wash + low-sun halo open → WORLD r4 | 3c87d9ea | — | `WORLD/round1..3`, `WORLD/JUDGE-round*.md` |
| VP2 terrain/ground | candidate merged (grass carpet ON with cull tiles/far thinning/mesh LOD, terrain grain/damp, aerial); proxy budget met (band1_open 11.80M / 7511; hall 3975); judge r3 calls ground close-ups the strongest frames | 3c87d9ea | — | `GROUND/`, `VP2-perf/`, `WORLD/JUDGE-round3.md` |
| VP3 vegetation | candidate merged (ecology gate, under band, heroes, water-edge bands, desaturated leaf retints); judge r2/r3: groves read, distant scatter at overlook still uniform → WORLD r4 | 3c87d9ea | — | `WORLD/round2..3`, `VEG` tests |
| VP4 corridor | round 1 judged (regressions at stations 02/07, groves vanished); CORRIDOR r2 rendering | — | — | `CORRIDOR/round1`, `CORRIDOR/JUDGE-round1.md` |
| VP5 village/tournament/camps | first pass merged (PLACES r2); Bar B yes for village | adaee521 | 5b8a53a6 | `PLACES/round1`, `PLACES/round2` |
| VP6 Warrens | tone variation merged (PLACES r3); soil-apron/exterior read still open → PLACES r4 | 81c4232a | | `PLACES/round3` |
| VP7 Relay | occupation + staffing/cables merged (PLACES r3) | 81c4232a | | `PLACES/round3` |
| VP8 Hall | dark weathered exterior merged (PLACES r3); silhouette at 200–400 m + storm band open → PLACES r4 | 81c4232a | | `PLACES/round3` |
| VP9 world life | round 2 merged (5 stands, field_emission); judge r2: both bars still no → LIFE r3 (pairing assertion, groups ≤ 10 m, night emission, pond blob) | 3c87d9ea | — | `LIFE/round1..2`, `LIFE/JUDGE-round*.md` |
| VP10–VP11 | not started | — | — | |

**Current pass:** VP1–VP9 all have merged candidates on the program branch; WORLD r4 / PLACES r4 / CORRIDOR r2 / LIFE r3 in flight. **Next action:** check-in #11 (08:25 UTC): judge pushed frames, merge accepted rounds (re-bake), then VP10 perf retention on the merged tree.

## VP-PRE — environment capability check

| check | result |
|---|---|
| 1. Godot binary + project imports | PASS — Godot 4.7.stable.official.5b4e0cb0f at `~/.cache/tetherbound-art/godot`; `--import` twice, 0 script errors (688 MB `.godot/`) |
| 2. real screenshot file on disk from the repo capture path | PASS — `tools/capture_diag_minimal.gd` wrote 1920x1080 via X11/llvmpipe GL 4.5; `tools/survey.gd` wrote 5 frames to `shots/` (copied to `ralph/reports/visual-parity/VP-PRE/`) |
| 3. image is a real rendered frame | PASS — opened `01-spawn-outward.png`/`03-rise-overlook.png`: real world frames (terrain, scatter, buildings, sky). FINDING: `05-spawn-low-sun` (golden) came back a flat frame (spread 0.000) — `apply_time("golden")` renders nothing under this pipeline; carried into VP1 as defect VP1-G0 |
| 4. test command runs | PASS — `tests/smoke_art.gd` headless: `art: OK` in 1m53s |
| 5. blind visual judge invocable from this environment | PASS — a fresh sonnet subagent given only the four VP-PRE frames, `docs/reference/`, the website board and the rubric produced a full critique: `ralph/reports/visual-parity/VP-PRE/JUDGE.md` (bar A: no, bar B: no). Not deferred. |

Environment notes for the next session (all verified 2026-09-01):
- Install Godot 4.7-stable: `tools/art_pipeline/setup.sh godot` → `~/.cache/tetherbound-art/godot`.
- Fresh container also needs: `apt-get update && apt-get install -y libegl1 libegl-mesa0 mesa-vulkan-drivers`
  (xvfb is preinstalled here) and `pip install pillow numpy` for `tools/frame_stats.py`.
- Import once (twice on a cold cache): `$GODOT --headless --path . --import`.
- Capture: `xvfb-run -a -s "-screen 0 1920x1080x24" $GODOT --path . --rendering-driver opengl3 --resolution 1920x1080 --script tools/<capture>.gd`.
  NEVER combine `--headless` with `--rendering-driver` (hangs forever, `ralph/conventions.md`).
- Tests: `$GODOT --headless --path . --script tests/run_tests.gd -- --only=<files>` and `tests/smoke_<name>.gd`.
- Blind judge: `.claude/skills/visual-judge/SKILL.md` — run as a fresh subagent given only the
  contact sheet, the frames and `docs/reference/`. Runnable here (Claude Code); record `DEFERRED` only if not.

## §6 acceptance numbers (PROVISIONAL — owner to confirm the placeholders)

| item | value |
|---|---|
| target platform | Windows / ROG Ally |
| renderer | Compatibility (`gl_compatibility`) |
| capture + measurement resolution | 1920x1080 for evidence frames; perf stands at 1280x720 (the repo's `tools/perf_render_stats.gd` series) |
| graphics preset | the shipped defaults: `project.godot` `[rendering]` (directional shadow 2048, positional atlas 2048, soft shadow filter 2, msaa_3d 2x) + `data/config/performance.json` as committed. There is no in-game preset system. |
| minimum sustained FPS | **45 (PROVISIONAL)** — cannot be measured in this container (software GL); owner measures on the Ally |
| minimum 1% low FPS | **30 (PROVISIONAL)** |
| container-enforced proxy per pass | `tools/perf_render_stats.gd`: primitives at `band1_open` ≤ 12.0M (baseline 9.25M with grass_field OFF; 31.7M produced the ~10 FPS owner report), draw calls at `band1_open` ≤ 7500, draw calls at `hall_approach` ≤ 4000 (`docs/PERFORMANCE_BUDGET.md` §0.5). Same tool, same resolution, every pass. |
| test command | `tests/smoke_art.gd`, `tests/smoke_playground.gd`, `tests/smoke_traversal.gd` + `run_tests.gd --only=` the tests owning changed files; full 4-shard unit suite at VP0 and at the end of VP3 |

## Parallel lanes (spawned 2026-09-02 00:39 UTC from 1ef3878a; contract in `docs/VISUAL_PARITY_LANES.md`)

| lane | pass | branch | session |
|---|---|---|---|
| SKY | VP1 | `claude/vp-sky` | session_01BGTw8d5sLdQA8V34RkTgou |
| GROUND | VP2 | `claude/vp-ground` | session_018GT9BkQfWZuu5kVdfmonw8 |
| VEG | VP3 | `claude/vp-veg` | session_01WF4HFAG7p6hPwuVQcjr8GY |
| VILLAGE | VP5 | `claude/vp-village` | session_01M1qiTLwxaFNJp9ZqgNbd52 |
| HALL | VP8 + VP7 | `claude/vp-hall` | session_01FvtyLa4Y6Kvib2fU8G84vM |
| WARRENS | VP6 | `claude/vp-warrens` | session_01XLcXZC6QjZV4mRn8rKC7Lk |

**Wrapped 2026-09-02 01:30 UTC by owner directive ("they're burning my usage").** All six Fable
lane sessions were interrupted and archived. What survived: code/config on `claude/vp-ground`
(24769eff: tiles A/B tile=0 measurement 31.67M primitives at band1_open, far_cover/grass shader edits),
`claude/vp-veg` (d6c0fe55), `claude/vp-village` (8d738af0), `claude/vp-hall` (992fbec7). No lane pushed
a single frame. SKY and WARRENS pushed nothing. Lane-branch code is reviewed and cherry-picked by the
coordinator, never merged blind.

**Area coordinators (Opus), spawned 2026-09-02 01:46 UTC from e3aba7d7** (owner directive: Opus
coordinates, Sonnet codes/renders, Fable judges/plans):

| area | passes | branch | session |
|---|---|---|---|
| WORLD | VP1 + VP2 + VP3 | `claude/vp-world` | session_01XigbWtMzp7EwN5SqzwLvYB |
| PLACES | VP5 + VP6 + VP7 + VP8 | `claude/vp-places` | session_0182PYdBscd4KZMdDfwmmu63 |
| LIFE (Sonnet, direct lane, spawned 05:36) | VP9 first slice: roll_new_worlds on, creature clusters at stands, creature/combat frames | `claude/vp-life` | session_01D9GHSeCLm2kM7uFYjod6TD |
| CORRIDOR (Sonnet, direct lane, spawned 05:36) | VP4: mid-ground structure along the village→band 2 route via band vegetation anchors | `claude/vp-corridor` | session_01TRE9FUps52WdL4esFFFxK9 |

Round plans are delivered into the coordinator sessions by the program coordinator; each round ends
with pushed frames + REPORT.md and the session stopping.

**Operating model from here:** the coordinator (this session) judges and plans; rendering runs serially
on the coordinator's box; the code-blind judge is a cheap Sonnet subagent inside this session; remote
Sonnet coder sessions are spawned only for bounded, well-specified rounds when wall-clock parallelism
is worth their setup cost.

## Performance measurements

Tool: `tools/perf_render_stats.gd`, 1280x720, Compatibility, llvmpipe (structural counters only).

| state | view | draw calls | primitives | objects | source |
|---|---|---|---|---|---|
| carpet OFF (shipped main) | band1_open | 7366 | 9,250,290 | 6361 | OWNER-0901-PERFORMANCE-LAG-V2 |
| carpet ON, one MultiMesh (owner's laggy build) | band1_open | 7320 | 31,757,567 | 6315 | OWNER-0901-PERFORMANCE-LAG-V2 |
| VP0 baseline: carpet ON, cull_tile_m=0 | band1_open | 7409 | 31,672,479 | 6378 | GROUND lane, `GROUND/perf/perf_before_tile0.txt` |
| VP0 baseline: carpet ON, cull_tile_m=0 | village_high | 2860 | 28,277,296 | 3050 | same |
| VP2 iteration 0: cull_tile_m=16 + far thinning/reach caps/tile LOD + VEG lod ranges on | band1_open | 8633 | 21,287,781 | 7612 | coordinator 04:23 UTC, settle 120/60/20, `WORLD-coord-fast/perf_render_stats.txt` |
| same | village_high | 4376 | 18,087,761 | 4474 | same |
| same | hall_approach | 4335 | 13,219,939 | 4680 | same |
| VP2 iteration A (superseded before measuring by main's owner-decided density) | — | — | — | — | — |
| VP2 iteration B: main's shipped density (75k tufts, 4 blades, 25k stones, 6k/6k/15k tiers) + cull tiles 16 m + far thinning/reach/tile LOD + VEG lod ranges (trees 700/grove 800) | band1_open | 8593 | 12,583,284 | 7573 | coordinator 04:52 UTC, `VP2-perf/perf_iterB.txt` |
| same | village_high | 4408 | 9,386,569 | 4504 | same |
| same | hall_approach | 4424 | 4,627,194 | 4769 | same |
| **VP2 iteration C (candidate)**: B + trees/grove/deadfall/rocks lod 420/460/260/220 + cull_tile_m 24 | band1_open | 7839 | 12,217,644 | 6812 | coordinator 05:20 UTC, `VP2-perf/perf_iterC.txt` |
| same | village_high | 3703 | 9,197,864 | 3852 | same |
| same | hall_approach | 4270 | 4,634,502 | 4615 | same |
| iteration C with `scatter_lod_ranges=false` (A/B) | hall_approach | **3975** | 4,201,344 | 4317 | coordinator 05:31 UTC, `VP2-perf/perf_iterC_lodoff.txt` |
| iteration C with `scatter_lod_ranges=false` (A/B) | band1_open | **7511** | **11,799,910** | 6481 | coordinator 05:48 UTC, `VP2-perf/perf_iterC_lodoff_band1.txt` |
| **VP2 COST CANDIDATE = iteration C + scatter_lod_ranges=false** (committed) | band1_open / hall_approach | 7511 / 3975 | 11.80M / 4.20M | | meets every §6 proxy budget |
| **Checkpoint 06:14 UTC: program branch with WORLD r2 + PLACES r2 merged** (`VP1-3-candidate/`) | band1_open | 7668 | 11,817,644 | 6608 | fast capture run, settle 120/60/20 |
| same | village_high | 3122 | 8,579,837 | 3263 | same |
| same | hall_approach | 3795 | 4,361,609 | 4137 | same — all inside budget with everything merged |

Budget: band1_open primitives ≤ 12.0M, draw calls ≤ 7500; hall_approach draw calls ≤ 4000. **Iteration 0 misses both** (21.3M; 4335). **Iteration B: 12.58M / 4424. Iteration C: 12.22M at band1_open (1.8% over the provisional 12.0M and 11% under the 13.69M main ships with grass on), hall_approach 4270 draw calls (7% over the reasoned 4000 ceiling; pre-program baseline at that stand was 4331 after the GROUND+VEG merge, ~2900 before it). A/B showed `scatter_lod_ranges=true` costs +0.4M primitives and +330 draw calls: OFF is the VP2 cost candidate — 11.80M / 7511 at band1_open, 3975 at hall_approach, all inside budget.**

## Judge history

### VP-PRE (survey frames, shipped main @ 252ccc81, grass carpet OFF) — `ralph/reports/visual-parity/VP-PRE/JUDGE.md`
**Superseded as a baseline**: these frames were captured with `grass_field` off (the shipped state), which the owner rejected as unjudgeable. Kept only as the capability-check evidence; the program baseline is VP0 with the carpet on.
- Bar A (keyart world): **no**. Bar B (Palworld kind of game): **no**.
- Ranked gaps: (1) the ground does not resolve — grass dissolves into textureless blur a few metres out in 3 of 4 frames; (2) nothing casts a believable shadow — rocks float, and 01 carries a large hard-edged diagonal dark patch with no caster; (3) the palette never leaves a narrow desaturated mid-tone band, sky identical and smeared in every frame, no atmospheric depth (03 horizon is a hard flat line).
- Also: trees are identical ball-on-stick at regular intervals (02); scatter-blob clump with hard falloff (04); no creatures in the survey set (capture gap, not a verdict).
- Response: (1) → VP2; (2) shadows/contact → VP1 (shadow bias, ambient) + VP2 (ground darkening under objects); the 01 diagonal patch is investigated in VP1 (suspect: PSSM split / terrain macro); (3) → VP1. Creature frames are added in VP0's location/combat set.

### VP0 baseline, village + mill pond (carpet ON, main @ 252ccc81 + grass_field enabled) — `ralph/reports/visual-parity/VP0-baseline/JUDGE-village-pond.md`
- Bar A (keyart world): **no**. Bar B (Palworld kind of game): **no**.
- Ranked gaps: (1) the sky — tan/brown-streaked smeared clouds in 7 of 9 frames, a third of every wide shot, "reads as a broken shader"; (2) no creature anywhere in the set; (3) lighting disagrees with itself — clear sky but no ground shadows, flat hard-edged sun disc with no bloom, distant hills with no blue haze.
- Also: single broccoli tree silhouette at one scale everywhere; dead tree and boulder assets copy-pasted; flat plastic leaf cards close up; fenced paddocks enclose nothing; NPCs static (village reads populated, not lived-in); mill has no wheel/chute (frame named "wheel" shows none); tournament frame shows no event dressing.
- Response: (1)+(3) → VP1 (shader rewrite + light/aerial config, drafted); creature frames → added to VP0 via the combat/creature captures, and creature staging near capture stands is a VP9 item; tree variety/leaf cards → VP3; paddocks/tournament/mill dressing → VP5; NPC life → VP9.

### WORLD round 1 (Opus coordinator, `claude/vp-world` @ 0409e726) — coordinator verdict 2026-09-02 04:00 UTC
Evidence: `ralph/reports/visual-parity/WORLD/round1/` (stands 2×4 times, clock-freeze, before) and the program
coordinator's fast render of the same tip (`WORLD-coord-fast`, village/pond/survey, 960x540).
- Fixed and confirmed in frames: cloud form and scale (large cumulus, blue sky), horizon no longer white,
  village day and night read well (moon disc, lit windows). Root causes found by WORLD: the day clock
  drifts ~1 in-game hour per 25 real seconds so every pinned capture time walked away during settle
  (`set_clock_frozen()` added; this was VP1-G0); the sun "blob" was a hard-coded halo exponent (27° halo),
  now `sun_glow_falloff`.
- Still open → round 2 sent 04:12: (1) canopies still mint-white — the runtime derived-texture binding
  failed twice; round 2 bakes the desaturated leaf sheets to derived PNG assets and uses the `retexture`
  swap; (2) sun halo still too large (falloff 200/120 → 600/350); (3) dawn overlook is a uniform red
  wash. Perf table not measured by WORLD; the program coordinator measures tiles 0/16 locally.

### PLACES round 1 (Opus coordinator, `claude/vp-places` @ 45238cab) — verdicts 2026-09-02 04:45 UTC
Evidence: `ralph/reports/visual-parity/PLACES/00-before/` (42 frames + survey/ground) and `PLACES/round1/locations/` (36).
Code-blind judge: `PLACES/JUDGE-round1.md`. Bar A soft yes for village/stronghold, no for relay/landmarks; Bar B yes.
- Judge: every after-frame is pixel-identical to its before-frame — the merged VILLAGE/HALL code did not reach the
  round-1 render (root-cause step added to round 2). Village reads as a cozy inhabited settlement day and night;
  trail camp is the strongest place (legible fire, placed props); waystop good (Hall silhouette + smoke); stronghold
  courtyard "nails ruin + Team Tether industry"; relay reads abandoned, not active; 04-warrens-den and
  06-relay-approach are camera-in-geometry frames; 11-castle-landmark stands show empty grassland; no village gate
  visible in any road frame; night NPCs silhouetted; cardboard tree cards and roof-tile moiré need art, not staging.
- Coordinator: Hall exterior at distance still reads cream castle kit; relay needs occupation; warrens exterior flat grey.
- Round 2 sent 04:50 (+ addendum 04:56): verify frames differ, Hall exterior weathering on all kit pieces, fix the
  three broken/empty stands, relay occupation first pass, warrens exterior, well pad, gate visible, night NPC light.
- PLACES also found: `smoke_traversal` fails on the merged tree at the South Bridge (pre-existing on main, outside
  PLACES), and that 34–58 main commits were missing from the program branch (now merged, ce235831).

### WORLD round 2 (`claude/vp-world` @ bf92e754) — coordinator verdict 2026-09-02 05:45 UTC — MERGED into the program branch
Evidence: `ralph/reports/visual-parity/WORLD/round2/` (village/pond 15 frames + survey 5, sheets).
- **Canopy regression fixed and verified in frame**: root causes were `Image.adjust_bsc` (nonexistent; the engine's is
  `adjust_bcs`, so the desaturation never ran and the aborted call left a null albedo → white) and a path-less runtime
  ImageTexture dropped through the Terrain3DMeshAsset round-trip. Fix: desaturated leaf sheets baked offline to
  `assets/environment/stylized_nature/derived/*.png` (derived textures, no new meshes) and bound via the existing
  `retexture` swap. Trees now read deep/mid green with three visible tints.
- Sun halo tightened (day 5.5°, golden 7.2°), night moon given a glow, cloud edges softened, dawn exposure 0.8→0.55,
  pond-approach stand moved out of the canopy.
- Open for round 3: golden still reads as a soft light mass (WORLD's own measurement), a night stand aimed at the moon's
  azimuth is needed to judge the moon, `03-rise-overlook-golden` reads cool/grey.
- Code-blind judge (`WORLD/JUDGE-round2.md`): **Bar A yes (day frames), Bar B yes on environment** — first yes of the
  program; creature/character half unanswerable (no creature in any frame → LIFE lane). Remaining: survey golden frame
  black again (clock freeze ordering in survey.gd), daytime sun a flat white cutout, night ground black past the lit
  radius, overlook distance flattens against the sky, one evenly spaced bush row. All sent as round-3 items.

### PLACES round 2 (`claude/vp-places` @ 347306a0) — verdicts 2026-09-02 05:50 UTC — MERGED into the program branch
Evidence: `PLACES/round2/locations/` (27 frames). Judge: `PLACES/JUDGE-round2.md` — Bar B **yes** for village and
stronghold courtyard, no for the Relay; Bar A no as a set (pale canopies — WORLD's bug, now fixed — and debug-line cables
are the loudest elements).
- Better: Warrens den stand fixed (interior with creature), Hall 100/200/400 m stands now actually aim at the Hall,
  relay gate + barrier + banner + grunts at the approach.
- Open → round 3 (sent 05:52 + addendum 06:06): Hall exterior kit still cream at distance; Warrens mound flat grey;
  cyan cables/beams unanchored at relay, stronghold sky and courtyard floor; relay standing/apparatus not staffed;
  smoke column a hard band; night courtyard/gate crushed black; route-out stand shows no gate.

### Check-in 06:50 UTC — lane state
- WORLD round 3 stands pushed (9, incl. a moon stand): golden sun still a very large disc; `03-rise-overlook-dawn` AND
  `06-moon-stand-night` are uniform red washes while day/golden at the same stand and the spawn stand at all times are
  fine → time-preset × elevated camera; a one-key-at-a-time bisect was dispatched. Round-3 locations/ground/survey
  frames not yet pushed.
- LIFE round 1 pushed (9 frames): placement work is in but not legible — creatures tiny or absent at every stand,
  `03-band1-open-meadow-day` is a camera-in-geometry frame, the starter-beside-trainer frame shows only the creature's
  back. Round 2 sent: re-stage at eye height with clusters 8–15 m ahead, fix the stand, hero pairing, REPORT.md.
- PLACES round 3 in flight (VP7 cables/staffing commits landed 06:47; Hall exterior + Warrens next).
- CORRIDOR: running (rendering + one test failure), nothing pushed at 06:50.

### Check-in #19 (12:59 UTC) — LIFE r6 merged; CI fix; WORLD 5c
- **Ship-to-main**: the first mirror run (`dbfec0be`) failed two unit tests that came from LIFE r5, not from
  `main`: `test_spawns_data` (new mosshell cluster 1071 inside the Creek Hollow footprint → 9 clusters / 11
  creatures vs the authored 8 / 9) and `test_band_content` (a doc key on band1 order 0 not mirrored into the
  band-split fixture). Fixed on the program branch (`095cee94`: cluster 1071 removed, fixture mirrored; 31/31
  locally), mirror moved to that SHA, CI queued; sweep when green.
- **LIFE round 6** (`6aa21e95`): pairing rewritten side-by-side at equal depth with a flatness-selected stand;
  village-life re-aimed at the one natural villager group (village_npcs.json deliberately untouched per the
  owner's "too many people" directive); relay-camp clusters moved into the bonfire's light. Judge
  `LIFE/JUDGE-round6.md`: **pairing composition solved**, village reads occupied (2 villagers), relay-camp-day the
  best frame; open meadow still reads as zero fauna (camouflaged species), relay-camp-night creatures unread.
  Merged `02292cf7`. Round 7 dispatched 13:07 as the lane's final round (high-contrast species at 03, bodies
  inside the firelight, walker scope estimate, final state section).
- **WORLD 5c** (`d2c80263`): matched-TIME A/B — neither arm washed out to 2,900 s; elapsed time is a correlate,
  not the cause; the `TIME` wrap stays as a latent fix. The trigger is a stand/preset TRANSITION. Final
  diagnostic dispatched 13:01: dump and mechanically diff every Environment / DirectionalLight3D / sky-uniform /
  camera property between a clean and a washed shot across a preset cycle and a teleport.
- CORRIDOR round 6 and PLACES round 8 (+ camps) in progress.

### Check-in #18 (12:28 UTC) — CORRIDOR r5 and PLACES r7 judged and merged
- **CORRIDOR round 5** (16 stations, `fb27f52d`): band4's first `layer_anchors` (copse + rock cluster at station 13).
  Judge `CORRIDOR/JUDGE-round5.md`: 01–06, 12, 16 solid; 13 borderline (right two-thirds bare); 09 better but no
  water in frame; 07/08 still unfixed (lane's round 6 in progress); 10/14 weak; 11 white (PLACES). Merged
  `3be018a6`, re-bake in progress. Round-6 addendum sent 12:34 (13 right side, 09 re-site to the river, 10 relay
  glimpse, 14 clearing edge cover).
- **PLACES round 7** (`ed2582f6`): storm slabs +150 m / alpha 0.4, Hall massing +30 % height with a capped distance
  darken and fog disabled on hall stone, courtyard brazier attenuation 1.4→1.0 / range 27 (the real cause of the
  black floor), relay walls given an albedo (they never had one), `06-relay-road` stand added, ROUND8-CAMPS-PLAN.
  Judge `PLACES/JUDGE-round7.md`: **storm band ~30 % → ~3 % of sky at every stand**, relay walls weathered, Hall
  reads at 400 m; still failing: relay ground pad + colonnade pale, Warrens pale boulder above the mouth + pale
  right-side panel, Hall flat/unlit up close, sentries not identifiable, courtyard night median 0 on a single frame
  (flicker ±26 %). Merged `dcd45f99`. Round 8 dispatched 12:35 (those five with pixel-sample proof, then VP5 camps).
- Ship-to-main: `ralph/VP-PROGRAM` mirror CI running on `dbfec0be`; sweep at 12:48 if green.

### Owner directive 12:20 UTC — ship to `main` as we go
The owner overrode the brief's "do not merge": program work goes to `main` continuously. Mechanism (repo
convention, `ralph/conventions.md` Shipping): `main` is never pushed directly; the program branch tip is mirrored to
`ralph/VP-PROGRAM`, CI runs there, and `ralph-sweep.yml` is dispatched to fast-forward `main` (the sweep deletes the
mirror branch after shipping; it is recreated from the program tip for every ship). `origin/main` was merged into the
program branch first (`dbfec0be`, clean, 7 commits incl. the campsite split) so the ship is a fast-forward. Cadence:
after every merge whose CI is green.

### Check-in #17 (11:45 UTC) — LIFE round 5 judged and merged; CI green
- **CI `308b4fca`** (CORRIDOR r3 bake): green. Local guards on the same tree: 50/50 tests, traversal, stronghold,
  warrens all exit 0.
- **LIFE round 5** (`f2fa8906`, real population): the tool no longer spawns or hides anything for a stand — it
  positions the eye (clearance sweep, camera pulled back 3.5 m like `_capture_locations.gd`), lets streaming
  settle and REPORTS which real wild bodies are in frame; legibility moved to authored clusters in band spawn
  data; the pairing frame grants the starter through the real party/summon path; a `00-village-life` frame was
  added. Judge `LIFE/JUDGE-round5.md`: lens occlusion mostly gone, **05-ridge-camp-day now the strongest frame**
  (trainer + 2 legible creatures), mill pond solid, village edge day/night read; still failing: pairing frame
  shows the starter at 2.5–3× the trainer's apparent size (hero reveal, not side-by-side), village-life shows one
  camouflaged villager, night nearly black at relay camp, 03 open meadow aimed away from its clusters. Merged
  `d55e6ad5` (spawn data + species + capture tool; no bake impact). Round 6 dispatched 11:49: same-depth pairing,
  village gathering from existing villagers + a walker scope estimate, firelit night stand, re-aimed 03.
- **WORLD**: bounded `TIME` in `sky_clouds.gdshader` pushed (`84f6bfd9`, `time_wrap` 2500 s derived so both
  drift layers land on integer noise cells) — unverified by render; A/B in progress. Not merged until proven.
- PLACES round 7 (+ relay-from-road) and CORRIDOR round 5 (all 16 stations) rendering.

### Check-in #16 (11:14 UTC)
- Bake after the CORRIDOR r3 merge committed (`308b4fca`, 825,701 placements; 50/50 scatter/veg/perf tests).
- **WORLD**: identity check proved the rendered Environment/Sky are the objects world_look mutates, and the
  shutter-time env/sky state is bit-identical between a clean and a red frame — the wash tracks **elapsed render
  time** (a clean early `03-rise-overlook-dawn`, and a `day` frame going maroon after a long settle). Both the lane
  and the coordinator converge on unbounded shader `TIME` in `sky_clouds.gdshader` (cloud drift offsets) breaking
  noise precision at large values, with the SKY ambient/radiance path carrying it onto terrain. Wrap test dispatched
  11:15 (`mod(TIME, period)`), plus the aerial push re-apply after ground materials (`04bbb286`).
- **CORRIDOR**: bands 3–5 before frames pushed (stations 09–16) and judged (`CORRIDOR/JUDGE-b3b5-before.md`):
  12 and 16 pass, 15 borderline, 10/14 weak, **09/11/13 fail** (13 is textbook empty grass → sky). Ranked fix list
  dispatched 11:18; round 5 will render all 16 stations as one set.
- **Defect found from the road**: the Team Tether relay compound renders as untextured white walls on a bleached
  ground pad at station 11 (`00-before-b3b5/11-relay-day.png`) — a VP7 failure the relay-apparatus stand never
  showed. Sent to PLACES as a round-7 addendum with a new `06-relay-road` stand.
- **LIFE** round 5 (real population): boot-1 frames pushed before a camera/cluster fix; boot 2 in progress; the
  session compacted its context once. Judge after boot 2.
- **PLACES** round 7 in progress.

### Check-in #15 (10:38 UTC) — CORRIDOR r3 and PLACES r6 judged and merged
- **CORRIDOR round 3** (lane folder `round4/`, `dd74ce6c`): anchor RNG isolation with a shipped-config unit test
  (`test_anchors_do_not_perturb_corridor_fill_or_any_other_placement`), station 02 rebalanced, station 06 restored
  by the isolation alone, `--only` comma-list bug fixed. Judge `CORRIDOR/JUDGE-round3.md`: canopies read as
  foliage at all 8 stations, 06 exceeds baseline, 04 near keyart quality, **Bar A "yes" except station 07** (lost
  its foreground copse; below baseline), signpost text overflow at 08. Merged `b08c0ecd`, re-bake in progress.
  Round 4 dispatched 10:40: 8 new stations Band 2 far → Band 3 river/relay → Band 4 ironwood → Band 5 approach →
  Hall gate (befores first), plus the 07 copse and signpost addendum.
- **PLACES round 6** (`900f3bb7`): Warrens mound re-materialled as earth, overhang wedge removed, one rock family
  at the threshold, den stability restored (1.8 %), courtyard-night mean 12.45 (floor at the trainer 2.4×), gate
  sentries/sconces, storm slabs halved. Judge `PLACES/JUDGE-round6.md`: courtyard night reads, banners sampled
  oxblood, floating prop gone, sconces/windows read; still failing: mound reads as boulders + a new white patch
  over the doorway, Hall collapses past 100 m, storm band extent unchanged, no identifiable sentry. Merged
  `98d50074`. Round 7 dispatched 10:46: doorway patch + earth dome, Hall tower height / distance darkening,
  storm band ≤ 15 % of sky, sentries on the wall walk; camps list prepared for round 8 (VP5).

### Coverage audit against the brief (10:22 UTC, owner asked "is VP1–9 everything?")
Not everything. Remaining after the current lane rounds:
- **VP4** — only village → Band 2 walked; bands 3–5 to the Hall approach still need corridor stations + judge.
- **VP5** — camps/waystops (fire focal point, seating, supplies, a reason to exist) never judged as a set.
- **VP9** — the brief forbids faking life for screenshots and requires visible == gameplay population; the LIFE
  lane's staged-group captures (rounds 3–4) violate that, so LIFE was redirected at 10:22: staging becomes a
  diagnostic flag, deliverable frames come from authored clusters in spawn data, the pairing frame uses the real
  party/summon path. NPC walkers, ambient motion and wind remain unaddressed.
- **VP1** — dawn/night presets and the low-sun disc still open (WORLD 5b).
- **VP10** — profiling/LOD/visibility optimisation + post-optimisation visual regression check not started
  (only per-merge proxy numbers exist).
- **VP11** — handoff gallery, hero gallery, performance report, judge-history table, known limitations: not started.
- **§6 on-device FPS floor** — owner-side only (`tools/vp_capture_windows.ps1`).
Plan: finish the in-flight rounds → CORRIDOR bands 3–5 → PLACES camps round → LIFE real-population round → VP10
on the merged tree → VP11.

### Check-in #14 (10:06 UTC)
- **WORLD round 5** (`3a0fd9f8`, report only): both discriminators (fog_aerial_perspective 0; Sky REALTIME) produced
  bit-identical frames — eight explanations falsified; `fog_sky_affect` is 0.0 in this project so the fog/radiance
  mechanism was structurally impossible. The lane's own new suspicion is the useful one: unrelated config
  mutations keep producing **bit-identical** frames and the per-time aerial push moved a vista by < 1/255 —
  changes may be mutating an Environment/Sky other than the one the camera renders. Round 5b dispatched 10:08:
  print the rendered World3D environment / camera override / world_look's Environment identities in one boot,
  fix ownership if they differ and prove delivery with one toggle, else print the per-frame env/sky values for
  01-dawn (clean) vs 03-dawn (red); fix the aerial push ordering.
- **LIFE round 4** (`0786e323`, 9 frames): bbox contract + AABB near-clip floor + hiding unstaged wild bodies; 01
  day/night and 04 day pass and read; mill-pond blob gone; but the pairing frame regressed to creature-only (the
  trainer was measured from a CollisionShape3D, not visible geometry), 05 eye is inside rock, 03 Pipwing never
  cleared the 8% floor, mill-pond has a staged body crowding the right edge. Not merged. Round 5 dispatched 10:08
  (visible-geometry trainer AABB, eye clearance sweep, small-species floor, central-80% lateral bound, night 04
  under lantern light; max two boots). Judge running.
- CORRIDOR round 3 (RNG isolation done, station 02 re-render) and PLACES round 6 (courtyard floor diagnostic,
  earth-mound Warrens) in progress.

### Program-branch health at 09:55 UTC
- **CI `34cdd67a` (CORRIDOR r2 merge + bake): fully green** — first all-green run on the program branch (the
  ecology test rewrite `00745630` was superseded by this push and cancelled).
- Local guards on the merged tree: `test_scatter_rules + test_veg_corridor + test_scatter_perf_budget` 49 tests,
  0 failed; `smoke_traversal` exit 0; after the PLACES r5 merge `smoke_stronghold` / `smoke_warrens` exit 0.
- Program branch head `761393b3` carries: WORLD r1–r3, GROUND, VEG, LIFE r2, PLACES r2–r5, CORRIDOR r2, grass
  carpet ON with cull tiles, fresh bake (825,875 placements). Not merged: WORLD r4 (no-op), LIFE r3 (occluded
  stands), CORRIDOR r2 addendum (RNG isolation; lands with r3).

### PLACES round 5 (`claude/vp-places` @ 09:17) — judged 09:45, MERGED 09:46 (`60994d60`)
Evidence: `PLACES/round5/locations/` (12), `_sheet_r4_vs_r5.png`, `PLACES/JUDGE-round5.md`.
- Lane: Warrens reshaped (223→89 boulders, spoil mounds, exterior base = den rock), storm slabs lifted above the Hall
  skyline, braziers ×3 + a face torch (21/22 omnis), gate sconces + 2 sentries, banner constant → oxblood; perf
  `hall_approach` 3848; smokes green; courtyard-night mean 8.38 (target 12 missed, reported honestly).
- Judge: approach/gate night genuinely brighter with a lit window and sconce; Hall silhouette reads at 200/400 m;
  den unchanged; a legible grunt in the courtyard by day. Still failing: Warrens exterior a rock bunker with a flush
  door, threshold frame regressed (darker, overhang wedge, a third grey rock material); courtyard floor still black;
  banners still poster-red (the constant did not reach the rendered material); no identifiable gate sentry; a
  floating prop above the gate; storm band still a third of every day sky. Bars A/B still **no** for the set-pieces.
- Merged for the night/Hall gains. Round 6 dispatched 09:47: palworld-02-style earth mound with the mouth cut in,
  one rock family, courtyard floor light diagnostic then ≥ 12, banner material found and sampled, gate prop/sentries,
  storm band halved.

### CORRIDOR round 2 (`claude/vp-corridor` @ 08:33) — judged 09:05, MERGED 09:06, re-baked
Evidence: `CORRIDOR/00-before`, `round1`, `round2`, `CORRIDOR/JUDGE-round2.md`.
- Judge: station 07 restored and improved (hero tree, rock landmark, horizon); 04 a clean win (left-flank horizon
  mass); 02 improved but still right-heavy; **06 regressed** — a near-trunk wall on the path's right buries the
  mid-ground tree line and signpost (the shared-RNG side effect the lane itself named); 01/03/05/08 stable. The
  "shattered-glass" canopies in these frames are the pre-merge leaf bug, already fixed on the program branch.
- Merged clean (band `layer_anchors` + additive `_merge_band_layer_anchors`, `tools/_capture_corridor.gd`); bake
  825,875 placements. Round 3 dispatched 09:06: anchor RNG isolation (own seeded stream + byte-identical fill test),
  station 06 trunk wall, station 02 balance, re-render on the merged base via fast-forward checkout (the lane's
  auto-mode classifier blocks `git merge`).

### Check-in #12 (09:00 UTC) — WORLD r4 judged, CORRIDOR r2 / LIFE r3 under judgement, CI fix landed
- **CI:** `test_ecology_core_clusters_without_changing_the_count` rewritten to measure the mean core-gate value under
  the placements (the bin-CV proxy was dominated by the 64-tree clumps both sides share); 37/37 locally; pushed as
  `00745630` (CI commit). Post-merge `smoke_stronghold` / `smoke_warrens` exit 0 on the PLACES-r4 tree.
- **WORLD round 4** (`claude/vp-world` @ 08:51; stands + repeat test): judge `WORLD/JUDGE-round4.md` — all 9 stands
  visually unchanged from round 3; dawn overlook + moon stand still a full-frame red wash, night overlook a flat
  steel-blue wash with no near/far separation, golden sun still a huge pale oval. Lane's own findings: repeat test
  flat (not accumulation), six config explanations falsified, per-time aerial plumbing is a silent no-op. **Not
  merged.** Round 5 dispatched 09:04 with the coordinator's mechanism: fog_sky_affect + fog_aerial_perspective paint
  far terrain AND sky with the sky *radiance cubemap*, which a ShaderMaterial sky updates incrementally — two
  discriminating renders (aerial_perspective 0; Sky.PROCESS_MODE_REALTIME), then the in-game fix, sun disc ≤ 3%
  frame height, night separation, dead plumbing fixed or removed.
- **CORRIDOR round 2** pushed 08:33 (stations 02/07 restored, 04/08 horizon masses); lane blocked on a classifier-
  denied `git merge` of the program branch — told to skip merging (coordinator merges lane branches). Judge running.
- **LIFE round 3** pushed 08:54: mill-pond blob root-caused (paddlenewt is self-lit; `field_emission` compounded an
  active emission texture → reverted), stands now stage 2-species de-synced groups, pairing frame has a visibility
  assertion (false-negative: it measures against the 1920×1080 design viewport while VP_FAST renders 960×540);
  two stands (open meadow, ridge camp) regressed to a creature body filling the frame. Judge running.

### PLACES round 4 (`claude/vp-places` @ 08:18) — judged 08:33, MERGED 08:35 (`622b904e`)
Evidence: `PLACES/round4/locations/` (12), `PLACES/round4/_sheet_r3_vs_r4.png`, `PLACES/JUDGE-round4.md`.
- Lane findings: the grey band behind the Hall is the `rift_collapse` StormWall (three 520–620 m alpha slabs at
  262–356 m), never the boiler smoke; Warrens boulders now carry a stain shader; 4 courtyard braziers (omni budget
  18→22); storm-wall top softened; perf `hall_approach` 3843 (≤ 4000), smokes green.
- Judge: Warrens recoloured, not reshaped — still a boulder-dome pile, and the standing frame now shows brown
  exterior rock against the untouched grey interior; Hall 200/400 m and gate night perceptually unchanged;
  courtyard night reads only with exposure boosted ~4×; banners poster-red; first "occupied" gate signals.
  Bars A/B still **no** for the two set-pieces (daylight meadow shots alone would pass).
- Merged as incremental gain (nothing regressed at native exposure). Round 5 dispatched 08:36: earthwork Warrens
  (spoil mounds, soil apron, half-buried boulders, one rock family), Hall silhouette vs storm band (slabs lifted
  above the skyline, Hall kept darker at distance), courtyard night ≥ 12 mean at native exposure with a face light,
  sentries/lit windows/oxblood banners.

### Program-branch guard after the WORLD r3 + LIFE r2 merge (08:20) and CI on `b0fc0328`
- Local: bake 826,135 placements; `--import` ok; smoke_wild_streaming / catching / traversal / art / night_ecology
  all exit 0 (traversal South Bridge no longer fails on the merged tree); `test_grass_field.gd + test_scatter_rules.gd`
  55 tests, 1 failed: `test_ecology_core_clusters_without_changing_the_count`.
- CI `b0fc0328`: every job green except `verify-scatter-rules` (same test: 100 m-bin CV 2.511 gated vs 2.329 plain,
  needs ×1.15). Cause: the live `trees` layer now carries 19 authored anchors, 70 hero trees and water-edge bands
  (main merge + VEG) appended identically to both sides; they are clustered by construction and inflate the plain
  CV. Fix: the test strips `anchors/heroes/water_edge/verge/under` from both copies so it measures the corridor fill
  the gate acts on (test-only change; the gate itself is unchanged).

### WORLD round 3 + LIFE round 2 — merged into the program branch 07:58 UTC (`3c87d9ea`)
- WORLD r3 (day ground close-ups strongest to date; judge `WORLD/JUDGE-round3.md`) and LIFE r2 (5 stands re-framed,
  `field_emission` for paddlenewt/burrowback) merged without conflict; re-bake + guard smokes + grass/scatter unit tests
  run after the merge (results recorded below when the chain finishes).
- LIFE round 2 code-blind judge (`LIFE/JUDGE-round2.md`, 08:03 UTC): both bar questions still **no**. Ranked gaps:
  (1) the pairing frame `06-starter-beside-trainer-day` has **no starter in it** — the terrapup is spawned on the
  far side of a boulder that sits exactly where the creature should stand; (2) no frame shows a living group legible
  at native scale — the only real groups (relay camp, ridge camp) read only at 3–4× zoom; (3) night is functionally
  empty — the green field-emission exists but is far too dim at the delivered distance. Also: the mill-pond
  "creature" is a shapeless glowing blob (bug, not legibility), legible pairs share an identical pose, and the
  relay-camp trees are a visibly different tree language from village-edge/ridge-camp trees (handed to WORLD/VEG).
  Environment quality at these stands stepped up independently of wildlife (pond, open meadow, camps).
- LIFE round 3 dispatched 08:06: pairing frame re-staged with a screen-space in-frame + line-of-sight assertion,
  groups 5–10 m from camera with mixed species and de-synced poses, night stands with creatures ≤ 8 m and emission
  strong enough to read, mill-pond blob root-caused, REPORT.md before/after per stand.

### PLACES round 3 (`claude/vp-places` @ 07:11) — coordinator verdict 07:25 UTC — MERGED
Evidence: `ralph/reports/visual-parity/PLACES/round3/` (warrens, stronghold, castle-landmark 100/200/400 m, plus ground/water/survey).
- Both headline fixes were "a value silently cancelled downstream": the Hall exterior already carried the weathered
  shader but `darken` 0.24 left it brighter than the interior tone (now 0.56 + per-piece variation); the Warrens
  `tint_variation` was 65% eaten by a later lerp (now applied after it, 0.42). Frames: Hall reads as a dark
  weathered mass with distinct towers from the gate and at 100 m; Warrens boulders vary in tone, entrance darkest.
- Still open (VP8/VP6 round 4 candidates): Hall silhouette at 200–400 m is faint against the haze; no ivy/scaffold
  read at distance; Warrens is still a boulder pile without a soil apron read at the approach stand.
- Code-blind judge (`PLACES/JUDGE-round3.md`): Hall gate/courtyard day "genuinely good"; 100/200 m improved (silhouette
  and the pylon row now visible); 400 m still does not separate from the ground and a flat-edged grey storm band sits
  behind the Hall; courtyard night near-black; **Warrens approach measured pixel-comparable to round 2** — the lane's
  tint change did not reach that stand. Round 4 sent 07:40 (Warrens staining/apron/entrance with a pixel-diff proof,
  Hall far read + storm band, courtyard night practicals).
### CORRIDOR round 1 (`claude/vp-corridor` @ 07:17) — coordinator verdict 07:25 UTC — NOT merged yet
- Before/after pairs at 8 stations are nearly identical; the two emptiest sightlines (02-first-bend, 07-band2-mid)
  got nothing visible. The lane added a band `layer_anchors` merge in scatter_rules.gd (out of its file scope,
  disclosed) because band vegetation files never carried anchors — mechanism accepted in principle; round 2 sent
  with concrete per-station placements. Frames predate the canopy fix (white trees).

## Implementation decisions

- `data/config/grass_field.json` is **ON** for this program (owner directive 2026-09-01: "I don't see how a
  judge can judge anything without the actual grass in the frame"). Current `main` ships it OFF after the
  ~10 FPS Ally report (`ralph/reports/OWNER-0901-PERFORMANCE-LAG-V2.md`, 31.8M primitives/frame at
  band1_open with it on vs 9.25M off). The carpet is the intended ground read, so every evidence frame
  carries it, and **VP2 owns the real fix that report asked for**: per-tile distance culling inside
  `grass_field.gd` so far tiles stop submitting, measured with `tools/perf_render_stats.gd` primitives
  at the fixed stands. The proxy budget in §6 is re-baselined in VP0 against the carpet-on numbers.
  Until VP2 lands, this branch is not an Ally shipping candidate.

## Regressions / unresolved problems

- **VP1-G0 (golden frame black):** no longer reproduces on the branch tip with fast mode (05-spawn-low-sun renders,
  spread 1.585). Root cause not isolated (settle count / merged shader changes are the candidates). The golden
  frame that now renders is badly overexposed: a giant white sun disc, trees blown to white — WORLD round 2.
- **Capture time sink is the stale bake, not rendering:** with the scatter bake fingerprint stale, every capture
  process spends ~348 s at boot recomputing placements (`[vegetation] boot phases placements=348106`). Re-bake
  after any `vegetation.json` / `terrain_playground.json` change before capturing; fast mode alone changed
  nothing (11m42 vs 10m49) because boot dominated. **Fixed on the branch tip:** fresh bake → placements 1,669 ms, and the same fast-mode survey takes 5m03 (5 frames). Remaining boot cost (~3.5 min) is world stand-up; the locations tool amortises it over many shots per process.

## Resume note

(written at the end of every pass)
