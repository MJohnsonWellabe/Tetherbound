# Codex Exit Handoff — Meadows Campaign Checkpoint — 2026-09-19

> Superseded by [the content/visual wrap-up](CODEX_EXIT_HANDOFF_2026-09-19_CONTENT_VISUALS.md).
> The campaign-first restart objective below is historical; do not use it as the current scope.

## Restart objective

Resume Meadows first. Finish gates A0–A11 from one fresh production campaign,
including capture twins, studies, independent visual review, current export and
landing verification. Only after Meadows is accepted should work continue to
Cloudreach, Stormwood and Water.

The user requested this clean stopping point on 2026-09-19. No Godot process or
agent is running. This is a source/evidence checkpoint, not Meadows acceptance.

## Git and worktrees

- Source repository: `D:\tetherbound\source`
- Branch: `codex/all-branches-integration-0913`
- Pushed checkpoint: `c25e57af1e2daf1298272eceb9d7ad2956b5829f`
  (`Checkpoint Meadows village passage diagnosis`)
- Previous tested campaign candidate: `e0d49c6c23bc25e49450182294fc8a55ad1272be`
  (`Train against nearby wilds until earned tournament readiness`)
- Production worktree: `D:\tetherbound\owner-kickoff-closeout-r5`
- Production branch: `codex/meadows-campaign-0916`
- Production worktree remains frozen at `e0d49c6c`; do not fast-forward it
  until the new passage code is tested and committed as a candidate.
- Draft PR: <https://github.com/MJohnsonWellabe/Tetherbound/pull/127>

The source worktree still contains extensive pre-existing generated `.import`
and `.uid` churn, old capture directories, probes and the unrelated modified
`shaders/earth_bank.gdshader`. They were deliberately left unstaged. Continue
to exact-stage only; do not clean, reset or blanket-add the worktree.

## What is accepted or already proven

- Meadows playtest ledger is 43/43 and the named-location ledger is 23/23.
- The Rise, Old Quarry, Old Mill Crossing and Burrow Warrens visual/location
  work is accepted. Do not redo those art passes without new evidence.
- The current production staging fix prevents the trainer from moving the
  player through Mira's cottage. Its focused clearance test has six passing
  physics cases, and a real trainer battle passed.
- The exact Engage opponent is retained across physical input and verified
  against the combat manager.
- Training now selects the nearest living wild across species and stops
  starting new rounds once the production tournament readiness predicate is
  true. A started round must still finish with a real victory and recovery.
- At `e0d49c6c`, five focused Godot tests passed with 203 assertions. All 57
  Python Gate F tests, capture derivation and phase-plan checks passed.
- CI 4774 for `b2462788` completed successfully. Its first-attempt audit is
  `ralph/reports/MEADOWS-0916/ci4774-first-attempt-audit.md`; it records real
  nonfatal diagnostics and must not be summarized as error-free output.

## Latest production campaign evidence

Run root:

`D:\tetherbound\owner-kickoff-closeout-r5\ralph\reports\gate-f-run-20260916T030951Z-closeout-r14`

R14 S03p1 passed at `e0d49c6c`:

- 195 steps: 193 PASS, 0 FAIL, 0 SKIP, 2 DELEGATED, 0 refused.
- `inventory.complete=true`; raw and effective exit 0.
- Five living companions, levels 3/2/2/2/2.
- Actual save SHA-256:
  `51d2b9c15c1c1423701495a3d17cab4537d14249e2103f29f4f219eea88e5e4f`.
- Compact evidence is committed under
  `ralph/reports/MEADOWS-0916/r14-S03p1`.

R14 S03p2 was intentionally stopped and is not an eligible handoff:

- Five wild battles produced verified production wins and XP.
- `S03-51n5a` selected `Wild_galecrest_12_1` outside the village while the
  player was inside its southeast boundary.
- The 2000-frame physical walk repeatedly hit actual VillageBoundary fence
  panels 39–41 and corner guards 20–21 instead of discovering a remote gate.
- Rounds 5, 6 and 7 each recorded approach, interaction and absent-fight
  defects: nine defects total. The run was stopped during `S03-51n8a`.
- Raw/effective exit is -1; there is no completed inventory or reusable save.
- The exact compact receipt is committed at
  `ralph/reports/MEADOWS-0916/r14-S03p2/failure-summary.json`.

The input save already has `pickup:castle_gate_key` and `road_gate_open`.
Progression is not blocking the trip. The local wall follower cannot discover
one of the three distant authored openings in a closed settlement polygon.

## In-progress village passage repair

Checkpoint `c25e57af` adds:

- `tools/gate_f/village_passage_route.gd`
- `tests/test_gate_f_village_passage.gd`
- a small adapter in `tools/gate_f/operator_harness.gd::_walk_loop`

The intended behavior is harness-only. It reads the authored village outline
and live `gate.is_open()` state, computes physical intermediate waypoints around
solid fence edges, keeps the original selected target and charges every
waypoint frame to the original walk budget. It does not change production fence
geometry, progression, stats, target selection or input semantics. Passage
plans are emitted into walk telemetry.

This repair is **unfinished and unverified**. The usage limit interrupted work
after the files were written. No Godot test, parser run, native forward/reverse
traversal or independent code review has run against these files. Commit
`c25e57af` is therefore a recoverable WIP checkpoint, not a tested candidate.

## Exact next work

1. Review the three passage-related files before changing them. Pay particular
   attention to geometry clearance, closed-gate refusal, route recomputation
   for a moving target and whether all intermediate travel stays inside the
   caller's original 2000-frame budget.
2. Run `tests/test_gate_f_village_passage.gd` and the relevant existing stick
   navigator/low-geometry tests. Fix parser or geometry failures from evidence.
3. Run one real native diagnostic from the original R14 n5 starting position
   `(45.99, -1.57, -42.67)` to Galecrest near
   `(34.3026, 1.567575, -119.1532)`, then the reverse direction. Require an
   actual open road gate, physical movement, exact target retention and no
   frame-budget increase. Do not use the partially traveled failed-run state.
4. Obtain an independent read-only review of the final passage code. Address
   concrete findings and rerun only affected checks.
5. Commit and push the tested candidate, then fast-forward the production
   worktree to that exact SHA.
6. Start a new run ID and replay S03p1, S03p2 and S03p3 at one identical SHA.
   A failed phase cannot hand a save to the next phase.
7. Continue the Meadows chain through S04 and the remaining A0–A11 campaign.
   Final acceptance still requires a fresh S01 start, capture twins, study
   lanes, blind visual review, current Windows export, current CI, PR landing
   and verification of the landed commit.

Do not reuse the inherited diagnostic S02 prefix for final acceptance. It was
useful for isolating S03 failures, but the final chapter proof must begin fresh
at S01 on one candidate SHA.

## Other observations kept out of the repair

- The saved party's nourishment values are 66.01, 67.06, 67.23, 68.72 and
  69.34. `fed=true` begins at 55, while feeding remains valid below 100. The
  later feed steps are therefore not guaranteed to skip. The optional picker
  behavior for an already-full creature remains a latent edge, not an observed
  R14 defect.
- CI 4775/run 35070487416 for `e0d49c6c` was last observed in progress. Recheck
  its terminal result and focused logs next session; do not infer success from
  this handoff.
- Accepted visual ledgers and locations are independent of Gate F campaign
  completion. Meadows remains open until the fresh campaign and review package
  pass.
