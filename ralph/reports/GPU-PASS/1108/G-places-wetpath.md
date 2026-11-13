# G-places-wetpath: wet trail ground in Cloudreach (F40#0, F40#19, F40#1; GPU High)

## Verdict: SPLIT. Do not ship as one change.
The arm fails no-loss: night rain loses for all 3 judges, and overlook rain loses slightly. The clear-weather trail and the gate rain win clearly.

| Set | Base | Arm | Gain | Prefer arm |
|---|---|---|---|---|
| F40#0 clear controls, gameplay camera (4 places) | 5.95 | 6.55 | **+0.60** | 3/3 |
| F40#0 clear controls, approach view (4 places) | 6.03 | 6.60 | **+0.57** | 3/3 |
| F40#0 gate rain (pieces 3–4; also F40#19) | 5.64 | 6.29 | **+0.65** | 3/3 |
| F40#0 summit day rain | 6.08 | 6.16 | +0.08 | 2/3 |
| F40#0 overlook rain | 5.60 | 5.51 | −0.09 | 1/3 |
| **F40#0 summit night rain** | 6.42 | 6.08 | **−0.34** | **0/3** |
| F40#1 row (no rain at these stands) | 5.64 | 5.69 | +0.05 | 1/3 (2 ties) |

The judges' reading is consistent: they want "a mid-value, desaturated earth brown that holds up by day, in rain and at night". The arm's clear-weather and day-rain trail gets there. Base's trail is "a saturated orange strip that looks painted on" (3/3), and the arm wins wherever base shows it. The arm's rain darkening overshoots in two places:
- **Summit night:** the trail becomes "a black, char-like smear ... a burn mark" (3/3). Base's golden-brown trail "reads clearly as a path".
- **Overlook:** the trail goes grey and "gets lost in the wet grass" (2/3).
- **Summit day, minor:** the arm's trail is "a dark, faint smudge" for 2/3, so it is roughly level.

## Frames
- **Source:** `tb/gpu-frames-1108`, five sections, all High.
  - G-places-wetpath-gate (5a16bc8c1): pieces 3–4.
  - G-places-wetpath-summit-day (a47849d1b): pieces 83–84.
  - G-places-wetpath-summit-night (0853aac0f): pieces 87–88.
  - G-places-wetpath-overlook (cc51b9d43): pieces 91–92.
  - G-places-wetpath-f40-1 (4721b65ae): the row's job.json frames.
- **Capture:** `capture_cloudreach_f40_matrix.gd --ground-cover-cache` for the F40#0 pieces, and `phase2_capture_locations.gd` seed 2042 for F40#1.
- **Build:** `tb/places` 4eba46f9f on both sides, no import.
  - **base:** no overlay.
  - **arm:** `PLACES-WETPATH/overlay.json` (`ground_wet_path_1112`).
- **Health:** 0 script errors, 0 blank frames.
- **Sets:** each rain piece is one set of four views in a 2×2 grid (approach, gameplay, reverse, detail). The clear controls are two sets, the gameplay and approach views of the four places (three by day, the summit at night). The F40#1 row is the three job.json frames.
  - The three-frame F40#1 grid left one cell empty. Judge c noted it, and it affects both sides equally.
- **Render check:** mean difference per set:
  - gate rain 7.9, summit day rain 6.8, summit night rain 10.2, overlook rain 6.0;
  - clear gameplay 1.6, clear approach 2.7;
  - F40#1 row 1.1 (noise floor).
- **By eye:** this matches the GPU lane's pre-check. The overlook trail turns grey, and the night trail turns charcoal.

## Batch `G-wp`
- Three code-blind judges, standard prompt, seven candidate sets.
- Anchors: craft, f36_0_npc:C1 and f10_2_r3_capacitor. This is a confirming batch.
- **Fit:** linear, slope 1.3001, intercept −1.2052, r 0.909, anchor RMSE 0.58. No warnings.

| Set | Base raw | Arm raw |
|---|---|---|
| Clear gameplay | 5.6, 5.1, 5.8 | 6.3, 5.6, 6.0 |
| Clear approach | 5.6, 5.2, 5.9 | 6.3, 5.6, 6.1 |
| Gate rain | 5.4, 4.9, 5.5 | 6.0, 5.3, 6.0 |
| Summit day rain | 5.8, 5.3, 5.7 | 6.0, 5.2, 5.8 |
| Overlook rain | 5.6, 4.6, 5.5 | 5.5, 4.7, 5.3 |
| Summit night rain | 6.2, 5.5, 5.9 | 5.8, 5.3, 5.7 |
| F40#1 row | 5.6, 4.9, 5.3 | 5.6, 4.9, 5.4 |

- **F40#1 recorded defect** (flat grass fields lead the route): PRESENT 3/3 on both sides. Paving or a trail tone cannot fix it; it needs ledges and terraces (new art). This matches G-places-gatepaving.
- **Clear night summit, arm:** a "violet blotch under the trainer" (2/3). This is a small risk on the arm even without rain.

## What holds F40#0 down (3/3, both sides)
1. **Flat lawns.** Flat grass planes fill half the frame, with no stratified ledges or terraces. This is new art.
2. **Primitive props.** Floating hedge or wall blocks and flat yellow and blue banner cards at the gate; a cube boulder at the summit; slab-underside ruins.
3. **The trail itself.** It needs one mid-value, desaturated earth brown across day, rain and night, with soft, width-varying edges.

## Recommendation
1. **Ship the clear-weather tone, and the day rain at the gate and summit.** These are the arm's wins: +0.6 on both clear-control sets, +0.65 on gate rain.
2. **Cap the rain darkening:**
   - Limit it so the trail stays at mid-value brown: a floor on trail luminance, or at most about half the current darkening.
   - At night, skip the darkening (base's night trail wins).
   - At the overlook, keep the warm hue rather than greying it.
3. **Re-capture** the four rain pieces plus one clear control, and re-judge. Overlook rain and night rain are the no-loss checks.
4. **F40#1:** unchanged by this arm. It needs ledges and terraces.
