# Cloudreach rock sections — independent source review

2026-09-27. Read-only review of `cloudreach_rock_sections.gd`, `_visual_rock_mass` integration and `cloudreach_visual.json::geology.rock_sections`. Inspected installed Rock_Medium_1/2/3 glTF metadata and imports, bounds helper, callers and the supplied pixel-ray ownership receipt. No Godot/import/export, production edits or art acceptance judgment.

**Verdict: no concrete height/collision/material correctness blocker found for the current installed family and config.** Mesh-instance cost increases materially, and the configured section aspect is not a strict upper bound. Native connectedness and appearance remain unproven by source.

## Bounds, family and integration

- `cloudreach_rock_sections.gd` fits each imported section against the existing transform-aware `combined_aabb`. All three source meshes have nonzero bounds, one mesh/primitive and no authored transform/collision node; import subresource dictionaries are empty. Their LOD0 counts are respectively 342, 244 and 522 triangles; imported LOD generation remains enabled.
- Section width factor lies in [.84,.92], while each horizontal centre shifts by at most .03 of the requested dimension. Thus each local X/Z bound is at most `.92/2 + .03 = .49` times the requested dimension from centre, inside the old ±.50 box. The parent yaw/base are unchanged. This preserves a bounding box, not the old rock silhouette or its exact surface footprint.
- Each section's minimum Y is `i*stride`. Last maximum Y is exactly `height`, because `section_height * [1+(count-1)*(1-overlap)] = height`. CPU calculation on the 54 region spurs/satellites found maximum floating residual `2.27e-13 m` and maximum horizontal half-extent fraction `.4899413371`.
- The family cycles the existing three PackedScenes deterministically; no new RNG calls alter other scatter. The original root material selection, including distant haze tiers, is applied to all section meshes through per-instance `material_override`. No shared material, imported mesh, source texture, normal or LOD resource is edited. Visibility distance is applied through the same root walk as before.
- The integration is confined to `_visual_rock_mass`, which is visual-only. It creates no collision shape, changes no route/crown geometry and does not modify rewards, triggers or access state. Unqualified/disabled masses use the original one-rock branch.
- Helper preconditions are currently satisfied: nonempty installed family, positive requested dimensions and nonzero imported bounds. It does not defend against an empty/replaced family or zero imported bounds; this is not a present production failure.

## Section aspect is a target, not a guarantee

Count calculation uses the full requested width, then each section narrows to .84–.92 of that width. Even without reaching `max_sections`, actual section height/width can exceed `section_aspect=3.2`. The eight-section cap further limits the correction on the tallest crags.

Exact identified owners, reconstructed from production callers:

| Owner | Requested size | Sections | Maximum section aspect | LOD0 triangles before → after |
|---|---|---:|---:|---:|
| HighRoostSkyShrine/SatelliteCrag0, seed 28 | 59.8 × 1198 × 80.5 m | 8 | 4.916664 | 244 → 2,982 |
| UpperCloudreach/BeddedSpur3, seed 943 | 173.6 × 1048 × 105 m | 5 | 3.703497 | 244 → 1,874 |

This is still a substantial reduction from the original height/width ratios (~20.03 and ~9.98), but do not describe 3.2 as an enforced maximum. A strict guarantee would require count selection using the narrowed width and enough allowed sections, or an explicit documented cap exception; that is a separate implementation choice.

## Count and performance

A CPU reconstruction of all 42 BeddedSpur and 12 SatelliteCrag recipes across six regions found:

- 51 of 54 qualify for replacement.
- **54 → 257 mesh instances**, an additional 203 potential submissions before visibility/occlusion/LOD behavior.
- **19,944 → 95,224 LOD0 triangles** across that subset.
- Each section retains one source surface, so there is no batching reduction in this helper. Shared meshes/materials save resource duplication but do not merge submissions.

These totals exclude other qualifying `_visual_rock_mass` callers (horizon ranges, lower relief, bridge supports and settlement dressing). The helper applies to every qualifying call, not just the two pixel-ray owners. Native whole-scene counts and frame timing are therefore required; the above is not a full scene cost or a frame-rate prediction.

## Capture obligations

Overlap=.45 gives vertically overlapping AABBs, not proof that the irregular actual rock solids intersect continuously. Different family profiles, tapered ends and lateral shifts can create holes, shelves or disconnected-looking joins despite that overlap. Inspect the two identified Windscar owners at near/mid/far and oblique angles, including silhouettes and spaces between sections. Positive scales preserve source winding; no triangle topology is generated here.

Narrower boxes and changed profiles can uncover unchanged procedural walls, embedded props or roads. Root/height preservation does not prove every prior attachment remains embedded. Capture should check those relationships, section popping/culling, and whether the tall-stretch defect is materially improved. The earlier terraced-wall experiment is rejected/reverted and provides no acceptance evidence for this replacement.
