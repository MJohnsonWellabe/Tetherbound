# Salt Crown production footing repair — 2026-09-08

Scope: ROAD sites 01/02/03/05 on `salt_crown_exploration_spine`.
Four coordinate pairs (`position` and `island_local_offset`) changed; counts,
tables, species, sizes, spawn radii and production support tolerances did not.

The original sites were 5.44–5.47 m from route centre, beyond the graded 3 m
flat half-width. Production footprint probes found 2–4 missing support rays and
surface normals below 0.7. The new centres are 1 m off the route, preserving
their side of the road. The largest measured footprint is 1.594 m body radius
plus 0.15 m margin, fitting inside the graded strip at those centres.

Validation on the PR branch:

- `tools/probe_water_road_footing.gd`: exit 0 in 39.827 seconds. All seven
  Salt Crown ROAD sites admitted exactly two production members, with no site
  failure. All four repaired populated segments passed 24 m real-stick walks.
- `test_road_creature_visibility`: six tests, 272 assertions, zero failures.
- Parser, JSON and diff checks passed.
- Runtime log inspected during integration:
  `C:/Users/mattj/AppData/Local/Temp/water-road-footing-salt-crown-repaired.log`.

The probe uses explicit starting poses. This is production admission and local
walkability evidence, not continuous chapter or visual acceptance. Ordinary
Salt Crown wild sites 011/012/013 still warn about footing; Sluice ROAD sites
remain under investigation. The whole-route forward-view requirement remains
open. No blind visual verdict is asserted by this functional repair.
