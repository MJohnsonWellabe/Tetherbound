STATUS: land
BRANCH: tb/newapproach-cloudsea-land (cut from origin/main c93b5600)

# F40#11 and F40#6 soft cloud sea — READY (floor only, no card shading)

**Verdict:** GPU High, `G-newapproach-cloud-sea-only` (tb/item-scout-1108 0d66a3a88):
- F40#11 6.17 -> 6.97 mapped, +0.80, 3/3 prefer.
- F40#6 5.61 -> 6.33 mapped, +0.72, 3/3 prefer. This takes F40#6 above 6.

**Files (6):**
- `scripts/world/cloudreach_world.gd`
- `shaders/cloudreach_cloud_sea_soft.gdshader`
- `shaders/cloudreach_cloud_sea_soft.gdshader.uid`
- `data/config/cloudreach_visual.json`
- `tests/test_cloud_sea_landed.gd` (new)
- `ralph/reports/LANES/NEWAPPROACH-CLOUDSEA/READY.md`

**What ships:**
- `cloudreach_world.gd`: main's copy plus the `cloud_sea.soft_sea` block only (25 lines added, none changed).
- The sea shader exactly as judged (`tb/newapproach` 2078f6442). Later edits to it on the lane branch are not included.
- `cloudreach_visual.json cloud_sea.soft_sea`: `enabled` true with `_why` and `_why_on`. Colours and scale are not written; the judged values are the code and shader defaults.

**Not in this landing:** `shaders/cloudreach_cloud_card.gdshader` and `island_roots.mist_card_shading`. The card colour failed its GPU pre-check (blue) and is being fixed on `tb/newapproach`.

**Why it works:** on the judging GPU the deck shader's `fract(sin())` noise hash draws the floor as flat rectangular patches. The sea material hashes the lattice cell with integers. `cloudreach_cloud_deck.gdshader` itself is not changed; the sheets simply stop using it while `soft_sea` is on.

## Frame 27 ribbon sheets: on base too, so not from this change
Looked at full size, `tb/gpu-frames-1108` fe749ec0a, `G-newapproach-cloud-sea-only` base and softsea, `phase2_27_terrace_road_back_13.5s`:
- The straight-edged translucent bands around the rider are on both sides, with the same shapes in the same places. They were also there in the 11 Nov morning captures (`G-newapproach-cloud-plane` base).
- They are not the deck sheets' surface: the floor under them changed from grey facets to white and blue billows, and the bands kept their shape and their warm grey-beige colour.
- That colour is the colour of the distant billow banks in the same frame. My reading is that they are the `CloudBillows` volume banks (`_add_cloud_billows`, `cloudreach_cloud_volume.gdshader`) seen from close by: each bank is a density marched in 24 steps inside a box up to 840 m across, and near the camera the step pattern follows the box's edges and corners.
- This is a reading, not a proof. One GPU frame 27 with `CloudBillows` hidden would settle it. The first edge-cards probe on CPU (hide one layer at a time) confirmed only that the lens-shaped banks at the pillar feet are that node.

## Tests run (11 Nov, with the landing files)
One unit run, `--only=` the seven files: 52 tests, 260 assertions, 0 failed.
- `test_cloud_sea_landed` (new, 2 tests)
- `test_edge_cards_landed`
- `test_cloudreach_environment`
- `test_vis_cloudreach_landed`
- `test_cloudreach_cause`
- `test_near6_cr_judged_on`
- `test_cloudreach_rain_storm_sky`

`tests/smoke_cloudreach_fall_recovery.gd`, headless, on its own: exit 0.

How they were run: this branch is a sparse checkout, so the tests ran in the lane's `tb/newapproach` checkout with this branch's `cloudreach_world.gd`, `cloudreach_visual.json`, sea shader and the two landed-value tests copied in. The other five test files there are the lane branch's copies.

## Gaps
- The new test has no `.uid` file; the next import creates it.
- Night, rain and Medium were not captured. The rain-sky unit test passes.
- The pattern does not move.

## Judges' follow-ups
- F40#11: the edge cards are still lavender clumps on the cliff foot (3/3). The card colour fix is the close-out.
- F40#6: the deer keeps its riding pose out over the cloud floor with nothing under it (3/3). That is the `refuse_drop` question held for the owner.
