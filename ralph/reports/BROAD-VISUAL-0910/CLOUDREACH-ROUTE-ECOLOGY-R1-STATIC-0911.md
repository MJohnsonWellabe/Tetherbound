# Cloudreach Route Ecology R1 — static candidate (2026-09-11)

## Evidence diagnosis

The current production baseline and the COVER01, FOOTPRINTS01, and UPLAND-MATERIAL01 diagnostics agree on the gap: Cloudreach technically contains very high grass-instance counts, but its traversed middle distance still reads as large flat green lawns, sparse wiry plants, repetitive cliff/turf contacts, and weakly dressed travel between named locations. The grass disposition explicitly retires more blanket density, tuft tuning, local-clearance, footprint, and blurred procedural-colour attempts. The next useful unit is a composed mid-distance vegetation mass with a bounded performance budget.

## Candidate

`cloudreach_route_verges.gd` adds a separate collisionless post-build layer derived from the canonical route polylines. It evenly samples at most 16 stations on each grounded route (157 planned stations under the current data), preserves the visible path centre, resolves final placement through the production `_route_detail_ground` support query, respects settlement clearances, and batches six asset families into MultiMeshes. Each usable station gets irregular low grass masses, a bush or flowering accent, and an outer embedded scree tooth. This supplies an authored foreground-to-midground ladder and breaks the most repetitive turf/cliff contact without increasing the already-large blanket tuft field.

No route points, landmark coordinates, collisions, encounter data, progression flags, harvests, or Fly access are changed. The Fly-only `windscar_to_high_roost_flight` route is intentionally excluded.

## Expected biome-wide reach

The plan covers all ten grounded routes: `arrival_gate_road`, `lower_cliff_road`, `lower_overlook_loop`, `broken_causeway_main`, `causeway_west_loop`, `windscar_floor_loop`, `windscar_counterweight_pass`, `upper_plateau_circuit`, `upper_summit_road`, and `summit_overlook_loop`. It therefore affects approaches and connective views around Realm Gate Crag, Galefoot Waycamp, Three Bells Bridge, Broken Skyroad Arch, Windscar Beacon, the grounded Flight Aerie vicinity, Cliffhold, Old Wind Observatory, Summit Eyrie, and Stormward Overlook. It does not dress the airborne Aerie-to-High-Roost corridor.

## Honest boundary and pending proof

This is a bounded shared composition improvement, not a macro cliff resculpt. It can reduce crude cliff repetition where scree meets the route shoulder, but it does not replace the large cliff-wall mesh. Commercial PASS still requires production route captures at the Gate, Three Bells, Windscar, Cliffhold, Observatory, and Summit; blind review; and a frame-time/load measurement. No Godot, headless run, render, staging, or commit was performed while the render lane was occupied.
