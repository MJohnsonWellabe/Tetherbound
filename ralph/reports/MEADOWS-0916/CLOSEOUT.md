# Meadows campaign continuation — 2026-09-16

Persistent work window: 2026-09-16 03:09:51 UTC through 2026-09-17
03:09:51 UTC, requested by the owner. Resume checkpoint: `0938d73f` on
`codex/all-branches-integration-0913`. Meadows A0–A11 remains open;
Cloudreach, Stormwood and Water follow Meadows acceptance.

## S02 route-distance diagnosis

Primary evidence: `D:/tetherbound/owner-kickoff-closeout-r5/ralph/reports/
gate-f-run-20260915T222920Z-owner/S02/`, especially `notes/S02.md` and
`telemetry/events.jsonl`.

The campaign walked every authored opening waypoint, earned two creatures,
opened the road gate, and reached the village. Recorded cumulative horizontal
travel was 139.57 m. The 150 m assertion was the only route assertion that
failed; the trace had 597 rows against 450 required, and peak dead travel was
38.5 m against the 150 m ceiling.

The authored spawn, loft, Grandpa, practice meadow, key, gate and village
centres define 138.647 m of straight-line legs before arrival tolerances:
4.579 + 3.500 + 7.201 + 59.953 + 24.110 + 8.944 + 30.360 m.
Subtracting both endpoint radii on each leg permits 111.147 m. Production
combat additionally stages and returns the human; these large position jumps
are correctly excluded by the harness rather than counted as walking.
Consequently, 150 m requires incidental detours beyond the prescribed route.
A 100 m recorder sanity floor accommodates those tolerances and combat
staging. Mandatory waypoint, catch, objective, gate, village, trace-row and
dead-travel checks remain necessary and unchanged. This correction is not a
chapter pacing verdict; real travel measurements remain in the evidence.

## Save seam and packaging

The old S02 save navigation sent three RB presses from Map, landing on Players.
No slot 4 save was written, and S03 onward failed from the missing handoff.
Live controller-driven tab navigation and focused hidden/revealed Skills
coverage are being implemented before another production run.

The previous packaging log records `git add` refusing report paths outside
the sparse checkout. `-f` does not override sparse-checkout restrictions.
The runner did not check the failed commit before reporting a successful
push of the unchanged code ref. Exact evidence staging with sparse support
and checked commit/publication is being repaired independently.

No new gate pass is claimed yet.

## Validated code checkpoint

`82f6c11f17c347ee0b6a8469b96f1c8594278f64` contains the navigation and
packaging repairs. Pushed to the integration branch; draft PR 127 targets
`main`, with CI run 35051296904 in progress. No main landing is claimed.

The orchestrator independently repeated the production-menu smoke with
**22 checks / 0 failures**, recording stdout in
`D:/tetherbound/menu-navigation-smoke-0916.log`. The packaging integration
fixture also passed: sparse publication, exact payload policy, preservation
of unrelated work, staging failure, rejected commit, empty evidence and
existing branch collision.

Production S02 is running in the already-imported closeout worktree on
`codex/meadows-campaign-0916`, at the exact committed code checkpoint.
This avoids including the unrelated modified source-worktree earth-bank
shader. Its fresh profile is under `D:/tetherbound/closeout-profiles/`, and
evidence is in `owner-kickoff-closeout-r5/ralph/reports/
gate-f-run-20260916T030951Z-closeout/`. Native NVIDIA OpenGL is confirmed.

## Focused navigation validation

The new `select_menu_tab` action navigates through physical controller RB
input and reads the live context after every transition. It fails on a stalled
transition, repeated tab, loss of menu ownership or exhausted bounded budget.
Campaign and matrix navigation setup steps targeting Save or Build now name
their destination; intentional controller-binding stress presses are unchanged.

Executed from `D:/tetherbound/source` with Godot 4.7 stable:

- `--headless --path . --script tests/smoke_gate_f_menu_navigation.gd`:
  **22 checks, 0 failures**. The real production menu was driven by parsed
  controller events with Skills hidden and revealed. Checks include Save,
  Build, unchanged already-selected tab, unknown destination, insufficient
  budget, unresponsive input and closed-menu refusal. Skills reveal is an
  explicit character fixture, not a claimed production chapter transition.
- `--headless --path . --script tests/run_tests.gd -- --only=gate_f`:
  **90 tests, 45,517 assertions, 0 failures**. Includes vocabulary/schema,
  segment validity, bounded navigation pricing and a guard against fixed-count
  Save navigation. Existing committed-telemetry and sparse protocol checks
  reported their documented skips.
