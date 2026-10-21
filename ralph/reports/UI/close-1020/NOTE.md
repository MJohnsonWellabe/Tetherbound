# UI lane close run (tb/ui), from 21 Oct 2026

Rows: P2-002, P2-001, P2-007, P2-095, P2-004, P2-031, P2-088, P2-061, P2-032, P2-096.
Rule (coordinator): three code-blind judges on matched before/after frames call the defect FIXED and the after mean is 6.7+ (CPU-provisional, Mesa llvmpipe, Low/Compatibility, xvfb). Shared UI code: one judged set counts for every biome listing the row when it holds frames from each listed biome, or the screen is identical across biomes (stated per row).

Earlier "done" rows (P2-002, P2-007, P2-095, P2-096, P2-088, P2-032) had single-judge verdicts without the three-judge score; they are re-judged here.

## Ledger

| Row | Status | Biomes | Before mean | After mean | Judges | Proof |
|---|---|---|---|---|---|---|

## Rounds

### Blocker correction: catch capture never entered combat (P2-061 proof)
- Criterion: P2-061 catch result hierarchy (F38–F41 #2) needs matched catch verdict frames.
- Failure (reproduced 21 Oct, Meadows): `tools/phase2_capture_catch.gd` pressed the actionable "Engage Bramblebun" offer for 17 minutes and combat never started.
- Cause: the tool adopts the starter but never adds it to the party; with `combat.json` actor_vitals on, a wild fight refuses an unowned fighter. `tests/smoke_controller_catching.gd` already does that ownership step.
- Alternatives checked: `capture_catch_sequence.gd` uses the same adopt path; no other catch capture covers the verdict frames.
- Correction: the same three-line party-add step in `_ensure_ally()`. Next proof: catch before/after runs on Meadows.
