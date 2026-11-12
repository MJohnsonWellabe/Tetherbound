# G-newapproach-flowfoam-fronts-v3: closer, thinner, unevenly spaced swell lines (CARD:T2, F13#5)

Frames: `tb/gpu-frames-1108` 88ac9afeb (the same frames as diagnostic `G-newapproach-flowfoam-v3-diag`). High, `--fixed-fps 20`, 10-frame strips (0.1 s per strip frame), arrow off on both sides.
- base = `tb/newapproach` a947d825b.
- arm = base + `overlay_fronts` v3: closer, thinner lines in the near and middle water, uneven spacing, margin 3.2.
- GPU lane, swim-away-day: middle-water lines move +9 to +12 px per strip frame against the near log's +6 to +8. Far lines move 0 to +2.

Render check (frame t0, pixels changed by more than 30): away-day 17.5%, across-day 23.8%, night 24.7%.

## Verdict: DO NOT SHIP. Park the swell-line technique (second failure).

- **Direction fails both away views:** 0/3 TOWARD_CAMERA on each, against a bar of at least 2/3 at confidence 6+.
- **swim-across-day direction gets worse:** base 3/3 RIGHT, arm 2/3 at lower confidence.
- **Look is mixed:**
  - across-day loses (−0.26, 1/3);
  - away-day is about flat (+0.13, 2/3);
  - night gains (+0.65, 2/3).
- The coordinator's clause "direction passes but look loses only to the far comb" does **not** apply: direction did not pass.
- No Medium. Nothing maps above 6.39.

## 1. Blind direction test (strips t = 0, 2, 4, 6, 8; labels 0.2 s apart; six shuffled, unlabelled strips; three fresh judges)
Data: `yardstick_g_ff3/direction_test_strips.json`.

| View | Truth | Base | Arm |
|---|---|---|---|
| **swim-away-day** | TOWARD_CAMERA | 0/3 (LEFT 5, CANNOT_TELL 2, RIGHT 3) | **0/3** (LEFT 4, LEFT 3, RIGHT 4) |
| **swim-away-night** | TOWARD_CAMERA | 0/3 (LEFT 5, CANNOT_TELL 2, RIGHT 3) | **0/3** (LEFT 4, CANNOT_TELL 3, RIGHT 3) |
| swim-across-day | RIGHT | 3/3 (confidence 5, 5, 6) | **2/3** (RIGHT 3, CANNOT_TELL 3, RIGHT 4) |

What the direction judges saw:
- **Away views (arm):**
  - "long bands make the flow's axis obvious (horizontal), but which way along it is unclear because the bands barely move between frames";
  - "bands wobble rather than travel one way";
  - "the band versions make the current's axis much clearer … none makes the direction obvious; that needs visible scrolling or flow along the bands themselves".
  - The judges see the bands as running across the screen, sideways, not as coming toward the camera.
- **Across-day (arm):** "the bands run into the distance, so their shape suggests flow toward or away from the camera, but over time they shift sideways to the right. These two cues conflict."

Note that the base in this tree (a947d825b) reads 0/3 on night, where the v2 base (4b3cfa57a) read 3/3. The night baseline moved between base trees, so this round shows no night loss against its own base.

## 2. Paired look score (each side shows t0, t3, t6, t9, 0.3 s apart)
Batch `G-ff3`:
- three code-blind judges and the standard prompt;
- recorded defect: direction not readable at a glance;
- anchors: craft, f10_2_r3_capacitor, f04_6_r22, so this is a confirming batch.

Fit: linear, slope 1.2992, intercept −1.0186, r 0.866, anchor RMSE 0.577. No warnings.

| View | Base | Arm | Gain | Judges preferring arm |
|---|---|---|---|---|
| swim-across-day | 6.39 | 6.13 | **−0.26** | 1/3 |
| swim-away-day | 6.21 | 6.34 | +0.13 | 2/3 |
| swim-away-night | 5.74 | **6.39** | **+0.65** | 2/3 |

Raw Bar A, base → arm (judges a, b, c):
- across: 6.0, 5.5, 5.6 → 5.5, 5.0, 6.0.
- away-day: 5.8, 5.3, 5.6 → 5.3, 5.6, 6.1.
- night: 5.4, 5.0, 5.2 → 5.3, 5.9, 5.9.

On still frames the arm's lines read the direction (defect FIXED in 5 of 9 arm judgements), but every judge says they do not look like water:
- across-day: "thick opaque streaks … like painted ski tracks or wind lines", "same width and brightness from foreground to horizon", "run straight across the swimmer's foam disc";
- away-day: "stiff horizontal white bands … a band passes right across the driftwood logs instead of breaking around them", "evenly spaced bands near the horizon look machine-made";
- night: "wavy white ribbons spaced like a sine grid", "glow-bright for a night scene", "look generated rather than authored".

The far "comb" the GPU lane flagged is what two judges call the machine-made sine grid. It is part of the look loss, but not all of it: the near streaks are called opaque and painted too.

Defects present on both sides:
- the flat white foam disc around the swimmer (3/3 judges);
- the pale hard-edged rectangle on the night water right of the swimmer (scene, as the GPU lane said).

## Recommendation
This is the second judged failure of the advected-swell technique (v2, then v3), and both failed the same gate: the toward-camera direction in the away views. Under the owner's 25 Oct rule, park it until there is a new idea.

The direction judges' diagnosis is consistent over v2 and v3. Lines laid across the current show the axis but not the sense, because a band moving along its own normal at camera-follow speed looks static. Every round where the toward-camera direction did read (v3 crests, 3/3) used discrete marks with a leading edge moving clearly down the screen.

The judges' recurring top suggestion is still a flow-mapped normal surface with drifting debris or bubbles carried along the current: point features, so the sense of motion reads. Ship-ready alternatives already in hand:
- keep the shipped arcs and the arrow (T2 arrow close-out is High 6.32 and Medium 6.24, not closed);
- spend effort on the swimmer foam disc and the night slab, which every judge names on both sides.
