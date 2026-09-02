# Meadows visuals — handoff to the next agent

**Written 2026-09-02 (end of the Visual Parity program session). Read this before touching any Meadows visual work.**

The goal has not changed: the real, playable Godot Meadows should deliver roughly **80% of the visual impression** of the
approved art — `docs/website/redesign-2026-08-30/02_WEBSITE_ART_BOARD_FINAL.png` (crop `site/img/page-board.jpg`) and
`docs/reference/tetherbound-meadows-keyart.png` — as defined by `docs/TETHERBOUND_VISUAL_BIBLE_V2.md` and staged by
`docs/VISUAL_PARITY_STAGED_GOAL_PROMPT_V2.md`. The program (VP0–VP11) is complete and on `main`; this file is about
**what is still short of the vision, what was learned about closing it, and how to work so the next round actually moves.**

Read in this order: this file → `docs/VISUAL_PARITY_HANDOFF.md` (the evidence package: galleries, perf, judge history,
known limitations §6) → `docs/VISUAL_PARITY_PROGRESS.md` (the authoritative checkpoint ledger, newest check-ins at the
bottom) → the lane closing reports `ralph/reports/visual-parity/{WORLD,CORRIDOR,PLACES,LIFE}/REPORT.md`.

---

## 1. Where things stand

- Everything the program produced is on `main` via PR #20 (VP1–VP9, `b03cdb94`) and PR #21 (lane close-out, VP10,
  VP11 handoff). The program branch `claude/coordination-subagents-3fhz1x` is fully merged; do not resume on it — start a
  new branch from `main`.
- The shipped state of every location is in **one unedited run**: `ralph/reports/visual-parity/VP11-final/`
  (1920x1080; 54 location frames, 5 wide survey stands, 30 ground/water/sky stands, combat, buildings, perf). The
  code-blind final verdict is `VP11-final/JUDGE-final.md`. Before/after for 34 stands: `VP11-final/_sheet_before_after.png`.
- Perf proxy (structural, software GL; not FPS): band1_open 6847 draws / 11.72M prims, hall_approach 3847, village_high
  2880, with `data/config/performance.json` `structure_visibility_ranges: true` and the grass carpet ON. Budgets
  (PROVISIONAL, owner to confirm): band1_open ≤ 7500 draws / ≤ 12.0M prims, hall_approach ≤ 4000 draws.
  **On-device FPS on the ROG Ally has never been measured in this program** — that is the owner's measurement
  (`tools/vp_capture_windows.ps1`) and the single biggest unknown.

## 2. What is still short of the vision (prioritised)

Each item names the mechanism that blocks it. These were each given the owner's one judged shot and declared a
ceiling *under the current mechanism*; the fix is a mechanism change, not another tuning round.

1. **Dawn far plain (sky/ground relationship).** Reference dawn = saturated sky over a hazy, desaturated far plain.
   Blocked because `sky.horizon_colour` must equal `environment.fog_colour` (`fog_sky_affect` 0) to hold the horizon
   seam closed; any far-ground desaturation drags the sky with it (sky saturation 0.363 → 0.136 vs a 0.25 floor).
   Mechanism to try: a terrain aerial-fade colour decoupled from `fog_colour` (a dedicated `aerial_fade_colour` uniform
   in `shaders/terrain_ground.gdshader`, plumbed from `data/config/terrain_playground.json` per time of day), or
   `fog_sky_affect > 0` with the seam re-tuned. Evidence: `WORLD/round9/dawn-distancefade/REJECTED-*.png`,
   `WORLD/REPORT.md` item 3.
2. **Night far ground bluer and brighter than the reference** (should be bluer and darker). Levers are
   `art.json` `times.night.ground_horizon_colour` / `ground_bottom_colour` and the night aerial-fade strength; not
   chased after the seam fix. Evidence: `WORLD/JUDGE-round7.md`.
3. **Night creature meshes render unlit beside lit humans** (village-edge-night, relay-camp-night). Humans get rim/fire
   light; creature meshes do not. Look at the creature material/shader path versus the humanoid one (rim term,
   `SHADING_MODE`, light-affect flags) before touching placement. Evidence: `LIFE/JUDGE-round7.md`, `LIFE/REPORT.md`.
