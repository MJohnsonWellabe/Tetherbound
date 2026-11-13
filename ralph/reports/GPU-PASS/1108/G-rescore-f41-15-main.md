# G-rescore-f41-15-main: F41#15 row score on main after #918 (GPU High)

## Score: F41#15 = 4.99 mapped

| | Value |
|---|---|
| Raw scores (a, b, c) | 5.0, 4.6, 4.8 |
| Mapped per judge | 5.23, 4.74, 4.99 |
| Old board score | 4.49 |
| Change | +0.50 |

The row is still below 6. What holds it back is the Nysa frame, which was captured for the first time.

## Frames
`tb/gpu-frames-1108` 77452e670, High, one side, no arm.
- Main at 3b7d04b5e (#918, the Marrow glow fix, landed).
- Captured with `phase2_capture_dialogue.gd --fixed-fps 20`.
- The three job.json `__dialogue` frames, stacked top to bottom: captain_marrow, captain_marrow_dynamo_core, officer_nysa_deepwood_rod.
- Blend 1.000 on all frames, 0 blank, 0 script errors.

## Batch `G-r15`
- Three code-blind judges, standard prompt.
- Anchors: craft, f36_0_npc:C1 and f10_2_r3_capacitor. This is a confirming batch.
- **Fit:** linear, slope 1.2055, intercept −0.8009, r 0.914, RMSE 0.563. No warnings.

**Recorded defect** ("Large foreground creatures or overhead geometry hide the named speaker"): PRESENT for judges a and c, PARTIAL for judge b ("one frame rather than several").

## What the judges see (3/3)
- **Nysa (frame 3):** "two large blue lightning-veined creature bodies fill the foreground; the named speaker is a sliver in the gap between them" (about 70% of the frame).
  - **Identity mismatch** (GPU lane): the portrait shows a dark-haired man while the body is a pale-haired figure.
  - **Player bloom:** the player's face blows out to white at the left edge.
- **Marrow (frames 1 and 2):** visible and unobstructed, with the glow fix holding. A white hair rim or halo still blooms (2/3).
- **All frames:** a washed lavender grade, a flat tiled plank deck, slab or cylinder trunks, and a flat painted sky band.

## Next for F41#15 (in order)
1. **Nysa's shot.** Clear the storm creatures out of the speaker cone. This is the creature clearance that Stormwood is currently excluded from. Fix the portrait and body mismatch at the same time. This is the one change that moves the row the most: frame 3 is what keeps the defect PRESENT.
2. **Stormwood dialogue grade and materials:**
   - lavender wash to a storm palette with a value range;
   - plank and trunk textures;
   - remove the hair and player bloom.
