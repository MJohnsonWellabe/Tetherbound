# G-confirm-f39-26: one-sided High re-judge of F39#18 and F39#26 with rimSoft

Frames: `tb/gpu-frames-1108` 6426126b, manifest `G-confirm-f39-26-high`. Live is main d9d79ff93 plus `water_character_rim_soft.json`; batch 28 is not merged yet. Preset: High.

Batch `G-c26`:
- One-sided sets with three code-blind judges.
- Pinned anchors are craft, f10_2_r3_capacitor and f04_6_r22, so the top anchor is 7.35 and this is a confirming batch.
- Fit: linear, slope 1.1237, intercept −0.1613, r 0.821, anchor RMSE 0.658. No warnings.

| Row | Item | Raw (j1, j2, j3) | Mapped judges | **Mapped High** | G-water-rim (paired) | ≥7.5 |
|---|---|---|---|---|---|---|
| F39#18 | Tidewake dialogue camera framing | 6.4, 6.3, 6.6 | 7.03, 6.92, 7.26 | **7.07** | 7.36 | no (0.43 short) |
| F39#26 | Tidewake dialogue foreground obstruction | 6.1, 6.0, 6.7 | 6.69, 6.58, 7.37 | **6.88** | 7.52 | no (0.62 short) |

**F39#26 does not hold 7.5 one-sided.** The 7.52 in G-water-rim was scored right beside the ghosted live side. That contrast lifted the arm, as G-water-rim.md warned. Medium capture is **not** warranted yet.

The rimSoft gain itself stands: +1.9 and +2.1, 3/3, within-batch. It should still ship. It moves both rows from about 5.4 into the high-6 to 7 band.

## Remaining defects, all three judges

**F39#18:**
- Speakers sit at about a quarter of the frame height.
- The dialogue box covers their lower bodies.
- The player's back and backpack take up the left fifth to third of the frame.
- Daro is distant, so his panel reads as detached.
- PARTIAL 3/3.

**F39#26:**
- The player's head touches or overlaps Adair's lower torso in the Adair frame (PARTIAL 3/3).
- **The Adair portrait shows a different face** (glasses and auburn hair, matching Iona) from the dark-haired model on screen (2/3).
- A flat, untextured green tent or dune slab sits behind Iona and Rowan (3/3).
- The Aquaryn creature appears to hover at shoulder height against that slab (2/3).

**Next swing for both rows:** the judges converge on a tighter conversation shot, with the speaker filling about half the frame height above the panel and the player's shoulder pushed to the edge. That would be a dialogue camera arm, a camfx or conversation-camera config, but it would also move the fixed camera set. The rule against reframing cameras applies to capture stands; a game-side dialogue shot change is the lane's call.

**F39#26 data fixes** (no camera change):
- The Adair portrait mismatch.
- The Iona-frame green slab and the floating Aquaryn.
