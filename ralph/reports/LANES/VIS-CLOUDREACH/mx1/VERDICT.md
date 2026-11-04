# VIS-CLOUDREACH mx1: first CPU baseline for the F40 matrix rows (subset)

- **Capture:** `capture_cloudreach_f40_matrix.gd --preset=Low --low-resolution=1280x720 --seed=2042 --piece=3,4,7` on the merged tree (`d02df5264`), CPU llvmpipe Compatibility. Stand 0 (realm gate crag), four production views (approach, gameplay, reverse, detail) in day clear (piece 3), day rain (piece 4) and night clear (piece 7): **12 of the plan's 384 frames per preset; a subset, not the full matrix.**
- **Judging:** standard prompt verbatim; conditions paired as two-sided sets (day clear vs day rain, night clear vs day clear); `anchor_tiles.py --pairs 3 --include craft --seed 110406`; three fresh code-blind judges in parallel; `calibrate.py` linear (r 0.89, slope 1.49, anchor RMSE 0.40, confirming batch). Day clear was judged twice, identically (5.45 both times).

| Condition | CPU mapped |
|---|---|
| day clear | 5.45 |
| day rain | 4.90 |
| night clear | 5.05 |
| **subset mean** | **5.13** |

**Rows:**
- **F40#19** (matrix passes the bar on High and Medium): CPU subset 5.13; not met. First CPU score.
- **F40#0** (biome re-captured, ≥200 frames, catalogue rows re-scored): 12-frame CPU subset only, mean 5.13; the full 384-frame CPU recapture is about 40 h for Cloudreach alone and is not attempted here. First CPU score.
- **F40#21** (no flat magenta rings or slabs, placeholder materials, floating bodies or clipping in the matrix): no magenta and no placeholder materials in any frame (all three judges). One judge called the overhanging stratified ledge above the gate road a floating slab (PARTIAL); two called the defect FIXED. Subset: near-clean, one possible floating read.

**What all three judges asked for:** break the uniform grass carpet at the gate into groves, clearings and pale stratified stone ground; the gate arch is small and sits behind the quest card and minimap in the approach and detail views; rain only desaturates; night turns the foreground into a black-green mass.
