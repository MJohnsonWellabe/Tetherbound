# G-places-gatepaving: boot-sized Cloudreach paving (F40#0, F40#1; GPU High)

## Verdict: SPLIT
- **F40#0 realm gate:** gains +0.93 in clear weather and +0.79 in rain. All three judges prefer the arm in both.
- **F40#1 row:** loses −0.61, and no judge prefers the arm. Where there is no dirt path, the arm's paving shrinks to a near-invisible patch.
- **The other F40#1 views** gain +0.32 (3/3).

The change fails the "no loss" rule as one flag. Land it only where a path carries it, or give path-less stands a visible stone patch first.

## Frames
`tb/gpu-frames-1108`, High. Both sides were captured from `tb/places` 4ca9e4fc3, with no import.

**Sides:**
- **base:** overlay off.
- **arm:** `PLACES-GATEPAVING/overlay.json` turns on `paving_scale_1112`. Paving pieces are 0.12 m and sunk 55%, read by `cloudreach_settlement_life.gd`.

0 blank, 0 script errors. CAPTURE.json says base = main; the GPU lane followed the queue entry and used 4ca9e4fc3 for both sides.

**Sections:**
- `G-gatepaving-f40-1` (ab7e91886), captured with `phase2_capture_locations.gd`, seed 2042.
  - The F40#1 row: realm_gate_crag day approach, sky_shrine_heartstone day approach and sky_shrine 07 day close.
  - Three other views as controls.
- `G-gatepaving-f40-0` (5be621b2f), captured with `capture_cloudreach_f40_matrix.gd --piece=3-4`.
  - Realm gate, day, clear and rain, four views each.

**Render check (mean difference, pixels changed):**

| Set | Mean diff | Pixels changed |
|---|---|---|
| F40#1 row | 4.3 | 12% |
| F40#1 other views | 4.1 | 11% |
| F40#0 clear | 7.2 | 21% |
| F40#0 rain | 6.3 | 23% |

## Batch `G-gp`
- Three code-blind judges, standard prompt, four sets.
- Anchors: craft, f36_0_npc:C1 and f10_2_r3_capacitor. This is a confirming batch.
- **Fit:** linear, slope 1.3931, intercept −1.7409, r 0.926, RMSE 0.522. No warnings.

## Results

| Set | Base raw → mapped | Arm raw → mapped | Gain | Prefer arm |
|---|---|---|---|---|
| **F40#0 gate, day clear (4 views)** | 5.9, 5.3, 5.0 → 5.78 | 6.3, 6.0, 5.9 → **6.71** | **+0.93** | 3/3 |
| **F40#0 gate, day rain (4 views)** | 6.0, 5.0, 4.8 → 5.60 | 6.3, 5.7, 5.5 → **6.39** | **+0.79** | 3/3 |
| F40#1 other views (controls) | 6.2, 5.5, 5.4 → 6.20 | 6.4, 5.8, 5.6 → 6.52 | +0.32 | 3/3 |
| **F40#1 row (3 frames)** | 5.6, 5.0, 4.9 → 5.46 | 5.2, 4.5, 4.5 → **4.85** | **−0.61** | 0/3 |

### F40#0 gate
- **Base (3/3):** "huge piled slabs that swallow the trainer to the shins", "a rockslide, not a road", with stones that "clip through one another".
- **Arm (3/3):** "a warm dirt path with a few small scattered stones ... far cleaner and the trainer reads well".
- **Remaining:**
  - The path is "a saturated orange stripe with little edge blending" (judges b and c).
  - The overhanging rock shelf reads as "a soft brown blob".
  - The rain gives "no wet response; the grass stays saturated green".

### F40#1 row
- **Arm (3/3):** the subject is "a faint, flat grey smear under the trainer's feet ... close to invisible". This is the "bare" outcome the GPU lane flagged.
- **Base (3/3):** "a dense heap of near-identical grey stones ... a pasted-on carpet". It is generated-looking, but it gives the frame a subject.
- **Recorded defect** ("broad level grass fields ... where layered elevated land and ledge detail should lead"): PRESENT 3/3 on both sides. Paving cannot fix this row; the flat lawn is the defect.

## What still holds F40#0 and F40#1 down (3/3)
1. **Flat lawn mid-ground.** Judges ask for terraced ledges, stratified outcrops, drop-offs to a cloud sea and visible sky islands (new art). This is the F40#1 row's own recorded defect.
2. **Path material.** Lower the orange saturation and blend the path edges into soil and grass. Stones should be scale-varied and partly buried, "never piled above the trainer's ankles".
3. **Rain.** Add wet darkening and sheen.

## Recommendation
1. **Scope `paving_scale_1112` to path-bearing settlements,** where F40#0 gains about +0.86. At path-less stands, either keep the old patch or replace it with a visible, scale-varied, sunk scree patch, so the F40#1 subject doesn't vanish.
2. **Re-judge the F40#1 row** after that change, then land.
