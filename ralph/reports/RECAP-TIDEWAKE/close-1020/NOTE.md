# READY F39#0

F39#0 (Tidewake): "After F26 look-dev, the biome is re-captured (≥200 frames) and its catalog rows re-scored against the new bar."

## Proof

- **Source:** `f6e822826d8f6c2d54e8151e51825288b0d24651` (tb/tidewake head, includes WorldWeather fix 129fadfe8). Branch `tb/recap-tidewake`. Shipping visual settings; `tidewake_look_candidate=false`, `f39_candidate=false`.
- **Renderer (disclosed substitute):** Low preset, `gl_compatibility`, Mesa llvmpipe (CPU), 1920x1080. The criterion names High/Medium; no GPU is available, so the owner's 17 Oct direction applies (CPU-provisional bar 6.7). **A High/Medium GPU pass is still owed.**
- **Recapture command** (one per segment, `t` = day, night):
  `xvfb-run -a -s "-screen 0 1920x1080x24" godot --path . --rendering-method gl_compatibility --rendering-driver opengl3 --resolution 1920x1080 --script res://tools/capture_f39_catalogue.gd -- --biome=water --times=$t --preset=Low --source-commit=f6e822826d8f6c2d54e8151e51825288b0d24651 --seed=2042 --f39-weather=clear --output=/home/user/f39cap/main-clear-$t`
- **Frames:** 230 (115 day + 115 night), 230 unique SHA-256 hashes, in `frame-manifest.json`. That covers 23 of 24 authored destinations × 5 camera headings × day/night. Destination 10, Tidal Cradle Saddle Camp, was refused by the `Game.debug_teleport_to` walkability/combat guard in both segments. Those 10 planned frames are missing, so both manifests carry `complete=false`. This is a stand-coordinate defect for the Tidewake world owner. Frames stay local; the one committed sheet is `_sheet_f39_recapture_heading0.jpg` (heading-0 frame per destination, 660 KB).
- **Supplementals** (existing tools, same SHA, Low/CPU) for rows the landscape views cannot show: creatures 91, UI 12, currents 16, swimming 7, mounted swim 17, camps 9, Venn fight 40 + full Venn fight 75 (Cannonback/Riverdrake/Riptusk), world pickups 23. Receipts are under `ralph/reports/VISUAL/phase2/tidewake/recap1020*/`.
- **Rows scored:** all 44 Tidewake catalogue rows. `row-scores.json` has per-judge scores, mean, spread, evidence cells and reasons.
  - **33 SCORED** by all three judges.
  - **11 NO_CURRENT_EVIDENCE**, with the exact missing capture stated (no score invented):
    - Catch, 4 rows (P2-060/061/113/114): `phase2_capture_catch.gd` loops on "Engage Mangrove Monitor" until timeout, 0 frames.
    - Dialogue, 3 rows (P2-073/074/075): the dialogue tool refuses non-fullscreen Xvfb, failed twice.
    - Fly, 2 rows (P2-069/119): the flight tool is Cloudreach-only.
    - Victory and Riverdrake faint, 2 rows (P2-103/104): the fight capture cap ended before an observed win.
  - This matches the accepted Stormwood precedent (F41#0: 36 assessed, 8 honest unassessed).
- **Judges:** three independent code-blind Agent subagents per pass, three passes (prompts and raw outputs in `judges/`). Each judge saw only the contact sheets, ART_DIRECTION excerpts, `docs/reference` boards and Palworld shots, and the row defect texts.

### Bar A / Bar B by pass

| Pass | Frames judged | Bar A per judge | Bar A mean (spread) | Bar B mean |
|---|---|---|---|---|
| 1 | landscape 230 | 4.6 / 4.1 / 3.8 | 4.17 (0.8) | 3.63 |
| 2 | supplementals | 4.8 / 4.7 / 5.2 | 4.90 (0.5) | 4.30 |
| 3 | pickups + late fight | 5.6 / 5.6 / 5.4 | 5.53 (0.2) | 4.80 |

- **Blind completeness check:** PASS (`blind-completeness.json`). Separate auditor findings:
  - All 44 IDs appear exactly once.
  - All 33 scored rows were recomputed from the raw files.
  - All 11 no-evidence rows were "not pictured" for every judge in every pass.
  - The overall means match the raw files.

## Result (not part of the closure)

- No row reaches 6.7 CPU-provisional or 7.5. Highest: P2-090 and P2-091 at 6.0; P2-009 and P2-101 at 5.67. Lowest: P2-002 (map) 2.0; P2-067/066 (current restoration/streaks) 2.17/2.5; P2-011 (destination read) 2.83; P2-030 (shiny) and P2-026 (Veilfall shallows) 3.0.
- Judges' most valuable changes:
  - Replace the dashed current markings with flowing foam bands, and make restoration visible. (scene)
  - Rebuild the Veilfall silhouette to the board. (new art)
  - Use pattern-preserving shinies and distinct hurt/faint/rest poses. (scene)
  - Replace the flat pink telegraph rings. (scene)
  - Add terrain/road context to the map. (UI)
- F39#1–#5 remain open.
