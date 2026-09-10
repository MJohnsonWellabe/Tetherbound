# Cloudreach crown-edge geology 01 — withdrawn

## Disposition

Withdraw the complete candidate. Three fresh blind comparisons at Gate Lower
Cliffs, Upper Cloudreach, and Windscar Ravine each found **no meaningful pair
preference**. Every judge answered A (belongs to the key-art world) **No**, B
(same broad kind of game as Palworld) **Yes**, and commercial visual quality
**No** for both pairs. The added rocks were safe and mechanically bounded, but
they did not materially change the broad landform, shelf, or vista composition.
This is an art-impact failure rather than a runtime or collision failure.

After withdrawal, Cloudreach returns to its prior authored crown producer. That
producer still does not place broad geological structure across these regions;
this candidate must not be described as solving that omission.

## Candidate mechanism

The production change in `scripts/world/cloudreach_world.gd` selected only Gate
Lower Cliffs, Windscar Ravine, and Upper Cloudreach. It deterministically placed
three installed nature-rock meshes per selected region (nine total) on the
eroded crown strip, applied the existing cliff material, and gave every visual
mesh a matching trimesh `StaticBody3D` collision shape. Counts, terrain, routes,
grass, scatter, materials, and densities were unchanged.

Eligibility used the actual generated crown polygon and exact crown-triangle
height rather than the smaller height-query ellipse. Full rotated bounds were
rooted 62% below that sampled surface. Candidates were rejected against ground
route widths, route landing crowns, landmark and settlement footprints, and
battle yards. Collision copied the complete local `Node3D` transform ancestry
from each installed mesh to its shape, avoiding off-tree `global_transform`
access and preserving nested imported offsets and rotations. Two small `_mesa`
expressions were extracted into shared crown-point helpers so eligibility and
rendered geometry used the same formulas.

Frozen candidate revisions before archival/restoration:

- `scripts/world/cloudreach_world.gd` — SHA-256
  `dfbc18eed4c31d90f657b708c2ef06438ed3bd6d6975e91fec4c85030589377a`
- `tests/test_cloudreach_crown_edge_geology.gd` — SHA-256
  `911bec9893a75d2f4c9d448b08dd983f659730c9735895f4f58c51e05fc8a820`
- test UID — SHA-256
  `965b044c6782bd81ac20e6a2dac003323dd7134ce7a8134b3dcc5bbb4160be51`
- `tools/probe_cloudreach_crown_edge_off.gd` — SHA-256
  `7370ea3b46baf7bc15943589f1f77ab5af881165d278f5c274efd323fbb2b169`
- probe UID — SHA-256
  `33d3a9c0ad7c4d6c995ee410ef456bf6a5d6b9b9c31a9f9180e08193615b9821`

The coordinator preserves the exact patch and held test/probe under
`.artifacts/broad-visual-0910/held-cloud-crown01/` before restoring production.

## Validation record

The geometry test evolved through five meaningful attempts; all failures remain
part of the evidence:

1. `geology-label-route-unit-first`: 10 tests / 140 assertions / 0 assertion
   failures, but non-clean because two new off-tree `get_global_transform`
   errors exposed an invalid fixture/factory assumption.
2. `geology-label-unit-second`: failed because the attempted fixture called
   `add_child` on the `RefCounted` test case.
3. `geology-label-unit-third`: failed because the synchronous test runner has
   no `SceneTree` from `Engine.get_main_loop()` during initialization.
4. `geology-label-unit-fourth`: one exact `Transform3D` equality assertion
   failed on insignificant floating-point composition differences despite
   identical printed transforms. The comparison was correctly changed to
   `is_equal_approx`.
5. `geology-label-unit-fifth`, 07:10:38–07:10:43: clean, 5 tests / 119
   assertions. The existing label test contributed 1 test / 6 assertions; the
   four crown-geometry tests contributed 4 tests / 113 assertions. They covered
   three regions with three supported specs each, deterministic route and
   landmark exclusions, visual-to-collision coverage, and a nested translated
   and rotated import transform chain.

Native candidate capture `shots/catalogue/cloudreach/broad-crown-edge01/` ran
07:12:20–07:14:24 and completed clean with 6 frames. Matched visual-OFF control
`shots/catalogue/cloudreach/broad-crown-edge01-off/` ran
07:14:40–07:16:48 and completed clean with 6 frames. The control hid only the
three `CrownEdgeGeology` visual parents; matching collision remained enabled and
identical in both sets.

Blind verdicts:

- `JUDGE-CLOUD-CROWN-GATE01.md`: no meaningful preference; the extra cropped
  rock at the extreme edge did not improve geology or composition.
- `JUDGE-CLOUD-CROWN-UPPER01.md`: no meaningful preference; landform silhouette,
  empty shelf, and repeated cliff language remained effectively unchanged.
- `JUDGE-CLOUD-CROWN-WINDSCAR01.md`: no meaningful preference; the dominant
  pillar, grass, cliffs, and framing remained materially the same.

## Limits and future rule

The captures prove clean mounting and static presentation at three intended
vistas. They do not prove traversal of every rock perimeter, multiplayer
behavior, performance across a full session, or broader Cloudreach coverage.
The geometry guards and collision tests establish why the candidate was safe to
render; they do not establish useful art impact.

Do not continue by adjusting these nine rocks' scale, count, or crown radius.
If revisited, use a materially different mechanism and fresh runtime/visual
evidence. This report does not create a new approval requirement; the owner's
current instruction is to defer hard subjects after repeated lack of progress.
