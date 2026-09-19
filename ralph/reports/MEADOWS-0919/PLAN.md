# Meadows lane plan — 2026-09-19

## Scope for this work window

Continue the Meadows production campaign from the checkpoint documented in
`docs/CODEX_EXIT_HANDOFF_2026-09-19_GOAL.md`. The immediate task is the
harness-only village passage repair that R14 exposed during S03 training. The
work window will validate that repair, replay the affected campaign phases at
one candidate SHA, and continue repairing the next real Meadows failure in
campaign order.

This lane will not implement Cloudreach, Stormwood or Water. A separate session
owns the newly authorized Cloudreach visual/environment exception. This lane
will not change production village fence geometry, progression, combat balance,
creature stats or target selection to make the evidence harness pass.

Substantive implementation is held until
`ralph/reports/MEADOWS-0919/PLAN-APPROVED.md` appears, as required by
`OWNER_DIRECTIVE_2026-09-19_PARALLEL_MEADOWS_CLOUDREACH_LANES.md`. Low-risk
inspection and report maintenance may continue while approval is pending.

## Starting checkpoint

- Working branch: `codex/all-branches-integration-0913`
- Pushed head before this plan: `7d0ddac6bc7bf7f69631eb911aa590c2c73047c7`
- In-progress passage checkpoint: `c25e57af1e2daf1298272eceb9d7ad2956b5829f`
- Last tested production candidate: `e0d49c6c23bc25e49450182294fc8a55ad1272be`
- Production worktree: `D:\tetherbound\owner-kickoff-closeout-r5`, still
  frozen at `e0d49c6c`
- Draft PR: <https://github.com/MJohnsonWellabe/Tetherbound/pull/127>

R14 S03p1 passed all 195 steps: 193 PASS, 0 FAIL, 0 SKIP and 2 DELEGATED.
R14 S03p2 earned five verified wild victories, then failed because physical
walking aimed through the village's southeast fence at a selected Galecrest
outside the closed polygon. Nine consequent defects were recorded before the
run was intentionally stopped. That failed phase has no eligible handoff.

## Intended sequence after plan approval

1. Review `tools/gate_f/village_passage_route.gd`, its `_walk_loop` adapter in
   `tools/gate_f/operator_harness.gd`, and
   `tests/test_gate_f_village_passage.gd`. Check authored-outline geometry,
   live `gate.is_open()` handling, closed-gate refusal, moving-target refresh,
   telemetry and original-budget accounting.
2. Run the focused passage test and relevant existing stick-navigator and
   low-geometry checks. Fix only reproduced parser, geometry or integration
   defects.
3. Run a native physical diagnostic from the original R14 n5 start
   `(45.99, -1.57, -42.67)` to the selected Galecrest near
   `(34.3026, 1.567575, -119.1532)`, plus the reverse trip. Require passage
   through an actually open authored road gate, exact target retention and no
   increase to the 2000-frame budget.
4. Obtain independent read-only review of the final passage code, address
   concrete findings, then commit and push a tested candidate.
5. Fast-forward the production worktree only to that committed candidate. Use
   a fresh run ID and replay S03p1, S03p2 and S03p3 at one identical SHA. Do not
   reuse a save from any failed phase.
6. Continue the Meadows chain through S04 and later segments. Record each real
   failure as the next work item and update `RESULTS.md` with evidence paths,
   verdict counts and ledger deltas.
7. Final Meadows acceptance remains a fresh S01-start campaign with capture
   twins, studies, independent blind visual review, current Windows export,
   current CI, PR landing and verification of the landed commit.

## Render and machine coordination

No screenshot or visual capture will start without first reading and atomically
claiming `D:\tetherbound\RENDER_LOCK.json` as `held_by: "meadows"` with an ISO
UTC timestamp. If Cloudreach holds it, this lane will do non-rendering code,
root-cause or test work and recheck later. The lock will be reset to
`held_by: null` immediately after capture, including failed or aborted attempts.
A lock older than two hours will only be reclaimed after confirming there is no
corresponding new capture output, and that recovery will be recorded here and
in `RESULTS.md`.

Focused headless tests and read-only analysis do not claim the render lock.
Before any native screenshot/capture process, this lane will also confirm no
other Godot render process is active. Meadows takes priority if the two lanes
need the same render resource.

## Evidence and reporting contract

- Tests must identify the exact first attempt and assertion counts. A retry is
  recorded as a finding rather than silently replacing the first result.
- Native campaign evidence must report raw and effective exit, PASS/FAIL/SKIP/
  DELEGATED counts, candidate SHA and actual save hash.
- Capture results must reference shipping-build frames and an independent blind
  verdict. Capture harness output with missing production geometry is not proof.
- `ralph/reports/MEADOWS-0919/RESULTS.md` will separate verified results,
  failures and open work. It will not promote A0–A11 or another ledger from a
  self-report.
- Only intended files will be exact-staged. Existing import/UID churn, old
  capture payloads, probes and `shaders/earth_bank.gdshader` remain untouched.

## Completion criterion for this work window

The ideal endpoint is a committed and pushed Meadows candidate with the
passage repair independently reviewed, focused checks passing first attempt,
S03p1–S03p3 passing at one SHA, and the production campaign advanced to its next
honestly isolated failure. This work window does not claim Meadows complete
unless every full acceptance item above has current evidence.

