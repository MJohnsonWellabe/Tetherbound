# F39#4 — Veilfall reads at distance and up close

- Commit under test: 826d273c3
- Renderer: software renderer (Compatibility) = Low preset; Xvfb + llvmpipe, opengl3, 1920x1080
- Current Veilfall flags (data/config, at 826d273c3): `water_veilfall_falls_visual.json` enabled=false (runtime-on only with `--f39-candidate`); `water_current_flow_visual.json` enabled=false; `water_veilfall_silhouette_visual.json` enabled=false (P2-010 candidate); `water_shore_presentation.json` enabled=false (P2-008 candidate); `water_veilfall.json` far_relief / current_flow / interior props (pump_station, sluice_gates, heart_banner) / crag all enabled=true; `water_offshore_visual.json`, `water_visual.json` enabled=true.

## Distance matrix: ERROR (tool failure on current code)

`xvfb-run ... --resolution 1920x1080 --script tools/capture_f39_catalogue.gd -- --biome=water --times=day,night --preset=Low --source-commit=826d273c3dbdcb1002034812041b1dfb59d84120 --seed=2042 --f39-weather=clear --subset=veilfall --output=<dir>` → exit 1, 0/20 frames, 20× `ERROR: F39 production weather service unavailable` (tools/capture_f39_catalogue.gd:95 `_pin_time`: `_weather == null or not _weather.has_method("set_weather")`). Receipt: matrix_failed/. (A first attempt with a short SHA was rejected by the bootstrap's 40-hex check — this lane's argument error, not counted.)
Fallback (base `tools/capture_lookdev_catalogue.gd` with the same subset) was queued but not run before this lane was retired.
Related evidence: ../F13-5 veilfall_1..3 distance frames — code-blind judge: "None of the three frames shows a mountain, cliff, waterfall or anything white-falls-like" (FAIL).

## Close-up interior: captured, not judged

`xvfb-run ... --resolution 1920x1080 --script tools/capture_veilfall_interior.gd -- --out=<dir>` → exit 0; interior/{intake_gallery, pump_hall, sluice_crossing, heart_chamber_entry, heart_chamber_crystal, heart_chamber_banner}.jpg + frames.json. No code-blind judge run (lane retired before judging).

## Verdict: ERROR (distance matrix tool fails: weather service unavailable; close-up frames unjudged). High/Medium: needs native GPU (Codex F26 lane).
