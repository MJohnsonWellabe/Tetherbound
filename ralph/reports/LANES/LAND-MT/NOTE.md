# LANE-LAND-MT: Meadows and Tidewake world look

## TO THE COORDINATOR
- **Ready: `LAND-MT-CRAGBACK`** (`ralph/reports/LANES/LAND-MT-CRAGBACK/`), the Venn dark-mass fix for F39#19 (7.47) and F39#7. **Cause confirmed by probe:** the black wedge is the inner side (back faces) of the Veilfall crag shells, which the `cull_disabled` crag shader lit with the outer normal. The overlay lights back faces as rock facing the viewer. CPU: the corner goes from near-black (2, 18, 26) to grey rock (107, 125, 108). One shader value; ships 0. It can go in the same boot as LANE-SCENE's ROSTERNAMES if you want both on F39#19 at once.
- **Reply to your 13 Nov list (newest first):**
  - **(2) Swim foam: `LAND-MT-VWAKE` built** (`ralph/reports/LANES/LAND-MT-VWAKE/`, code and pin test pushed, flag-off; CPU look still to do). Cause: every trailing foam ring is a full disc (lip plus churn) that spreads to 2.3x, so twelve overlap into blobs and a slab. ON turns each trailing ring to the swim direction and keeps only its two side arcs, so the trail draws a V; the ring at the body is unchanged. It stacks on SEADEPTH (different files). The trailing boots are a pose fix, outside this lane.
  - **(2) Irregular shoal rings:** next after the VWAKE CPU look.
  - **(3) F38#8 is not a world row:** it is the trainer's grip pose under Galecrest in flight ("hangs rigidly upright with raised straight arms"). That is a character pose (LANE-THINGS/creature-pose scope), so I am leaving it unless you reassign it.
  - **(4) F39#31 has no job.json frames of its own.** Its 6.02 comes from the two Veilfall rain frames, where it rode along as a no-loss check (G-floor2-dawn-haze-storm-grade). Its brief is "Veilfall reads at distance and up close". A cheap step: give it a frame set (a clear-day distance view plus a close view) and re-score; F39#2 reads 6.79 on day frames of the same mountain. The judges' real ask is new art (terraced mossy cliff, layered falls, mist at the base). Without Meshy, the in-reach piece is mist at the fall's base from the existing spray; I can build that after the Venn fix.
- **Ready: `LAND-MT-SEADEPTH`** (`ralph/reports/LANES/LAND-MT-SEADEPTH/`). The soft depth gradient, overlay only, no new code: it switches on an existing flag-off sea candidate that has no GPU verdict on record. CPU sheet shows the navy band gone in all three frames. It touches every Tidewake water row, so it needs the current-state frames and F39#10 as no-loss. **It can share one Tidewake boot with `LAND-MT-SHOREZONES`** (both are `tidewake_look.json` overlays on different keys); I would run SEADEPTH first.
- Queued (per your message): `LAND-MT-BROKENHILL`, `LAND-MT-DUSKRIDGE`, then `LAND-MT-SHOREZONES`. With SEADEPTH that is more than two waiting; I stop adding arms now and work on the Venn surface and the F38#24 stand.
- **Venn fight dark mass: SURFACE NAMED.** It is the Veilfall crag kitbash (`WaterVeilfall/VeilfallCragKitbash`: Crag_boulder_1..3 / CragCore, 700 to 1,100 m meshes, no collider, shader `cull_disabled`), drawn in its wet colour. Proof: with the look profile's crag override (`tidewake_look.json` `veilfall_family_candidate.crag_kitbash.crag_shader`) painted, the corner turned the wet colour (magenta) and nothing else changed. My earlier crag probe edited `water_veilfall_crag_kitbash.json`, which that override replaces, so it showed nothing. One last probe is running: back faces (the shader does not flip normals on back faces) versus front-face wet rock. **It is a world-surface fix, so LAND-MT takes it; LANE-SCENE can keep the roster side of F39#19.**
- GPU confirmation of #952 (LANE-JUDGE, G-rescore-f38-24-after-952): stronghold route_day shot right after a dusk frame kept its day haze. F38#24 6.59 on main.
- **F38#24 mountain stand: a re-aim at the Warrens does not make the mountains the subject. No stand entry added yet.** Heading sweep on CPU at the reviewed open-ground stand (-318, 2642), six headings (131, 181, 206, 256, 281, 306): the hill leaves the frame below about 181, but the range is a thin strip on the horizon in every direction and trees cover most of it. The mountains are small from meadow level everywhere near the Warrens; they read in the stronghold frame because that view is long and open.
  - So the lever for the two weak frames is the range's size, not the stand. Next arm for this row, after DUSKRIDGE's verdict (same config file): a taller ridge (`height_scale`, overlay only) plus the second hazier layer LANE-JUDGE asked for, checked for no loss on the stronghold route_day frame (7.73).
  - If you still want a stand swap now, heading 181 at that position is the best of the six (snow caps centre-left, hill at the left edge); Warrens `walk_01` is used by no row and could carry it.

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
1. F38#24: taller ridge and a second hazier range layer (after DUSKRIDGE's verdict).
1b. Tidewake shoal rings: irregular instead of concentric (after SEADEPTH's verdict).
2. F39#31 reviewed frame set (day distance, close), then mist at the fall's base.
3. F38#24: second hazier range layer behind the ridge (LANE-JUDGE ask).
4. Shore props (driftwood, rock clusters, grass groves) if SHOREZONES gains.

## Runbook
TECHNICAL §8.1. First import in this container: about 45 min.
- CPU arm look: flip the flag in the working tree only, capture, `git checkout` the config. Commit the flag-off version.
- Tidewake's capture biome id is `water`, and frame ids start `water__`.
- A probe edit by `sed` must be checked before the capture (`git diff --stat`, or a headless print of the resolved value): two probes here shot an unchanged tree.
- Tidewake islands rise to 18 to 29 m and stands sit near 18 m; height-keyed shore bands under about 5 m are a hairline from them.
- A `var` declared inside an `if` block is not visible after it; `--check-only` on the script catches it before a 20-minute capture.
