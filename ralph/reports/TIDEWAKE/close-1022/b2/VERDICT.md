# Tidewake calibrated batch 2 (22 Oct 2026, ~15:20 CT)

## Setup

- **Control frames:** the batch-1 control frames, reused. Production behaviour is unchanged: every change since 807adae56 is behind the OFF look gate.
- **Candidate:** `--tidewake-look-candidate` at e388cab88. It includes the b2 depth/current changes, the Meshy shrine and terrace walls, and has the log floater removed.
- **Currents set:**
  - Captured with `capture_tidewake_f13_5.gd --only=currents`.
  - Control at 807adae56; candidate at the same head as above.
  - Frames used: three departure beaches plus one swim frame (Brine Steps, First Shore, Salt Crown, swim Brine Steps).
- **Anchors and fit:** `anchor_tiles.py --pairs 3 --seed 22` gave anchors F36#0 npc C5, F36#0 gap C7 and craft before/after.
- **Calibration:** linear fit, slope 1.477, r = 0.912, anchor RMSE 0.41, top anchor 7.35. Warning: some controls lie more than 0.5 outside the anchors' measured range (extrapolated low). No candidate score is above the top anchor.
- CPU llvmpipe, Low, 1920x1080.

## Mapped Bar A

| Row | Set | Control → mapped | Candidate → mapped (judges) | Batch 1 candidate | Gain on best |
|---|---|---|---|---|---|
| P2-011 named destinations, heading 0 | Gf | 3.03 | **6.13** (5.34/6.53/6.53) | 6.03 | +0.10 |
| P2-011 named destinations, other headings | Ys | 2.88 | **6.23** (5.94/5.94/6.82) | 6.28 | -0.05 |
| F13#5 dock | Ds | 3.97 | **6.77** (6.38/7.12/6.82) | 6.74 | +0.03 |
| P2-026/P2-009 water and shoals | Bw | 4.36 | **4.41** (4.46/4.01/4.75) | 5.57 | none |
| P2-066/F13#5 currents | Sa | 4.21 | **4.85** (4.75/4.75/5.05) | (first) | n/a |

- **Round count:** this is the first round gaining under 0.5 on every repeated row. One more such round parks them, so the next round needs a clearly different approach.
- **Batch-to-batch shift:** both control means dropped about 1.2 between batches (different anchors and judges). The cross-batch comparison is therefore approximate. Each batch's control-to-candidate gap is the robust signal: destinations +3.1/+3.4, dock +2.8, water +0.05, currents +0.6.

## Recorded defects

| Defect | Candidate (j1/j2/j3) | Control |
|---|---|---|
| Current road markings | FIXED ×3 | PRESENT ×3 |
| Markers read as boxes or debris | PRESENT ×3 | PRESENT ×3 |
| Destination missing (set Gf) | FIXED ×3 | — |
| Landmark reads as stand-in | PARTIAL ×3 (Salt Crown crystal "on a thin pole", Lantern arch behind a smoke slab) | — |
| Dock corral fence | FIXED ×3 | — |
| Shoal disc chain | PRESENT ×3 | PRESENT ×3 |
| Bubble foam | PARTIAL ×3 | — |
| Flat depth bands | PRESENT ×3 | PARTIAL |

## Judges' asks (all three)

1. **Dunes (scene).** Huge bare, shaded dune planes fill half of several frames, and the whole set sits under flat noon light with no haze or aerial perspective. Dress the dune faces and edges with groves, rocks, driftwood and grass clumps. Lower the sand value. Use a warmer, lower sun and distance haze.
2. **Currents (scene).** Now that the road markings are gone, you cannot tell where a current runs. They need a natural flow cue: foam ribbons or flow ripples. The teal Meshy buoy markers read as crystal shards or debris.
3. **Shoals and depth.**
   - The shoals are still an evenly spaced chain of round discs; reshape them irregularly.
   - The depth halo is still a hard band on the candidate.
   - The Meshy terrace walls read as "white boxes" at the shore at that distance.
   - One "X-shaped crossing band" appears on the First Shore water.
4. **Dock.** The flat white RockPath discs on the sand read as placeholder stepping stones. The rope runs across the beach.
5. **Salt Crown shrine.** It sits alone on a bare steep slope and the pedestal is hidden, so it reads as "crystal on a pole". It needs a grounded setting, such as a platform, steps or a plinth.

Disposition: every row stays open and every candidate stays OFF. Best mapped scores: dock 6.77, destinations 6.13/6.23, water 4.41 (batch 1: 5.57), currents 4.85.
