# G-f38-15-row: F38#15 flight and landing on its own frames, with the landing staging arm (GPU High)

## Score: F38#15 arm = 7.70 at High
F38#15 is 7.5 or above at High and now needs a Medium capture to close.

| | Base | Arm |
|---|---|---|
| Raw (a, b, c) | 6.6, 6.6, 6.6 | 7.2, 7.0, 7.2 |
| Mapped per judge | — | 7.78, 7.54, 7.78 |
| Mapped mean | 7.08 | 7.70 |

- **Gain:** +0.62. All three judges prefer the arm, and every judge is at 7.5 or above.
- **Board:** 6.84.
- **Calibration warning:** the arm score lies above the top anchor (7.53). This batch's anchors reach 7.35 or more, so this is the confirming batch.

## Why this is the row's own frame set
F38#15's job.json frames are `meadows__flying__glide` and `meadows__flying__landed`. Both are reproduced with:

```
tools/phase2_capture_realm_flight.gd -- --biome=meadows --seed=2042
```

That uses the default carrier, Galecrest. They are therefore the `02-glide` and `03-landed` frames of `G-galeland2-galecrest` (`tb/gpu-frames-1108` 8f1aa83b0, High, `tb/things` b628efddf).
- **base:** overlay off.
- **arm:** `THINGS-GALELAND/overlay_galewisp_landing.json`.

**Set:** glide on top, landed below, at full size. Brief and recorded defect are F38#15's.

**Batch `G-f3815`:** three code-blind judges, standard prompt. Anchors: craft, f36_0_npc:C1 (7.47/7.53) and f04_6_r22.

**Fit:** linear, slope 1.1552, intercept −0.5421, r 0.933, RMSE 0.359.

## What the judges see (3/3)
- **Arm landed:** "a convincing upright perch with the wings folded, the talons planted, a sharp beak profile and a clear eye ... close to the owner's style bar".
- **Base landed:** "half-hidden behind the trainer ... wing feathers flared up and ruffled into a spiky mass".
- **Recorded defect:**
  - Arm: PARTIAL 3/3. The perch now reads, but "the flight silhouette is the same spread-wing pose with no glide or landing variation".
  - Base: PARTIAL 2/3, PRESENT 1/3.
- **Bar B on the arm:** yes 3/3. "The naturalistic raptor and the sky and mountain grade carry it."
- **Remaining:** the flat, blurry olive plain below the glide and the flat grey mountain cards. Judges also ask for a distinct swept glide or flaring landing pose.

## Close-out answers for the coordinator

### F38#15: needs a Medium capture on the arm
- **Tool:** `phase2_capture_realm_flight.gd --biome=meadows --seed=2042`, default carrier (Galecrest).
- **Overlay:** `THINGS-GALELAND/overlay_galewisp_landing.json`.
- **Preset:** Medium. Arm only.
- **Frames to judge:** `02-glide` and `03-landed`. The capture also writes `01-launch`, which is not part of the row.
- **Result:** it closes if Medium maps to 7.5 or above.

### F36#48 (Galewisp poses, board 7.44): no Medium yet
- This row is scored on the pose stage:
  ```
  capture_f36_poses.gd --species=galewisp --whole-body --context
  ```
  The frames are standing, hit, faint and the fly-grip travel poses.
- The landing overlay does not change the pose stage, so the G-galeland2 scores (Galewisp landed 8.11, flight 7.29) are not F36#48 scores.
- Its latest High is 7.44 (`G-newapproach-travel-pose.md`). That is under 7.5, so a Medium capture would not close it.
- It needs a change first. The judges' named gaps:
  - the fly-grip reads as "dangled rather than held";
  - the faint wing passes over the trainer.
- After a change, it needs a fresh High on the pose stage.
