# Meadows lane results — 2026-09-19

## Current status

**Session stopped at owner request.** Full wrap-up and restart state:
`docs/CODEX_EXIT_HANDOFF_2026-09-19_CONTENT_VISUALS.md`. R18 never started;
no Meadows native check remains mid-flight. CI 4802 ended cancelled after the
newer plan push, not passed. Other lanes' processes and unrelated working-tree
changes remain untouched. Older running/next statements below are historical.

**Owner scope change:** Meadows content and visuals now supersede the campaign
queue, especially off-trail discoveries. PLAN.md records the new sequence.
Candidate `3692fd618367e5c5c336fa80452f31c54d491f81` is pushed and its CI 4802
was in progress at the scope change. R18 has a verified inherited prefix but
has never launched; it will stay idle. No native check remains mid-flight.
Combat depth and all other biomes belong to separate concurrent lanes.

The app goal replacement was attempted but rejected because the old unfinished
goal is usage-limited. Available goal tools cannot edit its objective or resume
it. The old goal is not falsely marked complete; the owner's new scope controls
the work and is recorded in this plan regardless of that app metadata limitation.

Precondition native diagnostic attempt 1 passed **38/38**, zero FAIL/SKIP/
DELEGATED/refused, complete inventory and raw exit 0. Physical RB deployed the
living active companion; readiness and healthy-pilot checks passed. The exact
selected Mudsnout approach took 343 walking frames, zero held; physical X
entered combat and production victory plus live XP passed in 334 fight frames.
All 20 exact harvest flag readbacks passed. This diagnostic used the failed
R17p3 save and explicit setup relocation; it proves the repair mechanism, not
night/campaign acceptance or a usable handoff. Lock released immediately.
Receipts: `preconditions-native-attempt1`. Final Python attempt 1 passed all
57 tests; capture and both phase derivation checks match. Next is a fresh
same-commit R18 replay of S03p1 through S03p3 after this candidate is pushed.

R17 S03p3 ended **215 PASS, 3 FAIL, 20 SKIP, 3 DELEGATED**, 241/241,
incomplete inventory, raw exit 0/effective exit 1. No eligible handoff.
All three failures stem from approaching the night wild after the creature-bed
sequence recalled the companion: the prompt was Call out, not Engage. The
source candidate now uses mapped RB (the nearby bed still owns the X prompt),
verifies a visible living active companion and then physically selects the
healthiest pilot before approaching. No production deploy or health writes.

Harvest review matched all 20 exact depletion flags to the first-interaction
deltas in R17. Added before-walk absence assertions as well as post-interaction
presence checks, so a stale flag cannot satisfy a wrong-node press.
Focused precondition attempt 1 was a parser failure (zero assertions, despite
runner exit 0); fixed explicit typing. Attempt 2 had one fixture failure: a
new unattached SceneTree did not make its body live. The state predicate was
extracted for pure tests; actual body readiness remains checked natively.
Attempt 3: **7 tests, 51 assertions, zero failures**, including existing healthy
pilot tests. Logs are retained. Native precondition DIAG is running with the
failed R17p3 save strictly as diagnostic input, never as a campaign handoff.
CI 4799 for bcad22f2 completed success.

R17 S03p3 has advanced through gathering into real camp construction with no
defect yet, but optional duplicate harvest presses record SKIPPED. These block
strict acceptance. Independent review confirmed production `harvest_node.gd`
depletes each authored node on one successful ledger claim; there is no second
hit. The next candidate preserves all 20 first interactions and replaces each
stale `-again` step with an exact `harvest_node:order:N.0` depletion assertion,
mapped to the authored coordinate/item. Wrong-tool/no-yield first attempts still
fail. IDs and coverage remain; no gate or optional-skip policy is weakened.
Current production R17 remains frozen at bcad22f2 while the next source
candidate and derived phases are prepared.

R17 S03p2 **passed** on bcad22f2: 169 PASS, two delegated captures, zero
FAIL/SKIP/refused, 171/171 steps, complete inventory and raw/effective exits 0.
Both prior failure sites now pass in the actual phase. Actual output hash:
`5806ed0b44616d229e5a74a194c540884cb9017c31bbd23f8c59da1004a03d9a`.
Receipts: `r17-S03p2`. Same-SHA S03p3 has claimed the released lock and started
from this verified artifact. Full S03 acceptance and capture debt remain open.

R17 S03p1 **passed** on bcad22f2: 193 PASS, two delegated captures, zero
FAIL/SKIP/refused, 195/195 steps, complete inventory and raw/effective exits 0.
Actual save hash matches receipt:
`ff546ec78519ee1ed09d155de81349184baddb06c99cc3e6ab0d537112af2c69`.
Compact receipts: `r17-S03p1`. Lock released then reacquired for S03p2,
which is running from that same-revision verified save.

