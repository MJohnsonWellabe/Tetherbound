# tb/fplus-grade: Forward+ grade multipliers measured on GPU (22 Oct 2026, evening)

**Branch:** `tb/fplus-grade` head **cff972b7e**, which is 493ebb9ff plus the review fixes. **Main:** a4f8a6b7b.
Both were measured on the same GTX 1060, at Low (Compatibility) and Medium (Forward+), with no forced variants. The branch applies its own factors from `art.json` (`forward_plus_grade`: fog ×0.5, exposure ×1.3333, saturation ×1.2, Medium and High only).

**Result: the branch reproduces the round-2 recipe and leaves Low untouched.**

| Scene | Low, main | Low, branch | Medium, main | **Medium, branch** | Round-2 forced recipe (parent folder) |
|---|---|---|---|---|---|
| Stormwood (F10#2 north, 12 frames) | 29.4 / 0.546 | 30.2 / 0.542 | 29.8 / 0.395 | **39.3 / 0.512** | 38.6 / 0.520 |
| Meadows (band1 day, 3 frames) | 106.7 / 0.571 | 107.0 / 0.570 | 87.6 / 0.506 | **104.3 / 0.555** | 104.2 / 0.554 |
| Tidewake (brine steps day, 2 frames) | 164.7 / 0.274 | 164.7 / 0.274 | 141.9 / 0.269 | **162.1 / 0.281** | 162.0 / 0.281 |

Values are mean Rec.709 luma (0–255) / mean HSV saturation. The method matches the parent `forward-plus-grade/` report: same crops, same frames, measured by `grade_measure.ps1`.

## Applied exactly once (no compounding)

The local logger, run in base mode, only reads the live WorldEnvironment each frame and forces nothing. It printed at frames 1, 60, 600 and 1200 and on every change (`commands_and_grade_samples.txt`).

- **Saturation** is 1.20 at every Medium sample on all three scenes, all the way to the last frame; it never reaches 1.44. On Low it is always 1.00.
- **Stormwood (Medium):**
  - Frames 1–600 show the engine's pre-world default environment (exposure 1.0, fog 0.00023) on both trees; the branch leaves it alone, as designed.
  - From the world write at frame 826, the branch holds exposure 0.800, fog 0.00068 and saturation 1.20. Main holds 0.600, 0.00135 and 1.00.
- **Meadows (Medium):** the location tool's clock ramps exposure and fog on both trees over the run. Main goes 0.600 → 0.702, fog 0.00040 → 0.00089. The branch tracks it at the same ratios:
  - frame 600: 0.866 vs 0.647 (×1.34), fog 0.00032 vs 0.00063 (×0.51);
  - frame 1200: ×1.34 and ×0.52;
  - last frame: 0.800 vs 0.600 (×1.333), fog 0.00020 vs 0.00040 (×0.500).
  The small mid-run deviation comes from the two runs' clocks not being frame-locked; the end values are exact.
- **Tidewake (Medium):** exposure 0.800, fog 0.00028 (main 0.00055) and saturation 1.20 at every sample.
- **Low on the branch:** exposure, fog and saturation equal main on all three scenes. `renderer_grade()` is empty on Compatibility.

## Pending

Once the Meadows land (#712) is on main (Meadows fog 0.0004 → 0.001), I'll re-measure Meadows with this branch merged onto that main.

## Files

- `_sheet_fplus_branch.png`: Stormwood i03, Meadows grandpas_village and Tidewake stairstones for Low (main), Medium (main) and Medium (branch).
- `grade_branch_measure.csv`: every run.
- `commands_and_grade_samples.txt`: exact commands, plus the logged environment at frames 1, 60, 600, 1200, the world write and the last frame.
