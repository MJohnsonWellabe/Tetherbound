# Articulated trunk and constructed-platform candidate

The branching comparison improved the outline but left a nearly constant-width
shell, flat wood surfaces and little inhabited detail. Both Stormheart boards
call for large organic trunk ridges, constructed platforms and warm fixtures
with blue/gold hanging cloth. This candidate addresses those visible gaps.

Two new nested flags, `ancient_trunk` and `built_detail`, default to false and
also require the existing presentation master. The articulated shell has broad
twisting outer ridges, a narrowing waist, uneven upper tips, smoother normals
and unwrapped bark UVs at a metre-based repeat. Its interior below185m retains
the existing clearance. The split entrance angles remain authored.

The construction pass reuses the upper wood strip from the installed
Quaternius Medieval `T_WoodTrim_BaseColor.png`, sampled without its stone or end
grain atlas rows. Existing floors and the later-created approach receive a
cut-plank material. Fascia, underside brackets and rail pickets dress existing
surfaces. Shaped blue cloth, gold hems/lightning embroidery and metal hangers
follow the saved boards; these are generated visual meshes, not new platforms
or barriers. No imported material, texture, floor, rail collision, encounter,
progression or production camera is changed.

Focused unit validation executes the enabled build and compares every physical
shape's stable parent/order, transform and geometry to the disabled baseline.
A separate deferred scene smoke mounts both trees at a translated origin,
adds the world-space approach after `build()`, compares the complete physical
signatures and checks its material and both world-space endpoints.
The unit suite tests whole bark triangles
clipped to the145–179m upper-floor slab, finite geometry, triangle winding and
master gating. A source-review finding about parent-space beam scaling was
fixed with local-axis scaling and oblique endpoint/orthogonality checks.
The clean focused run is 11 tests / 188 assertions, zero failures or diagnostics:
`.tmp/stormwood-phase2/ancient-trunk-tests-r6.log`
(SHA256 `8d41d5e1e5679b0f96e680661363a7c768733da9d04d8afb6faca284972177c3`).
The deferred smoke passes four assertions without diagnostics:
`.tmp/stormwood-phase2/ancient-trunk-scene-r1.log`
(SHA256 `eff48fb871b56cf589a1e8d2550e909408667fdffaabe0ca205ba353fac84ea7`).
Earlier r4/r5 summaries were invalid: scene-dependent calls ran before a usable
scene tree existed. Those logs do not count as passing evidence.

Required texture-import and creature-viewport suites pass 15 tests / 629
assertions (`.tmp/stormwood-phase2/ancient-import-framing.log`, exit 0), with
renderer/ObjectDB resource-leak diagnostics at shutdown; this is assertion
evidence, not a diagnostic-free engine run. Independent source reviewer
`stormwood_dialogue_review` found no remaining blocker in the candidate,
geometry/scene checks or raised-deck recorder. Native acceptance remains open.

These tests do not establish native visual quality, camera visibility, banner
occlusion, complete traversal or all dressing intersections. The upper-floor
triangle check covers bark only. The new `phase2_capture_stormheart_decks.gd`
stages the actual entry, spiral,150m core and174m chamber, verifies a collision
floor within a bounded ray interval, and records actual local player height,
floor collider and camera basis. It remains debug staging, not earned ascent.
Native exterior/deck comparisons and a fresh code-blind verdict are required
before either candidate can be enabled. P2-037 remains open.
