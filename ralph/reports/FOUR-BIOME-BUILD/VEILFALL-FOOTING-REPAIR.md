# Veilfall ROAD Footing And Passage Repair

Date: 2026-09-08
Scope: `veilfall_exploration_spine` ROAD sites only. This proves production
spawn admission and local populated crossings, not whole-route visual or
continuous-play closure.

## Baseline

Production probe log:
`C:/Users/mattj/AppData/Local/Temp/water-road-footing-veilfall-baseline.log`

- The strict all-site probe found 15/24 ROAD sites with neither authored member
  admitted: 03, 05, 06, 07, 08, 10, 12, 14, 16, 17, 18, 19, 20, 22 and 24.
- Their centres were 5.168-5.490 m from the nearest route segment on the steep
  graded shoulder. Individual footprints had 6-8 missing rays and minimum
  observed normals of 0.042-0.172; the nine other sites admitted 2/2 and were
  left unchanged.

## Repair

The 15 rejected centres moved to the same side of their authored route sample,
one metre into the supported route core. Counts, tables, rolled species, creature
sizes, radii, activation distances and footing tolerances are unchanged.

The first repaired production run is recorded at
`C:/Users/mattj/AppData/Local/Temp/water-road-footing-veilfall-repaired.log`.
It proved the new footprints but exposed two separate passage defects:

- Opposite-shoulder sites 19 and 20 share the exact same route projection.
  Their one-metre insets were only 2.0 m apart, so existing wild/wild clearance
  admitted 23/24 sites and only 1/2 members at site 20. Site 20 was therefore
  staggered eight metres longitudinally while retaining the same one-metre,
  same-side route-core offset.
- Water owns a separate `_spawn_available_sites` implementation and had omitted
  Cloudreach's narrow ROAD/player collision exception. The populated 24 m walks
  consequently passed 12/15 and failed at the narrow 19/20/22 corridor. Water now
  applies the reciprocal exception only to unnamed ROAD ecology. Terrain,
  wild/wild, attack and ordinary/named encounter collisions and collision masks
  remain unchanged.

## Validation

Final production log:
`C:/Users/mattj/AppData/Local/Temp/water-road-footing-veilfall-final.log`

Command: `Godot_v4.7-stable_win64_console.exe --headless --path . --script
tools/probe_water_road_footing.gd -- --route=veilfall`

- Exit 0; clean `ERROR` / `SCRIPT ERROR` scan.
- Strict production admission: all 24 Veilfall ROAD sites spawned exactly 2/2,
  with no failed site.
- All 15 repaired centres had zero missing footprint rays. Their measured
  minimum normals were 0.802 or better, above the unchanged 0.7 requirement.
- Real-stick traversal across a populated 24 m segment passed at every repaired
  site: 15/15, including the previously blocked 19, 20 and 22 crossings.
- `test_water_encounter_residency.gd`: 3 tests, 16 assertions, 0 failures. The
  regression drives Water's production admission loop and proves the exception
  is reciprocal and ROAD-only; ordinary and named encounters stay physical and
  ROAD collision layer/mask values do not change.
- `test_road_creature_visibility.gd`: 6 tests, 272 assertions, 0 failures.
- JSON parse, GDScript parser checks and `git diff --check`: passed.
