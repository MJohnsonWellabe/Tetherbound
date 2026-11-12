# GPU baselines: F41#22 Stormwood frame matrix and F41#24 Stormwood cleanliness (matrix scope)

Frames:
- `tb/gpu-frames-1108` 75cae1eb3, `G-baseline-f41-22-stormwood-matrix`: main 2ffc97db0, High, one side, 30 frames, no stale scatter.
  - 10 F41-look stands (forest, forest_r, giant, giant_r, glass, rod_line, stormheart, heart_near, hollows, reverse), each in calm, break and the Long Storm aftermath.
- 60fda2d4b, `G-baseline-f41-22-hollows-fight`: `--fixed-fps 20`, 33 frames.

Method:
- One-sided 3×2 sheets (two stands × three phases), five matrix sheets plus a six-moment fight sheet.
- Fight sheet: i02, tell1 start/strike/impact, tell3-b-mid, 99-after.
- Three code-blind judges per batch, standard prompt.
- Anchors: craft, f36_0_npc:C1 (7.47/7.53) and f10_2_r3_capacitor, so all three batches are confirming.

Batches:

| Batch | Brief | Fit | Warnings |
|---|---|---|---|
| `G-f41m` | F41#22 matrix brief | slope 1.2892, intercept −1.2352, r 0.903, RMSE 0.593 | none |
| `G-f41c` | F41#24 cleanliness brief | slope 1.1846, intercept −0.7373, r 0.895, RMSE 0.619 | none |
| `G-f41x` | trunk-free fight sheet (tell3-b-mid replaced by tell2-d-strike), both briefs | slope 1.4283, intercept −2.2687, r 0.921, RMSE 0.540 | none |

Note: the magenta-ring and "camera in canopy at i13/i15" comments in the judges' text are about the **f10_2 anchor** set, not these frames. No flat magenta telegraph appears in the Hollows fight sheet (3/3 judges on cleanliness).

## Scores (mapped, GPU High)

| Sheet | F41#22 matrix | F41#24 cleanliness |
|---|---|---|
| stormheart + heart_near | 6.89 | 6.84 |
| glass + rod_line | 6.71 | 6.73 |
| hollows fight (with the trunk frame) | 5.77 | 5.66 |
| forest + forest_r | 5.64 | 5.78 |
| hollows + reverse | 5.55 | 6.05 |
| giant + giant_r | **4.82** | 5.58 |
| **Row mean (with the trunk frame)** | **5.90** | **6.11** |
| hollows fight, **without** the trunk frames (`G-f41x`) | 6.44 | 6.68 |
| **Row mean (fight without the trunk frames)** | **6.01** | **6.28** |

- **F41#22 baseline: 5.90**, or 6.01 with the trunk-blocked fight frame excluded. The giant stands (4.82) are the only sheet under 5.
- **F41#24 in matrix scope: 6.11**, or 6.28 without the trunk frames. That is in line with the earlier single-grove 6.30. The judges' cleanliness verdict per sheet:
  - PARTIAL on all stand sheets except glass + rod_line, which 1 of 3 judges marked FIXED;
  - fight sheet: PARTIAL ×2 and PRESENT ×1;
  - trunk-free fight sheet: PARTIAL ×3.
- **The trunk question is reported separately.** Swapping the one blocked frame (tell3-b-mid) for a clear strike lifts the fight sheet from 5.77 to 6.44 (F41#22) and from 5.66 to 6.68 (F41#24). This compares two batches with different judges, so take it as the size of the effect, not an exact delta.
  - tell4-a-start (the GPU lane's other trunk frame) was not in either sheet.
  - 99-after still has a root covering about a third of the frame, and all judges count that.

## Defects, worst first (for the floor lane)

1. **Giant stands: lilac trunk walls** (giant, giant_r; 4.82). Smooth, untextured lilac trunks fill about 70% of every frame behind the trainer. No sky, no landmark, and calm, break and aftermath look identical (3/3, "weakest world set").
   - Scene fix: reframe these stands, or open the canopy.
   - New art: bark material.
2. **Forest interior reads as generated** (hollows + reverse 5.55; forest + forest_r 5.64), named by all judges:
   - evenly spaced, near-identical cone trunks;
   - the canopy is a flat, oversaturated green wall with no sky;
   - the black pools read as hard-edged, jagged cut-out holes, not water;
   - trunk tops are sheared flat, with fragments floating at the canopy line (2/3 cleanliness judges);
   - white ground discs or decals repeat;
   - a pink creature at the edge reads as a placeholder blob.
   The storm phases cannot be told apart in any stand without sky.
3. **Fight readability** (Hollows Alpha; 5.77, or 6.44 without the trunk frames):
   - the camera sits inside a teal trunk at the later telegraph, so the fight is fully hidden (3/3);
   - a root covers about a third of the after frame;
   - the player's Sparkit is tiny and nearly lost (3/3);
   - telegraph and impact show no world-space effect, only HUD text such as "HEAVY" and "CHARGE" (2/3).
   Fixes: camera occlusion fade, rim light or outline on the player's creature, an in-world tell and impact.
4. **Sky artefact at the stormheart/wolf stand** (6.89): in break and aftermath the sky shows hard-edged, faceted, pale planar slabs, read as a broken skybox (3/3 on both briefs). The trainer overlaps the wolf's foreleg (near-clipping, 3/3).
5. **Glass + rod_line** (6.71, the best world sheet: purple storm sky, lightning, crystals, glowing eyes):
   - the ground is a flat green with painted dark stripes;
   - the lilac trunks are untextured;
   - a mushroom is cut by the frame edge;
   - the lower stand is murky.

Cross-cutting: the lilac trunk material (smooth "painted plastic") is named in every stand sheet, by every judge, on both briefs. It is the single change that touches the most sheets.
