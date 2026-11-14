# BEINGS-STORMRAVEN-WINGS: folded wings stay folded in hit and faint (F36#74)

**Status: CPU-ready, NOT queued.** Two of my arms are already waiting. Coordinator: take it when a slot frees, or fold it into the BEINGS-NECKDOWN batch if that has not started (same tool, same config file, same tree).

**Row:** F36#74 Stormraven poses, GPU High 6.37.

**Defect, quoted (G-things-t4-rescore, 3/3):** the wing or tail "stands up as a rigid flat slab" or "blade" in the hit and the faint.

## Cause, and how it was confirmed
The model is a raven with its wings **folded** (wing tips lying over the tail). Its hit and faint clips still rotate the wing bones as if the wings were open: up to 30.6 degrees at the shoulder in the hit and 33.9 in the faint (read from the GLB's clips). A folded wing swung at the shoulder leaves the body as one rigid sheet, and the two tips splay into the bell shape at the tail.

Confirmed by switching the suspect off: with the six wing joints held at their rest rotation the bell is gone in hit 050 and faint 050 (sheet). Two things ruled out first, both captured:
- skin weights (a copy with the tail freed of wing-tip weight still showed the slab);
- the tail's own pitch (plus and minus 45 degrees only tilted the slab).

`--raw-clips` gives the same frames as the game's clips, so the settle does not add the slab; the authored clips do.

## Change
- Code (flag-off, absent by default): `scripts/creatures/creature_pose_settle.gd` `faint.rest_joints` and `hit.rest_joints`. Named joints keep their rest rotation through the clip (`keep` 0 to 1 blends back toward the clip). No species row uses it on main.
- Overlay: Stormraven's hit holds the six wing joints; its faint holds the six wing joints and `tail_1`, `tail_2`. Stormraven already runs the settle (`things_faint2_scope`), so nothing else changes.

## CPU before and after
`_sheet_cpu_base_top_arm_bottom.jpg` (judges' crop; hit 000, hit 050, faint 050, faint 100).
- hit 050: base rears with a black bell hanging from the back to the floor; arm is a rearing raven with a normal tail.
- faint 050: base has a tall black fin behind the body; arm is a crouching raven, wings folded.
- faint 100: **only partly better.** A raised fan remains behind the body, lower and smaller than base. It is not the wing or tail joints, the leg splay or the tail relax (each switched off in turn, no change). Not claimed as fixed.

## By-eye line for the GPU lane
`stormraven-hit-050`: base shows a black bell between the bird's back and the floor; the arm shows no bell, only a narrow tail. `stormraven-faint-050`: no fin standing behind the body. If either is still there, hold.

## Risks and no-loss frames
- `hit-000` (standing) must be identical.
- The hit loses its small wing flare, so the hit reads as a rear-up only. If judges call the hit stiff, set `hit.per_species.stormraven.rest_joints.keep` to about 0.3.
- F41#13's Stormwood frames only change where a Stormraven is being hit or has fainted.

## Landing notes
Put the two Stormraven rows into the config with a `_why_on`, and turn `test_no_species_holds_joints_at_rest_by_default` into a pin that only Stormraven states them.
