# GROUND lane — VP2 (terrain materials + ground-cover density) — REPORT

`branch: claude/vp-ground` · `starting SHA: eb884325e8270fc2d7e45a6d71d4d82869a07223` ·
`final SHA: <<FILL: SHA after last commit this lane pushes>>` · `date: 2026-09-02` · `pass: VP2`

Owns (`docs/VISUAL_PARITY_LANES.md`): `scripts/world/grass_field.gd`, `data/config/grass_field.json`,
`shaders/grass_field.gdshader`, `shaders/cover_tier.gdshader`, `shaders/far_cover.gdshader`,
`shaders/stone_field.gdshader`, `shaders/terrain_ground.gdshader`, `data/config/terrain_playground.json`
(`shader`/`textures` blocks only), `data/config/water.json`, `shaders/water.gdshader`. Must not touch
`data/config/vegetation.json`, `scripts/world/scatter_rules.gd`, `data/scatter/**`.

Owner directive this pass answers: the grass carpet (`data/config/grass_field.json` `enabled: true`)
stays **ON**. The ~10 FPS Ally finding (`ralph/reports/OWNER-0901-PERFORMANCE-LAG-V2.md`) is fixed by
making the carpet affordable — per-tile/instance distance culling and far-band thinning — not by
reverting the flag to `false`.

## 1. Perf table — front and centre

`tools/perf_render_stats.gd --views=band1_open,village_high --settle=120 --resettle=60 --sample=20` at
1280x720, `--rendering-driver opengl3`, same bake unless noted. `TB_GRASS_CULL_TILE_M` env override
selects `cull_tile_m`. Delta is vs the owner-report carpet-ON baseline (31,757,567 primitives).

| view | state | draw calls | primitives | objects | delta vs 31.76M |
|---|---|---|---|---|---|
| band1_open | owner-report baseline, carpet ON (no cull tiling) | 7320 | 31,757,567 | 6315 | — (ref) |
| band1_open | owner-report baseline, carpet OFF | 7366 | 9,250,290 | 6361 | -70.9% |
| band1_open | `cull_tile_m=0` (before this pass) | <<FILL>> | <<FILL>> | <<FILL>> | <<FILL>> |
| band1_open | `cull_tile_m=16` (before this pass) | <<FILL>> | <<FILL>> | <<FILL>> | <<FILL>> |
| band1_open | `cull_tile_m=8` (before this pass) | <<FILL>> | <<FILL>> | <<FILL>> | <<FILL>> |
| village_high | `cull_tile_m=0` (before) | <<FILL>> | <<FILL>> | <<FILL>> | n/a |
| village_high | `cull_tile_m=16` (before) | <<FILL>> | <<FILL>> | <<FILL>> | n/a |
| village_high | `cull_tile_m=8` (before) | <<FILL>> | <<FILL>> | <<FILL>> | n/a |
| band1_open | **after** — chosen `cull_tile_m`+far thinning+LOD, carpet ON | <<FILL>> | <<FILL>> | <<FILL>> | <<FILL>> |
| village_high | **after** — same config | <<FILL>> | <<FILL>> | <<FILL>> | n/a |

Proxy budget (`docs/VISUAL_PARITY_PROGRESS.md` §6): primitives at `band1_open` <= 12.0M, draw calls
at `band1_open` <= 7500.

**What the numbers mean:** <<FILL: did the chosen cull_tile_m land inside budget with the carpet
still visually on; what fraction of the 22.5M grass_field cost far-band thinning removed; did draw
calls move meaningfully (owner-report showed they barely do — Compatibility renderer counts MultiMesh
batches, not instances) or did the terrain_ground.gdshader tail add measurable cost; any surprise
(e.g. village_high vs band1_open behaving differently)>>

## 2. What changed (files, values, why)

### 2a. Grass ring far cost (cull tiles, far thinning, tier reach caps, LOD)

Standing counts: grass ring 315,232 instances / 9 lattice layers (`tuft_count` 300,000); stones
93,236; bushes 15,052; flowers 15,052; litter 48,716; far-cover sheet 71,200 tris (1 sheet). Modelled
primitive budget (48 tris/tuft, 35/stone, ~190/bush, 32/flower, 8/litter): grass 15.13M, stones 3.26M,
bushes 2.86M, flowers 0.48M, litter 0.39M. ~189k of the ring's 315k instances (~60%) sit in the 40–72m
fade band — the target for tile culling/far thinning to remove before it reaches the GPU.

<<FILL: every value changed in `grass_field.gd`/`grass_field.json` — final `cull_tile_m`,
per-lattice-layer visibility ranges (`instance_geometry_set_visibility_range` or equivalent), far-band
thinning ratio/method, per-tier reach caps (tuft/stone/bush/flower/litter), LOD swap distances — file,
old value, new value, one-sentence why (cost removed, visual read preserved)>>