4. **Night stone at the Hall's inner jamb faces (gate-face-night).** A per-sconce omni failed its proof (jamb medians
   0.30/0.00 vs ≥ 28). Needs a light *inside* the gate mouth (or emissive jamb detail) rather than plaques on the outer
   curtain. Evidence: `PLACES/REPORT.md` item 5, progress file check-in #27. Sentries at the gate are **proven** at
   night (per-sentry chest light) — do not reopen them.
5. **Warrens mouth flanks read as an unlit dark mass at the approach stand.** The pale slab and flat wall are fixed
   (0.4 m earth-skin cladding, `burrow_warrens.json` `site.exterior_cladding_*`). What remains is lighting: the flanks
   sit in the mound's own shadow. A soft fill (sky-coloured omni or a lower-sun stand) is the next mechanism.
   Interior is owner-approved GOOD — never touch it.
6. **Hall silhouette at 200–400 m is still soft against the haze.** Material read at ≤ 100 m is fixed (the black-stone
   root cause was `Color.darkened` in sRGB on a dark texture; `stronghold.json` `site.weathering.exterior.darken` is now
   clamped ≤ 0.15). Distant read needs a silhouette lever (tower caps, banner masses, a darker far-LOD tint), not more
   weathering. Evidence: `PLACES/JUDGE-round8.md`, `VP11-final/locations/11-castle-landmark-hall-400m-day.png`.
7. **Corridor station 13 right edge (~10% of frame empty).** Three anchor rounds narrowed it; a fourth would need a
   genuinely new element (a rock line or a fence) rather than another tree anchor. Station 08 signpost text is a
   `Label3D` resolution limit; station 09 water is structurally unreachable. Evidence: `CORRIDOR/REPORT.md`.
8. **Villager walkers** (scoped, never built): `npc_body.gd` is a placed `StaticBody3D`; ~60–100 lines across two
   scripts plus JSON, contingent on the dialogue system exposing "conversation active". Evidence: `LIFE/REPORT.md`.
   Respect the owner's "too many people in the village" verdict — walkers replace static villagers, they do not add.
9. **Character/creature mesh fidelity** is out of scope by hard rule (no new meshes / Meshy without owner reference
   art). Differentiate with materials, scale, animation, VFX only.
10. **Three capture stands are mis-framed by the harness, not the world** (`05-relay-camp` fire inside a scatter
    canopy; `03-quarry` approach inside foliage; `07-mill-crossing` yard at the player's boots). Fix in
    `tools/_capture_locations.gd` (probe first with `tools/_probe_relay_fire_trees.gd --at=X,Z`). Also:
    `tools/_capture_ground_and_sky.gd` exits 1 with a stale "GrassField holds no instances" guard while writing every
    frame correctly — fix the guard or ignore the exit code.
11. **Terrain3D streams around the player, not the camera.** ~30 capture tools still drop the player 500 m below the
    stand; any distant-camera feature (cutscene, photo mode) must move the streaming anchor with the camera.
12. **45% of band1_open draw calls are unattributed** in the per-group breakdown (`VP10-perf/`). If the owner's Ally
    measurement is below the floor, that attribution gap is where to look first; the grass carpet is *not* the cost
    (133 draws, measured).

## 3. What the judges kept saying (direction for the next visual round)

Across ~35 code-blind rounds the recurring gap to the reference was never one defect; it was **layering and
composition**: the reference has a foreground element, a mid-ground subject and a distant mass in nearly every frame,
with warm/cool separation between them. The build now has the sky, the ground and the vegetation clustering to do
that, but many stands still read as "subject on a plain". The highest-value next round is therefore **per-stand
composition** (foreground rock/log/bush within 3 m of the eye, a mid-ground landmark, a distant silhouette) on the
five survey stands and the village/Hall approaches, judged blind against the page-board — not another global
shader pass. Use `tools/_probe_station14_candidates.gd` as the pattern for choosing eye/look pairs without paying a
render per candidate.

## 4. How to work so a round actually moves

- **Judge first, code second.** Every round is judged by a **code-blind** Sonnet subagent given only the frames,
  `docs/reference/`, `site/img/page-board.jpg` and `.claude/skills/visual-judge/SKILL.md`. Never tell it what changed.
  Convergence rule: `ralph/conventions.md`.
- **Owner's one-shot rule.** Each open item gets one judged shot with a numeric proof (crop medians, luminance,
  pixel-diff %) written *before* the render. If it fails: either record it as a ceiling with the mechanism named, or
  hand it to a **clean Fable agent** that starts from the brief and the frame, not from the previous attempts. Four
  chronic items (station 14, Hall black stone, sentries, Warrens slab) each failed 3–5 tuning rounds and were then fixed
  by a clean restart that root-caused them in under an hour. Tuning rounds are not progress; root causes are.
