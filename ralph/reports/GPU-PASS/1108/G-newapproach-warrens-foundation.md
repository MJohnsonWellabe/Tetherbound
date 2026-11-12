# G-newapproach-warrens-foundation: F38#30 Burrow Warrens hillside, F38#24 distant mountains (GPU High)

Frames: `tb/gpu-frames-1108` e954ee827, High, seed 2042.
- base = `tb/newapproach` b2522d3a0.
- arm = base + `NEWAPPROACH-WARRENS2/overlay_foundation.json`: a grass foundation with collision under the chamber shells, plus the buried-stand guard. In walk_03 the stand moved 3.3 m up because the old spot is now inside the hill.

Render check (pixels changed by more than 30): walk_02 1.7%, walk_03 49.3%, route_day 5.6%.

Batch `G-wf`:
- three code-blind judges, standard prompt;
- each walk frame judged on **each** row's catalogue brief and defect;
- route_day as the no-loss check;
- anchors craft, f10_2_r3_capacitor and f04_6_r22, so this is a confirming batch.

Fit: linear, slope 1.0589, intercept 0.4694, r 0.849, anchor RMSE 0.611.
Warning (verbatim): `some candidates lie more than 0.5 outside the anchors' measured range (extrapolated)`. The walk scores, about 3, sit below the lowest anchor, so treat their exact values loosely. The gains and preferences are unaffected.

## Verdict: SHIP (gain > 0, 3/3 prefer on every changed frame, no loss on walk_02 or route_day). Neither row closes or reaches the floor.

| Frame | Row | Base | Arm | Gain | Judges preferring arm |
|---|---|---|---|---|---|
| walk_02_day | F38#30 hillside | 4.56 | 4.56 | 0.00 | tie (frames near-identical) |
| walk_02_day | F38#24 mountains | 3.72 | 3.72 | 0.00 | tie |
| **walk_03_day** | F38#30 hillside | 3.08 | **3.65** | **+0.57** | **3/3** |
| **walk_03_day** | F38#24 mountains | 3.08 | **3.65** | **+0.57** | **3/3** |
| route_day (no-loss check) | — | 5.94 | **6.40** | **+0.46** | **3/3** |

Raw Bar A (judges a, b, c):
- walk_03 mountains: 2.6, 2.2, 2.6 → 3.2, 2.6, 3.2.
- walk_03 hillside: 2.6, 2.2, 2.6 → 3.0, 2.8, 3.2.
- route_day: 5.6, 5.3, 5.0 (base) → 5.6, 5.6, 5.6 (arm), as given in the judges' A/B order after key mapping.

**Row means** (walk_02 and walk_03):

| Row | Base | Arm | Gain |
|---|---|---|---|
| F38#30 | 3.82 | 4.11 | +0.29 |
| F38#24 | 3.40 | 3.69 | +0.29 |

These are close to the board's 4.00 and 3.67.

## What the arm fixes
- **walk_03 base:** huge black, unlit floating slabs or drums, a debris cloud and leaf cards fill the sky, with a flat grey box rock by the trainer (3/3: "severe artefact", "broken render"). The arm removes them all.
- **route_day:** base has black triangular shards and dark gaps on the right hillside and the entrance roof. The arm is cleaner, which is where its +0.46 comes from.

## Why both rows stay far below 6
- **walk_03 arm: the camera now faces a blurry, stretched moss slope that fills about 70% of the frame (3/3).** The new seat is 3.3 m higher, and from it neither subject is in frame. The mountains are a faint pale band at the far left, and the Burrow hillside is not visible. One judge marked the hillside defect "FIXED" only because the face is out of frame.
  - The next gain for both rows is a stand that frames its subject from open ground, which is a camera-set change for the lane.
- **walk_02 (unchanged):**
  - the hillside still shows the broad diagonal brown band with a dark cut at its base (PRESENT/PARTIAL);
  - the "mountains" are pale-blue faceted shards over a near bank, not a range (PRESENT 3/3);
  - the bank texture is blurry and stretched.
  - Judges' fixes: new art for a continuous layered mountain backdrop, and a sculpted, eroded earth bank.
- **route_day:** the smoke column reads as a stiff solid pillar or cone, the mound has smeared brown bands, and a flat plank door blocks the entrance.

## Flag: red trees beside the Burrow entrance
All three judges named the saturated crimson trees left and right of the Burrow entrance as red on friendly ground. Recolouring them to a non-red autumn hue is cheap and protects the Team Tether rule.
