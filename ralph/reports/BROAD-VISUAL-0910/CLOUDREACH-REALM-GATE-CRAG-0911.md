# Cloudreach Realm Gate Crag visual pass — 2026-09-11

## Result

Realm Gate Crag no longer uses a catalogue stand inside its own gate or reads as
a small castle balanced above an oversized dark rock drum. The installed stone
gatehouse is seated into the south crag face at the real arrival-road tier. Its
complete arch, paired crenellated towers, blue-and-gold banners, realm-heart
emblem and teal arrival beacons now form one road-facing threshold. The visual
layer adds no collision and preserves a 9.6 m clear route.

The exact Settings/catalogue row now uses the grounded approach at
`[-15.5, -202.0]` with a gate-facing heading, rather than the landmark centre at
`[0.0, -130.0]` that produced the cropped baseline.

## Production evidence

- Final evidence root: `shots/locations/cloudreach-realm-gate-crag-0911-r6/`
- Manifest: `shots/locations/cloudreach-realm-gate-crag-0911-r6/manifest.json`
- Result: `REALM GATE CRAG CAPTURE OK: 4/4`
- Renderer: production Compatibility renderer, NVIDIA GeForce RTX 3050 6GB,
  1280x800, production player/HUD/CameraRig and verified day/night WorldLook.
- Primary close view: `realm-gate-crag-approach-day.png` and
  `realm-gate-crag-approach-night.png`.
- Secondary arrival view: `realm-gate-crag-arrival-day.png` and
  `realm-gate-crag-arrival-night.png`.

Honest visual disposition:

- Primary approach: **strong keep / polish**. The complete portal, trainer scale,
  route, banners, emblem and beacons read immediately; no wall crop or stray
  floating glow remains.
- Secondary distant arrival: **polish**. The portal is identifiable and complete,
  but the crag and foreground route dressing still share emphasis at that distance.
  This is not claimed as a commercial-bar pass.

The capture computes the projected bounds of the above-ground gate structure.
All four frames passed with no behind-camera corner and at most a documented
16 px tolerance for invisible imported-mesh bounds. The former baseline crop was
hundreds of pixels and would still fail this gate.

## Validation

- `tests/test_cloudreach_realm_gate_crag.gd`: 3 tests, 35 assertions, 0 failed.
- `tests/test_cloudreach_world_data.gd`: 13 tests, 407 assertions, 0 failed.
- `tests/test_four_biome_debug_teleport.gd`: 8 tests, 1,047 assertions, 0 failed.
- `tests/smoke_playground.gd`: `smoke: OK`; the existing dummy-renderer
  `ERROR: Parameter "material" is null.` remained the only engine error and is
  unchanged by this Cloudreach visual pass.

The frames are review evidence, not a progression or full-chapter claim.
