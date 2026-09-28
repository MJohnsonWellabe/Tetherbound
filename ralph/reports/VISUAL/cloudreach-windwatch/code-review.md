# Windwatch final candidate code review

Reviewed the uncommitted candidate at HEAD `9425066d003dd20f0faf6bfb0a461f98ab2aee35`: `scripts/world/cloudreach_windwatch.gd`, windwatch-only changes in `scripts/world/cloudreach_world.gd`, `data/config/cloudreach_visual.json`, and `tests/smoke_cloudreach_windwatch.gd`. Read AGENTS and relevant status/process/art contracts. This reviewer did not launch Godot or judge visual acceptance.

## Final result

No remaining blocking concrete code issue found. The prior P2 seating finding is resolved: configured and fallback clearance are both 0.28 m, while crown top is stone height +0.30 m. The derived cut is therefore embedded 2 cm, and the original deck underside (Y=2.012304) is embedded approximately 1.91 cm. The obsolete lower-support embedding comment is corrected.

The final triangle-fan guard rejects zero-area triangles before emission. It also rejects triangles with cross-product length below 1e-6 in source units; this negligible threshold is appropriate for the fixed asset and removes duplicate clipping-plane vertices without changing surviving winding. No remaining index/winding/normal interpolation issue was found by source review.

## Revision history and evidence boundary

The first candidate retained the complete scaffold. My first code-only report incorrectly inferred that lower legs were embedded from gross bounds. The coordinator's native render exposed dangling scaffold outside the narrow stone shaft and rejected that candidate. Gross bounding-box containment was insufficient to establish local shaft containment; that prior claim is withdrawn.

The revised candidate derives a mesh clipped at the gallery floor and changes roof albedo from orange RoundTiles to installed neutral RockTrim, matching an existing building-recipe substitution. The coordinator's imported-mesh probe confirmed LightWood/Celing material names. The intermediate clipped candidate left a 5 cm unsupported gap, identified by this review and now fixed with clearance 0.28.

The coordinator's first geometry smoke found two degenerate-triangle failures; the final zero-area fan guard addresses that failure. I read the final native log at `D:/tetherbound/visual-acceptance-local/windwatch-smoke.log`: Godot 4.7, `WINDWATCH_SMOKE checks=21 failures=0`. This is reviewed execution evidence from the coordinator for the prior 12/10 m stone-height configuration, not a separately executed reviewer run. The same smoke on the final 12/14 m configuration is pending the coordinator rerun; the existing unversioned log alone does not prove that new run.

## Final bounded height adjustment

The only subsequent source change is configured lower_stone_height_m from 10 to 14, following the coordinator-reported blind nighttime Galefoot landmark-height regression. Upper stone height remains 12. Rechecked all four hashes: script, world and smoke are identical to the prior reviewed versions; only config hash changes below. No implementation files were edited by this reviewer.

This adds 4 m to the lower tower stone top, crown, attached banners and derived gallery position, with their relative seating unchanged. Lower gallery deck top is now 14.636764 m and roof peak 19.504597 m above its origin; upper remains 12.636764/17.504597 m. X/Z placement, footprint, clipping plane, material mapping, all collisions and gameplay ownership remain unchanged. No new blocking code issue is introduced by this adjustment. Its intended silhouette outcome remains for fresh image review, not this source verdict.

## Source and test checks

- `cloudreach_world.gd:3719-3726` preserves both tower X/Z positions and reduces only stone heights from 19/16 m to 12/14 m. Houses, house colliders, paths, yard placement, interactions and durable/gameplay data remain unchanged. Banners follow the shortened height.
- `_gallery_mesh` processes indexed source triangles through one horizontal half-space. Appending an inside vertex followed by its outgoing-edge intersection preserves polygon order; triangle-fan reconstruction preserves winding. Opposite-side testing makes intersection division safe. Original corner normals and normalized interpolated normals are supplied before each emitted vertex.
- Both source surfaces retain geometry at the configured cut. `builder.commit(result)` preserves surface order, and per-instance material overrides map the fixed imported LightWood/Celing surfaces correctly. Source assets remain unchanged. The test's active-material assertions exercise the actual imported material classification and surface order.
- The clipping path is deliberately specific to indexed source triangles with full normals and this floor cut. It is not a generic unindexed-mesh clipper or a general configuration validator. No such generic capability is required by this candidate.
- Both roof texture paths exist and configuration parses. Triplanar materials do not depend on preserved source UVs. The later settlement recolour pass processes only Terrace_ children and does not replace gallery materials. The cut does not add a bottom cap; its slight burial in the crown covers the cut boundary.
- Source OBJ bounds: X [-0.746770, 0.746772], Y [-0.023286, 3.813585], Z [-0.746771, 0.746772]. Import uses unit scale and zero offset; X/Z centering error is negligible. Final maximum gallery width is 10.5 m; roof width is approximately 9.665 m. Deck underside is stone height +0.280882 m, deck top +0.636764 m, roof peak +5.504597 m.
- The 21-check smoke covers both configured settlement heights: distinct derived meshes, two material surfaces, correct active materials, scaffold removal, retained roof height, configured seating and crown overlap, gallery width, finite unit normals, no degenerate triangles, and source geometry preservation after both builds. It is useful native geometry verification; it does not establish camera appearance, collision behavior, or whole-scene acceptance.

## Physical limitation, accurately scoped

The new deck, posts and roof have no collision surfaces and cannot provide a Fly landing or support a trainer. This is newly drawn geometry with the same decorative physical treatment as the existing tower: `_castle_piece` adds no body, settlement construction never calls `_castle_piece_collision`, and crown/foot explicitly pass false. This is not a newly introduced loss of a working collider. The new silhouette may invite landing attempts; ordinary-flight/visual review should assess that expectation. Source inspection does not establish a newly blocked route or gameplay regression.

## Exact reviewed file SHA-256

- `scripts/world/cloudreach_windwatch.gd`: `41F49E15342F225018DB0EC430349C9C0F9066FD7ADF42E9E520F592388DDE82`
- `scripts/world/cloudreach_world.gd`: `CAAA76BDB3C6B9BF97BC5E11086A4011C47AF7BB90D0599738448550D26FD481` (windwatch diff only reviewed)
- `data/config/cloudreach_visual.json`: `C3E55245197A19D3049CAF4DC1B3EE408CF51EAE77980F3A40A8CD20C11D735B`
- `tests/smoke_cloudreach_windwatch.gd`: `9AA84E9868F31C3B7FEE77DEF57EA25407B630211D38CBB7933DF79B064D6ACE`

No player traversal, device performance or image comparison was performed by this reviewer. This code review does not close visual Bars A/B or broader settlement acceptance.
