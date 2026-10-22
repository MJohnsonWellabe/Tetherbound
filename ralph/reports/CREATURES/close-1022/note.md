# Creatures close-1022 (lane tb/creatures)

## TO COORDINATOR
- 22 Oct 14:40 CT QUESTION Is OUTBOX.md fine for MESHY requests (six MESHY lines and three REDRAFTs are there), or should they move here?
- 22 Oct 14:40 CT (b1 CPU yardstick) Candidates beat base on every set, but none has reached 7.5: shiny 6.60, poses 6.64, dark palette 6.12, F29#3 6.12 (mapped). Round 2 is capturing now.

Renderer for every capture: Godot 4.7 Compatibility (Low), Mesa llvmpipe under xvfb. Scoring waits for the
judge yardstick (tb/judge-yardstick) to land; until then this lane fixes and captures.

## RESUME
- Coordinator messaging is refused from this session (`elevated_session_untrusted_device`); see `OUTBOX.md`.
- Meshy remakes (two-style split, top GPU ask) are blocked on reference drafts: `remake-briefs.md`.
- Candidates, all OFF on the branch:
  - `f36_pose_postpass.py --candidate-1022` (+ `f36_arachnid_profile.py --candidate-1022`): every recoil hit becomes
    the body-carried shove at gain 1.5; Mirejaw side topple; Meadowhart resting-deer prone (antlers off the floor);
    Fulgocobra hood-drop prone (dip 3) + shove; Voltarach side-tip with legs curled.
  - `data/config/creature_surface_finish_1022_candidate.json`: value-gamma lift for Tanglevolt, Voltarach,
    Galecrest, Fulgocobra (shader uniforms `base_value_gamma`/`base_saturation_scale`, default 1.0 = unchanged).
  - Solmane / Pebbik shiny gradient maps: `<species>_extracted_base_color_shiny_gm.png`
    (`solmane/source/shiny_gradient_map.py`); live shiny png and the `shift` rows unchanged.
  - P2-030 r3 (ported from tb/shared-art ae6bafa24 with the fallback ON): `p2-030-r3-finishes.json`.
  - F29#3 growth: Stormursa 4.10 -> 5.00 m (species.json height/radius + ladder target) on this branch only.

## Batch b1 (22 Oct ~14:00 CT): yardstick round 1, every candidate beats its base; none at 7.5

CPU Compatibility (llvmpipe), stage tool `capture_f36_poses.gd --candidate --whole-body --context` at 1280x720
(base = lane state with live recipes and Stormursa 4.10 m; c1 = `--candidate-1022` recipes, finish candidate rows,
Stormursa 5.00 m) and `phase2_capture_creatures.gd --biome=cloudreach --poses=idle,shiny_idle` for the shinies.
Standard prompt verbatim, three fresh judges, 3 anchor pairs (p2_094_r4, f36_0_gap:C2, f36_0_npc:C1), `calibrate.py`:
linear, slope 1.309, intercept -1.827, anchor RMSE 0.432, top anchor 7.53 (confirming batch), no warnings. Files: `b1/`.

| Set | Base raw (j1/j2/j3) | c1 raw | Base mapped | **c1 mapped** | Gain |
|---|---|---|---|---|---|
| P2-018 Solmane + Pebbik shinies (gradient map) | 5.6/5.6/5.6 | 6.4/6.5/6.4 | 5.50 | **6.60** | +1.10 |
| F36 poses (Mirejaw, Meadowhart, Voltarach) | 5.2/5.6/5.4 | 6.2/6.6/6.6 | 5.24 | **6.64** | +1.40 |
| F36 dark palette (Tanglevolt, Galecrest, Fulgocobra) | 5.4/5.6/5.3 | 6.0/6.2/6.0 | 5.29 | **6.12** | +0.83 |
| F29#3 Stormursa 5.00 m + bear shove hit | 5.3/5.8/5.5 | 5.8/6.4/6.0 | 5.42 | **6.12** | +0.70 |

Defects (c1): hit react FIXED x2 / PARTIAL x1; Mirejaw+Voltarach faint FIXED x2 / PARTIAL x1; Meadowhart antlers FIXED x3;
dark melt PARTIAL x3; shiny blotches PARTIAL x3 (Solmane navy wing streaks and eye smudges, Pebbik flank mottling);
cub = adult model PRESENT/PARTIAL (needs new art), bear hit PARTIAL (recover equals standing).
Asks: lift dark grades further plus a soft rim (Mirejaw's faint end goes near-black; Voltarach melts); a distinct
juvenile cub mesh (new art); cleaner shiny masks. Fulgocobra keeps its live pose (prone hood-drop dropped unjudged).
