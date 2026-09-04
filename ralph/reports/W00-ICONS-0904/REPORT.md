# W00-ICONS-0904 — the six missing item icons

Branch: `ralph/W00-ICONS-0904` (from `origin/main` @ `ef16544f`).
Final commit: _(filled in below)_.

## Files changed

- `tools/gen_item_icons.py` — six new generators in the script's own language
  (`_candy_body` + `icon_good_candy` / `icon_great_candy` / `icon_rare_candy`;
  `_mushroom_body` + `icon_speed_mushroom` / `icon_stamina_mushroom` /
  `icon_wild_mushroom`; a `_cutout_star` helper), registered in `ITEM_ICONS`.
- `assets/ui/icons/items/{good,great,rare}_candy.png` and
  `{speed,stamina,wild}_mushroom.png` — 64 px RGBA, rendered by
  `python3 tools/gen_item_icons.py <the six filenames>` (per-icon filter, so the
  existing set was NOT re-rendered; `git diff --stat origin/main -- assets/ui/icons/`
  shows only the 12 additions).
- The six matching `.png.import` files, produced by `godot --headless --path . --import`.
- `ralph/reports/W00-ICONS-0904/REPORT.md`, `_sheet_r1.png` (this report and the
  one blind-judge contact sheet).

Not touched: `data/items/items.json`, every existing icon, anything outside the
ownership list. Godot's import run also drops untracked `*.uid` / `.import`
files for other lanes' assets; those were left uncommitted.

## What the player sees

The satchel and inventory now show an icon for the three found candies and the
three foraged mushrooms instead of a missing texture:

- **Candy family** — one wrapped-sweet silhouette (round sweet, twisted wrapper
  fan each side, matching `candy_pickup.glb` / board 17). Good = plain, green.
  Great = a star medallion cut out of the sweet, blue. Rare = the star plus two
  small wings on the shoulders, gold. Three silhouette features (ball / +star /
  +wings) give a value ladder that survives the 19 px (30 %) thumbnail.
- **Mushroom family** — one cap-and-stem silhouette. Speed = five spot cutouts
  on the cap, blue. Stamina = three ring cutouts, orange. Wild = a broader,
  flatter cap on a stouter stem with gill cutouts at the rim, red.

Tints come from each item's `colour` in `items.json` through the script's
existing tint table (each file is used by exactly one item, so the item's own
colour applies, lifted to the shared `TINT_PEAK`).

## Tests and smokes

| Command | Result |
|---|---|
| `godot --headless --path . --script tests/run_tests.gd -- --only=test_item_icons.gd` | 7 tests, 276 assertions, 0 failed (first attempt) |
| Red check: `rare_candy.png` + `.import` moved aside, same command | 2 failed, both naming `rare_candy` (`..._icon_field_whose_file_exists`, `..._icon_loads_as_a_texture`); files restored |
| `--only=test_items_data.gd` | file does not exist in `tests/`; not run |
| `godot --headless --path . --script tests/smoke_art.gd` | exit 0, `art: OK`; `grep -E '^ERROR:|SCRIPT ERROR'` on the log: 0 lines |

## Runtime validation

- `godot --headless --path . --import` twice (warm-up, then with the PNGs present);
  the six `.import` files were generated and the textures load as `Texture2D` in
  the test above.
- Inspected all six PNGs at 4x, 64 px, 32 px and 19 px on a dark tile
  (`_sheet_r1.png`, top row; bottom row is six existing icons for context).

## Blind judge (code-blind sub-agent, opus, given only the sheet, `docs/reference/`, board 17 and the visual-judge skill)

### Round 1 (`_sheet_r1.png`)

Verdict, condensed: the six read "cleanly" as two families ("a player would say
'sweet' and 'mushroom'"); all three candy tiers and the Speed/Stamina pair were
distinct at 64 px and 19 px; the flat-fill / knockout treatment matched the
existing set exactly (same 223 peak channel, no glow). Defects named:

1. Rare Candy read as "a military medal / rosette with ribbons" (straight
   diagonal wings with hairline hatching).
2. Wild Shroom's hairline rim ticks vanished below 64 px, leaving a blank cap.
3. Stamina's three small rings filled in at 19 px into blobs told from Speed's
   dots only by count.
4. Good/Great Candy were 1.93:1 letterbox bars (29.6 % / 27.9 % tile fill vs
   32-41 % for every existing icon).
5. Hue collisions: Rare gold ~ Greater Orb gold, Stamina orange ~ Prime Orb
   orange, Great Candy blue ~ Speed Shroom blue.
6. Good Candy's blank centre (suggested the board's leaf); suggested a crown
   instead of a star on Rare.

Acted on (round 2): 1, 2, 3, 4. Not acted on: 5 is fixed by the tints in
`items.json`, which this lane does not own (recorded below for the owner);
6 contradicts the brief (Good = plain, Great = star, Rare = star + wings), so
the brief's design stands.

### Round 2 (`_sheet_r2.png`)

_(filled in below)_

## CI

_(filled in below)_

## Known limitations / deliberately not done

- The six candy/mushroom icons were the only change; `verify-unit-tests (3)` on
  `main` was red for exactly these six missing files, so nothing else in that job
  was touched.
- `items.json` was not edited (out of ownership).
- No world-model, VFX or pickup work: this lane is icons only.
