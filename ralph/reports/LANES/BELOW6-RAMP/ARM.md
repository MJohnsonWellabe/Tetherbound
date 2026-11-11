STATUS: prepared, NOT yet sent: waits for the GPU's stand-screening frames so the new approach stand and this game fix go as ONE arm (coordinator, 11 Nov)
ROW: F41#1 Stormheart finale (row 5.66, close-only 5.95 after the heartwood)
BRANCH: tb/below6 (code and config; no new asset, no import)
OVERLAY: ralph/reports/LANES/BELOW6-RAMP/overlay_aged_heartwood.json (`heartwood_1111` on, `split_bark_finish.aged_heartwood_1112` on)

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

## Still to do before sending
The new approach stand. The GPU lane is screening `--spot` a/b/c at (-100, 5300 / 5200 / 5100), heading 0. When those frames arrive: pick the stand, author it for the two approach views, and send one arm (stand + aged heartwood, and the ramp body if the chosen stand shows the ramp) with all four F41#1 frames.

## Checks
`--only=stormheart_ramp_body`: 2 tests, 0 failed. `--only=stormheart` before the aged-heartwood change: 37 tests, 1 failed (my own new test's node-name pattern, since fixed). The Stormheart set has not been re-run since the shader change.
