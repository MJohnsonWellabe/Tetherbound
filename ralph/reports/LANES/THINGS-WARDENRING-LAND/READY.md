# THINGS-WARDENRING-LAND: fainter boundary ring in the Warden's arena

STATUS: land

- **Branch:** `tb/things-wardenring-land`, cut from `origin/main` fe19404d.
- **Verdict (LANE-SCOUT):** `G-things-wardenring-f41-13-closeout.md` (`tb/item-scout-1108` 7d2ccb33). No set loses.

  | Set | Base | Arm | Judges |
  |---|---|---|---|
  | F38#28 Medium job frames | 7.05 | **7.52** | 3/3, defect FIXED |
  | Other Warden frames, High | 5.80 | 6.03 | 3/3 |
  | F38#28 High job frames | 7.05 | 7.05 | identical |

- **F38#28 does not close:** High reads 7.05 in this batch (the panel ran about 0.3 strict).
- **What ships:** `data/config/combat.json arena.boundary_per_trainer_candidate` ON with `_why_on`. In the Warden's fight only, the ring goes 0.3 to 0.12 alpha and 0.8 m to 0.45 m; radius and every other fight unchanged. Config only.
- **Tests:** `tests/test_combat_arena_boundary_candidate.gd` updated: ships ON with the verdict cited, OFF still changes nothing, the shipped ring is softer for the Warden only (3 tests).
- **Tests run on this branch:** every `test_combat_arena*.gd` plus `test_stronghold_warden_arena.gd`: 10 tests, 59 assertions, 0 failed. No other test reads the boundary keys (grepped).
- No `.uid` files are included.

## Still named by the judges (both sides, 3/3)
- `warden_aldis-r10` is near-black: the fight camera is inside or behind geometry. A camera fault; next on my list.
- At High the band still reads as "a soft-glowing cyan ring overlay": the closing path is a fainter band at High too, or a floor-material edge.
- A teal bar in the left doorway; a single orange grade; floating heart and key icons in the win frame (2/3).
