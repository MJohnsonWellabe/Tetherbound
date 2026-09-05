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

Verdict, condensed: families still read; mushrooms "unmistakable" at every
size; stroke and colour handling "convincingly" the same language (every icon
peaks at the same 0xDF channel). Defects named:

1. Stamina's concentric bullseye read as an eye at every size, and as the
   orbs' own ring ladder (Basic / Greater / Prime = 0 / 1 / 2 rings).
2. Rare's shoulder cutouts read as a medal's rim ring and 12-o'clock lug; the
   wings as laurel / a butterfly at 19 px.
3. All three candies bled to both tile edges (x0-63) with a 38 px height and
   sat low, where the existing set is inset 8-11 px per side and centred.
4. Wild's cap was 60 px wide against its siblings' 47.
5. Repeats of round 1's out-of-brief asks (leaf on Good, crown on Rare, spots
   moved from Speed to Wild, tint changes) and the hue collisions.

Acted on (round 3): 1, 2, 3, 4. Not acted on: 5, same reasons as round 1 (the
brief fixes the tier markers and tints are `items.json`'s).

### Round 3 (`_sheet_r3.png`)

Verdict, condensed: mushrooms "unambiguous" at every size, Speed "the
strongest icon in the set"; Good and Great read as wrapped sweets down to
19 px; ink coverage 37-46 % against the existing set's 38-48 %, "a clean
match"; the candy value ladder "works". In a shuffled, unlabelled sort of all
twelve 19 px thumbnails, eleven landed in the right class and **Rare Candy
filed with the Orbs**: the clearance ring cut around the sweet and the
feather split through the small wings made both read as hollow loops, so it
read as a medal with ribbon loops. Stamina's three rings smeared into one
band at 19 px; Wild's four end ticks read as chipping. Verdict: "shippable
with defects 1 and 2 [Rare's wings and twists] fixed first"; the rest polish.

Acted on (round 4): Rare's wings solid, rooted on the sweet's sides behind
the fans and flaring outward past them (the first round-4 draft rose them
off the top of the ball, which read as a cat's ears in my own check and was
not sent to the judge), no clearance ring, no interior cutout; Stamina down
to two unequal, offset rings; Wild's ticks removed (the brief names the
broad cap as its mark); Great's star enlarged.

### Round 4 (`_sheet_r4.png`)

_(filled in below)_

## CI

Run 33920949877 on `e8c4b997` (the round-3 code head; the later commits are
report-only), 2026-09-04 21:24 to 2026-09-05 00:23 UTC. Jobs relevant to this
lane:

| job | this branch | `main` @ base `ef16544f` (run 33916513195) |
|---|---|---|
| verify-unit-tests (4), the shard holding `test_item_icons.gd` | 255 tests, **1 failed: `test_scatter_perf_budget.gd::test_playground_bake_is_committed_and_fresh`** (icon tests all green) | failed |
| verify-unit-tests (3) | green | green |
| verify-unit-tests (1) | 511 tests, 1 failed: `test_terrain_bake_freshness.gd::test_playground_terrain_bake_is_committed_and_fresh` | failed on the same single test |
| verify-unit-tests (2) | green | green |
| verify-terrain-bake-freshness / verify-scatter-bake-freshness | failed | failed |
| verify-gate-b-core | failed | failed |
| verify-regions-shard (`Verify art` step) | cancelled by fail-fast before `art` ran | same |

Two things the brief did not know, both verified rather than assumed:

- **The icon failure sits in shard 4 at this base, not shard 3.** PR #39's own
  merge run (33916194315 on `90efc0d5`) is where `verify-unit-tests (3)` was
  the only red job, exactly as the brief says. The docs checkpoint `ef16544f`
  that followed it added `tests/test_capture_check.gd`, which re-sliced the
  four shards; `--shard=4/4` lists `test_item_icons.gd`'s seven methods on this
  branch and `--shard=3/4` none. On this branch shard 4 runs 255 tests and the
  only failure is the scatter bake; on `main` at the base the same shard died
  in 8 s. The icon test is green in CI on this branch.
- **Every remaining red job is inherited from `main`.** `ef16544f` also
  rewrote `data/scatter/playground/manifest.json` and
  `data/terrain/playground/manifest.json`, and both bake-freshness tests fail
  on `main` at the base and locally on this branch (which changes nothing under
  `data/` or `scripts/`, per `git diff --stat origin/main -- data/ scripts/`):

  ```
  godot --headless --path . --script tests/run_tests.gd -- --only=test_terrain_bake_freshness.gd
    3 tests, 8 assertions, 1 failed  (test_playground_terrain_bake_is_committed_and_fresh)
  godot --headless --path . --script tests/run_tests.gd -- --only=test_scatter_perf_budget.gd
    3 tests, 6 assertions, 1 failed  (test_playground_bake_is_committed_and_fresh)
  ```

  `verify-gate-b-core` is red on `main` at the base too. Not this lane's to
  fix (outside the ownership list); the coordinator should know `main` needs a
  terrain and scatter re-bake before anything lands green.

## Known limitations / deliberately not done

- The six candy/mushroom icons were the only change; `verify-unit-tests (3)` on
  `main` was red for exactly these six missing files, so nothing else in that job
  was touched.
- `items.json` was not edited (out of ownership).
- No world-model, VFX or pickup work: this lane is icons only.
