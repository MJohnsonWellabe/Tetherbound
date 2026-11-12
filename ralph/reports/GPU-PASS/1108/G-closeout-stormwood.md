# G-closeout-stormwood: close call for F41#1, F41#11 and F41#14 on High and Medium in one batch (GPU)

## Verdict: F41#11 CLOSES. F41#14 and F41#1 do not.

| Row | Subject | High | Medium | Per judge (mapped; same on both presets) | Recorded defect |
|---|---|---|---|---|---|
| **F41#11** | named character portrait identity | **7.61** ↑top | **7.61** ↑top | 7.92, 7.31, 7.61 | FIXED 3/3 |
| F41#14 | candy pickup tiers | 7.05 | 7.05 | 7.31, 6.69, 7.15 | FIXED 1/3, PARTIAL 2/3 |
| F41#1 | Stormheart finale | 6.54 | 6.54 | 6.69, 6.08, 6.85 | PARTIAL 3/3 |
| *Control: F38#38 (closed at 8.16 High / 8.30 Medium)* | craft hint contrast | *8.18* | *8.18* | *8.38, 7.92, 8.23* | FIXED 3/3 |

- **The control lands exactly on its closing score** (8.18 against 8.16/8.30). This panel's scale matches the one that closed F38#38.
- **F41#11** meets the bar only above the top anchor (7.53). This is the confirming batch.
- **Fit:** steep (slope 1.53, RMSE 0.53), so rows here are about ±0.3.
- **Against LANE-PLACES' re-score:**
  - F41#11: 7.55 → 7.61 (holds).
  - F41#14: 7.59 → 7.05.
  - F41#1: 7.62 → 6.54.
  The re-score read high on the two rows that miss.
- **Presets:** every judge scored High and Medium the same on all three rows (render difference 2.3–4.7).

## What the judges say
### F41#11, portrait identity
- The portraits of Rook, Lio and Elder Maud match the on-screen speakers (3/3).
- Margin items:
  - the world models are "waxy" or over-bright: Rook's skin washes out (3/3);
  - the dialogue box is plain black (1/3).

### F41#14, candy pickup tiers
- Rare Candy (gold star, violet base, gold ring) is now distinct (3/3), and Great glows blue.
- Good and Great still share one wrapped form and one scale (PARTIAL 2/3).
- The black pool ground fills half of every frame (3/3).
- Next: a distinct silhouette or size for Good against Great. This is the B-PICKUPS cause, which is THINGS' now.

### F41#1, Stormheart finale
- It now reads as a giant tree base with buttress roots and an arched door, not a ring with a hole.
- The camera crops the trunk at the frame top, so the branching crown never shows (3/3).
- The interior core is "a flat white-blue slab", not a lightning column.
- The root path is crushed pure black with an orange crack line.
- Next:
  - frame or stage the crown (a camera or scene change, which this lane does not make);
  - a volumetric core (new art);
  - lift the black path grade (P-STORMSKY / P-GROUND).

## Frames
- **High:** LANE-PLACES' `G-rescore-stale-ext-stormwood` (tb/places 444270729), main 90ffeb663, job.json frames.
- **Medium:** `G-closeout-stormwood-medium` (bbfe358bd), main 90ffeb663, the same frames.
  - The locations and world_inventory tools ran with `--preset=Medium`.
  - The dialogue tool renders in the Stormwood world under the run's Medium override.
- **Rows:**
  - F41#1: Stormheart approach and close, dynamo core close.
  - F41#11: Rook, Lio and Elder Maud dialogue.
  - F41#14: good, great and rare candy.
- **Control:** F38#38's closing frames.
- **Sets:** High on one side and Medium on the other (shuffled), stacked at 960×540 per frame. Brief: "one catalogue subject in the stormwood biome: <subject>". The recorded defect is the job.json defect.

## Batch `G-swm`
- Three code-blind judges, standard prompt, four candidate sets.
- Anchors: craft, f36_0_npc:C1 and f10_2_r3_capacitor. This is a confirming batch.
- **Fit:** linear, slope 1.5339, intercept −2.3559, r 0.923, anchor RMSE 0.53.

**Raw Bar A (judges a, b, c; both presets):**

| Row | Raw |
|---|---|
| F41#11 | 6.7, 6.3, 6.5 |
| F41#14 | 6.3, 5.9, 6.2 |
| F41#1 | 5.9, 5.5, 6.0 |
| F38#38 | 7.0, 6.7, 6.9 |
