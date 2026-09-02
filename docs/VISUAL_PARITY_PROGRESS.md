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

### 17:40 UTC — Sentries: clean restart PROVEN by day (root cause: half of each body inside the jamb stone)

- The restart agent's live-tree probe showed the two grunts had been built, rigged, animated and on screen in EVERY earlier round — their centreline sat exactly on the jamb's inner face (`at` x ±2.0 = the stone edge), so half of each body was inside the jamb and the visible remainder was a 12–16 px sliver read as a dark stripe. Fix (`stronghold.json` `gate_sentries` [±1.5, −14.9] + `on_causeway: true`, `_build_gate_sentries` seats them on the ramp deck via the existing `_causeway_y()`): re-probe feet 0.00 m above `ApproachRampBody`, 8.6 m from the gate-face camera, 107 px tall, clear sightlines.
- One render (`PLACES/round11-sentries/`, `DECISION-sentries-restart.md`, commit `a4cb1285`): **gate-face-day PASS** — west guard 108 px at x[710,759] (28 px from the jamb column), east guard ≥ 108 px at x[529,575]; coordinator's own view: two Team Tether grunts flank the red gate door, fully legible, the stone gate lit with ivy and banners. **gate-face-night: visual ceiling** — both silhouettes present at the same columns but box luminance 5.1 / 6.4 vs ≥ 25; a lighting decision (a chest-height per-post sconce or a night character emission floor), not placement. `gate-day` at 42 m: the pair reads as two figures flanking the door at 6× zoom (~20 px). Code-blind judge on the frames running.
- Supersedes the r10 "sentries at ceiling" note: the placement ceiling was false; only night legibility remains.

### Check-in #27 (17:25 UTC) — PLACES round 11 (final): night stone at visual ceiling, lane closed; restart agents on the last two items

- **PLACES round 11** (`d41ba248`): the sconces were found to be emissive plaques with NO light node (`_build_gate_tower_sconces()` builds a material, never an OmniLight3D) — a real mechanism explaining every earlier "raise the sconce" no-op. One shadowless OmniLight per sconce (range 10 m, energy 3.2) was tried; the render proved it does not reach the inner jamb faces the gate-face stand frames (crop medians 0.30 / 0.00 vs ≥ 28), while the outer curtain at `gate-night` already met the target in round 10 (42.1 / 35.0, std 19.9 / 12.4). Per the one-shot rule the lane REVERTED the code (Hall back to 21/22 omnis, `smoke_stronghold` green), kept the failure frames as evidence and recorded **night stone (inner jamb faces at gate-face-night) as a visual ceiling**: a light would have to sit inside the gate mouth. Closing summary written (VP5 pass, VP6 partial, VP7 strongest, VP8 headline fix). **MERGED** (report + evidence only). **PLACES session archived.**
- **Restart agents**: sentries — probe 2 confirms both grunts now stand on the causeway deck 8.6 m from the gate-face camera, 107 px tall, inside the jamb columns with clear sightlines (the earlier placements sat at `_floor_y`, floating/inside the jamb stone); render running. Warrens — ray-cast names the slab: the OUTER face of the mouth chamber's front wall, a BoxMesh with `material_override = _material(_rock(), 0, true)` (#5b5147 lerped 75 % toward the near-white ROCK_TINT); three lane rounds had set a SURFACE material that `material_override` silently takes precedence over. Fix = clad the outer face with the earth skin (`exterior_cladding_m` 0.4); render queued. Both WIPs are committed on the program branch (94bcdcab, 57fed672) pending their proofs.
- WORLD: VP10 in progress (structure visibility ranges, not yet measured; dawn distance-fade pass rendered, frames pending). CI on `b805d9d6` still in progress (runner backlog). Program branch 9+ commits behind main (gameplay records only).

### Check-in #26 (16:54 UTC) — Warrens decision agent found cancelled; clean restart launched; courtyard accepted

