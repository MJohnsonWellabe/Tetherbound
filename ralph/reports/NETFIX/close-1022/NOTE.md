# NETFIX close-1022: co-op race fixes

Lane branch `tb/netfix`, built from `origin/main` at 9c97caa68.

## TO COORDINATOR

- 2026-10-22 18:40 UTC STATUS: the send_message channel was refused (elevated_session_untrusted_device), so status is reported here.
- 2026-10-22 19:20 UTC READY (#2 only): tb/netfix-land daae6841961608c543c5a147916694d3f05270d6 is origin/main a4f8a6b7b plus the #2 fix and its test, nothing else. Proof: tools/net/run_net_smoke.sh f48_coop_loop passed 10 of 10 under load (2 busy loops, with a boss smoke loop running beside it for most runs), on tb/netfix with the same panel code. Related units (test_f28_training_boundaries + test_breakthrough_panel_labels): 21 tests, 486 assertions, 0 failed.
- 2026-10-22 19:20 UTC #1 (boss_rewards wedge) is still open. The root cause is not pending_vitals; see below. tb/netfix-land does not touch it.
- 2026-10-22 21:30 UTC BLOCKED (#1, not closed): there is no local reproduction in about 55 runs across 7 stress variants
  (listed below, including SIGSTOP stalls of random peers). The CI evidence narrows it to the final round's
  completion duty stalling on a branch that logs nothing today.
- 2026-10-22 21:30 UTC QUESTION/OFFER: tb/netfix d0551206c adds one-time notes (existing once-per-reason helpers, no
  behaviour change) on exactly those silent branches. Landing it would let the next CI occurrence name the
  branch. Checks: owner_passive/ledger_rpc/creature_training units 90 tests, 1498 assertions, 0 failed;
  boss_rewards passes and prints none of the new notes when healthy. It is not in tb/netfix-land. Land it
  separately if you want the evidence; I continue on #1 meanwhile.

- 2026-10-22 21:10 UTC READY (#2, review fix): tb/netfix-land b56138a5311b9757804c0d91d2bd1a3df02d2424 = origin/main a4f8a6b7b
  + daae68419 + b56138a53. Review defect fixed: close() releases a refused press waiting to be resent (nothing was
  admitted); a resend needs the visible panel, its service and source, in the scene it was opened in, otherwise the row
  is released with "Press again to retry"; each resend keeps "Saving your earlier action first..." (no raw code).
  New tests test_closing_the_kitchen_stops_a_waiting_resend and test_a_scene_change_stops_a_waiting_resend (the
  scene case uses a ScenePanel subclass, since the unit runner has no live SceneTree). Both fail on daae68419
  (close: still pending, 2 sends; scene: 3 sends, still pending); the message assertion fails there too. Units:
  panel_labels + f28_training_boundaries 23 tests, 496 assertions, 0 failed. f48_coop_loop on 5a091c9b6 (same panel/test
  as the land head): ALL CHECKS PASSED; the guest's feed went checkpoint_pending, then settled.
- 2026-10-22 21:10 UTC #1 update:
  (a) The third occurrence (PR #712, run 39843866133) is a DIFFERENT failure. Its diagnostic shows round 1 resolved, no
      vitals pending (actor_vitals_pending=false, arbiter []), and the host's own creature FAINTED in round 2
      (active_hp=0, fainted=true, manager RESOLVING outcome "lost", enemy 32.6/112 after 37 swings). The host lost the
      damage race, and the co-op fight correctly continues for the guest, whom the smoke never drives, so the
      battle never resolves. This is the same class as item 3 (shared_boss: peer 0's creature fainted on a slow runner).
      The pending_vitals move_start refusal is again just the last stale refusal.
  (b) "Completion gated in the same scan that releases round 2" is NOT sufficient by itself: I forced that exact
      ordering (3 s scan interval; the gate lands 2 ms after the release, as in CI) and 12/12 runs passed, the
      completion settling normally in each (host_duties traces). I won't ship a change to that ordering without a
      failing reproduction: there is no deterministic test that fails today.

- 2026-10-22 22:20 UTC READY: tb/netfix-land 58235bcc29266edc6d0d9c07d68bc15786b167a5 = origin/main a4f8a6b7b + daae68419 +
  b56138a53 (Kitchen resend and its review fix) + 58235bcc2, the boss_rewards smoke fix for the PR #712 variant: Bryn's
  creatures' HP is capped with win_trainer_battle's existing enemy_hp_ceiling (20), the allowance smoke_boss uses
  (also used by shared_boss and f48_four_peer_boss on durable fights) because this smoke is about the payout's wiring, not balance. No
  assertion changed. Proof: boss_rewards_each_participant 10/10 under load (2 busy loops) on tb/netfix 2172c8fe5
  (same smoke file).
- 2026-10-22 22:20 UTC #1 status: three CI failures, two causes.
  - PR #712 (host creature fainted, outcome lost): FIXED by the cap above.
  - PRs #706 and #710 (final-round completion never settles, no log line): STILL OPEN. The forced same-scan ordering
    passes 12/12, so it is not the cause on its own, and there is no deterministic failing test to fix against. tb/netfix
    d0551206c (one-time notes on the silent branches, no behaviour change) is the way to name it on the next occurrence; it
    is NOT in tb/netfix-land.
- 2026-10-22 22:20 UTC Item 3 (shared_boss "peer 0's creature is alive to be swung at (0.0 hp)", PR #711 run
  39824552283): analysis, not fixed. Peer 0's creature fainted during the two "landed a blow on the SHARED boss" phases,
  which run against the Warden's uncapped second creature (231 hp, attack 61.6, cooldown 0.765 s). On CI those took 4
  and 6 swings (peer 1's strikes ~138 frames each); locally they take 1 and 2, and peer 0 reaches the probe at 50 hp.
  The host then lost (only creature fainted), so the friendly probe and the later whole-team fight both failed.
  Moving the probe earlier does not help: peer 0 would still die in the blow phases and the final whole-team check would
  fail instead. Robust options, none taken yet:
  (a) give peer 0 a second owned creature before the fight and tag-switch to it through the production path when its
      first is low;
  (b) a wire step for the disclosed f48_actor_topup aid. That is new harness work, so it needs your call.
  (Capping the boss's HP does NOT help here: a blow phase ends at the first landed blow whatever the boss's HP, so the
  exposure is set by how many swings it takes to land, not by HP.) My recommendation is (a). Say if you want it.

## #2 f48 guest feast feed

The CI log for run 39817268602 (job 119959298748) shows the guest's feed press got
`{"code":"owner_passive_original_pending","ok":false,"resolved":false}` from the host. The panel stayed
`still_pending: "feast_feed"` for the whole 1800-frame budget, with message `awaiting_saved_decision`.
That refusal is non-terminal: the host still held the guest's cook checkpoint on its owner-passive
stream (it clears only when the guest's rebase lands after the cook settles). Nothing ever resent the
feed, so it never committed. It was not a press landing on a row being freed by `_rebuild()`.

Fix (`scripts/masters/breakthrough_panel.gd`): a cook/feed refused with
`owner_passive_original_pending`, `owner_passive_prior_transaction_pending` or
`owner_passive_readmit_pending` resends the same original intent once a second, up to 60 times. The
host's checkpoint admits that intent once, so a resend can never feed or cook twice. When the retries
run out, the row is released with "Your earlier action is still saving. Press again to retry."
The Master chest already handles these codes this way.

Test: `tests/test_breakthrough_panel_labels.gd::test_a_momentary_feed_refusal_resends_the_same_intent_then_offers_a_retry`
fails without the fix and passes with it.

## #1 boss_rewards_each_participant wedge

The CI diagnostics contradict the pending_vitals theory:
`ordinary-round-failure-*.json` in net-smoke-runs-7 for both #710 (run 39817268602) and #706
(run 39767816107). At the failure, `actor_vitals_pending=false`, `arbiter_pending_vitals=[]`,
round 2 is `resolved=true` and the manager is in RESOLVING/won. The `pending_vitals` refusal is
only the last stale strike refusal from earlier in the fight.

What never finishes is the final round's completion duty:
- #710: neither character's completion row was ever committed (both latest rows are round 2,
  accepted). The guest's completion duty was held at `owner_passive_checkpoint_pending` from t=97616.
- #706: the host's completion row was accepted, but the guest's completion row stayed `pending`
  (journaled, never acknowledged by the guest).
- In both failures, the host gated the guest's completion checkpoint 1 ms after releasing round 2,
  in the same foundation scan. In passing runs, that gate happens in a later scan.

### #2 evidence so far

- Unit: `test_breakthrough_panel_labels.gd` 5 tests, 58 assertions, 0 failed. On the
  pre-fix panel the new test fails (expected true, got false).
- Smoke (no forced race): f48_coop_loop 5 of 5 passed while a boss smoke ran beside it. Later
  runs in that batch hit host memory exhaustion (six Godot processes on 15 GB) and are not
  counted. In the passing runs the guest's feed got `owner_passive_checkpoint_pending`, then settled.
- Smoke (forced race, debug-only 2 s delay on the guest's owner-passive rebase, local only): the
  guest's feed got `owner_passive_original_pending` twice. The panel resent the same intent;
  it then got `owner_passive_checkpoint_pending` and settled with receipt `feast_feed:<pup>:1`. The
  feast and boss legs passed in full, including "peer 1 spent one cook's cost, fed the feast, and
  its Pup's cap is 20" and "peer 1 gained 1 new feast feed receipt(s)". That run's final home-key
  step timed out under the artificial delay, which is an artifact of the injection.

### #1 local reproduction attempts (all passed; none reproduced the CI wedge)

About 45 local boss_rewards runs on 4 cores:
- 6 plain;
- 8 under 5 busy loops;
- 12 + 6 concurrent with the f48 loop;
- 12 with a 3 s foundation scan, which reproduces CI's ordering: the guest's completion is gated in
  the same scan that releases round 2;
- 5 with the smoke's Godot processes at nice 15 under 4 busy loops;
- 1+ with every enemy strike forced onto the guest, so the guest is hit in round 2 as in both CI
  failures.

A forced 3 s delay of the guest's owner-passive rebase made the gate return
`owner_passive_original_pending` and then recover, so that window is safe.

What the CI evidence still allows: in #706 the guest's saved character file already contains the
completion receipt, but the host's row stayed pending. Every remaining branch that could hold it
there without a log line is silent today:
- host `_accept_creature_training` (fallback_busy, ledger refusal, world-save refusal);
- guest owner-passive `prepared` rejection and save-phase waits;
- host `_commit_saved` early returns.

Next: keep reproducing. If it stays unreproducible, propose one-time diagnostics on exactly those
branches, using the existing `_note_host` / `_note_training_stall` convention, so the next CI
occurrence names the branch.

Additional runs: 10 with random 1-4 s SIGSTOP stalls of either peer. 8 passed. 2 failed only
"peer 1 returned to normal exploration" within the smoke's fixed 120-frame settle; the guest was still
settling, and every reward check in those runs passed, so this is not the wedge. An independent
read-only review of the code found no path that also matches the logs: its top candidate, "actor
baseline not ready", would have printed once, and it never appears. The remaining silent candidates are
the ones the d0551206c notes cover. For the host's own missing completion in #710, the prime suspect is
the scan's silent `admitted_character_state(...).is_empty()` skip.
