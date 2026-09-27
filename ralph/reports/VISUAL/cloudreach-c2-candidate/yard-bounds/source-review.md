# Independent source review

Reviewer: `settlement_structure_review`, read-only, exact final source diff.
No blocking findings. Earlier density concern was fixed before final evidence.

Settlement tagging is synchronous and therefore covers only the current
settlement's yard/precinct patches. The23.8m half-extent is inside both the
24m collision floor and24.1m visual crown. Earlier untagged settlement patches
stay inside the crown: central ellipse radius22.44m, skirt pockets about23.64m.
No route, terrain, collision or house-placement change. Both Cliffhold and
Galefoot use this path; both require native evidence.

Clipping occurs after the original placement/scale/rotation RNG draws.
Unsupported eligible roots count toward the requested total, preventing
replacement grass from accumulating along the boundary. Untagged patches
retain their old behavior. Regression builds the real MultiMesh output for
fully, partly and wholly supported patches and compares complete transforms
to the original supported subset across grass, flowers and bushes. The
southern patch uses its actual6.8×9m extent.

Root verification: six focused tests /587assertions /0failed. Both before and
after runs wrote ten native frames,0skips,exit0. Every image opened individually.
There is still a floating clump in Cliffhold court003/004; this bounded source
repair does not establish whole-scene ground-contact or F08#4 acceptance.

Reproduction: Windows Godot4.7, NVIDIA GTX1060, Compatibility renderer,
borderless1920×1080, fixed60fps, `-s tools/capture_cloudreach_settlement_identity.gd`
with `--section=region --region=cloudreach --out=<output>`.
Same fixture at baseline5c886d80f and the retained source diff. The fixture uses
scripted progression, hidden HUD, stationary production-camera stands and
parks the companion behind the camera. Upward pitches are in each manifest;
these are diagnostic views, not the complete C2 matrix or motion proof.

No new art asset, generation or purchase. The separately trialled retaining
arcade is reverted; see sibling `settlement-terrace/visual-judge.md`.