- `git diff --check` on the changed harness, schema, segments and focused test:
  passed, with checkout line-ending warnings only.

These results were captured in the agent tool transcript; no separate raw
stdout file was saved by the implementation lane. The orchestrator's repeat
has its own log, identified above.

## Production S02 result

Run `gate-f-run-20260916T030951Z-closeout/S02` exited **0** at code
`82f6c11f`, with no recorded step defects. Save navigation observed four RB
transitions: Map, Quests, Build, Players, then Save. The real slot-4 Save
button wrote **4,190,889 bytes** and `save_out` copied them to
`S02/saves/S02-exit.json`. Both files have SHA256
`21F35468F0D33918709C5186E7ABE7340C183B3C59C0BF22809AFD0FECE90CEC`.

The stderr log contains shutdown resource/GL leak diagnostics, including
SceneShaderGLES3, PagedAllocator geometry, textures and buffers. No script
error was observed; these shutdown diagnostics are retained, not described
as an error-free log. S03 is now running from this exact handoff in the same
fresh profile and at the same frozen revision.

Independent code review found one controller-binding classification edge
case. `f078e961` preserves a missing physical binding as a gameplay FAIL
instead of a HARNESS-ERROR. Expanded production-menu smoke passes **24 checks /
0 failures**, logged in `D:/tetherbound/menu-navigation-smoke-0916-r2.log`.
This source-only follow-up does not alter the in-flight S03 revision.

## S02-to-S03 seam proven; S03 village route failed

S03 loaded the copied S02 save through the production title Load path and
restored a real player near `(12.13, 0.90, -10.74)`, party size **3**, and
`tam_tools_given` as the tracked objective (the `village_tools` entry).
These explicit assertions passed. The save seam is closed at `82f6c11f`.

The next independent failure is **S03-25**. S03-23 walked to the old Tam
coordinate `(8,-16)`, but the current `village_npcs.json` places him at
`(8,12)`. The player stopped at `(9.64,0.90,-13.91)` with no interaction
prompt; the blind interact press opened nothing, and the dialogue-advance
step correctly refused. The inventory records **1 failed / 541 skipped**,
`complete:false`, and an unresolved derail. No S03 exit save exists.

The native process nevertheless exited **0**, intentionally: the harness
records gameplay expectation failures without classifying them as process
errors. The outer owner runner currently confuses that with campaign success.
Its verdict must inspect the actual inventory and derail markers while
retaining the raw process exit. The local continuation wrapper now does so;
the checked-in owner runner fix and fixture coverage are in progress.

The next replay will preserve this rejected evidence and use a new attempt
with explicit inherited S02 provenance. It will repair the current NPC/door
approaches, not move production NPCs back to retired coordinates.

## Current campaign gate evidence

| Gate | Required evidence | Current verdict |
|---|---|---|
| A0 prerequisite | Current regression, build/export, ledgers, complete packaged campaign | Open: ledgers 43/43 and 23/23; CI pending; campaign stopped at S03 |
| A1 | Objective clarity throughout the chapter | Open: S02 and S03 entry objective proven only |
| A2 | Meaningful five-creature roster pressure before the legendary | Unproven |
| A3 | Repeated fighting, catching, exploring, gathering and preparation | Open: opening combat/catch only |
| A4 | Building/rest/injury decisions support the journey | Unproven |
| A5 | Independently judged distinct regional identities | Current full-campaign capture debt remains |
| A6 | Optional places visibly invite and reward detours | Unproven by current campaign |
| A7 | Measured travel has no long empty stretches | Opening measured; remainder unproven |
| A8 | Earned roster changes between start and end | Opening save has three creatures; ending missing |
| A9 | Warden fight/presentation culminates the chapter | Unproven by current campaign |
| A10 | Release and final-five choice carry team history | Unproven by current campaign |
| A11 | Post-Warden healing visibly changes the world | Unproven by current campaign |

A1–A11 retain the meanings in `docs/acceptance/MEADOWS_EXIT_CRITERION.md`.
A0 is the handoff's prerequisite shorthand, not an additional player-voice row.

## Village-route repair checkpoint

S03 and its capture twin now walk to live Tam, Bryn and Oskar identities
within their prompt radius, then require the intended provider and prompt.
Mira's entry/exit staging uses the current shop transform, `(13.6,5)`;
the exterior route to Oskar goes around the shop through `(13.6,9)` and
`(25,9)`. A conditional controller party-cycle replaces a fainted saved lead
with an available earned creature before the normal recall input deploys it.
The actual S02 save had a fainted Ripplet and two healthy Bramblebun.

