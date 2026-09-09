# Begin cancellation correction — focused first-attempt evidence

2026-09-09. Root approved this bounded correction after snapshot `0a9d5b544`. No branch change, commit, push or full-world rerun by this lane. Changed production files: `scripts/net/realm_transition.gd`, `autoload/game_state.gd`; focused fixtures: `tests/test_realm_transition.gd`, `tools/probe_realm_transition_game.gd`.

The boolean begin API remains compatible. A deadline after a grant now sends cancellation and awaits a separate acknowledged outcome, bounded by the existing 120-second timeout. Authority replies distinguish traffic-free refusal, completed abort and loading-won recovery. Receipt application requires matching client epoch, request and token, an active settlement, and no earlier terminal outcome. A loading-won receipt additionally requires the actual loading transaction installed locally. Timeout retains identity and gates; a late reply cannot overwrite that terminal recovery outcome. Existing Session reset clears it and old epoch waiters fail.

Game returns directly only for refusal/acknowledged abort. Loading-won failure creates the existing overlay, preserves the undetached source root, checks actual source identity/readiness, explicitly retargets the host transaction to the source (Game has not changed its own realm yet), and uses existing guarded rollback admission/dismissal. An unsettled cancellation or failed recovery exposes the existing focused exit-without-save action. No receiver is silently deleted or reopened on uncertain settlement.

## Focused result

First changed-source attempt `.artifacts/realm-transition-cancel-v1/`: focused units **13 tests / 65 assertions**, exit 0, raw log clear. Actual Game fixture **108 checks**, exit 0, approximately four seconds. Its exactly four existing declared negative ERROR lines were two injected target-readiness refusals, guarded rollback recovery, and host autosave refusal. No unexpected ERROR, SCRIPT ERROR, WARNING or FAIL. Terminal CIM inspection: Godot count 0; tiny lease released to root.

New unit coverage exercises stale epoch/request/token, delayed receipt after cleanup, loading installation prerequisite, retained gates, terminal settlement timeout, reset/new-session independence and acknowledged refusal reuse. Four new actual Game modes exercise refused, aborted, recovery-required and unsettled outcomes, source preservation, explicit host retarget, readiness before admission, no destination admission, and usable recovery UI. The Game coordinator remains a recording seam; this does not establish native cancellation composition.

## Proposed next native proof for review

Reuse the established three-peer real Session/adapter fixture with its actual trainer and creature spawners and peer-owned state. Add one explicit cancellation mode that calls **actual Game.enter_realm** on the mover with the existing tiny source assigned as its current scene. Drive cancellation at the actual inventory-empty/drained event before the host loading install is consumed, by injecting the same local error condition that enters production cancellation settlement; do not wait 120 seconds or alter engine timing/production deadlines. Log that exact injected condition and phase rather than claiming a naturally elapsed timeout.

The mover must consume real despawns, retain its same source root, receive the host loading-won settlement, reverse membership, and regain actual trainer/creature nodes only after source readiness/admission. Assert token/pins removed after completion, local state reusable, unrelated host/staying motion and reliable presentation continue, and no absent target path appears on the staying peer. Fixture host membership cleanup must use the actual `from` realm when reversing, since its existing helper assumes every change is a departure from Meadows. This is fixture correctness, not a production architecture change.

One changed-source candidate, tiny three peers, at most 60 seconds internally / 90 seconds externally; actual owned engine descendants, isolated profiles, system commit below 90%, process count below 400, first unexpected raw error stops all owned peers. Retain all role logs and peak accounting. No world launch. Root review/lease required before execution. A passed result would establish this injected cancellation branch composition, not a naturally delayed network timeout, scoped latejoin, or host occupied-world correctness.

## Native first-failure follow-up

The first actual-Game native cancellation candidate failed on absent abandoned-target spawn paths; see REALM-TRANSITION-CANCELLATION-NATIVE-FIRST-ATTEMPT.md. Root approved retaining the abandoned target receiver denial before retarget. Current source prepares that correction using existing history, includes history in normal phase installation, and rejects duplicate, non-loading or stale-generation retargets before membership mutation. Focused tests and a corrected candidate await the import lease release. No acceptance is claimed for this follow-up yet.

Corrected follow-up is now terminal: focused 22 tests/105 assertions and actual-Game native 77 checks pass, with all six native logs clear. See REALM-TRANSITION-CANCELLATION-NATIVE-SECOND-ATTEMPT.md. The original ten-error candidate remains retained and failed.
