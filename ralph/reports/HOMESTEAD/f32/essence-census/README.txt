F32#2 essence nodes: one or two per type per biome, mostly off-route, respawn on a configured timer.

Count and timer: tests/test_f32_essence_census.gd (CI, 3 tests / 204 assertions). 32 nodes, one per type per
  live biome, each a registered renewable site with respawn_days = essence_nodes.json respawn_days (3, host
  world day). Respawn mechanics: test_foundation_resources (next_ready_day; stock regrows only on host day).
Off-route: route_distance.py (route_distance.txt) and the same rule in the CI census. Main routes per realm
  are documented in the script. Threshold off_route_minimum_m = 15.
  BEFORE: Meadows 0/8 (all eight in the starting village; 5 of them also failed controller reach/grounding),
    Cloudreach 5/8 by recorded numbers, but 3 nodes (ground, water, ice) were not placeable as authored: the
    production resolver snapped ground 130 m and water 2.2 km onto other paths, and ice found no surface.
  CHANGES (data/config/essence_nodes.json):
    Meadows: ground and water stay village-side as the early on-ramp; air, electric, fire, dark, ice and
      psychic move to band1 harvest anchors order:1040/1001/1041/1042/1005/1002 (+6 m), 69-568 m from paths.
    Cloudreach: ground -> gale_fiber_causeway [0,6]; water -> cliffglass_ravine [0,6]; air -> ravine [-6,0];
      fire -> heartwood_west [0,-6]; ice -> latch_landing [-6,0]. Each was picked from
      cloudreach-anchor-probe.txt (production placement_verdict, drift < 1 m).
    Recorded placement.main_route_distance_m/off_route are recomputed for all 32 (--write).
  AFTER: Meadows 6/8, Cloudreach 8/8, Stormwood 8/8, Tidewake 8/8 off-route.
Real path: tests/smoke_f32_material_sites.gd --realm=<realm> --essence. Every one of the 32 nodes: production
  placement, controller approach >= 3 m, prompt, host transaction, owner save + ACK, exact essence + attuned
  gain on disk, receipt, consumed stock (revision 1, generation 2). All four realms exit 0
  (<realm>-essence-report.json).
  Disclosed fixtures (Stormwood): world flag stormwood:rootgate_released for the three Deepwood nodes; the
  saved storm clock is set inside the Break phase for the air node's charged seam. The host still applies
  both rules.
Regression: contention smoke still exit 0 / 68 PASS on the relocated psychic node; 65 related unit tests pass.
Verdict F32#2: PASS.

== Review follow-up ==
Meadows main routes now also include terrain_playground spokes.routes[].road (the roads out across the
bands). Recomputed: fire 50.2 m, dark 65.2 m, ice 251.8 m, psychic 462.9 m; Meadows still 6/8 off-route.
All 32 nodes' placement.terrain_and_player_path_proven and the catalogue status now record the
real-path proof above.
