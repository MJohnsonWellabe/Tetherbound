# Tidewake close-1024 round mc1: F13#5 currents with the Meshy driftwood and spar buoys (24 Oct 2026, CT)

The row was PARKED at r3 (6.20). The gain rule lets a parked row reopen for clearly new art, and the Meshy 1024 driftwood log and spar buoy are exactly that, so this is the one reopening round, as the coordinator directed ("park F13#5 if the next round gains under 0.5").

- **Candidate:** 28c4e8282: 3.0 m Meshy driftwood logs drifting the lanes, 2.6 m Meshy spar buoys on the stakes, otherwise r3 (seams, tongues, leaning stakes with wakes).
- **Sides in one batch:** control, r3 and the Meshy candidate (judged twice).
- **Yardstick:** standard prompt verbatim, three fresh code-blind judges; `anchor_tiles.py --seed 8080 --pairs 4 --include craft --include f36_0_npc:C1`; `calibrate.py` fitted a line (slope 1.542, r 0.965), anchor RMSE 0.36, top anchor 7.53, `confirming_batch: true`.

## Mapped Bar A (this batch)

| Side | Raw (j1/j2/j3) | Mapped mean |
|---|---|---|
| Control (set Nu-B) | 5.0 / 5.0 / 4.8 | 4.54 |
| r3 (set Iq-A) | 5.4 / 5.6 / 5.0 | 5.16 |
| Meshy (set Iq-B) | 5.3 / 5.5 / 4.9 | 5.00 |
| Meshy (set Nu-A) | 5.3 / 5.5 / 5.0 | 5.06 |

The Meshy round lands 0.10-0.16 **below** r3 in the same batch. **No gain, so the row stays PARKED** at its best, 6.20 (r3 batch). This batch's absolute level runs about 1.0 lower than r3's for every side (different judges, steeper fit), which is why only the within-batch ordering is used.

## What the judges saw

- **The driftwood reads as debris, not current.** One judge: "two shapes that look like driftwood logs: exactly the 'debris' read the recorded defect describes." A floating object only says "current" in motion, and every frame here is a still.
- **The r3 wake is an artefact.** All three, independently, describe the stake wakes as vertical glass panes or light shards. The wedge lies flat on the water, but from the sea-level camera its pale triangle stands up the screen like a pane. The wake is removed from the OFF candidate (`wake_length_m` absent) so a future reopening does not inherit it; the stakes keep their lean.

## What would reopen the row

Unchanged from r3, and now with one more round of evidence behind it: the cue has to come out of the water surface itself (flow-aligned shearing normals, foam that travels dock to horizon, a deeper channel value), not from objects placed on it. Three object-based approaches (stakes, wakes, driftwood) have all scored level.
