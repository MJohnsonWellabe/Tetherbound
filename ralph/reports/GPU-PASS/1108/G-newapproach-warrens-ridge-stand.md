# G-newapproach-warrens-ridge-stand: Blender ridge ring + walk_03 heading 215 (F38#24 distant mountains, F38#30 Warrens hillside; GPU High)

Frames: `tb/gpu-frames-1108` fdb473cae, High.
- base = `tb/newapproach` e43aaa7d3.
- arm = base + the `meadows_ridge_vl` ridge ring (replacing the faceted procedural horizon rings), with walk_03 turned to heading 215.
- Frames: Warrens walk_02, walk_03 and route_day, plus the stronghold approach route_day. Together these are all of F38#24's 8 Nov frames.
- **Note on composition.** This base still shows the floating black drums at walk_03, and the arm shows the closed grass hillside and the green flank right of the mound at route_day. So this arm also carries the Warrens foundation; it is not the ridge alone.

Render check (pixels changed by more than 30): walk_02 2.1%, walk_03 67.1%, Warrens route_day 6.5%, stronghold route_day 14.4%.

Batch `G-rs`:
- three code-blind judges, standard prompt;
- each row's own catalogue brief and defect;
- Warrens route_day as the no-loss check;
- anchors: craft, f10_2_r3_capacitor and f04_6_r22, so this is a confirming batch.

Fit: linear, slope 0.936, intercept 1.3003, r 0.814, anchor RMSE 0.669.
Warning (verbatim): `some candidates lie more than 0.5 outside the anchors' measured range (extrapolated)`. The walk scores sit below the lowest anchor, so treat their exact values loosely.

## Verdict: does NOT pass the ship rule as built. One frame loses: Warrens route_day, −0.22, 0/3.
The loss comes from the foundation flank, not the ridge. **The ridge itself is a clear win**: stronghold +0.75, 3/3, F38#24's best frame now 7.26. Recommendation: **ship the ridge ring** (alone, or with the flank re-textured), and fix the flank texture before it ships again.

| Frame | Row | Base | Arm | Gain | Judges preferring arm |
|---|---|---|---|---|---|
| **stronghold route_day** | F38#24 | 6.51 | **7.26** | **+0.75** | **3/3** |
| walk_03 | F38#24 | 3.64 | 3.95 | +0.31 | 3/3 |
| walk_03 | F38#30 | 3.48 | 3.92 | +0.44 | 3/3 |
| walk_02 | F38#24 | 4.11 | 4.11 | 0.00 | tie (unchanged) |
| walk_02 | F38#30 | 5.01 | 5.04 | +0.03 | 1/3, 2 ties |
| **Warrens route_day (no-loss check)** | — | 6.51 | 6.29 | **−0.22** | **0/3** |

Raw Bar A (judges a, b, c):
- stronghold: 5.6, 5.5, 5.6 → 6.3, 6.4, 6.4.
- walk_03 hillside: 2.3, 2.3, 2.4 → 3.0, 2.6, 2.8.
- walk_03 mountains: 2.5, 2.5, 2.5 → 2.8, 2.7, 3.0.
- route_day: 5.7, 5.6, 5.4 → 5.4, 5.4, 5.2.

**Row means:**

| Row | Base | Arm | Gain |
|---|---|---|---|
| F38#24 (walk_02, walk_03, stronghold) | 4.75 | **5.11** | +0.36 |
| F38#30 (walk_02, walk_03) | 4.25 | **4.48** | +0.23 |

## Why route_day loses
- All three judges say the arm's right-hand hill is "blurrier", "more stretched" and "smeared".
- A crop of the right third confirms it: the arm replaces the base's broken right flank (dark gaps and shards under the bush) with a **large, smooth, low-resolution grass slab**, reading as a stretched texture.
- The new distant range at the far right is small and is not what the judges marked down.
- This is the foundation flank seen from the route.
- In the earlier `G-newapproach-warrens-foundation` batch (a different base), the same flank won route_day +0.46 against a base with black shards. Against this base it loses −0.22. Either way, its texture is the weak point.
- **Fix:** give the flank the terrain's grass and earth blend at full texel density, or a grass scatter.

## What the ridge does
- **stronghold:** the faceted horizon becomes a continuous, cool-blue, snow-capped range with haze, and the defect moves from PRESENT to FIXED/PARTIAL (3/3).
  - **Remaining:** hard facets at the right end behind the oak (2/3), and the range reads "slightly photographic and flat next to the stylised castle" (1/3).
  - At 7.26, this frame is near-bar.
- The castle's red banners are Team Tether; the judges accepted them.

## Why both rows stay low
- walk_02 is still a close blurry hillside with the brown band and dark cut (F38#30 PRESENT 3/3). Its "mountains" are pale-blue shards poking over the crest (F38#24 PRESENT 3/3). Neither subject is properly framed.
- walk_03's new heading shows open meadow and a small blue range on the right, but the slope still fills about 70% of the frame. The hillside subject is not in view.
- Both rows need **camera stands that frame their subject** (a camera-set change for the lane) before the art work can show.

## Flags (unchanged from the last batch)
- The crimson bushes beside the Burrow entrance read as red on friendly ground (3/3).
- Floating leaf shards around the mound.
- A stiff, opaque smoke column through the entrance.
