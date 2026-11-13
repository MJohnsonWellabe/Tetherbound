# G-below6-mushrooms: natural mushroom clusters for pickups and the High Perches rim (F40#16, F40#17; F38#6, F41#14 no-loss; GPU High)

## Verdict: SPLIT. Ship the High Perches rim dressing; do not ship the pickup mushrooms. As one arm it fails (one set loses 3/3).

| Set | Base | Arm | Gain | Prefer arm | Arm per judge (mapped) |
|---|---|---|---|---|---|
| **F40#17 row** (crown rim, day and night) | 6.01 | **6.94** | **+0.93** | 3/3 | 6.62, 7.04, 7.17 |
| High Perches views (arrival, court, departure) | 6.29 | 6.57 | +0.28 | 2/3 | 6.90, 6.20, 6.62 |
| **F40#16 row** (Cloudreach speed and wild finds) | 6.43 | 6.34 | −0.09 | 1/3 (2 prefer base) | 6.20, 6.48, 6.34 |
| Meadows mushroom finds (speed, stamina, wild) | 6.66 | **5.92** | **−0.74** | 0/3 | 6.06, 5.92, 5.78 |
| F38#6 row (Meadows candy and potion) | 6.62 | 6.62 | 0.00 | identical | 6.48, 6.48, 6.90 |
| F41#14 (Stormwood candy) | n/a | n/a | n/a | n/a | not judged: base and arm byte-identical |

## The rim dressing works (F40#17, +0.93, 3/3)
- **Base:** "three oversized, saturated toy mushrooms ... about half the trainer's height, in a regular row" (3/3). The yellow one is "barely grounded" at the rim, so the recorded defect is PARTIAL on base for 2/3.
- **Arm:** "smaller natural clusters (tan, blue, orange shelf), all clearly on the grass ... at a believable size". The recorded defect is FIXED on the arm 3/3.
- **The court gains too.** In base's crown-court frame "three huge glossy mushrooms sit right at the camera and block the bottom" (3/3). The arm leaves only one orange cap at the edge. That is most of the +0.28 on the High Perches views. Judge b preferred base there by 0.2 for the arrival staging, which is creature position, not the mushrooms.
- **Close-out exception.** F40#17's arm at 6.94 is 7.04 and 7.17 for two judges. It is a near-bar candidate once it is on main.

## The pickup restyle loses (F40#16 −0.09; Meadows −0.74, 3/3)
- **The GPU lane's flag is the cause.** The speed and stamina finds are now "tiny glowing smudges", a "blue glowing sprig that reads as a herb, not a mushroom", or a cluster that "reads more like pebbles" and "nearly vanishes into the grass" (3/3).
- **Base's yellow cap "reads instantly"** (3/3), so base wins on identity even though its caps are "glossy and toy-like".
- **F40#16's recorded defect is already fixed on base** for 2/3: base's two Cloudreach finds already differ, as a yellow cap and an orange cap. The arm's version is "more believable but small and low-contrast". So the row is level-to-down.
- **The lesson for the next round:** keep the natural forms (bracket shelf, clusters) but make each find read as a mushroom at normal distance. That means larger caps, more value contrast against the grass, a visible cap-and-stem silhouette for speed and stamina, and one distinct hue each. The glow halo alone is not enough.

## No loss elsewhere
- **F38#6:** the frames differ only by run timing (mean difference 3–5), and every judge scored them identically. The recorded defect is PARTIAL on both sides: the canister and the cloth bundle read as "a different asset family", and the bundle and basket are about half the trainer's height (2/3).
- **F41#14:** not reached by the arm (byte-identical), so it is level by construction.

## Flags
- **Meadows wild find, frame 3 (both sides, 3/3):** the pickup floats on open water beside the swimming trainer, as "a pale disc" or "a faint ghost". That is a placement bug, not part of this arm.
- **Red near oxblood (1/3, both sides):** "a soft red glow on a pillar" in the crown court, and "the rust-red disc on the upper plateau". The arm's salmon "have 0" text is UI, not this arm. Worth one look by PLACES.
- **Griffin (1/3, both sides):** clips into the tower wall in the rim frames.

## Pooled current-main lines
No earlier GPU panel of these rows is on main. This batch's bases are the current-main reads: F40#17 6.01 and F40#16 6.43, at High.

## Frames
- **Sources:** `tb/gpu-frames-1108`, High, `--fixed-fps 20`, `tb/below6` 6eb2cfa71 on both sides.
  - **base:** no overlay.
  - **arm:** `BELOW6-MUSHROOMS/overlay.json`.
- **Sections:**
  - `G-below6-mush-cloudreach` (a2cc932a7)
  - `G-below6-mush-perch` (b07de21f8): 12 frames per side; the tool's own `_sheet.png` was left out.
  - `G-below6-mush-meadows` (4ab660946)
  - `G-below6-mush-stormwood` (aae21e7d7): byte-identical.
- **Health:** 0 script errors.
- **Render check (mean difference per frame):**
  - Cloudreach finds 3.3 and 3.5.
  - Crown rim 3.3 (day and night).
  - Court 6–7, landed 5–9, departure 7.6 and 19.8 (night).
  - Meadows finds 3.0–5.5.
  - Candy and potion 3.3–4.7, which is run timing.
  - By eye: on the rim, three big toadstools become a bracket shelf plus small clusters, and the Cloudreach speed find shrinks to a pale cluster.
- **Sets** (stacked, 1280×720 each):
  - F40#16: Cloudreach speed and wild finds.
  - F40#17: crown-rim-out day and night.
  - High Perches views: arrival-landed day, crown-court night, departure-lookback night.
  - Meadows finds: speed, stamina and wild.
  - F38#6: good candy, rare candy and small potion.

## Batch `G-mu`
- Three code-blind judges, standard prompt, five candidate sets.
- Anchors: craft, f36_0_npc:C1 and f10_2_r3_capacitor. This is a confirming batch.
- **Fit:** linear, slope 1.393, intercept −2.017, r 0.936, anchor RMSE 0.49. No warnings.
- Yardstick: `yardstick_g_below6_mushrooms/`.

**Raw Bar A (judges a, b, c):**

| Set | Base | Arm |
|---|---|---|
| F40#17 row | 5.5, 5.8, 6.0 | 6.2, 6.5, 6.6 |
| High Perches views | 5.9, 6.1, 5.9 | 6.4, 5.9, 6.2 |
| F40#16 row | 5.6, 6.4, 6.2 | 5.9, 6.1, 6.0 |
| Meadows finds | 6.3, 6.1, 6.3 | 5.8, 5.7, 5.6 |
| F38#6 row | 6.1, 6.1, 6.4 | 6.1, 6.1, 6.4 |

Bar B: yes for both Meadows sets from 2/3 (the meadow carries it); no for every Cloudreach set (3/3).
