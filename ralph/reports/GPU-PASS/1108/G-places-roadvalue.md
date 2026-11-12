# G-places-roadvalue: Stormwood road value, no-puddles arm (LANE-PLACES; GPU High)

## Verdict: do not land as is
- The arm gains +0.24 to +0.43 on four rows, with all three judges preferring it on each.
- It loses on F41#4 in two separate batches: −0.23 with 0 of 3 judges preferring it, then −0.09 with 0 of 3 preferring it and 1 tie.
- Every gain is below 0.5 on rows scoring about 6, so under the owner rule it should ride inside a larger change, not land alone.

## Frames
`tb/gpu-frames-1108`, High, three sections:
- `G-places-roadvalue-storm` (a6e992aa9);
- `G-places-roadvalue-locations` (f80209d9d);
- `G-places-roadvalue-dialogue` (bba97ce20).

**Sides:**
- **base:** main 328c598ae (#914).
- **roadnp:** `tb/places` 66b68b8c8 with a local "match main" overlay and `PLACES-ROADVALUE/overlay_no_puddles.json`.
  - The "match main" overlay sets `storm_phase_1111` on, Building far_bolts 0.0 and `distinct_bodies_1111` on.
  - Every manifest row records the places sha as "tree". The base side was really main 328c598ae.
- **Held:** the GPU lane held the `road` arm (with puddles) under the reject rule. It adds lilac-white puddle slabs; at struck_sentinel the lilac share in the lower half rises from 0.46% to 1.11%.
- **Caveat:** Bryn's albedo is the older cached import on all sides. Discount Bryn in F41#8.
- 0 blank, 0 script errors.

## Sets and batches
**Sets:** the same as `G-places-stormlight.md`, restricted to the rows these sections cover: F41#2 (four phases), F41#4, F41#5, F41#12 and F41#8 (stacked).

**Batch `G-rv`:**
- Three code-blind judges, standard prompt.
- Anchors: craft, f36_0_npc:C1 and f10_2_r3_capacitor. Confirming batch.
- **Fit:** slope 1.166, intercept −0.4778, r 0.845, RMSE 0.739. This is a loose fit.
- **Process note:** judge c's hand-back carried only a summary. I took judge c's JSON verdict from its own full reply in its task transcript, unchanged.

**Batch `G-rv4`:** a fresh batch of three new judges on F41#4 alone, with the same anchors.
- **Why:** in `G-rv` all three judges' notes on F41#4 praised the brown road, but they scored the side that has the darker road higher. I checked the key and the image. The key was correct: side A (left) is the arm, and the arm's road is warmer brown.
- **Fit:** slope 1.2568, intercept −1.207, r 0.896, RMSE 0.614.

## Results

| Row | Base raw → mapped | Arm raw → mapped | Gain | Prefer arm |
|---|---|---|---|---|
| F41#12 charged road surface | 5.5, 5.5, 5.7 → 6.01 | 5.8, 5.9, 6.1 → **6.44** | +0.43 | 3/3 |
| F41#5 forest ground and distance layers | 5.3, 5.4, 5.4 → 5.78 | 5.6, 5.7, 5.8 → **6.17** | +0.39 | 3/3 |
| F41#2 Surge phases | 5.5, 5.8, 5.6 → 6.09 | 5.8, 6.1, 5.8 → **6.40** | +0.31 | 3/3 |
| F41#8 named character silhouettes | 5.5, 5.6, 5.6 → 6.01 | 5.8, 5.7, 5.8 → **6.25** | +0.24 | 3/3 |
| **F41#4** named destination identities (`G-rv`) | 5.8, 5.9, 5.9 → 6.36 | 5.6, 5.7, 5.7 → 6.13 | **−0.23** | 0/3 |
| **F41#4** rejudge (`G-rv4`) | 5.6, 5.6, 5.9 → 5.96 | 5.5, 5.6, 5.8 → 5.87 | **−0.09** | 0/3 (1 tie) |

### What the judges see
- **The arm's road (3/3 in `G-rv`):** "brown, textured mud with value variation" against "a near-black, almost unshaded strip ... reads as a hole". On the arm, the gold line "sits in believable mud".
- **F41#4:** the `G-rv4` judges call the two sides "almost the same picture". The one difference they name is that base's gold path line is "a little brighter / more saturated" in frame 2. Read together with the `G-rv` contradiction, F41#4 is a small, repeatable loss from **the gold line losing contrast on the lighter umber road**, not from the road material itself.
- **Recorded defects:**
  - F41#12 "thick gold stripes": PARTIAL 3/3 on both sides.
  - F41#2 phases: base PRESENT 1/3, arm PARTIAL 3/3. Judge b: the arm's "Break bolt" is "the best phase read in the batch", but "Calm and Building are the same frame".
  - F41#5 carpet: PRESENT on base, PRESENT or PARTIAL on the arm.

## What still holds these rows down (3/3)
1. **Flat distance:** a flat lavender fog band with a cut-out treeline, uniform turf with evenly scattered pebbles, and no groves or depth steps (F41#4 and F41#5).
2. **Off-palette colour:**
   - salmon-pink conical stumps and trunks (F41#4);
   - pastel-peach bears (F41#8).
3. **The charged road line:** one thin gold line with no glow onto the ground, no branching and no white-violet lightning (F41#12).
4. **Storm phases:** Calm and Building are still indistinguishable (F41#2). Fading's mist puffs read as sprites.

## Recommendation
1. **Keep the no-puddles road arm flag-off for now.**
2. **Fix F41#4 before it rides along:** restore the gold line's contrast on the umber road, with more emissive or a dark edge so it stays as bright as on base. That should remove the F41#4 loss.
3. **Ride it inside the next Stormwood swing:** the treeline and depth layers, plus the salmon and peach recolour, so the whole change clears 0.5.
4. **Keep the held puddle arm held:** its lilac slabs are the defect the judges keep naming.