### 2b. Terrain material (shader tail: grain/damp/path wear; textures block tints)

<<FILL: changes to `shaders/terrain_ground.gdshader` (grain/noise detail, damp/wet darkening,
path-wear blending) and `data/config/terrain_playground.json`'s `shader`/`textures` blocks (tint,
scale, transition sharpness) — file, old value, new value, why, tied to VP2's brief: less exposed
uniform terrain, better texture scale, better dirt/grass/rock and path transitions, no fluorescent-
lime surfaces>>

### 2c. Water

<<FILL: changes to `data/config/water.json`/`shaders/water.gdshader` — edge transition, color, cost —
file, old, new, why. If nothing changed, say so and why>>

## 3. Before/after evidence

- Before: `ralph/reports/visual-parity/GROUND/00-before/ground/` (matched player-height views: open
  meadow, path, village edge, water edge, forest edge) and `.../00-before/locations/` (wide set per
  `tools/vp_capture.sh` location ids).
- Round dirs: `ralph/reports/visual-parity/GROUND/round1/`, `round2/`, … each with its own contact
  sheet. Contact sheets: <<FILL: path per round, from `tools/contact_sheet.gd -- --dir=res://shots/<d>`>>

<<FILL: confirm every path above exists and matches; note any flat/black capture (VP-PRE found
`apply_time("golden")` renders nothing — check GROUND captures for the same defect)>>

## 4. Judge verdicts per round

Blind judge per `.claude/skills/visual-judge/SKILL.md` — fresh subagent, frames + `docs/reference/` +
website board + rubric only, told nothing about what changed.

**Round 1** — Bar A (keyart world): <<FILL>>. Bar B (Palworld kind of game): <<FILL>>.
Ranked gaps (verbatim): <<FILL: 1) ... 2) ... 3) ...>>. Response: <<FILL: gap → file/value change>>.

**Round 2** (if not converged) — Bar A: <<FILL>>. Bar B: <<FILL>>. Ranked gaps (verbatim): <<FILL>>.
Response: <<FILL>>.

<<FILL: repeat per `ralph/conventions.md` convergence rule until no new defects, or record why
iteration stopped early>>

## 5. Tests run and results

| test | command | result |
|---|---|---|
| `tests/test_grass_field.gd` | `run_tests.gd -- --only=grass_field` | <<FILL: pass/fail, N tests/asserts>> |
| `tests/test_scatter_perf_budget.gd` | `run_tests.gd -- --only=scatter_perf_budget` | <<FILL>> |
| full unit suite (if run) | `run_tests.gd` (no filter) | <<FILL>> |

## 6. Playability guard

Per `docs/VISUAL_PARITY_STAGED_GOAL_PROMPT_V2.md` §7 / `docs/VISUAL_PARITY_LANES.md`.

| check | result |
|---|---|
| `tests/smoke_traversal.gd` — major route traversable end to end | <<FILL>> |
| `tests/smoke_playground.gd` | <<FILL>> |
| `tests/smoke_unstick.gd` — no new blockers/stuck spots from tiling/culling | <<FILL>> |
| NPC/creature pathfinding unaffected | <<FILL: N/A — lane doesn't touch scatter/navmesh, or note if terrain collision was touched>> |
| save/load | <<FILL>> |

## 7. Re-bake note

Any edit to `data/config/terrain_playground.json` (even the `shader`/`textures` blocks this lane owns)
moves the scatter bake fingerprint. This lane does **not** commit a re-bake of `data/scatter/**` — out
of scope per file ownership. The coordinator re-bakes (`scripts/world/bake_playground_scatter.gd`)
after merging this lane, before the next lane captures against scatter output.

<<FILL: confirm whether this pass touched `terrain_playground.json`, and if so which blocks/keys, so
the coordinator knows a re-bake is actually required>>

## 8. Proposed bake-side values (macro/colour/paths)

Observations that would improve the ground read but sit in scatter/vegetation/bake territory owned by
VEG or the coordinator's bake step — not implemented here, only proposed:

<<FILL: e.g. macro terrain-color variation noise scale/amplitude, path-wear blend width, any
scatter density/placement suggestion for VEG>>

## 9. Unresolved defects + recommended next step

| defect | evidence | recommended next step |
|---|---|---|
| <<FILL>> | <<FILL: frame/round path>> | <<FILL>> |
| <<FILL>> | <<FILL>> | <<FILL>> |

**Exact recommended next step for the coordinator:** <<FILL: e.g. merge GROUND into the program
branch, trigger the scatter re-bake, then VEG lane recaptures against the new bake before its judge round>>
