# LAND-CS-OVERLOOK-SEAMS: remove the buried approach pavers at the Stormward Overlook (F40#15)

Branch `tb/land-cs`. Flag `cloudreach_stormward_overlook_visual.json paver_strips_1113`, OFF on the branch; `overlay.json` turns it on. Base is main with both overlook ships (#954).

## Row and score
F40#15, 5.60 GPU High mapped (walk_02 and walk_03, after #954).

## Defect, as the judges put it
- `G-below6-overlook-solid-c673` (3/3): the new stands show "a dark slab at the trainer's feet in walk_02" and "flat dark plank and green-top slabs in walk_03"; PARTIAL 2/3, PRESENT 1/3.
- `G-below6-overlook-join-c673`: the thin seam is gone but "the dark wedge" and plank strip remain at route_day and vista_dusk.

## Cause, and how I know
A pixel probe during the capture (a temporary hook in `phase2_capture_locations.gd`, not committed): for chosen pixels it casts the camera ray against the triangles of every visible mesh and prints the nearest hits.
- route_day and vista_dusk, every pixel on the plank strip: nearest hit `StormwardOverlookPresentation/StormwardPaver01`, 5 cm in front of the ridge turf (`SummitOverlookLoopCliffShoulders/Ridge003`).
- walk_02, the slab behind the trainer: `StormwardPaver03`.
- These are the four `approach_pavers` slabs. The ridge join (#954) lifted the turf around them to the ledge crown, so each is buried except for a sunken strip that reads as a dark plank on the grass.
- Confirmed by switching them off: the strips are gone at route_day, vista_dusk, walk_02 and walk_03 (the dark strip at upper left), and nothing else in those frames moves.

## Change
`cloudreach_stormward_overlook.gd build_pavers()`: when the flag is on, the four pavers are not built. They carried no collision (`_box` makes a mesh only), and the trail is a separate surface, so walking is unchanged.

## CPU before and after
`_sheet_cpu_base_vs_arm.jpg`: the lower part of route_day, vista_dusk, walk_02 and walk_03, base left and arm right (`phase2_capture_routes.gd --biome=cloudreach --subset=cloudreach__summit_final_stronghold__12__stormward_overlook --seed=2042`, Compatibility). Same stands and camera on both sides.

## Checked against the judged GPU frames
`tb/gpu-frames-1113` G-below6-overlook-solid-c673 solid-High: the dark rectangle by the tree at walk_02 and the dark plank strip at upper left of walk_03 are the same paver slabs the probe names; both are gone in this arm on CPU.

## By-eye line for the GPU lane
- route_day and vista_dusk: the cobbled or plank strip running down-right from the dark wedge, right of the trainer, is gone.
- walk_02: the dark slab on the grass behind the trainer, by the tree, is gone.
- walk_03: the dark plank strip on the grass at upper left is gone.
Hold the arm if any of those strips is still there.

## What this does not fix
- **The dark wedge** beside the path at route_day and vista_dusk. The probe names the overlook ledge's own body (`LandmarkLedge/StratifiedCliffBody`) a few centimetres above the ridge turf. Raising the join's lift above the crown (`sink_m` −0.12, tried in this capture) did not change it, so it is not in this overlay. My reading: the join deliberately does not lift the ridge within 4 m of the trail, so the ledge's edge stands proud there as a step. That is the next fix.
- **The walk_03 grey ramp** under the trainer is the ridge shoulder's steep flank, which the surface shader shows as rock. Not changed.

## Risks and no-loss frames
- walk_01 and the overlook's other views: the pavers were the only paving on the approach; with them gone, the approach is turf and trail.
- No-loss: the Sky Shrine and High Perches sets used for the overlook arms.

## Tests
`tests/test_overlook_paver_strips_flag.gd` (ships OFF; OFF builds the pavers; ON builds none), run with the overlook and gate-crag tests: 19 tests, 0 failed. A landing must turn `test_cloudreach_stormward_overlook.gd`'s four-paver count into zero with the flag on.
