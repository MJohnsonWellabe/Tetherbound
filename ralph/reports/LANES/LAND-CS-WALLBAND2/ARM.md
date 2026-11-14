# LAND-CS-WALLBAND2: the pale wall band on rims only (F40#1, with F40#8 no-loss)

Branch `tb/land-cs`. Round 2 of LANE-BELOW6's WALL-BAND. `overlay.json` turns on `cloudreach_visual.json landmass.wall_top_band_1113` and sets the new `band_depth_m` 3.0. With `band_depth_m` unset the code is round 1 exactly; the flag stays OFF in the shipped config.

## Rows and scores
- F40#1, 6.19 on the judging panel (round 1 gave +0.32, 3/3, G-below6-wall-band-main).
- F40#8 no-loss, 6.29: round 1 lost there, 6.29 -> 5.86 (0/3, G-lcs-wallband-bridge), so the verdict was amended to DO NOT SHIP and the flag came out of PR #963.

## Defect, as the judges put it
- F40#1 (round 1 arm, 3/3): the brown disc rim became "a pale grey-beige stone ledge band".
- F40#8 (round 1 arm, 3/3): "the big cliff right of the bridge becomes a pale grey mass with sharp faceted brown patches ... a mis-mapped material". Ask: "limit the wall-top band to rim and wall-top geometry (by height band or by a slope and normal mask), so it never repaints whole cliff faces".

## Cause, and how I know
The band is the mesa's first wall band, from the rim (`top_ring`) down to `upper_ring`, which sits a quarter of the mass height below it (`top_point.y - size.y * 0.26`). On a 72 m landmark ledge that is about 19 m; on a region cliff mass it is the whole visible face. At the Realm Gate the camera sees only the strip under the lip, which is why the same band gained there and lost at the bridge. The CPU round 1 capture reproduces the bridge defect: the big cliff right of the bridge turns pale grey.

## Change
`cloudreach_world.gd` (band emission): when `band_depth_m` is set, each side's first wall face is split at that depth below the rim. The pale band covers only the strip above the split, with no relief; the face below keeps the ordinary cliff material with the shipped relief. Relief is zero at both split edges (`relief * sin(PI * v)`), so the two pieces meet without a crack. No collision change (the collider comes from the crown).

## CPU before and after
`_sheet_cpu_base_r1_r2.jpg`:
- Top row, Three Bells bridge close: base, round 1 (the cliff right of the bridge turns pale grey, the judged loss), round 2 (the cliff keeps its rock; only a thin pale lip along its top).
- Bottom row, Realm Gate approach (F40#1's changed frame): base (brown earth band under the lip) and round 2 (pale stone band, as round 1).
`phase2_capture_locations.gd --biome=cloudreach --subset=realm_gate_crag --subset=three_bells_bridge --times=day --views=approach,close --seed=2042`, Compatibility. Round 1 was stopped before its landmark gate frames, so the gate is shown base and round 2 only.

## By-eye line for the GPU lane
- Three Bells bridge close (F40#8): the large cliff right of the bridge keeps its brown rock, as on base; at most a thin pale lip on top. Hold if it turns pale grey.
- Realm Gate approach (F40#1): the band under the turf lip is pale stone, as round 1.

## Combined re-judge
The coordinator and LANE-JUDGE ask for a combined read with GATE-TERRACE. Round 2 of the terraces (taller risers, no loops) is not built yet. `overlay_with_terrace_r1.json` stacks this arm on the round 1 terraces if a combined read is wanted now; otherwise judge this arm alone with the bridge as no-loss.

## Tests
`tests/test_wall_band_depth.gd` (shipped config: band OFF and unsplit; the split lives in the band emission), with `test_cloudreach_wall_top_band_flag`, `test_cloudreach_environment`, `test_vis_cloudreach_landed`: 21 tests, 0 failed.
