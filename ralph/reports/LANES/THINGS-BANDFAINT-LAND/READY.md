# THINGS-BANDFAINT-LAND: Duskhush and Ribbonray faint onto the ground

STATUS: land

- **Branch:** `tb/things-bandfaint-land`, cut from `origin/main` a5787c0a.
- **Verdict (LANE-SCOUT):** `G-things-bandfaint.md` (`tb/item-scout-1108` 138a0c1f), GPU High. The arm split by species; only the winners are here.

  | Row | Base | Arm | Judges |
  |---|---|---|---|
  | F36#44 Duskhush | 6.59 | **7.09** | 3/3 |
  | F36#61 Ribbonray | 6.55 | **7.09** | 3/3 |

- **Dropped, as judged:** Trailpup (−0.69) and Voltwig (−0.23), 0/3 each: the faint mid read as a running leap. Neither is in the scope; the test pins that.
- **What ships:** `data/config/creature_pose_settle.json` only: `things_band_scope` ON with `_why_on`, species duskhush and ribbonray. No code, no texture.
- **Tests:** `tests/test_things_faint_ground.gd` gains `test_band_scope_ships_duskhush_and_ribbonray_only`; the pinned scope list in `tests/test_cause_poses_settle.gd` gains the two species.
- **Tests run on this branch:** `things_faint_ground`, `cause_poses_settle`, `rest_faint_settled`: 9 tests, 91 assertions, 0 failed. `remakes_floor_landed` (Ribbonray hit blend): 4 tests, 0 failed.
- No `.uid` files are included.

## What still holds the rows (3/3)
- Duskhush faces away from the camera in the standing and hit frames, so no face shows; no rim light or element.
- Ribbonray reads as an odd upright ray on legs (new art).
