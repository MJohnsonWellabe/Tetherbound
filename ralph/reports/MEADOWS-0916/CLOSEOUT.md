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
