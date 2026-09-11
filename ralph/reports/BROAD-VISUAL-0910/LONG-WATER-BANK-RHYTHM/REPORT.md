# The Long Water bank-rhythm pass — 2026-09-11

## Status

**Accepted R3 grade: POLISH (shippable improvement, not PASS).** Production
proof is complete at **6/6 frames with 0 failures**. The east-axis view finally
sells a long receding water corridor with a bend, wooded banks and a distant
tower, and the new camera keyhole removes the blocking trunks. The pale far bank
remains an unnaturally straight cut in arrival and west-axis views, so this is
not location closure.

## Bounded correction

- Retained the established r23 open-water sightline and all two-bank reeds.
- Kept the three existing far-bank shelves moderate and moved them onto the
  flat waterline bed at the toe, where one-point ground sampling can actually
  seat them. Added three separately grounded rim-top outcrops and enlarged the
  established irregular reed clumps to interrupt the upper silhouette.
- Strengthened the existing three-stone south-bank crown rather than adding a
  new structure or changing the water/terrain carve.
- Kept every prop outside the flat channel and left long open-water and bare-face
  intervals between the authored beats.

Dedicated evidence tool: `tools/capture_long_water_bank_identity.gd`, covering
ordinary arrival, overlook and shelf read in production day/night pairs.

Windows production command (real Compatibility renderer; deliberately no
`--headless`):

```powershell
& 'C:\Users\mattj\.cache\tetherbound-tools\godot-4.7\Godot_v4.7-stable_win64_console.exe' --path . --rendering-driver opengl3 --resolution 1280x720 --script tools/capture_long_water_bank_identity.gd
```

The harness applies each authored clock before freezing `WorldLook`, hides both
`PlaygroundHUD` and the independent `Water/SubmersionOverlay`, and seats player
and camera from live `ground_height_at` samples rather than underground parking.

## Validation before capture

- `test_long_water_visual_identity.gd`: **2 tests, 101 assertions, 0 failed**.
- `test_band_content.gd`: **6 tests, 1,433 assertions, 0 failed**.
- Combined: **8 tests, 1,534 assertions, 0 failed**.

## R3 production evidence

- `01-axis-arrival-day.png` / `02-axis-arrival-night.png`: valid, grounded
  ordinary arrival with water visible beside the road. **POLISH**: road and
  trees remain co-subjects and the pale wall stays straight; the raised camera
  clips the avatar's head at the bottom edge.
- `03-overlook-west-day.png` / `04-overlook-west-night.png`: no trunk
  obstruction and a real along-bank view. **POLISH**: the near crown rocks and
  continuous far wall dominate more than the water's length.
- `05-overlook-east-day.png` / `06-overlook-east-night.png`: **PASS for named
  identity and composition**. The reach recedes through a wooded bend toward a
  distant tower, with open water as the clear subject and no blocking trunk.

Incidental evidence defect: the ordinary avatar raises both arms during later
frames as part of its live idle/settle state. It does not affect terrain or
traversal judgment, but should be held neutral in any final commercial capture.

Manifest: complete, 6 frames, 0 failures. All player Y values remain exactly
0.35 m above their sampled live terrain surfaces.

## Rejected production candidate r1

The first 6/6 production batch is retained as negative evidence. Enlarging
single rocks on the steep transition produced embedded/floating wall pieces,
not natural shelves; the arrival camera underframed the water, its first player
fell while collision streaming caught up, and the overlook was blocked by a
right foreground tree. That geometry was removed. Candidate r2 uses separate
flat-bed toe and plateau-rim seating, freezes player locomotion at each sampled
surface, raises the arrival eye, and shifts the overlook away from the trunk.

R2's 6/6 batch proved the ground seating and player fix, but the perpendicular
cross-section still read as an engineered canal and the shifted cameras found
the same two trunks: one filled the centre of 05/06 and one filled the right
edge of 03/04. R3 therefore adds one r6 camera keyhole overlapping the existing
r23 opening and recomposes the evidence along the water's west/east axes. The
goal is to prove a long natural corridor, not disguise the straight cross-section
with a flattering lens; all trunk occlusion remains a failure condition.
