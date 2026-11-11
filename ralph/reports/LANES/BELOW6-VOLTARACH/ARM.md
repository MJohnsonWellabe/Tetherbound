STATUS: ready for GPU (High first)
ROW: F36#86 Voltarach poses (5.11 on 8 Nov)
BRANCH: tb/below6 (needs the branch: new textures, import once)
OVERLAY: ralph/reports/LANES/BELOW6-VOLTARACH/overlay.json
FRAMES: CAPTURE.json (capture_f36_poses.gd --species=voltarach --whole-body --context, base and arm)

# ARM: Voltarach, charcoal shell with thin gold cracks (LANE-REMAKES, 11 Nov)

## What the 5.11 measured
- The 8 Nov re-score was taken on the 1 Nov remake. The owner switched that remake off on 9 Nov ("Use the real spider"), so main now ships the native eight-leg spider.
- The native spider carried the same defect on 24 Oct (6.87, "chrome-gold statue shader; face lost") and 5.32 in ST-storm-arcs ("gold floods the body as blotches"). The base capture here re-baselines it on the current stage.

## Cause
- The gold is painted into the albedo: 20% of texels are saturated gold, in wide fields and halos. The maps are already matte (metallic 0, roughness mean 0.67), which is why the matte-only arm CO-F36-7 changed nothing.

## The arm (`creature_coat_flags.json remakes_floor_voltarach`, OFF)
- Albedo `creature_voltarach_native_Image_0_floor1.png`: wide bright gold fields and the dim gold halo go to dark bronze; only thin crack cores stay gold; the charcoal lifts a step; the blue eyes brighten.
- Emission `..._floor1_glow.png` at energy 1.8: the blue eyes plus the thin cracks at 0.45 (the one storm trait: glowing eyes and lines).
- Roughness 0.82 constant, specular 0.35.
- Board check: `reference/front.png` and `native-standing-v1.png` show a charcoal shell, thin gold cracks and blue eyes. Reserved-red texels fall 4.4% to 1.4%.
- Script: `tools/art_pipeline/grade_remakes_floor.py voltarach`.

## CPU check (`_sheet_cpu.jpg`: base left, arm right; standing and faint 050)
- The shell reads charcoal with a crack network and the abdomen plates separate. The leading leg edges still carry a gold line.
- The face is still small at this camera: the eyes are brighter but the head is a small part of a wide body. Low/Compatibility shows no glow, so the eye and crack emission can only be judged on GPU.
- No CPU judge batch was run.

## Expected
- More than 0.5 over the native base on the gold-statue defect. The face defect may only move to PARTIAL.
- If it fails: the next step is the leg gold (the crescent edges) or a Meshy pass, which is LANE-MESHY's.

## Checks
- Tests `--only=creature_coat_flags,texture_import_policy,remake_owner1101_finish,creature_clip,creature_model_flags`: 17 tests, 0 failed.
