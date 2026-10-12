# P2-011 Drowned Garden terraces — claude-r1

Candidate: `garden_terraces_claude_enabled` in `data/config/water_garden_terraces_claude.json` (shipped **OFF**).
Builder `scripts/world/water_garden_terraces_claude.gd` (extends the contour r2 support); hooks in `water_world.gd`
(build, hide the old lure courses, collapse island scatter and add grass-field clearances over the levels).

Rebuild, not an iteration of ab334143/971dc2be: Codex's three 8 m bands left raw sand strips between them, so the
levels read as ramps and wedges. Now there are four continuous, truly flat 9 m levels (each top = highest sampled terrain in
its band + 0.15 m), each running from its own retaining wall to the next, with switchback ramps and the existing
entry from dry ground. Collision and the bounded floor index reuse Codex's support code via a pure
extraction (`water_garden_contour_r2.gd::_build_support`). Dressing is installed assets only: medieval
UnevenBrick masonry, RockTrim coping, Prop_Vine, stylized_nature planting (no red: Bush_Common and TwistedTree
foliage is red and is excluded), meadow-grass lawn, forest-floor mulch beds, an uphill retaining wall and end cheek
walls, and installed `water.gdshader` standing water over the lowest level that runs into the ramp feet.

Proof `before-after-Low.jpg`: Low/Compatibility 1280x720, production camera + HUD. Three ordinary-camera stands
(`tools/capture_named_stands.gd`) and the catalogue landmark close (`tools/phase2_capture_locations.gd`).

Walk/refactor evidence `walk-probe.txt` (`tools/garden_terrace_walk_probe.gd`; player capsule r0.4 h1.8, 45 deg, snap 0.4):
- The beach → entry ramp → every switchback → top level route PASSES; the pool-edge walk PASSES; the open-dune control walk is unchanged.
- Straight end-to-end lines along some levels stop where a ramp crosses them, as a raised slope or a cut trench. This is by design and is informational.
- Codex's contour support with its flag ON is **byte-identical** before and after the refactor: 6 bodies of collision faces and meshes, and 1,200 floor samples.

Tests (flag ON): `--only=test_water_garden_records,test_water_lead_map_pins` gives 15 tests, 521 assertions, 0 failed.
