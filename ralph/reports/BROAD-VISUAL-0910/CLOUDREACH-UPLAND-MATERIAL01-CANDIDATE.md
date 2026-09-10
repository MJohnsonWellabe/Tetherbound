# Cloudreach upland material contract — withdrawn

## Disposition

Withdrawn after fresh blind comparison: Gate preferred the previous, quieter
ground (F01/F02), while the upper observatory found no meaningful pair
preference. Both locations remain A No / B Yes / commercial quality No.
F01/F02 are the matched control; F03/F04 are the candidate.

The source mismatch was real, but making those settings visible did not make
the resulting terrain better. No material-quality improvement is claimed.
The tracked patch is preserved at
`.artifacts/broad-visual-0910/cloud-upland-material01-withdrawn.patch`; its
focused tests and control tool are held outside the production/test tree.
The previously committed Cloudreach foliage changes remain intact.

## Executed validation

- Editor import: 04:51:41–04:51:49 UTC, clean.
- Initial factory/binding checks: 3 tests / 23 assertions, clean.
- Actual imported normal texture probe: both current maps are DXT1 with blue
  present, so no BC5 defect was established. The candidate subsequently used
  XY-based Z reconstruction and guarded degenerate cotangent frames.
- Revised checks: 3 tests / 25 assertions, 04:54:25–04:54:30, clean.
- Candidate native gate/observatory day/night: 4/4 frames, 123 seconds,
  04:54:38–04:56:41, clean.
- Matched material-only control: 4/4 frames, 117 seconds,
  04:56:55–04:58:52, clean. Manifest verifies scale .65, normal strength 0,
  texture detail .52 and roughness .98 on both mounted materials.
- Judgments: `JUDGE-CLOUD-UPLAND-GATE01.md` and
  `JUDGE-CLOUD-UPLAND-UPPER01.md`.

## Hypothesis

Production replaced both configured upland materials with a legacy turf factory that hardcoded a 0.65 world-space scale, fallback tints, and albedo-only shading. This left the authored 0.27/0.20 scales, distinct tints, normal textures, and normal strengths unused. The candidate routes those existing contracts through the factory and restores texture definition without changing terrain, scatter, grass geometry, counts, or clearance.

## Frozen owned files

- `data/config/cloudreach_visual.json`
- `scripts/world/cloudreach_environment_materials.gd`
- `scripts/world/cloudreach_world.gd` (only the two upland factory calls; concurrent foliage binding hunks retained)
- `shaders/cloudreach_surface.gdshader`
- `shaders/cloudreach_turf.gdshaderinc`
- `tests/test_cloudreach_surface_material.gd`

Cloudreach's generated surface meshes call `generate_normals()` but never generate or author tangents. The surface shader therefore reconstructs a cotangent frame from world-position and world-UV derivatives, applies the authored NormalGL map in that world-projected basis, then converts the result through `VIEW_MATRIX` before assigning Godot's view-space `NORMAL`.

## Authored candidate values

- upland: scale 0.27, normal depth 0.32, texture detail 0.78, roughness 0.96
- dry upland: scale 0.20, normal depth 0.22, texture detail 0.76, roughness 0.97

## Validation for root

Run the focused test through the repository's canonical unit runner for `tests/test_cloudreach_surface_material.gd`, then perform import/check and native Gate/Waycamp captures. The test checks both factory parameters and the production world's final material dictionary, including actual texture resource paths; it also guards the derivative world-to-view normal basis.
