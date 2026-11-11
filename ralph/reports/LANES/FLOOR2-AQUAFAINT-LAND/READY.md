# FLOOR2-AQUAFAINT-LAND: Aquaryn faints with folded legs, lying on the sand, ships ON (F39#6)

STATUS: land

- **Branch:** `tb/floor2-aquafaint-land`, cut from `origin/main` after #907 (the settled rest it builds on).
- **Verdicts (LANE-SCOUT, `tb/item-scout-1108`):**
  - High: G-floor2-aquaryn-faint-fold (9caedcf89), F39#6 **7.79**, +0.73, 3/3 judges, defect FIXED 3/3.
  - Medium: G-floor2-aquaryn-faint-fold-medium (9a3c1101f), **7.46**, +0.44, 3/3. 0.04 under the bar, so **the row does not close with this landing**.
- **What ships:**
  - `scripts/creatures/creature_pose_settle.gd` as judged (`tb/floor2` 54298c95e): `Rig.fold_limbs`, the `faint_fold` bake, and `rest_only` letting a folded faint through.
  - `data/config/creature_pose_settle.json`: `faint_fold` block added, enabled, with `_why_on` citing both verdicts. Values as judged: 50° limb swing, 60° lower-limb fold, 10% sink, Aquaryn only.
- **Test updated:** `tests/test_cause_poses_settle.gd` gains seven assertions pinning `faint_fold` (on, Aquaryn, cited score, the three judged values, and no `drop_deg`).
- **Tests run on this branch:** `cause_poses_settle, creature_rest_pose, rest_faint_settled, aquaryn_faint_headdown_flag, fainting`: 32 tests, 602 assertions, 0 failed.
- **Not included:** `faint_fold.drop_deg` (the FLOOR2-AQUAFLAT close-out arm, waiting on the GPU) and every other `tb/floor2` candidate.

## Next for the row
Medium judges: the limbs and claws are still raised above the torso. FLOOR2-AQUAFLAT lowers them; it is queued for High and Medium together.
