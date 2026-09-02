# VP10 — structure_visibility_ranges: KEEP (true)

## Numbers, OFF (known baseline) vs ON (measured this run)

| view          | draws OFF | draws ON | budget | primitives OFF | primitives ON | budget    |
|---------------|-----------|----------|--------|-----------------|-----------------|-----------|
| band1_open    | 7659      | 6847     | ≤7500  | 11,757,306      | 11,718,510      | ≤12.0M    |
| hall_approach | 3844      | 3847     | ≤4000  | —               | 4,325,660       | —         |
| village_high  | 3165      | 2880     | —      | —               | 8,532,978       | —         |

band1_open dropped 812 draws, now under the 7500 proxy budget with primitives essentially flat
and under 12.0M. hall_approach ticked up 3 draws (run-to-run noise, not the mechanism — it has
no structure groups ahead of that camera per the config's own accounting) but stays well under
4000. village_high dropped 285 draws. All three decision criteria pass.

## Visual check (survey stands, ON vs WORLD/round7 baseline)

Pixel diff (WORLD/round7 frames are 960x540, upscaled to 1280x720 to compare; mean abs diff /
% px with any-channel diff > 8):

| stand               | mean abs diff | % px > 8 |
|----------------------|---------------|----------|
| 01-spawn-outward      | 7.96          | 32.2%    |
| 02-valley-floor       | 7.91          | 30.2%    |
| 03-rise-overlook      | 4.60          | 20.6%    |
| 04-three-quarter      | 8.85          | 36.8%    |
| 05-spawn-low-sun      | 8.83          | 34.9%    |

All five exceed the 10% look-closer threshold, so all five were visually inspected side by side
(round7 ref vs this run). None show a missing or newly-vanished structure: 01 keeps its fence
run, boulders, hay bales, and background tree; 02 keeps the distant village rooftops through the
trees; 03 (the farthest stand, camera looking back at the village from the ridge) still shows the
village's red roofs clearly at range; 04 keeps Grandpa's house, its fence, and the flanking trees
fully intact; 05 keeps the fence/boulder/hay-bale group at golden hour. The diff magnitude reads
as ordinary rebake noise (procedural grass/foliage placement, shadow dithering, cloud/lighting
state) plus resize-interpolation softening from the 960x540→1280x720 upscale, not as a content
change — no building/structure pops out or disappears at any stand.

A background chain also dropped an independent OFF-vs-ON contact sheet
(`survey_vis_on/_sheet_off_vs_on.png`) into this same directory using its own OFF captures —
it shows the same result: all five stands read as visually identical between OFF and ON.

## Decision: KEEP (`structure_visibility_ranges` stays `true`)

All four gates pass: band1_open ≤7500 draws, primitives ≤12.0M, hall_approach ≤4000, no
structure visibly missing at any survey stand. `tests/run_tests.gd -- --only=test_scatter_perf_budget.gd,test_grass_field.gd`
ran clean (21 tests, 87812 assertions, 0 failed) before committing.
