> **GitHub publication update:** At the owner's subsequent request to push this exit, the unfinished source/tests were preserved in commit **b7cb9ee128968011870eee20c4dfc60475508c0c** on **codex/stormwood-hosted-integration-0907**, followed by this handoff documentation commit. References below to uncommitted/unpushed work describe the original stop-time state and are superseded by this publication note. The code remains unproven and unmerged; no implementation or test rerun was performed for publication. Main remains the previously verified PR #77 landing. Recover the WIP from this branch; do not merge it merely because the exit is published.

# Stormwood exit handoff — owner stopped execution, 2026-09-07

This is the current pickup document. **The owner explicitly asked this agent to stop implementation and hand off. Do not interpret the still-incomplete goal or an old reminder as authorization for this agent to resume.** The chapter is not complete. No phase or full exit criterion is accepted. The latest official score is **12/100**, not a percentage estimate of code written.

## Repository and safe recovery

- Work in **D:\Tetherbound-source**, not the conversation's C: checkout.
- Current branch: **codex/stormwood-hosted-integration-0907**.
- HEAD and last verified origin/main: **ba8a66fbfe823c439a3adea268d00fce0199fff7** (PR #77).
- PR #77: https://github.com/MJohnsonWellabe/Tetherbound/pull/77 ; all code jobs passed in CI run **34122979345**. Its head **cc484c0ab1fe1f95607a983093b3484ca7b4958a** was rechecked as an ancestor of origin/main at exit (exit 0).
- Earlier landings: PRs #68, #70, #74 and #76. PR #76 main was **4562268dee581d2f2ce167a4670bbf752f139310**. Do not confuse its older reports with the latest main.
- The hosted-combat wave below is **uncommitted, unpushed, and has no PR**. Preserve the working tree before any checkout/reset. Never `reset --hard` to reproduce the initial startup instruction now: it would discard the continuation work.
- Old pushed branch `ralph/stormwood-dynamo-0907` contains merged PR #77. Historical scratch backup `a92faa8bd` remains intact.
- `D:\CodexWork\stormwood-authority-lane` is an unused, stale sparse draft. `D:\CodexWork\stormwood-recipes-lane` is an unused partial worktree. Do not use either as the source of current code.
- A former assets junction in the authority worktree caused sparse Git operations to remove tracked primary assets. Root removed that junction and restored primary `assets/` exactly from HEAD; asset diff was verified empty. **Do not recreate asset junctions or attempt another sparse-worktree repair.** Primary D: has the working assets/import cache.
- Other origin art/Cloudreach/Water lanes are not ours to land. Cloudreach wins conflicts. Never push main; ship future implementation via reviewed PRs and actual green CI code jobs.

At stop: both current delegated agents were interrupted; no Godot process appeared in the process inventory. The overnight update automation was set to **PAUSED**. No background build or test is being claimed.

## Read and retain the owner's contract

Read CLAUDE.md, docs/00_START_HERE.md, docs/DEVELOPMENT_ROADMAP_START_HERE.md, then the Stormwood 00_CODEX_START_HERE.md, EXECUTION_PROGRESS_POLICY.md and BUILD_STORMWOOD_TO_COMPLETION.md in order. Read docs/reference/boards-2026-09-06/README.md and both Stormheart Tree boards. Follow the owner's Stormwood multiplayer directive and docs/AGENT_WORKFLOW.md.

Owner choices remain settled: Stormwood is Biome 3, Water Biome 4; realm `stormwood`; Stormglass Arches; no creature teleport; captive legendary; Spark with Livewire; lightning hurts; cap 100. **The Stormheart Tree IS the Dynamo**: lower Outer Works, hollow-trunk ascent, split-core arena at the top and captive chamber in its crown. Retain all four banks, three plates, three phases, Marrow, Kestrel and Ember Bivouac. No new creature meshes. One owner-board-based Meshy split-trunk hero object is allowed only after a playable kitbashed arena; none has been generated. Do not ask the owner to settle these again.

## What is actually on main

“Proven partial” below covers only the evidence named, never the complete system.

| System | Status and evidence boundary |
|---|---|
| Cloudreach handoff | Proven partial: retargeted entry/return and two-peer realm seam. Continuous traversal from a completed Cloudreach save remains unproven. |
| World | Implemented but unproven: six Terrain3D regions, 108 terrain chunks, 33,773 baked placements, initial tree and climb, 15 settlement structures. No accepted full route, forest composition or Ally performance. |
| Surge | Proven partial: host clock, phase-gated harvest, rod timing. No blind phase recognition or complete co-op field sequence. |
| Hazard | Proven partial: announced host strike fixture, evasion and duplicate suppression; all-phase Glass Sink eligibility. Equipment mitigation and actual multiplayer creature/player field impacts incomplete/unproven. |
| Arches | Proven partial: ancient relight/travel and constructed-pair cost, pairing, Crown return, dismantle and blocked-destination fixtures. ENet construction/late join and full journey unproven. |
| Crown | Implemented but unproven: constructed access and heartstone fixture. Guardian unmounted; guardian → Wen → heartstone → Rootgate path incomplete. |
| Story and objectives | Implemented but unproven: 28 objectives, six side chains. Actual opening Ashfoot → Hesk → Tamsin objective passes; later continuous story does not. |
| NPCs | Implemented but unproven: 19 mounted; 57 conversations/171 lines. This does not satisfy 160 stateful dialogue nodes. |
| Trainers | Implemented but unproven: 26 mounted. Main lacks proven client-originated host-owned fights; unmerged wave attempts this. Guard victory → rod chain not played. |
| Encounters | Implemented but unproven: 330 clusters mounted as 660 wild instances. Six named encounters and Surge/night population changes not integrated. Remote-origin wild authority remains a gap. |
| Resources | Proven partial: real durable harvesting and charged Stormglass collection. Whole collection/crafting loop unproven. |
| Gear | Implemented but unproven: items/eight live recipes; insulation effects incomplete. |
| Pickups | Proven partial: 229 configured, 226 ordinary mounted including four electric TMs, three story rewards withheld. No walked exploration cadence proof. |
| Camps | Implemented but unproven: six anchors/rest-recovery setup. Built rod and intended pressure/recovery loops unfinished. |
| Dynamo | Blocked by missing implementation: rules/kitbashed parts/adapters exist, but no mounted three-phase controller or played Marrow fight. |
| Legendary | Blocked by missing implementation: captive specified; release, offer and five-slot ceremony absent. |
| Spark | Blocked by missing implementation: no earned relic/Livewire sequence. |
| Aftermath | Blocked by missing implementation: no played storm-ending/world response. |
| Waterward setup | Blocked by missing implementation: no played ending looking at non-enterable water. |

These blockers are engineering work, not a request for owner permission. No missing gameplay was intentionally deferred. Creature art replacement is deliberately deferred by owner directive. Do not advertise Stage A as finished or advance the roadmap to Stage B just to satisfy an end-of-run wording requirement.

## Preserved unmerged hosted-combat wave

New source files:

- `scripts/combat/stormwood_authoritative_fight.gd`: host-owned opponent using existing damage/AI; no private party/input/camera. Retarget preserves windup. Arena hidden on host. Not a complete Dynamo.
- `scripts/combat/stormwood_hosted_trainer.gd`: host roster, shared EncounterHost records, sequence/cooldown/move/position checks, participants, round transitions, host damage and reward hook. Missing deployment gets a two-second party-switch grace; realm exit withdraws immediately. Co-op scaling refreshes AI profile.
- `scripts/combat/stormwood_combat_manager.gd`: local per-round XP award deduplication for hosted verdict/snapshot ordering.
- `scripts/world/stormwood_encounter_hub.gd`: Session transport, actual sender realm and proximity/card admission, client/observer replicas. Marrow intentionally refuses without a Dynamo controller.

Modified source files:

- `scripts/combat/stormwood_encounter_director.gd`: hosted start/rendering/party switching/observer/reward adapters.
- `scripts/world/stormwood_combat_runtime.gd`: mounts the new manager and hub.
- `scripts/net/session.gd`: stable global request/event transport for a remote Stormwood participant when the host stays in Meadows. Shared net change requires full suite/CI before landing.

New/modified tests:

- `tests/test_stormwood_hosted_combat.gd`: four tests/eight assertions on retarget and award-hook ordering. Historical verified pass: `D:\CodexWork\stormwood-hosted-unit-root.log`.
- `tests/smoke_net_stormwood_hosted_trainers.gd`: real two-process host-in-Meadows/client-in-Stormwood test. Intended strike/roster/reward checks are **not proven**, because the last run stopped at trainer start.
- `tools/net/peer_runner.gd`: test-only hosted start/health/raw-strike/input/probe adapters. Raw injected action IDs also advance the local test counter so subsequent real buttons are not spuriously stale.

Latest edits made just before owner stop:

1. Hub now sends `start_refused` with an explicit admission reason, remembers `last_start_refusal` and shows an ordinary Game world message. Covers distance, deployment health/presence, existing defeat, prerequisites, busy battle and unavailable opponent/Dynamo. Early version compiled; the final added message mapping **has not been recompiled/run**.
2. Delegated fixture edit split trainer positioning into `prepare_only` and `request_only`; smoke polls host actor/trainer positions to <=5 m before requesting admission. The agent was interrupted by owner stop; these files **must be inspected and compiled before use**. Do not assume the patch or its diagnosis is complete.
3. No rerun of the failed two-process smoke occurred after those edits.

Other modified docs are CURRENT_STATE.md, crown-wave-evidence-0907.md and fresh-session-tail-0907.md. Pre-existing untracked `.agents/`, generated `.uid` files, historical reports and `tools/_probe_stormheart_tree_v5.gd` remain; do not sweep them into a PR with `git add -A`.

## Exact current blocker and next hypothesis

Last real net run: **stormwood-hosted-20260907-1317**.

- Driver: `D:\CodexWork\stormwood-hosted-net-root-driver.log`.
- Peers, homes and terminal summary: `D:\CodexWork\stormwood-hosted-net-root\`.
- PASS: listen host/join, distinct real ENet peer ID, shared keys, client Stormwood entry, host physically Meadows, ready Stormwood host shell, remote actor and deployed creature.
- FAIL: remote client starts authored `tamsin_surge_lesson` through the hub. Peers exited cleanly. No strike, round, reward, co-op or late-join credit.
- Strongest **unconfirmed** hypothesis: reliable start arrived before the host actor transform converged after test teleport. Host log records destination landing initially refused `too_far`, then accepted. The original fixture waited only 20 local frames; hub refused >12 m silently. Deployment PASS does not independently prove a healthy host card, so do not claim the position race as established root cause.
- The new host-position wait and refusal reason will separate these possibilities. First inspect interrupted test edits; then run once against this changed hypothesis. Do not repeat unchanged failures or weaken admission checks to green a fixture.
- Test party starts at Meadows levels while Tamsin is level 32/33. A later loss during protocol checks may require an explicitly authored level-appropriate fixture; that would prove protocol, not balance.

Other high-value blockers/repros:

- Crown: enter through constructed pair and visit Wen. Guardian has no runtime, so the intended guardian gate is absent. Mount named authority first, then gate truth and play through Rootgate.
- Dynamo: approach Marrow; challenge remains locked because StormwoodDynamo controller is absent. Reuse proven hosted fights inside a separate climax controller; do not turn it into a generic roster-only battle.
- Visual: `D:\CodexWork\stormwood-crown-compatibility\_sheet.png`; blind report `crown-visual-judge-0907.md` fails both bars. Sparse/grid forest, weak tree landmark/split, bare settlements and Crown artifacts remain. Frame 05 white arch is emissive WallEntrance material (2.8); flat island is constant-height Glass Sink core. Investigation: `D:\CodexWork\stormwood-crown-frame05-investigation.md`. Neither fixed.
- Ending: there is no release/Spark/Waterward runtime to test yet; adapt existing five-slot ceremony/relic mechanisms after real Dynamo victory.

## Evidence, census and score history

Use the full table and exhaustive **461 replacement points** in [census-and-placeholders-0907.md](census-and-placeholders-0907.md). It contains actuals beside §13 minima: 373 encounter points, 87 trainer points and one captive point. Its counts remain the referenced audit; historical labels saying PR #77 arches/TMs/Dynamo rules are unmerged are superseded by this exit document. Do not turn configured rows into runtime proof.

Important census gaps: 57 conversations versus >=160 required dialogue nodes; eight live recipes versus >=12; three of four new buildables lack mounted consumers; named encounters and phase population changes unmounted; ten rod-able clearings, required resident distribution, off-path pickup percentage, route cadence and audio not verified. Nine arches/five footings, 210 harvests (35/region), 28 charged sites, 229 configured pickups and 28 main objectives are actual configuration counts. Route polylines total about 24 km but have not been walked as acceptance.

Evidence index:

- `runtime-wave-evidence-0907.md`: opening, harvest, lightning and earlier integration scope.
- `crown-wave-evidence-0907.md`: constructed arches, heartstone/TM proofs and PR #77 CI.
- `crown-visual-judge-0907.md`: failed blind acceptance, not a passing visual report.
- `D:\CodexWork\stormwood-hosted-opening-assets-restored.log`: real assembled opening prefix passes; does not start Tamsin combat.
- PR #77 CI run 34122979345: all code jobs green; intentional known-red/export jobs skipped. Covers merged PR #77, **not this uncommitted hosted wave**.
- Local full-unit `stormwood-crown-full-unit-wave.log` has no terminal summary; process/handle gone. Not a pass.
- An accidental direct invocation of `test_stormwood_hosted_combat.gd` during the final turn was interrupted; it is not a runnable suite by itself and supplies no new evidence. Use the actual runner below.
- No continuous chapter playthrough, accepted frames or measured ROG Ally result exists.

Frozen scorecard: [scorecard.md](scorecard.md). Baseline 0; 23:54 UTC 0; 01:54 5.25; 03:54 12 (+6.75). Missed 05:54 and 07:54 windows are retrospectively 12 (+0, +0), reaching the original stop condition. Approximately 04:06–12:10 UTC had no verified work. Owner resumed at 12:10, same weights and 12-point baseline. The resumed 14:10 checkpoint **was not reached/executed before owner stop**. PR #77 has not received a new weighted rescore. Do not claim 12+ productive unattended hours.

## Next five bounded tasks for the successor

1. Preserve the dirty wave, inspect interrupted fixture edits, and prove remote trainer admission/host strikes/two-member roster/rewards. Add real co-op and late-join evidence; run full suite for Session changes and ship reviewed PR after all code jobs green. Fix actual causes, not assertions.
2. Mount named encounters using host authority; complete Crown guardian → Wen → heartstone → Rootgate. Audit actual trainer/objective event mappings and guard-to-rod transitions; the interrupted read-only chapter audit produced no accepted findings.
3. Implement the separate Stormheart Dynamo controller: four banks/three plates, Marrow phases, piloted conduit strikes, co-op/late join, wipe recovery at Ember and gated victory. Keep the board's tree structure.
4. Finish captive offer/five-slot ceremony, Spark/Livewire, storm aftermath and final non-enterable water view. Play the full main path before polishing a narrow tail.
5. Close remaining §13/progression/save/visual/performance gaps from continuous play and blind frames; reconcile CURRENT_STATE and roadmaps to reality. Only then advance to Stage B Water.

## Known-good command shapes for a fresh run

Godot: `D:\CodexWork\godot-4.7\Godot_v4.7-stable_win64_console.exe`.

From D:\Tetherbound-source:

```powershell
& D:\CodexWork\godot-4.7\Godot_v4.7-stable_win64_console.exe --headless --path . --check-only --script tools/net/peer_runner.gd
& D:\CodexWork\godot-4.7\Godot_v4.7-stable_win64_console.exe --headless --path . --check-only --script tests/smoke_net_stormwood_hosted_trainers.gd
& D:\CodexWork\godot-4.7\Godot_v4.7-stable_win64_console.exe --headless --path . --script tests/run_tests.gd -- --only=stormwood_hosted_combat
```

For the actual net smoke set a new TB_NET_RUN_ID and TB_NET_OUT_DIR, then run `--headless --path . --script tests/smoke_net_stormwood_hosted_trainers.gd`. Inspect terminal driver and peer logs, not exit code alone. For visual work use `tools/survey.sh` and the visual-judge skill; production is Compatibility/OpenGL. Never force a rendering driver with headless, and never judge your own frames.

No implementation or validation should be inferred beyond the evidence above. This handoff preserves unfinished work for another agent; it is not a completion report.
