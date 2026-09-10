# Continuous Meadows creature-visibility audit 01

Status: **read-only; no spawn/content change justified by this evidence**.

## Evidence and measurement contract

The exact runtime record is:

`C:/Projects/Tetherbound/.artifacts/broad-visual-0910/runs/continuous-through-bridge-second/profile/Godot/app_userdata/Tetherbound/four_biome_coverage_21312_2590.jsonl`

It is 154,136,648 bytes and contains 352 samples over about 3,697m of observed
movement; 183 samples report fewer than two credited bodies and one interval was
undersampled. The producer is
`tests/helpers/four_biome_road_coverage_observer.gd`. Each sample contains every
live eligible wild body, but credit is deliberately stricter than raw distance:
the body must lie in the **camera's** forward half-plane, have both endpoints in
front of the camera, have its centre inside the actual camera frustum, occupy at
least 15px at a normalized 720p height, and pass a camera-to-body physics ray.
`nearest_route` is explicitly nearest-polyline metadata; it is not membership.

The formal oracle is `tools/gate_f/road_creature_visibility_model.gd`, exercised by
`tests/test_road_creature_visibility.gd`. It samples the authored route tangent every
10m and credits authored cluster counts from projected size and the tangent's forward
180 degrees. It does not model scatter displacement, actual camera yaw/frustum, live
wandering, terrain/prop occlusion, or visibility gates. The latest targeted ROAD run
passed, so the runtime observer is complementary experiential evidence rather than a
formal ROAD contradiction.

## What dominates this run

Restricting the runtime data to 238 samples within 5m of the Band 1 polyline leaves
130 below-two samples. Across 231 consecutive on-road sample pairs with usable
movement, the camera faced against the direction of travel in **223 pairs** and with
it in only 8; the median horizontal camera/travel dot product was -0.490. Of the
below-two samples that have a consecutive pair, 120 occurred while the camera faced
against travel. For most of the route the camera forward vector remained about
`(+0.037, -0.423, -0.905)` while the driver travelled toward increasing world Z.
The stick driver can walk backward relative to that retained camera, so these are
real frames but not evidence that the road ahead lacks creatures.

The longest near-road below-two runs were:

| Route arc | Approximate world span | Runtime run | Concrete observation |
|---|---|---:|---|
| 464–647m | `(-237,334)` to `(-386,434)` | ~201m | Camera looks mostly toward -Z while route advances +Z; nearby forward-by-camera Pipwings are often outside the narrow frustum. |
| 706–778m | `(-416,486)` to `(-396,537)` | ~80m | At arc ~748m, nearby Paddlenewts lie behind the camera; a 42m Bramblebun is clear but outside the frustum, while farther candidates are terrain/bridge occluded. |
| 848–988m | `(-342,581)` to `(-214,640)` | ~151m | At arc ~928m, two large Meadowharts 24–28m away are in the camera half-plane and clear but outside its frustum; the road/travel direction is on the other side. |
| 1029–1089m | `(-177,655)` to `(-120,675)` | ~70m | Several nearby Pipwings are clear and large enough but outside the retained camera frustum; the closest is behind it. |
| 1290–1420m | `(66,750)` to `(183,807)` | ~141m | Nearby Trailpups/Pipwings are predominantly behind the camera as the driver advances. |
| 1943–2084m | `(294,1146)` to `(167,1204)` | ~151m | Clear, readable Pipwings exist at 21–55m but fall outside the retained camera frustum; nearby Bramblebuns/Trailpups lie behind it. |

There are real occlusions in individual frames (terrain, common-tree and rock
colliders), but they are secondary to view direction here. Authored exclusion zones
cannot explain bodies that are already nearby, projected well above 15px, clear by
ray, and rejected only because the unchanged camera points elsewhere.

## Disposition

Do not add or move creatures from this record. Doing so would spend population to
fill the half of the world behind a deliberately retained camera and could regress
encounter spacing while the formal forward-road coverage already passes.

One bounded shared measurement improvement is justified: preserve both metrics in a
future observer. Keep the current camera-visible credit exactly as the experiential
view result, and add a separate travel-heading/route-tangent credit over the same live
bodies, with the same actual projected-size and LOS checks. Report camera/travel dot
and segment results separately. A controlled ordinary traversal that turns the real
camera toward travel before each stable sample can then decide whether any authored
interval is visually empty. This changes no production camera behavior and preserves
free orbit. Only gaps that remain below two in that aligned-camera run should be
mapped to specific clusters or exclusions.
