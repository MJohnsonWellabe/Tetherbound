# FLOOR2-AQUAREST-LAND: Aquaryn rests curled on the sand, ships ON (F39#6)

STATUS: land

- **Branch:** `tb/floor2-aquarest-land`, cut from `origin/main` (after #906).
- **Verdict:** LANE-SCOUT G-floor2-aquaryn-settled-rest (`tb/item-scout-1108` ee82bdaee), GPU High: F39#6 6.75 → 7.47, +0.72, 3/3 judges. 0.03 under the 7.5 bar. Medium not captured.
- **What ships:** the three files as judged on `tb/floor2`, with the two flags turned on.
  - `scripts/creatures/creature_pose_settle.gd`: a rest clip baked from the species' faint clip (legs folded, belly to the ground, head kept), `rest_only` mode that leaves the faint and hit clips alone, and an inert per-species opt-out of the faint's camera turn (no species listed).
  - `scripts/creatures/creature_body.gd`: when that rest is installed the body lies down on it instead of being rolled onto its side in its standing pose.
  - `data/config/creature_pose_settle.json`: `floor2_aquaryn_scope.enabled` and `settled_rest.enabled` true, each with `_why_on` citing the verdict; `rest_only` true; species Aquaryn only.
- **Test updated:** `tests/test_cause_poses_settle.gd` pinned scope set `["mosshell"]` → `["mosshell", "aquaryn"]` with the verdict in the comment, plus four assertions pinning `settled_rest` (on, rest only, Aquaryn, cited score). A shipped-state update, as the coordinator directed.
- **Tests run on this branch:** `cause_poses_settle, creature_rest_pose, rest_faint_settled, aquaryn_faint_headdown_flag, fainting`: 32 tests, 595 assertions, 0 failed.
- **Not included:** any other `tb/floor2` candidate (harvest grounding, bow wake, Stormheart bolt).

## Next for the row (a close-out arm, not in this landing)
All three judges: a grounded faint. Legs slack or folded instead of stiff in the air, body weight on the sand (two judges see it hovering over its shadow), and a contact shadow.
