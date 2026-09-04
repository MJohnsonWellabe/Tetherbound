# Lane W00-ICONS — the six missing item icons that keep `main` red

Branch: `ralph/W00-ICONS-0904`. Model tier: creating art.

**Why.** PR #39 (`05e57a09`) added six items to `data/items/items.json` — `good_candy`, `great_candy`, `rare_candy`, `speed_mushroom`, `stamina_mushroom`, `wild_mushroom` — whose `icon` fields name PNGs that do not exist. `verify-unit-tests (3)` fails on `tests/test_item_icons.gd` (`test_every_item_has_an_icon_field_whose_file_exists`, `test_every_item_icon_loads_as_a_texture`). Every other lane branches from this red `main`; you are the fix.

**Owns:** `tools/gen_item_icons.py`, the six new PNGs (and their `.import` files, produced by `godot --headless --path . --import`) under `assets/ui/icons/items/`. Nothing else. Do not edit `items.json`.

**Do.** Read `tools/gen_item_icons.py` end to end — it is the icon language (white silhouette + cutout strokes, 64 px from a 256 px supersample, tinted per `items.json` `colour`). Add six drawing functions in that language and register them the way the existing ones are registered. Design intent: the candy family is one silhouette (a wrapped sweet, matching the installed `assets/props/candy_pickup/candy_pickup.glb` — look at `docs/art/reference/17_Candy_Revive_Potion_Mushroom_Pickups.png`) whose three tiers read as a value hierarchy at 64 px: Good = plain, Great = a medallion/star cutout, Rare = the same plus two small wings. The mushroom family is one cap-and-stem silhouette whose three tiers differ by cutout pattern (dots for Speed, rings for Stamina, a broader cap for Wild) and by tint from `items.json`. Regenerate ONLY the six new files (do not re-render the existing icon set unless the script cannot be run per-icon — if it regenerates everything, verify with `git diff --stat` that existing PNGs are byte-identical or revert them). Run `python3 -c "import PIL"` first; `pip install pillow` if missing.

**Verify.** Install Godot, `--import`, then `godot --headless --path . --script tests/run_tests.gd -- --only=test_item_icons.gd` must pass; also `--only=test_items_data.gd` if it exists, and `tests/smoke_art.gd`. Look at the six PNGs yourself (Read the files) and at 30 % size: the three candy tiers must be tellable apart. Commit the PNGs, their `.import` files, and the script.

**Acceptance.** `test_item_icons.gd` green on your branch, first attempt; six icons that read as two families with a three-step hierarchy each. Report at `ralph/reports/W00-ICONS-0904/REPORT.md`. This lane is small; finish inside an hour.
