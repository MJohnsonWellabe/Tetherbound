# Meadows lane results — 2026-09-19

## Current status

Oskar approach DIAG attempt 1 passed **16/16**, no failures, skips, refused
steps or delegated captures, inventory complete and process exit 0. Starting
from explicitly marked diagnostic placement at Mira's doorway with the real
R15p1 save, [23,9] took 108 walking frames and live Oskar took another 46,
zero held frames. His real greeting opened narrative dialogue, the SwapPanel
opened, and menu-cancel returned world control. Native receipts are in
`oskar-native-attempt1`; this is diagnostic evidence, not campaign acceptance.
The lock released and read back null at 16:45:26 UTC.

Independent read-only layout review found the route clears the shop shell,
stays west of the rear rail, and increases bench center clearance from 1.17 m
to 3.06 m. Applied only S03-59c's x waypoint 25 -> 23 plus its explanation;
walking budgets, targets and production geometry remain unchanged. Regenerated
S03C and both sets of phase definitions/manifests. Python first invocation ran
57 tests with nine skipped because this shell lacked BASH; preserved that log
and reran with the installed Bash runtime explicitly configured: **57 passed,
zero skipped**. Capture derivation and both phase derivation checks also pass.
CI 4787 unit audit confirms 3,740 tests / 507,392 assertions / zero failures;
the full workflow still had three running jobs at the last observation.

R15 S03p2 finished **165 PASS, 4 FAIL, 0 SKIP, 2 DELEGATED**, 171/171
steps, inventory incomplete, process exit 0 and effective exit 1. No eligible
handoff: do not start S03p3 from its saved slot. Nine training victories reached
the production readiness condition; subsequent rounds were verified omissions.
The new first failure is S03-59c, the authored [25,9] waypoint beside the actual
tournament east bench at [26,9.6]. Collision telemetry records that bench and
the boundary fence; the passage planner issued one direct route, not a reset
loop. S03-60/61 and the guarded menu-cancel then failed downstream. Investigate
a physically clear approach west of the bench without changing production
geometry or increasing budgets. Render lock released at 16:38:10 UTC.

R15 **S03p1 passed** on `f1fd7833`: 193 PASS, 0 FAIL, 0 SKIP,
2 DELEGATED, 0 refused; 195/195 steps ran, inventory complete true, raw and
effective exit 0. Five living companions were saved. Actual slot handoff
SHA-256: `5707918ac93a367eeeedcaeb940ff091ee8ad2f498853f49ee7e70d85df63883`.
Compact receipts are in `r15-S03p1` and `r15-S03p2`. Both phases released
the render lock at completion.

R15's original R14 failure point is now proven in the actual campaign:
`S03-51n5a` reached its exact selected Galecrest through an open road gate in
1658 walking frames with zero held frames. `S03-51n5b` verified the already
active pinned fight without redundant input; `S03-51n5c` then won after 452
combat frames and 11 quick attacks, with production victory and XP progress
verified. All nine required training victories completed without defects;
the phase later failed on the separate Oskar approach described above.

Tested repair pushed as `f1fd783372f1e4bf28477cd968d6f36c5a362858`.
The production worktree fast-forwarded to that exact SHA. R15 evidence lives
at `D:\tetherbound\owner-kickoff-closeout-r5\ralph\reports\gate-f-run-20260919-meadows-r15`.
The inherited S02 save hash was rechecked before launch; `PREFIX_PROVENANCE.json`
records its original revision and explicitly requires a fresh full campaign.
Current CI is 4787/run 35454805960, in progress. Draft PR 127 now describes the
tested repair and remaining campaign obligations.

Machine wrappers used for this lane:
`D:\tetherbound\run-meadows-passage-diag-0919.ps1` for bounded DIAG runs and
`D:\tetherbound\run-meadows-locked-segment-0919.ps1 -Segment S03p1 -RunId gate-f-run-20260919-meadows-r15`
for the canonical production phase wrapper. Both claim the local render lock
and release their exact ownership claim in `finally`. The lock is not tracked
in Git; these local wrappers must be used instead of launching the older
unlocked phase wrapper directly.

The passage diagnostic now passes: attempt 3 completed **15/15 PASS**, zero
FAIL/SKIP/DELEGATED/refused, inventory complete true and raw exit 0. The exact
Galecrest fight began after 1602 walking frames (zero held); the reverse trip
completed after 1623 walking frames (zero held). Both fit the original 2000
frame budget. Real RB flight ended combat, verified after six physics frames.
The lock released automatically and was read back as null.

