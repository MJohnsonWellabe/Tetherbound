# Cross-region cliff comparison

This is the first repair experiment selected by the whole-game ranking in
[AUDIT](AUDIT.md). It compares shared cliff/shore presentation across Cloudreach
and Tidewake. It does not close priority 1 or whole-game Bars A/B.

## Build and evidence

GitHub main `94c63b1f221063c2cec7122136bb111f6805bfd7` was fetched and merged
into the owned visual branch as `dbb7a98fe`. The previous 508-frame whole-game
audit remains an immutable snapshot of its earlier baseline. Main was checked
again after these captures and still pointed to `94c63b1f2`.

Five completed capture sets contain **69 native 1920x1080 frames**: Cloudreach
12 baseline and 12 candidate; Tidewake 15 baseline, 15 first candidate and 15
revised candidate. Every recorded camera pose, feet position, target, yaw and
pitch matches its corresponding baseline. Tiny spring-arm floating-point
differences are not changes in the recorded pose. The fixture selects existing
stands, writes region/party/progression/clock state, hides HUD and parks the
companion. These are staged production-scene/CameraRig views, not walked routes.

Runtime: Godot 4.7 stable `5b4e0cb0f`, Compatibility/OpenGL3.3, GTX1060 3GB,
driver560.94. The three Tidewake runs exited cleanly, with the existing physics
interpolation deprecation warning. Both Cloudreach runs produced all 12 frames
but their wrappers failed because current production progression emits
`unscoped chapter flag: fly_tutorial_completed`. The fixture itself no longer
writes that obsolete flag; the error comes from chapter reconciliation. No
gameplay fix was made in this visual lane. Earlier parser/dump setup failures
produced no accepted evidence and are excluded from the 69-frame count.

[Manifest and hashes](cliff-family/evidence.json), exact capture driver/runner,
logs, candidate source snapshots and contact sheets are in `cliff-family/`.
Native PNG paths are recorded there and remain local. Reviewers inspected the
native PNGs; contact sheets only summarize them.

Four unaltered native PNGs are also committed for direct inspection:
[First Shore baseline](cliff-family/first-shore-day-baseline.png) and
[retained candidate](cliff-family/first-shore-day-retained.png);
[Shellwatch night baseline](cliff-family/shellwatch-night-baseline.png) and
[retained candidate](cliff-family/shellwatch-night-retained.png). The latter
pair exposes the recorded shaded-surface regression rather than hiding it.

## Cloudreach: rejected

The candidate replaced fine wall displacement with wider bedding and joints,
and increased wall sampling from 20 to 48 rows. It preserved crown and route
construction and their collision copies. Independent source inspection found
no concrete collision/seam blocker, but sampling could multiply a wall quad's
triangle count by 14.4 in the worst width range.

The [independent visual review](cliff-family/cloudreach-verdict.md) inspected
all 24 native frames. It preferred the baseline at Windscar day and night and
tied the other ten pairs. Added ridges read as regular corrugations or zipper
marks while the broad extruded-wall form persisted. The candidate is **removed
from production**; its source is retained only as rejected evidence.

Only Windscar exposed enough cliff face to judge the change strongly. The camp,
shrine and Cliffhold views were mainly non-regression controls. The next form
experiment needs substantial irregular terraces, broken shoulders and recessed
fractures, first proved at Windscar at medium and reachable near-face distance.
Increasing the rejected ripple strength or repeating the same weak viewpoints
would not address the finding.

## Tidewake

The first candidate projected the already installed Rock030 albedo and normal
onto steep faces. It reduced stretched scree detail but left an obvious band
where the old material remained on less-steep exposed rock. That candidate was
not retained. The revised candidate combines authored rock coverage with the
steep-face mask and adds a top projection for coherent coverage. It changes no
height maps, control maps, route data or collisions. Veilfall's separately
authored material region is excluded.

The revised run confirmed the coastal shader marker, bound albedo sampler,
strength1.0 and scale0.18 after the world's subsequent installation steps.
[Independent source review](cliff-family/cliff-source-review.md) found no new
blocker: 262,144 control-decode cases, 10,000 bilerp cases and 10,000 three-plane
normal cases passed CPU checks. These are mathematical checks, not GPU or
performance acceptance. The active layer costs six additional texture reads
per affected fragment; coverage now includes painted gentle rock. Its paint
mask is raw occupancy, not Terrain3D's final height-blended contribution.

