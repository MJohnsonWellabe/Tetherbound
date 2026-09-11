# Windscar Beacon readability continuation — 2026-09-10

Status: retained. The production Windscar landmark now reads as a complete open
arch in its canonical gameplay composition, and one measured procedural tree no
longer occupies its aperture. This is a bounded visual improvement, not an overall
Cloudreach or commercial-visual acceptance claim.

## Problem and retained correction

The exact stand 05 baseline showed only the lower portions of the prior 24 m arch.
Its crown and signal were outside the frame, so the two native-textured uprights
read as oversized tree trunks. `RouteTree000_4_0`, measured at
`(-249.3687, 497.2246, 2687.029)`, also stood 2.867 m from the beacon centre and
filled the opening.

The retained config changes only the arch's vertical scale from `8.0` to `3.2`.
The installed `Wall_Arch.gltf` therefore presents a 9.6 m crown in the unchanged
camera while keeping its 8.0 m width and a measured 5.8747616 m minimum passage
height. The beacon centre, heading, 15 m forward offset, depth, four foundations,
collision construction, pickup ring, light, route and camera are unchanged.

Cloudreach nature config now carries one 7 m tree exclusion centred on the actual
beacon at `(-248.64766, 2689.80420)`. Both regional and route tree placement honor
the same data-driven exclusion. The measured obstruction is inside; the next-nearest
measured landmark tree, 19.07 m away, remains outside. Rocks and ground cover are
unchanged.

## Visual evidence

- baseline canonical day:
  `.artifacts/visual-audit-0910/cloudreach-windscar-current/cloudreach__windscar_ravine__05__windscar_beacon__day.png`
  (`00E1505D6AF5CB3D3AF5B10C008289DABC4775E0FA0F5773E627DA1BD26CD672`)
- retained canonical day/night:
  `.artifacts/visual-audit-0910/cloudreach-windscar-clear-candidate01/`
  (day `252AD98019F37CEE09E1E9AC2AC7DEF2C2B44C865EC597B8BE343982E6FF89C0`;
  night `ED81DE10B2A3E84A952238FA105B0D502E995E1AD0A379BD7E5D0CC6C780934F`)
- ordinary grounded full-silhouette frame:
  `.artifacts/visual-audit-0910/cloudreach-windscar-readability-final/windscar-beacon-ordinary-full-silhouette-day.png`
  (`D847A4BAEF971FD363DD3C8A11FD385F685FF1EF7D7FACB983976FC1A2CED6DC`)

The canonical pair uses the exact production player position, heading, CameraRig,
70-degree FOV, HUD and day/night presets. It shows the full arch face and an open
horizon where the tree previously stood. The supplemental frame uses ordinary look
input from a grounded point 11.55 m back and visibly contains the complete physical
arch.

## Verification

Focused test evidence is retained at
`.artifacts/broad-visual-0910/runs/cloudreach-windscar-readability-unit/`:

- 3 tests, 0 failed, exit 0;
- two installed arch frames, four grounded feet and ten matching solid colliders;
- maximum support-contact delta `0.0000132256` m;
- minimum pickup-to-ground-solid clearance `6.584853` m;
- passage `7.99999968` m wide by `5.8747616` m high;
- the measured obstructing tree is inside the exclusion and the 19.07 m comparison
  tree is outside.

The production ordinary-stick proof is retained at
`.artifacts/broad-visual-0910/runs/cloudreach-windscar-readability-world/`, with its
manifest beside the three frames. All three movement legs passed grounded with zero
confined resets: 11.55 m to establish the approach, 11.08 m back to the anchor, and
19.11 m through the aperture. Terrain contact passed at `0.00001221` m.

That helper still exits 1 for its known conservative aggregate-AABB assertion. The
rotated pair's empty rectangular corner projects below the viewport
(`y=572.26..994.66`) even though the actual thin arch is visibly contained. This is
not reported as a clean automated full-bounds pass. The only other engine diagnostic
is the pre-existing `cr_candy_broken_route_good_07` no-surface warning.

## Withdrawn signal mechanism

Two signal-only passes were not retained. Amplifying the existing torch's flame
planes, then seating them lower into the crown, produced no material gain because
the production location/objective overlays cover that centreline in the canonical
frame. Signal scale and placement are restored exactly to their prior values. A
future signal treatment must use a different authored composition; size or vertical
offset should not be retried.

## Exact production scope

- `data/config/cloudreach_windscar_beacon_visual.json`
- `data/config/cloudreach_visual.json`
- `scripts/world/cloudreach_world.gd`
- `tests/test_cloudreach_windscar_beacon_site.gd`

