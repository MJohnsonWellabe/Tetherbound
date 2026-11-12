# G-f38-15-steer2: banked glide with the side-on landing restored (F38#15 close-out; GPU High and Medium)

## Verdict: F38#15 does NOT close. The bank reads as a small gain at Medium and is level at High. Park the glide bank.

| Preset | Base (landing overlay) | Arm (+ glide bank) | Gain | Prefer arm | Arm per judge (mapped) |
|---|---|---|---|---|---|
| High | 6.96 | **7.02** | +0.06 | 1/3 (2 ties) | 6.75, 7.55, 6.75 |
| Medium | 7.23 | **7.39** | +0.16 | 3/3 | 7.07, 7.86, 7.23 |

- **Ship rule.** Nothing loses: High is level with no judge preferring base, and Medium gains 3/3. The bank may land as a ride-along flag, but it does not move the row.
- **F38#15 tonight:**
  - G-f38-15-row (High): 7.70.
  - G-medium-f38-15-galeland (Medium): 7.37.
  - This batch: 7.02 High / 7.39 Medium.
  - This panel's fit is steep (slope 1.59) and its base reads about 0.7 lower at High than the G-f38-15-row panel did, so a stricter panel accounts for part of the gap. Even so, neither preset reaches 7.5 here.
- **Stop rule.** This is the second glide-bank round under 0.5 (G-things-glidebank +0.31/+0.26 on the steer frames, now +0.06/+0.16). Park the bank and use a different approach.

## What holds F38#15 (3/3 unless noted)
1. **No descent pose.** The glide is "the same held spread-wing pose" on both sides, banked or not, with "no tuck or flare that would signal descent".
   - The recorded defect is PARTIAL 3/3: the landed perch is credited, but the change from flight to rest "still reads as a cut".
   - The judges ask for a distinct glide → flare (talons forward, wings cupped) → folded perch sequence. This is **new animation**, not a scene change.
2. **Flat, fog-washed ground under the glide.** "A flat, blurry olive-green plane with no groves near the subject"; "fog flattens the midground" (3/3). This is the P-GROUND cause.
3. **The High landed frame caught the wings mid-settle.** In the High pair the wings are "half-raised into a spiky fan" that reads "bristly", "like broken geometry" (3/3). The Medium pair has a clean folded perch.
   - This is capture timing. It explains part of High's lower score.
   - A later landed frame, after the wings have folded, would help both sides.
4. **Minor.**
   - No contact shadow under the talons (1/3).
   - Weak rim light on the dark back (1/3).
   - No elemental trait visible on the bird (1/3).

## Frames
- **Source:** `tb/gpu-frames-1108` section `G-f38-15-steer2` (e52a05aa0), High and Medium.
- **Capture:** `phase2_capture_realm_flight.gd --biome=meadows --seed=2042 --glide-steer`, default carrier Galecrest.
- **Build:** `tb/things` caf1939b0 on both sides. The fixed `--glide-steer` returns to the start heading before landing, so 03-landed is side-on on every side.
  - **base:** `THINGS-GALELAND` landing overlay.
  - **arm:** that overlay plus `THINGS-GLIDEBANK/overlay_glide_bank.json` (36° bank).
- **Health:** 0 script errors, no flight failures.
- **Sky pairing (GPU lane):** Medium within 1. High 5 apart (base 171/182/193, arm 176/182/190), within run-to-run variance.
- **Sets:** 02-glide over 03-landed, stacked, with the same brief and recorded defect as the earlier F38#15 batches.
- **Render check:** mean difference 11.0 at High, 7.9 at Medium. By eye, the arm banks into the turn on both presets.

## Batch `G-st2`
- Three code-blind judges, standard prompt, two candidate sets.
- Anchors: craft, f36_0_npc:C1 and f04_6_r22. This is a confirming batch.
- **Fit:** linear, slope 1.5915, intercept −3.4355, r 0.981, anchor RMSE 0.19. No warnings.

**Raw Bar A (judges a, b, c):**

| Preset | Base | Arm |
|---|---|---|
| High | 6.4, 6.8, 6.4 | 6.4, 6.9, 6.4 |
| Medium | 6.5, 7.0, 6.6 | 6.6, 7.1, 6.7 |
