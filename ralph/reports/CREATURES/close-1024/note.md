# Creatures close-1024 (lane tb/creatures)

Rows: F36#0, F36#1, F29#3. Renderer for every capture: Godot 4.7 Compatibility (Low), Mesa llvmpipe under xvfb (CPU-provisional bar 6.7 mapped).

## TO COORDINATOR
- 23 Oct 23:59 CT READY tb/creatures-land 7773d93c5 (origin/main 5f1f388cc + one commit): F36#0 Terrapup (starter) and Bramblebun naturalistic pilots ON.
  - b1 (CPU, three judges, standard prompt, confirming batch; `close-1024/b1/`): Terrapup 7.62 vs live 5.30, Bramblebun 7.57 vs live 4.59 mapped. Both clear 7.5 even on CPU; recorded as CPU-provisional until a GPU pass.
  - Integration: Terrapup seat 3.264 -> 3.80 m on the measured plated back, rest offset 1.0302 -> 0 (pilot rest clip grounded, 0.79 height ratio), out of `enabled_species`; Bramblebun lift/degreen off. Provenance jsonl + drafted concept beside each rig. Textures mode 2.
  - Checks on 7773d93c5: Godot `--only=terrapup,bramblebun,rest_pose,rideable,riding,f36_pose,creature_pose,species,creature_body,scale_ladder,colourway,shiny,surface_finish,variant,texture_import_policy,companion,water,roster,fly,meadowhart,spawns,saddle,bed,camp` 806 tests, 0 failed; `smoke_bramblebun_colourway_binding.gd` 12/12; postpass `--check` current; texture policy PASS.
  - Test changes follow the shipped model: F36 wiring sample Terrapup -> Trailpup; rest offset pin 1.0302 -> 0; Bramblebun UV smoke reads the shipped GLB.
  - Known: `tools/_capture_riding.gd --species=terrapup` fails identically on main (Meadowhart-only leg/boot fit; mount fades from its camera), so the seat was checked on the pose stage's ride row. No authored shiny/alpha for the pilot UVs (fallback path, as Meadowhart).
  - GPU confirm: `capture_f36_poses.gd --whole-body --context --species=terrapup,bramblebun` (no `--candidate`).
- 23 Oct (b1) Riverdrake pilot 7.29 vs live 4.78 (>= 6.7 CPU). Held on tb/creatures: `water_riverdrake` binds its own model (water_roster/water_mounts), so land and water forms move together after a water-mount re-measure.
- 23 Oct MESHY: batch 1, ten naturalistic remakes (starters/main path first): `ralph/reports/CREATURES/close-1024/meshy-batch1/REQUEST.md` (identity refs, target heights, prompts; same route as the Meadowhart nat-v1 pilot).

## Worklist
1. F36#0: judge the archived Terrapup, Bramblebun and Riverdrake naturalistic pilots against live (restored from `tb/archive-2026-10-23^4`, OFF); rig Ripplet and Galewisp nat-v1 GLBs.
2. F36#1: full shipping pose matrix (58 species) captured, ranked, worst faints fixed (Fulgocobra faint end rears up).
3. F29#3: Staticub juvenile remake (batch 1) for the cub/adult read; Stormursa eyes, veins, rim.
