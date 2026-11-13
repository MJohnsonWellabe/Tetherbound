# LANE-LAND-MT: Meadows and Tidewake world look

## TO THE COORDINATOR
- **New arm: `LAND-MT-SHOREZONES`** (`ralph/reports/LANES/LAND-MT-SHOREZONES/`), rows F39#1, F39#15, F39#27; overlay over flag-off code on `tb/land-mt`. Same tree and boot can also carry `LAND-MT-BROKENHILL` (different biome, so a second run).
- That makes two arms waiting (BROKENHILL, SHOREZONES); I build no further GPU arms until one returns.
- Ridge fog fix is on main (#952). Thanks for queuing the stronghold `route_day` re-shoot.
- **Venn fight dark mass (from LANE-SCENE): not solved yet; two causes ruled out.** Details under "Venn fight dark mass" below. It is not missing sky or horizon.

## State (13 Nov)
- **Tan mountain backdrop: cause found and fixed (correctness, not flagged).**
  - `horizon_ranges.gd` copied the scene fog into the ridge on a 0.5 s poll.
  - The route tool pins the hour, waits 12 physics ticks (0.2 s) and 4 drawn frames, then shoots. On a GPU that is under 0.5 s, so a day frame taken right after a golden-hour frame (stronghold `route_day` follows warrens `vista_dusk` in one boot) could keep the tan dusk haze. Which boot got it depended on the poll phase. On CPU a drawn frame takes longer than the poll, so it never showed.
  - Fix: the fog is compared every frame and copied the frame it changes. Pin test: `test_meadows_ridge_vl.gd::test_ridge_fog_follows_the_environment_without_delay`.
  - Expected board effect: F38#24's `route_day` reads 7.73 every boot (row about 6.49), with no arm needed.
- **Merged main 4f9ee396 (#951).**
- **Built, flag-off, not yet looked at:** ridge shader `warm_haze_*` (dusk vistas: "flat tan haze swallows the mountains").

## Venn fight dark mass (F39#19, F39#7), open
- CPU capture (`phase2_capture_tidewake_fights.gd --trainer=water_trainer_venn`, 40 frames): a near-black mass (RGB about 2, 18, 26) with a scalloped edge fills the top-right corner and runs down the right edge. The top of the frame is the mossy Veilfall cliff foot with a mossy log on it (the judges' "floating olive object").
- **Not sky or a missing horizon:** the fight camera looks down; no sky is in frame.
- **Not the open sea:** deep water in the same build is RGB about 0, 82, 122.
- **Not the crag kitbash rock colours:** false-colour probe with `water_veilfall_crag_kitbash.json` `body_colour` green and `wet_colour` magenta (flip confirmed by `git diff`); the mass stayed near-black.
- **It sits where the Veilfall mountain wall is.** The fight camera is at about (377, 10, 3790) looking toward (-x, +z); `water_heightfield.height_at` shows the ground in the top-right of its view (x 300 to 330, z 3800 to 3850) climbing from about 20 m to over 100 m. So the mass is the mountain's steep face or a rock formation standing against it, in shadow.
- A third probe (terrain cliff tint in `water_visual.json` set to magenta) changed nothing in frame, including the lit mossy cliff, so that key does not colour this wall; inconclusive.
- **Stopping config-flip probes here (three runs, no identification).** Next step is different: a ray from the fight camera through the top-right pixel that prints the node hit (terrain or a `PhysicalCragSupport` body), then lift that surface's shadow value or keep the fight camera off it.
- Seen on the way: `water_veilfall_silhouette.gd` copies fog on a 0.25 s poll, the same pattern as the ridge bug fixed in #952. Not yet shown to cause a bad frame.

## Waiting on the GPU
1. `LAND-MT-BROKENHILL` (F38#30): queued.
2. `LAND-MT-SHOREZONES` (F39#1, F39#15, F39#27): turf patches on the dunes. Moderate change; honest read in its ARM.md.

## Next
1. Venn fight dark mass: identify the node with a camera ray, then fix (see above).
2. Meadows dusk ridge (`warm_haze_*`, built, flag-off): CPU look on the stronghold dusk vista, then an arm once a GPU slot frees.
3. Tidewake water: the hard navy-to-cyan depth edge and rimmed shallows discs (F39#15, F13#5, F39#16).
4. Shore props (driftwood, rock clusters, grass groves) if SHOREZONES gains.

## Runbook
TECHNICAL §8.1. First import in this container: about 45 min.
- CPU arm look: flip the flag in the working tree only, capture, `git checkout` the config. Commit the flag-off version.
- Tidewake's capture biome id is `water`, and frame ids start `water__`.
- A probe edit by `sed` must be checked before the capture (`git diff --stat`, or a headless print of the resolved value): two probes here shot an unchanged tree.
- Tidewake islands rise to 18 to 29 m and stands sit near 18 m; height-keyed shore bands under about 5 m are a hairline from them.
- A `var` declared inside an `if` block is not visible after it; `--check-only` on the script catches it before a 20-minute capture.
