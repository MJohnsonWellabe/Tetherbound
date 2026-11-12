# G-newapproach-edge-cards: cumulus cards replace the terrace-lip mist lumps (F40#11; GPU High)

Frames: `tb/gpu-frames-1108` b013a69c9, High, `--fixed-fps 20`, seed 2042.
- Tree: main 5b0f2c924 (#903) plus `scripts/world/cloudreach_world.gd` from `tb/newapproach` 422cf4dbd, on both sides.
- Capture: `phase2_capture_cloudreach_ride.gd`.
- base = island_roots.mist_style volume_bank.
- arm = base + `NEWAPPROACH-EDGECARDS/overlay_edge_cards.json`: mist_style cumulus_cards, camera-facing cloud_bank_v1 cards with ground and near fades.

Sheet: frames 16 (mounted at the edge), 17 (terrace, 1.0 s) and 18 (terrace after), stacked at full size, on F40#11's brief and recorded defect as in `G-newapproach-cloud-plane.md`.

Render check: 9.1%, 3.9% and 11.2% of pixels changed. Blank frames: 0 of 3 per side.

Batch `G-ec`:
- three code-blind judges, standard prompt;
- anchors: craft, f36_0_npc:C1 (7.47/7.53) and f10_2_r3_capacitor, so this is a confirming batch.

Fit: linear, slope 1.2886, intercept −1.3105, r 0.951, anchor RMSE 0.429. No warnings.

## Verdict: SHIP. +0.73, 3/3 prefer

| Row | Base | Arm | Gain | Judges preferring arm | Board |
|---|---|---|---|---|---|
| F40#11 terrace edge clouds | 5.26 | **5.99** | **+0.73** | **3/3** | 5.50 |

Raw Bar A, base → arm (judges a, b, c): 5.0, 5.0, 5.3 → 5.6, 5.6, 5.8.

Recorded defect, "flat white polygonal cloud puffs ... read as loose foreground shapes":
- base: PRESENT for judges a and c, PARTIAL for judge b;
- arm: PARTIAL 3/3.

F40#11 rises to 5.99, just under 6.

## The GPU lane's concern: crisper cards read as pasted on
**The judges confirm it (3/3).** The cards gain because they are no longer flat. They lose part of that gain because they read as separate clumps in the wrong value and hue:
- judge a: "lavender-grey, much darker and bluer than the white cloud floor ... In frame 2 they look like smoke banks pasted beside the rider";
- judge b: "tinted lavender-grey and cluster as a separate pile hugging the deer and the cliff lip (worst in frame 2). They still read as loose foreground objects sitting on the cloud floor rather than rising out of it";
- judge c: "they are tinted lavender-grey, darker than the cloud floor they sit on. They still sit as separate clumps along the cliff lip".

**The base puffs** are "smooth white blobs with no internal form ... bright opaque balloons" or "soft plastic balls stuck to the cliff edge" (3/3).

**The fix the judges ask for (3/3):** keep the card form, but match the cloud floor's white. Use sunlit tops and cool shadowed undersides, not lavender (the GPU lane measured hue 240 against the banks' 221), and soft, depth-faded bases so the cards well up out of the floor.

## What still holds F40#11 down (both sides, 3/3)
- **Cloud floor:** "a flat sheet of pale faceted polygons with visible triangular value patches ... a low-poly plane, not a cloud sea". This is now the largest single drag.
- **Grade and cliffs:** the distant cliffs are fog-washed to flat beige; there is no bright blue sky or sunlit stratified stone.

## What would add the most (all scene)
1. **Cloud floor:** replace the faceted plane with a soft, lit cloud-sea material (noise, white tops, blue shadows) that wraps the cliff base.
2. **Card colour:** retint the cards to the floor's white, with depth-faded bases.
   - On its own this is a small change likely to gain under 0.5. It should ride with item 1.