Focused Gate F validation: **93 tests / 45,628 assertions / 0 failures**.
These are route-authoring checks, not a substitute for the next real walk.

`e7fc6d35` fixes the outer owner-runner verdict. **35 focused fixture checks**
and the existing six packaging scenarios pass. Read-only classification of
the actual evidence gives S02 effective exit 0 and S03 effective exit 1,
preserving both raw zero process exits. Resume also revalidates inventories.

The new `gate-f-run-20260916T030951Z-closeout-r2` attempt retains a copied
S02 prefix with `PREFIX_PROVENANCE.json`, the original SHA and matching save
hash. This is a repaired continuation with inherited evidence; a clean
final frozen-revision campaign is still required for chapter acceptance.

## Native S03 retry: Tam and five-creature milestone proven; cost refusal

The `closeout-r2` S03 attempt at `ab1b8767` reached Tam through his live
identity, displayed `Greet Tam`, completed five dialogue advances, and set
`tam_tools_given`. The next objective became `tournament_team_ready`.
Controller party-cycle also replaced the fainted saved lead with an earned
healthy Bramblebun. Two further catches brought the party to five.

This attempt is **incomplete**, not a pass. At play time 326.817 seconds,
the cost gate refused: 238,332 remaining planned frames at 0.065142 seconds
per frame projected 15,526 seconds against 13,907 seconds of budget left.
Raw and effective process exits are both 1. The complete inventory, rolling
cost samples, route telemetry, and BLOCKER.md remain in the r2 directory.
The next investigation must distinguish sustained runtime degradation from
an inflated estimate of already-satisfied guarded catch attempts; no cost
ceiling, fight waits, or acceptance checks have been relaxed.

A read-only downstream audit found Tam's former coordinate again at
S10e-99 and an invented dialogue expectation at the passive tournament
board. S10e now approaches Tam by identity and checks his greeting provider.
S04/S04C now stand within the board's actual radius and observe its live
status and provider, including the champion status after victory. The
new read-only `interaction_prompt` predicate verifies text, ownership, and
actionability; it injects no input or progression. Region, tournament, and
acknowledgment assertions remain. Focused validation passed **96 tests /
45,727 assertions / 0 failures**, raw log:
`D:/tetherbound/gate-f-focused-0916-r3.log`. Production validation is pending.

## Cost-sampler and CI corrections; r3 replay started

`5ba5574d` fixes the cause of the r2 cost refusal: the sampler divided wall
time by manual harness callbacks, but controller settling advanced physics
without those callbacks. Settling was then budgeted again in remaining
frames. Samples now divide wall time by engine physics-frame deltas and
record both quantities. The median, refusal confirmation, 14,400-second
ceiling, gameplay waits, and assertions remain unchanged. Focused validation
passed **99 tests / 45,790 assertions / 0 failures**.

`e3603b55` applies strict inventory verdicts to the Bash runner too, while
keeping overhead diagnostics tied to their own measured metadata receipt.
Five tests / **29 real-entrypoint fixture invocations** passed independently.
The local native continuation now uses `run-closeout-segment-v2.ps1`, which
extracts the canonical PowerShell verdict function and records its reasons.

CI run `35052630249` exposed one unit-shard failure: its sparse checkout
omitted the eight accepted location manifests/reviews that the ledger test
requires. `db67c2d6` includes exactly those files in the unit checkout without
skipping the test or pulling the capture library. A real temporary Git
fixture verified that the exact sparse command restores only those eight
text files; all eight exist in the current commit.

At **2026-09-16 03:53:14 UTC**, S03 r3 started on frozen `5ba5574d` in the
native imported r5 worktree and a fresh isolated profile. It retains the
original S02 prefix with its matching hash and explicit provenance. No
S03 pass or full-campaign gate closure is claimed yet. Execution session
`47450`; evidence `gate-f-run-20260916T030951Z-closeout-r3/S03`.

## r3 exposed first-trainer loss and a production menu close-edge leak

The r3 replay passed the previous cost-refusal point, completed Tam's tools
and five-creature milestone again, and reached Bryn. S03-48 then lost the
active creature before its fixed 24 attacks completed; S03-50 also attempted
attacks after combat had ended. This is not a trainer victory. The replay
was deliberately terminated after these known failures, with the reason,
revision, timestamp and evidence paths in `S03/INTERRUPTED.json`.
`SEGMENT_RESULT.json` records raw/effective exit -1 and missing final inventory;
its partial telemetry remains available, and no complete S03 save is claimed.

