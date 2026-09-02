# Visual Parity program — parallel lane brief

Read this whole file before touching anything. It is the shared contract for every lane
of the Meadows visual-parity program. The coordinator session owns
`docs/VISUAL_PARITY_PROGRESS.md`, the scatter re-bake, and the merge into the program branch.

## Authority

1. `CLAUDE.md` hard rules (no new creature meshes, no Meshy without owner reference art, one
   nature/village/prop family, five creatures, no Biome 2). They win over everything below.
2. `docs/VISUAL_PARITY_STAGED_GOAL_PROMPT_V2.md` — the owner's staged program (VP0…VP11).
3. `docs/TETHERBOUND_VISUAL_BIBLE_V2.md` — the art target. Also `docs/ENVIRONMENT_AND_UI_BIBLE.md`.
4. References: `docs/reference/tetherbound-meadows-keyart.png` (primary),
   `docs/reference/palworld-0*.jpg` (real-time bar), `site/img/page-board.jpg` (approved website art).
5. `ralph/conventions.md` for capture/testing traps. `.claude/skills/visual-judge/SKILL.md` for the blind judge.

Owner decisions already made on this branch (do not relitigate):
- `data/config/grass_field.json` `enabled` is **true**. The grass carpet is the intended ground read.
  It is now laid out in cull tiles (`cull_tile_m`), which is the fix for the ~10 FPS finding.
- Evidence frames are 1280x720 unless a pass needs a hero frame. Never `--headless` with a
  rendering driver.
- The program branch is `claude/coordination-subagents-3fhz1x`. Lanes push to their own
  `claude/vp-<lane>` branch only; the coordinator merges. Never push to `main`, never merge, never
  open a PR, never force-push.

## Environment recipe (fresh container, ~10 min)

```bash
tools/art_pipeline/setup.sh godot            # -> ~/.cache/tetherbound-art/godot (4.7-stable)
apt-get update && apt-get install -y libegl1 libegl-mesa0 mesa-vulkan-drivers xvfb
pip install pillow numpy
export GODOT=$HOME/.cache/tetherbound-art/godot
$GODOT --headless --path . --import && $GODOT --headless --path . --import   # twice on a cold cache
xvfb-run -a -s "-screen 0 1280x720x24" $GODOT --path . --rendering-driver opengl3 \
  --resolution 1280x720 --script tools/capture_diag_minimal.gd          # must write a PNG
```

## Capture recipe

```bash
export GODOT=$HOME/.cache/tetherbound-art/godot RES=1280x720 LIGHT=1
tools/vp_capture.sh ralph/reports/visual-parity/<LANE>/<round> "<comma list of location ids>"
# location ids: 01-village 02-mill-pond 03-quarry 04-warrens 05-relay-camp 06-relay
#               07-mill-crossing 08-ridge-camp 09-waystop 10-stronghold 11-castle-landmark
# Single tools: tools/survey.gd (5 wide frames), tools/_capture_locations.gd -- --only=<ids>,
#               tools/_capture_ground_and_sky.gd, tools/_judge_capture_hall.gd (Hall),
#               tools/survey_combat.gd, tools/capture_buildings.gd, tools/contact_sheet.gd -- --dir=res://shots/<d>
# Baseline ("before") frames for your area: render them FIRST from your starting commit before
# changing anything, into <LANE>/00-before. Matched before/after is required evidence.
```

Software rendering: FPS is meaningless, never quote it. Structural cost is
`tools/perf_render_stats.gd` (draw calls / primitives) at fixed stands; run it with
`--settle=120 --resettle=60 --sample=20` and record numbers in your report.

## Roles (owner directive, 2026-09-02 01:45 UTC)

- **Judge + planner: the program coordinator (Fable).** Judges every round's frames (with a
  code-blind judge that sees ONLY frames, contact sheets, `docs/reference/`, the website board and the
  rubric) and writes the next concrete fix list per area. Merges into the program branch.
- **Area coordinators: Opus sessions** (WORLD = VP1 sky + VP2 ground + VP3 vegetation; PLACES = VP5
  village/tournament/camps + VP6 Warrens exterior + VP7 Relay + VP8 Hall). An area coordinator runs
  ONE round at a time from the fix list it is given: it sets up the environment once, then delegates
  every code edit and every render to Sonnet subagents (the `Agent` tool, `model: sonnet`) inside
  its own container, verifies the pushed frames exist, runs the named tests, pushes its area branch
  + report, and STOPS. It does not write code itself, does not read large files itself, does not
  self-certify, and does not start a new round until the program coordinator sends the next list.
