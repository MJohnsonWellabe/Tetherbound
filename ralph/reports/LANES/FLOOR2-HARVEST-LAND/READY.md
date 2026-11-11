# FLOOR2-HARVEST-LAND: Stormwood harvest presence ships ON (F41#9)

STATUS: land

- **Branch:** `tb/floor2-harvest-land`, cut from `origin/main` (after #904).
- **Verdict:** LANE-SCOUT G-floor2-harvest-presence-confirm (`tb/item-scout-1108` df24a8ab4), GPU High: F41#9 5.81 → 6.81 over storm-glass, crown and glowmoss, +1.00, 3/3 judges.
- **What ships:** exactly the two files judged at `tb/floor2` f79383083, with the flag turned on.
  - `scripts/world/stormwood_harvest_runtime.gd`: nodes grow by `height_scale`; five or six small copies of the node's own model ring 0.8 of its footprint radius (no colliders); emissive glass and fungus caps glow a little stronger. The ground-light code path is still there but no `light_*` key ships, so no light is created.
  - `data/config/stormwood_harvest_hero2.json`: `floor2_presence.enabled` true with `_why_on` citing the verdict.
- **Test added:** `test_stormwood_harvest_nodes_1107.gd test_floor2_presence_ships_on_as_judged` pins the flag, the cited score, no ground lights, and copies that stay on the node's base without colliders.
- **Tests run on this branch:** `stormwood_harvest_nodes_1107, storm_cams_candidates, stormwood_harvest_cues, stormwood_harvests`: 28 tests, 9945 assertions, 0 failed.
- **Not included:** the Warrens `meadow_match` code (on the GPU), and every other `tb/floor2` candidate.
- **Row after landing:** F41#9 6.81 High. Medium not captured.

## Follow-ups from the confirming batch (a later close-out arm, not in this landing)
- No contact darkening under the nodes now the lights are gone: a ground contact shadow or AO decal.
- The copper reads as flat orange putty: it needs a metallic sheen.
- Glowmoss reads more as mushrooms than glowing moss.
- The ring of copies is even and reads as generated: irregular, partly buried clusters.