The recovery telemetry revealed a real game defect: at t260.300, the B edge
that closed Satchel also consumed one potion and healed a Bramblebun from
10.9207 to60.9207HP. The same controller button binds menu cancel and hotbar1;
closing immediately unpaused and released ownership before the HUD read the
edge. `81c88162` retains menu ownership through that press's release. A parsed
physical-controller regression verifies both direct close and held-stack
first-cancel/second-close: no potion on close/hold/release, exactly one potion
and50HP on a fresh world press. The existing navigation coverage remains.

`e185e113` advances Bryn's dialogue to its actual close boundary, verifies
combat is live before the explicit pilot switch, and uses the existing
fight driver until the real `trainer_defeated_practice` flag. Loss or an
absent fight cannot pass. The generated S03C source matches the journey.

Independent timing review found that budgets include both process and
physics waits. `7c289c25` samples both counters over one wall interval and
uses the slower unit conservatively, in boot and in-play probes alike.
Both counts, wall duration and selected basis are retained. Neither the
cost ceiling nor authored waits were relaxed.

Focused validation: **104 tests /45,898 assertions /0 failures**; production
close-edge smoke passed. Raw receipts: `gate-f-close-edge-20260916-gate-f-tests.log`
and `gate-f-close-edge-20260916-smoke.log` under `ralph/reports`.
CI run35053540052 passed all four unit shards; its UI shard found a separate
combat-roster reveal-position defect under correction. Full CI remains open.

The UI-shard failure is repaired: party-strip reveal now animates an offset
against the current layout origin, so a resized active-creature panel cannot
leave the roster at an obsolete absolute tween target. Existing left-column
smoke and deterministic mid-tween reflow smoke both pass; the new regression
is included in CI. Native OpenGL rendering confirms five rows and a 24-pixel
final gap. `D:/tetherbound/party-strip-reflow-native.png` is a layout fixture
with placeholder active identity, not a full-campaign visual acceptance shot.
Native stderr is empty; local smoke and render logs are beside that image.

## Fourth diagnostic attempt: mixed frame prices

`gate-f-run-20260916T030951Z-closeout-r4` ran S03 at `03bc9a05` from
04:14:23 UTC. It preserved the original S02 save and its explicit provenance.
The run refused at 6.767 seconds of play during S03-09; inventory is incomplete,
raw and effective exit codes are 1, and no S03 exit save exists.

The third sampling window observed 120 physics frames and 35 process frames
over 1.980609 wall seconds. Applying the slower process price (0.056589 seconds)
to all 325,153 legacy mixed frames predicted about 18,400 seconds against
14,253 seconds remaining. Most movement waits use physics frames, so this
conservative mixed-unit estimate overstates their cost. The next correction
counts actual wait units separately, including previously omitted nested
waits, and retains the four-hour ceiling and authored waits. This is a harness
refusal, not a gameplay pass or a completed Meadows gate.

CI run35054816790 now passes all four unit shards and the full UI shard,
including both combat roster-layout checks. Its region shard repeats the
Warrens smoke failure seen in run35053540052: the production capsule stops
15.53m short on egress, two measured roots extend into the walking space,
and the haze-card count differs from the smoke expectation. Production
geometry versus stale fixture expectations is under investigation. The
earlier run also has cancelled jobs, so it is not a green release candidate.

The next harness checkpoint uses explicit physics/process wait bounds and
separate measured median rates. Actual runtime pricing tests cover mixed-rate
workloads, paid load time, rate-change receipts and disk cadence. Legacy frame
counts remain diagnostic. Unknown wait-bearing actions fail pricing closed.

S04 preserves all forty prescribed sequence IDs while physical controller
play continues. A completion barrier checks the full forty-second window,
valid images, and actual combat/transition/aftermath counts. Damage checkpoints
require fresh incoming and outgoing damage before verified pilot changes.
Two forward switches do not claim reverse cycling. S05 preserves three such
handoffs and proves a charged hit through the production damage signal;
readiness is earned through real quick attacks if needed. Trainer completion
uses production victory flags and dialogue closes at its actual boundary.

Validation: **125 tests /46,659 assertions /0 failures**, plus passing
prescribed-window and combat-checkpoint runtime fixtures. Generator consistency
and scoped diff checks pass. Raw receipts are `gate-f-final-typed-focused.log`,
`gate-f-final-window-smoke.log`, and `gate-f-final-combat-smoke.log` in this
report directory. These fixtures validate instrumentation, not full campaign
acceptance. Native S03 replay and capture debts remain open.

Native diagnostic r5 started at **04:39:18 UTC** on `78724778`, using
`gate-f-run-20260916T030951Z-closeout-r5` in the production worktree. Its
copied S02 prefix retains the original hash and revision provenance. It is
running, with no completed S03 inventory or exit save yet.

