# Meadows lane results — 2026-09-19

## Current status

Work window opened under
`OWNER_DIRECTIVE_2026-09-19_PARALLEL_MEADOWS_CLOUDREACH_LANES.md`. The required
plan is in `ralph/reports/MEADOWS-0919/PLAN.md`. Substantive implementation is
waiting for `PLAN-APPROVED.md`.

No screenshot, visual capture, Godot test or native campaign process has been
run in this work window. `D:\tetherbound\RENDER_LOCK.json` was missing when
checked; it was not created or claimed because no render-bound work occurred.

## Baseline evidence carried into the window

| Evidence | Result | Status |
|---|---|---|
| R14 S03p1 at `e0d49c6c` | 193 PASS, 0 FAIL, 0 SKIP, 2 DELEGATED; effective exit 0; five living companions | Verified phase result |
| R14 S03p1 save | SHA-256 `51d2b9c15c1c1423701495a3d17cab4537d14249e2103f29f4f219eea88e5e4f` | Valid only for same-SHA diagnostic continuation |
| R14 S03p2 at `e0d49c6c` | Five verified victories, then nine defects caused by walking into the village fence; interrupted during `S03-51n8a`; effective exit -1 | Failed; no eligible handoff |
| Focused training/selection checks at `e0d49c6c` | 5 tests, 203 assertions, 0 failures | Verified before passage WIP |
| Gate F Python checks at `e0d49c6c` | 57 passed; capture and phase derivations matched | Verified before passage WIP |
| CI 4774 at `b2462788` | Completed success; first-attempt audit committed | Verified with documented nonfatal diagnostics |
| Village passage code at `c25e57af` | Planner, focused test and operator adapter written | Unverified WIP; no parser/test/native claim |

Compact receipts are committed at:

- `ralph/reports/MEADOWS-0916/r14-S03p1`
- `ralph/reports/MEADOWS-0916/r14-S03p2/failure-summary.json`
- `ralph/reports/MEADOWS-0916/ci4774-first-attempt-audit.md`
- `ralph/reports/MEADOWS-0916/CLOSEOUT.md`

## Findings

The R14 failure is a harness-navigation defect. The selected Galecrest is
outside the village while the player begins inside. Telemetry records repeated
contacts with actual `VillageBoundary` panels 39–41 and corner guards 20–21.
The input save already contains `castle_gate_key` and `road_gate_open`, so the
three authored road passages are legitimately open. Local obstacle following
cannot discover a remote opening in the closed settlement polygon.

The proposed WIP keeps the selected creature and original walk budget, reads
the authored boundary plus live open gates, and feeds physical intermediate
waypoints to the existing stick navigator. Those properties are design intent
only until the planned tests and native traversal establish them.

A separate read-only audit found no immediate feeding regression: the five
saved nourishment values are 66.01–69.34. `fed=true` begins at 55, while a
living creature remains feed-eligible below 100. The already-full optional-row
case remains latent and is not an observed R14 failure.

## Ledger deltas

None. Meadows A0–A11 remains open. Existing 43/43 playtest and 23/23 named-
location ledgers, plus accepted Rise, Quarry, Mill and Warrens visual work, are
unchanged. No Cloudreach, Stormwood or Water ledger was touched by this lane.

## Open work

- Await plan approval.
- Validate or repair the WIP village passage implementation.
- Replay S03p1–S03p3 on one committed candidate SHA.
- Continue the production campaign, capture twins, studies and independent
  review until Meadows A0–A11 has current end-to-end evidence.

