# G-newapproach-wave-crests: crest_shape 1 wave crests, owner design (CARD:T2, F13#5)

Frames: `tb/gpu-frames-1108` 24c40e196, High, with the current arrow OFF on both sides.
- **Both sides:** `water_current_flow.gdshader` at 417076a37, with crest_shape default 0, which is the shipped arcs.
- **Arm:** adds `overlay_crests.json` (crest_shape 1, width 4.6 m, length 2.6 m, speed 1.9; chop_cap_opacity 0.5).
- **Captures:** strips at 0.1 s per step, plus GIFs.

**GPU lane's flag:** by day the crests break into hard-edged shards that flicker from frame to frame.

## 1. Blind direction test (strips)
Same method as `G-newapproach-waves`:
- Six shuffled, unlabelled time strips (water crop, five moments 0.2 s apart), judged by three fresh judges.
- Truth: across = RIGHT; both away views = TOWARD_CAMERA.
- Data: `yardstick_g_crest/direction_test_strips.json`.

| View | Side | Correct | Answers | Mean confidence | Mean readability |
|---|---|---|---|---|---|
| swim-away-day | base | 0/3 | AWAY, CANNOT_TELL, LEFT | 3.3 | 2.7 |
| swim-away-day | **arm** | **0/3** | CANNOT_TELL ×3 | 2.0 | 1.0 |
| swim-away-night | base | 2/3 | AWAY, TOWARD, TOWARD | 5.7 | 4.3 |
| swim-away-night | **arm** | 2/3 | AWAY, TOWARD, TOWARD | 3.3 | 2.0 |
| swim-across-day | base | **3/3** | RIGHT ×3 | 7.0 | 6.0 |
| swim-across-day | **arm** | 2/3 | CANNOT_TELL, RIGHT, RIGHT | 2.7 | 1.7 |

**swim-away still fails.** Day is 0/3 on both sides, and night is 2/3 on both. The arm lowers confidence and readability in every view, and loses swim-across from 3/3 to 2/3. On the arm strips the judges see "almost no crests", "a few faint streaks", "only a pale fan-shaped spray wedge".

**An important observation from one judge.** In the away views the camera follows the swimmer, who is carried by the current. Against fixed objects (the rock, the logs), the crests drift down-screen *more slowly* than the scenery, so relative to the world they move *away* from the camera. Two of three judges on base and one on the arm read AWAY_FROM_CAMERA for this reason.

In a camera that follows the swimmer, the water and the swimmer move together. A cue that is the water's own motion can therefore look backwards against the shore. This is the same problem LANE-NEWAPPROACH found with debris ("at swimmer scale, the swimmer and everything floating are carried at the same speed"). Waves alone will struggle in the toward-camera case, whatever the crest shape.

## 2. Paired look score (each side shows four moments 0.3 s apart)
Batch `G-crest`:
- Three code-blind judges and the standard prompt.
- Recorded defect: direction not readable at a glance.
- Pinned anchors are craft, f10_2_r3_capacitor and f04_6_r22, so this is a confirming batch.
- Fit: linear, slope 1.7212, intercept −3.9002, r 0.900, anchor RMSE 0.504. No warnings.

| View | Base | Arm | Gain | Judges preferring arm |
|---|---|---|---|---|
| swim-across-day | 6.25 | 5.57 | **−0.68** | 0/3 |
| swim-away-day | 6.14 | **4.99** | **−1.15** | 0/3 |
| swim-away-night | 6.48 | 5.74 | **−0.74** | 0/3 |

## What the shards cost
They are worst in swim-away-day, at −1.15. On the arm side all three judges flag them unprompted as artefacts:
- "hard-edged white wedges and slabs … look like artefacts, not foam";
- "flat white wedge or slab shapes … hard-edged geometric artefacts".

Elsewhere on the arm the crests are "small short white dashes scattered evenly … disappear at 30%". On the base side, the shipped crescent arcs are preferred in every view. They are "crisp, stamped-on" too, but they give the direction partly.

## Verdict
**DO NOT SHIP.**
- The arm loses −0.68 to −1.15 with 0/3 in all three views.
- The direction test gets no better (swim-away-day still 0/3) and confidence drops everywhere.
- The day shards read as rendering artefacts.

**This is the second failed attempt at an in-water cue on this item** (waves, then crests). Under the owner's 25 Oct rule, park it until there is a new idea. Any new idea has to address the camera-follow problem above.

**Keep the shipped arcs and the arrow.** The arrow scored 18/18 at confidence 9 earlier today. Whether the in-water cue replaces the arrow or adds to it remains the owner's call.

**Cheaper fixes all three judges named again, independent of the cue:**
1. Remove the vertical tint or seam band left of the swimmer. It appears in every T2 batch today.
2. Fix the night grade: the 23:00 views are lit like daylight.
3. Remove the stray white poles in the water by the shore.
