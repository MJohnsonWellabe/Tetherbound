# Sluice ROAD footing repair — 2026-09-08

Four production sites (01/02/03/05) failed admission on the graded route's
5.32–5.44 m shoulders. Footprint probes found missing rays and surface normals
as low as 0.371. The coordinate-only repair moves each centre to a 1 m route
offset on its original side. Counts, species, radii, scale and production support
rules are unchanged.

`tools/probe_water_road_footing.gd -- --route=sluice` now exits 0 in approximately
73 seconds. Its strict all-site verdict records exactly 2/2 production members
at all six Sluice ROAD sites, and populated 24 m real-stick traversals pass at
all four repaired segments. The default probe remains Salt Crown for repeatable
earlier evidence. Focused road tests pass 6 tests / 272 assertions; parser,
JSON and diff checks pass.

Integration inspected the log at
`C:/Users/mattj/AppData/Local/Temp/water-road-footing-sluice-repaired.log`:
six successful `WATER_PRODUCTION_SITE` rows, four successful `WATER_PLAYER_PASS`
rows, and `WATER_PRODUCTION_SUMMARY` with an empty failures array.

This probe uses explicit poses and proves local admission and walkability, not
continuous chapter or blind visual acceptance. Cradle 02/03, Veilfall 03 and
ordinary wild footing warnings remain open for investigation; the whole-route
forward-view requirement is not claimed closed.
