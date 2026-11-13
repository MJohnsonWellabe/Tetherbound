STATUS: prepared, queue after BELOW6-VOLTARACH returns
ROW: F36#61 Ribbonray poses (5.68 on 8 Nov)
BRANCH: tb/below6 (needs the branch: new texture, import once)
OVERLAY: ralph/reports/LANES/BELOW6-RIBBONRAY/overlay.json (coat flag plus hit clip flag)
FRAMES: CAPTURE.json (capture_f36_poses.gd --species=ribbonray --whole-body --context, base and arm)

# ARM: Ribbonray, ocean-navy ray with an attached tail (LANE-REMAKES, 11 Nov)

## Cause
- **Colour:** the remake's albedo is magenta and mauve over the whole body. Its board (`reference/front.png`, `side.png`) is a blue-headed ray with blue-violet wings and a cream underside, so blue is the species colour and the magenta is the remake's drift.
- **Detached tail tip:** not a skinning fault. Every tail vertex is weighted to `tail_1`/`tail_2` and none to a leg or the root. The hit clip pitches the body upright, the tail swings under the stage floor, and only the curled tip comes back up (base hit 025/050).

## The arm (both OFF)
- `creature_coat_flags.json remakes_floor_ribbonray`: albedo `..._Image_0_floor1.png` (magenta and mauve, hue 262 to 352, turn to ocean blue: dark scale texels deep navy, pale texels soft blue-lilac; the cyan eyes keep their pixels), roughness 0.85, specular 0.3. Script: `tools/art_pipeline/grade_remakes_floor.py ribbonray`.
- `creature_clip_flags.json remakes_floor_ribbonray_hit`: hit rotation x0.4, position x0.5.

## CPU check (`_sheet_cpu.jpg`: base left, arm right; standing and hit 050)
- The body reads navy with pale blue scale spots; no magenta is left.
- In hit 050 the tail is one piece, above the floor, and the body keeps a low stance instead of standing bolt upright.
- No CPU judge batch was run.

## Not fixed by this arm
- Judges also call the anatomy "an unclear upright ray-lizard". That is the mesh (a two-legged bird rig with wing bones); a material cannot change it. If the row stays under 6 after this arm, it needs a Meshy remake as a flat manta (LANE-MESHY).
- Faint frames are untouched (LANE-FLOOR2 owns faint grounding).

## Expected
- More than 0.5: the magenta defect was the top call 3/3 and the hit defect is removed.

## Checks
- Tests as in REMAKES-VOLTARACH: 17 tests, 0 failed.
