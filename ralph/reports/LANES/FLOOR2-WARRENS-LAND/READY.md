# FLOOR2-WARRENS-LAND: the Warrens mound wears the meadow's grass, ships ON (F38#30)

STATUS: land

- **Branch:** `tb/floor2-warrens-land`, cut from `origin/main`.
- **Verdict:** LANE-SCOUT G-floor2-warrens-meadow-match (`tb/item-scout-1108` f12fb0d9f), GPU High: F38#30 5.23 → 6.02, +0.79, 3/3 judges; F38#24 no loss.
- **What ships:** the two files as judged on `tb/floor2`, with the flag turned on.
  - `scripts/world/burrow_warrens.gd`: the hill shell shader blends the meadow's own grass sheet onto up-facing faces in world space; `_build_hill_shell_cover` stands 260 grass tufts and ferns on those faces, above the terrain and clear of the mouth, without collision.
  - `data/config/burrow_warrens.json`: `bank.hill_shell.meadow_match.enabled` true with `_why_on` citing the verdict.
- **Test added:** `tests/test_warrens_meadow_match.gd` (3 tests) pins the flag, the cited score, the tiling and blend band, and the cover's count, models and mouth clearance.
- **Tests run on this branch:** `warrens_meadow_match, warrens_hill_foundation, warrens_hill_shell_r2, warrens_shell_seat_f38_30, burrow_warrens_visual_identity, warrens_walk03_stand`: 20 tests, 205 assertions, 0 failed (the 17 existing Warrens tests plus the 3 new).
- **Not included:** any Stormwood harvest change or other `tb/floor2` candidate.
- **Row after landing:** F38#30 6.02 High. Medium not captured.

## Follow-ups from the judges (later arms, not in this landing)
- walk_02: the straight diagonal edge at the hill's base, and stretched grass on the steep face.
- route_day: the brown rectangular slab on the left hill.
- The plain white smoke column.
- The red trees at the entrance stay (owner: "I actually really like the red trees").
