# Fights lane close-1024 (tb/fights)

## TO COORDINATOR
- 2026-10-24 04:20 CT READY tb/fights-land 570357333: bodied fight telegraphs ON. Built on origin/main 2cde391e4; clean merge, no file overlap with main since base.
  - What changed:
    - Every wind-up (feet ring, charge lane, pattern ring/cone/fan/lane/marker/field, guard cone) raises kicked dust along its outline (drifting down a lane toward the strike), a low light curtain and a faint rim glow on the attacker.
    - The painted line is fainter, and the shared hue is #b16cff (was magenta #ff40e6).
    - Fixes: lingering pattern fields hard-coded magenta (they now follow the tell hue: Cloudreach's magenta rings); the Stormwood hosted-fight observer ring used the retired oxblood-band #ff5a3c; the stagger ring no longer takes the extras.
  - Scores, yardstick r2 (CPU, 3 fresh judges, mapped; arm E judged at #8c6cff):
    - Meadows 6.54 vs shipping 5.51; Tidewake 6.38 vs 5.97; Stormwood 6.13 vs 5.87.
    - Judged slab defect PRESENT -> PARTIAL, so F38#5-F41#5 and the 7.5 bar stay OPEN. ON under the judged-better rule.
  - The hue moved from 253 to 268 deg (#b16cff) so the shared tell stays 72 deg from the Riverwatch water tells (test_f22_riverwatch_presentation). r3 (Meadows, Tidewake, Cloudreach on the shipped config) is capturing to re-judge it; I'll add the result here.
  - Checks run on tb/fights ac8a016d8 (same telegraph code and config as the land commit): 134 tests across telegraph_glow, charger_lunge, enemy_pattern_telegraph, stormwood_b_named_lunge_lanes/cues, creature_attack_telegraph_animation, lunge_lane, telegraph, shared_opponent_cue_shape, named_tell_text, combat_stagger, combat_ai, combat_feedback, f22_riverwatch_presentation, stormwood_road_current, named_fight, fight_camera, combat_arena, combat_manager, stormwood_hosted_combat: 0 failed. stormwood_lightning/surge, water_alpha, tidecoil: 80 tests, 0 failed.
  - Not run: the C2 named-fight smoke (no gameplay or timing change) and full CI.
  - Balance: game 5 commits / tests-tools 0.
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

### r2 (24 Oct, CPU llvmpipe Compatibility 1280x720): arm E vs shipping
- Arm D, captured and not judged: kicked dust, attacker glow 0.9, fainter ground line. At 0.9 the glow washed Voltarach and Mirejaw pale on Compatibility, the same "ghost" look as the GPU Riverwatch aura, so D was dropped.
- Arm E (`cand_tell.py.txt E`), the same captures as r1:
  - Kicked dust (`dust_alpha` 0.75, spacing 0.55 m, size 0.8 m, rise 0.9 m, 1.1 Hz, #cdb894) rises along every tell outline and drifts down a lane toward the strike.
  - The attacker glows faintly during its wind-up (`tell_aura` 0.3 on Compatibility, x0.3 on Forward+).
  - Curtain 0.4 m at alpha 0.5.
  - Fainter ground line: edge 0.32, locked 0.6, core 0.75, build start 0.4.
  - Hue #8c6cff.
- Batch: same anchors (seed 1024), three fresh judges, JUDGE_PROMPT v1 verbatim, same defects slot. Fit: linear, slope 1.54, intercept -2.63, r 0.85, RMSE 0.53, top anchor 6.90, no warnings.

| Set | Control raw | Control mapped | E raw | E mapped | Slab defect (E) | Readability (E) |
|---|---|---|---|---|---|---|
| Meadows | 5.5/5.2/5.2 | 5.51 | 6.4/5.7/5.8 | **6.54** | PARTIAL x3 | PARTIAL x3 |
| Tidewake | 6.2/5.3/5.3 | 5.97 | 6.5/5.6/5.5 | **6.38** | PARTIAL x3 | PARTIAL x3 |
| Stormwood | 5.9/5.1/5.6 | 5.87 | 6.2/5.3/5.6 | **6.13** | PARTIAL x3 | PARTIAL x2, PRESENT x1 |

- E beats shipping on every set: 3/3 judges in Meadows and Tidewake; 2/3 in Stormwood, with one tie.
- The control's slab defect read PRESENT in Meadows from all three judges. On E it is PARTIAL everywhere ("grey dust disc", "translucent strip, no longer magenta"), but every judge still sees a flat ground decal, so F38#5-F41#5 do not close on the telegraph.
- Gain on the r1 best: Meadows +0.03, Stormwood -0.08 (round 1 under +0.5), Tidewake +1.06.
- Judges' asks:
  - Cracking ground or stones lifting along the lane, beyond dust.
  - The camera and the HUD covering the lower third (Camera/UI-owned).
  - The judges' readability note: a fainter lane reads "where" less clearly than magenta did.

### r3 (24 Oct, CPU llvmpipe Compatibility): shipped config (#b16cff) vs shipping main
- Arm F is the committed config as is (ac8a016d8 onward); control is origin/main before this lane. Captures:
  - Meadows and Tidewake: the r1/r2 commands.
  - Cloudreach: `tools/phase2_capture_cloudreach_live_fight.gd --seed=7` (1920x1080, captain Veyra; frames live-1722/1902/2082/2262; 40 min cap). It includes the lingering-field colour fix.
- Batch: same anchors (seed 1024), three fresh judges, JUDGE_PROMPT v1 verbatim. Fit: linear, slope 1.61, intercept -2.89, r 0.88, RMSE 0.48, top anchor 6.90, no warnings.

| Set | Control raw | Control mapped | F raw | F mapped | Slab defect (F) |
|---|---|---|---|---|---|
| Meadows | 5.3/5.6/5.3 | 5.80 | 5.8/6.0/5.6 | **6.44** | PARTIAL x3 |
| Tidewake | 5.5/5.0/5.2 | 5.53 | 5.9/5.6/5.8 | **6.39** | PARTIAL x3 |
| Cloudreach | 5.5/5.5/5.4 | 5.91 | 5.8/5.7/5.6 | **6.28** | PARTIAL x3 (control PRESENT x3) |

- The shipped hue holds the r2 result, and all three judges prefer it on every set.
- Gain rule (telegraph rounds, mapped best):
  - Meadows: r2 +0.03, r3 -0.10, two rounds under +0.5, so PARKED at 6.54.
  - Tidewake: r3 +0.01 (round 1 under).
  - Stormwood: parked at 6.21 (r2 -0.08 after r1 +0.15).
  - Cloudreach: first judged here at 6.28.
- Still open in every biome: F38#5-F41#5 (slab defect PARTIAL, not FIXED) and the 7.5 bar.
- Judges' next asks, the same in all three rounds: cracked ground or stones lifting along the lane plus a timing fill (new art or effects); camera and HUD (Camera/UI lanes).
- Sheet: `_sheet_r3.png` (Meadows and Cloudreach, control left, F right).
