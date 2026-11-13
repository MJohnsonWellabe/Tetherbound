# G-places-swing2: Stormwood road value with a brighter, branching gold current (LANE-PLACES; GPU High)

## Verdict: DO NOT SHIP

| Row | Base | Swing2 | Gain | Judges preferring base |
|---|---|---|---|---|
| F41#12 | 6.07 | 5.36 | −0.71 | 3/3 |
| F41#5 | 5.69 | 5.53 | −0.16 | 3/3 |
| F41#4 | 5.95 | 5.78 | −0.17 | 2/3 |
| F41#8 | 5.36 | 5.74 | +0.38 | 0/3 (all prefer swing2) |

Three rows lose and one gains. The contrast boost brings back the defect the earlier rounds had removed: the gold road charge reads as "thick, saturated gold stripes" again.

## Frames

From `tb/gpu-frames-1108`, High. Both sides were captured from `tb/places` e83c4119b, which contains #914.

**Sections:**
- `G-places-swing2-locations` (5cf286cae)
- `G-places-swing2-dialogue` (702c3c532)

**Sides:**
- **base:** overlay off.
- **swing2:** `PLACES-STORMWOOD2/overlay.json`, which turns on `road_value_1112`, `road_current contrast_1112` and `fading_clear_1112`.

0 blank frames and 0 script errors.

**Held by the GPU lane:** the F41#2 storm-phase set. A white lightning bolt still crosses the Fading sky on all three sides, and `fading_clear_1112` does not remove it. Fading is also only slightly brighter than Building, with a sky L of 105 → 113 on swing2.

**GPU lane's measurements:**
- The share of yellow pixels in the lower half rises at every stand, for example lantern_pools 0.35 → 1.59%.
- Lilac is unchanged except at crown_heartstone, where it rises 0.50 → 0.83%.
- In Bryn's frame the current turns into a network of looping veins across the whole road.

## Batch `G-s2`
- Three code-blind judges, standard prompt.
- Sets: the four rows, in the same format as `G-places-roadvalue.md`.
- Anchors: craft, f36_0_npc:C1 and f10_2_r3_capacitor. This is a confirming batch.
- **Fit:** linear, slope 1.2655, intercept −1.1812, r 0.902, RMSE 0.598. No warnings.

## Results

| Row | Base raw → mapped | Swing2 raw → mapped | Gain | Prefer swing2 | Recorded defect, base → swing2 |
|---|---|---|---|---|---|
| **F41#12** charged road surface | 5.5, 5.9, 5.8 → 6.07 | 4.9, 5.4, 5.2 → 5.36 | **−0.71** | 0/3 | "thick gold stripes" PARTIAL 3/3 → **PRESENT 3/3** |
| F41#4 named destination identities | 5.4, 5.8, 5.7 → 5.95 | 5.4, 5.6, 5.5 → 5.78 | −0.17 | 0/3 (1 tie) | PARTIAL 3/3 on both sides |
| F41#5 forest ground and distance | 5.2, 5.7, 5.4 → 5.69 | 5.0, 5.6, 5.3 → 5.53 | −0.16 | 0/3 | PRESENT or PARTIAL on both |
| F41#8 named character silhouettes | 4.9, 5.4, 5.2 → 5.36 | 5.3, 5.5, 5.6 → **5.74** | +0.38 | 3/3 | PARTIAL 3/3 on both sides |

### What the judges see
- **On swing2 (3/3):** "thick, bright, saturated gold stripes run the full length of the road in all three views, as a flat repeated pattern", "worst in frame 2 (the bright zigzag in the foreground)". In F41#4 the veins "pull the eye away from the destinations". In F41#5 they "add pattern noise without depth".
- **On base (3/3):** "fewer and thinner lines that read more as a charged accent", but the road is "crushed to a near-black slab with hard straight edges" and "the characters' feet vanish into it".
- **Why F41#8 gains:** on that row's frames the base road is the crushed black slab, so the swing2 current lifts the ground under the villagers.
- **Bryn's busy veins:** the GPU lane asked whether the vein network in Bryn's frame reads as busy. The judges did not single out Bryn. Read together with `G-places-roadvalue.md`, the pattern is that the road needs both value and restraint:
  - The umber road wins against the black slab (F41#5 +0.39 and F41#12 +0.43 in road value).
  - A bright, wide or branching gold current loses (F41#12 −0.71 here).
  - The F41#4 loss in road value came from a line that was too faint.

## What still holds these rows down (3/3)
1. **Ground value and edges:** the near-black or muddy road slabs have hard, straight edges against the grass.
2. **The charge:** judges ask for "sparse, thin, white-violet flicker segments", not long gold stripes. The board's lightning is white-violet, not gold.
3. **Depth:** a flat lavender fog band with a low card treeline, no giant mid-ground trunks, an even grass carpet, and a flat lavender skybox with no shafts.
4. **Off-palette colour:** salmon-pink bears and pink or copper distant tree cards.

## Recommendation
1. **Drop the `road_current contrast_1112` branching and brightening.**
2. **Keep the umber road from the road-value arm.** Give its current a single thin line with a dark edge, or move the line toward white-violet, rather than more gold.
3. **Fold `fading_clear_1112` into the F41#2 storm-phase work.** The Fading bolt has to go before that set can be judged.
