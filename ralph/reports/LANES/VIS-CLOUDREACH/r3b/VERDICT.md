# VIS-CLOUDREACH round 3b: mount scramble + island low mist vs main, terrace ride, CPU

- **Arms (captured together):** `cloudreach_physical_runtime.json:mounted_drop_no_air_drive` (`--cloudreach-mount-drop-candidate`: over a real drop the stick no longer drives the mount; after 0.7 s with no walkable floor under it, it scrambles back to its newest verified ground through the existing mounted-fall recovery) and `cloudreach_visual.json:island_roots.low_mist` (`--cloudreach-island-mist-candidate`: the floating-island mist collars sit 170 m below each base, wider and fewer).
- **Capture:** `phase2_capture_cloudreach_ride.gd --tag=phase2 --seed=2042 --fixed-fps 60`, CPU llvmpipe Compatibility 1280x720. Base = round 1 base (`r1_ride_base`, same tree apart from flag-off code). The arm recovered at t=1.2 s, so its frames at the base's 2.0/3.0 s marks are `terrace_after` and `terrace_road_back_01.5s` (the same sequence positions, the tool's own names).
- **Judging:** standard prompt verbatim, `anchor_tiles.py --pairs 3 --include craft --seed 110404`, three fresh code-blind judges in parallel, `calibrate.py` linear (r 0.80, slope 0.91, anchor RMSE 0.51, confirming batch).

| Item | Board | CPU base | CPU arm | Delta | Defect calls (arm) |
|---|---|---|---|---|---|
| P2-105 mounted terrace edge and cloud crossing | F40#6 | 4.82 | **5.91** | +1.09 | FIXED 3/3 |
| P2-106 terrace edge clouds | F40#11 | 4.97 | **6.03** | +1.06 | PARTIAL 3/3 |

**Verdict: gain on both; both flags ship ON** (owner rule: a judged CPU gain ships ON with its score; P2-106 is above 6.0). Test: `tests/test_vis_cloudreach_landed.gd`.

**Rule note (disclosed):** the scramble recovers a mount sooner than the walker's 100 m recovery. It fires only when there is no walkable floor within 100 m under the mount (`scramble_probe_m`), so every survivable ride-off still lands with no snap-back (the causeway-ledge leg of `tests/smoke_cloudreach_saddle_remount.gd` is unchanged); only a fall the walker rule would catch anyway ends earlier. The terrace leg of that smoke now asserts the scramble when the flag is ON and the 100 m parity when it is OFF.

**Remaining (all three judges):** the soft mist bank sits right behind the pale deer and flattens its silhouette; the third moment's camera sits inside a tree canopy on the road back; cliff faces still read as untextured with hard black shadow wedges. Next: thin the bank directly behind the terrace rim, and a camera occlusion fade.