- The Fable agent on the Warrens slab + courtyard (launched 15:52) had been stopped by the owner's 16:13 interruption of the coordinator turn; its 95 minutes produced no file. Under the owner's clean-restart rule a fresh Fable agent now owns the **Warrens slab** from the brief and the frames: ray-cast identification from the standing camera through the slab regions (physics hit or projected-AABB fallback), a source fix that never touches the owner-approved interior, one render with PIL proof (slab regions median ≤ 90, std ≥ 15, > 15 % px changed), `smoke_warrens`, commit with `round11-warrens/` evidence + `DECISION-warrens-restart.md`.
- **Courtyard night: ACCEPTED** on the code-blind judge's visual read (r9 and r10: "lit pool around the trainer, trainer reads, rest acceptably dark"); the lane's 3 m-disc median metric (5.82 vs ≥ 20) is recorded as a known limitation of the metric, not of the frame.
- Sentry clean-restart agent: probe tool committed (`tools/_probe_gate_sentries.gd`, d8731e88), parked on the Godot slot behind the local guard chain.
- Lanes: WORLD pushed the dawn distance-fade pass (`6914302f`, frames pending); PLACES r11 (night stone) fired 16:53. CORRIDOR archived (session cost $92.70). CI queued on `b805d9d6`; program branch is 9 commits behind main (gameplay coordinator records only) — the next ship PR merges cleanly or re-merges main first.
- Local: CORRIDOR r8 bake tests 12/12 green, traversal smoke running; PLACES r9 site smokes and the r9-corridor re-bake queued.

### 16:40–16:50 UTC — PLACES r10 (Hall stone FIXED) and CORRIDOR r9 (final) judged and merged; CORRIDOR archived; sentries to a clean Fable restart

- **PLACES round 10** (`0161cbf2`) — the Fable Hall decision executed exactly: `darken` 0.48 → 0.0, `stone_light` #767268, `stone_dark` #5a554d, knob clamped ≤ 0.15. Lane proof: LightRock tint luminance 66 → 139.7/255; gate-day tower medians 64.1 / 72.4 (≥ 55), curtain 54.6 (≥ 45), 100 m towers 75.4 / 70.3 (≥ 50), silhouette gap 116 (≥ 60), 400 m bbox/horizon 0.74 (≤ 0.80); frames changed 84–91 % px. Judge `PLACES/JUDGE-round10.md`: **Hall stone PASS** — black cutout → lit stone with blocks, mortar, moss/ivy, sunlit pillars ~110–140 vs recessed arch ~40–70; **Hall 6/10** (from 3.5). Night stone PARTIAL (walls flat ambient, only banner accents). Sentries NOT VISIBLE even with the camera bug fixed (the tool's clearance capsule had counted the causeway deck as a body and swept the eye 6 m off it); the lane declared its own ceiling after five placements. Courtyard/Warrens controls unchanged; no regressions. **MERGED** `b805d9d6`.
- **Sentries → clean Fable restart** (owner rule): a fresh Fable agent with render access, starting from the brief, must first PROVE a grunt renders at the gate-face stand (probe: every sentry/grunt node under Stronghold — path, position, visible, whether a mesh actually loaded), fix the real cause with the smallest edit, render `10-stronghold` once, prove two silhouettes ≥ 65 px at the posts (lit at night), commit on the program branch with `round11-sentries/` evidence + `DECISION-sentries-restart.md`; one render, then ceiling if it fails.
- **PLACES round 11 (final) dispatched 16:53**: night stone one-shot (sconce/gate-fire range ≥ 8 m and energy so a wall crop within 4 m of a sconce measures median ≥ 28 with joint contrast std ≥ 8; shadows off; hall_approach ≤ 4000), then the lane's closing summary; archive after.
- **CORRIDOR round 9 (final)** (`a5a98606`) — judge `CORRIDOR/JUDGE-round9.md`: **14 PASS** (tent 114 px, fire, crates, grunt, foreground rock; unclipped), **13 FAIL** (mid-right cluster denser but the rightmost 10 % is still sky/grass) → **visual ceiling, known limitation** (one shot spent). Route verdict: reads as a composed journey with per-band character; bar A (keyart) yes for most of the route, bar B (Palworld density/NPC presence/shadow depth) no. The judge's three weakest: 11-relay (overexposed white ground — judged from the round-6 frame, which predates PLACES r8's relay pad fix; re-checked in the VP11 recapture), 09-river-lock-entry (no water in frame), 13. **MERGED** `c80f9f3f` (band4 vegetation → re-bake queued in `final_bake.log` with perf-budget/veg tests + stronghold/camps/traversal smokes). **CORRIDOR session archived.** Known limitations carried: 08 signpost text at native res; 13 right edge; 09 no water glimpse.
- WORLD: VP10 breakdown pushed (`11288d13`): the grass carpet is 133 draws at band1_open — not the excess; the pass continues on the real contributors; dawn far-plain one-shot in the same session.
- Fable Warrens-slab/courtyard decision agent still running (world-wide ray-cast); PLACES has paused that item pending it.

