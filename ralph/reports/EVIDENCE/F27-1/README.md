# F27#1 — essence sources: defeating wilds, releasing a caught creature, attuned nodes, essence crops

Lane: systems-a (`tb/ev-systems-a`). Sun 11 Oct 2026, Godot 4.7-stable headless, Linux, solo host path.
Commits: units/defeat/node/release on `228203a2` (= ev-coordinator `00d4a639` + uid sidecars); crop on `0ecfd0ad` (adds the approved crop-smoke settle).

| Source | Proof (command: `godot --headless --path . --audio-driver Dummy --script tests/<file>`) | Result |
|---|---|---|
| Unit, all sources | `run_tests.gd -- --only=test_f27_essence_rules.gd,test_f27_guest_release_service.gd,test_f32_type_crops.gd,...` | 95 tests / 2566 assertions, 0 failed (`units.txt`): defeat payout typed + level-scaled; wild defeat stages essence once; release pays the released creature's type once; every type crop pays its configured essence; care trickle capped; no expedition/automation source |
| Defeating a wild | `smoke_f27_wild_defeat_essence.gd` (10:35–10:38 CT) | PASS: real Meadows wild fight vs bramblebun L2 (ground) paid `essence_ground: 1` + reduced XP via host wild-victory transaction |
| Attuned node | `smoke_f27_essence_node.gd` (10:38–10:39 CT) | PASS: controller walk + interact on shipped `essence_meadows_ground_01`; disk gained exactly `essence_ground 3, attuned_ground 1` with accepted journal + receipt |
| Releasing a caught creature | `smoke_release.gd` (10:39–10:41 CT) | PASS: real release ceremony on a full belt; `release paid [essence_ground x3] with its receipt`, five-creature rule held |
| Essence crop | `smoke_f32_type_crop_harvest.gd` (11:13–11:14 CT, `0ecfd0ad`) | PASS 53/53: hand-tilled, sown, ripened on host day clock, picked; disk paid exactly 3 `essence_ground` + 2 `attuned_ground`, accepted row, owner receipt |

## Test change (coordinator-approved 11:15 AM CT)
The crop smoke failed twice on the unmodified base (`crop_failures_before_fix.txt`, once solo): `harvest reaches owner save and ACK (source_or_revision_changed)`.
Root cause (scratch-worktree diagnostics, not committed): the smoke advanced two host days with `Game.advance_day()` 5 frames apart and tapped harvest at once. The host's bounty morning poll (`bounty_host_adapter`, 1 s) then wrote `bounty_rotate` into the character's single training-delivery slot while the harvest was in flight. The harvest's retry no longer found its own row (`session.gd` replay check), fell into `foundation_resources.host_context`, and Session's training-ACK hold read as dialogue/cutscene there, so it got a terminal refusal.
Fix: after the day-advance loop, `await _frames(120)` then poll ≤1800 physics frames until `session.owns_input() != true`. No assertion changed.

## Open finding (later ticket, not fixed here)
The host had already accepted (and paid) the harvest, but the plot reported a refusal, because the bounty rotation replaced that delivery row before the plot's retry. In normal play the morning rotation lands ~1 s after the day roll, well before a harvest, but any row written into the same per-character slot during an in-flight resource action can do the same.

## Disclosed fixtures
Each smoke's own: isolated save dirs, one owned Terrapup, opening free-play flag, short starts beside the source, hoe + 2 seed_ground for the crop, `Game.advance_day()` for crop growth, pending-catch seam for release. No generated save. Not claimed: two-peer for these sources (guest wild win/release have separate net smokes), research tasks and care trickle beyond the unit tests.

Verdict: PASS
