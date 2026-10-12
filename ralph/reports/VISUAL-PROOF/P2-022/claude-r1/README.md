# P2-022 Summit aviary — claude-r1

Candidate: `aviary_claude_enabled` in `data/config/cloudreach_aviary_claude.json` (shipped **OFF**).
Builder `scripts/world/cloudreach_aviary_claude.gd`, hook after the Astra blockout in `cloudreach_world.gd::_build_summit_stronghold`.

New approach (not the crown arcade nor the Astra mantle): the existing 9 m drum becomes the base storey and a
solid 13 m masonry clerestory storey rises above it, outside the lattice dome (20 arched windows with pale
arched heads and sills, string course, cornice, balustraded parapet terrace), so the dome becomes the crown of a
layered stone sanctuary. An open colonnade (pillars, lintels and lanterns) runs along both edges of the existing
paved approach to the arena court and joins drum and court into one site. Night: window glass is dark by day
and glows amber as the live Sun dims (`WindowGlowDriver`). Installed quaternius_fantasy `Lantern_Wall` lanterns flank every
arch, with unshadowed entry pools, an interior fill and a colonnade walk light.
Uses the existing aviary masonry materials and installed meshes only. Render-only, above the 9 m drum top or off the
paving: no collision, floor, route, spawn or persistent state.

Proof `before-after-Low.jpg`: the three catalogue sightings (day approach, day close, night approach), production
camera + HUD, Low/Compatibility 1280x720 (`tools/phase2_capture_locations.gd --subset=11__summit_eyrie`).

Tests (flag ON): `--only=test_cloudreach_aviary_architecture,test_cloudreach_summit_paving,test_cloudreach_summit_eyrie_catalogue`
gives 8 tests, 152 assertions, 0 failed.