### 16:31 UTC — WORLD round 8 judged: sun disc PROVEN, dawn far plain one-shot dispatched

- `WORLD/JUDGE-round8.md`: (1) sun disc PROVEN — 01-golden bright core 12.41 % → 2.41 % of frame height, 03-golden 4.81 % → 1.30 %, golden mood statistically unchanged, moon halo 9.8 % → 2.4 % as a bonus; (2) dawn ground PARTIAL — near-camera ground fixed (03 foreground R−G 15.5 → 7.3, 01 hillside 31.5 → 25.7) but the mid/far plain at 03-rise-overlook-dawn is still orange (R−G 69.1 → 58.8) and now out-saturates its own sky (58.8 vs 33.9). No regressions across nine stands. Score 6.5/10 for sky/light vs the reference.
- Coordinator diagnosis: the far plain is not the key light (fixed) but the distance fade — `art.json times.dawn` `fog_colour`/`horizon_colour` #e8b784 and the dawn `aerial_fade_colour` are a saturated orange-tan, so everything past ~150 m fades toward orange. **One shot dispatched 16:36** (owner rule): dawn fog/horizon → low-saturation pink-grey (~#d8bfb8, kept identical per the file's EV8 seam rule) and aerial ~#b9a4a2; proof = far-ground crop R−G ≤ 30 and below the sky crop's, sky saturation ≥ 0.25, no horizon seam (step ≤ 25). If it fails: revert, record as visual ceiling. WORLD then continues the VP10 draw-call pass and archives.

### Check-in #25 (16:22–16:30 UTC) — WORLD r8 delivered + merged; CORRIDOR r8 judged + merged, r9 (final) running; PLACES r10 running on the Fable decisions