Receipts: `passage-native-attempt3/INVENTORY.json` and
`passage-native-attempt3/notes/diag_village_passage_0919.md`. Attempts 1 and 2
remain preserved with their failures. The result is a physical diagnostic
using a real earned save and explicitly marked setup teleport, not a fresh
campaign acceptance run. The tested candidate is frozen for the S03p1–S03p3
replay on one SHA in the production worktree.

All 57 Python Gate F tests passed (`gate-f-python-tests-attempt1.log`). CI 4775
for the earlier `e0d49c6c` candidate is confirmed completed/success through
GitHub run metadata (run 35070487416); that result does not validate the new
passage code. Current candidate CI remains in progress.

Approval pulled by fast-forward at `d3fd668b`. The initial passage geometry
suite passed on its first attempt: 3 tests, 39 assertions, zero failures
(`passage-tests-attempt1.log`). The existing physical navigator low-geometry
smoke also passed first attempt (`navigator-smoke-attempt1.log`), including
walkable ramps, short blocking geometry, collision masks and confined movement.

Independent read-only review then identified three missing cases: valid
near-panel starts rejected by oversized clearance; square corner guards treated
as smaller round obstacles; and cached routes not rechecked after movement.
The harness now separates panel and corner clearance and checks the current
leg before reusing a route. Added near-panel, square-corner and moving-target
regressions passed: 5 tests, 43 assertions, zero failures
(`passage-tests-attempt2.log`). This second suite follows actual code and test
changes, rather than an unchanged retry.

Native diagnostic attempts used the real R14 phase-one save and explicitly
marked starting-position setup as DIAG. Their failures and corrections below
explain why the third attempt's passing result is not an unchanged retry.

### Native diagnostic attempt 1 and follow-up

Attempt 1 completed with raw exit 0 but **10 PASS / 1 FAIL**, inventory complete
false. D10 crossed the open road gate, then the exact Galecrest started a real
fight on approach. The harness waited for an impossible Engage prompt while
combat was already active; the deployed companion fainted. D10 exhausted 2000
walking frames plus 757 held frames. D11 physically returned through the gate
in 1696 walking frames, with zero held frames. Evidence is
`passage-native-attempt1/INVENTORY.json`, its notes and telemetry. This is a
failed diagnostic, not a campaign pass or victory.

The render lock was released after the run. The wrapper's timestamp comparison
initially failed because PowerShell parsed JSON UTC timestamps as DateTime;
ownership was verified against the exact raw claim before release. The wrapper
now compares the raw unique claim string so future `finally` releases work.

Review's remaining endpoint finding is fixed: an existing body may escape or
approach conservative padding only without getting nearer than its endpoint
already is; crossing a solid fence remains forbidden. Intermediate graph legs
retain full padding. The expanded route suite passed 6 tests / 47 assertions.

The approach now recognizes a production fight already started by its exact
pinned creature, and the following interaction records that active fight
without sending a redundant button press. Wrong opponents and wrong controls
cannot consume that receipt. Combined route/Engage tests passed 11 tests / 89
assertions (`passage-engage-tests-attempt1.log`). No gameplay stats, aggression,
fence geometry or progression were changed.

Native attempt 2 used a fresh profile with the same original save and start
position. Its unsuccessful flee input is accounted for below.

Independent final review found no remaining blocking defect in endpoint escape,
square-corner clearance, cached-leg revalidation or exact active-fight receipt
consumption. The reviewer ran no engine. A minor remaining prose mismatch in
older training expectations describes only the prompt-driven branch; actual
receipts explicitly distinguish approach-started combat and issue no false
button-press claim.

### Native diagnostic attempt 2: approach fixed, diagnostic flee too early

Attempt 2 recorded **13 PASS / 1 FAIL**, inventory complete false, despite raw
exit 0. Exact Galecrest combat was recognized after 1606 walking frames with
zero held frames, and the pinned interaction receipt passed without input.
The diagnostic then pressed RB immediately during combat's production 0.25s
entry input guard (`combat_manager.gd::_input_guard`); the press was correctly
ignored. The reverse walk eventually passed in 1790 walking frames but had
678 held frames while the companion fainted. This is not a clean diagnostic.

Attempt 3 adds a diagnostic-only 0.5s wait before that one-shot flee press.
The production input guard and both 2000-frame walk budgets are unchanged.
The render lock released automatically after attempt 2 and was claimed again
for attempt 3, whose passing result is summarized above.

## Opening baseline (before approval)

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

## Open work at the pre-approval baseline (superseded above)

- Await plan approval.
- Validate or repair the WIP village passage implementation.
- Replay S03p1–S03p3 on one committed candidate SHA.
- Continue the production campaign, capture twins, studies and independent
  review until Meadows A0–A11 has current end-to-end evidence.

