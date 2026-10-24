# Tidewake close-1024 batch b6: F13#5 currents (24 Oct 2026, CT)

Same item and fixed views as b5 (`../b5/VERDICT.md`). One batch holds the control, b5 and b6, so the three are directly comparable on one scale.

- **Control:** main 5f1f388cc, shipping look.
- **b5:** tide-line seams, wavelet caps, dashes at 0.3 (57eadb9f1).
- **b6:** seams become tapered foam tongues (bright downstream head, frayed upstream tail), no ribbon dashes at all, larger and denser wavelet caps, deeper lane tint with a soft wandering edge (81f8f630e).
- **Renderer:** CPU llvmpipe, Low/Compatibility, 1920x1080. Each side is its four frames stacked vertically (b5's judges said the 2x2 sheet downscaled too far).
- **Yardstick:** `JUDGE_PROMPT.md` verbatim, three fresh code-blind judges; `anchor_tiles.py --seed 2410` gave the anchors f10_2_r3_capacitor, f36_0_gap C5 and f36_0_npc C3; `calibrate.py` fitted a line (slope 1.369, r 0.891), anchor RMSE 0.49, top anchor 6.93.

## Mapped Bar A

| Side | Raw (j1/j2/j3) | Mapped mean | Note |
|---|---|---|---|
| Control (main) | 3.9 / 5.3 / 5.0 | 5.00 | |
| b6, set Sv-B | 6.0 / 6.9 / 6.4 | **7.33** | above_top_anchor |
| b6, set Xq-A | 5.7 / 7.0 / 6.3 | **7.19** | above_top_anchor; the same frames, judged again in the same batch |
| b5, set Xq-B | 6.3 / 6.8 / 6.5 | **7.47** | above_top_anchor |

- The candidate gains +2.2 to +2.5 over the control in the same batch. b5 and b6 are within judge noise of each other (7.47 vs 7.33/7.19), so the b6 change did not move the row.
- Every mapped pass is extrapolated past the batch's top anchor (6.93), so by the yardstick it needs a confirming batch whose anchors reach 7.35. That batch is b7.

## Recorded defects

| Defect | Control | b5 | b6 |
|---|---|---|---|
| Road markings | PRESENT x3 | FIXED x3 | FIXED x3 |
| Direction unreadable | PRESENT x2, PARTIAL x1 | PARTIAL x3 | PARTIAL x3 |
| Markers read as boxes/debris | PRESENT x3 | FIXED x3 | FIXED x3 |

The road-marking and floating-box defects are fixed by all three judges. Direction stays PARTIAL on both candidates: the foam says where the lane is, not which way it runs.

## Judges' asks

1. **Direction** (the one remaining recorded defect). All three: make the flow a moving object, not paint. Drifting foam and debris that travel the lane, buoys leaning downstream, sheared surface normals.
2. **The sea's value structure.** All three named a "razor-straight horizontal band" where the shallow ramp hands off to the deep colour, reading as a clipping boundary. Addressed in the P2-009 candidate (a mid shelf stop and a wandering depth ramp), capturing for its own round.
3. **Even scatter and an empty foreground.** Dune grass and pebbles at uniform density over the whole dune face; 50-60% of each dock frame is bare sand.
4. **Out of scope for this lane, recorded for the others:** the Stormwood fight anchor had a camera inside the canopy, flat magenta telegraphs, no impact on a strike and no player creature in frame; the NPC anchor's eyes read as empty sockets; a creature anchor's faint pose floats with two disagreeing shadows and its coil buries the 1.80 m ruler.
