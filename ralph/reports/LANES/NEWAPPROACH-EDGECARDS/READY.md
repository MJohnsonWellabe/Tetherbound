STATUS: land
BRANCH: tb/newapproach-edgecards-land (cut from origin/main 5b0f2c92)

# F40#11 terrace edge clouds — READY (island mist as cumulus cards)

**Verdict:** GPU High, `G-newapproach-edge-cards` (tb/item-scout-1108 0a154f5d7): F40#11 5.26 -> 5.99 mapped, +0.73, 3/3 prefer; defect PARTIAL 3/3. The row is still just under 6.

**Files (4):**
- `scripts/world/cloudreach_world.gd`
- `data/config/cloudreach_visual.json`
- `tests/test_edge_cards_landed.gd` (new)
- `ralph/reports/LANES/NEWAPPROACH-EDGECARDS/READY.md`

**What ships:**
- `cloudreach_world.gd`: main's copy plus only the `cumulus_cards` path (44 lines added, 2 changed, in the two places that read `island_roots.mist_style`). None of the lane's other flag-off code in that file is included.
- `cloudreach_visual.json island_roots.mist_style`: `volume_bank` -> `cumulus_cards`, with `_mist_style_why_on` citing the verdict. The card keys (`mist_cards_per_puff`, `mist_card_width_fraction`, `mist_card_tint`, `mist_card_ground_fade_m`, `mist_card_near_fade_m`) are not written; the judged values are the code defaults.

**Scope:** the style applies to every airborne island's mist in Cloudreach, not only the arrival terrace. Only the terrace frames were judged.

## Tests run (11 Nov)
One unit run, `--only=` the five files: 42 tests, 230 assertions, 0 failed.
- `test_edge_cards_landed` (new, 2 tests)
- `test_cloudreach_environment`
- `test_vis_cloudreach_landed`
- `test_cloudreach_cause`
- `test_near6_cr_judged_on`

How they were run: this branch is a sparse checkout, so the tests ran in the lane's `tb/newapproach` checkout with this branch's `cloudreach_world.gd`, `cloudreach_visual.json` and the new test copied in. The four existing test files there are the lane branch's copies. No world smoke was run.

## Gaps
- The new test has no `.uid` file; the next import creates it.
- Night, rain and Medium were not captured.
- Cards inside one bank are not sorted against each other; no judged frame shows a fault.

## Judges' follow-ups (next arm, in progress on tb/newapproach)
- The cards read lavender-grey and darker than the cloud floor (3/3): retint to the floor's white with sunlit tops, cool undersides and depth-faded bases.
- The faceted cloud floor is now the largest drag on the row.
