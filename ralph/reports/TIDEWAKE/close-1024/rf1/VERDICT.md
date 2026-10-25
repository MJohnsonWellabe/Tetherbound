# Tidewake close-1024 round rf1: one rock family at the Veilfall (24 Oct 2026, CT)

- **Why.** Every judge since ls1 named the same ask: the shipped pale limestone terrain and the near-black formation slabs and crown crags read as different rock families.
- **What changed.** `veilfall_family_candidate` is a material change only:
  - the gate formations (`exterior_composition` `rock_tint` #5a6468 → #a39b8a, roughness 0.85);
  - the crown kitbash crag shader (body, wet and crown colours → limestone tones, strata 0.07 → 0.14).

  Geometry, collision and route clearances are unchanged.
- **Capture.** `tb/tidewake` 6fbded1d2 or later, CPU llvmpipe, Low, 1920x1080.
  - Shipping is the limestone ON; the candidate adds the family section.
  - Views: veilfall-near and veilfall-rain, the seven F39-look shore and lesson views, and the Venn fight. The fight is judged as matched moments: tell-start 0.65, hit 0.70, hit 1.08 and tell-ended 1.32 s, the states both seeded runs share before they diverge.
- **Yardstick:**
  - Standard prompt verbatim, three fresh code-blind judges.
  - 3 anchor pairs, seed 9595.
  - `calibrate.py`: slope 1.239, r 0.97, anchor RMSE 0.38, top anchor 7.53. This is a confirming batch with no extrapolation warning.

## Mapped Bar A

| View | Shipping | Rock family | Δ | Judges |
|---|---|---|---|---|
| Veilfall close-up from the camp, clear and rain | 3.90 | **4.51** | **+0.61** | higher x3 |
| Seven F39-look shore and lesson views | 6.08 | 6.08 | 0.00 | level x3 |
| Venn fight, matched moments | 4.85 | 5.01 | +0.16 | 2 higher, 1 level |

**It beats shipping where it shows and regresses nowhere, so `veilfall_family_candidate` ships ON.** It is below 6.7, so F39#4 and F39#5 stay open.

## What the judges still see

- **Close-up:**
  - The crown boulders are now "pale tan textured stone". Near-black slabs moved from PRESENT to PARTIAL (x3).
  - Two problems remain. The right-hand cliff planes are still "flat dark polygon planes" in shadow. The tan boulders and the green-grey streaked terrain still read as two families: PRESENT x3, though closer.
  - The falls are a "small white puff". The Meshy facade (vf3) is the next step for both.
- **Fight:** the "black slab" in the top right is unchanged in all three judges' frames. It is not the kitbash or the formations this round touched; the likeliest source is the far silhouette or ridge blockout, which needs identifying.
- **Shore:** the even pebble scatter, the empty dune sand and the black night sky.

## Files

- `batch.json`, `mapped.json`, `key.json`
- `_sheet_rf1.jpg` (left: shipping, right: rock family)
