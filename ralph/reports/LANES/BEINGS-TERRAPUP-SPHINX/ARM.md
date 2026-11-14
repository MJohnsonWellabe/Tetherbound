# BEINGS-TERRAPUP-SPHINX: Terrapup rests lying down instead of in the faint's side-lie (F38#1)

**Status: CPU-ready, waiting for a GPU slot.**

**Row:** F38#1, Meadows Terrapup. The resting and fainted world frames read stiff, and the two are the same pose.

## Cause, and how it was confirmed
A clip probe on the live owner1101 remake (13 Nov) found that its `rest` clip is a copy of its `faint` clip. Both end with the root rolled 90 degrees onto the flank and the legs swept fore and aft. The only difference is 12 degrees at the neck (and the root sits 0.17 rig units higher). Terrapup's species rest recipe (`rest_pose`, clip_role `rest`) adds nothing on top. So the world's resting frame is the faint's stiff side-lie: the defect frame `meadows__terrapup__resting` matches `__fainted` almost exactly.

This also explains why the earlier `settled_rest` and `faint_fold` attempts did nothing for the rest. Terrapup's rest goes through the authored path, which plays the `rest` clip, not `rest_faint`.

## Change
New flag `beings_terrapup_sphinx_rest` in `data/config/creature_model_flags.json`, OFF. It replaces only Terrapup's `rest_pose` recipe and uses the existing reversible authored-rest lifecycle, so `stop_rest` restores the saved pose. The recipe:
- undoes the root roll (−90 degrees about Z);
- lays the front legs forward on the ground (upper leg 75 degrees forward, lower 10 degrees);
- folds the hind legs under (upper 60 degrees, lower 120 degrees back);
- raises the head about 10 degrees;
- lowers the root 1.55 rig units so the belly sits on the grass.

The deltas were computed on the remake's rig, from the rest clip's end to the standing pose with the limbs folded about the lateral axis. The faint, the model and every clip are unchanged. There is no code change.

`tests/test_creature_model_flags.gd` now accepts a flag that refines only a recipe (no `model` key). Such a flag keeps the installed model.

## CPU before and after
`_sheet_r1.jpg`, three rows:
1. World resting, before and arm. Before: a stiff side-lie with the legs straight out. Arm: a big dog lying on its belly, head up, front paws forward.
2. World fainted, before and arm. Identical; this is the control.
3. Neutral stage, before and arm. That tile uses a root of −1.45; the arm ships −1.55, as in the world frames.

## By-eye line for the GPU lane
`meadows__terrapup__resting`: the dog lies upright on its belly with its head up and eyes open, and it is clearly not the same pose as `__fainted`. If it still lies on its side, the overlay did not apply.

## Risks
- At −1.55 the hind end sinks slightly into the grass (the world probe's lowest vertex is 0.45 m under the contact ground, mostly the folded hind paws). A judge may call the hindquarters buried.
- The faint stays the stiff side-lie. A folded faint for Terrapup (`faint_fold`) was tried on CPU and was no better: the fold turns off face-camera, so the plated back faces the lens and the legs and head disappear. That approach is parked for Terrapup.
