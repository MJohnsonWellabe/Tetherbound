# Fights lane close-1024 (tb/fights)

## TO COORDINATOR
- 2026-10-24 INFO Task 1 (fight telegraphs vs F38#5-F41#5 "no flat magenta rings or slabs") started. New OFF hook: bodied tell (`telegraph.soft_style.curtain_height_m`, 0/absent = off; scripts/combat/tell_style.gd). Each tell's outer rim (feet ring, charge-lane rails, pattern ring/cone/fan/lane/marker outline, guard cone) raises a thin depth-tested light curtain that fades upward with a travelling shimmer. Footprints, timings, the AI's telegraph and depth rules unchanged. Candidates are capture-only overlays (`cand_tell.py.txt`).

## Rounds

### r1 (24 Oct, CPU llvmpipe Compatibility 1280x720): arm C vs shipping
- Arm C (`cand_tell.py.txt C`): curtains 0.8 m (alpha 0.9, shimmer 0.6) on every tell rim plus hue #8c6cff (hue 253; >= 25 deg from both reserved oxbloods; not teal/cyan) on `telegraph.colour` and `charger_lunge.lane_colour`. Stormwood named rows keep their own #b48cff.
- Captures (control = clean origin/main config):
  - Meadows: `tools/art_pipeline/capture_named_fight.gd --trainer=captain_field --live-member=captain_field:1 --ally=ripplet --frames=12 --interval=0.5 --tell-frames`.
  - Tidewake: `tests/capture_tidewake_named_fights.gd --trainer=water_trainer_tess --interval=1.0 --max-frames=10`.
  - Stormwood: `tools/capture_named_fights_f10_6.gd --ids=glass_field_alpha --seconds=14 --interval=2.0 --camera-view=north --fixture-seed=1042206` with `--fixed-fps 20`.
  - Cloudreach: the captain capture was still running, so it joins r2.
- Batch: `anchor_tiles.py --pairs 3 --seed 1024` (f36_0_gap C2, f04_6_r22, f36_0_npc C3). Three fresh judges, JUDGE_PROMPT v1 verbatim. Defects slot per fight set: "flat magenta ring or slab telegraph on the ground"; "wind-up warning does not show where and when to move".
- Fit: linear, slope 1.48, intercept -2.12, r 0.85, anchor RMSE 0.54, top anchor 6.90 (not confirming), no warnings.

| Set | Control raw | Control mapped | C raw | C mapped | Slab defect (C) | Readability (C) |
|---|---|---|---|---|---|---|
| Meadows | 4.9/5.4/5.6 | 5.72 | 5.5/5.9/6.1 | **6.51** | PARTIAL x3 | PARTIAL x3 |
| Tidewake | 4.8/5.0/5.3 | 5.32 | 4.9/4.8/5.3 | 5.27 | PARTIAL x3 | PRESENT x3 |
| Stormwood | 5.6/5.3/5.7 | 6.06 | 5.6/5.5/5.8 | 6.21 | PRESENT x2, PARTIAL x1 | PARTIAL x2, PRESENT x1 |

- Control slab defect: PRESENT on Meadows (3/3), PRESENT/PARTIAL elsewhere. All three judges' first change: replace ground decals with a physical wind-up (dust and stones kicked along the charge path, a glowing body part on the attacker, an impact at the end point). Arm C stays OFF.
- Round 2: arm D (kicked dust along every tell outline, attacker rim glow, fainter ground line).
