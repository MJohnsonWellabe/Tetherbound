# G-below6-hits: Mirejaw hit clip and Abyssal Guardian flinch (F36#52, F36#30; GPU High)

**Frames:** `tb/gpu-frames-1108` b4afac81a, High, tree `tb/below6` 8e1931604.
- Capture: `capture_f36_poses.gd --species=mirejaw,abyssal_guardian --whole-body --context`.
- **base:** flags off.
- **arm:** `BELOW6-HITS/overlay.json` (`below6_mirejaw_hit` and `below6_flinch_abyssal` on).
- 40 frames, 0 blank. The faint frames are identical on both sides, so the sets show the hit only.

**Sets:**
- Crop 560,200 1000×640. Tiles: standing (hit 000), hit 025, 050 and 075. Brief: F36 (1).
- **Mirejaw defects:** "the hit reaction smears the jaw or tail into a pale translucent shape", "tail passes through the trainer".
- **Abyssal Guardian defects:** "hit reaction barely different from standing", "glossy vinyl, toy-like".
- Pixels changed: 3.4% and 4.4%.

**Batch `G-bh`:**
- Three code-blind judges, standard prompt.
- Anchors: craft, f36_0_npc:C1 (7.47/7.53) and f04_6_r22. This is a confirming batch.
- **Fit:** slope 1.296, intercept −1.279, r 0.973, RMSE 0.230. No warnings.

## Verdict: SPLIT. The Mirejaw hit ships; the Abyssal flinch does not

| Row | Base | Arm | Gain | Prefer arm | Raw base → arm (a, b, c) |
|---|---|---|---|---|---|
| **F36#52 Mirejaw** (`below6_mirejaw_hit`) | 5.72 | **6.32** | **+0.60** | 3/3 | 5.5, 5.1, 5.6 → 6.0, 5.6, 6.0 |
| F36#30 Abyssal Guardian (`below6_flinch_abyssal`) | 6.19 | 5.94 | −0.25 | 1/3 | 6.0, 5.9, 5.4 → 5.8, 5.3, 5.6 |

**Mirejaw moves above 6.**
- "Pale translucent jaw or tail smear": PRESENT 3/3 on base, PARTIAL 3/3 on the arm. The tail no longer balloons into a pale paddle over the trainer, but the snout still reads "whitish and semi-translucent" in the hit frames.
- "Tail passes through the trainer": PRESENT 3/3 on both sides, in every frame including standing.
- **Next for Mirejaw:**
  1. Find why the jaw renders translucent. This looks like a material or alpha problem in the hit pose, not a pose problem.
  2. Space the pose stage, or the tail, so the tail clears the trainer.

**Abyssal flinch: do not ship.**
- The arm's backward flinch reads as distinct from standing; "hit barely different from standing" is FIXED or PARTIAL on both sides.
- But the arm adds **a detached white rectangular block or fragment at the front foot** in hit 025 and 050 (3/3). Judges call it a geometry artefact. The base shows a "pale paddle shape" between the legs, which they judge less severe.
- "Glossy vinyl, toy-like" is PRESENT 3/3 on both sides. The material arm (`G-below6-abyssal-matte.md`, +0.55) was not on this tree.
- **Next:** fix the stray foot block, then re-judge the flinch together with the matte coat and THINGS-FAINT.

**Owner rules:** no red on either creature. Both are taller than the trainer, though Mirejaw is "long and low" (1/3).