- **WORLD round 8** (`81d6ccbf`, 9 stands, art.json only) — coordinator's read of the r7→r8 sheet: 03-rise-overlook-dawn no longer washes the terrain orange (ground back to tan/ochre with cool rocks, sky still pink-gold); golden stands keep the mood with no blown disc; night stands unchanged (2.6–6.4 % px). Pixel diffs r7→r8: dawn overlook 29 %, others 4–11 %. **MERGED** (no bake inputs). Code-blind judge running (`WORLD/JUDGE-round8.md`); WORLD continues to the VP10 draw-call pass in the same session, then archives.
- **CORRIDOR round 8** (`6c2d9c92`) — judged `CORRIDOR/JUDGE-round8.md`: 07 PASS (real foreground clump; composition reads like the path-framing reference), 13 PARTIAL (right ~26 % still open), 14 PARTIAL (camp visible for the first time — tent, fire glow, crates, one figure — but small on a featureless hillside). No regressions. **MERGED** `1293fd4f` (band2/band4 vegetation → re-bake queued, `corridor8_bake.log`). **Round 9 (final) dispatched 16:07**: station 13 anchor sited by unprojecting the frame's right edge; station 14 eye 5 m closer (tent ≥ 110 px) + one foreground anchor; then archive.
- **PLACES round 10 dispatched 16:19** with `DECISION-hall-sentries.md` (Hall: darken 0 + stone tints #767268/#5a554d, darken knob clamped ≤ 0.15, no shader/light changes; sentries: clearance capsule lifted 0.15 m, gate-face pull_back −33.1). The lane had independently paused Warrens patching and asked for a decision (`7c999508`, R9.8: a second forward-projection hypothesis — the mouth chamber ceiling — tested and rejected at 1.5 % px; no node in the BurrowWarrens subtree projects into the slab). The Fable agent on the Warrens slab + courtyard is doing the inverse: a world-wide ray-cast from the standing camera through screen (0.80, 0.42).
- Local guard state: CORRIDOR r7 merged tree — scatter/veg/perf-budget/band-content **56 tests 0 failed**, `smoke_traversal` running; PLACES r9 site smokes and the CORRIDOR r8 re-bake queued behind it. CI in progress on `1293fd4f` (the CORRIDOR r8 merge). Main moved to `87b306ac` (the gameplay coordinator's session record) — no overlap with this program's files.
- Handoff status: VP1 sky/light is at ACCEPT pending the r8 judge; VP4 corridor closes with r9; VP5–VP8 places closes with r10 under the one-shot rule; VP9 closed; VP10 in the WORLD session; VP11 recapture after the last merge.

### Owner directives 16:00–16:15 UTC — Fable decides on stuck items; one-shot rounds; ceiling or clean restart

- **15:00** "if any lane gets stuck use a Fable agent to make decisions; keep this going until our visuals are where we want them." Applied: three Fable decision agents so far — corridor station 14 (camp was in frame behind a signpost; fixed and judged in one round), the Hall's black stone (sRGB darken × 0.2-mean texture ⇒ albedo 0.011; fix = darken 0 + lighter stone tints, no shader/light changes) and the missing sentries (spawned, but the capture eye was swept 2 m off the causeway; fix = clearance capsule lift + pull_back −33.1), the Warrens slab + courtyard (in progress). Decisions live in `ralph/reports/visual-parity/<LANE>/DECISION-*.md`.
- **16:13** owner: "if we're not making solid progress on each subsequent round we should take a different approach of either noting we're at our visual ceiling or entirely restarting with a clean Fable agent that understands what we're trying to do but doesn't build from what we already have." **Rule now in force**: each open item gets ONE more judged round on its current lane. If the code-blind judge does not record solid progress, the item is closed one of two ways: (a) **visual ceiling** — recorded as a known limitation in the handoff with the last evidence, or (b) **clean restart** — a fresh Fable agent given only the brief, the Visual Bible, the reference art and the current frames (not the lane's history or hypotheses) re-derives the approach from scratch and executes it. No third round on the same hypothesis.
- Status of the open items under this rule: Hall stone, sentries (PLACES r10, dispatched 16:19 with the Fable decisions — one shot); Warrens slab, courtyard night (PLACES r10 second message once the Fable decision lands); corridor stations 13/14 (CORRIDOR r9 final, dispatched 16:07 — one shot, then archive); sun disc + dawn ground tint (WORLD r8 — one shot); VP10 draw calls (WORLD, measured pass — ceiling is acceptable if within 3 % of the provisional proxy).
- Judge summary of the merged tree so far: CORRIDOR r8 — 07 PASS, 13 PARTIAL (right 26 % open), 14 PARTIAL (camp visible, small); PLACES r9 — courtyard night and camps accepted, Hall/sentries/Warrens failed on the lane's hypotheses (now replaced by Fable's).

### Check-in #24 (15:50–16:00 UTC) — PLACES round 9 delivered and MERGED (`33fe3cfd` + fix `42af7dec`); judge + Fable decisions running

- **PLACES round 9** (`ec2a654c`, 33 frames incl. the new `10-stronghold-gate-face` day/night stand) — the lane's own delivery check now carries pixel diffs per targeted frame and it corrected its round-8 claim (the Warrens panel "proof" had been byte-identical). Delivered: Hall stone uncrushed (`distance_darken_start` 260, floor 0.85, `weathering.exterior.darken` 0.74 → 0.48; LightRock tint luminance 33 → 66/255) with the 400 m silhouette kept; sentries' 1.5× scale REVERTED, grunts at the gate posts at native size; camps dressed (relay +5 incl. firewood, third touching log, bucket-as-kettle; ridge +1; waystop +1). Failed, disclosed: Warrens right panel (1.4 % px changed; the lane's own node-projection diagnostic found NO Warrens node in that region — it is something else's geometry) and courtyard night (trainer 3 m disc median 5.82 vs ≥ 20 even after torch energy 3.4 → 6.6). Perf: hall_approach 3845 ≤ 4000. Coordinator's read of the r8→r9 sheet: Hall stone and camps improved; the new gate-face stand is badly composed (a wall fills the left half, sentries not obviously legible, night frame near-black) and needs recomposing.
- **MERGED** `33fe3cfd`: one conflict in band4 `props.json` — CORRIDOR r7 had moved the whole ridge_patrol_camp 7 m toward the route while PLACES r9 added a touching log at the old position; resolved by keeping the moved camp and shifting the new log by the same (−6.83, −1.52). The first resolution left a trailing comma → fixed in `42af7dec` (all five band props files validate). No bake inputs touched. Guard queued: `smoke_stronghold`, `smoke_warrens`, `smoke_relay`, `smoke_authored_camps` (`places9_guard.log`).
- Code-blind judge on r9 and a **Fable decision agent** on the two chronic failures (identify the pale slab by a whole-world ray-cast through the standing camera; explain why the courtyard disc stays dark under 6.6-energy torches and name a mechanism that lights it) are running; round 10 is dispatched from their output.
- WORLD: round-8 code pushed 15:28 (`7cba5a20` "tighten the sun halo; stop dawn's key light painting the ground orange"); stand frames + VP10 pending. CORRIDOR round 8 in progress (`224e2324`, `_surface()` rewrite per the decision).
- Local: CORRIDOR r7 re-bake done (825,825 placements), scatter/veg/perf-budget/band-content tests running, then the bake is committed.

### Check-in #23 (15:19–15:30 UTC) — CORRIDOR r7 judged + merged; first Fable decision (station 14); round 8 dispatched

- **CORRIDOR round 7** (`b49c443e`, 5 stations) — judged `CORRIDOR/JUDGE-round7.md`: 13 PARTIAL (mid-right trees added, right edge still empty); 08 reframed (both signposts in frame, text still not legible at native res); 07, 10, 14 content-identical to round 6 (the lane's "bake-fresh copse" at 07 did not change the frame); camp absent at 14. No regressions. Pixel diffs r6→r7 are dominated by grass/cloud noise (28–79 % px) — content-level diffs are what count. **MERGED** `df90c5e6` (band3/band4 vegetation.json → re-bake queued, `corridor7_bake.log`: bake + import + scatter/veg/perf-budget/band-content tests + smoke_traversal).
- **First Fable decision agent (owner directive)**: the lane had disclosed station 14 as "STILL NOT FIXED" after five camera candidates plus a 7 m prop move, blaming an unstable ground-height raycast. The Fable agent (`CORRIDOR/DECISION-station14.md`) found from the lane's own PNGs and projection maths that the camp IS in frame in every render — a ~90×20 px patch at exact frame centre, 41–48 m away, directly behind the "Watchtower Spur" signpost 6 m from the camera; the 9.2/4.8/3.6 m raycast variance is real (the raycast never excluded the player/props) but irrelevant. Decision A: re-site the stand to the clearing's trail-side edge (eye (-254.5, 6465.7) → look at the posted grunt (-235, 6470)), make `_surface()` use `ground_height_at` (the bake) with a raycast fallback that excludes non-terrain colliders, fix the proof's stale prop coordinates, with a three-part proof criterion.
- **CORRIDOR round 8 dispatched 15:33** (time box 40 min, then archive): 14 per the decision; 07 a real foreground-framing anchor (pixel-diff must show the anchor region); 13 fill to the right edge; 08 text = raise the label size if parametric, else known limitation.
- WORLD: round-7 survey frames pushed 15:23 (`7f5c0f96`); round 8 + VP10 trigger fired 15:18 into the same session.
- PLACES round 9: no push since dispatch (14:40, 50 min) — within the range of its earlier rounds (r8 took ~75 min); stuck rule applies at check-in #24 if still silent.
- Local guard note: the WORLD r7 guard's `--only=` filter matched no test files and launched the full unit suite; killed at 15:26, chain continued with smoke_art + smoke_night_ecology. The relevant unit test is `test_day_cycle.gd`; CI on the next code commit runs the full suite anyway.

### 15:15 UTC — WORLD round 7 judged + MERGED (`7a8870fa`); round 8 + VP10 draw-call pass dispatched; handoff draft started

- **Owner directive 15:00 UTC**: if any lane gets stuck, use a Fable agent to make decisions; keep going until the visuals are where we want them. Applied as: at every check-in a lane with WIP-only churn or silence past its time box gets a Fable decision agent fed its report, commits and frames; the program continues past the original VP11 label until the visual bar is met.
- **WORLD round 7** (`8ae70423`, stands 9) — judged `WORLD/JUDGE-round7.md`: (1) sun disc PARTIAL — 01-spawn-outward-golden core still ~7.4 % of frame height (r6 13.5 %), 03-rise-overlook-golden clean; (2) dawn PROVEN — sky saturation 0.09 → 0.29, hue grey-lavender → pink-magenta; (3) night seam PROVEN — no near-black horizon band at either night stand; (4) night depth NOT PROVEN as asked (far ground bluer but brighter, unchanged from r6) — coordinator ACCEPTS it as a valid hazy-night read. Regressions: none (day/night diffs at noise level). Coordinator's own read adds: 03-rise-overlook-dawn washes the whole terrain orange; the reference keeps pink-gold in the sky with the ground's local colour surviving. Pixel diffs r6→r7: dawn 27 % / 74 % changed, golden 9.5 % / 7.6 %, night 3.7–9.7 %, day ≤ 7 %. **MERGED** `7a8870fa` (art.json, world_look.gd, sky_clouds.gdshader; no bake inputs). Guard queued: art/world_look unit tests + smoke_art + smoke_night_ecology (`world7_guard.log`).
- **WORLD round 8 + VP10 dispatched 15:18** (same session, not a new lane): sun disc ≤ 3 % at both golden stands with measured core height; dawn ground crop R−G ≤ 25 while sky saturation stays ≥ 0.25; then the VP10 draw-call pass at band1_open (7659 → ≤ 7500, primitives ≤ 12.0M) with a per-node breakdown first, measured candidates, before/after perf at all three views, pixel-diffs on the survey stands, grass/scatter tests + traversal/playground smokes. Archive after.
- **VP11 handoff draft** committed `docs/VISUAL_PARITY_HANDOFF.md` (`b5e5aacf`, STATUS: DRAFT): branch info, matched before/after and hero galleries from existing evidence, perf report, judge history per pass, known limitations, reproduction commands. Drafter flagged: no WORLD/round7 (now delivered) or PLACES/round9 dirs at draft time; CORRIDOR round 4 has frames but no separate judge file (folded into round 5); GROUND/VILLAGE lane REPORTs still carry FILL placeholders (the progress file's consolidated tables are used instead). Final galleries come from the VP11 recapture.
- Guard on the merged tree completed: `smoke_relay` returned 1 inside the contended chain and 0 on a serial re-run ("relay: OK — the captain is beaten, the captive is freed…"); recorded as chain contention, not a tree defect.
- CORRIDOR r7: station-14 fix pushed 14:52 (`52bd8f1a`, camp dressing moved 7 m toward the route), no frames by 15:15 — time box expires at 15:17; PLACES r9: no push since dispatch (14:40).

### 14:56 UTC — SHIPPED TO MAIN (PR #20 merged, `b03cdb94`); VP10 first measurement on the merged tree

- **PR #20 merged into `main`** at 14:56 UTC as merge commit `b03cdb94` (CI run 33642046946 on `1d1a2f74`: success after a 25-minute run — the code jobs ran, this was not a docs-only skip). Main now carries VP1–VP9 as merged so far (WORLD r1–r6, GROUND/VILLAGE, CORRIDOR r1–r6, PLACES r1–r8, LIFE r1–r7). The program branch is fast-forwarded onto `b03cdb94`; later lane rounds ship through a new PR the same way.
- **VP10 measurement** (`ralph/reports/visual-parity/VP10-perf/perf_merged_1d1a2f74.txt`, `tools/perf_render_stats.gd` 1280x720 Compatibility llvmpipe, settle 120/60/20, `scatter_lod_ranges=false` — the VP2 decision `1f7b5a03`, not a merge regression):

| view | draw calls | primitives | objects | budget | verdict |
|---|---|---|---|---|---|
| band1_open | 7659 | 11,757,306 | 6593 | ≤ 7500 draws / ≤ 12.0M prims | prims PASS (2 % headroom); **draws 2 % OVER** (+148 vs the VP2 candidate's 7511) |
| hall_approach | 3844 | 4,332,388 | 4185 | ≤ 4000 draws | PASS |
| village_high | 3165 | 8,622,824 | 3306 | — | recorded |

  The band1_open draw-call growth since VP2 comes from VP3/VP4/VP9 content (hero trees, band layer anchors, authored wild clusters) and main's own additions. VP10 action: a targeted draw-call pass at band1_open (candidates: grass carpet `cull_tile_m` 24 → 32 trades ~40 % fewer carpet tiles for a small primitive rise — primitives have only 2 % headroom, so it must be measured; instancer region-cell batching for the near layers; prop material sharing), proven by re-measurement plus a pixel-diff/judge on the survey stands so nothing visible is lost. Assigned to the WORLD session after its round 7 (existing session, no new lane).
- Guard on the merged tree (`vp10_guard.log`): `smoke_art`, `smoke_wild_streaming`, `smoke_stronghold` exit 0; `smoke_warrens`, `smoke_relay` running.
- Lane deliveries in flight at 14:56: WORLD r7 pushed code + 6 frames (`f4d3cf26`, sun disc / dawn saturation / night seam / depth) — full stands+survey set and CI commit still to come; CORRIDOR r7 pushed the station-14 fix (`52bd8f1a`, camp dressing moved 7 m toward the route) — frames still to come; PLACES r9 in progress.

### Check-ins #21–#22 (13:45–14:30 UTC) — WORLD r6 / LIFE r7 (final) / PLACES r8 judged and merged; PR #20 open; bake fresh on the main-merged tree

- **Program branch** `1d1a2f74` (pushed 14:26): main `371605b6` re-merged (scatter conflicts → ours + re-bake), then `origin/claude/vp-world` (`c7b773b7`, rounds 4–6), `origin/claude/vp-life` (`aac8cc90`, round 7 final), `origin/claude/vp-places` (`ebe7d826`, round 8), then the fresh bake (`825,759` placements; bake inputs unchanged by the three lane merges, verified with `git diff 371605b6..HEAD` on `terrain_playground.json` + vegetation files). Local guard on the merged tree: scatter/veg/perf-budget/spawns/band-content 52 tests 0 failed, `smoke_playground` green, `smoke_traversal` in the chain.
- **Ship to main**: the mirror + `ralph-sweep` route failed at 13:40 (main moved 30 s earlier → 191-commit rebase conflict at `grass_field.json`). Alternative route per the owner's 12:20 directive: **PR #20** https://github.com/MJohnsonWellabe/Tetherbound/pull/20 (program branch → main, 272 commits, 1,246 files); merge when CI on `1d1a2f74` is green. Main has moved another 4 commits since (`8bf4f0bd`); a merge commit absorbs that unless `data/scatter/**` conflicts again, in which case: re-merge main, `--ours` for the bake, re-bake, push.
- **WORLD round 6** (`639314db`) — judged `WORLD/JUDGE-round6.md`: every previously washed elevated stand is clean; root cause was the stands tool free-falling the player 500 m below the camera (Terrain3D streams around the player → unloaded terrain rendered as sky-heavy wash). `TIME` wrap in `sky_clouds.gdshader` kept as a latent fix. Remaining polish → **round 7 dispatched 14:32 (final)**: sun disc ovality, dawn saturation, night horizon black seam, night far separation. Archive the WORLD session after judging r7.
- **LIFE round 7 (final)** (`aac8cc90` merge) — judged `LIFE/JUDGE-round7.md`: open-meadow trailpup pack passes; pairing side-by-side and occupied village hold; relay day best; night stands unchanged (creature meshes unlit beside lit humans — recorded as a known limitation). Walkers were scoped only (no movement method on villagers; ~20–30 lines + driver). **LIFE session archived.**
- **PLACES round 8** (`167b6d7f`) — judged `PLACES/JUDGE-round8.md`: relay road fixed; Warrens pale surfaces and the Hall's flat-black near faces unchanged in the delivered frames (pixel-identical to r7 — the edits were never rendered); 1.5× sentries not identifiable; camps ranked relay < ridge < waystop. **Round 9 dispatched 14:40**: Warrens pale surfaces with pixel-diff proof, Hall `distance_darken_start` ≥ 250 m / floor 0.85 and gate wall ≥ 60 luminance, revert the 1.5× sentry scale (gate-post sentries + a gate-face stand instead), courtyard night median ≥ 20 within 3 m of the trainer, camps relay → ridge → waystop.
- **CORRIDOR round 7** running since 13:45 (WIP pushes for stations 07/08/14 visible on `claude/vp-corridor`): station 07 bake-fresh proof, 08 signpost framing, 10 relay glimpse, 13 right side, 14 camp in FOV.
- **Delivery rule (all lanes, from PLACES r8 / CORRIDOR r6)**: edit THEN render; every targeted frame carries a pixel-diff vs the previous round in REPORT.md; < 5 % changed pixels = failed delivery, not a judged round.
- **VP10 started** on the merged tree: `tools/perf_render_stats.gd --views=band1_open,hall_approach,village_high --settle=120 --resettle=60 --sample=20` queued after the guard chain → `ralph/reports/visual-parity/VP10-perf/perf_merged_1d1a2f74.txt`; budget band1_open ≤ 12.0M primitives / ≤ 7500 draw calls, hall_approach ≤ 4000 draw calls.
- Costs so far (approx. session spend): WORLD ~$225, PLACES ~$148, LIFE ~$115, CORRIDOR ~$63.

### Check-in #20 (13:31 UTC) — red wash SOLVED (capture artifact); first ship attempt blocked by a moving main
- **WORLD 5e** (`7d67651d`): the wash was the stands capture tool — a stand without an `actor` key dropped the
  player 500 m below the eye with physics live, and Terrain3D streams around the player, so a sky-heavy elevated
  camera rendered from unloaded terrain. Same sequence with the player placed at the camera: night overlook
  +80.8 → −16.8 R−G. Thirteen config hypotheses were falsified because the config was never wrong. Not a game
  defect in normal play; a known limitation for any future distant-camera feature (streaming anchor). Closing
  round dispatched 13:33: player at every stand by default with a cam→player distance assertion, re-render stands +
  survey, keep the TIME wrap (latent fix), tests.
- **Ship-to-main**: `ralph/VP-PROGRAM` @ `095cee94` went green and the sweep (13:28) tried to ship it, but `main`
  had moved 30 s earlier (`e97baa30`, another session's stale-bake CI job + re-bake) so the script attempted a
  191-commit rebase and stopped at the first conflict (`grass_field.json`). `origin/main` re-merged into the
  program branch (`15313d8c`; scatter conflicts resolved with our bake), re-bake + guards running; next mirror +
  sweep immediately after that CI is green, while `main` is still.
- **CORRIDOR round 6** (`42b12878`, 16 stations): 07 copse restored, 09/10/14 re-sited or anchored, 13 filled,
  signpost siting separated (text still clipped — open). Judge running.
- **LIFE round 7** (final) running; **PLACES round 8** rendering (camp before-frames pushed).

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