The [independent visual review](cliff-family/tidewake-verdict.md) inspected all
30 native baseline/revised frames. It recommends **retaining candidate 2 as an
intermediate improvement**, preferring it in 11 of the 12 useful comparisons.
Shellwatch night marginally favors the baseline because the revised shaded
bank loses information. The three Veilfall views have no material verdict.
The source/config changes are retained on draft PR365, not declared ready or
accepted. No new image pixels or geometry are imported.

**The material itself still FAILS final quality, and whole-frame Bars A/B
remain FAIL.** Fine mottling is too uniform over large smooth faces, distant
bands can read as painted stripes, and the installed pale boulders do not yet
match the cliff finish well. Further work must establish large/mid/small rock
structure and ground/shore transitions, including shaded-night readability;
another grain or tint adjustment alone is not the next acceptance step.

## Follow-up: identify the visible mesh before changing its shape

The subsequent coarse procedural-wall profile was also removed. Its native
12-frame test did not materially improve the dominant Windscar faces, and
independent source review found an edge extending 32.15m past the old wall
where the new profile skipped an existing bend. Its code and review are
archived as rejected evidence in `cliff-family/ownership/`.

A production-camera pixel-to-triangle probe then identified the actual
foreground owners. At Windscar pixel(420,250), the first intersection is
`HighRoostSkyShrine/SatelliteCrag0/Rock_Medium_2`, 1217m from the camera;
the procedural CliffMass is behind it. Pixel(1550,200) hits
`UpperCloudreach/BeddedSpur3/Rock_Medium_2`, 1395m away. The former stretches
a 244-triangle installed boulder to 59.8x1198x80.5m; the latter to
173.6x1048x105m. Thus changing the hidden procedural wall could not repair
those visible masses. [Exact ray receipts](cliff-family/ownership/pixel-to-mesh.json)
include other hits and the source probe. Its one native frame is diagnostic,
not an art pass. The two captures share the disclosed production flag error.

The retained replacement acts in `_visual_rock_mass`: extreme tall crags use
overlapping, shorter sections from the same three installed boulders. Root
position/yaw, total height, material selection and visibility-distance policy
are preserved; unqualified masses keep the old branch. No source asset pixels,
import settings, playable crowns, route geometry or colliders change. The
instance cap and narrowed pieces mean 3.2 is a target aspect, not a guarantee;
the named satellite's most stretched section is still about 4.92:1.

The [independent image verdict](cliff-family/ownership/rock-sections-verdict.md)
inspected all 24 matching native baseline/candidate views: the candidate is
preferred at Windscar day/dusk/night, while the other nine pairs tie and give
weak cliff evidence. It recommends retaining this **modest localized form
improvement**. Final cliff form and material quality still fail: broad smooth
walls, sharp section boundaries, pale dusk values and near/far stone mismatch
remain. No full Bar A/B or chapter acceptance is claimed.

[Baseline](cliff-family/ownership/windscar-baseline.png) and
[retained shape](cliff-family/ownership/windscar-sections.png) are unaltered
native PNGs. The 12 final frame hashes and matching camera/feet/target records
are in [evidence](cliff-family/ownership/rock-sections-evidence.json).

Source review found no concrete correctness blocker. A native Godot check
using the actual imported three-rock family passed 22 assertions across the
two identified owners, two additional aspect cases and fallback cases:
exact height, horizontal bounds, no collision nodes and capped section count.
The committed `tests/smoke_cloudreach_rock_sections.gd` was executed directly
after strengthening its disabled-config case. Neither bounding boxes nor these tests establish solid
overlap or visual quality of every join.

**Cost remains open:** for the 54 regional spurs/satellites alone, the source
census grows 54 to 257 mesh instances and 19,944 to 95,224 LOD0 triangles. Other
callers are excluded from that count. Near/oblique joins, motion/culling and
native whole-scene/Ally timings still need verification. This is a draft
intermediate improvement, not a performance-accepted replacement. The source
review and native check receipts are retained beside the image verdict.

## Remaining evidence boundaries

Day/dusk/night views span First Shore, Brine Steps, Shellwatch, Veilfall crown
and Deep Watch. The Veilfall crown is an exclusion/ground control, not proof of
the waterfall face. Full material acceptance still needs motion, a normal HUD
camera route and target-device cost. Unchanged silhouette, vegetation, shore
contact and destination failures remain governed by the ranked whole-game
audit. No region, criterion or whole-game acceptance is inferred from a local
improvement or from source correctness.

No generation service, Meshy credits, asset purchase or new texture provenance
is involved. Rock030 is reused from the installed terrain family; source image
pixels remain unchanged. Claude's checkout and gameplay files were not edited;
Claude retains merge ownership.