Canonical CB-09 requires real midfight pilot/camera handoff and no input
loss; it does not require reverse cycling. The prior segment's “both
directions” wording was an added requirement, not the protocol. The scoped
clarification is recorded in `GATE_F_CB09_ACCEPTANCE_2026-09-16.md` one level
above this directory.

The first Warrens collision adjustment failed its second traversal check
and was reverted. The real exit obstruction remains open. Exact triangle
clearance within the passage proves all twelve roots clear the existing
1.9m threshold; the earlier transformed bounding boxes included empty
corners outside the walking route. Accepted visual geometry is unchanged.

The subsequent evidence-based Warrens repair passes the full smoke, exit 0:
the real capsule traverses 61.7m into and back out of the cave. The exterior
bank blend had lost its descending collision triangles and ended 0.49m above
terrain, beyond the trainer's 0.35m step limit. Retaining that collision ramp
to ground fixes egress while preserving the exact visible triangle selection.
Enclosure, interior route, gated branch, rewards and guardian persistence
checks also pass. `warrens-continuous-egress-0916.log` preserves the complete
receipt, including existing shutdown leak diagnostics; it is not a clean-exit
claim beyond the smoke's successful verdict and exit code.

R5 S03 terminated with raw/effective exit 1 at its cost guard. The measured
typed estimate was 14,343s against 14,228s remaining (0.01666s/physics frame,
0.06825s/process frame). No S03 exit save was produced. Explicit save-linked
phases are being implemented with all original steps and capture debts retained;
the four-hour per-segment guard remains unchanged.

## Save-linked replay and paid home care checkpoint

S03p1/p2/p3 now derive from the original S03 steps, with explicit production
Save/Load boundaries. The operator validates source hashes and predecessor saves
before execution; the aggregator requires all original verdicts, unchanged capture
debts, cumulative route thresholds and a byte-identical canonical exit. Added
boundary steps cannot inflate route measurements or reset dead travel. The default
chain stops on a failed segment and aggregates p3 before allowing S04. These are
fixture-verified contracts, not evidence that native S03 gameplay has passed.

The route now targets the actual authored fiber at (31,-32) and wood at (7,-24).
Sheltered Bedroll placement uses bounded physical movement and a verified placement
input. Five-creature care reuses the single paid Creature Bed over real nights,
as allowed by the authored objective, checking each live assignment and resulting
rested state. No rest conditions or readiness predicates were waived. Production
Creature Bed panels now retain B ownership through the closing release, preventing
the same press from consuming a hotbar potion. Both HUD processing orders pass.

Integrated Gate F validation: 144 tests / 50,261 assertions / zero failures
(`phase-care-godot-0916.log`). The physical close-edge, prescribed-window and
combat-checkpoint fixtures also pass, with their full logs alongside this report.
Capture and phase generators match committed definitions. Independent adapter
review caught stale-panel selection; lookup now requires the open panel for the
exact placed bed. Native replay remains the next required check.

CI run 35056295898 at 78724778 completed: all enabled jobs passed except the
regions shard's Warrens smoke. Its other regional checks passed. That run predates
the locally passing aa19df9c collision repair; the next push must validate it in CI.

Final Python suite: 35 tests passed with portable GNU Bash enabled (no skips),
including real-shell failed-handoff fixtures and incomplete run-inventory checks.
Receipt: phase-python-0916.log. Native replay is not yet complete.

## R6 native phase result and next repair

Native S03p1 at bd23e30b finished with raw exit 0 / effective exit 1. All 195
steps ran: 171 PASS, 15 FAIL, seven SKIP and two delegated captures; inventory
complete=false. It wrote a real phase save containing four creatures, SHA256
501314066062cf62069cbc851fc5943575486d75ed0353e670d9418ed4330fec.
That failed receipt cannot seed S03p2. Text receipts are retained in r6-S03p1;
raw telemetry and save remain in the production worktree's r6 run directory.

Observed failures include second cancel presses after Satchel already closed,
approaches to unavailable wild targets/wrong prompts, and pilot faint during
repeat catching. S03-36d had only one observed launch before Moss fainted;
the old helper misleadingly reported a second throw from an input attempt.
The required fifth capture failed. None of these receipts was relabelled passing.

Next-revision repairs read actual menu ownership before B, require visible living
wild approach targets, refresh prompt observation after movement, and guard/count
real orb launches. S03 may use bounded physical LB handoffs to healthier earned
party members before re-aiming; live foe/pilot identity and loss checks remain.
Authored skip_if conditions now record freshly verified conditions explicitly as
no-input satisfaction; optional/unreached skips still prevent completion.
Event-level phase and step attribution is repaired for future runs; r6 lacks it.

