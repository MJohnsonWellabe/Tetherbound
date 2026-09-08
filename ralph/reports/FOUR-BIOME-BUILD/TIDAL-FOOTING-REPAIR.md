# Tidal Cradle ROAD Footing Repair

Date: 2026-09-08
Scope: `tidal_cradle_exploration_spine` ROAD sites only. This is spawn-footing and
local populated-crossing evidence, not whole-route visual or continuous-play closure.

## Baseline

Production probe log:
`C:/Users/mattj/AppData/Local/Temp/water-road-footing-tidal-baseline.log`

- Sites 02 and 03 reproduced the warnings seen in the Settings teleport and Water
  runtime logs. Both members at each site failed production admission.
- The strict all-site probe also found site 08 failing both members.
- Sites 01, 04, 05, 06, 07 and 09 admitted 2/2 and were left unchanged.
- Sites 02/03 had 4–6 missing footprint rays and minimum ground normals of
  0.349–0.412. Site 08 had no missing rays, but 6/9 samples were below the required
  0.7 normal, with a minimum of 0.541.
- The three centres were 5.375–5.489 m from their nearest route segment, on the
  graded shoulder rather than within the flat route core.

## Repair

Only positions and matching island-local offsets changed. Counts, tables, species,
activation distances, roam radii, creature sizes and footing tolerances are unchanged.

| Site | Old route offset | New world position |
| --- | ---: | --- |
| 02 | 5.489 m | `(625.571, 36.496, 1421.962)` |
| 03 | 5.489 m | `(635.381, 37.762, 1439.459)` |
| 08 | 5.375 m | `(694.354, 33.069, 1686.411)` |

Each replacement preserves its original side of the route and sits one metre from
the nearest authored polyline segment.

## Validation

Production repaired log:
`C:/Users/mattj/AppData/Local/Temp/water-road-footing-tidal-repaired.log`

- Exit 0; clean `ERROR` / `SCRIPT ERROR` scan.
- Strict production admission: all nine Tidal Cradle ROAD sites spawned exactly 2/2,
  with no failed site.
- Repaired footprint samples: zero missing rays and zero normals below 0.7. Minimum
  normals were 0.998 at sites 02/03 and 0.977 at site 08.
- Real-stick traversal across a populated 24 m segment passed at sites 02, 03 and 08.
- `test_road_creature_visibility.gd`: 6 tests, 272 assertions, 0 failures.
- `tools/probe_water_road_footing.gd --check-only`: passed. The probe now fails closed
  on an absent route/polyline, empty site prefix or missing declared repair target.
