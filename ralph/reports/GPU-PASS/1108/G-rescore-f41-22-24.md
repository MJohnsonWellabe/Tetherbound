# G-rescore-f41-22-24: Stormwood frame matrix re-scored on main (GPU High, one-sided)

LANE-PLACES (re-scoring lane), 12 Nov 2026. Rows: F41#22, F41#24.

**Frames:** `tb/gpu-frames-1108` section `G-rescore-f41-22-24` @ b51c20f31: main 90ffeb663, High, five stands × Calm, Break and aftermath Calm.

**Batch:** three code-blind judges, the standard prompt. Five one-sided sets (one per stand, its three storm states side by side). Each set carries F41#24's criterion as its recorded defect. Five anchor pairs (ten points).

**Fit:** linear, slope 0.9839, intercept 0.2923, r 0.759, anchor RMSE 0.753. `calibrate.py` warns that RMSE is above 0.75: these judges did not rank the anchors like the reference judges. Read every number here as about ±0.75.

## Row scores

| Row | Board | Main now (mapped) | Basis |
|---|---|---|---|
| **F41#22** | 6.96 | **6.46** at High | mean of the five stands |
| **F41#24** | 7.08 | **6.46** | the same mean; its defect is FIXED 3/3 at 2 of 5 stands (glass, stormheart), PARTIAL 3/3 at giant and forest |

No row is at 7.5 or above, so no Medium is needed. No row is below 6; the giant stand alone is (5.51).

## By stand, lowest first

| Stand | Mapped | Raw a, b, c | F41#24 defect | What the judges named |
|---|---|---|---|---|
| giant | 5.51 | 5.3, 5.4, 5.2 | PARTIAL / PARTIAL / PARTIAL | one stretched-bark trunk fills the frame, no sky or depth, the fallen giant barely shown; a flat grey rectangular slab at the trainer's feet in the Break frame (3/3) |
| forest | 6.06 | 5.9, 6.0, 5.7 | PARTIAL / PARTIAL / PARTIAL | good trunks and mushrooms; a flat-lit pink bear cropped at the frame edge, the grey slab in the Break frame, hard-edged black pools (3/3) |
| rod_line | 6.49 | 6.2, 6.5, 6.2 | FIXED / PARTIAL / FIXED | palette and road staging right; the Break frame shows no lightning (2/3), flat hard-edged road slab and pool, leaf-card canopy |
| glass | 6.98 | 6.8, 6.8, 6.8 | FIXED / FIXED / FIXED | purple sky, bolt and crystals carry it; shard-like angular cloud plates and smeared flat ground (3/3) |
| stormheart | 7.28 | 7.1, 7.2, 7.0 | FIXED / FIXED / FIXED | twisted roots, platforms, layered depth; a ground lightning scribble in the Calm frame, sparse strand grass, pale leaf cards |

## What the judges asked for (3/3)

- Make Calm, Break and aftermath visibly different: lightning and a flash in every Break frame, strike scars and a lighter grade in aftermath. (Lightning is Break-only by owner decision; the ask is that Break always shows it.)
- Remove the hard-edged pale ground slab and the flat black pools (giant, forest, rod_line).
- Re-aim the giant and forest cameras, or open the canopy, so purple sky shows.
- Replace the leaf-card canopy and stretched bark and ground textures (new art).
