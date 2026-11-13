# THINGS-BANDFAINT: grounded faints for four 6.5–7.0 pose rows

**Rows.** F36#44 Duskhush (6.53), F36#61 Ribbonray (6.90), F36#83 Trailpup (6.53), F36#87 Voltwig (6.78). Judges, 3/3 each: Duskhush "crumpled feather heap, no head"; Ribbonray's sail stands up while the body goes down; Trailpup "belly-up, legs in the air, reads as dead"; Voltwig "belly-up lumpy green log".

**Change** (`creature_pose_settle.json things_band_scope`, OFF): the standard settle already on main for other species now runs for these four. No new code and no per-species tuning.
- Duskhush and Ribbonray collapse onto the ground: the owl lies as a low body instead of a heap, and the ray's sail comes down flat.
- Trailpup and Voltwig roll to a side-lie with the back toward the camera. This is the side-lie, not the forced crumple that lost in FAINT2 ("cowering").

**CPU** (`_sheet_band_faint_cpu.jpg`; columns: main faint 050, arm faint 050, main faint 100, arm faint 100). All four ends change as described. Hit frames are unchanged.

**Risks I can see on CPU.**
- Trailpup's arm end may read as a flat pelt seen from the back (judges said that of Stormtrail). If it loses, Trailpup and Voltwig are parked for good on settle changes and need an authored clip.
- Duskhush's head is still hard to find at the end.

**Tried and left out (CPU).**
- Glimmermoth and Tempestwing: the wings stay up or splay (the remake rigs have no wing bones). Worse than main.
- Voltarach: the collapse pushes a leg through the floor, also with a shallower drop.
- Water Cragclaw and Water Mosshell: no visible change.

**Ask.** The four species, `capture_f36_poses.gd --whole-body --context --roles=hit,faint`, base vs arm, High. Ship per species.
