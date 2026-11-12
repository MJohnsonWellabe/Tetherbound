# GPU arm round 1108, G-fp-exposure-115: global Forward+ exposure 1.333 → 1.15 (live vs arm, GPU High plus ghost-glow, mapped)

**Verdict: no visible effect at judging scale.**
- **Mean gain +0.006 over 17 rows**, so the coordinator's rule (mean gain positive and no meaningful scene drop) is met only in the trivial sense.
- **15 of 17 rows were scored identically by all three judges** on both sides; the judges saw the frames as "the same, only reordered". The GPU lane measured about 10/255 lower luma by eye, and that is below what changes a judgement.
- **Gains:** F38#28 Warden arena +0.16 (3/3) and F39#18 Tidewake dialogue framing +0.21 (3/3).
- **Loss:** F39#26 −0.26 (0/3). That drop comes from a capture difference: a red-orange crab wandered in beside Iona in frame 2 on the arm side. Two judges flagged it as close to the reserved red. It is not caused by exposure.
- **Recommendation:** ship only if the darker grade is wanted for its own sake. The yardstick shows no gain, and it does not touch Marrow's head (still "blown out to a white bloom", 3/3).

| Row | Live | Arm | Gain | Prefer arm |
|---|---|---|---|---|
| F39#18 Tidewake dialogue framing | 6.38 | **6.59** | **+0.21** | **3/3** |
| F38#28 Warden arena boundary | 7.50 | **7.66** | **+0.16** | **3/3** |
| F38#2 hurt and move poses | 6.33 | 6.33 | 0.00 | level 3/3 |
| F39#10 water depth | 6.99 | 6.99 | 0.00 | level |
| F39#29 speaker visibility | 5.92 | 5.92 | 0.00 | level |
| F40#2 summit aviary | 6.89 | 6.89 | 0.00 | level |
| F39#2 Veilfall silhouette | 7.10 | 7.10 | 0.00 | level |
| F41#7 trainer dialogue identity | 6.94 | 6.94 | 0.00 | level |
| F39#15 Veilfall approach shallows | 6.89 | 6.89 | 0.00 | level |
| F41#15 Marrow and Nysa | 6.33 | 6.33 | 0.00 | level |
| F39#3 destinations | 6.89 | 6.89 | 0.00 | level |
| F40#12 dialogue speaker visibility | 7.55 | 7.55 | 0.00 | level |
| F41#12 charged road | 6.38 | 6.38 | 0.00 | level |
| F38#23 Tether Relay yard | 7.30 | 7.30 | 0.00 | level |
| F41#17 Crown Arch | 7.55 | 7.55 | 0.00 | level |
| F39#1 shore landforms | 7.05 | 7.05 | 0.00 | level |
| F39#26 dialogue obstruction | 6.54 | 6.28 | −0.26 | 0/3 (capture difference: crab in frame) |

**Side finding: three rows map to 7.5 or above in the ghost-glow state, regardless of the arm.**
- **F40#12** dialogue speaker visibility: 7.55.
- **F41#17** Crown Arch: 7.55.
- **F38#28** Warden arena: 7.50 live, 7.66 with the arm.

How far to trust these:
- Each is above the top anchor (7.35) in a confirming batch, so under the yardstick rules they count.
- This batch's slope is steep (1.529), and their raw means are 6.6–6.9.
- They are candidates for a Medium capture to close. F38#28 is at 7.50 live, so read it with care; with the exposure arm it is 7.66.
- Judges' remaining asks:
  - F40#12: "solid, centred speakers in a dressed stronghold".
  - F41#17: the square tiled plinth.
  - F38#28: a thin cyan floor arc still visible.

**Per judge, mapped, for the rows that moved:**
- F39#18: 6.33 / 6.03 / 6.79 → 6.64 / 6.18 / 6.94.
- F38#28: 7.86 / 7.25 / 7.40 → 8.01 / 7.40 / 7.55.
- F39#26: 6.94 / 6.33 / 6.33 → 6.33 / 6.18 / 6.33.

## Method
- **Arm frames:** `G-fp-exposure-115` (877686b8), with the 4 trainer frames re-shot in `G-fp-exposure-115-b` (801fe9f7) replacing the first run's.
- **Live frames (all ghost-glow state, main ba6778f45), matched by frame id:** `G-fp-exposure-115-live` (2442b698) where present; otherwise the G-ghost-glow arm frames or the G-npc-albedo live frames. No frame lacked a live match.
- **Hardware:** GTX 1060, Forward+ High.
- **Batch:** one batch, `G-exp`: 17 pairs plus 3 pinned anchor pairs, three fresh code-blind judges, standard JUDGE_PROMPT, sides shuffled with the key kept outside.
- **Fit:** slope 1.5286, intercept −2.8401, r 0.881, anchor RMSE 0.546. Confirming batch (top anchor 7.35).
- **Warning:** "meets the bar only above the top anchor: F38#28, F40#12, F41#17 (both sides); extrapolated, but this batch's anchors reach 7.35 or more, so it is the confirming batch".
- **Judged by:** LANE-SCOUT, 9 Nov 2026 ~09:20 UTC.
