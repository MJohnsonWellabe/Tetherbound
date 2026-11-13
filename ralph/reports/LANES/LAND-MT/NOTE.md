# LANE-LAND-MT: Meadows and Tidewake world look

## TO THE COORDINATOR
- **Ready, not yet sent (my two slots are full): `LAND-MT-DUSKRIDGE`** (`ralph/reports/LANES/LAND-MT-DUSKRIDGE/`). Overlay only, two shader values. On CPU it turns the flat tan dusk mountains into a blue-grey snow-capped range (sheet in the folder). It is the clearest of my three; **if you prefer, run it in place of `LAND-MT-SHOREZONES`**, which is the weaker arm. It can share a Meadows boot with `LAND-MT-BROKENHILL`.
- Waiting: `LAND-MT-BROKENHILL` (F38#30), `LAND-MT-SHOREZONES` (F39#1, F39#15, F39#27).
- Next arm in build: Tidewake soft depth gradient (LANE-JUDGE: the hard navy edge is "in every current frame"). A flag-off candidate already exists (`tidewake_look.json` `cause_tidewake.sea`, no GPU verdict on record); CPU look next.
- F38#24 follow-up from LANE-JUDGE (6.59 on main): re-aim Warrens walk_02 / walk_03 at the mountains. Those two frames are also F38#30's frames (the hillside), so re-aiming them trades one row's subject for the other's. Your call: I would rather add a mountain-facing stand for F38#24 than turn F38#30's frames away from the hill.
- Venn fight dark mass: located (the Veilfall wall behind the arena), surface not yet named. Section below.

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
1. Tidewake soft depth gradient: CPU look at `--tidewake-cause=sea`, then tune the shoal rings to be irregular.
2. Venn fight dark mass: name the surface with a camera ray, then fix.
3. F38#24: second hazier range layer behind the ridge (LANE-JUDGE ask).
4. Shore props (driftwood, rock clusters, grass groves) if SHOREZONES gains.

## Runbook
TECHNICAL §8.1. First import in this container: about 45 min.
- CPU arm look: flip the flag in the working tree only, capture, `git checkout` the config. Commit the flag-off version.
- Tidewake's capture biome id is `water`, and frame ids start `water__`.
- A probe edit by `sed` must be checked before the capture (`git diff --stat`, or a headless print of the resolved value): two probes here shot an unchanged tree.
- Tidewake islands rise to 18 to 29 m and stands sit near 18 m; height-keyed shore bands under about 5 m are a hairline from them.
- A `var` declared inside an `if` block is not visible after it; `--check-only` on the script catches it before a 20-minute capture.