- **Coders/renderers: Sonnet subagents.** Bounded tasks only: "edit these values in this file",
  "run this capture command into this directory", "run these tests and report". "Coded" is not a
  result; a pushed frame is.

## The loop, per round

1. Reproduce the current state (before frames). 2. Fix the highest-impact visible problems in
your owned files. 3. Run your named tests. 4. Capture after frames + contact sheet. 5. Spawn a
**blind judge subagent** (fresh context; give it only the frames, `docs/reference/`, the website
board and the rubric; tell it nothing about what changed). 6. Fix what it names; repeat while it
still names new defects (convergence rule in `ralph/conventions.md`). 7. Commit with
`visual(VP<n>): …` and `[skip ci]` on WIP, push your lane branch, write your report.

## Report (required, at `ralph/reports/visual-parity/<LANE>/REPORT.md`)

Branch + SHA; what changed (files, values, why); before/after frame paths + contact sheets;
judge verdicts per round (verbatim ranked gaps + bar answers); perf numbers; tests run and
results; playability guard results (`smoke_traversal.gd`, `smoke_playground.gd`, plus any smoke
owning your area); unresolved defects; exact recommended next step. The coordinator merges from
this report and the diff, not from a summary claim.

## Lanes and file ownership (edit ONLY your files; read anything)

| lane | branch | pass | owns | must not touch |
|---|---|---|---|---|
| SKY | `claude/vp-sky` | VP1 | `shaders/sky_clouds.gdshader`, `data/config/art.json`, `scripts/world/world_look.gd`, `data/config/weather.json`, `tools/frame_stats.py` | terrain/vegetation/grass files |
| GROUND | `claude/vp-ground` | VP2 | `scripts/world/grass_field.gd`, `data/config/grass_field.json`, `shaders/grass_field.gdshader`, `shaders/cover_tier.gdshader`, `shaders/far_cover.gdshader`, `shaders/stone_field.gdshader`, `shaders/terrain_ground.gdshader`, `data/config/terrain_playground.json` (`shader`/`textures` blocks only), `data/config/water.json`, `shaders/water.gdshader` | `data/config/vegetation.json`, `scripts/world/scatter_rules.gd`, `data/scatter/**` |
| VEG | `claude/vp-veg` | VP3 | `data/config/vegetation.json`, `data/config/bands/*/vegetation.json`, `scripts/world/scatter_rules.gd`, `scripts/world/vegetation.gd`, `data/config/performance.json` (`scatter_lod_ranges` only) | grass_field files, terrain_playground.json, `data/scatter/**` (do NOT commit a bake; run `scripts/world/bake_playground_scatter.gd` locally for your captures and leave the result uncommitted) |
| VILLAGE | `claude/vp-village` | VP5 (village, tournament, camps) | `data/config/village.json`, `data/config/village_boundary.json`, `data/config/tournament.json`, `data/config/props.json`, `data/config/bands/*/props.json`, `scripts/world/village.gd`, `scripts/world/props.gd`, `scripts/world/tournament.gd`, `data/config/building_prefabs.json` (village prefabs only) | Hall/Relay/Warrens files, vegetation, grass |
| HALL | `claude/vp-hall` | VP8 (+VP7 Relay) | `data/config/stronghold.json`, `scripts/world/stronghold*.gd`, `scripts/world/interior_structure.gd` (extend, never replace), `data/config/building_prefabs.json` (`meadows_hall` only), `assets/environment/team_tether/**` materials, `data/config/tether_relay.json`, `data/config/relay_site.json`, `scripts/world/tether_relay.gd`, `tools/_judge_capture_hall.gd` | village/vegetation/grass files |
| WARRENS | `claude/vp-warrens` | VP6 (exterior only; interior is owner-approved GOOD, do not touch) | `data/config/burrow_warrens.json` (exterior/skirt/mound blocks only), `scripts/world/burrow_warrens.gd` (exterior only) | everything else |

Shared ground truth every lane must respect: the ~10 FPS owner report (`ralph/reports/OWNER-0901-PERFORMANCE-LAG-V2.md`);
`docs/PERFORMANCE_BUDGET.md` (≤ 4000 draw calls at `hall_approach`); owner verdicts in
`ralph/OWNER_FEEDBACK_2026-08-29_BUILDINGS.md` and `ralph/OWNER_PLAYTEST_2026-09-01.md` ("do not
overfill with props", "too many people in the village", a gate on every village road); the
standing ledger `ralph/reports/audit/BACKLOG-FROM-AUDIT-2026-08-31.md` and the latest judge verdicts
in `ralph/reports/visual-parity/VP0-baseline/`.
