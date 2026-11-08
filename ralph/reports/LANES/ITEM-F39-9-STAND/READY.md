STATUS: land
BRANCH: tb/item-f39-9-stand  HEAD: see the commit that adds this READY (pushed head)

Lane LANE-MESHY, F39#9 P2-113 catch camera distance (Tidewake): **capture-stand fix** (coordinator 8 Nov, for tonight's GPU re-score; no score credit).

## Cause (scout batch 1)
- In `tools/phase2_capture_catch.gd`, sequence A throws at a full-health target with the dice forced to about 0% (`chance.max` 0.001) so it can photograph a breakout.
- Its strike, absorbing, resting and shake frames came from that throw. The orb resolved at once, so 03-absorbing, 04-orb-resting and 05-orb-shakes all showed the "broke free / Weaken it more" card.
- There was no absorbing or resting moment to judge.

## Fix
- `tools/phase2_capture_catch.gd`: a new opt-in `--stages-on-catch` takes 02-orb-in-flight, 03-strike (and 03-absorbing), 04-orb-resting and 05-orb-shakes from sequence B's first weakened throw (the real absorb and shake path).
- Sequence A keeps 01-aiming-full-health and 06-breakout.
- Off by default, so every other row's frames are byte-for-byte the same stand.
- `ralph/reports/VISUAL/item-scores/job.json`: the three F39#9 repros add `--stages-on-catch`.

## Proof (`qj/F39-9-stand`, CPU; `_sheet_stand.jpg`)
- 02-orb-in-flight: the orb on its way into the Mangrove Monitor at mid distance, with no breakout card.
- 03-strike: the orb at the monitor's flank, with no breakout card.
- 03-absorbing: the orb on the sand under the resolve camera with the absorb rings. **CPU artefact:** the "Caught Mangrove Monitor!" card is already up.
  - The resolve runs on the process clock, and on llvmpipe each of the 14 physics frames between strike and absorbing carries about 0.3 s of wall time, so the whole 3-shake resolve fits in the gap. The tool already documents the same effect for the verdict card.
  - On the GPU rig the gap is about 0.23 s, before the first shake. **Check this on tonight's GPU re-score.**
- Tests: test_capture_catch_pinned_tidewake_wild and test_capture_catch_pinned_wild (4 tests, 0 failed); quick_judge unittest (15, OK).

## Not fixed here (note for the coordinator)
- **HUD ghost (possible real bug):** in 02 and 03 a half-transparent "100% CAPTURE CHANCE" chip and its reticle ring hang over the sea at upper left after the orb has left the hand. A fix would clear the chance chip on the frame the orb is released.
- **F38#13 and F38#14 (Meadows)** use the same strike, absorbing and resting frames from sequence A and probably show the same broke-free card. They could take `--stages-on-catch` too, as a separate stand decision.

## Files
- `tools/phase2_capture_catch.gd`
- `ralph/reports/VISUAL/item-scores/job.json`
- `ralph/reports/LANES/ITEM-F39-9-STAND/**`