Focused validation: 169 Godot tests / 50,570 assertions / zero failures, plus
40 Python tests and regenerated-source checks. Native validation remains required.
CI at bd23e30b passed the repaired Warrens smoke and its regions shard. A Python
fixture used Bash syntax under /bin/sh; corrected to POSIX test syntax after local
four-case rerun. The completed CI job log confirmed that exact POSIX incompatibility; the next CI phase-continuity step passes.
Multiplayer shard 4 also failed and is under investigation before merge.


## R7 native checkpoint and pending R8 repairs — 2026-09-16

R7 S03p1 at `898b521a` reached five creatures and saved a real slot-4 handoff,
but failed strict acceptance: 188 PASS, 5 FAIL, 0 SKIP, 2 DELEGATED out of195
steps. Raw process exit0, effective exit1. No S03p2 was launched from this run.
Save SHA256: `7d9d11adfc46f7608f3f6590bab257673c27a819150beb7cb9149c5341a5b8ad`.
Text receipts are retained under `r7-S03p1`; raw telemetry and save remain in the
production worktree's `gate-f-run-20260916T030951Z-closeout-r7/S03p1` directory.

Failures: pilot/foe loss before another catch attempt (36c), physically blocked
throw aim (36f), first chip swing defeated a previously wounded foe (35g/36g),
and a live-target approach stopped3.5m away after3000frames (32h). The later
catch succeeding does not erase these failures. The old inventory incorrectly
reported complete=true despite steps.fail=5; the independent runner rejected it.
The next operator revision explicitly includes zero FAIL in completeness.

Pending R8 replaces the unconditional post-breakout wait with observed production
signals and requires the exact caught foe appended to the unchanged real party
plus a completed caught exit. A read-only production damage bound protects the
first and every subsequent quick chip hit, including critical/variance/type
multipliers, and waits for outstanding attacks before re-reading HP. Every new
wait is charged to the existing cost ceiling. Capture S03C is also being split
through actual Save/Load seams without inventing a final fight/save requirement.
These are repairs awaiting a new native run, not Meadows acceptance.


Integrated R8 candidate validation:184 Godot tests /53,426 assertions /zero
failures;55 Python tests passed with the POSIX shell available. Windows kickoff
fixtures passed265 phase checks and35 existing runner checks. The final native
candidate also logs selected walk target, target gaps, detour state and collision
normals every60walking frames without adding simulation frames. R7 replay shows
its orbit would not trigger the existing confinement watchdog; no speculative
navigation repair is claimed. CI at898b521a has passed all four unit shards,
phase continuity and multiplayer shard4; remaining jobs are still pending.


## R8 native result and R9 candidate — 2026-09-16

R8 S03p1 at `b13beee2` finished184 PASS,9 FAIL,0 SKIP,2 DELEGATED; actual
five-member party, raw exit0/effective exit1, inventory.complete=false.
No continuation was launched. Saved slot4 SHA256:
`3f9688ad34d5bfc93340c90cfa33d6e5bec5afa2d5b396c5c4de9ceb1f005855`.
Text receipts are under `r8-S03p1`; original telemetry/save remain in the
production worktree's `gate-f-run-20260916T030951Z-closeout-r8/S03p1`.

The outcome observer worked natively: first attempt observed three breakouts,
then an actual fourth launch, caught exit and exact foe appended. Two failures
in attemptb came from the intervening blind LB selecting a newly caught15HP
Bramblebun despite79HP/58HP allies; it fainted during the required staging wait.
Seven later chip failures exposed missing authored `skip_if party_size>=5` on
those actions; approach/engage/throw already had that condition. The old chipper
could inspect a stale enemy after the roster was full. New live guards correctly
refused that state rather than hiding it.

R9 prospectively repairs the protocol: world recovery selects greatest current
HP among earned living/non-resting members using mapped LB only, verifies actual
visible companion and unchanged roster, at most one traversal/600physics+8process
waits. Ten catch chip actions now verify the same earned-five condition as their
approach/throw pair before issuing input. Explicit combat switch and training
rotation steps retain their own semantics. No health, active-index or deployment
writes are used. Generated logic/capture phase manifests have been refreshed.

The authored catch expected result says caught OR every allotted throw spent.
Accordingly, every verified launch plus observed miss/breakout can finish an
attempt without catch; early loss/aim/identity/missing-outcome errors remain FAIL.
Following world-context and actual five-member assertions remain binding. This
is prospective; none of the R6/R7/R8 failures has been relabelled. INCOMPLETE now
also prints the step verdict counts directly.

