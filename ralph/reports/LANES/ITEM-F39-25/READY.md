STATUS: land
BRANCH: tb/item-f39-25  HEAD: 92af3af1b9ddefefc99ad59cb9d2e0facc563bf7 (code and flags; this line was added in the next commit)

# ITEM F39#25 P2-032 map active region (LANE-TW)

- **Score:** GPU live 6.36. CPU quick judge r25b: base 7.38 -> candidate **8.11** mapped (+0.73). All three judges scored it up (raw 6.3/6.4/6.4 -> 6.6/6.8/7.2). Calibration: anchor RMSE 0.50, r 0.90.
  - Round dir: `ralph/reports/LANES/LANE-TW/qj/F39-25-a46982c0a52b-11071809/`.
  - The candidate sits above the top anchor (7.35), so its value is extrapolated. It needs the GPU pass (High, then Medium).
- **Flags turned ON** (`data/config/map.json`, `fog_veil`; scope client_presentation):
  - `keyboard_hint_one_device` true (new; `_why_on_keyboard_hint_1107`). `tab_map.gd::_refresh_controls_label` keyboard branch: Enter/left-click to place, E/right-click to remove, [Minus]/[Equal] to zoom. No pad letters remain.
  - `cloud_fog.tones.water` changed from #14324a/#3d6a85 (navy) to parchment #8c8266/#cfc3a0, the Meadows tones that scored 6.15 -> 7.18 on F38#4.
  - `chart_grid_1104.realms` gains "water" (survey grid and north mark on Tidewake).
- **Tests:**
  - Flipped: `tests/test_near6_ms_1104.gd::test_f38_4_chart_grid_ships_on`. Its realms assertion changed from Meadows only to `["meadows", "water"]`.
  - Added: `tests/test_player_map_markers.gd::test_f39_25_tidewake_chart_and_keyboard_row_ship_on`.
  - Both files pass: 5/5 and 9/9 tests, 0 failed.
- **Files touched:**
  - `scripts/ui/tab_map.gd`: the keyboard branch, and a per-realm `painted_chart.long_side_px_by_realm` override.
  - `data/config/map.json`
  - the two tests above
  - this report
- **Left OFF or not used:**
  - `painted_chart.long_side_px_by_realm` stays `{}` (inert). I inspected arm r25a (water 1024 px): it only stair-stepped the island shore and did not remove the blur. I did not judge it.
  - The blurry blob comes from 0% survey and cloud fog, not chart resolution.
- **Judges' remaining asks:**
  - Empty band below the hint row.
  - A clipped second glyph row at the bottom edge of the panel.
  - The hint row wraps ("View / Meadows").
  - At 0% surveyed the map body is still near-empty. One judge suggests a revealed coastline illustration.
  - The keyboard and mouse glyph pairs are small and busy.
- **Next idea:** trim the hint row to one line (drop the mouse glyphs, or move realm switching to the header chip row) and fill the empty band. At 0% survey, draw island coastlines as faint ink outlines on the parchment without revealing interiors. This is an OW3 question: coastline-only might count as revealing terrain, so check UX/WORLD before building it.
