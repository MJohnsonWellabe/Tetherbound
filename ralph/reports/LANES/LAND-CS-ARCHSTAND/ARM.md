# LAND-CS-ARCHSTAND: frame the broken skyroad arch itself (F40#3)

Branch `tb/land-cs`. `capture_stands.json approach_overrides.candidates_1113`, OFF on the branch; `overlay.json` turns it on. Capture tooling only (the coordinator's stand rule: a stand that cannot show its subject may be moved, and the frame is re-baselined, as for the Stormheart, the observatory and the beacon).

## Row and score
F40#3 Cloudreach landmark read, 6.33 GPU High (G-below6-f40-3-landmarks).

## Defect, as the judges put it (3/3)
"The skyroad arch frame shows no landmark. On both sides it is an empty field between two blocky stacked-slab cliff faces. This one frame keeps the recorded defect PARTIAL at best." Recommendation in that verdict: "stage the skyroad arch frame on its actual arch: a stand change".

## Cause, and how I know
- The two "cliff faces" are the arch's own legs. A probe in the capture prints the camera and the arch node: the camera is 13 m from the arch, which sits at screen centre, so the frame looks between the legs with the span above the top edge.
- The tool falls back to that 8 m stand because every farther one fails travel: a ground probe round the arch finds turf to 10 m on every heading, to 15 m only to the south (headings 120 to 240), and void beyond. The island is about 15 m across.
- The band frame `broken_causeways__04__broken_skyroad_arch` gets no stand at all ("no supported production-camera stand among 27 candidates").

## Change
`candidates_1113` gives both arch identities a stand that searches from the arch centre toward the south rim, facing north. The tool picks its 16 m candidate, on the rim, with the camera about 21 m from the arch. Both frames capture; the band frame captures for the first time.

## CPU before and after
`_sheet_cpu_base_vs_arm.jpg`: base (8 m north stand, two leg walls) and arm (16 m south stand, the arch with its span and both legs, and the pale stacks behind it). `phase2_capture_locations.gd --biome=cloudreach --subset=broken_skyroad_arch --times=day --views=approach --seed=2042`, Compatibility.

## By-eye line for the GPU lane
Skyroad arch approach (landmark frame and broken_causeways 04): the stone arch, its span and both legs, is in frame behind the trainer. Hold if the frame still shows only two walls.

## Risks
- The top of the span is close to the frame edge.
- The south rim is the island's drum edge; the island's flat lawn is still the island ("a cylinder dropped on the ground" is a separate ground ask).
- No game change: no player, world or collision effect.

## Tests
`tests/test_arch_stand_candidate.gd` (OFF resolves nothing; ON resolves both identities to the arch centre, heading 0), with the stand-override tests: 9 tests, 0 failed; `test_capture_approach_overrides.gd` also passes.
