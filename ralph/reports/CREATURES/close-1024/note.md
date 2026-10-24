# Creatures close-1024 (lane tb/creatures)

Rows: F36#0, F36#1, F29#3. Renderer for every capture: Godot 4.7 Compatibility (Low), Mesa llvmpipe under xvfb (CPU-provisional bar 6.7 mapped).

## TO COORDINATOR
- 24 Oct 04:10 CT READY tb/creatures-land 250d4b42b (= 337f81506 + one commit): F36#0 Mudsnout, Trailpup, Paddlenewt naturalistic remakes (your Meshy batch 1, thanks) and the Riverdrake pilot, land and water forms, ON.
  - b6 (CPU, 3 judges, confirming; `close-1024/b6/judges.md`): Trailpup 7.49 vs 6.50, Mudsnout 7.40 vs 5.61, Paddlenewt 6.88 vs 5.29, water Riverdrake 7.00 vs 6.36; land Riverdrake 7.29 vs 4.78 (b1).
  - Functional fix with test: `water_species_catalog.gd` forced every water presentation's colourway source to the board id, so a replacement water mesh wore the installed atlas on its own UVs. A presentation may now name its own source; `test_water_species_catalog.gd` checks only replacement meshes may.
  - Riverdrake water mount/saddle unchanged (pilot back about 2.49 m under the 2.739 m seat). `smoke_water_mounted_swimming.gd` restricted to water_riverdrake: 19/19 checks. NOTE: the unrestricted smoke fails at water_sirenseal ("rider art origin remains above sea") on origin/main data too, before it reaches Riverdrake; pre-existing, not touched here.
  - Checks on 250d4b42b: Godot `--only=mudsnout,trailpup,paddlenewt,riverdrake,terrapup,bramblebun,rest_pose,rideable,riding,f36_pose,creature_pose,species,creature_body,scale_ladder,colourway,shiny,surface_finish,variant,texture_import_policy,companion,water,roster,fly,meadowhart,spawns,saddle,bed,camp,evolution` 848 tests, 0 failed; postpass `--check` current; texture policy PASS.
  - Also passing in b6 but held for mount/faint work: Burrowback 7.23 (rideable seat), Mosshell 7.08 (faint stands; water swim mount), Veridian 6.82 (rideable seat). Losing, OFF: Sparkit 5.84, Staticub 7.11 (lost its storm veins, maroon drift), Mirejaw 6.42.
- 24 Oct MESHY batch 2 request follows once I've drafted it: Staticub juvenile with violet storm veins (F29#3), Sparkit with fennec ears and real fur, Pipwing (bird rig weighting fails on the remake; heat weighting found no solution, a cleaner single-shell mesh may fix it).
- 24 Oct 01:40 CT READY tb/creatures-land 337f81506 (= 7773d93c5 Terrapup/Bramblebun pilots + one commit): F36#1 held shove hit live for 16 species and five more species on their recipe.
  - b2-b4 (CPU, 3 judges x 3 batches, standard prompt, confirming batches; `close-1024/b2/judges.md`): Craghorn 7.89, Cloudfang 7.82, Breezetail 7.73, Stormraven 7.47, Tidecoil 7.43, Burrowback 7.34, Frostclaw 7.34, Aquaryn 7.29, Thundertunnel 7.22, Cliffspike 7.16, Pebbik 7.09, Trailpup 7.08, Voltwig 7.04, Stormbrush 6.97, Sirenseal 6.97, Riptusk 6.79 mapped, each above shipping. b3 (Aquaryn, Tidecoil, Voltwig, Sirenseal, Riptusk) carries an anchor-RMSE 0.83 caveat.
  - The regenerated `f36_pose_candidates.json` changes exactly those 16 profiles, each byte-equal to its judged candidate; Aquaryn/Tidecoil/Breezetail/Craghorn/Stormraven join `enabled_species`.
  - Checks on 337f81506: Godot `--only=f36_pose,creature_pose,creature_body,species,scale_ladder,water,roster,fly,riding,rideable,terrapup,bramblebun,rest_pose,texture_import_policy` 617 tests, 0 failed; `test_f36_pose_postpass.py` 8/8 OK (tear guard); postpass `--check` current.
  - GPU confirm: `capture_f36_poses.gd --candidate --whole-body --context --species=<the 16>`.
- 24 Oct QUESTION (your call, as on 22 Oct): these beat shipping but sit under 6.7 mapped, all OFF: Cindercub 6.67, Cragclaw 6.65, Skyrill 6.62, Ashtusk 6.57, Nightburrow 6.52 (+1.03), Shadelet 6.52, Mangrove Monitor 6.51, Cannonback 6.44, Mosshock 6.13, Mudsnout 6.00, Tuskroot 5.95, Stormtrail 5.75, Riftfrill 5.18. ON for the wind-down, or keep OFF? I'll keep iterating their faints meanwhile.
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
