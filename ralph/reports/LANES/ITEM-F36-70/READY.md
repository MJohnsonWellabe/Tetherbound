STATUS: land
BRANCH: tb/item-f36-70  HEAD: the commit that adds this file

- Row: F36#70 Sparkit legs (GPU 5.41; Blender/art row). Judges, three rounds: "spindly stick legs".
- New art: a geometry-only patch of the live owner-remake GLB. `thicken_legs_glb.py` rewrites only the POSITION accessor; rig, weights, all 11 clips, normals, materials and textures stay byte-identical.
  - Legs are found geometrically: below the hip, split into four by side and front/rear. This remake's auto-weights put most leg vertices on pelvis/spine, and its leg bones sit off the leg geometry.
  - Each 2 cm height slice is scaled horizontally about its own centroid: fades in under the hip, eases at the paw.
  - Height stays 1.95 m (> 1.80 m trainer); nothing shrinks. Blender (`thicken_legs.py`, a first try) was dropped: its glTF round-trip re-oriented the bones and broke the clips (collapsed stills, round 1). Blender 4.2 Cycles renders were the before/after reference check.
  - Provenance: source `creature_sparkit_owner1101.glb` (Meshy 01a197ef-c6ca-707e-a25f-84f3434e6678, owner remake 1 Nov); scripts in this dir.
- Rounds (CPU mapped, three code-blind judges each):
  1. `qj/F36-70-76438ddef11e-11072206`: Stormwood creature stand, x1.4: **flat** 4.49 -> 4.49. Sparkit is too small there to read legs.
  2. `qj/F36-70-76438ddef11e-11072217`: neutral stage beside the 1.80 m ruler (`capture_f36_poses.gd`, job in `qj_job.json`), x1.4: **6.51 -> 6.71 (+0.20)**.
  3. `qj/F36-70-5ab631b5d2af-11072222`: same stage, x1.8 over x1.4: **5.91 -> 6.03 (+0.12)**, every judge +0.1.
  Stop: two consecutive rounds gaining under 0.5.
- Flag ON: `data/config/creature_model_flags.json:flags.lanekit_sparkit_legs_1107`, model `creature_sparkit_owner1101_legs18.glb`. `_why_on` names r2, `_why_on_r3` names r3.
- Tests: `tests/test_creature_model_flags.gd`. The flag was added to HELD while OFF and removed from HELD when ON. run_tests --only=test_creature_model_flags: 3 tests, 1082 assertions, 0 failed.
- Files: creature_model_flags.json, test_creature_model_flags.gd, the legs18 GLB plus its extracted textures and .import (compress mode 2 like the live remake), scripts, qj_job.json, the three verdict dirs.
- Left OFF: `creatures_ralph_sparkit_lateral_hit` (other lane, still HELD).
- Judges' remaining asks (new art beyond this row):
  - The yellow and black tiger banding reads as a tiger or wasp, not a fennec.
  - No visible storm trait (glowing eyes or arcs).
  - Long craned neck, small head.
  - The hit react drops the head to knee height.
  - The defect is still PRESENT for most judges: thin upper legs over darker "boot" lower legs.
- Next idea: thicken the upper legs too. Their skin sits above the 0.50 m hip cut, so raise HIP to about 0.62 with a wider fade. Separately, an eye and arc emission for the storm trait (coat flag).
