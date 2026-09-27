# Meadows session wrap-up — 2026-09-19

## Current direction and stopping point

Stopped at the owner's request after documenting and pushing the session.
The controlling scope is `docs/owner/OWNER_DIRECTIVE_2026-09-19_LANE_RESTRUCTURE_CONTENT_AND_COMBAT_SPLIT.md`
(read from fetched `origin/main`) and the user's matching instruction:
prioritize Meadows content throughout the map, especially off-trail, and visual
quality. Gate F A0–A11 is opportunistic and must not block content/visual work.
Combat depth, Cloudreach, Stormwood and Water are separate concurrent lanes.
No content/visual implementation has yet been made under the revised scope.

Read `ralph/reports/MEADOWS-0919/PLAN.md`'s superseding scope first. Its older
campaign-first plan is historical. `RESULTS.md` contains chronological evidence;
older statements that a run is running or next are superseded by this handoff.

## Git checkpoints

- Source: `D:\tetherbound\source`, branch `codex/all-branches-integration-0913`.
- Draft PR: https://github.com/MJohnsonWellabe/Tetherbound/pull/127 (not landed).
- `f1fd7833`: physical passage through live village road gates, preserving targets
  and original budgets; selected spontaneous combat handled explicitly.
- `34a3e0a5`: Oskar approach waypoint moved clear of the tournament bench.
- `bcad22f2`: physical L3 sprint for long training approaches; normal stamina,
  release on exits/holds, original targets and budgets retained.
- `3692fd618367e5c5c336fa80452f31c54d491f81`: exact absent/present harvest claims,
  physical companion deployment and verified readiness before night combat.
- `2a02a2c01c6944851c7865e24a498feb94f309db`: revised content/visual plan and results.
- Production worktree `D:\tetherbound\owner-kickoff-closeout-r5`, branch
  `codex/meadows-campaign-0916`, remains at `3692fd618`.

## Validation and limits

R17 on bcad22f2:

| Phase | PASS | FAIL | SKIP | DELEGATED | Outcome |
|---|---:|---:|---:|---:|---|
| S03p1 | 193 | 0 | 0 | 2 | complete, raw/effective exit 0 |
| S03p2 | 169 | 0 | 0 | 2 | complete, raw/effective exit 0 |
| S03p3 | 215 | 3 | 20 | 3 | incomplete, raw 0/effective 1; no handoff |

Phase 3 exposed optional duplicate harvest presses after one-claim depletion,
and a recalled companion preventing the night encounter. The final repair
preserves first harvest interactions and checks exact node flags before/after;
RB deploys the companion, visible living identity is verified, and physical
party selection chooses a healthy earned pilot.

Final native diagnostic: **38/38 PASS**, no failures/skips/refusals/delegations.
Actual RB deployment, selected Mudsnout approach (343 walking frames, zero held),
Engage, victory and XP (334 fight frames) passed. All twenty harvest flag
readbacks passed. This used a failed phase save and explicit diagnostic setup:
it is not campaign or night-visual acceptance and yields no campaign handoff.

Focused tests: attempt 1 parser failure; attempt 2 fixture failure; attempt 3
**7 tests, 51 assertions, zero failures**. All attempts retained. Final Python
suite: **57 tests passed** with Bash configured. Capture and both S03 phase
derivation checks match. Earlier diagnostic retries and CI audits are recorded
in RESULTS.md; do not present retries as first-attempt passes.

CI 4799 on bcad22f2 completed successfully. CI 4802 on 3692fd618 was cancelled
after the newer plan push; it is not a passing verification of the final repair.
The wrap-up push may trigger another run; inspect its actual code jobs before
claiming current CI success. No merge, current export, visual acceptance or
A0–A11 promotion is claimed.

Evidence is committed under `ralph/reports/MEADOWS-0919/`: `r17-S03p1`,
`r17-S03p2`, `r17-S03p3`, `preconditions-native-attempt1`, focused/Python logs.
Raw local telemetry/capture payloads were not staged.

## Local state and coordination

R18 (`gate-f-run-20260919-meadows-r18`) has only a prepared inherited S02 prefix;
**no phase started**. Do not launch it merely to chase a clean automated run.
Prefix SHA256: `21f35468f0d33918709c5186e7abe7340c183b3c59c0bf22809afd0fece90cec`.
No Meadows native check remains mid-flight. Other lanes have Godot processes;
do not kill them. At wrap-up inspection the render lock was unheld; it is shared
live state, so re-read and atomically claim before every future render/capture.
Use `D:\tetherbound\RENDER_LOCK.json`, release immediately, and never render
while another lane holds it. Priority: Meadows, Cloudreach, Combat, survey.

Preserved unrelated working-tree changes include import/UID churn,
`shaders/earth_bank.gdshader`, S08C/X01C/X03C line-ending changes, and existing
untracked probes/capture payloads. Do not blanket stage, reset or clean.
Machine-local locked-run wrappers in `D:\tetherbound` remain available; they
are not portable committed artifacts.

The app goal remains the old usage-limited goal. Replacement was rejected
because it is unfinished; available tools cannot edit its objective or resume
it. It was not falsely marked complete. The new owner scope governs the next
session irrespective of stale app metadata.

## Next authorized work when resumed

Inspect current main and reconcile real optional activities, rewards, NPC
directions/map reveals and visible off-trail draws across Meadows bands. Pick
an evidenced underserved area, reproduce its production appearance and actual
interaction, then implement a coherent discovery or visual repair using existing
assets/systems. Verify interaction, focused checks, production render and
code-blind visual review. Record validated checkpoints; commit through CI/PR
and verify landing on main. Preserve other lanes and do not resume campaign
automation as the primary task.