Validation:191 Godot tests /53,524 assertions /zero failures;55 Python tests;
all capture/phase generation checks. Full-protocol study scheduling adds170
PowerShell assertions, with existing35 verdict and265 phase checks passing.
The scheduler preserves frozen checkouts, requires successful named checkpoint
providers, checks actual authored outputs, and rejects differing-byte saves that
could shadow the harness's input. X06 variants precede X05 awkward-save study;
no fake X06 parent pass is published. Studies still require actual execution.


## R9 S03p1 clean diagnostic handoff — 2026-09-16

At frozen production revision `c9c4610e7856eacdb5e83c08652e1bab978dc90e`,
S03p1 completed193 PASS,0 FAIL,0 SKIP,2 DELEGATED; all195steps ran, no
refusals, inventory.complete=true, raw/effective exit0. Actual slot4 save has
five creatures and eight Revives; SHA256:
`3d6b29fb82cf5c9f5f88a73c4206184a4f96e638165e6c4a2e7213c791dbe867`.
Original-route metrics carried forward:224.200606m,746trace rows,
dead-travel peak0.325805m. These are only the first phase's metrics; the full
S03 aggregate still owes420m/1200rows and all later canonical steps.
Two prescribed captures remain delegated to S03C. Text receipts are copied under
`r9-S03p1`; raw telemetry/save remain in production `closeout-r9/S03p1`.

The first catch attempt observed four real breakouts and completed its allotted
throws without claiming a catch. Its following world/recovery requirements
passed. Attempts b and c each caught on one observed throw. Physical healthy
selection passed natively and no post-full-party attack was issued.
S03p2 has started in the SAME production worktree/run/revision; do not fast-forward
that worktree mid-chain. No current evidence establishes completed S03/A0-A11.

Separately, source-only next-candidate readiness repair replaces S03-09's fixed
180seconds of game time with a world-input readiness predicate and the same
10800-frame maximum. R8/R9 showed the loaded world was already ready at play
~1.7seconds after synchronous wall-clock CPU loading; standing idle afterward
was not a chapter beat. Generated logic/capture phases match,33 Python phase
tests pass. This change is NOT in the frozen R9 production run and remains
uncommitted pending the diagnostic chain outcome and engine validation.


## R9 S03p2 interrupted on repeated training-route failures

S03p2 did not pass. Its global ranks 10+ selected living wild creatures hundreds
of metres from the player: the first target was roughly276m away, beyond the
2000-frame walking budget (roughly167m unobstructed at5m/s). Subsequent ranks
sent the player back across the map. After seven repeated failed rounds the
operator stopped the attempt; process/effective exit is-1, inventory/save absent.
Original telemetry remains in closeout-r9/S03p2; r9-S03p2 contains the failure
summary and interruption receipt. Do not aggregate or continue its handoff.

The next candidate uses nearest living wild targets, retains existing walking
budgets, and requires actual production victory plus XP progress for training.
Paid Revive recovery and healthy pilot selection are being integrated to keep
fainted teammates eligible for subsequent XP. No items, health or XP are granted.
The nearest-target and victory guards passed7 focused Godot tests/27 assertions;
the full revised training phase still needs native replay.


## R10 candidate validation

Nearest-live training and opt-in production victory/XP readback are implemented.
The training path now uses owned Revives for fainted teammates and physically
selects the healthiest available pilot between wins. Existing explicit in-fight
LB check remains; shared XP must still satisfy the unchanged whole-roster level
five gate. Recovery verifies exact item payment, same creature identity, unchanged
teammates and restored world input; no-faint recovery emits no controls.

Focused Godot:204 tests/53750 assertions/0 failures. After clarifying recovery
receipt counters as reserved rather than elapsed frames, affected recovery/budget
tests:16 tests/91 assertions/0 failures. Python:55 tests passed with shell fixtures
active. Capture and both phase generators match. Full paid recovery is priced at
280 physics+670 process frames; p2 conservative estimate6671.8seconds remains
under the existing14400second cap. These tests are not native training acceptance.

Next native diagnostic starts S03p2 from the genuine clean R9 p1 exit save, with
its original SHA/hash recorded as an inherited prefix. This avoids replaying the
already diagnosed roster build for each training fix; it is not a one-SHA chapter
and cannot satisfy canonical full-campaign acceptance. A fresh full run remains
mandatory once the route is repaired.


## R10 refused; R11 same-revision S03 replay started

