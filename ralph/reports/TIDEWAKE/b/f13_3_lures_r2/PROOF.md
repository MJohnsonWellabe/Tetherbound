# F13#3 lures, round 2: installed-prop wayfinding lures + fresh code-blind judges

Criterion: ACCEPTANCE §6.1 **F13#3**, §5 "see the lure" clause; Codex rows V-TW-2..V-TW-6
(`ralph/reports/VISUAL/AUDIT.md`). Round 1 evidence: `../f13_3_lures/`.

## What changed
- `data/config/water_local_chains.json` gains `wayfinding_lures`: thirteen always-standing
  groups (nine for the six chains, four for F13#2 reward pockets). They use only pieces the
  Water chapter already uses:
  - the Lastlight bark lamp post with the Quaternius wall lantern (colliding post);
  - the Quaternius standing banner `Banner_2` (teal-blue cloth, no red; art only);
  - the Water camps' campfire (`scripts/build/campfire.gd`) with its smoke column raised through
    `campfire_glow.gd configure_smoke` (art only; its log-pile collider is removed so a
    simulation-only host and a rendering client agree on collision).
- `scripts/world/water_local_chains.gd` builds them on every peer from the first frame, whatever
  the chain state (the Lastlight lamp's rule). The lamp-post code is shared with the Lastlight
  landmark lamp; the Lastlight lamp itself is unchanged.
- `tools/capture_water_chain_lures.gd`: the Cradle mid stand is now the walked-route point
  (740, 1584), 98 m short of the nest on the chain walk's own baked-ground plan (V-TW-6
  verify-first). Each frame also logs the camera pose and the pixel of every lure.
  No other stand moved.
- Spots were chosen with the production camera pose plus a terrain sightline probe along the
  walk planner's route (`plan_route`). Each post stands at least 3.5 m aside from that route.

| Chain | Lure group (at_xz) | Pieces |
|---|---|---|
| lantern | `lantern_cove_rise` (-327.7, 134.5), 66 m from the landing camera, right of the crest tree | 9 m banner, lamp post, 20 m signal smoke |
| lantern | `lantern_cove_nook` (-411.5, 213.0), 4.6 m past the cache | 9 m banner, lamp post, 42 m signal smoke |
| gull | `gull_rest_survey_marker` (-43.3, 890.0), 21 m below the satchel | 9 m banner, lamp post, 20 m smoke |
| gull | `gull_rest_satchel_lamp` (-19.6, 886.2), 3.5 m from the satchel | 4.8 m lamp post, 7 m banner |
| cradle | `tidal_cradle_rise` (555.5, 1377.0), on the climb beside Otto's camp | 7.5 m banner, lamp post, 16 m smoke |
| cradle | `tidal_cradle_nest` (796, 1652), head of the gully, 23 m short of the seam | 7 m banner, lamp post, 30 m smoke |
| garden | `drowned_garden_rise` (1137.5, 2270.2), in the saddle | 9 m banner, lamp post, 20 m smoke |
| garden | `drowned_garden_vault` (1206, 2342), behind the vault wall | 7 m banner, lamp post, 45 m smoke |
| deep | `deep_watch_chart` (1270.7, 3413.7), 2.4 m past the chart control | 4.8 m lamp post, 4.5 m banner |
| lastlight | unchanged (Halen's lamp) | none |

## Chain walks (final data)
`tests/smoke_tidewake_b_chain_route.gd -- --only=<chain>` (headless; logs `walk_<chain>.log`):
lantern 54/0, gull 59/0, cradle 55/0, garden 59/0, deep 61/0, lastlight 60/0. **All PASS.**
Data tests `tests/run_tests.gd -- --only=water,tidewake`: 432 tests, 0 failed.

## Capture
```
xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 --resolution 1280x720 \
  --script tools/capture_water_chain_lures.gd -- --out=ralph/reports/TIDEWAKE/b/f13_3_lures_r2 --only=<keys>
```
The capture uses the production scene, the production CameraRig, daytime with the clock frozen, and the same stands as round 1 except Cradle's mid stand (see above). Logs: `capture_*.log`.

## Code-blind judges
Each round ran a fresh `claude -p --safe-mode --tools Read` process in an isolated scratch
directory. It held only `frame_01..12.jpg` (renamed per `JUDGE_FRAME_MAP.txt`), `_sheet.png`
and `keyart.png`. The prompt is round 1's text, unchanged (`JUDGE_PROMPT.txt`). Round 2's
sheet was built after keyart.png was copied in, and that judge reported that the sheet showed
the key art. From round 3 on, the sheet is built first.

| Place | Chain | Judge A (`round1/`) | Judge B (`round2/`) | Judge C, final (`JUDGE_VERDICT.txt`) |
|---|---|---|---|---|
| 1 | lantern | WEAK | WEAK | **WEAK**: landing banner/smoke "small, muted"; approach NOTICEABLE (plume + banner) |
| 2 | gull | WEAK | YES | **YES** |
| 3 | cradle | WEAK | WEAK | **YES**: banner, smoke and camp at the landing; banner and smoke at the gully head from the walked stand |
| 4 | garden | WEAK | YES | **NO**: "landmark small, off-center"; the same frames scored YES under Judge B |
| 5 | deep | YES | YES | **YES** |
| 6 | lastlight | YES | YES | **YES** |

Adjustments: two rounds (after A and after B), the task's cap.
- After A: 9 m banners and smoke on the rise markers; Cradle rise moved into the frame.
- After B: Cradle rise moved to 31 m; Lantern nook banner raised to 9 m and its smoke made denser.

The garden frames did not change between B and C, so the garden verdict flipped with the judge alone.
