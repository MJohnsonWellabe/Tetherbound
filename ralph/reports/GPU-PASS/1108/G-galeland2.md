# G-galeland2: carrier landing staging, Galewisp and Galecrest (F36#48, F38#15; GPU High)

## Verdict: SHIP
All three judges prefer the arm on all three sets. Nothing loses.

| Set | Base | Arm | Gain | Prefer arm |
|---|---|---|---|---|
| Galewisp landed | 6.34 | **8.11** ↑top | +1.77 | 3/3 |
| Galewisp flight | 6.43 | 7.29 | +0.86 | 3/3 |
| Galecrest flight (the planned no-loss control) | 6.88 | 7.43 | +0.55 | 3/3 |

Galecrest gains too, so the landing staging helps both carriers. The fit warns that the Galewisp landed score is above the top anchor; this batch is the confirming one (anchors reach 7.35 or more).

## Frames
`tb/gpu-frames-1108`, High, from `phase2_capture_realm_flight.gd --biome=meadows --seed=2042`. Frames per carrier: 01-launch, 02-glide and 03-landed.

| Section | Commit | Carrier flag |
|---|---|---|
| `G-galeland2-galewisp` | 0c7fa0744 | `--carrier=galewisp` |
| `G-galeland2-galecrest` | 8f1aa83b0 | default carrier |

Both sides use `tb/things` b628efddf.
- **base:** overlay off.
- **arm:** `THINGS-GALELAND/overlay_galewisp_landing.json`. It sets the landing stand side to 2.3, leaves forward at 2.4, and sets the Galewisp height to 3.4.

The Galewisp arm is the GPU lane's second run. The first run had "double Jump denied" at all three stands, so it was kept aside and not judged. 0 script errors.

GPU lane pre-check: Galewisp's left ear tip comes within about 1–3 px of the top edge but stays inside the frame.

## Batch `G-nf`
- This batch is shared with `G-below6-namedfaces.md`. It used three code-blind judges and the standard prompt.
- Anchors: craft, f36_0_npc:C1 (7.47/7.53) and f04_6_r22. This is a confirming batch.
- **Fit:** linear, slope 1.3588, intercept −1.6769, r 0.984, RMSE 0.180. This is the tightest fit of the run.

## Results

| Set | Base raw → mapped | Arm raw → mapped | Gain | Prefer arm | Recorded defect, base → arm |
|---|---|---|---|---|---|
| **Galewisp landed** (03-landed alone) | 5.7, 5.6, 6.4 → 6.34 | 7.2, 7.0, 7.4 → **8.11** ↑top | **+1.77** | 3/3 | "hidden behind the trainer ... barely taller": PRESENT 2/3 and PARTIAL 1/3 → **FIXED 3/3** |
| **Galewisp flight** (launch, glide, landed) | 5.9, 5.9, 6.1 → 6.43 | 6.6, 6.6, 6.6 → **7.29** | **+0.86** | 3/3 | "carries nothing": FIXED on both sides |
| **Galecrest flight** (control) | 6.2, 6.4, 6.3 → 6.88 | 6.7, 6.7, 6.7 → **7.43** | **+0.55** | 3/3 | — |

**Galewisp landed**
- Arm (3/3): "large and unobstructed, about 1.6–2 times the trainer's height, with its face, glowing eye and feather pattern clear".
- Base (3/3): "set behind the trainer's shoulder, partly hidden ... only modestly taller".
- Bar B on the arm landing: yes, 3/3 ("reads as Palworld-class").

**Galecrest**
- Arm (3/3): "stands upright and distinct, clearly taller, face and crest read".
- Base (3/3): "crowds the trainer ... head merges into the trees".

## Rows
- **F38#15** (flight and landing pose read, board 6.84) is scored on the default carrier's glide and landed frames, which belong to the Galecrest section.
  - The Galecrest three-frame set reaches **7.43**. That puts the row in the close-out range, though it is not yet a row score on F38#15's two frames.
  - A row score on glide and landed, at High and then Medium, would show whether it closes.
- **F36#48** (Galewisp poses, board 6.84) is scored on the pose stage, which this arm does not change. The landing frames above measure the Galewisp's in-world carrier look, not that row.

## What still holds these rows down (3/3)
1. **The flight backdrop.** A flat olive ground plane, grey haze and flat grey ridge cards. Judges ask for groves, colour variation and cool blue aerial perspective.
2. **The flight pose.** The wings are "spread stiffly and symmetrically ... a T-pose rather than a glide" (judge a). At 30% the grip on the trainer is a small blob.
3. **The ground at landing.** The path texture is blurry.

## Recommendation
1. Land `overlay_galewisp_landing.json`.
2. Then capture an F38#15 row score: Galecrest glide and landed, at High, then Medium if High reaches 7.5 or more.
