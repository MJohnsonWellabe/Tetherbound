# THINGS-ASHTUSK: tusks through the floor in the hit frame (F36#33 close-out)

**Row.** F36#33 Ashtusk: High 8.03, Medium 7.28. 3/3: "the tusks clip into the floor in the hit frame". Pair with THINGS-EMBERS (the thin line above the back): the row needs +0.22 at Medium and these are its two artefact defects.

**Cause.** Ashtusk's own hit clip drops the head until the tusks pass through the ground; Ashtusk was not in any settle scope, so nothing planted it.

**Change** (flag `creature_pose_settle.json things_hit_scope`, OFF; species: ashtusk). New `hit.per_species` rows (same deep-merge as the faint rows) and a `recoil.force` switch. Ashtusk's row rears the body 12 degrees nose-up through the hit and plants it on the ground line. Its `faint.per_species` row turns every faint section off, so its faint is still the game's clip.

**CPU** (`_sheet_hit_off_vs_on_cpu.jpg`; top main, bottom arm; hit 025, hit 050, faint 100): the tusks are above the floor with the forelegs lifted in a flinch; hind feet planted; faint identical.

**Tests.** `tests/test_things_hit_per_species.gd` (3), with the existing settle tests: 11 tests, 0 failed.

**Ask.** Ashtusk, `capture_f36_poses.gd --whole-body --context --roles=hit,faint`, base vs arm with BOTH overlays (this one and `THINGS-EMBERS/overlay_aspect_billboard.json`), High then Medium. One session can serve both arms.