- **Prove by number, not by prose.** Every lane that said "fixed" without a crop measurement was wrong at least once.
  Pattern: Python/PIL crop → median/mean → compare to a target set in advance.
- **Capture protocol** (never `--headless` with a render driver — it hangs):
  ```
  GODOT=$HOME/.cache/tetherbound-art/godot          # tools/art_pipeline/setup.sh godot installs it
  RES=1920x1080 tools/vp_capture.sh ralph/reports/visual-parity/<round>        # full evidence set (~2 h)
  RES=1920x1080 tools/vp_capture.sh <dir> 05-relay-camp,10-stronghold          # locations subset
  xvfb-run -a -s "-screen 0 1280x720x24" $GODOT --path . --rendering-driver opengl3 --resolution 1280x720 \
    --script tools/perf_render_stats.gd -- --views=band1_open,hall_approach,village_high --settle=120 --resettle=60 --sample=20
  ```
  One Godot process at a time on the 4-core box; serialise with `while pgrep -x godot; do sleep 10; done`. The grass
  carpet stays ON in evidence (owner directive). Re-bake scatter (`scripts/world/bake_playground_scatter.gd`, then
  `$GODOT --headless --path . --import`) after any edit to `vegetation.json`, `terrain_playground.json` or a band
  vegetation file, or CI's `verify-scatter-bake-freshness` and `test_scatter_perf_budget` go red.
- **CI traps.** A docs-only or `[skip ci]` head commit skips every code job on the push run *and* the PR run (a
  3-minute green is a skip, not a pass). Ship through a PR whose head is a non-skip commit and confirm the code jobs
  actually ran before merging. Concurrency cancels superseded runs.
- **Perf proxy every round** at the same stands/resolution/settle; software GL FPS is meaningless — only draw calls,
  primitives, objects.
- **Where the knobs are.** Sky/light/time: `data/config/art.json` + `scripts/world/world_look.gd` +
  `shaders/sky_clouds.gdshader`. Terrain: `data/config/terrain_playground.json` + `shaders/terrain_ground.gdshader`.
  Scatter: `data/config/vegetation.json`, band `vegetation.json` (`layer_anchors`), `scripts/world/scatter_rules.gd`.
  Props/camps: `data/config/bands/<band>/props.json`, `village.json`. Hall: `stronghold.json` + `stronghold.gd` +
  `assets/environment/team_tether/hall/hall_stone.gdshader`. Warrens: `burrow_warrens.json` + `burrow_warrens.gd`.
  Relay: `tether_relay.json`. Visibility ranges: `performance.json` `structure_visibility_range`.
- **Hard rules that bit us:** no new meshes; interior of the Warrens untouched; do not overfill with props; no more
  villagers; gate on every village road stays; five-creature limit and all `CLAUDE.md` rules apply to visual work too.

## 5. Suggested next program (if the owner wants another round)

1. Owner measures FPS on the Ally at the three perf stands with the shipped defaults; if below floor, attribute the
   45% unknown draws before any visual work.
2. One clean Fable agent, one branch, **composition round** on the five survey stands + village approach + Hall
   approach (§3), judged blind, one shot per stand, ceiling or restart.
3. Then the mechanism items in §2 order (dawn fade colour decoupling → night creature lighting → gate-mouth light →
   Warrens fill), each as its own branch with its own before/after and blind judge.
4. Keep `docs/VISUAL_PARITY_PROGRESS.md` as the running ledger (append check-ins; never rewrite history) and re-run
   `tools/vp_capture.sh` for a full before/after set at the end.
