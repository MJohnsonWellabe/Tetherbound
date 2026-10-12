# P2-010 Veilfall silhouette — claude-r1

Candidate: `crag_kitbash_enabled` in `data/config/water_veilfall_crag_kitbash.json` (shipped **OFF**; coordinator enables).
Builder `scripts/world/water_veilfall_crag_kitbash.gd`, shader `shaders/water_veilfall_crag.gdshader`, hook in `water_veilfall.gd`.

New approach (not an iteration of r1–r3 blockouts): a crag kitbashed from INSTALLED rock meshes —
`stylized_nature/Rock_Medium_1-3`, `cloudreach/limestone_spire_1-3`, `nature/rock_tallA` — instanced on a
massif measured against the real Veilfall terrain (rock mantle, radial buttress spurs, ledge steps, raised peaks),
with a notch following the accepted r2 water path (r2 water/spray reused unchanged), the authored approach
corridor, entrance stand and passage gorge kept clear, and the entrance curtain limited to 380 m draw range.
Wet-dark / weathered-crown / ledge-moss material with reduced fog. No meshes generated, no Meshy.

Render-only: no terrain, collision, actor, route, gate or camera change. Old candidates stay OFF.

Proof: `before-after-Low.jpg` — Low/Compatibility 1280x720, production camera + HUD, catalogue route sightings
(sluice bridge stock approach, Drowned Garden whole profile, First Shore far) and the catalogue cascade close.
Tools: `tools/phase2_capture_routes.gd --frame=...`, `tools/phase2_capture_locations.gd --subset=the_veilfall_cascade`.

Tests (flag ON): `--only=test_water_veilfall_geometry,test_veilfall_far_crag_presentation,test_veilfall_fall_surface,
test_water_veilfall_arena_bounds,test_water_veilfall_interior_props` → 10 tests, 2421 assertions, 0 failed.

Code-blind judge (images + defect line only), round 2: **PASS** — "the near-geometric cone silhouette is gone from
every distance"; no blocking artifacts. Round 1 FAILed on a dark core slab at the entrance close view (fixed:
passage gorge cleared, core only where fully raised) and a white curtain card at distance (fixed: draw range).
Non-blocking polish noted: some smooth terrain visible between columns at the stock approach; slab-sided
near flanks; repeated column shapes.
