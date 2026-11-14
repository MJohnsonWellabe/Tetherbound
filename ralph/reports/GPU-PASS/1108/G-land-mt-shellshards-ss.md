# G-land-mt-shellshards-ss: Burrow Warrens mound, detached shards stripped (GPU High, base vs arm)

## Verdict: SHIP. F38#30 5.44 → 5.98 (+0.54, 3/3). Warrens other views 5.35 → 5.94 (+0.59, 3/3). F38#24 no-loss 6.16 → 6.44 (+0.28, 3/3). Every set gains, 3/3.

| Set | Base | Arm | Gain | Prefer arm | Raw a / b / c (base → arm) | Defect (base / arm) |
|---|---|---|---|---|---|---|
| **F38#30** (warrens walk_02, walk_03) | 5.44 | **5.98** | **+0.54** | 3/3 | 5.2→5.6, 4.9→5.3, 4.9→5.3 | PARTIAL / PARTIAL 3/3 |
| Warrens other (route_day, walk_01, vista_dusk) | 5.35 | 5.94 | +0.59 | 3/3 | 5.0→5.4, 4.9→5.4, 4.9→5.3 | none recorded |
| F38#24 no-loss (warrens walk_02, walk_03, stronghold route) | 6.16 | 6.44 | +0.28 | 3/3 | 5.6→5.9, 5.3→5.5, 5.7→5.8 | PARTIAL / PARTIAL 3/3 |

- **Scores:** all mapped. Fit: r 0.943, slope 1.35, anchor RMSE 0.46; the batch is confirming.
- **Board baseline:** F38#30 is 6.48 on the board, from BROKENHILL's panel; this panel reads base at 5.44. The paired gain is the measure.

## Note (14 Nov): arm run crash
- **What happened:** the GPU lane reports that the arm run crashed (integer divide by zero) after six frames: the five Warrens views and stronghold route_day. Stronghold walk_01 to walk_03 and vista_dusk have no arm capture.
- **Effect on this verdict: none.** Every frame judged here was captured on both sides: Warrens walk_02, walk_03, route_day, walk_01 and vista_dusk, and stronghold route_day. F38#24's job frames are exactly Warrens walk_02, walk_03 and stronghold route_day.
- **The missing stronghold views:** they were not part of any judged set, so nothing needs re-judging. If the queued retry lands, those views can be checked as extra no-loss.

## Addendum (14 Nov): stronghold no-loss from the retry run
- **The run:** G-land-mt-shellshards-retry (07806bb97) re-ran the full arm side, all 10 frames.
- **What was judged:** the four stronghold views the crash had missed (walk_01, walk_02, walk_03, vista_dusk, as a 2x2), against base.
- **Result: level.** 6.77 = 6.77, with three ties (raw 6.0/6.0, 6.3/6.3, 6.3/6.3). Fit r 0.951, RMSE 0.43. Yardstick: `yardstick_g_land_mt_shellshards_retry/`.
- **Confound:** the retry spawned turtles and grey foxes where base had badgers and tan foxes. The judges were told creatures are not the subject, and all three call the subject identical.
- **What the judges see on both sides (3/3):**
  - The stronghold is "a small toy Gothic block" rather than the key art's ivy-hung hall.
  - The mountain backdrop is flat blue cards.
  - The approach route is a faint worn strip with no staging.
- **Effect:** the SHIP stands with no loss anywhere.

## What the judges see (3/3)
- **Base:** "many floating pale-blue and white triangular shards and leaf cards across the hillside", reading as "sky-coloured holes or exposed backfaces", "a strong artefact".
- **Arm:** "much cleaner, with only a few dark flecks".
- **F38#24:** gains because base's frame 1 carries the same "pale sky-blue shards on the foreground hillside". The mountains themselves are unchanged and PARTIAL: continuous now, but "a washed, smeared, painted card".
- **F38#30's defect is still PARTIAL (3/3):**
  - The brown rectangle is now mossed over.
  - Frame 2 still shows "a long straight lower edge where the slope meets the grass, with a hard dark cut".
  - The slope texture is "smeared, stretched, no strata".
- **Warrens, both sides:**
  - The entrance is "a dark brown plank wedge jammed against a cave mouth" that reads as placeholder.
  - A few dark debris shards remain on the crest.
  - The dusk frame collapses to one brown mid-tone.

## Next asks (LANE-LAND-MT)
1. **Soften the hill's toe:** replace the straight dark cut at the slope base (walk_03, left of the trainer) with a blended edge of rocks, grass and soil. This is the last of the recorded defect. Scene.
2. **Remove the remaining dark debris shards** on the crest and round the cave mouth.
3. **A higher-frequency rock and moss material** with slope blending and form light, instead of the smeared low-res moss.
4. **Warren entrance hero piece** (timber frame, door, steps, lantern) in place of the brown plank wedge. New art, 3/3.
