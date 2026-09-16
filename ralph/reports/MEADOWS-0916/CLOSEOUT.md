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
