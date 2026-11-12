# GPU re-score 1108, section C: F41#21 P2-111 Hollows victory reward tiles, live vs `victory_on` arm (GPU High, mapped)

- Frames: `tb/gpu-frames-1108` manifest-C.json (6ca42119): hollows_alpha 99-after and 100-aftermath, each on live (be95950b) and on the victory_on arm (2c593b05). GPU High 1920x1080.
- Judged in the same batch as section A (same three code-blind judges, same anchors and fit: slope 1.423, r 0.907, anchor RMSE 0.486, confirming). Sides shuffled; judges were not told which side is which.

| Side | Mapped mean | Mapped per judge | Raw per judge |
|---|---|---|---|
| live | 5.61 | 5.52 / 5.52 / 5.80 | 5.3 / 5.3 / 5.5 |
| victory_on arm | **7.13** | 7.08 / 7.08 / 7.23 | 6.4 / 6.4 / 6.5 |

- **Gain: +1.52. Judges preferring the arm: 3 of 3.** Defect ("victory acknowledgement groups with the persistent quickbar"): PRESENT on live, FIXED on the arm, 3/3.
- Judges' reading: live shows a bare subtitle line floating over the x1 quickbar tile and the empty binding glyphs; the arm shows a gold-bordered "Hollows Alpha defeated" card at top right with the quickbar hidden. Remaining asks: the card's body text is small for a 7-inch screen; heavy white rain streaks and the near-black ground plane.
- **Ship rule (gain above 0 and at least 2 of 3 prefer): met. The arm ships.** Its High mapped score 7.13 is under 7.5, so no Medium capture is needed yet.
