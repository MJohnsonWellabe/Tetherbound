# G-rescore-stale-ext-stormwood: 16 rows re-scored on main (GPU High, one-sided)

LANE-PLACES (re-scoring lane), 12 Nov 2026.

**Frames:** `tb/gpu-frames-1108` section `G-rescore-stale-ext-stormwood` @ d41014666: main 90ffeb663 as it is, High, each row's own job.json frames (42 frame slots across 16 rows).

**Batch:** three code-blind judges, the standard prompt, each row as a one-sided sheet of its own frames (640×360 tiles) against its job.json brief and recorded defect. Anchors pinned to craft, f10_2_r3_capacitor and f04_6_r22 (three pairs, six points).

**Fit:** linear, slope 1.1369, intercept 0.0455, r 0.792, anchor RMSE 0.704; confirming batch: True; warnings: ["meets the bar only above the top anchor (7.35): F41#1, F41#11, F41#14; extrapolated, but this batch's anchors reach 7.35 or more, so it is the confirming batch"].

**Read the change column as indicative (about ±0.3):** board scores come from other batches and judge pools.


## Results

| Row | Subject | Board | Main now (mapped) | Change | Raw a, b, c | Recorded defect (a / b / c) |
|---|---|---|---|---|---|---|
| F41#1 | Stormheart finale | 6.81 | **7.62** | +0.81 | 6.6, 6.6, 6.8 | PARTIAL / PARTIAL / PARTIAL |
| F41#3 | named wild fight actor spacing | 6.23 | **7.06** | +0.83 | 6.2, 6.0, 6.3 | PARTIAL / PARTIAL / PARTIAL |
| F41#4 | named destination identities | 6.37 | **7.02** | +0.65 | 6.3, 6.0, 6.1 | PARTIAL / PARTIAL / PARTIAL |
| F41#5 | forest ground and distance layers | 6.06 | **6.53** | +0.47 | 5.7, 5.6, 5.8 | PARTIAL / PARTIAL / PARTIAL |
| F41#6 | named wild danger and opening cues | 6.8 | **6.83** | +0.03 | 6.1, 5.8, 6.0 | FIXED / FIXED / FIXED |
| F41#7 | named trainer dialogue identity | 6.24 | **7.02** | +0.78 | 6.2, 6.0, 6.2 | FIXED / FIXED / FIXED |
| F41#9 | harvest resource identity | 6.81 | **7.17** | +0.36 | 6.2, 6.2, 6.4 | PARTIAL / FIXED / FIXED |
| F41#11 | named character portrait identity | 6.91 | **7.55** | +0.64 | 6.6, 6.4, 6.8 | FIXED / FIXED / FIXED |
| F41#12 | charged road surface | 6.6 | **6.90** | +0.30 | 5.9, 5.9, 6.3 | FIXED / FIXED / FIXED |
| F41#14 | candy pickup tiers | 6.35 | **7.59** | +1.24 | 6.6, 6.5, 6.8 | FIXED / FIXED / FIXED |
| F41#15 | dialogue foreground obstruction | 4.49 | **6.87** | +2.38 | 6.0, 5.8, 6.2 | FIXED / FIXED / FIXED |
| F41#16 | Hollows fight loss result clarity | 6.28 | **6.37** | +0.09 | 5.5, 5.5, 5.7 | PARTIAL / PARTIAL / PARTIAL |
| F41#17 | Crown Arch | 7.03 | **7.40** | +0.37 | 6.4, 6.4, 6.6 | FIXED / FIXED / FIXED |
| F41#19 | Glass Field spike bases | 6.56 | **7.25** | +0.69 | 6.4, 6.3, 6.3 | FIXED / FIXED / FIXED |
| F41#20 | named character dialogue reuse | 6.41 | **6.68** | +0.27 | 5.9, 5.7, 5.9 | FIXED / FIXED / FIXED |
| F41#21 | Hollows victory reward tiles | 7.13 | **7.25** | +0.12 | 6.3, 6.2, 6.5 | FIXED / FIXED / FIXED |

## Read this before using the numbers
- **This is the loosest fit of the five batches: r 0.792, anchor RMSE 0.70.** The map here adds about 0.9 to every raw score (slope 1.14, intercept 0.05), because these judges scored the anchors low. A change smaller than about 0.7 in this table is inside the batch's own error and should not move the board on its own.
- **Other batches today read these rows lower.** F41#4, #5 and #12 were 5.71, 5.40 and 5.62 as the unchanged side of G-places-stormlight and 6.01 to 6.09 in G-places-roadvalue; here they are 7.02, 6.53 and 6.90. Between-batch offsets of 0.6 to 0.9 are what three anchor pairs give. From the next batch I use five anchor pairs.
- **Clear moves (well outside the error):** F41#15 dialogue foreground obstruction 4.49 → 6.87, defect FIXED 3/3; F41#14 candy pickup tiers 6.35 → 7.59, defect FIXED 3/3.
- **The three 7.5-or-above flags are marginal and extrapolated** (7.55 to 7.62, raw 6.4 to 6.8). Treat them as rows worth a second panel, not as High passes.

## Flags

- F41#1 7.62: at or above 7.5, needs Medium
- F41#11 7.55: at or above 7.5, needs Medium
- F41#14 7.59: at or above 7.5, needs Medium

## Coverage notes

- every row was judged on all of its job.json frames

## What the judges named (3/3)
- **Ground and road, every outdoor row:** a "flat blotch-textured plane" with even tufts; the road is "a flat hard-edged black band" with "painted" or "cut-out" edges. All three ask for relief (roots, banks, hollows), puddles with reflections, soft blended road edges and grass in clumps. This matches the judged umber-road arm that is parked on the charge colour.
- **Road charge (F41#12):** "the lightning is now a thin crack", "restrained", "a nice touch": the recorded thick-stripe defect is FIXED 3/3 on main as it is.
- **Distance:** one lilac band where two or three fogged tree layers and far landmarks should be.
- **Background creatures:** flat pink bears and solid-blue crows behind speakers and at stands (new art or material).
- **Dialogue (F41#15, #7, #20):** speakers are now unobstructed (FIXED 3/3), but Captain Marrow's stage is a bare plank deck.
- **Fights (F41#3, #6, #16):** flat magenta telegraphs; the trainer stands among the boss's legs; the loss result is not clear (F41#16 PARTIAL 3/3).
- **Recorded defects FIXED 3/3:** F41#6, #7, #11, #12, #14, #15, #17, #19, #20, #21.