R10 failed before gameplay: the strict phase predecessor check rejected missing
same-revision S03p1. The proposed inherited R9 p1 shortcut is therefore withdrawn;
no guard was relaxed. The exact refusal is retained under r10-preflight-refusal.

Committed/pushed candidate015dab0f0643b6c962331ba3c693779055dd41bd is frozen
in the production worktree. R11 S03p1 is now running with the original hash-verified
S02 diagnostic prefix. Its S03p2/p3 must follow successful same-revision outputs.
R11 remains diagnostic because the earlier S02 prefix belongs to82f6c11f; fresh
full-campaign acceptance remains outstanding. Do not fast-forward production
while any R11 phase is running or between its phase handoffs.


## R11 S03p1 completed with two preserved failures

At015dab0f the readiness predicate passed at play1.717seconds with zero extra
physics waits. The first wild approach stopped at25.89,0.94,-43.30 within the
authored2m creature radius, but deadwood at0.96m won nearest-prompt arbitration;
after prompt settling its distance was0.84m. S03-32a2 correctly refused the
Gather prompt; S03-35a then failed with no combat enemy. Later catches built the
roster, but these two failures make the phase incomplete: rawexit0/effective1.
Do not continue this save as an accepted phase. Text receipts are r11-S03p1.
A bounded physical reposition with exact target/provider readback is being built;
no harvest is triggered, prompt priority altered or failure waived.


## R12 candidate: exact physical Engage approach

R11 final counts:191 PASS,2 FAIL,0 SKIP,2 DELEGATED; all195steps ran, no
refusals. Its ineligible diagnostic exit save hash is
5f9f0fb4f74de6f47e095dc50d4ab3f4602ae5288932697a8959ab6821c3cb45.

All30 catch/training approaches now require the exact selected living wild to
own the actual actionable Engage offer. If another interaction wins, four
physical stances around the live target share the unchanged walking/held budget.
The following interaction rechecks the pinned target/provider after settling and
immediately before input. No prompt priorities, harvest objects or game state
are changed. Full-roster conditional checks still happen before engagement guards.

Validation:211 focused Godot tests/53918 assertions passed, including the
transaction observer tests. Real production Satchel snapshot smoke:25checks/0fail.
Phase Python:33tests passed; capture and both phase generators match.
The multiplayer measurement repair is separately committed asf48590c8 after
4unit tests/18assertions and a first-attempt real two-peer shared-wild smoke pass.
These checks do not substitute for the next native S03 phase chain.


## R12 S03p1 passed; training phase running on frozen3b20f154

All195steps ran:193 PASS,0 FAIL,0 SKIP,2 DELEGATED, no refusals,
inventory.complete=true, raw/effectiveexit0. Real slot4 exit save SHA256:
e2eeb790375f7e38bfebeeeec5aa86ebe82182949a3d5d4eb71dbf6f812f0ade.
The first two catch attempts each caught on one observed throw. This run
approached a different roaming wild than R11, so it proves successful guarded
approach/catches, not a forced reproduction of the four-stance deadwood case.
Text receipts: r12-S03p1. S03p2 now runs in the same run/worktree/revision.

Independent review found a post-input target identity race: the production
consumer recomputes its target after the pre-input readback. Source-only follow-up
retains the pinned target through input and requires the actual live combat
enemy body to match after the existing settle.4focused tests/37assertions pass.
This follow-up is not in R12 and must be included in the final fresh candidate;
do not fast-forward production or mix phase definitions while R12 is running.

## R12 training stopped: production trainer staging crosses a cottage wall

R12 S03p2 at3b20f154 was intentionally interrupted after33 actual defects
(eleven training rounds, each approach/Engage/fight failed), duringS03-51n11a.
Raw/effectiveexit-1; no eligible handoff. Its prompt/identity guards correctly
issued no input while trapped, and no fight was reported as successful.

Bryn challenge begins at(13.18,0.90,7.36). S03-45 battle staging changes the human
position to(20.06,0.90,4.38), inside cottage_a_3. The first training approach
already oscillates atx19–20.37,z2.63–3.35, about44.6m from its selected live wild.
This never reaches the2m Engage stance logic. Production
CombatManager._stand_the_trainer_aside grounds the side destination but does
not check the path against structures. Collision-safe staging is under repair.
Compact failure and staging receipts: r12-S03p2; raw telemetry remains in the
production run. The inherited S02 prefix still prevents full-campaign acceptance.

The post-input opponent identity guard passed6focused tests/46assertions with
the actual operator script preloaded (r12-post-input-integration-tests.log).
CurrentCI4773 multiplayer shard2 passed with the transaction observer repair;
other running jobs are not counted as passes.
