# P2-022 independent code review

Reviewed the current default-off aviary crown candidate on `tb/x04-cloudreach` in `D:\tetherbound\x04-cloudreach`.

Exact candidate files reviewed:

- `scripts/world/cloudreach_world.gd` (working diff)
- `data/config/cloudreach_aviary.json` (working diff)
- `tests/test_cloudreach_aviary_architecture.gd` (working diff)
- `scripts/world/cloudreach_aviary_crown.gd` (new builder)

## Findings

No actionable findings.

- **Default-off behavior:** `crown_arcade.enabled` is false. The builder returns before creating any node or light when disabled or when the key is absent. The world hookup retains the existing aviary build/seating order and does not mutate existing materials or geometry.
- **Geometry and seating:** with the supplied dimensions, the sill bottom is at local Y=9.0, matching the original drum and pier tops; the posts overlap the sill, and their capitals overlap the arch springline. The existing summit seating helper adds lower footings without moving the drum tops. The bay basis maps local X to the drum tangent and positive Z outward, as its comment states. New geometry stays above the existing 8.0 m throat clearance.
- **Winding:** inspected the reused `_arch_stone` helper. An independent arithmetic check of its face indices at all 13 candidate wedge angles found 156 nondegenerate triangles and no inward clockwise faces. This checks the construction math, not engine rendering.
- **Collision and scope:** every new box passes `collision=false`; arch wedges are MeshInstance3D nodes. The installed lantern source contains a mesh node without a collision suffix or extension, and its import metadata has no custom script or subresource overrides. No route, gameplay, encounter, durable state, or camera logic changes were found.
- **Materials and lights:** the builder reuses the production aviary stone/trim materials without changing them. Their shader uses world-space triplanar mapping, so the helper's planar UVs do not introduce a new UV dependency. The supplied configuration creates four ordinary OmniLight3D accents with positive energy/range and shadows disabled. No apparent GDScript type or syntax concern was found.
- **Tests:** the added test exercises both the disabled and enabled builder, checks for collision bodies/shapes including imported descendants, and checks combined visible bounds against throat headroom. `combined_aabb` includes descendant transforms, making that local-height assertion relevant here. Existing architecture assertions remain unchanged.
- The JSON parsed successfully, and `git diff --check` passed for the reviewed paths.

## Limits

Static review only: no Godot process, GPU run, world boot, or source edit was performed. Existing helper implementations, lantern source/import metadata, seating logic, bounds logic, and material setup were inspected for context. The parent reported the focused suite passed 4 tests and 129 assertions; this review did not independently rerun it.

The added test does not verify arch winding, masonry joins, lighting appearance, full-world integration, or rendering cost. The winding conclusion above comes from independent arithmetic inspection. Configuration review covers the supplied valid dimensions, not arbitrary malformed tuning. Four extra lights and the added mesh instances still require the native capture/performance evidence appropriate to enabling the candidate.

No screenshots or visual verdicts were inspected. This review is not visual acceptance, and the default-off candidate remains subject to independent matched native day/night review before activation.
