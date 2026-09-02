# Meadows Visual Parity — Handoff (candidate for external visual judgement)

**STATUS: CANDIDATE READY FOR EXTERNAL VISUAL JUDGEMENT** (VP0–VP11 complete; final recapture + code-blind judge in `ralph/reports/visual-parity/VP11-final/`)

This document packages the Meadows Visual Parity program (`docs/VISUAL_PARITY_STAGED_GOAL_PROMPT_V2.md`)
for external visual review. It is generated from `docs/VISUAL_PARITY_PROGRESS.md` (the authoritative
checkpoint) and the evidence under `ralph/reports/visual-parity/`. All eleven passes are closed; the final
code-blind verdict is 6.5/10 (Bar A yes, Bar B partial) — see §5 VP11 and, for what remains short of the vision,
`docs/VISUAL_NEXT_AGENT_HANDOFF.md`.

---

## 1. Branch info

| item | value |
|---|---|
| program branch (this session's harness-pinned branch; the owner prompt named `codex/meadows-visual-parity`, but the harness pins the branch below, so this branch *is* the visual-parity branch — see `docs/VISUAL_PARITY_PROGRESS.md` "Branch and SHAs") | `claude/coordination-subagents-3fhz1x` |
| starting `main` SHA | `252ccc81` (2026-09-01, `origin/main` at program start) |
| ship-to-main merge | `b03cdb94` — PR #20, merged 2026-09-02 14:56 UTC (CI run 33642046946 on `1d1a2f74`, green after a 25-minute run). Carries VP1–VP9 as merged at that point (WORLD r1–r6, GROUND/VILLAGE, CORRIDOR r1–r6, PLACES r1–r8, LIFE r1–r7). |
| latest pushed SHA (this session, `git rev-parse --short HEAD`) | see PR #21's merge commit on `main`; code content is identical from `0a04ce69` (main merged in) onward — every later commit is docs/evidence only |

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
| VP10 perf retention numbers | `f0740c96` | perf retention numbers on the merged tree (band1_open 7659 draws / 11.76M prims, hall_approach 3844, village_high 3165) |
| Lane close-out (WORLD r7–r9, CORRIDOR r7–r9, PLACES r9–r12, sentries, Warrens cladding, Hall stone) | `b805d9d6` … `6c7f8d1e` | merged lane branches + Fable decision/restart agents' fixes |
| VP10 visibility ranges ON (kept) | `222ea390` | `structure_visibility_ranges: true` — band1_open 6847 draws |
| main merged into the program branch | `0a04ce69` | 16 main-side commits (sleep/traversal/train-clarity harness fixes), no conflicts |
| VP11 final recapture + judge + handoffs | `4011160b` … (PR #21 head) | `VP11-final/`, `JUDGE-final.md`, handoff STATUS flip, next-agent handoff |

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

All AFTER frames are the **VP11 final recapture** (`ralph/reports/visual-parity/VP11-final/`, 1920x1080, program
head with `structure_visibility_ranges` ON and the grass carpet ON), taken in one run on 2026-09-02 19:03–21:00 UTC
so every location is shown at the same shipped state. BEFORE frames are the earliest capture of the same stand in
the program (VP0 baseline where it exists; otherwise the first lane capture of that stand). Side-by-side sheet:
`VP11-final/_sheet_before_after.png` (left BEFORE, right AFTER, 34 pairs); the mapping below is generated from the
same script and every path was verified to exist at write time.

| location | BEFORE | AFTER (VP11-final) |
|---|---|---|
| Village day | `VP0-baseline/locations-1080p/01-village-standing-day.png` | `VP11-final/locations/01-village-standing-day.png` |
| Village night | `PLACES/00-before/locations/01-village-standing-night.png` | `VP11-final/locations/01-village-standing-night.png` |
| Village approach | `VP0-baseline/locations-1080p/01-village-approach-day.png` | `VP11-final/locations/01-village-approach-day.png` |
| Grandpa yard | `VP0-baseline/locations-1080p/01-village-grandpa-yard-day.png` | `VP11-final/locations/01-village-grandpa-yard-day.png` |
| Tournament | `VP0-baseline/locations-1080p/01-village-tournament-day.png` | `VP11-final/locations/01-village-tournament-day.png` |
| Mill pond | `VP0-baseline/locations-1080p/02-mill-pond-standing-day.png` | `VP11-final/locations/02-mill-pond-standing-day.png` |
| Mill wheel | `VP0-baseline/locations-1080p/02-mill-pond-wheel-day.png` | `VP11-final/locations/02-mill-pond-wheel-day.png` |
| Spawn outward (wide) | `WORLD/round1/before/01-spawn-outward.png` | `VP11-final/survey/01-spawn-outward.png` |
| Valley floor (wide) | `WORLD/round1/before/02-valley-floor.png` | `VP11-final/survey/02-valley-floor.png` |
| Rise overlook (wide) | `WORLD/round1/before/03-rise-overlook.png` | `VP11-final/survey/03-rise-overlook.png` |
| Three-quarter (wide) | `WORLD/round1/before/04-three-quarter.png` | `VP11-final/survey/04-three-quarter.png` |
| Spawn low sun (wide) | `WORLD/round1/before/05-spawn-low-sun.png` | `VP11-final/survey/05-spawn-low-sun.png` |
| Band1 ground day | `VP1-3-after/ground/ground-01-band1-opening-day.png` | `VP11-final/ground/ground-01-band1-opening-day.png` |
| Band2 stone-root ground | `VP1-3-after/ground/ground-02-band2-stone-root-day.png` | `VP11-final/ground/ground-02-band2-stone-root-day.png` |
| Band4 ironwood ground | `VP1-3-after/ground/ground-04-band4-ironwood-day.png` | `VP11-final/ground/ground-04-band4-ironwood-day.png` |
| River edge | `VP1-3-after/ground/water-02-river-eye.png` | `VP11-final/ground/water-02-river-eye.png` |
| Pond edge | `VP1-3-after/ground/water-01-pond-eye.png` | `VP11-final/ground/water-01-pond-eye.png` |
| Warrens approach | `PLACES/00-before/locations/04-warrens-approach-day.png` | `VP11-final/locations/04-warrens-approach-day.png` |
| Warrens standing | `PLACES/00-before/locations/04-warrens-standing-day.png` | `VP11-final/locations/04-warrens-standing-day.png` |
| Warrens den (interior) | `PLACES/00-before/locations/04-warrens-den-day.png` | `VP11-final/locations/04-warrens-den-day.png` |
| Relay camp | `PLACES/00-before/locations/05-relay-camp-standing-day.png` | `VP11-final/locations/05-relay-camp-standing-day.png` |
| Relay camp night | `PLACES/00-before/locations/05-relay-camp-fire-night.png` | `VP11-final/locations/05-relay-camp-fire-night.png` |
| Relay apparatus | `PLACES/00-before/locations/06-relay-apparatus-day.png` | `VP11-final/locations/06-relay-apparatus-day.png` |
| Relay approach | `PLACES/00-before/locations/06-relay-approach-day.png` | `VP11-final/locations/06-relay-approach-day.png` |
| Ridge camp | `PLACES/00-before/locations/08-ridge-camp-standing-day.png` | `VP11-final/locations/08-ridge-camp-standing-day.png` |
| Ridge camp night | `PLACES/00-before/locations/08-ridge-camp-fire-night.png` | `VP11-final/locations/08-ridge-camp-fire-night.png` |
| Waystop | `PLACES/00-before/locations/09-waystop-standing-day.png` | `VP11-final/locations/09-waystop-standing-day.png` |
| Hall approach (200 m) | `PLACES/00-before/locations/11-castle-landmark-approach-day.png` | `VP11-final/locations/11-castle-landmark-hall-200m-day.png` |
| Hall gate day | `PLACES/00-before/locations/10-stronghold-gate-day.png` | `VP11-final/locations/10-stronghold-gate-day.png` |
| Hall gate night | `PLACES/00-before/locations/10-stronghold-gate-night.png` | `VP11-final/locations/10-stronghold-gate-night.png` |
| Hall courtyard day | `PLACES/00-before/locations/10-stronghold-courtyard-day.png` | `VP11-final/locations/10-stronghold-courtyard-day.png` |
| Hall courtyard night | `PLACES/00-before/locations/10-stronghold-courtyard-night.png` | `VP11-final/locations/10-stronghold-courtyard-night.png` |
| Hall at 100 m | `PLACES/00-before/locations/11-castle-landmark-gate-day.png` | `VP11-final/locations/11-castle-landmark-hall-100m-day.png` |
| Stronghold approach night | `PLACES/00-before/locations/10-stronghold-approach-night.png` | `VP11-final/locations/10-stronghold-approach-night.png` |

Per-round judged pairs (the rounds that moved each location) remain listed in §5 with their judge files.

Stands that could not be matched: combat and building/home have no pre-program baseline (VP0 did not capture
them); their VP11 frames are in `VP11-final/combat/` and `VP11-final/buildings/` and appear in §3.

---

## 3. Hero gallery

Ten slots per the VP11 brief, all from the final recapture (`VP11-final/`) so the hero set is the shipped state.

| slot | frame path(s) |
|---|---|
| 3 strongest wide Meadows views | `VP11-final/survey/03-rise-overlook.png`, `VP11-final/survey/01-spawn-outward.png`, `VP11-final/survey/05-spawn-low-sun.png` |
| Village day | `VP11-final/locations/01-village-standing-day.png` |
| Village night | `VP11-final/locations/01-village-standing-night.png` |
| Creature/world frame | `VP11-final/locations/08-ridge-camp-standing-day.png` (creatures beside the ridge camp) |
| Combat/world frame | `VP11-final/combat/02-arena-opens.png` |
| Building/home frame | `VP11-final/buildings/07-farmhouse-interior.png` |
| Tournament | `VP11-final/locations/01-village-tournament-day.png` |
| Warrens | `VP11-final/locations/04-warrens-approach-day.png` |
| Team Tether Relay | `VP11-final/locations/06-relay-apparatus-day.png` |
| Hall approach | `VP11-final/locations/11-castle-landmark-hall-200m-day.png` (plus `10-stronghold-gate-day.png` for the gate face) |

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

**VP10 draw-call pass at band1_open: DONE — `structure_visibility_ranges` ON (one-shot measurement, KEPT).**
`ralph/reports/visual-parity/VP10-perf/perf_visibility_ranges_on.txt`, same tool / settle 120/60/20 / 1280x720:

| view | draw calls (OFF → ON) | primitives (OFF → ON) | objects (OFF → ON) | budget | verdict |
|---|---|---|---|---|---|
| band1_open | 7659 → **6847** | 11,757,306 → 11,718,510 | 6593 → 5858 | ≤ 7500 draws / ≤ 12.0M prims | **PASS** (8.7% draw headroom, 2.3% prim headroom) |
| hall_approach | 3844 → 3847 | 4,332,388 → 4,325,660 | 4185 → 4188 | ≤ 4000 draws | PASS |
| village_high | 3165 → 2880 | 8,622,824 → 8,532,978 | 3306 → 3021 | — | recorded |

Visual check for the switch: `VP10-perf/survey_vis_on/_sheet_off_vs_on.png` (five survey stands, OFF left / ON
right) — no structure missing or popping at any stand. The final VP11 recapture (§2/§3) was taken with the switch
ON on the same code, so the **ON row above is the shipped number of record**. The recapture chain's own trailing
perf series (`VP11-final/perf_render_stats.txt`) had not finished when the owner called wrap-up; if the file exists
in the repo it was appended by that chain and should match the ON row within sampling noise, otherwise the VP10
measurement stands.

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
5/5 checks passed: Godot 4.7 binary + import, real screenshot on disk, verified as a real rendered frame, test
command runs (`tests/smoke_art.gd`), blind judge invocable from this environment (not deferred). One finding carried
forward: `apply_time("golden")` rendered a flat black frame under this pipeline (VP1-G0). Evidence:
`VP-PRE/JUDGE.md`. **Final state: PASS (capability check, not a visual pass).**

### VP0 — baseline
Rounds run: 1 (baseline judgement only). Judge file: `VP0-baseline/JUDGE-village-pond.md`. Judged on village + mill
pond (carpet ON, `main@252ccc81`). Bar A (keyart world) **no**, Bar B (Palworld kind of game) **no**. Main failures:
sky tan/brown smeared clouds in 7/9 frames ("reads as a broken shader"); no creature anywhere in the set; lighting
disagrees with itself (clear sky, no ground shadows, hard sun disc, no distance haze); single tree silhouette
repeated everywhere, static NPCs, no mill wheel, no tournament dressing. Response: sky/lighting routed to VP1,
creatures to VP0 combat captures + VP9, tree variety to VP3, paddocks/tournament/mill dressing to VP5, NPC life to
VP9. **Final state: PASS (baseline established), problems routed forward.**

### VP1 — sky, sun, global lighting, atmosphere
Rounds run: 1–9 (round 9 a one-shot dawn-far-plain attempt that failed and was reverted; WORLD then closed and
archived). Judge files: `WORLD/JUDGE-round1.md`…`round4.md`, `round6.md`–`round8.md` (round 5's fix is judged inside
round 6; round 9 had no separate judge — the one-shot failed its own proof). Main failures: a solid red/maroon wash
at every elevated/night stand across thirteen falsified hypotheses; an oversized blown-out sun/moon halo (~27.4°);
dawn/golden desaturated to dust-brown instead of pink-gold; a hard black seam at the night horizon; night far ground
read bluer but brighter, not darker, than near ground. Response: round 5e root-caused the wash — stands with no
`actor` key dropped the player 500 m below the world and Terrain3D streams mesh around the player, not the camera
(capture-tool bug, flagged as a latent risk for any future distant-camera gameplay feature); round 6 confirmed every
washed stand clean; rounds 7–8 gave the sun a true angular radius (halo ~27.4°→~2.0°) and lifted dawn sky saturation
0.09→0.29; round 9's attempt to decouple the dawn far-plain fade from `fog_colour` failed its own proof (saturation
collapsed 0.363→0.136) and was reverted, recording a mechanism-locked ceiling instead of shipping it. **Final state:
PASS with limitations** (dawn far-plain CEILING recorded; night far ground bluer/brighter, not chased further — §6).

### VP2 — terrain materials + ground-cover density
Rounds run: one focused pass plus coordinator iterations (iteration 0, B, C, C+`scatter_lod_ranges=false` as the
committed cost candidate); no dedicated VP2 judge round — folded into WORLD's own rounds. Judge file:
`WORLD/JUDGE-round3.md` (day ground close-ups called "the strongest frames to date"). Main failure: the grass carpet
at 31.8M primitives in the owner's laggy build (the ~10 FPS Ally report). Response: per-tile distance culling
(`cull_tile_m`), far-band thinning and tile LOD in `grass_field.gd`, landing at 7511 draws / 11.80M primitives at
`band1_open` and 3975 draws at `hall_approach` — inside the §6 proxy budget. **Final state: PASS** (budget met,
judged qualitatively via WORLD round 3).

### VP3 — vegetation layering + natural clustering
Delivered via the WORLD lane alongside VP1/VP2: ecology gate, under-canopy band, hero trees, water-edge bands,
desaturated leaf retints (the same fix that solved VP1's white-canopy bug). Judge files: `WORLD/JUDGE-round2.md`,
`WORLD/JUDGE-round3.md`. Main failures: groves read as foliage but distant scatter at the overlook stand still reads
uniform — a density gradient problem, not a lighting one. Response: no further dedicated round; the item stayed open
through to WORLD's closing summary rather than being chased separately. **Final state: PASS with limitations**
(distant-scatter uniformity at the overlook stand remains open — see §6).

### VP4 — mid-ground composition + travel corridor
Rounds run: 1–9 (final). Judge files: `CORRIDOR/JUDGE-round1.md`…`round3.md`, `round5.md`…`round9.md`; Fable
decision: `CORRIDOR/DECISION-station14.md`. Main failures: round 1 near-identical before/after at stations 02/07; by
round 7–8 three items stayed stuck — station 07's foreground was a no-op re-render, 13's right ~26–35% stayed empty
sky/grass, and 14 showed no camp at all (round 7 FAIL) even after a re-site and props move (round 8 PARTIAL — small,
under-anchored). Response: round 8 gave 07 a real close foreground clump (PASS, "the shot that most now resembles
the Palworld framing"); a Fable agent (`DECISION-station14.md`) found 14's camp was in frame the whole time, at 18
px, masked by the "Watchtower Spur" signpost and the player's own head — fixed by re-siting to the clearing's
trail-side edge and hardening `_surface()` against the terrain bake; round 9 judged 14 **PASS**. Station 13 got a
denser mid-right cluster each round but round 9 measured the true rightmost 10% as still 100% empty — **FAIL,
unchanged**, declared a ceiling. Station 09's water was never attempted (river ~800 m down the route); 08's signpost
text stayed short of legibility, root-caused to ordinary distance/resolution softness. **Final state: PASS with
limitations** (stations 08, 09, 13 open — §6).

### VP5 — village + tournament + camps
Owned by the PLACES lane. Rounds run: 1–2 (village/tournament), 8–9 (camps; unchanged since round 8). Judge files:
`PLACES/JUDGE-round2.md`, `PLACES/JUDGE-round8.md`, `PLACES/JUDGE-round9.md`. Round 2: Bar B **yes** for village and
stronghold courtyard; village reads as a cozy inhabited settlement day and night. Round 8 main failure: all three
camps amounted to "one thin campfire flame, one or two generic crates/barrels, and 1–2 NPCs standing in a large
empty patch" with no seating and no clustering around the fire; ranked weakest-to-strongest relay < ridge < waystop.
Response: round 8 (R8.6) dressed relay camp +5 props (larger fire ring, a third touching log, kettle), ridge +1,
waystop +1 — deliberately minimal, flagged by the lane itself as a judgement call the external judge may want to
revisit. Round 9 confirmed all three camps pixel-identical to round 8 (untouched) and re-ranked them relay (weakest
— props scattered, fire half-hidden) < waystop (middle) < ridge (best — real fire pit, bench, seated NPC). **Final
state: PASS for village/tournament; camps PASS with limitations** (relay camp weakest, minimal dressing — see §6).

### VP6 — Burrow Warrens
PLACES lane, rounds 3–11. Judge files: `PLACES/JUDGE-round8.md`, `PLACES/JUDGE-round9.md`,
`PLACES/JUDGE-round11-warrens.md`; Fable decision: `PLACES/DECISION-warrens-restart.md`. Main failures: rounds 3–8
left the exterior "recoloured, not reshaped" (a boulder-dome pile), and rounds 8–9 named a pale, flat, un-textured
slab above the mouth and a flat grey approach wall — both pixel-identical across two rounds, never actually
rendered. Response: a clean-restart Fable ray-cast agent traced the standing camera's own screen point through the
world and found the slab was the outer face of the mouth chamber's front wall, set via `material_override` (silently
overriding the surface material the lane had been re-skinning); fixed with a 0.4 m earth-skin cladding on exterior
wall faces (`site.exterior_cladding_m`), interior untouched. Round 11 judge: slab median 102/44 → 2.8/2.5 (61% px
changed) — **standing PARTIAL** (slab gone, flanks now an unlit black void), **approach PARTIAL** (wide flat wall
gone; a smaller lintel remains close-up), **den PASS**. FAIL → PARTIAL, "**ONE MORE KNOB**" queued
(`exterior_cladding_colour` ~#4a3a2a for grain in shadow). **Final state: PASS with limitations** (flanks pending
the queued colour knob, not delivered inside this handoff's evidence window — see §6).

### VP7 — Team Tether Relay
PLACES lane, rounds 3, 7, 8. Round 3 added gate/barrier/banner/grunts at the approach. Round 7 gave the walls an
albedo (they had none) and added a `06-relay-road` stand after CORRIDOR found the compound rendering as untextured
white walls from the road. Round 8 (R8.2) root-caused the ground pad reading near-white: the pad material was
correct but a separate dead-ground tint skin was painted over it at 0.72 alpha — fixed (0.40 alpha, darker tint),
proven by sample: pad `[195.6,191.4,163.6] → [98.1,89.8,69.1]`. Deck, gantry, console and cable-socket materials
unified onto the same weathered-stone shader in the same round. **Final state: PASS** (ground pad and colonnade
proven under budget; apparatus visible from the standing stand, though the road stand's framing keeps most pylons
out of frame by construction — flagged, not fixed).

### VP8 — Meadows Hall
PLACES lane, rounds 3, 4, 7–11, plus a two-stage sentry fix outside the numbered rounds. Judge:
`PLACES/JUDGE-round8.md`–`round10.md`, `round11-sentries.md`; decisions: `DECISION-hall-sentries.md`,
`DECISION-sentries-restart.md`, `DECISION-sentries-night.md`. Main failures: through round 9 the Hall read as a flat
black cutout at every distance including point-blank (albedo 0.011, below coal); sentries were absent from every
gate-face frame; courtyard night's floor crushed near-black. Response: `Color.darkened` was found multiplying in
sRGB (0.48 ⇒ ×0.24 linear) over an already-dark texture — fixed with `darken: 0.0` + lighter tints; round 10: **Hall
stone PASS by day** (tint 66→139.7/255, score 3.5→6/10), night stone PARTIAL. Sentries, declared "at ceiling" in
round 10, went to a clean-restart agent whose probe found the grunts on-screen every round all along, half-buried in
the jamb, not a rendering ceiling; re-siting 0.5 m inboard gave **gate-face-day PASS** with **gate-face-night
PARTIAL** (~5x darker than the doorway); a one-shot omni light then gave west luma 5.1→29.17, east 6.4→30.55 (≥25
target). A jamb-face OmniLight failed its own proof and was reverted, recorded as a ceiling. **Final state: PASS
with limitations** (day stone PASS; night stone at the inner jambs a declared CEILING; sentries PASS day and night —
"at ceiling" was a placement bug; courtyard night accepted on visual read though its 3 m-disc metric fails — §6).

### VP9 — world life + population + ambient density
LIFE lane, rounds 1–7 (final). Judge file: `LIFE/JUDGE-round7.md`. Main failures carried into round 7: the open
meadow's creature cluster was camouflaged (pale-on-pale), relay-camp and village-edge night stands showed only an
unidentifiable pale smudge beside the lit human figures, and the pairing frame's composition was solved but scale
between trainer and starter was unresolved. Round 7 (final): open-meadow trailpup pack **PASS, decisively** — 3–4
grey wolf-type bodies countable without zoom on the right side (the left side's pale blobs are an unresolved
residual of the same camouflage problem); relay-camp-day now shows 3 countable wolves and is the round's best frame;
pairing and village-life hold **PASS, unchanged**; both night stands (relay-camp-night, village-edge-night) are
**FAIL, visually unchanged from round 6** — night lighting reaches the human figures via rim/fire light but never
reaches the creature meshes standing next to them. Villager walkers were scoped (60–100 lines estimated) but never
implemented. **Final state: PASS with limitations** (night creature visibility unresolved; walkers scoped, not
implemented — see §6).

### VP10 — performance retention
Not a visually-judged pass — a measurement pass on the merged tree via `tools/perf_render_stats.gd`. Evidence:
`VP10-perf/perf_merged_1d1a2f74.txt` (baseline, switch OFF), `VP10-perf/perf_visibility_ranges_on.txt` (switch ON),
`VP10-perf/survey_vis_on/` + `_sheet_off_vs_on.png` (five survey stands OFF vs ON), `VP10-perf/DECISION-visibility-ranges.md`.
First finding: `band1_open` draw calls sat 2.1% over the provisional VP2 proxy (7659 vs 7500) on the merged tree,
while primitives (11.76M ≤ 12.0M) and `hall_approach` (3844 ≤ 4000) both passed. A per-group draw-call breakdown
disproved the leading candidate by measurement (the grass carpet costs 133 draws, not thousands — a MultiMesh is one
draw per surface, not per instance). A `structure_visibility_range` mechanism (per-group visibility ranges on
authored structures/props, `data/config/performance.json` `structure_visibility_range`) was built, merged default-OFF,
then given its one measurement under the owner's one-shot rule: ON brings `band1_open` to **6847 draws / 11.72M
prims**, `hall_approach` 3847, `village_high` 2880, with the five survey stands pixel-compared OFF vs ON — no
structure missing or popping at any stand (the 15–29% pixel diffs are grass/cloud motion). Unit guards
`test_scatter_perf_budget` + `test_grass_field` 21/0. **Final state: PASS on the proxy budget** — switch KEPT ON
(commit `222ea390`); on-device FPS remains the owner-side measurement (§4).

### VP11 — handoff: final recapture + code-blind final judge
Evidence: `VP11-final/` (one unedited run, 1920x1080, program head, visibility ranges ON, carpet ON) and
`VP11-final/JUDGE-final.md` (Sonnet, code-blind: frames + `docs/reference/` + `site/img/page-board.jpg` + the
visual-judge skill only; combat/buildings folders were not yet rendered when it ran and were skipped).

Verdict verbatim: **overall parity 6.5/10**; **Bar A (belongs to the key-art world): Yes**, with the caveat that the
flat cel-shaded rendering is a stylisation, not a miss; **Bar B (same kind of game as the Palworld boards):
Partially, leaning no** — structure matches (open terrain, distant landmark, camps, creature-at-scale), the
anime-cel outline on trainer/NPC/creature and the simpler tree shape language sit a visible step below the material
and density bar. Per-area scores: sky/light 7, ground/vegetation 6, corridor 6, village+tournament 7, camps 5,
Warrens 6, Relay 8, Hall 9, creatures/life 5, night 6.

Strongest five: `10-stronghold-gate-day`, `09-waystop-standing-day`, `06-relay-apparatus-day`,
`08-ridge-camp-standing-day` (four creature sizes legible at once), `11-castle-landmark-hall-400m-day` (landmark
reads through haze). Weakest five, all named as capture-rig framing rather than assets: `05-relay-camp-fire-day/-night`,
`07-mill-crossing-yard-day`, plus `02-mill-pond-wheel-day` and `05-relay-camp-standing-night`. Coordinator's
check on the last two (`VP11-final/locations/`): the mill-wheel frame is a clean building shot with sky, and the
relay standing-night frame is dark but carries the fire, bench and trainer — those two are judge misreads, recorded
as such; the other three are the stand-siting limitations in §6. The judge's "fixable by scene" list — tournament
banners' flat placeholder look (the relay pennant proves the kit has a real cloth flag), weather variants reading
identical to clear, night fill in unlit camps, band-to-band sameness — and its "needs new art" list — tree canopy
shape language, the cel-outline material split between creature/trainer/terrain, creature variety in the sampled
frames — are carried into `docs/VISUAL_NEXT_AGENT_HANDOFF.md` as the next round's direction.

**Final state: CANDIDATE READY FOR EXTERNAL VISUAL JUDGEMENT** — the label the program prompt defines; it means
the evidence package is complete and honest, not that the vision is reached (6.5/10 against an ~8/10 target).

---

## 6. Known limitations (explicit)

**WORLD**

- **Terrain3D streams around the player, not the camera, and roughly 30 capture tools still drop the
  player 500 m below the stand by default.** This produced the VP1 red-wash defect (root-caused WORLD
  round 5e) and remains program-wide scope, only recorded, not repaired: `tools/capture_water.gd` parks
  ~7071 m away horizontally, ~21 tools still do the 500 m drop, ~8 more use the 5000-offset shape. Any
  future distant-camera feature — cutscene, photo mode, spectator or map view — must move the streaming
  anchor with the camera. — `WORLD/REPORT.md` ("closing summary", known limitations item 1).
- **Night far ground is bluer and brighter than the reference**, not the intended bluer-and-darker read;
  the seam is closed and the cliff is gone, but this was not chased further. — `WORLD/REPORT.md` (item 2);
  `WORLD/JUDGE-round7.md`.
- **Dawn's far plain is a mechanism-locked ceiling, not an open bug.** `sky.horizon_colour` must stay
  byte-identical to `environment.fog_colour` under `fog_sky_affect 0` (the seam invariant rounds 3 and 7
  stabilised); desaturating the far-ground fade desaturates the sky in lockstep — sky saturation collapsed
  0.363 → 0.136 against a 0.25 floor even with compensation attempted. Reaching the reference dawn
  relationship needs a mechanism change (a ground-fade colour decoupled from `fog_colour`, or
  `fog_sky_affect > 0`), explicitly not attempted inside a time box. — `WORLD/REPORT.md` (item 3);
  `docs/VISUAL_PARITY_PROGRESS.md` (18:25 UTC check-in).
- **VP10's draw-call cost is now inside the proxy, but 45% of draws remain unattributed.** `band1_open`
  went 7659 → 6847 draws (≤ 7500) by switching `structure_visibility_ranges` ON (one-shot measurement, kept);
  the grass carpet was disproved as the cause by measurement (133 draws — a MultiMesh is one draw per
  surface, not per instance). The per-group breakdown is still a surface-count upper bound, not
  frustum-aware, so vegetation's true share is unknown. — `VP10-perf/perf_visibility_ranges_on.txt`;
  `VP10-perf/DECISION-visibility-ranges.md`; `WORLD/REPORT.md` (item 4).

**CORRIDOR**

- **Station 13's rightmost ~10% of frame is still 100% empty sky/grass** after three rounds of right-side
  fill (round 6's copse, round 8's closer anchor, round 9's edge-sited anchor) — each round narrowed the
  gap without closing it; declared a ceiling rather than pursued a fourth time. —
  `CORRIDOR/REPORT.md` ("closing summary"); `CORRIDOR/JUDGE-round9.md`.
- **Station 08's signpost text is not fully crisp at native resolution from ~2.5 m.** Root-caused to
  ordinary distance/resolution softness on a small `Label3D` board, not a size-parameter bug and not a
  baked-texture limitation — this lane's tools have no further lever to address it. —
  `CORRIDOR/REPORT.md` ("closing summary").
- **Station 09's water is structurally unreachable from that station's position** without duplicating
  station 12's own river-lock framing — the river's course runs ~800 m away; never attempted. —
  `CORRIDOR/REPORT.md` ("closing summary"); `CORRIDOR/JUDGE-round9.md`.

**PLACES**

- **Night stone at the Hall's inner jamb faces (gate-face-night) is a declared visual ceiling.** A
  per-sconce OmniLight was tried once and failed its own proof (crop medians 0.30/0.00 vs a ≥28 target)
  while the outer curtain already met its target — reaching the jamb faces would need a light inside the
  gate mouth itself; reverted, not shipped. — `docs/VISUAL_PARITY_PROGRESS.md` (17:25 UTC check-in,
  "Check-in #27"); `PLACES/REPORT.md` ("PLACES closing summary", known limitations item 5).
- **Warrens flank brightness is a lighting ceiling.** Round 11's clean-restart fix removed the pale slab
  (median 102/44 → 2.8/2.5) and the flat approach wall; round 12 shipped the agreed `exterior_cladding_colour`
  (#4a3a2a, `data/config/burrow_warrens.json`) on the earth-skin cladding, which gives the mouth flanks a
  material read but not brightness — the flanks sit in the mound's own shadow at the approach stand, so
  they still read dark. Accepted at round 12 as a lighting ceiling rather than pursued again. —
  `PLACES/JUDGE-round11-warrens.md`; `PLACES/DECISION-warrens-restart.md`; `PLACES/round12-warrens/`.
- **Courtyard night is accepted on the code-blind judge's visual read** ("lit pool around the trainer,
  trainer reads, rest acceptably dark") **while its own 3 m-disc median metric still fails** (5.82 vs a
  target of ≥ 20) — recorded as a known limitation of the metric, not of the frame. —
  `docs/VISUAL_PARITY_PROGRESS.md` (16:54 UTC check-in, "Check-in #26"); `PLACES/REPORT.md`.
- **Sentries night is now proven, not a ceiling — any older "sentries at ceiling" wording is superseded.**
  The r9/r10 "ceiling" reading was a placement error (centreline half-buried in the jamb stone), root-caused
  and fixed by a clean-restart agent; a further one-shot chest-height per-sentry light then proved night
  legibility (west luma 5.1 → 29.17, east 6.4 → 30.55, both ≥ 25). —
  `PLACES/DECISION-sentries-restart.md`; `PLACES/DECISION-sentries-night.md`;
  `docs/VISUAL_PARITY_PROGRESS.md` (18:35 UTC check-in, "Sentries CLOSED").

**LIFE**

- **Night creature meshes render unlit beside lit humans.** Both night stands meant to carry life
  (village-edge-night, relay-camp-night) are visually unchanged since round 6 — human figures stay legible
  via rim/fire light, but the same light never reaches the creature meshes standing next to them. —
  `LIFE/JUDGE-round7.md`; `LIFE/REPORT.md` ("Final state" / per-stand table).
- **Villager walkers were scoped, never implemented.** No movement method exists on `npc_body.gd` (a
  `StaticBody3D` placed once); estimated 60–100 new lines across two scripts plus JSON, contingent on an
  unresolved question of whether the dialogue system exposes "a conversation is active" for the walker to
  pause on. — `LIFE/REPORT.md` ("Villager-walk-loop — scope estimate").

**Program-wide**

- **Three capture stands in the final recapture are mis-framed by the harness, not by the world.**
  `05-relay-camp` **fire** (detail stand): the eye now sits inside a scatter tree's canopy (day frame is
  leaves, night frame near-black) although PLACES round 10 was clear from the same numbers — the bake was
  regenerated after the CORRIDOR round 9 vegetation merge and the nearby placements moved. The camp itself
  is proven at the **standing** stand (`VP11-final/locations/05-relay-camp-standing-day.png`). `03-quarry`
  **approach** renders inside foliage and `07-mill-crossing` **yard** frames the player's boots; both stands
  came in from `main` after the program's judged set was fixed and were never part of a judged round. All
  three are stand-siting work in `tools/_capture_locations.gd`, not visual defects, and are left as-is so the
  final evidence stays one unedited run. — `VP11-final/locations/`; `tools/_probe_relay_fire_trees.gd`.
- **`tools/survey_combat.gd` exits 1 on its action-timing guards under software GL** (charged attack never reaches
  `charged_cost` / no hit inside 240 frames; the throw aim does not open) while still writing the six combat frames
  (`VP11-final/combat/01..06`). The frames show approach, arena open, closing-in, wind-up and the quick attack; no
  charged-hit or throw frame exists in any run of this program. A real-time capture on the Ally would not hit these
  guards. — `VP11-final/capture.log`.
- **`tools/_capture_ground_and_sky.gd` reports `GrassField … holds no instances` for every frame and exits 1**
  while still writing all 30 frames with the carpet visibly present. Identical in the VP1–VP3 checkpoint
  capture, so it is a stale guard (the camera-relative carpet is checked before it repopulates for the
  teleported eye), not a missing carpet. Treat the frames, not the exit code, as the evidence.
  — `VP11-final/capture.log`; `VP1-3-after/capture.log`.
- **No on-device FPS floor has been measured.** All perf numbers in §4 are structural counters (draw
  calls/primitives/objects) from software GL in this container; the §6 sustained-FPS (45) and 1% low (30)
  floors are PROVISIONAL placeholders pending an owner measurement on the actual ROG Ally via
  `tools/vp_capture_windows.ps1`. — `docs/VISUAL_PARITY_PROGRESS.md` §6.
- **Character/creature model fidelity is explicitly out of scope for this program.** No new meshes were
  generated (`CLAUDE.md` hard rule); blocky low-poly silhouettes and flat toon shading versus the Palworld
  reference bar are named directly by LIFE's own round-6 judge. — `LIFE/JUDGE-round6.md`; `LIFE/REPORT.md`.
- **The §6 acceptance numbers are PROVISIONAL.** `band1_open` primitives ≤ 12.0M / draw calls ≤ 7500 and
  `hall_approach` draw calls ≤ 4000 are a proxy budget the owner has not yet confirmed, and the minimum
  sustained FPS (45) and 1% low FPS (30) are placeholders pending the on-device measurement above. —
  `docs/VISUAL_PARITY_PROGRESS.md` §6.

---

## 7. Final progress file

**Next agent:** read `docs/VISUAL_NEXT_AGENT_HANDOFF.md` first — it lists what is still short of the vision, the mechanism behind each ceiling, and the working protocol that actually moved rounds.

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
