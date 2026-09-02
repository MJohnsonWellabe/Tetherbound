# Meadows Visual Parity — Handoff (candidate for external visual judgement)

**STATUS: DRAFT — VP10/VP11 in progress**

This document packages the Meadows Visual Parity program (`docs/VISUAL_PARITY_STAGED_GOAL_PROMPT_V2.md`)
for external visual review. It is generated from `docs/VISUAL_PARITY_PROGRESS.md` (the authoritative
checkpoint) and the evidence under `ralph/reports/visual-parity/`. VP10 (performance retention) and VP11
(this handoff) are not finished — the draft status above reflects that; the coordinator flips it to final
once VP10's draw-call pass and a fresh recapture land.

---

## 1. Branch info

| item | value |
|---|---|
| program branch (this session's harness-pinned branch; the owner prompt named `codex/meadows-visual-parity`, but the harness pins the branch below, so this branch *is* the visual-parity branch — see `docs/VISUAL_PARITY_PROGRESS.md` "Branch and SHAs") | `claude/coordination-subagents-3fhz1x` |
| starting `main` SHA | `252ccc81` (2026-09-01, `origin/main` at program start) |
| ship-to-main merge | `b03cdb94` — PR #20, merged 2026-09-02 14:56 UTC (CI run 33642046946 on `1d1a2f74`, green after a 25-minute run). Carries VP1–VP9 as merged at that point (WORLD r1–r6, GROUND/VILLAGE, CORRIDOR r1–r6, PLACES r1–r8, LIFE r1–r7). |
| latest pushed SHA (this session, `git rev-parse --short HEAD`) | `f0740c96` |

### Per-pass milestone commits

| pass | commit | description |
|---|---|---|
| VP-PRE | `f4afc9d9` | environment capability check passes (5/5); blind critique recorded |
| VP0 baseline | `401d7217` | baseline evidence set (village/pond/survey) + six parallel lane sessions recorded |
| VP1–VP3 candidate (checkpoint) | `5b8a53a6` | checkpoint frames of the merged program branch (53 frames, 960x540) + perf inside budget, taken after WORLD r2 + PLACES r2 merged |
| VP2 perf (cost candidate) | recorded in `ralph/reports/visual-parity/VP2-perf/perf_iterC_lodoff*.txt`, folded into `3c87d9ea` | iteration C + `scatter_lod_ranges=false`: band1_open 7511 draws / 11.80M prims, hall_approach 3975 draws — meets every §6 proxy budget |
| VP4 corridor (WORLD r3 + LIFE r2 merge) | `3c87d9ea` | merge of `origin/claude/vp-life`; program branch tip carrying WORLD r1–r3, GROUND, VEG, LIFE r2 at that point |
| VP5–VP8 places (round 3) | `81c4232a` | `visual(VP6,VP8): merge PLACES round 3` — dark weathered Hall exterior, Warrens tone variation |
| VP5 places (round 2, first pass) | `adaee521` | merge of `origin/claude/vp-places` round 2 (Bar B yes for village) |
| VP9 life (round 7, final) | folded via `3c87d9ea` ancestry and the later `371605b6` re-merge; final LIFE frames at `aac8cc90` (lane branch) | LIFE lane's final round, merged onto the program branch before the PR #20 ship |
| Ship to main | `b03cdb94` | PR #20 merge: VP1–VP9 candidate (sky, ground, vegetation, corridor, places, life) |
| VP10 re-bake on merged tree | `1d1a2f74` | re-bake playground scatter on the main-merged tree (825,759 placements; bake inputs unchanged by the WORLD/LIFE/PLACES merges) |
| VP10 first perf measurement | `8db85108` | first perf measurement on the merged tree — band1_open draws 2% over proxy budget, prims/hall pass |
| VP10 perf retention numbers | `f0740c96` (current HEAD) | perf retention numbers on the merged tree (band1_open 7659 draws / 11.76M prims, hall_approach 3844, village_high 3165) |

### Lane branches

All merged through the program branch, never merged blind (coordinator reviews and cherry-picks):

- `claude/vp-world` — VP1 (sky) + VP2 (ground/terrain) + VP3 (vegetation), rounds 1–6+
- `claude/vp-places` — VP5 (village/tournament/camps) + VP6 (Warrens) + VP7 (Relay) + VP8 (Hall), rounds 1–8+
- `claude/vp-corridor` — VP4 (travel corridor), rounds 1–6+
- `claude/vp-life` — VP9 (world life/population), rounds 1–7 (final)

Earlier, wrapped-before-pushing-frames lane sessions (owner directive "they're burning my usage",
2026-09-02 01:30 UTC): `claude/vp-ground`, `claude/vp-veg`, `claude/vp-village`, `claude/vp-hall`,
`claude/vp-sky`, `claude/vp-warrens`. Their surviving code/config was reviewed and folded into the area
coordinator lanes above; none of their frames are cited in this handoff.

---

## 2. Matched before/after gallery

All paths verified to exist under `ralph/reports/visual-parity/` unless marked PENDING.

| location | BEFORE | AFTER | judge round |
|---|---|---|---|
| Village day | `VP0-baseline/locations-1080p/01-village-standing-day.png` | `PLACES/round2/locations/01-village-standing-day.png` | PLACES round 2 (Bar B **yes** for village) |
| Village night | `PLACES/round1/locations/01-village-standing-night.png` (VP0 baseline captured day only — no VP0 night frame exists) | `PLACES/round2/locations/01-village-standing-night.png` | PLACES round 2 |
| Mill pond | `VP0-baseline/locations-1080p/02-mill-pond-standing-day.png` | `WORLD/round3/locations/02-mill-pond-standing-day.png` | WORLD round 3 (day ground close-ups "strongest to date") |
| Band1 open meadow | `LIFE/round1/03-band1-open-meadow-day.png` | `LIFE/round7/03-band1-open-meadow-day.png` | LIFE round 7 ("PASS, decisively" — 3 trailpup unmistakable) |
| River/water edge | `VP1-3-after/ground/water-02-river-eye.png` | `WORLD/round3/ground/water-02-river-eye.png` | WORLD round 3 |
| Ridge/overlook | `WORLD/round1/before/03-rise-overlook.png` | `WORLD/round6/stands/03-rise-overlook-day.png` | WORLD round 6 (red-wash root-caused and fixed; "every previously washed elevated stand is clean") |
| Forest edge (stone-root corridor entry) | `CORRIDOR/00-before/06-stone-root-entry-day.png` | `CORRIDOR/round6/06-stone-root-entry-day.png` | CORRIDOR round 6 |
| Travel corridor (full 16-station set) | `CORRIDOR/00-before-b3b5/_sheet.png` (bands 3–5) + `CORRIDOR/00-before/_sheet.png` (bands 1–2) | `CORRIDOR/round6/_sheet.png` | CORRIDOR round 6 (`JUDGE-round6.md`) |
| Tournament ground | `VP0-baseline/locations-1080p/01-village-tournament-day.png` | `PLACES/round2/locations/01-village-tournament-day.png` | PLACES round 2 |
| Warrens exterior | `PLACES/00-before/locations/04-warrens-approach-day.png` | `PLACES/round8/locations/04-warrens-approach-day.png` | PLACES round 8 (pale boulder/panel **PROVEN by sample** fixed; round 9 dispatched for remaining items — see §6) |
| Team Tether Relay | `PLACES/00-before/locations/06-relay-apparatus-day.png` | `PLACES/round8/locations/06-relay-apparatus-day.png` | PLACES round 8 (ground pad ≤120 lum **PROVEN**) |
| Relay camp | `PLACES/round8/camps-before/05-relay-camp-standing-day.png` | `PLACES/round8/locations/05-relay-camp-standing-day.png` | PLACES round 8 (R8.6, minimal dressing added deliberately) |
| Ridge camp | `PLACES/round8/camps-before/08-ridge-camp-standing-day.png` | `PLACES/round8/locations/08-ridge-camp-standing-day.png` | PLACES round 8 |
| Waystop | `PLACES/round8/camps-before/09-waystop-standing-day.png` | `PLACES/round8/locations/09-waystop-standing-day.png` | PLACES round 8 |
| Hall approach | `PLACES/00-before/locations/11-castle-landmark-approach-day.png` | `PLACES/round8/locations/11-castle-landmark-hall-200m-day.png` | PLACES round 8 ("Hall material read at ≤100m improved"; 200–400m still soft — see §6) |
| Hall gate/courtyard | `PLACES/00-before/locations/10-stronghold-gate-day.png` + `PLACES/00-before/locations/10-stronghold-courtyard-day.png` | `PLACES/round8/locations/10-stronghold-gate-day.png` + `PLACES/round8/locations/10-stronghold-courtyard-day.png` | PLACES round 8 (day gate reads; **courtyard night median 1.49 vs target 8 — FAILED**, open) |
| Creature-in-world | `LIFE/round1/05-ridge-camp-day.png` | `LIFE/round7/05-ridge-camp-day.png` | LIFE round 7 ("strongest overall" single frame) |
| Combat | none (no pre-VP combat baseline was captured) | `VP1-3-candidate/combat/02-arena-opens.png` | not separately judged by name; captured at the VP1–VP3 checkpoint (06:14 UTC) and unchanged since — LIFE's own report names "total absence of any action/combat framing" as an open limitation |
| Building/home | none (VP0 did not capture building interiors) | `VP1-3-candidate/buildings/07-farmhouse-interior.png` | not separately judged by name; same VP1–VP3 checkpoint |

---

## 3. Hero gallery

Ten slots per the VP11 brief. The first slot is a triplet (3 strongest wide Meadows views); the rest are
single frames.

| slot | frame path(s) |
|---|---|
| 3 strongest wide Meadows views | `WORLD/round6/stands/01-spawn-outward-day.png`, `WORLD/round6/stands/03-rise-overlook-day.png`, `WORLD/round6/stands/03-rise-overlook-golden.png` |
| Village day | `PLACES/round2/locations/01-village-standing-day.png` |
| Village night | `PLACES/round2/locations/01-village-standing-night.png` |
| Creature/world frame | `LIFE/round7/05-ridge-camp-day.png` |
| Combat/world frame | `VP1-3-candidate/combat/02-arena-opens.png` |
| Building/home frame | `VP1-3-candidate/buildings/07-farmhouse-interior.png` |
| Tournament | `PLACES/round2/locations/01-village-tournament-day.png` |
| Warrens | `PLACES/round8/locations/04-warrens-standing-day.png` |
| Team Tether Relay | `PLACES/round8/locations/06-relay-apparatus-day.png` |
| Hall approach | `PLACES/round8/locations/11-castle-landmark-hall-200m-day.png` |

---

## 4. Performance report

**Tool and settings (unchanged across the whole program):** `tools/perf_render_stats.gd`, Compatibility
renderer (`gl_compatibility`), llvmpipe software GL — structural counters only (draw calls, primitives,
objects; not real FPS). Evidence frames are captured at 1920x1080 (`tools/vp_capture.sh`); perf stands run
at 1280x720. Graphics preset: the shipped defaults in `project.godot` `[rendering]` (directional shadow
2048, positional atlas 2048, soft shadow filter 2, msaa_3d 2x) plus `data/config/performance.json` as
committed — there is no in-game preset system.

**§6 acceptance numbers — PROVISIONAL, owner to confirm:**

| item | value |
|---|---|
| target platform | Windows / ROG Ally |
| minimum sustained FPS | 45 (PROVISIONAL) — cannot be measured in this container (software GL); owner measures on the Ally |
| minimum 1% low FPS | 30 (PROVISIONAL) |
| container-enforced proxy per pass | `band1_open` primitives ≤ 12.0M, draw calls ≤ 7500; `hall_approach` draw calls ≤ 4000 (`docs/PERFORMANCE_BUDGET.md` §0.5) |

### Baseline (owner-reported lag + VP0)

| state | view | draw calls | primitives | objects | source |
|---|---|---|---|---|---|
| carpet OFF (shipped main) | band1_open | 7366 | 9,250,290 | 6361 | `OWNER-0901-PERFORMANCE-LAG-V2` |
| carpet ON, one MultiMesh (owner's laggy build) | band1_open | 7320 | 31,757,567 | 6315 | `OWNER-0901-PERFORMANCE-LAG-V2` (this is the ~10 FPS Ally report) |
| VP0 baseline: carpet ON, `cull_tile_m=0` | band1_open | 7409 | 31,672,479 | 6378 | `GROUND/perf/perf_before_tile0.txt` |
| VP0 baseline: carpet ON, `cull_tile_m=0` | village_high | 2860 | 28,277,296 | 3050 | same |

### VP2 iterations (terrain/ground-cover optimization)

| state | view | draw calls | primitives | objects | source |
|---|---|---|---|---|---|
| iteration 0: cull_tile_m=16 + far thinning/reach caps/tile LOD | band1_open | 8633 | 21,287,781 | 7612 | coordinator 04:23 UTC |
| iteration B: shipped density + cull tiles 16m + far thinning/reach/tile LOD + VEG lod ranges | band1_open | 8593 | 12,583,284 | 7573 | `VP2-perf/perf_iterB.txt` |
| iteration C (candidate): B + trees/grove/deadfall/rocks LOD 420/460/260/220 + cull_tile_m 24 | band1_open | 7839 | 12,217,644 | 6812 | `VP2-perf/perf_iterC.txt` |
| iteration C, `hall_approach` | hall_approach | 4270 | 4,634,502 | 4615 | same |
| **iteration C + `scatter_lod_ranges=false` (VP2 COST CANDIDATE, committed)** | band1_open | **7511** | **11.80M** | 6481 | `VP2-perf/perf_iterC_lodoff_band1.txt` |
| same | hall_approach | **3975** | 4.20M | 4317 | `VP2-perf/perf_iterC_lodoff.txt` |

VP2 A/B testing showed `scatter_lod_ranges=true` costs +0.4M primitives and +330 draw calls at no proven
visual gain — left `false` for this reason; the flag stays available for future tuning.

### VP1–VP3 checkpoint (all merged so far)

| state | view | draw calls | primitives | objects | source |
|---|---|---|---|---|---|
| WORLD r2 + PLACES r2 merged (06:14 UTC checkpoint) | band1_open | 7668 | 11,817,644 | 6608 | `VP1-3-candidate/perf_render_stats.txt` |
| same | village_high | 3122 | 8,579,837 | 3263 | same |
| same | hall_approach | 3795 | 4,361,609 | 4137 | same — all inside budget with everything merged at that point |

### VP10 — measurement on the merged tree (post PR #20 ship)

`ralph/reports/visual-parity/VP10-perf/perf_merged_1d1a2f74.txt`, settle 120/60/20, `scatter_lod_ranges=false`
(the VP2 decision, not a merge regression):

| view | draw calls | primitives | objects | budget | verdict |
|---|---|---|---|---|---|
| band1_open | 7659 | 11,757,306 | 6593 | ≤ 7500 draws / ≤ 12.0M prims | prims PASS (2% headroom); **draws 2% OVER** (+148 vs the VP2 candidate's 7511) |
| hall_approach | 3844 | 4,332,388 | 4185 | ≤ 4000 draws | PASS |
| village_high | 3165 | 8,622,824 | 3306 | — | recorded, no budget set |

**VP10 draw-call pass at band1_open: IN PROGRESS.** The growth since VP2 comes from VP3/VP4/VP9 content
(hero trees, band layer anchors, authored wild clusters) plus main's own additions. Candidates identified
but not yet measured: grass carpet `cull_tile_m` 24 → 32 (trades ~40% fewer carpet tiles for a small
primitive rise — primitives have only 2% headroom left, so it must be re-measured before landing); instancer
region-cell batching for near layers; prop material sharing. Assigned to the WORLD session; not yet
re-measured or re-judged.

### Optimization decisions (carried into VP10)

- **Grass carpet:** `data/config/grass_field.json` `enabled: true` for the whole program (owner directive:
  "I don't see how a judge can judge anything without the actual grass in the frame"). Per-tile distance
  culling (`cull_tile_m`) plus far-band thinning and tile LOD inside `grass_field.gd` bring the carpet from
  31.8M primitives (owner's laggy build) down to 11.80M at the VP2 candidate — this is the real fix for the
  ~10 FPS Ally report, not reverting the flag to `false`.
- **`scatter_lod_ranges`** left `false`: the A/B test showed the `true` arm costs +0.4M primitives / +330
  draw calls with no measured visual gain.
- **Tree/grove LOD ranges:** trees 420–700m / grove 460–800m depending on iteration, deadfall 260m, rocks
  220m — tuned in VP2 iteration C, unchanged since.
- **§6 on-device FPS floor is unmeasured** in this container (software GL only) — owner-side measurement
  required on the actual Ally via `tools/vp_capture_windows.ps1`.

---

## 5. Judge history per pass

### VP-PRE — environment capability check
5/5 checks passed: Godot 4.7 binary + import, real screenshot on disk, verified as a real rendered frame,
test command runs (`tests/smoke_art.gd`), blind judge invocable from this environment (not deferred). One
finding carried forward: `apply_time("golden")` rendered a flat black frame under this pipeline (VP1-G0).
Evidence: `VP-PRE/JUDGE.md`. **Final state: PASS (capability check, not a visual pass).**

### VP0 — baseline
Judged on village + mill pond (carpet ON, `main@252ccc81` + grass_field enabled). Bar A (keyart world) **no**,
Bar B (Palworld kind of game) **no**. Ranked gaps: (1) sky — tan/brown smeared clouds in 7/9 frames, "reads
as a broken shader"; (2) no creature anywhere in the set; (3) lighting disagrees with itself (clear sky, no
ground shadows, hard sun disc, no distance haze). Also: single tree silhouette repeated everywhere, static
NPCs, no mill wheel, no tournament dressing. Response: (1)+(3) → VP1; creatures → VP0 combat/creature
captures + VP9; tree variety → VP3; paddocks/tournament/mill dressing → VP5; NPC life → VP9. Evidence:
`VP0-baseline/JUDGE-village-pond.md`. **Final state: PASS (baseline established), problems routed forward.**

### VP1 — sky, sun, global lighting, atmosphere
Rounds 1–6 (WORLD lane). Round 1 fixed cloud form/scale and the clock-drift bug (`set_clock_frozen`).
Round 2 root-caused and fixed the white-canopy regression (`adjust_bsc` → `adjust_bcs` typo + a lost
runtime texture); first "yes" of the program (Bar A day frames, Bar B on environment). Rounds 3–5 chased a
red-wash defect at elevated/night stands through thirteen falsified config hypotheses. Round 5e solved it:
the capture tool dropped the player 500m below unloaded terrain at any stand without an `actor` key —
Terrain3D streams around the player, so the camera rendered unloaded ground (a capture-tool bug, not a
shader bug, though flagged as a latent risk for any future distant-camera gameplay feature). Round 6
confirmed every previously-washed stand is clean. **Final state: PASS**, with round-7 polish (sun disc
ovality, dawn saturation, night horizon seam) dispatched but not confirmed by a fresh judge round in this
handoff's evidence set.

### VP2 — terrain materials + ground-cover density
One focused pass (GROUND lane + coordinator iterations). Delivered per-tile grass culling, far-band
thinning, and tile LOD, taking the carpet from 31.8M to 11.80M primitives at band1_open — inside the §6
proxy budget (7511 draws / 11.80M prims; hall_approach 3975 draws). WORLD's judge round 3 called the
resulting day ground close-ups "the strongest frames to date." No dedicated VP2 judge round beyond that;
folded into the WORLD rounds. **Final state: PASS** (budget met, judged qualitatively via WORLD round 3).

### VP3 — vegetation layering + natural clustering
Delivered via the WORLD lane alongside VP1/VP2: ecology gate, under-canopy band, hero trees, water-edge
bands, desaturated leaf retints (the same fix that solved VP1's white-canopy bug). WORLD round 2/3 judge:
groves read as foliage; distant scatter at the overlook stand still reads uniform. **Final state: PASS with
limitations** (distant-scatter uniformity at the overlook stand remains open, not separately re-judged
after round 3).

### VP4 — mid-ground composition + travel corridor
CORRIDOR lane, rounds 1–6 across all 16 stations. Round 1: befores/afters nearly identical, the two
emptiest sightlines (02, 07) got nothing visible. Rounds 2–5 progressively fixed stations 02, 04, 06, 07,
09, 13; round 3 added an RNG-isolation unit test after shared-seed placements silently perturbed unrelated
stations. Round 6 (final, `JUDGE-round6.md`): most stations pass; two items **honestly left open**: station
08's signpost text still not fully legible after two fix attempts, and station 14's ridge-camp is still
not visible from its stand despite re-siting. Station 09's water complaint is structurally unfixable at
that position (river ~800m further down the route). **Final state: PASS with limitations** (stations 08,
14 open; see §6).

### VP5 — village + tournament + camps
Owned by the PLACES lane (village/tournament in rounds 1–2; camps in round 8). Round 2 (`JUDGE-round2.md`):
Bar B **yes** for village and stronghold courtyard, Bar A blocked at the time by the (since-fixed)
pale-canopy bug. Village reads as a cozy inhabited settlement day and night; tournament/trail-camp read
well. Camps (round 8, `JUDGE-round8.md`, R8.6): deliberately minimal dressing added (4 objects total across
3 camps) to give each a "reason it exists" without overfilling past the owner's stated ceiling; the report
flags this as a judgement call the external judge may want to revisit. **Final state: PASS for
village/tournament; camps PASS with limitations** (minimal dressing, judge may want more).

### VP6 — Burrow Warrens
PLACES lane, rounds 3–8. Round 3: exterior/interior tone fixes ("a value silently cancelled downstream" —
darken 0.24 vs 0.56, tint_variation partly eaten by a later lerp). Rounds 4–7: exterior stayed "recoloured,
not reshaped" (a boulder-dome pile) through several attempts; round 5 finally reshaped it (spoil mounds,
soil apron, half-buried boulders, one rock family). Round 8 (`JUDGE-round8.md`, R8.3): root-caused and fixed
a pale-boulder/pale-panel defect that had been "fixed" twice before and kept recurring from the same code
path (`_wear_as_wall_stone()`, now deleted). Interior/den explicitly preserved unchanged per a standing
owner verdict ("GOOD, must stay unchanged"). **Final state: PASS with limitations** (round 9 was dispatched
for further exterior work but not yet delivered — see §6).

### VP7 — Team Tether Relay
PLACES lane, rounds 3, 7, 8. Round 3 added gate/barrier/banner/grunts at the approach. Round 7 gave the
walls an albedo (they had none) and added a `06-relay-road` stand after CORRIDOR found the compound
rendering as untextured white walls from the road. Round 8 (R8.2) root-caused the ground pad reading
near-white: the pad material was correct but a separate dead-ground tint skin was painted over it at 0.72
alpha — fixed (0.40 alpha, darker tint), proven by sample: pad `[195.6,191.4,163.6] → [98.1,89.8,69.1]`.
Deck, gantry, console and cable-socket materials unified onto the same weathered-stone shader in the same
round. **Final state: PASS** (ground pad and colonnade proven under budget; apparatus visible from the
standing stand, though the road stand's framing keeps most pylons out of frame by construction — flagged,
not fixed).

### VP8 — Meadows Hall
PLACES lane, rounds 3, 4, 7, 8. Round 3 fixed the exterior-brighter-than-interior weathering bug (darken
0.24 → 0.56). Round 4 found the storm-wall backdrop was a `rift_collapse` StormWall, not boiler smoke, and
softened its top. Round 7 lifted the storm slabs above the Hall's skyline (≈30% → ≈3% of sky at every
stand) and grew the Hall's massing 30% with capped distance-darkening. Round 8 (R8.3): material read
improved to ≤100m (39.8% of pixels changed, moss/ivy/lit slits/banners now visible at 2x zoom); sentry
identification still **not proven** (a 1.5x sentry-scale fix was applied but flagged by the lane itself as
a design concern, not a legibility fix — see §6); courtyard night median **failed** (1.49 vs a target of 8).
**Final state: PASS for exterior/approach with limitations; courtyard night and sentries OPEN** (see §6).

### VP9 — world life + population + ambient density
LIFE lane, rounds 1–7 (final). Round 5 was the course correction that defines the whole pass: the capture
tool stopped staging creatures for screenshots and instead positions the eye and reports the game's own
real population, per the brief's "visible population must equal the real gameplay population" rule. Round 7
(final, `JUDGE-round7.md`): open-meadow trailpup pack **PASS, decisively**; pairing composition and village
occupation hold; relay-camp day is the best frame; night stands unchanged since round 6 (creature meshes
render unlit beside lit humans — recorded as a known limitation, not fixed). Villager walkers were scoped
(60–100 lines estimated) but never implemented. **Final state: PASS for day population; night population and
walkers OPEN** (see §6).

---

## 6. Known limitations (explicit)

- **Night creature meshes render unlit beside lit humans.** LIFE's own night stands are unchanged since
  round 6; creature bodies do not pick up the same emission boost NPCs get at night. — `LIFE/REPORT.md`
  ("Final state" / per-stand table), `LIFE/JUDGE-round7.md`.
- **Villager walkers were scoped, never implemented.** No movement method exists on `npc_body.gd`
  (a `StaticBody3D` placed once); estimated 60–100 new lines across two scripts plus JSON, contingent on an
  unresolved question of whether the dialogue system exposes "a conversation is active" for the walker to
  pause on. — `LIFE/REPORT.md` ("Villager-walk-loop — scope estimate").
- **Terrain3D streams around the player, not the camera.** Any capture stand (or future gameplay feature)
  with an elevated/distant camera and no `actor` placing the player at that camera renders unloaded terrain
  — this produced the VP1 "red wash" defect (root-caused WORLD round 5e) and is also named in WORLD's
  program-wide notes as affecting roughly 30 capture tools that still drop the player 500m below the stand
  by default. — `WORLD/REPORT.md` (round 5e "SOLVED" + "Program-wide" section).
- **Character/creature model fidelity is explicitly out of scope for this program.** No new meshes were
  generated (`CLAUDE.md` hard rule); blocky low-poly silhouettes and flat toon shading versus the Palworld
  reference bar are named directly by LIFE's own round-6 judge. — `LIFE/JUDGE-round6.md`, `LIFE/REPORT.md`.
- **No on-device FPS floor has been measured.** All perf numbers in §4 are structural counters
  (draw calls/primitives/objects) from software GL in this container; the §6 sustained-FPS (45) and 1% low
  (30) floors are PROVISIONAL placeholders pending an owner measurement on the actual ROG Ally via
  `tools/vp_capture_windows.ps1`. — `docs/VISUAL_PARITY_PROGRESS.md` §6.
- **CORRIDOR station 08's signpost text is still not fully legible** after two attempted fixes (double-
  sided text, sign separation); root cause not conclusively identified within the lane's budget. —
  `CORRIDOR/REPORT.md` ("Honestly still open", item 1).
- **CORRIDOR station 14's ridge camp is still not visible** from its capture stand despite a re-sited look
  target; the aim direction demonstrably changed but whatever it now frames does not read as "ridge camp."
  — `CORRIDOR/REPORT.md` ("Honestly still open", item 2).
- **CORRIDOR station 09's water complaint is structurally unfixable at that station's position** — the
  river is roughly 800m further down the route than the stand can see — and was not attempted. —
  `CORRIDOR/REPORT.md` ("Honestly still open", item 3).
- **Two more trailhead-signpost siting collisions exist elsewhere** (Pond Circuit/River Gorge Spoke;
  Quarry Haul Road/Mountain Trail Spoke), found by the same audit that fixed station 08's pair; neither is
  in view at any VP4 station and neither was touched. — `CORRIDOR/REPORT.md` ("Honestly still open", item 4).
- **Warrens exterior work continues past round 8.** Round 8 fixed a recurring pale-boulder/pale-panel
  defect (the same code path had been "fixed" twice before and kept regressing); a round 9 with further
  exterior items was dispatched at 14:40 UTC but had not delivered frames as of the evidence in this
  handoff. — `docs/VISUAL_PARITY_PROGRESS.md` (check-in #21–22); `PLACES/JUDGE-round8.md`.
- **Hall courtyard night median luminance FAILED its target** (1.49 measured vs a target of ≥8; more than
  half the frame is still essentially black despite bright brazier pools lifting the mean to 9.47). A prior
  round's claim that mean luminance had improved was corrected in round 8 as "measuring the wrong thing." —
  `PLACES/REPORT.md` (R8.4).
- **No Hall/Relay sentry is reliably identifiable at its capture stand.** The applied fix scales sentry
  bodies 1.5x, but the lane's own report states this is **not verified** (no figure identifiable in a 2x
  crop) and flags the approach itself as a design concern — a 2.7m-tall guard changes the game, not just the
  frame; the honest options (closer stand, lit sentry post, or accepting sentries don't read at ~44m) were
  left as an open decision rather than shipped silently. — `PLACES/REPORT.md` (R8.5).
- **Hall mass at 200–400m still reads soft/does not fully separate from the ground/storm backdrop**, even
  though the storm-band extent itself was fixed (≈30% → ≈3% of sky). — `PLACES/REPORT.md` (round 7/8
  sections); `PLACES/JUDGE-round7.md`.
- **VP9's pairing frame has an unresolved ~1.3–1.5x trainer/starter scale gap.** Composition (side by side,
  both fully in frame) is solved; the apparent-size mismatch is a species-data/contract-tolerance question,
  not a camera one, and was out of the lane's remaining budget. — `LIFE/REPORT.md` ("Known limitations,
  stated plainly").
- **Mill-pond's second wildlife species (mosshell, order 1071) is unresolved.** It was removed by a CI fix
  after it broke a protected spawn pocket and never replaced; the shipped round5/6 frames for that stand
  predate the removal and are not reproducible from current data. — `LIFE/REPORT.md`.
- **No combat or building/home frame was captured or judged after the VP1–VP3 checkpoint** (06:14 UTC,
  `VP1-3-candidate/`). LIFE's own report names "the total absence of any action/combat framing" directly as
  a limitation. — `LIFE/REPORT.md` ("Known limitations, stated plainly").
- **band1_open draw calls are 2% over the provisional VP2 proxy budget** on the merged tree (7659 vs the
  VP2 candidate's 7511; primitives still pass with 2% headroom). A targeted draw-call pass is identified but
  not yet measured or landed. — `ralph/reports/visual-parity/VP10-perf/perf_merged_1d1a2f74.txt`;
  `docs/VISUAL_PARITY_PROGRESS.md` (14:56 UTC check-in).
- **VP10 (performance retention) and VP11 (this handoff) are not finished.** VP10's draw-call pass at
  band1_open is in progress; a final recapture across every location in §2 with everything landed has not
  been run. — this document's STATUS line; `docs/VISUAL_PARITY_PROGRESS.md` pass table.
- **§6's acceptance numbers (minimum sustained FPS 45, minimum 1% low 30) are PROVISIONAL placeholders**,
  not owner-confirmed values — see the on-device FPS floor limitation above. —
  `docs/VISUAL_PARITY_PROGRESS.md` §6.

---

## 7. Final progress file

`docs/VISUAL_PARITY_PROGRESS.md` is the single resume checkpoint for this program. Its pass-status table,
per-pass commit/pushed SHAs, judge-history section, and "Regressions / unresolved problems" section are
authoritative — this handoff summarizes and cross-references it but does not supersede it. Where this
document and the progress file diverge on a specific number or verdict, the progress file wins.

---

## 8. How to reproduce the evidence

**Capture (evidence frames, 1920x1080):**
```
RES=1920x1080 tools/vp_capture.sh <evidence_dir>
```

**Performance (structural counters, 1280x720, under xvfb, Compatibility renderer):**
```
tools/perf_render_stats.gd --views=band1_open,hall_approach,village_high --settle=120 --resettle=60 --sample=20
```

**Blind-judge protocol:** `.claude/skills/visual-judge/SKILL.md`. The judge is given only the frame contact
sheet, `docs/reference/` (the key art and Palworld comparison boards), and `site/img/page-board.jpg` — never
told what changed, what verdict is desired, or what a previous judge round said, per
`docs/VISUAL_PARITY_STAGED_GOAL_PROMPT_V2.md` §10.
