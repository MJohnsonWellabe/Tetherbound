# SCENE-WORKSHOP: the Tidewake camp workbench as a covered work station (F39#13)

Row: F39#13 camp workbench identity, GPU High 6.14 (G-rescore-stale-ext-tidewake). Recorded defect: "The craft station looks like a narrow plain wooden bench with no obvious tools or work surface cues, and in two camp views it is partly hidden by the trainer."

## Cause, and how it was confirmed

Three causes, each checked on the GPU frames (`tb/gpu-frames-1108`, `G-rescore-stale-ext-tidewake/F39-13/main/High`) and on the model itself:

1. **The tools are not on the bench.** The Blender script for `camp_workbench_r2.glb` turned each joined material group about its own origin instead of the bench centre. The hung tools, rope coil, vise, jar and lantern sit up to 1.6 m off the bench. Measured: the model is 4.61 m long and 2.36 m deep against a 2.6 m by 1.05 m top (`tests/test_camp_workbench_model_parts.gd` fails on r2). On the GPU frames these are the small dark squares floating beside the tent and the white ring left of the bench; the tool board itself is bare. **This part is fixed on the lane branch as a correctness fix (`camp_workbench_r2b.glb`, in use), not as part of this arm.**
2. **The wood is the sand's own value.** GPU salt_crown frame: tool board pixels (210,180,128) and (225,188,133); sand beside it (184,161,111) and (199,180,137). The r2 script's wood stops are 0.25 to 0.58 linear, which display as pale tan.
3. **The metal tools render black.** Steel, iron and brass were metallic 0.8 to 0.9 with nothing to reflect, so the saw blade and hammer head are flat black shapes.

## Arm

Overlay only (`overlay.json`): `meshy_camp_props.json workbench.vl_candidate.model` to `camp_workbench_r3.glb`, and `workbench.height_m` 2.6 to 3.08 (the awning's height; the bench itself keeps its size).

`camp_workbench_r3.glb` is the same procedural bench (`assets/props/vl-1103/camp_workbench/source/workbench_r3.py`, Blender 4.2.3, no Meshy, no external assets) with:
- dark stained wood for the frame and tool board, a mid-brown top;
- non-metal tool colours: pale steel saw blade, blue-grey iron, yellow brass;
- hung tools about 1.35 times larger on a 2.4 m board;
- a deep teal sailcloth awning, 3.0 m at the back, on two slim front poles. It gives the station a coloured shape above the trainer's head. No red or oxblood.

Same collider, craft prompt and offer. Only the visible mesh changes.

## CPU (Compatibility, Low)

`phase2_capture_tidewake_camps.gd --seed=2042`, the three `__crafting` frames. `_sheet_cpu.jpg`: top row base (r2b, tools back on the bench, still pale), bottom row arm.

## By-eye line for the GPU lane

On `water_camp_salt_crown__crafting`: a dark-wood bench under a teal awning, clearly darker than the sand, with a pale saw, a hammer, tongs and a rope coil on the board. No floating dark squares near the tent on either side. If the bench is still sand-coloured, or the awning is missing, hold the arm.

## Risks and no-loss frames

- The awning is new geometry over a craft station: check it does not read as a second tent (the tent is brown canvas beside it).
- `__camp` and `__bed` frames of the same three camps show the bench in the background: F39#12 and the camp row must not lose.
- The same bench model is used wherever `meshy_camp_props.apply_workbench` runs (water camps only today).