Sprint candidate pushed as `bcad22f2a005f5aba1ab9f4d28807e5d181f369b`;
production worktree fast-forwarded to that exact commit. R17 prefix save hash
rechecked, provenance retained. Launch correctly refused Cloudreach's current
17:23:31 UTC render claim; S03p1 has not started. Current CI is 4799/run
35457978235. Draft PR 127 describes both new failures, repairs and validations.

Sprint DIAG attempt 2 passed **17/17**, zero FAIL/SKIP/refused/delegated,
complete inventory, raw exit 0. Setup earned a real Galecrest victory in 387
combat frames / nine quick attacks with XP verified, then retained a healthy
pilot. From the original R16 start the exact Mudsnout was reached in **1511
travel frames, zero held**, under the original 2000 budget. Its actual Engage
provider started combat. Telemetry proves sprinting with stamina draining from
100 to 0 and normal exhaustion/recovery; at arrival stamina was 4.2 and sprint
input was false. Lock released automatically. Attempt 1 remains failed and
preserved; no campaign acceptance is inferred from diagnostic setup teleports.

Sprint DIAG attempt 1 failed honestly: **9 PASS, 2 FAIL**, 11/11, incomplete,
raw exit 0. Earlier R16p1 save still had the Galecrest alive at the diagnostic
start; it attacked en route and fainted the selected companion (881 held
frames). The sprinting walker reached the Mudsnout but its live prompt was
"Bramblebun is out of the fight", so both strict approach/interaction failed.
Telemetry confirms real sprint state and stamina drain 100 -> 0 with normal
exhaustion/recovery cycling; sprint input was false at exit. This is not a
passing diagnostic. Attempt 2 adds physical Galecrest combat, paid recovery
and healthy-pilot selection to reproduce the campaign's already-defeated foe
precondition before resetting only the DIAG start position. Cloudreach holds
the render lock; the second attempt has not launched yet. CI 4791 for the
previous 34a3e0a5 waypoint candidate completed success.

R16 S03p2 finished **166 PASS, 3 FAIL, 2 DELEGATED**, zero skipped/refused,
171/171 steps, incomplete inventory, raw exit 0/effective exit 1. No eligible
handoff. Oskar's corrected approach and interaction passed in the actual phase.
The new first failure is S03-51n6a: exact selected Mudsnout starts 171.542 m
away (173 m passage route), beyond the ideal 166.667 m covered by 2000 frames
at production walking speed. Terrain-only contacts, steady progress, zero held
frames and moving target confirm a travel-time shortfall, not fence trapping.
Independent review verified selection sorting and only 1.433 m route overhead.

Next harness repair explicitly opts training approaches into physical L3 sprint,
with ordinary stamina, unchanged targets, unchanged frame budgets and no
production changes. All exits and modal holds release the input; close approach
and passage turns use walking. Focused first attempt: **13 tests, 107 assertions,
zero failures**. Native diagnostic awaits the active Cloudreach render lock.

Review identified a sprint-error path that could retain left-stick deflection.
The shared exit wrapper now clears both stick and sprint. Extended regression:
**13 tests, 119 assertions, zero failures**. All 57 Python checks passed on
first configured invocation; capture and phase derivation checks match. The
native Mudsnout diagnostic claimed the released lock and is now running.

R16 **S03p1 passed** at 34a3e0a5: 193 PASS, 2 DELEGATED, zero FAIL/SKIP/
refused, 195/195 steps, complete inventory and raw/effective exits 0. Saved
artifact SHA-256 independently matches the receipt:
`0b700f184e186768c1951b6bb12ee21656e3c43bef9a1b847947a05b8a5b4325`.
Receipts: `r16-S03p1`. Lock released, then S03p2 claimed it and started from
that same-revision save. No failed R15 save was reused.

Waypoint repair and receipts pushed as `34a3e0a5aec82642d5078f0dd89cb4b93b5dc336`.
Production worktree fast-forwarded to that candidate; R16 prepared with the
same explicitly inherited S02 prefix (hash rechecked). First launch attempt
correctly refused the live Cloudreach render lock claimed at 16:46:57 UTC;
no R16 phase or Godot process was started by that attempt. Await release before
running S03p1. CI 4787 for f1fd7833 is now terminal **success**, with known-red
suites and export skipped, not passed. New CI 4791/run 35456088529 is running.

Cloudreach released at 16:53:16 UTC. R16 S03p1 subsequently claimed the lock
and launched at the frozen 34a3e0a5 candidate. The bounded CI 4787 integration
audit records 32 first-attempt smoke passes across core verbs, owner regression,
gate evidence and combat, plus direct checks; it preserves nonfatal errors and
identifies the actual GitHub PR merge checkout. See `ci4787-integration-audit.md`.

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

