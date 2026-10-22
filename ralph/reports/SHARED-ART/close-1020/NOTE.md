# SHARED-ART close-1020 lane note (tb/shared-art)

Renderer for every capture here: Godot 4.7 opengl3 / Compatibility (Low), Mesa llvmpipe CPU under xvfb, 1920x1080. CPU-provisional bar: three-judge Bar A mean >= 6.7 with the defect called FIXED; a GPU pass must later confirm 7.5.
Judges: three fresh code-blind subagents per round, shown only the neutral sheet and docs/reference images; A/B randomised per row, key withheld until verdicts.

## Ledger
| Row | Biomes | Status | Best after mean (Bar A) | Before mean | Rounds |
|---|---|---|---|---|---|
| P2-017 normal creature scale | meadows;stormwood;cloudreach | open (stage FIXED; in-world PARTIAL, scene-capped) | 5.20 (r2 world) | 4.53 | 2 |
| P2-030 shiny creature finish | tidewake;stormwood;cloudreach | open (FIXED x3; 0.07 under bar) | 6.63 (r2) | 4.23 | 2 |
| P2-018 shiny palette distinction | meadows;stormwood;cloudreach | PASS r2 (CPU-provisional); re-confirm at landing state | 6.83 (r2) | 4.77 | 1 |
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

