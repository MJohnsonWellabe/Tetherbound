# Cloudreach courtyard wear comparison

F08#4, M1–M12 and whole-game Bars A/B remain open. This packet addresses the
square soil cells identified in the settlement comparison, across the shared
material's grass and paving consumers.

## Build and change

Base `4e41ad25c25084e5189741d40f2d79db177bfc48` incorporates current GitHub main
`5dac88621a6ba26d8d2e1699e50411a24f0cb4f4`. The candidate is the working patch
over that base. [Manifest](cloudreach-courtyard-wear/manifest.json) records source
and original artifact hashes.

The existing soil texture and irregular wear mask now blend over the actual
surface underneath. The old mask discarded whole world-grid cells. No turf is
painted into the soil's fading edge: the same material also covers ash on cobble,
and some high yards use a different turf family. Ground wear renders at priority
-1, before the live hazard overlay at priority 0, while retaining depth testing.
Unused synthetic-turf bindings are removed. Geometry, collision, gameplay and
the shared camera are unchanged.

The first local candidate mixed in synthetic turf. Source review rejected it
for high-yard turf mismatch and grass on paving. A subsequent alpha candidate
prompted the explicit hazard ordering before the final capture. These earlier
local images are diagnostic only; the archived final set uses the ordered
material and contains the extra overlap check.

## Evidence

- [Fresh code-blind review](cloudreach-courtyard-wear/blind-review.md) inspected
  both sheets and all 44 native frames. A was the candidate, B the control:
  **10 candidate preferences, 12 ties, zero control preferences**. The strongest
  wins remove square fragmentation from settlement wear; four ash comparisons
  are slight preferences. Whole-scene **Bar A: NO; Bar B: NO** for both sets.
- 44 untouched native 1920×1080 frames: 22 control/candidate pairs covering
  five settlement views, three battle yards, plain and hazard-overlapped brazier
  ash, and the aviary; all day/night. Godot 4.7, Compatibility/OpenGL 3.3,
  GTX 1060 3 GB. Final process exit 0, zero capture skips.
- One world instance switches the shared shader code between the preserved
  baseline and candidate. Geometry and material uniforms remain fixed between
  pairs. Time of day, feet, target, camera, pitch and yaw match in every pair;
  ordinary animation and physics time are not frozen globally.
- The hazard rows freeze only the production presentation's phase at 2 and
  elapsed time at 0, restoring both uniforms and processing afterward. The
  selected ash is at (123,1160.2,5448), inside the active arc and outside shelter.
  This is a layering diagnostic, not evidence of earned combat or tell timing.
- [Independent source review](cloudreach-courtyard-wear/code-review.md) finds no
  remaining production blocker after the substrate and priority revisions.
- [Focused environment tests](cloudreach-courtyard-wear/tests.log): 4 tests,
  12 assertions, zero failed. The existing off-tree mesa test emits a global
  transform error; this is not an error-free engine log. Removed assertions
  pinned the rejected grid expression; trail-joint checks remain.

## Limits and remaining work

The production camera uses teleported, physically seated diagnostic stands;
the companion is parked behind the camera and HUD hidden. Some ground wear in
the three yards is already buried under the opaque crown. Their unchanged views
are regression context, not proof the buried wear is effective. Likewise the
existing summit skirt's whole surviving mask is occluded by the deck; it was
excluded as a misleading material witness. The aviary retains hard-edged floor
geometry. These existing defects are not claimed fixed.

The capture logs preserve the existing unscoped `fly_tutorial_completed` error,
unsupported candy placement warning and fail-closed wild-site warnings. Source
review also notes that the adapter relies on the authored runtime ash/overlay
being present; the actual target and hazard fixture were checked in this run.
The logged wear priority is a declared fixture value, verified in source, not
a runtime material readback.

No full movement, co-op, target-device cost or complete regional acceptance is
established. Oversized/unsupported vegetation, cliff forms, settlement density,
night hierarchy and the remaining owner criteria still require work.
