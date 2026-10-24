# Tidewake close-1024 batch b7: F13#5 currents, confirming batch (24 Oct 2026, CT)

b6 mapped every candidate above its batch's top anchor (6.93). The yardstick requires such a pass to be confirmed by a batch whose anchors reach 7.35, so this batch re-scores the same three sides with high anchors.

- **Sides:** the same stacked frames as b6, reshuffled: control (main 5f1f388cc), b5 (57eadb9f1) and b6 (81f8f630e). No new capture.
- **Yardstick:** `JUDGE_PROMPT.md` verbatim, three fresh code-blind judges; `anchor_tiles.py --seed 777 --pairs 4 --include craft --include f36_0_npc:C1` gave craft before/after (4.83/7.35), f36_0_npc C1 (7.53/7.47), p2_094_r4 and f36_0_gap C6. `calibrate.py` fitted a line (slope 0.956, r 0.894), anchor RMSE 0.61, top anchor 7.53, `confirming_batch: true`.

## Mapped Bar A (not extrapolated)

| Side | Raw (j1/j2/j3) | Mapped mean |
|---|---|---|
| Control (main) | 4.8 / 4.8 / 5.6 | 5.42 |
| b6 (set Us-B) | 5.5 / 5.5 / 6.2 | **6.06** |
| b5 (set Kj-A) | 5.5 / 5.5 / 6.3 | **6.09** |
| b6 (set Kj-B) | 5.5 / 5.5 / 6.2 | **6.06** |

**This supersedes b6's 7.33/7.19/7.47.** Those were extrapolated past a 6.93 top anchor; with anchors that reach 7.53 the same frames land at about 6.1. The candidate does **not** meet the 6.7 CPU-provisional bar. Everything stays OFF.

## Round history for the row (mapped)

| Round | Approach | Best mapped | Gain on best |
|---|---|---|---|
| close-1022 b1-b3 | painted streaks, then ribbons | 4.96 | — |
| b5 | tide-line seams | 6.11 | +1.15 |
| b6 | tapered foam tongues, soft lane tint | 6.06 | none (first round under +0.5) |

One more round under +0.5 parks the row. The next round therefore takes a different approach (object-based direction, below) rather than another shader-parameter pass.

## Recorded defects

| Defect | Control | b5 | b6 |
|---|---|---|---|
| Road markings | PRESENT x3 | FIXED x2, PARTIAL x1 | FIXED x3 |
| Direction unreadable | PRESENT x3 | PRESENT x1, PARTIAL x2 | PRESENT x1, PARTIAL x2 |
| Markers read as boxes/debris | PRESENT x3 | PARTIAL x3 | PARTIAL x3 |

Two of the three recorded defects are fixed or reduced on both candidates. **Direction is the one defect still called PRESENT**, and it is what holds the row under the bar.

## Judges' asks, in value order

1. **Direction, as an object.** All three: the pennant stakes mark a position, the water between them does not move. They ask for a wake, a foam collar where each pole enters the water, poles leaning downstream, drifting debris travelling the lane, and surface displacement along it. ("No consistent flow angle, no motion cue.")
2. **The sea's value structure.** All three again: stacked flat bands closed by a hard navy horizon strip, with a razor-straight seam and no aerial haze. The P2-009 candidate (a mid shelf stop plus a world-space wander on the depth every ramp reads) is this lane's answer and is capturing for its own round.
3. **Authored ground.** Pebbles and dune grass at near-uniform spacing and scale; they ask for drifts, edges and clearings.
4. **Outside this row:** the quick bar and prompts show keyboard keys (M / I / B, 1-5) in a controller-first game, and the quick-bar slots carry no item icons. Recorded for the UI lane.
