# Tidewake close-1024 round rd1: F39#4 gully rock detail, material only (24 Oct 2026, CT)

- **Why.** The coordinator ruled that F39#4 is fixed in the terrain, not by moving the camera: "use the smallest change that removes the stretch".
- **What changed.** `veilfall_rock_detail_candidate` changes only the terrain material (`water_veilfall_rock.gd` uniforms):
  - the triplanar cliff texture tiles every ~9 m instead of ~28 m;
  - runnels are 9 m long instead of 30 m, and narrower;
  - bedding is every 4.5 m instead of 9 m, with more lift;
  - stock-albedo detail drops from 0.6 to 0.15;
  - rock starts further down the slopes (`slope_lo` 0.55 → 0.68).

  No heightfield, collision or route change.
- **Capture.** `tb/tidewake` c09b3a7fc or later. Shipping includes the limestone and the rock family ON. CPU llvmpipe, Low.
- **Yardstick:**
  - Standard prompt verbatim, three fresh code-blind judges.
  - 3 anchor pairs, seed 11717.
  - `calibrate.py`: slope 1.199, r 0.96, anchor RMSE 0.27. This is a confirming batch, extrapolated below the anchors.

## Mapped Bar A (CPU pre-judge)

| View | Shipping | Rock detail | Δ | Judges |
|---|---|---|---|---|
| Veilfall close-up, clear and rain | 4.34 | 3.94 | -0.40 | lower x3 |
| Four shore and lesson views | 6.46 | 6.34 | -0.12 | 2 lower, 1 level |
| Venn fight, matched moments | 5.10 | 4.86 | -0.24 | lower x3 |

**The candidate loses, so it stays OFF.**

## What this says

The judges read shipping's long runnels as "wet-streak detail" that "breaks up the smear" (side B, the shipping side, in their words). The candidate's finer texture made the slabs read flatter.

The "stretched, smeared" defect they keep naming is the slab geometry itself: a few huge faceted terrain faces filling the frame. It is not the shader. So the material route is exhausted:
- vf1 (limestone): ON
- rf1 (one rock family): ON
- rd1 (rock detail): loses

## Next step for F39#4

What remains is geometry, the heightfield in that gully. Two routes:
- break the faces up with real relief, which is a terrain bake on the hike, so it needs a route and walk check and the earned-save pieces;
- or have Meshy produce a slab-wall that hugs these exact faces. vf3 showed a free-standing piece reads as pasted on.

Both are larger than "smallest change". The coordinator's call.

## Files

- `batch.json`, `mapped.json`, `key.json`
