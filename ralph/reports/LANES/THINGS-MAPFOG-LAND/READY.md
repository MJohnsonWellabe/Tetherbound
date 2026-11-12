STATUS: land

# THINGS-MAPFOG landing (Meadows map: warm parchment outside the surveyed area)

Branch `tb/things-mapfog-land`, cut from main 90ffeb66.

Verdict: `ralph/reports/GPU-PASS/1108/G-restoredsea-mapfog.md` on tb/item-scout-1108 be513ad9 (GPU High, confirming batch): F38#4 7.36 -> 7.81 (+0.45, 3/3; per judge 7.76, 8.03, 7.63). Base fog read as "dirty smudges"; the arm lets the groves and roads read.

Change (config only): `map.json fog_veil.cloud_fog.tones.meadows` `["#8c8266", "#cfc3a0"]` -> `["#bda77a", "#dccfa8"]`, with `_why_meadows_1112`. Tidewake's tones are unchanged.

Tests: older pin updated in `tests/test_near6_ms_1104.gd` (it pinned the old Meadows tones; it now pins the new ones and that Tidewake keeps its own). Ran test_near6_ms_1104, test_player_map_markers, test_alpha_pins, test_map_realm_view: 0 failed.

Not closed yet: meets the bar at High; needs a Medium capture, and LANE-SCOUT asks to pool it with the stricter panel that had main's map at 6.99. Defect still PARTIAL 2/3: most of the canvas is fog at 0% surveyed, and there is dead space below the legend.
