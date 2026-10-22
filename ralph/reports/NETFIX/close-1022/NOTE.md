# NETFIX close-1022: co-op race fixes

Lane branch `tb/netfix`, built from `origin/main` at 9c97caa68.

## TO COORDINATOR

- 2026-10-22 18:40 UTC STATUS: the send_message channel was refused (elevated_session_untrusted_device), so status is reported here.
- 2026-10-22 19:20 UTC READY (#2 only): tb/netfix-land daae6841961608c543c5a147916694d3f05270d6 is origin/main a4f8a6b7b plus the #2 fix and its test, nothing else. Proof: tools/net/run_net_smoke.sh f48_coop_loop passed 10 of 10 under load (2 busy loops, with a boss smoke loop running beside it for most runs), on tb/netfix with the same panel code. Related units (test_f28_training_boundaries + test_breakthrough_panel_labels): 21 tests, 486 assertions, 0 failed.
- 2026-10-22 19:20 UTC #1 (boss_rewards wedge) is still open. The root cause is not pending_vitals; see below. tb/netfix-land does not touch it.

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
