# THINGS-BEDROOMWOOD-LAND: calmer wood in Grandpa's loft

STATUS: land

- **Branch:** `tb/things-bedroomwood-land`, cut from `origin/main` 3cf230b6.
- **Verdict (LANE-SCOUT):** `G-things-bedroomwood.md` (`tb/item-scout-1108` a32b6659), GPU High.

  | Set | Base | Arm | Judges |
  |---|---|---|---|
  | F38#19 exploration HUD | 6.64 | **7.15** | 3/3 |
  | F38#9, F38#4, F38#10 menus (no-loss) | 7.12, 6.91, 7.33 | identical | identical per judge |

- **Not closed:** High 7.15 (the panel ran about 0.5 strict; control 7.67), so no Medium this round.
- **What ships:** `data/config/building_prefabs.json prefabs.farmhouse_shell.interior_floor_material.tint` `#c9b49b` to `#7f8a92`, with `_why_tint_1113`. Config only. Grandpa's house floor, loft, stairs and ceiling. Mira's cottage floor has its own copy of the old tint and is not changed.
- **Tests:** new `tests/test_bedroom_wood_tint_landed.gd` (2 tests). No older test pinned the tint (grepped).
- **Tests run on this branch:** the new file plus every test file that reads the building prefabs, Grandpa's house or the farmhouse (28 files): 308 tests, 11885 assertions, 0 failed.
- No `.uid` files are included.

## What still holds F38#19 (3/3)
- The quest card, minimap and hint row cluster over the room on the right; the empty "+" quick slots add noise.
- One judge: a smeared ceiling wood texture.
