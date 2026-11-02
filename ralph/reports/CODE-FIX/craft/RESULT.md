# P2-095: craft panel item icons

**Branch:** `tb/world-craft-icons`, built from main 902671a0 with `tb/craft-r3` merged in, so the `readable_r3` changes are kept.

**Flag:** `craft_presentation.json` → `rendered_item_icons`, which ships `false`.

**What turning the flag on changes.** The recipe rows, the ingredient lines and the centre preview show icons rendered from each item's installed mesh. Ingredient icons are 40 px (`rendered_ingredient_icon_px`).

**How the icons are made.** Icons are rendered by `tools/bake_item_icons.gd` from `data/config/craft_item_icons.json` into `assets/ui/icons/items_rendered/` (30 PNGs, 192 px).
- The renderer crops each icon to the drawn object, so thin tools fill their slot.
- Meshes are the item's own `world_model`/`held_model` where one exists. Otherwise the config names an installed stand-in, tinted to the item's colour:
  - log for wood and timbers
  - rope for fibres
  - rock for stones
  - glass crystals for glass and ore
  - bag for seeds, pot for preserve, cauldron for stew, saddle for saddle parts
- No new meshes, no Meshy.
- These items keep their existing icons: ingots, the insulated helm and vest, berries, cloudberry, sparkfur, skyplume, voltcap, sunleaf, sluice metal, rod mast, thunderwood frame.

**Proof.**
- `tests/test_craft_rendered_icons.gd` covers four things: the flag ships off; with it off, every item keeps its `items.json` icon; with it on, an item shows its rendered icon where one was baked and its old icon otherwise; every configured item has a baked icon.
- That test plus the existing craft tests: 14 tests, 0 failed.
- CPU capture (`phase2_capture_build_systems.gd --biome=meadows --gamepad`, Compatibility, 1280x720) in `_sheet_craft_icons.jpg`: left is `readable_r3` only, right is `readable_r3` plus `rendered_item_icons`. The layout is unchanged and nothing clips.
