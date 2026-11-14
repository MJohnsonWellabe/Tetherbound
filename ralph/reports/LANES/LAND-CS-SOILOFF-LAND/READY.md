STATUS: land

# tb/land-cs-soiloff-land: Stormwood wet-soil discs not built (F41#22, F41#24)

**Verdict:** GPU High, `ralph/reports/GPU-PASS/1108/G-land-cs-soiloff.md` on tb/judge 810c894f2 (confirming batch, r 0.908, RMSE 0.58): forest + giant stands F41#22 5.33 -> 6.03 (+0.70, 3/3) and F41#24 5.29 -> 6.23 (+0.94, 3/3; cleanliness PRESENT -> PARTIAL). The glass, rod_line and stormheart stands are level (3 ties). The black glare slabs ("void planes ... a rendering bug") are gone. Five-stand reads on that panel: F41#22 6.02 -> 6.30, F41#24 6.00 -> 6.38.

**Flag:** `data/config/stormwood_ground_finish.json forest_layers_1113`, ON with `_why_on`; `layers.wet_soil.enabled` false.

**Files (4):**
- `scripts/world/stormwood_ground_cover.gd`: `forest_layers(finish)` patches the forest layers by name; OFF or no patch returns the shipped layers unchanged (the only change to this file).
- `data/config/stormwood_ground_finish.json`: the flag ON.
- `tests/test_stormwood_forest_layers_flag.gd` (new): ON pin (verdict file and score; wet_soil not built), OFF keeps both layers, a by-name patch applies without mutating the config.
- this READY.md.

**Scope:** presentation only: the 1,400 wet-soil discs are not built. No terrain, collision, route or scatter-state change, so no route smoke.

**Tests run (14 Nov, on this branch):** seven Stormwood ground and candidate test files in one run: 45 tests, 233 assertions, 0 failed (`test_stormwood_forest_layers_flag`, `test_stormwood_root_finish`, `test_stormwood_fleck_round`, `test_cause_stormwood_candidates`, `test_vis_stormwood_judged_on`, `test_stormwood_wet_earth_fine_rain`, `test_storm_cams_candidates`).

**Not a close.** Next asks (3/3): open canopy gaps at the forest and giant stands so the storm sky reads and the phases differ; denser foliage than the pale see-through leaf cards at rod_line; break up the flat striped ground at glass; a salmon-pink bear-like creature at the forest stand's left edge (creature coat, LANE-BEINGS). Stormwood world rows are now LANE-PLACES'.
