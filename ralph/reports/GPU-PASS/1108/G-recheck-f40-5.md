# G-recheck-f40-5: one-sided re-score of F40#5 on main (GPU High)

Frames: `tb/gpu-frames-1108` 38970534b, main e1c941cbd, High. Blank frames: 0 of 38.

Frames judged: live-2491, live-3571 and live-3931, in one row, left to right.
- They are the 8 Nov judged frames (live-2430, live-3510 and live-3870), matched by simulated time.
- All three fall in rounds 1–2, which the trainer wins.
- Since 8 Nov the fight dust was retuned (#882).

Brief: F40#5, captain fight camera orientation, with its recorded defect.

Batch `G-rf5`:
- three code-blind judges, standard prompt;
- anchors: craft, f36_0_npc:C1 (7.47/7.53) and f10_2_r3_capacitor, so this is a confirming batch.

Fit: linear, slope 1.2888, intercept −1.2761, r 0.927, anchor RMSE 0.518. No warnings.

## Verdict: F40#5 = 7.06 mapped at High (was 5.94 on 8 Nov)

| | Judge a | Judge b | Judge c | Mean |
|---|---|---|---|---|
| Raw Bar A | 6.6 | 6.4 | 6.4 | 6.47 |
| Mapped | 7.23 | 6.97 | 6.97 | **7.06** |

- The mapped score is not above the top anchor.
- +1.12 over the 8 Nov score, so F40#5 is now at 7.
- It is under 7.5, but at 7.0 or above it is a close-out candidate under the owner's 25 Oct exception.
- Medium is not captured; per the 31 Oct order it runs only once High reaches 7.5.

**Recorded camera defect:** judge a FIXED; judges b and c PARTIAL.

**Round 3 fixture loss:** no judge raised it (the judged frames are in rounds 1–2).

## What the judges see
- **Dust no longer covers the exchange.** No judge mentions dust or particles obscuring any frame. That was the main 8 Nov complaint, so the #882 retune shows here.
- **Frames 2–3:** Aeriex and the Mudsnout boar are both framed, and the white ground rings show the attack direction (3/3).
- **Frame 1, the remaining defect (judges b and c):**
  - the boar is out of view;
  - Sparkit is half-hidden behind the team HUD;
  - the trainer is cropped at the bottom edge.
  - Judge a reads frame 1 as Sparkit and Aeriex facing each other across a dashed telegraph, and marks the defect FIXED.
- **Subject:** a clean, appealing pale-blue crested bird with a readable silhouette. It is a little more stylised and smooth than the owner's style bar, with soft plume tips.

## Remaining drags
- **Lighting:** flat midday light with weak rim light on the subject and weak contact shadows (3/3).
- **Arena:**
  - a flat tan floor disc;
  - kitbash dressing (a black chimney or tower prop, banners, hedges) rather than the board's pale stratified stone (judges a and b);
  - a washed-out sky (judge c).
- **HUD:** in frame 3, Aeriex's tail runs under the left HUD (judge a).
- **Red banners in the arena** (judge a): correct if this is a Team Tether captain arena. Flagged only for the row owner to confirm.

## What would close it (all scene)
1. **Frame 1:** keep the opponent in frame during the incoming warning, and lift the trainer and ally clear of the HUD and the bottom edge.
2. **Light:** add a rim light on the creatures and a brighter Cloudreach sky grade.
3. **Arena floor:** replace the flat tan disc with pale stratified stone.