## P2-017 round 2 (21 Oct 2026, ~13:30 CT)
- Change (391663938): Pipwing 2.75, Sparkit 2.80, Riftfrill and Paddlenewt 2.80 (aspect kept equal to base), Bramblebun 3.00 (matches Creatures PR #698; excluded from my landing), Skyrill 3.60, Glimmermoth 3.60, Stormtrail 2.83 (keeps its ratio to Trailpup); test floor 2.40.
- Same stage route as r1 (fresh shuffle, three fresh judges). Candidate preferred in every changed row by all three. Verdicts FIXED x3 (one "borderline" at Pipwing ~1.04-1.19x body).
- Bar A after/before: 6.4/4.3, 5.0/4.0, 4.0/3.5 -> 5.13 vs 3.93. Judges all attribute the low ceiling to the bare grey stage (no world, flat light); not a scale defect.
- Next: judge on the catalog's own in-world sightings (phase2_capture_creatures idle frames, main vs round 2) where Bar A can be scored against the key art.

## Round 2 creature verdicts (21 Oct 2026, ~14:15 CT)
Candidate state: 0028273c9 (round 2 + accent fix). Captures: `phase2_capture_creatures.gd --poses=idle,shiny_idle`, c3 for water/stormwood/cloudreach at 0028273c9; Meadows c2 at 391663938 (only repaint rows shown there, unaffected by the accent fix). Before = main 29cfa6371 (sa-base-*). Fresh judges per row.

P2-030 (26 rows, three sheets): candidate is the better side on every differing row for all three judges. Verdicts FIXED on every sheet (one judge PARTIAL on Tidewake for Tidecoil, unchanged on both sides). Overall Bar A after/before: 6.5/3.8, 6.7/4.7, 6.7/4.2 -> 6.63 vs 4.23 (+0.30 over r1). Remaining: Tidecoil weak, Riverdrake violet near magenta, dull Torrentoad/Abyssal Guardian/Skyrill, Stormwood low light.

P2-018 (13 rows: Meadows Nightburrow/Stormtrail/Riftfrill, Stormwood Sparkit/Stormtrail, Cloudreach Cloudfang/Galecrest/Breezetail/Cliffspike/Pebbik/Stormcapra/Solmane/Aeriex): candidate better on 11/13 rows; on Galecrest and Solmane judges preferred main's authored shiny but rated the candidate tile clearly different too. Each judge then scored the exact candidate set (Set X) and exact before set (Set Y): FIXED x3; Bar A 6.9 / 6.8 / 6.8 = 6.83 vs 5.0 / 4.3 / 5.0 = 4.77; Bar B 6.4 / 6.3 / 5.8. ROW P2-018 PASS (CPU-provisional) at 0028273c9 state; caveats: Galecrest bib leans orange (not oxblood), Stormcapra one-tone, Stormtrail loses spots. Landing waits on a confirmation pass at the final landing state because round 3 changes the shared sheen.

P2-017 in-world (14 sighting rows across the three biomes, main vs round 2): candidate better on every changed row. Verdicts PARTIAL / PARTIAL / FIXED; Bar A 5.6 / 5.0 / 5.0 = 5.20 vs 4.5 / 4.5 / 4.6 = 4.53. Trailpup and Stormtrail still read short at the production camera distance; all three judges attribute the low ceiling mainly to the Stormwood/Cloudreach ground planes and lighting (look-pass work outside this row).

Round 3 (ae6bafa24): Trailpup 3.00, Stormtrail 3.33, Brooktail 2.75, Pipwing 2.95, Sparkit 3.00, Glimmermoth 3.90; shiny sheen 0.9; Tidecoil gold; Riverdrake off violet; brighter Torrentoad/Abyssal Guardian/Skyrill.

## RESUME (owner pause, 21 Oct 2026 ~15:05Z: "pause on all that visual until I start remote")
All renders stopped; no Godot process running. Lane branch tb/shared-art; every candidate flag below is OFF on the branch except the P2-017 scale data, which cannot be flagged (it lives in species.json on this branch only and is not landed). Captures so far are CPU (Mesa llvmpipe, Low/Compatibility); raw frames were local only.

| Row | Status | Best CPU Bar A (after vs before) | Candidate commit / flag | Exact next step |
|---|---|---|---|---|
| P2-018 shiny palette distinction | PASS r2 CPU-provisional, landing as tb/shared-art-land | 6.83 vs 4.77, FIXED x3 | judged state 0028273c9; landed with fallback OFF and P2-030-only rows removed | GPU pass: same 13 rows via `phase2_capture_creatures.gd --poses=idle,shiny_idle` (meadows, stormwood, cloudreach), three judges; >= 7.5 confirms |
| P2-030 shiny creature finish | open, FIXED x3 but 0.07 under | 6.63 vs 4.23 (r2) | ae6bafa24 round 3 (unrendered); flag `creature_surface_finishes.json shiny_fallback.enabled` (now false) | Enable the flag, render r3 for water/stormwood/cloudreach (`--poses=idle,shiny_idle`), judge against main sa-base frames; ready for GPU pass once r3 >= 6.7 |
| P2-017 normal creature scale | open; stage FIXED x3, in-world PARTIAL | stage 6.17 vs 5.27 (r1); world 5.20 vs 4.53 (r2) | species.json heights on tb/shared-art (r3 ae6bafa24: Trailpup 3.00, Stormtrail 3.33, Brooktail 2.75, Pipwing 2.95, Sparkit 3.00, Glimmermoth 3.90; Bramblebun 3.00 = PR #698) | Render r3 world sightings; judges cap Bar A at ~5-5.6 from Stormwood/Cloudreach ground planes and dark lighting (look-pass scope). Before landing: net smokes listed in the coordinator thread, twice each |
| P2-033 ground pickup identity | candidate built, partial baseline only | not judged | c7b0a600d; flag `data/config/item_identity_props.json enabled` (false); Meshy batch 1 in assets/props/meshy-1020 | Render base + flag-on with `phase2_capture_world_inventory.gd --views=close --subset=...` per biome (subsets in the queue script below), judge |
| P2-060 catch effect finish | candidate built, not rendered | not judged | ed5b7ccdd; flag `data/config/catch_kit.json enabled` (false); Meshy capture orb | Render `phase2_capture_catch.gd --framed=off` (base) and kit+framed on, four biomes; check whether the magenta ground ring is the foe telegraph (#ff40e6) lingering into the catch |
| P2-113 catch camera distance | existing candidate, not rendered | not judged | `data/config/catching.json framed_camera.enabled` (false) | Same catch run as P2-060 with `--framed=on` |
| P2-055 named character silhouettes | candidate built, stage-probed only | not judged | 90a21306e; flag `data/config/npc_role_accessories.json enabled` (false); Meshy batch 2 accessories | Render named posts `phase2_capture_characters.gd --views=close --subset=<ids>` in stormwood and water, base vs flag on, judge |

Partial captures that exist only locally (not reusable after the container ends): pickup baselines for meadows (5 frames) and water (11 frames; potion_small and orb_prime have no camera stand on both sides).
Queue order used (GPU pass can reuse): creature r3 (water/stormwood/cloudreach/meadows) -> pickups base/cand x4 -> catch base/cand x4 -> named NPC base/cand (stormwood, water).
Ready for a GPU confirmation pass now: P2-018. Next closest: P2-030 (after its r3 render).

## READY P2-018 (landing branch tb/shared-art-land)
ROW P2-018 PASS (biomes meadows;stormwood;cloudreach) CPU-provisional: Bar A 6.9 / 6.8 / 6.8 = 6.83 (before 5.0 / 4.3 / 5.0 = 4.77), FIXED x3, three fresh code-blind judges, exact candidate set scored.
- Judged state: tb/shared-art 0028273c9. Captures: `xvfb-run ... godot --path . --rendering-driver opengl3 --resolution 1920x1080 --script tools/phase2_capture_creatures.gd -- --biome=<meadows|stormwood|cloudreach> --poses=idle,shiny_idle --output=...` (Mesa llvmpipe, Compatibility). Before = main 29cfa6371.
- Landed content: shaders/creature_surface_finish.gdshader, scripts/creatures/creature_surface_finish.gd and the creature_body.gd fallback hook exactly as judged; data/config/creature_surface_finishes.json with the twelve P2-018 shiny rows as judged and the shared sheen. P2-030's fallback is landed OFF (`shiny_fallback.enabled=false`) and its species rows are left out, so fallback species keep main's behaviour. No species.json/scale change ships.
- Disclosed difference: the judged frames carried the lane's grown creature heights (P2-017 candidate); colour distinction, not size, was judged, and sizes stay at main here.
- GPU confirmation (7.5) still required.
