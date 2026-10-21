# SHARED-ART close-1020 lane note (tb/shared-art)

Renderer for every capture here: Godot 4.7 opengl3 / Compatibility (Low), Mesa llvmpipe CPU under xvfb, 1920x1080. CPU-provisional bar: three-judge Bar A mean >= 6.7 with the defect called FIXED; a GPU pass must later confirm 7.5.
Judges: three fresh code-blind subagents per round, shown only the neutral sheet and docs/reference images; A/B randomised per row, key withheld until verdicts.

## Ledger
| Row | Biomes | Status | Best after mean (Bar A) | Before mean | Rounds |
|---|---|---|---|---|---|
| P2-017 normal creature scale | meadows;stormwood;cloudreach | open | 6.17 (r1) | 5.27 | 1 |
| P2-030 shiny creature finish | tidewake;stormwood;cloudreach | judging r1 | | | |
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
