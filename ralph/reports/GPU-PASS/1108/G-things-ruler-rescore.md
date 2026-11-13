# G-things-ruler-rescore: trainer ruler cleared of the creature on the pose stage (F36 (1), six rows; GPU High)

## Verdict: SHIP `--clear-ruler`. Ashtusk and Brooktail meet the bar at High; capture Medium for them next.
Every row gains, at least 2/3 judges prefer the arm on each, and no judge prefers base on any row.

| Row | Board (t4 re-score) | Base here | Arm | Gain | Prefer arm | Arm per judge (mapped) |
|---|---|---|---|---|---|---|
| **F36#33 Ashtusk** | 6.90 | 7.22 | **8.03** ↑top | +0.81 | 3/3 | 8.32, 8.03, 7.74 |
| **F36#36 Brooktail** | 6.90 | 6.93 | **7.69** ↑top | +0.76 | 3/3 | 7.89, 7.60, 7.60 |
| F36#62 Riftfrill | 6.30 | 6.88 | 7.31 | +0.43 | 3/3 | 7.46, 7.17, 7.31 |
| F36#52 Mirejaw | 5.28 | 6.07 | 7.26 | **+1.19** | 3/3 | 7.46, 7.17, 7.17 |
| F36#70 Sparkit | 6.60 | 6.98 | 7.26 | +0.28 | 3/3 | 7.17, 7.17, 7.46 |
| F36#66 Shadelet | 6.15 | 6.88 | 7.07 | +0.19 | 2/3 (1 tie) | 7.02, 7.02, 7.17 |

- **Both bar rows are confirming.** Ashtusk and Brooktail meet 7.5 only above the top anchor (7.53), but this batch's anchors reach 7.47/7.53, so it is the confirming batch.
- **Mirejaw** gains more than 0.5 on its own, and comes up from below 7 on the board.
- **Riftfrill, Sparkit, Shadelet** gain less than 0.5. They ride along under `--clear-ruler`, which is one capture flag; Mirejaw, Ashtusk and Brooktail carry it.
- **Base vs board.** Base here maps higher than the t4 board scores. This judge pool's fit is steep (slope 1.43). Read the board changes as indicative; the paired gains are what this batch measures.

## What the judges see (3/3 unless noted)
- **Base:** the trainer is drawn through the creature.
  - Mirejaw: "the trainer stands inside the tail" in the standing, hit and faint-mid frames, and the faint-end body reaches his feet.
  - Brooktail: "the tail sweeps through the trainer".
  - Ashtusk, riftfrill, sparkit and shadelet: the creature sits closer, "rump and tail pass through the trainer" (ashtusk), or the tail tip touches him (riftfrill, sparkit, shadelet hit frame).
- **Arm:** "a clean gap in all four frames".
- **Recorded defects, arm:**

| Row | Defect | Result |
|---|---|---|
| Mirejaw | body passes through the trainer | FIXED 3/3 |
| Sparkit | faint tail passes through the trainer | FIXED 3/3 |
| Riftfrill | back below the trainer's head | FIXED 3/3 |
| Brooktail | about trainer height | FIXED 3/3 |
| Ashtusk | faint is an armoured ball | FIXED 3/3 |

## Frames
- **Source:** `tb/gpu-frames-1108` section `G-things-ruler-rescore` (05a5a8f58), High.
- **Capture:** `capture_f36_poses.gd --whole-body --context --roles=hit,faint` for mirejaw, brooktail, shadelet, riftfrill, sparkit and ashtusk. Five phases per role, 60 frames per side.
- **Build:** main f421556ca on both sides, no overlay, no import.
  - **base:** without `--clear-ruler`.
  - **arm:** with `--clear-ruler`.
- **Health:** 0 script errors. These are neutral-stage frames, so the GPU lane bypassed the sky heuristic (`PACK_STAGE_FRAMES=1`) after an eye check.
- **Sets:** the same format as the earlier pose re-scores.
  - Crop 560,200, 1000×640.
  - Tiles: standing (hit 000), hit 050, faint 050, faint 100.
  - F36 (1) brief. Recorded defects are the roster causes from G-things-t4-rescore.
- **Render check:** 0.8–1.2% of pixels changed per sheet. Only the trainer moves; creature size, camera and pose are identical. By eye, Mirejaw's base trainer overlaps the tail and the arm's is clear.

## Batch `G-rr`
- Three code-blind judges, standard prompt, six candidate sets.
- Anchors: craft, f36_0_npc:C1 and f04_6_r22. This is a confirming batch.
- **Fit:** linear, slope 1.4339, intercept −1.8655, r 0.988, anchor RMSE 0.16.
- **Warning, verbatim:** "meets the bar only above the top anchor (7.53): G F36(1) ashtusk ruler base-vs-arm [G-rr_ashtusk_arm.png], G F36(1) brooktail ruler base-vs-arm [G-rr_brooktail_arm.png]; extrapolated, but this batch's anchors reach 7.35 or more, so it is the confirming batch".

## What still holds the rows below 7.5 (arm, 3/3 unless noted)

| Row | What holds it | Kind |
|---|---|---|
| Riftfrill (7.31) | Glossy, wet-plastic dark purple over the whole body; the faint end reads as a dome or shell (1/3) | material, new art |
| Sparkit (7.26) | Still a single mustard yellow; no elemental spark trait (1/3); awkward hit crouch and a belly-up faint (2/3) | material, pose |
| Mirejaw (7.26) | Back only just above the trainer's head; a pale translucent snout that reads as glass; a smeared dark bar on the tail | scale, new art |
| Shadelet (7.07) | Near-black with no rim light; the faint end dissolves into an unreadable black arch | scene |
| Ashtusk (8.03) | Dark spines still merge into the shadowed back in the standing and hit frames | scene |
| Brooktail (7.69) | Aqua spots grow into oversized blob decals in the faint frames | material |

The judges' top scene change (3/3) is a cool rim or back light and a slight albedo lift on the dark species: shadelet, riftfrill, mirejaw and the ashtusk spines.

## Next
1. **Medium** for F36#33 Ashtusk and F36#36 Brooktail, with `--clear-ruler`, same roles and crop. Each closes if it holds 7.5 at Medium.
2. **Close-out candidates** (about 7.0 and above): riftfrill, sparkit, mirejaw and shadelet. A rim light on the pose stage is a single scene change across four of them.
