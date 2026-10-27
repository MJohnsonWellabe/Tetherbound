# SW20b: Ashfoot one-batch MET re-judge (coordinator NOTE item 5), 27 Oct 2026

**Result: the SW20 on arm (cc99525a5) is NOT MET, at 6.76 / 6.76, about 0.74 short of 7.5. The 6.96 vs 5.73 gap was batch scale, not scene.**

All three subjects were scored in one batch as one-sided sets: the Ashfoot inside frames in all four phases, Medium and High, with high anchors and three code-blind judges. Fit r 0.95, RMSE 0.35, confirming.

| Subject | Medium | High |
|---|---|---|
| SW16 on arm (m36b 0a633e222) | 5.58 | 5.58 |
| SW20 control (255b363c7) | 5.58 | 5.58 |
| **SW20 on arm (m48b cc99525a5)** | **6.76** | **6.76** |

- **SW16 on vs SW20 control:** all three judges read them as the same build and gave them identical scores and defect calls, as expected (storm_view on in both). The two old numbers (6.96 in the SW16 batch, 5.73 in the SW20 batch) are the same scene on two batch scales.
- **SW20 on:** +1.18 over the control in this batch (SW20's own batch had +0.87). The warm-room defect is FIXED on 2 of 3 judges and PARTIAL on 1. Generic cabin and window slab stay PARTIAL.
- **MET for SW20 on:** not met (6.76 / 6.76).

**Path to 7.5** (the same as the SW20 verdict, confirmed by all three judges here):
1. Cut the fire glare that blows out the trainer.
2. Seat the window flush in the wall, as an inset, rain-streaked pane.
3. Add copper fittings and a lightning rod alongside the storm-glass and moss.
4. Give the floor a texture in place of the flat green disc and beige rug.

## Files

- `yardstick/SW20b_candidates.json` (the 6 one-sided sets).
- `yardstick/SW20bb1/`: `key`, `sets.md`, `candidates`, `j1`–`j3`, `batch`, `mapped`.
- Frames and sides are the ones already published in SW16 and SW20.
