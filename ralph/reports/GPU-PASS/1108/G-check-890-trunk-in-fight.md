# G-check-890-trunk-in-fight: does #890's narrow trunk band cause the trunk-filled fight frames?

Frames: `tb/gpu-frames-1108` 1520cfed, High, `--fixed-fps 20`, hollows_alpha north view, fixture seed 1042206, 33 frames per side.
- `main-High` = main 2ffc97db0 (narrow band ON; the same frames as `G-baseline-f41-22-hollows-fight`).
- `bandoff-High` = main + `narrow_band_off.json` (the old 3–7 m trunk fade).

Method: pixel diff per frame, a crude teal-trunk-fill measure (share of the central frame dominated by the Deepwood trunk's teal), and a visual check of the flagged frames. No judge batch: this is a cause question, not a look score. Check sheet: `check_890/_sheet_trunk_890.png` (rows: tell3-b-mid, tell4-a-start, 99-after; left = band ON, right = band OFF).

## Verdict: #890 is not the cause. The trunk fills the camera on both sides, at different moments.

| Frame | Band ON (main) | Band OFF |
|---|---|---|
| i00 | fight in view (teal 39%) | **trunk fills the frame** (79%) |
| tell3-b-mid | **trunk fills the frame** (82%) | fight in view (28%) |
| tell4-a-start | **trunk fills the frame** (84%) | fight in view (25%) |
| 99-after | root covers the right third | clear |

- **The fights diverge after the opening.**
  - 00-before, i01 and all of tell1 are identical (0.0–0.2% of pixels changed).
  - From i02 on, 53–71% of pixels differ, because Voltarach and the trainer stand in different places.
  - So the two sides are not the same camera moment, and a trunk frame on one side cannot be compared to the other.
- **Band OFF hits the same trunk too:** at i00 the camera is buried in the teal Deepwood trunk with the fight fully hidden.
- **The counts per run** are 2 blocked frames with the band on and 1 with it off. That is within run-to-run variance for two diverged fights; neither fade setting keeps this trunk out of the camera.

## What this points at
The occluder is the large teal-scaled Deepwood trunk or root mass beside the Hollows arena. The fight camera passes into or right behind it whichever fade band is set, so it looks like this mesh is not covered by the trunk fade at all, or is too large for it.

The fix belongs in camera occlusion for that mesh, by one of:
- adding it to the fade set;
- a camera collision push-out;
- keeping the north view's orbit clear of it.

It does not belong in the #890 band width.

**Recommendation:** keep #890. Treat the trunk-filled frames as a separate F41#22 defect (item 3 in `G-baseline-f41-22-f41-24.md`).
