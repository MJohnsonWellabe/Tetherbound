# VIS-CLOUDREACH round 1 (ride): cloudreach_cause arm vs main, terrace ride, CPU

- **Capture:** `phase2_capture_cloudreach_ride.gd --tag=phase2 --seed=2042 --fixed-fps 60`, CPU llvmpipe Compatibility 1280x720; base and `--cloudreach-cause-candidate` in separate boots, same tree.
- **Judging:** standard prompt verbatim, `anchor_tiles.py --pairs 3 --include craft --seed 110402`, three fresh code-blind judges in parallel, `calibrate.py` linear (r 0.64, slope 1.05, anchor RMSE 0.67, confirming batch).

| Item | Board | CPU base | CPU arm | Delta |
|---|---|---|---|---|
| P2-105 mounted terrace edge and cloud crossing | F40#6 | 4.65 | 4.51 | -0.14 |
| P2-106 terrace edge clouds | F40#11 | 5.32 | 5.39 | +0.07 |

**Verdict: flat; the cause arm stays OFF** (it raises the cloud deck and pales the cliffs, which the judges read as washed-out and overexposed; both recorded defects PRESENT on both sides for all three judges).

**What all three judges asked for:** (1) the mount never hangs upright over the drop (ground it, give it a fall pose, or block the drop); (2) replace the flat white/blue-grey polygon puffs at the terrace cliff edge with soft cloud kept below the lip. New arms: `cloudreach_physical_runtime.json:mounted_drop_no_air_drive` (no air drive + scramble back after 0.7 s over a real drop) and `cloudreach_visual.json:island_roots.low_mist` (the island mist collars drop below the rims), captured together in round 3b.
