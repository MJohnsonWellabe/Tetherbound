# Cloudreach visual lane — High Perches, 2026-09-09

## Scope and switch

The queued Old Wind Observatory defect was the hard white cloud discs and overlapping cloud boundaries. That exact production mechanism has exhausted its iteration budget: `CLOUDREACH-ATMOS-0906` changed `cloudreach_world.gd::_build_cloud_decks`, the `CloudBillows` MultiMesh and `cloudreach_visual.json` across four render rounds and three blind judgments. Its final judge still described the result as “opaque white cardboard” and “flat cutouts.” This lane therefore did not repeat cloud-sheet or billow tuning.

The replacement defect is from the current canonical Cloudreach judgment: the High Perches stand showed immense plain brown columns with no intermediate detail, weakening both authoredness and environmental scale agreement. Retained source-identical baseline frames:

- `shots/catalogue/cloudreach/round-pylon-20260909T015726Z/cloudreach__high_roost_sky_shrine__08__the_high_perches__day.png`
- `shots/catalogue/cloudreach/round-pylon-20260909T015726Z/cloudreach__high_roost_sky_shrine__08__the_high_perches__night.png`

## Production candidate

`scripts/world/cloudreach_world.gd::_build_high_perches` retains all six original stone needles and timber caps. It adds non-colliding keeper construction at visible heights using materials already established in this biome: seated masonry footings and collar courses, six outward weathered-timber rest arms with paired knee braces, and a gently sagged rope line around the outside of the group. Heights and arm lengths vary by needle so the additions describe a maintained flight roost rather than a uniform ring treatment. Landmark position, terrain, lighting, cloud systems, route surfaces and physics shapes are unchanged.

`tools/_probe_cloudreach_high_perches.gd` checks the production scene for the retained six needles/caps, the complete new structural set, and zero collision bodies in those additions.

## Evidence and checks

- Godot 4.7 `--check-only --script tools/_probe_cloudreach_high_perches.gd`: pass.
- Production catalogue subset `high_perches`, Compatibility/OpenGL3 on NVIDIA RTX 3050: `CATALOGUE SURVEY OK: 2/2`; manifest `complete=true`, zero failures. Capture took 123.4 s; guard peak was 86% committed memory and 246 processes, below the 600 s / 90% / 400-process stops.
- Full raw scan of `engine.log`, `wrapper.stdout.log`, and `wrapper.stderr.log`: zero `^ERROR:`, `SCRIPT ERROR`, parse errors, invalid calls, assertion failures, or `FAILED`. The only stderr line is the pre-existing `cr_candy_broken_route_good_07` no-surface warning in `cloudreach_physical_runtime.gd`.
- After day: `shots/catalogue/cloudreach/round-high-perches-20260909T113828Z/cloudreach__high_roost_sky_shrine__08__the_high_perches__day.png`
- After night: `shots/catalogue/cloudreach/round-high-perches-20260909T113828Z/cloudreach__high_roost_sky_shrine__08__the_high_perches__night.png`
- Two-column before/after sheet (day row, then night row): `shots/catalogue/cloudreach/round-high-perches-20260909T113828Z/high-perches-before-after.png`
- Capture receipt: `shots/catalogue/cloudreach/round-high-perches-20260909T113828Z/manifest.json`; production CameraRig/Camera3D, ordinary HUD, same catalogue coordinate and camera transform as the retained baseline, audit-only clock pin, no progress or save injection.
- Independent code-blind verdict: owned by the root lane; this implementation lane does not judge its own candidate.

Visible evidence limitation: the canonical ground stand shows the new masonry footings and collar courses, but the rest arms, braces and perimeter rigging sit above or behind its framing. No additional upward or approach-context frame was captured because the single-render lease moved to the creature lane. The scoped production-count probe was intentionally not booted as a second full-world process; it remains a checked, runnable assertion for a later lease. These frames therefore do not prove the upper additions' readability or route clearance, and the requested ordinary approach context remains absent.

## Source and evidence receipt

| File | SHA-256 |
|---|---|
| `scripts/world/cloudreach_world.gd` | `FC82CCADE5639EEEE5216DEBBF109BCAE636F6666B7A030584E9712D8F546D8C` |
| `tools/_probe_cloudreach_high_perches.gd` | `E6D62E1DD639BF77CEE03559742698A5725E7FBCF0660BB25BA73A02EB36AF06` |
| retained baseline day | `C499B2A15F20EA05CBA6525A550702B61FD845C53CF33FE6ACD57F6BFBBC4910` |
| retained baseline night | `FDFB0ADFFC5F90B90E2645E278878C1775209763B64760FD135DBB33DB724C22` |
| after day | `8473D88ADCD73F91C474FB650DA0BF635116BDFC606EC735F1D1F75FAE33E274` |
| after night | `327A9EF349E33D946148B581C0D34E4CEDDC15C6764CB5B7EEC66BD7F3843BEF` |
| before/after sheet | `2D1007A29FEB57DA3F3289AAD48797EAA3C0C57F3ED11EB2EB0019C0EE7B81D0` |
| manifest | `1A4E82E957A2A115E0009128373E318DEEF7A3BE001B0B432920C363BC142F08` |

This is one bounded landmark candidate. It does not close the Cloudreach biome visual bar or the exhausted cloud-form defect.
