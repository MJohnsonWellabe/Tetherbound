STATUS: ready for GPU (High first): stand override built from the GPU screen (spot a), one arm with the aged heartwood
ROW: F41#1 Stormheart finale (row 5.66, close-only 5.95 after the heartwood)
BRANCH: tb/below6 (code and config; no new asset, no import)
OVERLAY: ralph/reports/LANES/BELOW6-RAMP/overlay_approach.json (heartwood on, aged heartwood on, approach stand override on)
FRAMES: CAPTURE.json (all four F41#1 frames, base and arm)

# ARM (in preparation): the approach frames' orange slab (LANE-BELOW6, 12 Nov 2026)

## What the slab is (corrected)
Both approach frames stand at tree-local (-23, -46), beside the trunk's south split. The orange wood-grain slab at their left edge (3/3 "untextured placeholder", about 0.3 on the row) is the split's exposed inner wood: `stormheart_split_wood.gdshader` multiplies an orange trim atlas by a tint, and no tint takes it off orange.
I first took it for the entrance ramp's underside and built a ramp body. The frame did not change with it, which is how the mistake was found.

## Game fix (flag OFF, built)
`stormheart_presentation.json split_bark_finish.aged_heartwood_1112`: a `weathering` parameter on the exposed-wood shader (0 = unchanged) greys the grain to 0.75 under a pale heartwood tint (#b3a892). Shader parameter only.

## CPU check (`_sheet_cpu_base_vs_aged_heartwood.jpg`: main with heartwood left, this flag right; the `stormheart_tree` approach frame)
The slab goes from saturated orange to a muted grey-brown that sits with the lavender-grey bark. Nothing else in the frame changes.

## Also built, not part of this arm
`ramp_body_1112` (flag OFF; plank skirts, edge beam and posts for the paper-thin entrance ramp; `tests/test_stormheart_ramp_body.gd` pins the ramp's collision quad byte-identical and no collider on the body). No judged frame shows the ramp, so it earns nothing here; it would matter for a stand on the road looking at the entrance (`overlay.json` in this folder turns it on).

## The stand (flag OFF, built)
`capture_stands.json approach_overrides` (read by `phase2_capture_locations.gd approach_override_for`): the two Stormheart approach views search for their stand from (-100, 5300) along heading 0, exactly as the GPU screen's `--spot=a@-100,5300@0` did. Screen result (GPU lane, `G-stormheart-stand-screen`, 275840782): the trunk and its arched gate sit centre-frame at the end of the path between the root buttresses; the crown is cut off at the top edge. Spots b and c showed only forest.
- Not captured on CPU with the override itself (outdoor Stormwood frames take about five minutes each there); the equivalent `--spot` frame is in `BELOW6-STORMHEART-STAND/_sheet_cpu_screen.jpg` (`s300h0`).
- The aged heartwood will probably not be visible from the new stand (it faces the entrance, not the split's flank). It is still a real fix for anyone standing where the old stand stood.
- The crown is still out of frame; no ground stand shows it.

## Checks
`--only=capture_approach_overrides,stormheart_ramp_body,stormheart_split_bark`: 7 tests, 26 assertions, 0 failed (after the shader and tool changes). The full Stormheart set was last run before the aged-heartwood change (37 tests, 1 failure in my own new test's node-name pattern, since fixed).
