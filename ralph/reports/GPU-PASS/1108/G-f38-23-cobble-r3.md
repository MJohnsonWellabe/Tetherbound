# G-f38-23-cobble-r3: F38#23 Tether Relay yard cobble r3, at Medium

Frames: `tb/gpu-frames-1108` 4ee6f5727, **Medium**, 2 frames: relay `route_day` and `vista_dusk`.
- **Live:** main 52a633598.
- **Arm:** live plus `tether_relay.gd` and `tether_relay.json` at 39fb00578, plus `ITEM-F38-23/overlay_cobble_r3.json` (`surface_candidate.r3` on).
- **Blank-frame receipts:** 0 of 5 on both sides.

## Pre-judge render check

| Frame | Pixels differing by more than 8 levels | Pixels differing by more than 30 levels | Mean luma, live → arm |
|---|---|---|---|
| `route_day` | 10.3% | 0.6% | 112.2 → 108.9 |
| `vista_dusk` | 3.3% | 0.5% | 85.8 → 83.6 |

The arm is in frame (a modest, frame-wide darkening of the cobble), so this batch is valid.

Batch `G-cob`:
- Three code-blind judges and the standard prompt.
- Pinned anchors are craft, f10_2_r3_capacitor and f04_6_r22, so this is a confirming batch.
- Fit: linear, slope 1.3589, intercept −1.2373, r 0.875, anchor RMSE 0.557. No warnings.

| Row | Preset | Live | Arm | Gain | Judges preferring arm | Mapped arm (j1, j2, j3) |
|---|---|---|---|---|---|---|
| F38#23 | Medium | 6.42 (raw 5.5, 5.8, 5.6) | **6.42** (raw 5.5, 5.8, 5.6) | **0.00** | 0/3 (3 ties) | 6.24, 6.64, 6.37 |

**The mapped Medium arm score is 6.42, below 7.5, so there is no High confirmation shoot and F38#23 does not close.**

All three judges called the two sides "nearly identical". The r3 surface darkening does not register as a difference at this size.

The recorded defect ("tall flowers and grass grow densely through the flat trafficked relay yard") is **FIXED on both sides (3/3)**. That is the earlier yard-clearing work, already on live.

Note on earlier scores: F38#23 was High 7.58 and Medium 7.07 in earlier pools. This pool scores the live Medium at 6.42, about 0.65 lower on the same subject, a reminder that single-batch absolute scores move with the pool.

## What holds F38#23 below the bar (3/3)
- **The empty cobble plane:**
  - It fills about 60% of every frame: a uniform tiled cobble with no wear, cart ruts, puddles or edge clutter.
  - It washes out to pale grey-cream in the day frame and to flat orange-brown under the dusk grade.
- **Thin staging:** the props (cage, guards, crates, ramp) are small, sit along the back wall and are evenly spaced, so the yard "reads like a stage set".
- **The right-hand wall:** a large blank block with little surface detail (judge a).
- **What works:** the stone arch and gatehouse read well. The red banners are correct, since this is a Team Tether site.

**Next change the judges name:** dress the near and mid yard. That means:
- wear and rut variation in the cobble material;
- clustered working props at the yard edges and in the foreground;
- a warm key with a cool fill, so the dusk grade does not flood the cobble one colour.

This is a scene change, not more surface tuning.
