# SHARED-ART close-1020 lane note (tb/shared-art)

Renderer for every capture here: Godot 4.7 opengl3 / Compatibility (Low), Mesa llvmpipe CPU under xvfb, 1920x1080. CPU-provisional bar: three-judge Bar A mean >= 6.7 with the defect called FIXED; a GPU pass must later confirm 7.5.
Judges: three fresh code-blind subagents per round, shown only the neutral sheet and docs/reference images; A/B randomised per row, key withheld until verdicts.

## Ledger
| Row | Biomes | Status | Best after mean (Bar A) | Before mean | Rounds |
|---|---|---|---|---|---|
| P2-017 normal creature scale | meadows;stormwood;cloudreach | open | 6.17 (r1) | 5.27 | 1 |
| P2-030 shiny creature finish | tidewake;stormwood;cloudreach | open (FIXED verdict, score below bar) | 6.33 (r1) | 4.00 | 1 |
| P2-018 shiny palette distinction | meadows;stormwood;cloudreach | pending r1 | | | |
| P2-113 catch camera distance | tidewake;cloudreach;stormwood | pending | | | |
| P2-060 catch effect finish | all four | pending | | | |
| P2-033 ground pickup identity | all four | Meshy batch 1 received (tb/meshy-props 0a7e3b01d) | | | |
| P2-055 named character silhouettes | stormwood;tidewake;meadows | not started | | | |

## P2-017 round 1 (21 Oct 2026, ~12:30 CT)
- Change (candidate 3862138bf): grow-only small class 1.90-2.15 m -> 2.30-2.55 m (13 species, height+radius via tools/art_pipeline/creature_scale_ladder.py targets); test floor 1.90 -> 2.30.
- Before: main 29cfa6371. Capture: `tools/art_pipeline/capture_f36_poses.gd -- --scale-only --species=<13 sighted species>` (level stage, trainer 1.80 m ruler beside each creature). Biome-neutral stage covers the sighted species of all three listed biomes; scale is a per-species fact, so one set covers every biome (coordinator ruling).
- Judges (better set = candidate in every changed row, all three): Bar A after 6.2 / 6.0 / 6.3 = 6.17, before 5.6 / 5.0 / 5.2 = 5.27; Bar B after 4.5 / 5.0 / 5.6. Verdict PARTIAL x3.
- Remaining: Pipwing, Sparkit, Riftfrill bodies only marginally above the trainer (ears/crests do the work); Bramblebun body short; Glimmermoth and Skyrill core bodies low; Stormraven/Stormtrail read near-black; Trailpup style mismatch (new art).
- Next: round 2 grows Pipwing/Sparkit/Riftfrill(+Paddlenewt, kept equal to its aspect)/Skyrill further; Bramblebun to 3.0 m to match Creatures PR #698.

## P2-030 round 1 (21 Oct 2026, ~13:00 CT)
- Change (candidate 4cb46d286): shinies with no authored colourway used a flat magenta multiply (creature_body SHINY_PLACEHOLDER_TINT 2.6/0.12/2.6). Replaced by a pattern-preserving hue shift in shaders/creature_surface_finish.gdshader (red/magenta-safe), configured in data/config/creature_surface_finishes.json `shiny_fallback`; per-species rows for weak authored shinies; dark-coat repaint fix.
- Before: main 29cfa6371. Capture both sides: `tools/phase2_capture_creatures.gd -- --biome=<water|stormwood|cloudreach> --poses=idle,shiny_idle` (production world, trainer, camera; seed 2042). Sheets: normal | A | B per species, A/B shuffled per row; 26 rows (8 Tidewake incl. the four catalog sightings, 10 Stormwood incl. five sightings, 8 Cloudreach incl. four sightings).
- Judges: candidate side chosen on every differing row by all three except Tidewake Cannonback/Tidecoil (my shift regressed the authored Cannonback shiny; reverted in round 2). Verdicts: FIXED x3 for T and S; C FIXED x2, PARTIAL x1 (Tempestwing near no-op).
- Bar A overall (better/after vs worse/before): 6.0/4.6, 6.4/3.1, 6.6/4.3 -> after 6.33, before 4.00 (+2.33). Bar B after 6.0-6.5 per sheet.
- Remaining: shifts converging on cyan (cause found: default accent repaint on shift rows; fixed 0028273c9), weak shifts (Aquaryn, Riptusk, Tempestwing), oxblood-adjacent rust on Torrentoad (guard widened), Stormwood low light (pearlescent rim sheen added).
