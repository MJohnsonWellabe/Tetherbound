# G-sw-foliage: Stormwood foliage_grade_1104 with the adjust_bsc fix

Frames: `tb/gpu-frames-1108` fbe4f1caa, manifest `G-sw-foliage-grade-fixed`, High, no script errors.
- **Live:** main f2891dd85.
- **Arm:** live plus `vegetation.gd` at 2ea565e63 (the adjust_bsc fix) plus `ITEM-VEG-ADJUST/overlay_foliage_grade.json` (`foliage_grade_1104` ON).

Judged rows: F41#3, F41#5 and F41#8, as the coordinator asked. The manifest's F41#4 and F41#6 entries were left out: F41#4's frame (`crown_overlook`) is the same image counted under F41#5, and F41#6's (`capacitor_alpha-tell1-e-impact`) has the same filename as an F41#3 frame.

**Pixel check before judging:** the grade rendered, but its footprint is small. On the location and character frames 2.4–4.6% of pixels change by more than 30 levels, and mean value drops 1–5 levels. The fight frames differ by about 50%, but that is the non-deterministic fight, not the grade.

Batch `G-fol`:
- Three code-blind judges and the standard prompt.
- Pinned anchors are craft, f10_2_r3_capacitor and f04_6_r22, so the top anchor is 7.35 and this is a confirming batch.
- Fit: linear, slope 1.324, intercept −0.7088, r 0.859, anchor RMSE 0.591. No warnings.

| Row | Item | Live | Arm | Gain | Judges preferring arm | Ship |
|---|---|---|---|---|---|---|
| F41#5 | forest ground and distance layers | 6.09 (raw 5.4, 4.8, 5.2) | 6.09 (raw 5.4, 4.8, 5.2) | **0.00** | 0/3 (3 ties) | no |
| F41#8 | named character silhouettes | 6.04 (raw 5.3, 5.0, 5.0) | 6.04 (raw 5.3, 5.0, 5.0) | **0.00** | 0/3 (3 ties) | no |
| F41#3 | named wild fight actor spacing | 5.96 (raw 5.3, 4.9, 4.9) | 6.75 (raw 5.4, 5.6, 5.9) | +0.79 | 3/3 | **not attributable** |

**The two deterministic rows are exactly flat.** All three judges called F41#5 and F41#8 "near-identical" on the two sides. The foliage-grade defect ("uniform grass carpet … weakens the deep wet ancient forest silhouette") is still PARTIAL or PRESENT on both.

**Do not credit the F41#3 gain to the grade.** The gain comes entirely from fight staging, which changes from run to run:
- On the arm side, Sparkit stands clear of Voltarach in frame 3 (judges b and c).
- On the live side, Sparkit is hidden under the boss's legs in frames 2 and 3.

No judge mentions foliage colour in F41#3. The manifest itself warns that this fight is not deterministic.

**Verdict: the foliage grade makes no attributable gain, so do not ship it.** If the coordinator wants a cleaner read on F41#3 alone, it needs paired seeds or several runs per side. The stronger lever is the code fixes the judges keep naming for that row: a spacing rule and a camera fade.

## What the judges rank first (3/3)
- **Stormwood depth (F41#5, scene):**
  - Layered forest masses and rising ground in the mid and far distance, with height fog between them, instead of one flat purple tree-line card.
  - Groves and clearings instead of an even grass carpet on flat land.
- **Fights (F41#3 and F41#6):**
  - Physical telegraphs instead of flat magenta rings.
  - A camera that stays out of trunks and canopy.
  - Keeping Sparkit and the trainer outside Voltarach's leg span.
- **F41#8:** distinct silhouettes for the named roles (new art).

The lens-ground-clearance sections had not landed when this batch started. They will be judged when they land.
