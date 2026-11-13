# G-things-bandfaint: settled faint poses for four creatures (F36#44, F36#61, F36#83, F36#87; GPU High pose stage)

## Verdict: SPLIT by species. Ship Duskhush and Ribbonray; drop Trailpup and Voltwig from the scope. As one arm it fails (two species lose 3/3).

| Row | Base | Arm | Gain | Prefer arm | Verdict |
|---|---|---|---|---|---|
| **F36#44 Duskhush** | 6.59 | **7.09** | **+0.50** | 3/3 | **SHIP** |
| **F36#61 Ribbonray** | 6.55 | **7.09** | **+0.54** | 3/3 | **SHIP** |
| **F36#83 Trailpup** | 6.82 | **6.13** | **−0.69** | 0/3 | **DROP** from the scope |
| **F36#87 Voltwig** | **7.51** | 7.28 | −0.23 | 0/3 | **DROP** from the scope |

The arm is scoped per species in `creature_pose_settle.json` (`things_band_scope`), so it can keep Duskhush and Ribbonray only.

## Per species (3/3 unless noted)
- **Duskhush (arm wins).**
  - **Base:** the faint frames "break down". Faint mid is "a crumpled, pinched wing mass", and faint end "a squashed heap with the feathers splaying out like broken geometry" (or "inverted with spiky feather cards jutting out").
  - **Arm:** "the collapse frames read as a slumped owl ... grounded".
  - Both recorded defects (near-black plumage, barely above the trainer) are FIXED or PARTIAL on both sides; the plumage is now pale lavender-grey.
  - **Still holding it (3/3):** the owl faces away from the camera in the standing and hit frames, so no face or eyes show. There is no rim light and no readable elemental trait.
- **Ribbonray (arm wins).**
  - **Base:** faint mid and faint end "throw a huge fin up like a sail", which reads "as an effect or a glitch rather than a faint".
  - **Arm:** "the faint collapses cleanly onto its side".
  - Both recorded defects (neon-magenta ribbons, airborne hit) are FIXED on both sides.
  - **Still holding it (2/3):** "an odd upright ray on legs" stance, dark and low-contrast on the stage.
- **Trailpup (arm loses).** The arm's faint mid is "airborne in a running leap ... all four paws off the ground", and its shadow is detached. It "reads as an attack, not a faint". This confirms my render check, where the arm's faint end lies prone with its shadow apart from the body. Base's "crawl-down and side-lying faint read correctly".
  - **Recorded defect PRESENT on both sides:** a stock coyote with no amber eyes or paws and no rim light.
- **Voltwig (arm loses).** The arm's faint mid is "a crouched running pose that reads as an attack" (1/3 named it). The others scored the arm slightly lower with the sides "nearly identical".
  - **Near the bar:** base scores **7.51** here (7.55, 7.55, 7.43). It is not above the top anchor, and this is a confirming batch. Voltwig on current main is a close-out candidate once Medium is judged.
  - Earlier panel: G-things-t4-rescore had 6.78 (a different panel), so pooled High ≈ 7.15.

## The GPU lane's description vs the frames
The lane described every arm faint as settling "on their side, grounded, where base stays crouched or half-upright". That holds for Duskhush and Ribbonray. For Trailpup and Voltwig the arm's faint mid reads as a leap or a run. The settle blend appears to start from a locomotion pose for the quadrupeds.

## Pooled current-main lines (High)
- **Duskhush:** 6.53 (t4) and 6.59 (this base), ≈ 6.56.
- **Trailpup:** 6.53 (t4), 6.62 (faint2 base) and 6.82 (this base), ≈ 6.66.
- **Ribbonray:** this base, 6.55. Earlier panels sit on different trees.
- **Voltwig:** ≈ 7.15 (above).

## Frames
- **Source:** `tb/gpu-frames-1108` section `G-things-bandfaint` (29cb35dbe), High, `tb/things` 4f91b7ee9 on both sides.
  - **base:** no overlay.
  - **arm:** `overlay_band_faint.json` (`creature_pose_settle.json` `things_band_scope`).
  - `capture_f36_poses.gd --whole-body --context --roles=hit,faint` at 0/25/50/75/100%, 40 frames per side, 0 script errors.
- **Render check:** faint frames 0.4–1.9 mean difference, hit frames 0.0–1.1.
- **Sets:** per species, a 2×2 grid of hit-000 (standing), hit-050, faint-050 and faint-100, each cropped (560, 200, 1560, 840). The briefs follow the pose-stage template. The recorded defects are each row's catalogue defects (Voltwig: none).
- `G-things-stormpool` (47d9ba2c7) was HELD by the GPU lane and not judged.

## Batch `G-bf`
- Three code-blind judges, standard prompt, four candidate sets.
- Anchors: craft, f36_0_npc:C1 and f04_6_r22. This is a confirming batch.
- **Fit:** linear, slope 1.150, intercept −0.159, r 0.911, anchor RMSE 0.41. No warnings.
- Yardstick: `yardstick_g_things_bandfaint/`.

**Raw Bar A (judges a, b, c):**

| Row | Base | Arm |
|---|---|---|
| Duskhush | 5.8, 5.9, 5.9 | 6.3, 6.3, 6.3 |
| Ribbonray | 5.7, 5.7, 6.1 | 6.2, 6.2, 6.5 |
| Trailpup | 6.0, 6.0, 6.2 | 5.5, 5.4, 5.5 |
| Voltwig | 6.7, 6.7, 6.6 | 6.6, 6.3, 6.5 |
