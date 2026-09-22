# WARRENS-EGRESS evidence report

Status: bounded collision correction verified on source commit `503ed3de529795a182f772b65dc14252f43d74dc` (PR #137). This report covers the existing Warrens and Playground runtime smokes; it does not claim a clean full-suite or release result.

## Verification

`tests/smoke_warrens.gd` ran first with stock Godot 4.7 and isolated APPDATA, then `tests/smoke_playground.gd` ran serially with a separate isolated APPDATA. Both exited 0.

Warrens evidence:

- Real production capsule ingress/egress walked 62.0 m from local z=-25.0 through the mouth and back.
- The deepest chamber remained enclosed: 180 daylight rays, 0 leaks; five chambers covered from above; mouth arch line clear.
- Interior ambient/layer probe checked 252 interior and 268 exterior meshes; player layer changed 3 → 0.
- All 12 root pieces were above the walk floor, with minimum measured clearance 2.186 m; no root was too low.
- The full cave walk reached the branch chamber (52 m), closed/open branch behavior worked, the first clear paid once, and a second cleared build spawned no guardian.
- The smoke ended `warrens smoke test passed`.

Playground evidence ended `smoke: OK`; terrain/world boot, creature/tool/UI, and berry-farm checks completed on the same stock runtime family.

The original defect was a hidden bank collision lip at approximately 0.50 m against the player’s 0.35 m step. The correction is the narrowly scoped approach from `aa19df9c5`, ported into the current source. It preserves the authored four haze cards and measures actual wall-root triangles for clearance rather than rejecting the passage on rotated whole-mesh AABBs.

Both logs contain the known headless dummy-renderer shutdown allocator/resource errors after the passing smoke verdicts. Playground also emits one dummy-renderer `Parameter "material" is null` diagnostic during its torch inspection; the smoke continues through `smoke: OK` and reports no gameplay `SCRIPT ERROR` failure. Repeated `Torch_Metal` glow warnings are existing authored prop diagnostics.

## Remaining limits

These smokes establish the local collision/route path and the broader Playground boot path. They do not establish device performance, visual review, export behavior, or unrelated chapter acceptance. The prior CI Warrens run included a real collision lip failure plus outdated haze-count and rotated-AABB criteria; `503ed3de5` addresses the lip and aligns the checks with the authored four-card haze and actual-root geometry. This result is the bounded current-source verification.
